local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  
  -- Telescope (fuzzy finder)
  use {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  
  -- Color scheme
  use 'everviolet/nvim'
  
  -- Treesitter (syntax highlighting)
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate'
  }
  
  -- Undo tree
  use 'jiaoshijie/undotree'
  
  -- LSP Configuration
  use 'neovim/nvim-lspconfig'
  
  -- Mason: Easy LSP server installation
  use {
    'williamboman/mason.nvim',
    run = ':MasonUpdate'
  }
  use 'williamboman/mason-lspconfig.nvim'
  
  -- Autocompletion
  use {
    'hrsh7th/nvim-cmp',
    requires = {
      'hrsh7th/cmp-buffer',       -- Buffer completions
      'hrsh7th/cmp-nvim-lsp',     -- LSP completions
      'hrsh7th/cmp-path',         -- Path completions
      'hrsh7th/cmp-nvim-lua',     -- Neovim Lua API completions
      'L3MON4D3/LuaSnip',         -- Snippet engine
      'saadparwaiz1/cmp_luasnip', -- Snippet completions
      'onsails/lspkind-nvim',     -- VS Code-like pictograms
    }
  }
  
  -- UI
  use 'nvim-tree/nvim-web-devicons'
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'nvim-tree/nvim-web-devicons', opt = true }
  }
  use {
    'shrynx/line-numbers.nvim',
    config = function()
      require('line-numbers').setup({})
    end
  }
  
  -- Automatically set up your configuration after cloning packer.nvim
  if packer_bootstrap then
    require('packer').sync()
  end
end)
