# Neovim LSP Setup Guide

This Neovim configuration includes a complete LSP setup with Mason for easy language server management.

## 🚀 Quick Start

1. **Open Neovim** and let Packer install all plugins:
   ```bash
   nvim
   ```

2. **Wait for Packer** to install all plugins (happens automatically on first run)

3. **Open Mason** to see installed language servers:
   ```
   :Mason
   ```

4. **Restart Neovim** and you're ready to code!

## 📦 What's Included

### Language Servers (Auto-installed)
- **TypeScript/JavaScript** (`ts_ls`)
- **Lua** (`lua_ls`) - configured for Neovim development
- **Python** (`pyright`)
- **HTML** (`html`)
- **CSS** (`cssls`)
- **JSON** (`jsonls`)
- **YAML** (`yamlls`)
- **Bash** (`bashls`)
- **GraphQL** (`graphql`)

### Features
- ✅ **Syntax highlighting** (via Treesitter)
- ✅ **Code completion** (via nvim-cmp)
- ✅ **Go to definition**
- ✅ **Hover documentation**
- ✅ **Find references**
- ✅ **Rename symbols**
- ✅ **Code actions**
- ✅ **Diagnostics/Linting**
- ✅ **Auto-formatting**

## ⌨️ Keybindings

### LSP Actions
- `gd` - Go to definition
- `K` - Show hover documentation
- `gr` - Find references
- `<leader>rn` - Rename symbol
- `<leader>ca` - Code actions
- `<leader>d` - Show diagnostics
- `[d` - Go to previous diagnostic
- `]d` - Go to next diagnostic
- `<leader>f` - Format document

### Completion
- `<C-Space>` - Trigger completion
- `<Tab>` - Next completion / expand snippet
- `<S-Tab>` - Previous completion
- `<CR>` (Enter) - Confirm selection
- `<C-j>` - Next item
- `<C-k>` - Previous item
- `<C-e>` - Close completion menu

## 🛠️ Managing Language Servers

### Open Mason UI
```vim
:Mason
```

In Mason:
- `i` - Install server under cursor
- `u` - Update server under cursor
- `X` - Uninstall server under cursor
- `?` - Show help

### Install Additional Servers
```vim
:MasonInstall <server-name>
```

Examples:
```vim
:MasonInstall rust_analyzer
:MasonInstall gopls
:MasonInstall tailwindcss
```

### List All Available Servers
```vim
:Mason
```
Then press `2` to see all available servers.

## 📝 Common Language Servers

Add these to `lua/core/lsp.lua` if you need them:

### Rust
```lua
lspconfig.rust_analyzer.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})
```

### Go
```lua
lspconfig.gopls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})
```

### Java
```lua
lspconfig.jdtls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})
```

### C/C++
```lua
lspconfig.clangd.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})
```

### Vue
```lua
lspconfig.volar.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})
```

### React/TypeScript
TypeScript server (`ts_ls`) already handles React files!

## 🎨 Customization

### Change Leader Key
Edit `lua/core/mappings.lua`:
```lua
vim.g.mapleader = " "  -- Space is the default
```

### Add More Language Servers
1. Open `lua/core/lsp.lua`
2. Add server name to `ensure_installed` list
3. Add configuration below:
```lua
lspconfig.your_server.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})
```

### Modify Completion Behavior
Edit `lua/core/cmp.lua` to customize:
- Completion sources order
- Keybindings
- Appearance
- Ghost text settings

## 🐛 Troubleshooting

### LSP not working?
1. Check if server is installed:
   ```vim
   :Mason
   ```

2. Check LSP status:
   ```vim
   :LspInfo
   ```

3. Restart LSP:
   ```vim
   :LspRestart
   ```

### Completion not showing?
1. Make sure you're in insert mode
2. Press `<C-Space>` to manually trigger
3. Check if LSP is attached:
   ```vim
   :LspInfo
   ```

### Treesitter issues?
Update parsers:
```vim
:TSUpdate
```

### Start fresh?
Remove Packer and reinstall:
```bash
rm -rf ~/.local/share/nvim/site/pack/packer
nvim
:PackerSync
```

## 📚 File Structure

```
~/.config/nvim/
├── init.lua                    # Main config
├── lua/
│   └── core/
│       ├── plugins.lua         # Plugin management (Packer)
│       ├── lsp.lua             # LSP configuration
│       ├── cmp.lua             # Completion configuration
│       └── mappings.lua        # Keybindings
└── after/
    └── plugin/
        └── treesitter.lua      # Treesitter config
```

## 🔄 Updating

### Update Plugins
```vim
:PackerUpdate
```

### Update Mason Packages
```vim
:MasonUpdate
```

### Update Treesitter Parsers
```vim
:TSUpdate
```

## 💡 Tips

1. **Learn your LSP**: Hover over errors with `K` to see what's wrong
2. **Use code actions**: `<leader>ca` can auto-fix many issues
3. **Format on save**: Add this to init.lua:
   ```lua
   vim.api.nvim_create_autocmd("BufWritePre", {
     pattern = "*",
     callback = function()
       vim.lsp.buf.format()
     end,
   })
   ```

## 🆘 Getting Help

- `:help lsp`
- `:help nvim-cmp`
- `:help mason`
- `:checkhealth` - Run health checks

## 🔗 Useful Resources

- [Mason.nvim](https://github.com/williamboman/mason.nvim)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
- [List of LSP servers](https://github.com/williamboman/mason-lspconfig.nvim#available-lsp-servers)
