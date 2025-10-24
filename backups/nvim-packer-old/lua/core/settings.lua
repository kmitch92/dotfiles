-- lua/core/settings.lua
-- Basic Vim Settings

local opt = vim.opt
local g = vim.g

-- Leader key
g.mapleader = " "
g.maplocalleader = " "

-- Line numbers
opt.number = true                -- Show line numbers
opt.relativenumber = true        -- Show relative line numbers
opt.numberwidth = 4              -- Width of number column

-- Tabs and indentation
opt.tabstop = 2                  -- Number of spaces tabs count for
opt.shiftwidth = 2               -- Size of an indent
opt.expandtab = true             -- Use spaces instead of tabs
opt.autoindent = true            -- Copy indent from current line
opt.smartindent = true           -- Smart autoindenting

-- Line wrapping
opt.wrap = false                 -- Don't wrap lines

-- Search
opt.ignorecase = true            -- Ignore case in search
opt.smartcase = true             -- Case-sensitive if uppercase used
opt.hlsearch = false             -- Don't highlight all search matches
opt.incsearch = true             -- Incremental search

-- Appearance
opt.termguicolors = true         -- True color support
opt.background = "dark"          -- Dark background
opt.signcolumn = "yes"           -- Always show sign column
opt.cursorline = true            -- Highlight current line
opt.scrolloff = 8                -- Lines to keep above/below cursor
opt.sidescrolloff = 8            -- Columns to keep left/right of cursor

-- Splitting
opt.splitright = true            -- Vertical splits to the right
opt.splitbelow = true            -- Horizontal splits below

-- Clipboard
opt.clipboard = "unnamedplus"    -- Use system clipboard

-- Backup and undo
opt.swapfile = false             -- Don't use swapfile
opt.backup = false               -- Don't create backup files
opt.undofile = true              -- Enable persistent undo
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

-- Completion
opt.completeopt = { "menu", "menuone", "noselect" }

-- Update time
opt.updatetime = 250             -- Faster completion
opt.timeoutlen = 300             -- Time to wait for mapped sequence

-- Performance
opt.lazyredraw = false           -- Don't redraw while executing macros

-- Mouse
opt.mouse = "a"                  -- Enable mouse support

-- Backspace
opt.backspace = "indent,eol,start"  -- Allow backspace on indent, eol, start

-- Display
opt.showmode = false             -- Don't show mode (lualine shows it)
opt.showcmd = true               -- Show command in status line
opt.cmdheight = 1                -- Command line height
opt.laststatus = 3               -- Global statusline

-- Folding (using treesitter)
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldenable = false           -- Don't fold by default

-- Wildmenu
opt.wildmenu = true
opt.wildmode = "longest:full,full"

-- Special characters
opt.list = true
opt.listchars = { tab = "→ ", trail = "·", nbsp = "␣" }

-- Performance for large files
opt.synmaxcol = 240              -- Max column for syntax highlight
