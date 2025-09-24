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
-- hello
local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use) use 'wbthomason/packer.nvim'
	-- My plugins here
	use { 'nvim-telescope/telescope.nvim', tag = '0.1.8',
	-- or                            , branch = '0.1.x',
	requires = { {'nvim-lua/plenary.nvim'} } }
	use({ 'everviolet/nvim' })
	use( 'nvim-treesitter/nvim-treesitter',{ run = ':TSUpdate' })
	use { "jiaoshijie/undotree" }
	use ({ "neovim/nvim-lspconfig" 
    --		config = [[require('config.lsp')]], -- this line may very based on your config
	})
	use ({
	  "hrsh7th/nvim-cmp",
	  requires = {
	   "hrsh7th/cmp-buffer",
	   "hrsh7th/cmp-nvim-lsp",
	   "hrsh7th/cmp-path",
	   "hrsh7th/cmp-nvim-lua",
	   "L3MON4D3/LuaSnip", -- may very based on config
	   "onsails/lspkind-nvim",
	  }
	 })
	 use 'nvim-tree/nvim-web-devicons'
	 use {
		 'nvim-lualine/lualine.nvim',
		 requires = { 'nvim-tree/nvim-web-devicons', opt = true }
		}
	 use({
 		"shrynx/line-numbers.nvim",
  		config = function()
    		require("line-numbers").setup({})
 		end
		})
--	use { 'tpope/commentary' }
--	use { 'airblade/gitgutter' }
		-- Automatically set up your configuration after cloning
		-- packer.nvim Put this at the end after all plugins
	if packer_bootstrap then require('packer').sync() end end)
