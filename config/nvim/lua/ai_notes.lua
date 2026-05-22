local M = {}

-- ── Storage ──────────────────────────────────────────────────────────────────

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

-- ── Note creation ─────────────────────────────────────────────────────────────

local function do_add_note(file, line_start, line_end, code)
  vim.ui.input({ prompt = "Note: " }, function(text)
    if not text or text == "" then return end
    local notes = load_notes()
    local entry = {
      file = file,
      line_start = line_start,
      line_end = line_end,
      note = text,
      created_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }
    if code and code ~= "" then entry.code = code end
    table.insert(notes, entry)
    save_notes(notes)
    vim.notify("[ai_notes] note added (" .. #notes .. " total)", vim.log.levels.INFO)
  end)
end

local function add_note_for_win(win)
  local buf = vim.api.nvim_win_get_buf(win)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    vim.notify("[ai_notes] no file in that window", vim.log.levels.WARN)
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(win)
  do_add_note(rel_path(name), cursor[1], cursor[1], nil)
end

function M.add_note_normal()
  add_note_for_win(vim.api.nvim_get_current_win())
end

function M.add_note_visual()
  local s = vim.fn.getpos("'<")
  local e = vim.fn.getpos("'>")
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    vim.notify("[ai_notes] no file in current buffer", vim.log.levels.WARN)
    return
  end
  local ls, le = s[2], e[2]
  local code_lines = vim.api.nvim_buf_get_lines(buf, ls - 1, le, false)
  do_add_note(rel_path(name), ls, le, table.concat(code_lines, "\n"))
end

-- ── Panel ─────────────────────────────────────────────────────────────────────

local state = { buf = nil, win = nil, note_map = {} }

local function is_panel_open()
  return state.win
    and vim.api.nvim_win_is_valid(state.win)
    and state.buf
    and vim.api.nvim_buf_is_valid(state.buf)
end

local function close_panel()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
  state.buf = nil
  state.note_map = {}
end

local function get_note_idx_at_cursor()
  if not is_panel_open() then return nil end
  local row = vim.api.nvim_win_get_cursor(state.win)[1]
  return state.note_map[row]
end

local function render(notes)
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end
  state.note_map = {}
  local lines = {}

  if #notes == 0 then
    lines = {
      "",
      "  No notes yet.",
      "",
      "  Add a note with <leader>a (normal or visual),",
      "  or press 'a' here to note the previous window's location.",
    }
  else
    for i, note in ipairs(notes) do
      lines[#lines + 1] = string.format("[%d] %s", i, loc_str(note))
      state.note_map[#lines] = i

      lines[#lines + 1] = "    " .. note.note
      state.note_map[#lines] = i

      if note.code then
        local n = #vim.split(note.code, "\n", { plain = true })
        lines[#lines + 1] = "    [code: " .. n .. " line" .. (n == 1 and "" or "s") .. "]"
        state.note_map[#lines] = i
      end

      lines[#lines + 1] = ""
    end
  end

  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
end

local function refresh()
  if not is_panel_open() then return end
  render(load_notes())
end

local function setup_panel_keymaps()
  local function map(key, fn)
    vim.keymap.set("n", key, fn, { buffer = state.buf, nowait = true, silent = true })
  end

  map("q", close_panel)
  map("<Esc>", close_panel)
  map("r", refresh)

  map("a", function()
    local prev = vim.fn.win_getid(vim.fn.winnr("#"))
    if prev == 0 or not vim.api.nvim_win_is_valid(prev) then
      vim.notify("[ai_notes] no previous code window", vim.log.levels.WARN)
      return
    end
    add_note_for_win(prev)
  end)

  map("e", function()
    local idx = get_note_idx_at_cursor()
    if not idx then return end
    local notes = load_notes()
    local note = notes[idx]
    if not note then return end
    vim.ui.input({ prompt = "Edit note: ", default = note.note }, function(text)
      if not text then return end
      notes[idx].note = text
      save_notes(notes)
      refresh()
    end)
  end)

  map("d", function()
    local idx = get_note_idx_at_cursor()
    if not idx then return end
    local notes = load_notes()
    table.remove(notes, idx)
    save_notes(notes)
    refresh()
  end)

  map("D", function()
    vim.ui.input({ prompt = "Clear all notes? (yes/no): " }, function(answer)
      if answer == "yes" then
        save_notes({})
        refresh()
        vim.notify("[ai_notes] all notes cleared", vim.log.levels.INFO)
      end
    end)
  end)

  map("<CR>", function()
    local idx = get_note_idx_at_cursor()
    if not idx then return end
    local notes = load_notes()
    local note = notes[idx]
    if not note then return end
    local target = vim.fn.win_getid(vim.fn.winnr("#"))
    if target ~= 0 and vim.api.nvim_win_is_valid(target) then
      vim.api.nvim_set_current_win(target)
    end
    vim.cmd("edit " .. vim.fn.fnameescape(note.file))
    vim.api.nvim_win_set_cursor(0, { note.line_start, 0 })
  end)

  map("p", function()
    M.bake_prompt(load_notes())
  end)

  map("y", function()
    M.copy_prompt(load_notes())
  end)
end

function M.open_panel()
  if is_panel_open() then
    close_panel()
    return
  end

  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].buftype = "nofile"
  vim.bo[state.buf].bufhidden = "wipe"
  vim.bo[state.buf].swapfile = false
  vim.bo[state.buf].modifiable = false

  local width = math.max(42, math.floor(vim.o.columns * 0.32))
  vim.cmd("botright " .. width .. "vsplit")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, state.buf)
  vim.wo[state.win].wrap = false
  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].signcolumn = "no"
  vim.wo[state.win].cursorline = true

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(state.win),
    once = true,
    callback = function()
      state.win = nil
      state.buf = nil
      state.note_map = {}
    end,
  })

  render(load_notes())
  setup_panel_keymaps()
end

-- ── Prompt generation ─────────────────────────────────────────────────────────

local function build_prompt_lines(notes)
  local lines = {}
  local function add(s) lines[#lines + 1] = s end

  add("TASK")
  add("")
  add("Use the notes below to modify the codebase.")
  add("")
  add("Preserve existing behavior unless a note explicitly says otherwise.")
  add("Prefer small, focused changes.")
  add("Do not rename exported APIs unless necessary.")
  add("After changes, summarize what changed and mention risks.")
  add("")
  add("NOTES")
  add("")

  for i, note in ipairs(notes) do
    add(tostring(i) .. ". " .. loc_str(note))
    add("")
    add("Note:")
    add(note.note)

    if note.code then
      add("")
      add("Selected code:")
      add("----- BEGIN SELECTED CODE -----")
      for _, cl in ipairs(vim.split(note.code, "\n", { plain = true })) do
        add(cl)
      end
      add("----- END SELECTED CODE -----")
    end

    add("")
  end

  return lines
end

function M.bake_prompt(notes)
  notes = notes or load_notes()
  if #notes == 0 then
    vim.notify("[ai_notes] no notes to bake", vim.log.levels.WARN)
    return
  end
  local lines = build_prompt_lines(notes)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "text"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.cmd("tabnew")
  vim.api.nvim_win_set_buf(0, buf)
end

function M.copy_prompt(notes)
  notes = notes or load_notes()
  if #notes == 0 then
    vim.notify("[ai_notes] no notes to copy", vim.log.levels.WARN)
    return
  end
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
      refresh()
      vim.notify("[ai_notes] all notes cleared", vim.log.levels.INFO)
    end
  end)
end

-- ── Setup ─────────────────────────────────────────────────────────────────────

function M.setup()
  vim.keymap.set("n", "<leader>a", M.open_panel, { desc = "AI Notes" })
  vim.keymap.set("x", "<leader>a", M.add_note_visual, { desc = "AI Notes: add note for selection" })

  vim.api.nvim_create_user_command("AiNotes",      M.open_panel,                       {})
  vim.api.nvim_create_user_command("AiAddNote",    M.add_note_normal,                  {})
  vim.api.nvim_create_user_command("AiBakePrompt", function() M.bake_prompt() end,     {})
  vim.api.nvim_create_user_command("AiCopyPrompt", function() M.copy_prompt() end,     {})
  vim.api.nvim_create_user_command("AiClearNotes", M.clear_notes,                      {})

  vim.api.nvim_create_user_command("Aio", M.open_panel,                       {})
  vim.api.nvim_create_user_command("Ain", M.add_note_normal,                  {})
  vim.api.nvim_create_user_command("Aib", function() M.bake_prompt() end,     {})
  vim.api.nvim_create_user_command("Aip", function() M.copy_prompt() end,     {})
  vim.api.nvim_create_user_command("Aic", M.clear_notes,                      {})
end

return M
