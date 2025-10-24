-- lua/core/lsp.lua
-- LSP Configuration with Mason

-- Setup Mason first
require('mason').setup({
  ui = {
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗"
    }
  }
})

-- Setup mason-lspconfig to bridge Mason and lspconfig
require('mason-lspconfig').setup({
  -- Automatically install these language servers
  ensure_installed = {
    'ts_ls',        -- TypeScript/JavaScript
    'lua_ls',          -- Lua
    'pyright',         -- Python
    'html',            -- HTML
    'cssls',           -- CSS
    'jsonls',          -- JSON
    'yamlls',          -- YAML
    'bashls',          -- Bash
    'graphql',         -- GraphQL
  },
  automatic_installation = true,
})

-- Setup completion capabilities
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- LSP keybindings
local on_attach = function(client, bufnr)
  local opts = { buffer = bufnr, remap = false }

  -- Go to definition
  vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
  
  -- Hover documentation
  vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
  
  -- Find references
  vim.keymap.set("n", "gr", function() vim.lsp.buf.references() end, opts)
  
  -- Rename symbol
  vim.keymap.set("n", "<leader>rn", function() vim.lsp.buf.rename() end, opts)
  
  -- Code actions
  vim.keymap.set("n", "<leader>ca", function() vim.lsp.buf.code_action() end, opts)
  
  -- Show diagnostics
  vim.keymap.set("n", "<leader>d", function() vim.diagnostic.open_float() end, opts)
  
  -- Go to next/previous diagnostic
  vim.keymap.set("n", "[d", function() vim.diagnostic.goto_prev() end, opts)
  vim.keymap.set("n", "]d", function() vim.diagnostic.goto_next() end, opts)
  
  -- Format document
  vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format() end, opts)
end

-- Configure each language server
local lspconfig = require('lspconfig')

-- TypeScript/JavaScript
lspconfig.ts_ls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- Lua (with special Neovim settings)
lspconfig.lua_ls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' }  -- Recognize vim global
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      telemetry = {
        enable = false,
      },
    },
  },
})

-- Python
lspconfig.pyright.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- HTML
lspconfig.html.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- CSS
lspconfig.cssls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- JSON
lspconfig.jsonls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- YAML
lspconfig.yamlls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- Bash
lspconfig.bashls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- GraphQL
lspconfig.graphql.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- Diagnostic settings
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  update_in_insert = false,
  underline = true,
  severity_sort = true,
  float = {
    border = 'rounded',
    source = 'always',
  },
})

-- Diagnostic signs
local signs = { Error = "✗ ", Warn = "⚠ ", Hint = "💡", Info = "ℹ " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end
