-- ============================================================================
-- Neovim Configuration
-- ============================================================================

-- Load settings first (line numbers, colors, etc.)
require("core.settings")

-- Load keybindings
require("core.mappings")

-- Load plugins (Packer)
require("core.plugins")

-- Set colorscheme
vim.cmd.colorscheme "evergarden"

-- Load plugin configurations
require("core.lualine-config")
require("core.treesitter-config")
require("core.lsp")
require("core.cmp")
