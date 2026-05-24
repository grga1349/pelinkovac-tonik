local M = {}

local hl_ns = vim.api.nvim_create_namespace("ai_notes_hl")

-- ── Storage ───────────────────────────────────────────────────────────────────

local function notes_path()
  return vim.fn.getcwd() .. "/.ai/notes.json"
end

local function ensure_ai_dir()
  local dir = vim.fn.getcwd() .. "/.ai"
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
end

local function load_notes()
  local f = io.open(notes_path(), "r")
  if not f then return {} end
  local raw = f:read("*a")
  f:close()
  if not raw or raw == "" then return {} end
  local ok, data = pcall(vim.json.decode, raw)
  if not ok or type(data) ~= "table" then return {} end
  return data
end

local function save_notes(notes)
  ensure_ai_dir()
  local f = io.open(notes_path(), "w")
  if not f then
    vim.notify("[ai_notes] cannot write " .. notes_path(), vim.log.levels.ERROR)
    return
  end
  f:write(vim.json.encode(notes))
  f:close()
end

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function rel_path(abs)
  local cwd = vim.fn.getcwd()
  if abs:sub(1, #cwd) == cwd then
    local rest = abs:sub(#cwd + 1)
    if rest:sub(1, 1) == "/" then return rest:sub(2) end
  end
  return abs
end

local function loc_str(note)
  if note.line_start == note.line_end then
    return note.file .. ":" .. tostring(note.line_start)
  end
  return note.file .. ":" .. tostring(note.line_start) .. "-" .. tostring(note.line_end)
end

local function line_count(s)
  if not s or s == "" then return 0 end
  return #vim.split(s, "\n", { plain = true })
end

local function first_line(s)
  return s:match("^([^\n]*)") or s
end

-- ── Highlights ────────────────────────────────────────────────────────────────

local function setup_highlights()
  vim.api.nvim_set_hl(0, "AiNotesIndex",         { fg = "#B8A0CC", bold = true })
  vim.api.nvim_set_hl(0, "AiNotesLocation",       { fg = "#8AABB0" })
  vim.api.nvim_set_hl(0, "AiNotesText",           { fg = "#A09890" })
  vim.api.nvim_set_hl(0, "AiNotesCode",           { fg = "#7FA36B", italic = true })
  vim.api.nvim_set_hl(0, "AiNotesSep",            { fg = "#3D3930" })
  vim.api.nvim_set_hl(0, "AiNotesSectionHeader",  { fg = "#D4935A", bold = true })
  vim.api.nvim_set_hl(0, "AiNotesLabel",          { fg = "#D0A15A" })
end

-- ── Prompt generation ─────────────────────────────────────────────────────────

local function build_prompt_lines(notes)
  local lines = {}
  local function add(s) lines[#lines + 1] = s end

  add("TASK"); add("")
  add("Use the notes below to modify the codebase."); add("")
  add("Preserve existing behavior unless a note explicitly says otherwise.")
  add("Prefer small, focused changes.")
  add("Do not rename exported APIs unless necessary.")
  add("After changes, summarize what changed and mention risks.")
  add(""); add("NOTES"); add("")

  for i, note in ipairs(notes) do
    add(tostring(i) .. ". " .. loc_str(note)); add("")
    add("Note:")
    for _, l in ipairs(vim.split(note.note, "\n", { plain = true })) do add(l) end
    if note.code then
      add(""); add("Selected code:")
      add("----- BEGIN SELECTED CODE -----")
      for _, cl in ipairs(vim.split(note.code, "\n", { plain = true })) do add(cl) end
      add("----- END SELECTED CODE -----")
    end
    add("")
  end
  return lines
end

local function apply_prompt_highlights(buf, lines)
  vim.api.nvim_buf_clear_namespace(buf, hl_ns, 0, -1)
  local in_code = false
  for i, line in ipairs(lines) do
    local lnum = i - 1
    if line == "TASK" or line == "NOTES" then
      vim.api.nvim_buf_add_highlight(buf, hl_ns, "AiNotesSectionHeader", lnum, 0, -1)
    elseif line == "Note:" or line == "Selected code:" then
      vim.api.nvim_buf_add_highlight(buf, hl_ns, "AiNotesLabel", lnum, 0, -1)
    elseif line:match("^%d+%. ") then
      local dot_space = line:find("%. ")
      vim.api.nvim_buf_add_highlight(buf, hl_ns, "AiNotesIndex",    lnum, 0, dot_space + 1)
      vim.api.nvim_buf_add_highlight(buf, hl_ns, "AiNotesLocation", lnum, dot_space + 2, -1)
    elseif line == "----- BEGIN SELECTED CODE -----" then
      vim.api.nvim_buf_add_highlight(buf, hl_ns, "AiNotesSep", lnum, 0, -1)
      in_code = true
    elseif line == "----- END SELECTED CODE -----" then
      vim.api.nvim_buf_add_highlight(buf, hl_ns, "AiNotesSep", lnum, 0, -1)
      in_code = false
    elseif in_code then
      vim.api.nvim_buf_add_highlight(buf, hl_ns, "AiNotesCode", lnum, 0, -1)
    elseif line:match("^Use the notes") or line:match("^Preserve")
        or line:match("^Prefer")       or line:match("^Do not")
        or line:match("^After") then
      vim.api.nvim_buf_add_highlight(buf, hl_ns, "AiNotesText", lnum, 0, -1)
    end
  end
end

-- ── Modal state ───────────────────────────────────────────────────────────────

local modal = {
  write_buf    = nil, write_win = nil,
  list_buf     = nil, list_win  = nil,
  note_map     = {},   -- list buf line (1-idx) → note index
  header_lines = {},   -- note index → list buf line of its header
  editing_idx  = nil,  -- nil = new note, N = editing existing note N
  preview_idx  = nil,  -- note currently shown in write pane (nil when editing)
  source_win   = nil,
  pending      = {},
}

local function is_modal_open()
  return (modal.write_win and vim.api.nvim_win_is_valid(modal.write_win))
      or (modal.list_win  and vim.api.nvim_win_is_valid(modal.list_win))
end

local function close_modal()
  pcall(vim.api.nvim_del_augroup_by_name, "AiNotesModal")
  for _, key in ipairs({ "write_win", "list_win" }) do
    if modal[key] and vim.api.nvim_win_is_valid(modal[key]) then
      pcall(vim.api.nvim_win_close, modal[key], true)
    end
  end
  modal.write_buf    = nil; modal.write_win = nil
  modal.list_buf     = nil; modal.list_win  = nil
  modal.note_map     = {}
  modal.header_lines = {}
  modal.editing_idx  = nil
  modal.preview_idx  = nil
  modal.source_win   = nil
  modal.pending      = {}
end

-- ── Layout ────────────────────────────────────────────────────────────────────

local function compute_layout()
  local total_w = math.floor(vim.o.columns * 0.90)
  local total_h = math.floor(vim.o.lines   * 0.78)
  local row     = math.floor((vim.o.lines   - total_h) / 2)
  local col     = math.floor((vim.o.columns - total_w) / 2)
  local inner_h = total_h - 2
  local avail_w = total_w - 4
  local write_w = math.floor(avail_w * 0.40)
  local list_w  = avail_w - write_w
  return { row = row, col = col, write_w = write_w, list_w = list_w, h = inner_h }
end

-- ── Write-win title ───────────────────────────────────────────────────────────

local function write_title()
  if modal.preview_idx and not modal.editing_idx then
    return string.format("  Preview [%d]  ", modal.preview_idx)
  end
  if modal.editing_idx then
    return string.format("  Edit Note [%d]  ", modal.editing_idx)
  end
  local p = modal.pending
  if p.file then
    local loc = p.file .. ":" .. tostring(p.line_start)
    if p.line_end and p.line_end ~= p.line_start then
      loc = loc .. "-" .. tostring(p.line_end)
    end
    if p.code then
      return string.format("  Note  [%s] [+%d lines]  ", loc, line_count(p.code))
    end
    return string.format("  Note  [%s]  ", loc)
  end
  return "  Note  "
end

local function update_write_title()
  if modal.write_win and vim.api.nvim_win_is_valid(modal.write_win) then
    pcall(vim.api.nvim_win_set_config, modal.write_win,
      { title = write_title(), title_pos = "center" })
  end
end

-- ── enter_new_mode: clear write pane, focus it, ready for new note ────────────

local function enter_new_mode()
  modal.editing_idx = nil
  modal.preview_idx = nil
  if modal.write_buf and vim.api.nvim_buf_is_valid(modal.write_buf) then
    vim.bo[modal.write_buf].modifiable = true
    vim.api.nvim_buf_set_lines(modal.write_buf, 0, -1, false, { "" })
    vim.api.nvim_buf_clear_namespace(modal.write_buf, hl_ns, 0, -1)
  end
  update_write_title()
  if modal.write_win and vim.api.nvim_win_is_valid(modal.write_win) then
    vim.api.nvim_set_current_win(modal.write_win)
    vim.cmd("startinsert")
  end
end

-- ── Preview: fill write pane with note content (stays modifiable) ─────────────

local function show_preview(idx)
  if modal.editing_idx then return end
  if not modal.write_buf or not vim.api.nvim_buf_is_valid(modal.write_buf) then return end
  local notes = load_notes()
  local note  = notes[idx]
  if not note then return end

  modal.preview_idx = idx
  local lines = {}

  for _, l in ipairs(vim.split(note.note, "\n", { plain = true })) do
    lines[#lines + 1] = l
  end

  if note.code then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "  ── selected code ──────────────────"
    for _, cl in ipairs(vim.split(note.code, "\n", { plain = true })) do
      lines[#lines + 1] = cl
    end
  end

  vim.bo[modal.write_buf].modifiable = true
  vim.api.nvim_buf_set_lines(modal.write_buf, 0, -1, false, lines)

  vim.api.nvim_buf_clear_namespace(modal.write_buf, hl_ns, 0, -1)
  if note.code then
    local note_lc  = line_count(note.note)
    local sep_lnum = note_lc + 1  -- 0-indexed: note lines + blank
    vim.api.nvim_buf_add_highlight(modal.write_buf, hl_ns, "AiNotesSep", sep_lnum, 0, -1)
    local code_lines = vim.split(note.code, "\n", { plain = true })
    for j = 0, #code_lines - 1 do
      vim.api.nvim_buf_add_highlight(modal.write_buf, hl_ns, "AiNotesCode", sep_lnum + 1 + j, 0, -1)
    end
  end

  update_write_title()
end

-- ── List rendering ────────────────────────────────────────────────────────────

local function apply_list_highlights(notes)
  if not modal.list_buf or not vim.api.nvim_buf_is_valid(modal.list_buf) then return end
  vim.api.nvim_buf_clear_namespace(modal.list_buf, hl_ns, 0, -1)
  for i, note in ipairs(notes) do
    local h       = (modal.header_lines[i] or 1) - 1  -- 0-indexed
    local bracket = #string.format("[%d]", i)
    vim.api.nvim_buf_add_highlight(modal.list_buf, hl_ns, "AiNotesIndex",    h, 0, bracket)
    vim.api.nvim_buf_add_highlight(modal.list_buf, hl_ns, "AiNotesLocation", h, bracket + 1, -1)
    vim.api.nvim_buf_add_highlight(modal.list_buf, hl_ns, "AiNotesText",     h + 1, 4, -1)
    if note.code then
      vim.api.nvim_buf_add_highlight(modal.list_buf, hl_ns, "AiNotesCode", h + 2, 4, -1)
    end
  end
end

local function render_list(notes)
  if not modal.list_buf or not vim.api.nvim_buf_is_valid(modal.list_buf) then return end
  modal.note_map     = {}
  modal.header_lines = {}
  local lines = {}

  if #notes == 0 then
    lines = { "", "  No notes yet.", "", "  Write a note on the left, press <CR> to save." }
  else
    local max_p = 60
    if modal.list_win and vim.api.nvim_win_is_valid(modal.list_win) then
      max_p = math.max(20, vim.api.nvim_win_get_width(modal.list_win) - 8)
    end
    for i, note in ipairs(notes) do
      lines[#lines + 1] = string.format("[%d] %s", i, loc_str(note))
      modal.note_map[#lines]  = i
      modal.header_lines[i]   = #lines

      local preview = first_line(note.note)
      if #preview > max_p then preview = preview:sub(1, max_p - 3) .. "..." end
      lines[#lines + 1] = "    " .. preview
      modal.note_map[#lines] = i

      if note.code then
        local n = line_count(note.code)
        lines[#lines + 1] = "    [code: " .. n .. " line" .. (n == 1 and "" or "s") .. "]"
        modal.note_map[#lines] = i
      end
      lines[#lines + 1] = ""
    end
  end

  vim.bo[modal.list_buf].modifiable = true
  vim.api.nvim_buf_set_lines(modal.list_buf, 0, -1, false, lines)
  vim.bo[modal.list_buf].modifiable = false

  if modal.list_win and vim.api.nvim_win_is_valid(modal.list_win) then
    pcall(vim.api.nvim_win_set_config, modal.list_win,
      { title = string.format(" Notes (%d) ", #notes), title_pos = "center" })
  end

  apply_list_highlights(notes)
end

-- ── Prompt review modal ───────────────────────────────────────────────────────

local function open_prompt_review(notes)
  if #notes == 0 then
    vim.notify("[ai_notes] no notes to bake", vim.log.levels.WARN)
    return
  end

  if is_modal_open() then close_modal() end

  local w   = math.floor(vim.o.columns * 0.82)
  local h   = math.floor(vim.o.lines   * 0.78)
  local row = math.floor((vim.o.lines   - h) / 2)
  local col = math.floor((vim.o.columns - w) / 2)

  local lines = build_prompt_lines(notes)
  local buf   = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype    = "nofile"
  vim.bo[buf].swapfile   = false
  vim.bo[buf].modifiable = true
  vim.bo[buf].filetype   = "text"
  apply_prompt_highlights(buf, lines)

  local win = vim.api.nvim_open_win(buf, true, {
    relative  = "editor",
    row = row, col = col,
    width = w, height = h,
    style = "minimal", border = "rounded",
    title     = "  Prompt — edit freely · <CR> copy · q close  ",
    title_pos = "center",
    zindex    = 60,
  })
  vim.wo[win].wrap = true

  local function copy_and_close()
    if not vim.api.nvim_win_is_valid(win) then return end
    local all  = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local text = table.concat(all, "\n")
    local ok, err = pcall(vim.fn.setreg, "+", text)
    if ok then
      vim.notify("[ai_notes] prompt copied to clipboard", vim.log.levels.INFO)
    else
      vim.notify("[ai_notes] clipboard unavailable: " .. tostring(err), vim.log.levels.WARN)
    end
    pcall(vim.api.nvim_win_close, win, true)
  end

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer   = buf,
    callback = function()
      apply_prompt_highlights(buf, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    end,
  })

  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "<CR>",  copy_and_close,                                        opts)
  vim.keymap.set("n", "q",     function() pcall(vim.api.nvim_win_close, win, true) end, opts)
  vim.keymap.set("n", "<Esc>", function() pcall(vim.api.nvim_win_close, win, true) end, opts)
end

-- ── Submit note ───────────────────────────────────────────────────────────────

local function submit_note()
  if not modal.write_buf or not vim.api.nvim_buf_is_valid(modal.write_buf) then return end

  local lines = vim.api.nvim_buf_get_lines(modal.write_buf, 0, -1, false)
  while #lines > 0 and lines[#lines] == "" do table.remove(lines) end
  local text = table.concat(lines, "\n")
  if text == "" then return end

  local notes       = load_notes()
  local was_editing = modal.editing_idx

  if was_editing then
    if notes[was_editing] then notes[was_editing].note = text end
  else
    local p = modal.pending
    if not p.file then
      if modal.source_win and vim.api.nvim_win_is_valid(modal.source_win) then
        local sbuf = vim.api.nvim_win_get_buf(modal.source_win)
        local name = vim.api.nvim_buf_get_name(sbuf)
        if name ~= "" then
          local cursor = vim.api.nvim_win_get_cursor(modal.source_win)
          p = { file = rel_path(name), line_start = cursor[1], line_end = cursor[1] }
        end
      end
    end
    if not p.file then
      vim.notify("[ai_notes] no location context — note not saved", vim.log.levels.WARN)
      return
    end
    local entry = {
      file       = p.file, line_start = p.line_start, line_end = p.line_end,
      note       = text,
      created_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }
    if p.code and p.code ~= "" then entry.code = p.code end
    table.insert(notes, entry)
  end

  save_notes(notes)
  render_list(notes)
  vim.notify("[ai_notes] note saved (" .. #notes .. " total)", vim.log.levels.INFO)
  enter_new_mode()
end

-- ── Keymaps ───────────────────────────────────────────────────────────────────

local function get_list_note_idx()
  if not modal.list_win or not vim.api.nvim_win_is_valid(modal.list_win) then return nil end
  return modal.note_map[vim.api.nvim_win_get_cursor(modal.list_win)[1]]
end

local function focus_write()
  if modal.write_win and vim.api.nvim_win_is_valid(modal.write_win) then
    vim.api.nvim_set_current_win(modal.write_win)
  end
end

local function focus_list()
  if modal.list_win and vim.api.nvim_win_is_valid(modal.list_win) then
    vim.api.nvim_set_current_win(modal.list_win)
  end
end

local function jump_to_note_header(idx)
  local line = modal.header_lines[idx]
  if line and modal.list_win and vim.api.nvim_win_is_valid(modal.list_win) then
    vim.api.nvim_win_set_cursor(modal.list_win, { line, 0 })
  end
end

local function setup_write_keymaps()
  local opts = { buffer = modal.write_buf, nowait = true, silent = true }
  vim.keymap.set("n", "<CR>",  submit_note, opts)
  vim.keymap.set("n", "<Tab>", focus_list,  opts)
  vim.keymap.set("n", "q",     close_modal, opts)
  vim.keymap.set("n", "<Esc>", close_modal, opts)
  vim.keymap.set("n", "<C-b>", function() open_prompt_review(load_notes()) end, opts)
end

local function setup_list_keymaps()
  local opts = { buffer = modal.list_buf, nowait = true, silent = true }

  -- note-by-note navigation
  vim.keymap.set("n", "j", function()
    local idx  = get_list_note_idx() or 0
    local next = idx + 1
    if next <= #load_notes() then jump_to_note_header(next) end
  end, opts)

  vim.keymap.set("n", "k", function()
    local idx  = get_list_note_idx() or 2
    local prev = idx - 1
    if prev >= 1 then jump_to_note_header(prev) end
  end, opts)

  -- Tab: go back to write pane in insert mode
  vim.keymap.set("n", "<Tab>", function()
    focus_write()
    vim.cmd("startinsert")
  end, opts)

  vim.keymap.set("n", "q",     close_modal,    opts)
  vim.keymap.set("n", "<Esc>", enter_new_mode, opts)

  -- add new note from source window position
  vim.keymap.set("n", "a", function()
    local pending = modal.pending
    if modal.source_win and vim.api.nvim_win_is_valid(modal.source_win) then
      local sbuf = vim.api.nvim_win_get_buf(modal.source_win)
      local name = vim.api.nvim_buf_get_name(sbuf)
      if name ~= "" then
        local cursor = vim.api.nvim_win_get_cursor(modal.source_win)
        pending = { file = rel_path(name), line_start = cursor[1], line_end = cursor[1] }
      end
    end
    modal.pending = pending
    enter_new_mode()
  end, opts)

  -- edit selected note
  vim.keymap.set("n", "e", function()
    local idx = get_list_note_idx()
    if not idx then return end
    local notes = load_notes()
    local note  = notes[idx]
    if not note then return end
    modal.editing_idx = idx
    modal.preview_idx = nil
    if modal.write_buf and vim.api.nvim_buf_is_valid(modal.write_buf) then
      vim.bo[modal.write_buf].modifiable = true
      vim.api.nvim_buf_set_lines(modal.write_buf, 0, -1, false,
        vim.split(note.note, "\n", { plain = true }))
      vim.api.nvim_buf_clear_namespace(modal.write_buf, hl_ns, 0, -1)
    end
    update_write_title()
    focus_write()
    vim.cmd("startinsert")
  end, opts)

  -- delete selected note
  vim.keymap.set("n", "d", function()
    local idx = get_list_note_idx()
    if not idx then return end
    local notes = load_notes()
    table.remove(notes, idx)
    save_notes(notes)
    render_list(notes)
    local new_idx = math.min(idx, #notes)
    if new_idx >= 1 then
      jump_to_note_header(new_idx)
      show_preview(new_idx)
    else
      enter_new_mode()
    end
  end, opts)

  -- clear all notes
  vim.keymap.set("n", "D", function()
    vim.ui.input({ prompt = "Clear all notes? (yes/no): " }, function(answer)
      if answer == "yes" then
        save_notes({})
        render_list({})
        vim.notify("[ai_notes] all notes cleared", vim.log.levels.INFO)
        enter_new_mode()
      end
    end)
  end, opts)

  -- jump to file at note location
  vim.keymap.set("n", "<CR>", function()
    local idx = get_list_note_idx()
    if not idx then return end
    local notes  = load_notes()
    local note   = notes[idx]
    if not note then return end
    local target = modal.source_win
    close_modal()
    if target and vim.api.nvim_win_is_valid(target) then
      vim.api.nvim_set_current_win(target)
    end
    vim.cmd("edit " .. vim.fn.fnameescape(note.file))
    local max_line = vim.api.nvim_buf_line_count(0)
    vim.api.nvim_win_set_cursor(0, { math.max(1, math.min(note.line_start, max_line)), 0 })
  end, opts)

  vim.keymap.set("n", "<C-b>", function()
    open_prompt_review(load_notes())
  end, opts)

  vim.keymap.set("n", "r", function()
    local notes = load_notes()
    render_list(notes)
    if not modal.editing_idx and modal.preview_idx and modal.preview_idx <= #notes then
      show_preview(modal.preview_idx)
    end
  end, opts)
end

-- ── Open modal windows ────────────────────────────────────────────────────────

local function open_modal_windows()
  local layout = compute_layout()

  modal.write_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[modal.write_buf].buftype  = "nofile"
  vim.bo[modal.write_buf].swapfile = false

  modal.list_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[modal.list_buf].buftype    = "nofile"
  vim.bo[modal.list_buf].swapfile   = false
  vim.bo[modal.list_buf].modifiable = false

  modal.write_win = vim.api.nvim_open_win(modal.write_buf, true, {
    relative  = "editor",
    row = layout.row, col = layout.col,
    width = layout.write_w, height = layout.h,
    style = "minimal", border = "rounded",
    title = write_title(), title_pos = "center",
  })
  vim.wo[modal.write_win].wrap           = true
  vim.wo[modal.write_win].number         = false
  vim.wo[modal.write_win].relativenumber = false

  modal.list_win = vim.api.nvim_open_win(modal.list_buf, false, {
    relative  = "editor",
    row = layout.row, col = layout.col + layout.write_w + 2,
    width = layout.list_w, height = layout.h,
    style = "minimal", border = "rounded",
    title = " Notes (0) ", title_pos = "center",
  })
  vim.wo[modal.list_win].wrap           = false
  vim.wo[modal.list_win].number         = false
  vim.wo[modal.list_win].relativenumber = false
  vim.wo[modal.list_win].cursorline     = true

  local augroup = vim.api.nvim_create_augroup("AiNotesModal", { clear = true })

  for _, key in ipairs({ "write_win", "list_win" }) do
    vim.api.nvim_create_autocmd("WinClosed", {
      group    = augroup,
      pattern  = tostring(modal[key]),
      once     = true,
      callback = function() vim.schedule(close_modal) end,
    })
  end

  -- live preview when cursor moves to a different note in the list
  vim.api.nvim_create_autocmd("CursorMoved", {
    group  = augroup,
    buffer = modal.list_buf,
    callback = function()
      if modal.editing_idx then return end
      local idx = get_list_note_idx()
      if idx and idx ~= modal.preview_idx then show_preview(idx) end
    end,
  })

  -- show preview when entering list pane (e.g. via Tab)
  vim.api.nvim_create_autocmd("WinEnter", {
    group  = augroup,
    buffer = modal.list_buf,
    callback = function()
      if modal.editing_idx then return end
      local idx = get_list_note_idx()
      if idx and idx ~= modal.preview_idx then show_preview(idx) end
    end,
  })

  local notes = load_notes()
  render_list(notes)
  setup_write_keymaps()
  setup_list_keymaps()

  -- position list cursor on first note; always open in write pane + insert mode
  if #notes > 0 then
    jump_to_note_header(1)
  end
  focus_write()
  vim.cmd("startinsert")
end

-- ── Public open functions ─────────────────────────────────────────────────────

function M.open_modal()
  if is_modal_open() then close_modal(); return end
  modal.source_win = vim.api.nvim_get_current_win()
  local buf  = vim.api.nvim_win_get_buf(modal.source_win)
  local name = vim.api.nvim_buf_get_name(buf)
  if name ~= "" then
    local cursor = vim.api.nvim_win_get_cursor(modal.source_win)
    modal.pending = { file = rel_path(name), line_start = cursor[1], line_end = cursor[1] }
  else
    modal.pending = {}
  end
  open_modal_windows()
end

function M.open_modal_visual(source_win, buf, name, ls, le)
  if is_modal_open() then close_modal(); return end
  modal.source_win = source_win
  if name ~= "" then
    local code_lines = vim.api.nvim_buf_get_lines(buf, ls - 1, le, false)
    modal.pending = {
      file       = rel_path(name),
      line_start = ls, line_end = le,
      code       = table.concat(code_lines, "\n"),
    }
  else
    modal.pending = {}
  end
  open_modal_windows()
end

-- ── Standalone commands ───────────────────────────────────────────────────────

function M.add_note_normal()
  local win  = vim.api.nvim_get_current_win()
  local buf  = vim.api.nvim_win_get_buf(win)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    vim.notify("[ai_notes] no file in current buffer", vim.log.levels.WARN)
    return
  end
  local file   = rel_path(name)
  local cursor = vim.api.nvim_win_get_cursor(win)
  vim.ui.input({ prompt = "Note: " }, function(text)
    if not text or text == "" then return end
    local notes = load_notes()
    table.insert(notes, {
      file = file, line_start = cursor[1], line_end = cursor[1],
      note = text, created_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    })
    save_notes(notes)
    vim.notify("[ai_notes] note added (" .. #notes .. " total)", vim.log.levels.INFO)
  end)
end

function M.bake_prompt()
  open_prompt_review(load_notes())
end

function M.copy_prompt()
  local notes = load_notes()
  if #notes == 0 then vim.notify("[ai_notes] no notes", vim.log.levels.WARN); return end
  local text = table.concat(build_prompt_lines(notes), "\n")
  local ok, err = pcall(vim.fn.setreg, "+", text)
  if ok then
    vim.notify("[ai_notes] prompt copied to clipboard", vim.log.levels.INFO)
  else
    vim.notify("[ai_notes] clipboard unavailable: " .. tostring(err), vim.log.levels.WARN)
  end
end

function M.clear_notes()
  vim.ui.input({ prompt = "Clear all notes? (yes/no): " }, function(answer)
    if answer == "yes" then
      save_notes({})
      if is_modal_open() then
        render_list({})
        enter_new_mode()
      end
      vim.notify("[ai_notes] all notes cleared", vim.log.levels.INFO)
    end
  end)
end

-- ── Setup ─────────────────────────────────────────────────────────────────────

function M.setup()
  setup_highlights()
  -- Re-apply after theme clears highlights (theme uses BufEnter/WinEnter/VimEnter autocmds)
  vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter", "WinEnter", "BufEnter" }, {
    callback = setup_highlights,
  })

  vim.keymap.set("n", "<leader>a", M.open_modal,  { desc = "AI Notes" })
  vim.keymap.set("n", "<leader>A", M.bake_prompt, { desc = "AI Notes: prompt review" })

  vim.keymap.set("x", "<leader>a", function()
    local source_win = vim.api.nvim_get_current_win()
    local buf  = vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(buf)
    local ls   = vim.fn.line("v")
    local le   = vim.fn.line(".")
    if ls > le then ls, le = le, ls end
    vim.schedule(function()
      M.open_modal_visual(source_win, buf, name, ls, le)
    end)
  end, { desc = "AI Notes: add note for selection" })

  vim.api.nvim_create_user_command("AiNotes",      M.open_modal,                    {})
  vim.api.nvim_create_user_command("AiAddNote",    M.add_note_normal,               {})
  vim.api.nvim_create_user_command("AiBakePrompt", function() M.bake_prompt() end,  {})
  vim.api.nvim_create_user_command("AiCopyPrompt", function() M.copy_prompt() end,  {})
  vim.api.nvim_create_user_command("AiClearNotes", M.clear_notes,                   {})

  vim.api.nvim_create_user_command("Aio", M.open_modal,                    {})
  vim.api.nvim_create_user_command("Ain", M.add_note_normal,               {})
  vim.api.nvim_create_user_command("Aib", function() M.bake_prompt() end,  {})
  vim.api.nvim_create_user_command("Aip", function() M.copy_prompt() end,  {})
  vim.api.nvim_create_user_command("Aic", M.clear_notes,                   {})
end

return M
