vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true
vim.opt.cursorline = false
vim.opt.winblend = 0
vim.opt.pumblend = 0
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400
vim.opt.colorcolumn = "120"

vim.filetype.add({
  extension = {
    templ = "templ",
  },
})

vim.keymap.set("i", "jj", "<Esc>", { silent = true })
vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Write" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit" })
vim.keymap.set("n", "<leader>?", function()
  vim.cmd("tabnew")
  local lines = {
    "ptx keybindings",
    "",
    "File tree: Space e",
    "File finder: Ctrl-p, Space f f, Space p",
    "Text search: Space /, Space f g",
    "Buffers: Space f b",
    "Escape insert mode: jj",
    "Save: Space w",
    "Quit: Space q",
    "Go to definition: gd",
    "References: gr",
    "Hover: K",
    "Rename: Space r n",
    "Code action: Space c a",
    "Format: Space f",
  }
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.modifiable = false
end, { desc = "ptx keybindings" })

local colors = {
  bg = "#1e1e1e",
  bg_alt = "#2d2d30",
  fg = "#d4d4d4",
  muted = "#6a9955",
  blue = "#569cd6",
  cyan = "#9cdcfe",
  green = "#6a9955",
  light_green = "#b5cea8",
  orange = "#ce9178",
  red = "#f44747",
  yellow = "#dcdcaa",
  purple = "#c586c0",
}

local function apply_theme_overrides()
  local set = vim.api.nvim_set_hl

  vim.cmd("highlight clear")
  vim.o.background = "dark"
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end
  vim.g.colors_name = "vscode-dark-plus"

  set(0, "Normal", { fg = colors.fg, bg = colors.bg })
  set(0, "NormalNC", { fg = colors.fg, bg = colors.bg })
  set(0, "NormalFloat", { fg = colors.fg, bg = colors.bg })
  set(0, "FloatBorder", { fg = colors.muted, bg = colors.bg })
  set(0, "SignColumn", { bg = colors.bg })
  set(0, "EndOfBuffer", { fg = colors.bg, bg = colors.bg })
  set(0, "LineNr", { fg = colors.muted, bg = colors.bg })
  set(0, "CursorLine", { bg = colors.bg })
  set(0, "CursorLineNr", { fg = colors.fg, bg = colors.bg, bold = true })
  set(0, "ColorColumn", { bg = colors.bg_alt })
  set(0, "WinSeparator", { fg = colors.bg_alt, bg = colors.bg })
  set(0, "VertSplit", { fg = colors.bg_alt, bg = colors.bg })
  set(0, "Visual", { bg = colors.bg_alt })
  set(0, "Pmenu", { fg = colors.fg, bg = colors.bg })
  set(0, "PmenuSel", { fg = colors.fg, bg = colors.bg_alt })
  set(0, "StatusLine", { fg = colors.fg, bg = colors.bg })
  set(0, "StatusLineNC", { fg = colors.muted, bg = colors.bg })

  set(0, "Comment", { fg = colors.muted, italic = true })
  set(0, "String", { fg = colors.orange })
  set(0, "Character", { fg = colors.orange })
  set(0, "Number", { fg = colors.light_green })
  set(0, "Boolean", { fg = colors.blue })
  set(0, "Float", { fg = colors.light_green })
  set(0, "Function", { fg = colors.yellow })
  set(0, "Identifier", { fg = colors.cyan })
  set(0, "Keyword", { fg = colors.blue })
  set(0, "Statement", { fg = colors.purple })
  set(0, "Conditional", { fg = colors.purple })
  set(0, "Repeat", { fg = colors.purple })
  set(0, "Operator", { fg = colors.fg })
  set(0, "Type", { fg = "#4ec9b0" })
  set(0, "PreProc", { fg = colors.blue })
  set(0, "Special", { fg = colors.yellow })
  set(0, "Constant", { fg = colors.light_green })

  set(0, "@comment", { fg = colors.muted, italic = true })
  set(0, "@string", { fg = colors.orange })
  set(0, "@string.escape", { fg = colors.cyan })
  set(0, "@number", { fg = colors.light_green })
  set(0, "@boolean", { fg = colors.blue })
  set(0, "@function", { fg = colors.yellow })
  set(0, "@function.call", { fg = colors.yellow })
  set(0, "@function.builtin", { fg = colors.yellow })
  set(0, "@method", { fg = colors.yellow })
  set(0, "@method.call", { fg = colors.yellow })
  set(0, "@variable", { fg = colors.cyan })
  set(0, "@variable.builtin", { fg = colors.cyan, italic = true })
  set(0, "@variable.member", { fg = colors.cyan })
  set(0, "@property", { fg = colors.cyan })
  set(0, "@keyword", { fg = colors.blue })
  set(0, "@keyword.function", { fg = colors.blue })
  set(0, "@keyword.return", { fg = colors.purple })
  set(0, "@conditional", { fg = colors.purple })
  set(0, "@repeat", { fg = colors.purple })
  set(0, "@operator", { fg = colors.fg })
  set(0, "@type", { fg = "#4ec9b0" })
  set(0, "@type.builtin", { fg = "#4ec9b0" })
  set(0, "@constant", { fg = colors.light_green })
  set(0, "@constant.builtin", { fg = colors.blue })
  set(0, "@constructor", { fg = "#4ec9b0" })
  set(0, "@tag", { fg = colors.blue })
  set(0, "@tag.attribute", { fg = colors.cyan })
  set(0, "@tag.delimiter", { fg = colors.muted })

  set(0, "NvimTreeNormal", { fg = colors.fg, bg = colors.bg })
  set(0, "NvimTreeNormalNC", { fg = colors.fg, bg = colors.bg })
  set(0, "NvimTreeEndOfBuffer", { fg = colors.bg, bg = colors.bg })
  set(0, "NvimTreeWinSeparator", { fg = colors.bg_alt, bg = colors.bg })
  set(0, "NvimTreeCursorLine", { bg = colors.bg_alt })
  set(0, "NvimTreeFolderName", { fg = colors.cyan })
  set(0, "NvimTreeOpenedFolderName", { fg = colors.cyan, bold = true })
  set(0, "NvimTreeGitDirty", { fg = colors.yellow })
  set(0, "NvimTreeGitNew", { fg = colors.green })
  set(0, "NvimTreeGitDeleted", { fg = colors.red })

  set(0, "TelescopeNormal", { fg = colors.fg, bg = colors.bg })
  set(0, "TelescopeBorder", { fg = colors.bg_alt, bg = colors.bg })
  set(0, "TelescopePromptNormal", { fg = colors.fg, bg = colors.bg })
  set(0, "TelescopePromptBorder", { fg = colors.bg_alt, bg = colors.bg })
  set(0, "TelescopeSelection", { fg = colors.fg, bg = colors.bg_alt })
  set(0, "TelescopeMatching", { fg = colors.yellow, bold = true })
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" },
    },
    config = function()
      require("nvim-tree").setup({
        view = {
          side = "left",
          width = function()
            return math.max(24, math.floor(vim.o.columns * 0.20))
          end,
        },
        renderer = {
          group_empty = true,
          highlight_git = true,
          icons = {
            show = {
              git = true,
              folder = true,
              file = true,
              folder_arrow = true,
            },
          },
        },
        filters = {
          dotfiles = false,
        },
        git = {
          enable = true,
        },
      })

      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.schedule(function()
            require("nvim-tree.api").tree.open()
            vim.cmd("wincmd p")
          end)
        end,
      })
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<C-p>", "<cmd>Telescope find_files hidden=true<cr>", desc = "Find files" },
      { "<leader>ff", "<cmd>Telescope find_files hidden=true<cr>", desc = "Find files" },
      { "<leader>p", "<cmd>Telescope find_files hidden=true<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>/", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Find buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Find help" },
    },
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = {
          prompt_position = "top",
          width = 0.9,
          height = 0.85,
          preview_width = 0.55,
        },
        sorting_strategy = "ascending",
        file_ignore_patterns = {
          "%.git/",
          "node_modules/",
          "tmp/",
        },
      },
      pickers = {
        find_files = {
          hidden = true,
        },
      },
    },
  },
  {
    "joerdav/templ.vim",
    ft = "templ",
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup()
      require("nvim-treesitter").install({
        "bash", "css", "go", "gomod", "gowork", "gosum",
        "html", "javascript", "json", "lua", "markdown",
        "templ", "tsx", "typescript", "vim",
      })
    end,
  },
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = true,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = {
        "gopls",
        "lua_ls",
        "templ",
        "ts_ls",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local bufnr = event.buf

          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end

          map("n", "gd", vim.lsp.buf.definition, "Go to definition")
          map("n", "gr", vim.lsp.buf.references, "References")
          map("n", "K", vim.lsp.buf.hover, "Hover")
          map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
          map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, "Format")
        end,
      })

      local servers = {
        gopls = {},
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = {
                globals = { "vim" },
              },
            },
          },
        },
        templ = {},
        ts_ls = {},
      }

      for server_name, config in pairs(servers) do
        config.capabilities = capabilities
        vim.lsp.config(server_name, config)
        vim.lsp.enable(server_name)
      end
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        go = { "gofmt", "goimports" },
        javascript = { "prettierd", "prettier" },
        javascriptreact = { "prettierd", "prettier" },
        templ = { "templ" },
        typescript = { "prettierd", "prettier" },
        typescriptreact = { "prettierd", "prettier" },
      },
      format_on_save = {
        lsp_fallback = true,
        timeout_ms = 1000,
      },
    },
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        desc = "Format",
      },
    },
  },
})

vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

apply_theme_overrides()
vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter", "WinEnter", "BufEnter" }, {
  callback = apply_theme_overrides,
})
