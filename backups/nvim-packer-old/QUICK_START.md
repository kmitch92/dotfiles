# Neovim Configuration Quick Reference

## 🎨 What Was Added

### Settings (`lua/core/settings.lua`)
- ✅ **Line numbers** (with relative numbers)
- ✅ **Syntax highlighting** (via Treesitter)
- ✅ **True colors**
- ✅ **Cursor line highlighting**
- ✅ **Smart indentation** (2 spaces)
- ✅ **System clipboard integration**
- ✅ **Mouse support**
- ✅ **Persistent undo**
- ✅ **Better search** (smart case)
- ✅ **No swap files**

### Visual Features
- Line numbers on the left
- Relative line numbers for easy jumping
- Current line highlighted
- Sign column for LSP diagnostics
- Status line (lualine) at bottom
- Special characters visible (tabs, trailing spaces)

## 🎹 Essential Keybindings

### Leader Key
- `<Space>` is your leader key

### File Navigation
- `-` - Open file explorer (netrw)
- `<leader>ff` - Find files (Telescope)
- `<leader>fg` - Live grep (search in files)
- `<leader>fb` - Find buffers
- `<leader>fh` - Help tags

### Window Management
- `<C-h>` - Go to left window
- `<C-j>` - Go to lower window
- `<C-k>` - Go to upper window
- `<C-l>` - Go to right window
- `<C-arrows>` - Resize windows

### Buffer Navigation
- `Shift-l` - Next buffer
- `Shift-h` - Previous buffer

### Editing
- `<leader>w` - Save file
- `<leader>q` - Quit
- `<leader>h` - Clear search highlighting
- `<leader>u` - Toggle undo tree

### Visual Mode
- `J` / `K` - Move selected text up/down
- `<` / `>` - Indent left/right (stays in visual mode)

### LSP (Code Intelligence)
- `gd` - Go to definition
- `K` - Hover documentation
- `gr` - Find references
- `<leader>rn` - Rename symbol
- `<leader>ca` - Code actions
- `<leader>f` - Format document
- `[d` / `]d` - Navigate diagnostics

### Completion
- `<C-Space>` - Trigger completion
- `<Tab>` - Next item / expand snippet
- `<Shift-Tab>` - Previous item
- `<Enter>` - Confirm selection
- `<C-e>` - Close menu

## 🚀 First Time Setup

1. **Open Neovim:**
   ```bash
   nvim
   ```

2. **Wait for Packer** to install plugins (automatic)

3. **Restart Neovim**

4. **Check everything works:**
   - You should see line numbers
   - Colors should be visible
   - Status line at the bottom
   - LSP should work in code files

## 🔧 File Structure

```
~/.config/nvim/
├── init.lua                       # Main entry point
├── lua/
│   └── core/
│       ├── settings.lua           # All vim options
│       ├── mappings.lua           # Keybindings
│       ├── plugins.lua            # Plugin list (Packer)
│       ├── lsp.lua                # LSP configuration
│       ├── cmp.lua                # Completion
│       ├── lualine-config.lua     # Status line
│       └── treesitter-config.lua  # Syntax highlighting
```

## 🎨 Color Scheme

Currently using **Evergarden** (dark theme). To change:

Edit `init.lua`:
```lua
vim.cmd.colorscheme "your-theme-name"
```

Popular alternatives (install via Packer first):
- `catppuccin` - Modern, pastel
- `tokyonight` - Clean, popular
- `gruvbox` - Classic, warm
- `nord` - Cool, minimal

## 💡 Useful Commands

### Packer (Plugin Manager)
- `:PackerSync` - Install/update plugins
- `:PackerStatus` - See plugin status
- `:PackerClean` - Remove unused plugins

### Mason (LSP Installer)
- `:Mason` - Open Mason UI
- `:MasonInstall <name>` - Install language server

### Treesitter (Syntax)
- `:TSInstall <language>` - Install parser
- `:TSUpdate` - Update all parsers

### LSP
- `:LspInfo` - Show LSP status
- `:LspRestart` - Restart LSP

### General
- `:checkhealth` - Check Neovim health
- `:help <topic>` - Get help
- `:q!` - Quit without saving
- `:wq` - Save and quit

## 🐛 Troubleshooting

### No colors?
1. Make sure your terminal supports true colors
2. Check: `:echo has('termguicolors')`
3. Should return `1`

### No line numbers?
1. Run `:set number?` 
2. Should show `number`
3. If not, check `settings.lua` loaded correctly

### LSP not working?
1. Check status: `:LspInfo`
2. Install server: `:Mason`
3. Restart: `:LspRestart`

### Completion not showing?
1. In insert mode, press `<C-Space>`
2. Check: `:echo &completeopt`
3. Should include `menu,menuone,noselect`

## 📚 Learning Resources

- `:Tutor` - Built-in Neovim tutorial
- `:help` - Comprehensive help system
- `:help nvim` - Neovim-specific help

## 🎯 Next Steps

1. **Get comfortable** with basic navigation
2. **Learn LSP keybindings** (`gd`, `K`, `gr`)
3. **Use Telescope** for file finding (`<leader>ff`)
4. **Try completion** (just start typing in a code file)
5. **Customize** to your liking!

## 💻 Quick Test

Open a TypeScript file and test LSP:

```bash
nvim test.ts
```

Type:
```typescript
function hello(name: string) {
  console.log("Hello " + name);
}

hello("world");
```

- Hover over `hello` and press `K` - see docs
- Put cursor on `hello` and press `gd` - go to definition
- Type `console.` and see completions!
