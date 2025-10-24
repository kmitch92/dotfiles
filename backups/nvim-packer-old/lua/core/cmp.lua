-- lua/core/cmp.lua
-- Autocompletion Configuration

local cmp = require('cmp')
local luasnip = require('luasnip')
local lspkind = require('lspkind')

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  
  mapping = cmp.mapping.preset.insert({
    -- Navigate completion menu
    ['<C-k>'] = cmp.mapping.select_prev_item(),
    ['<C-j>'] = cmp.mapping.select_next_item(),
    
    -- Scroll documentation
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    
    -- Trigger completion
    ['<C-Space>'] = cmp.mapping.complete(),
    
    -- Close completion menu
    ['<C-e>'] = cmp.mapping.abort(),
    
    -- Confirm selection
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    
    -- Tab completion
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },    -- LSP completions
    { name = 'luasnip' },     -- Snippet completions
    { name = 'nvim_lua' },    -- Neovim Lua API
  }, {
    { name = 'buffer' },      -- Buffer completions
    { name = 'path' },        -- Path completions
  }),
  
  formatting = {
    format = lspkind.cmp_format({
      mode = 'symbol_text',
      maxwidth = 50,
      ellipsis_char = '...',
      before = function(entry, vim_item)
        return vim_item
      end
    })
  },
  
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  
  experimental = {
    ghost_text = true,  -- Show ghost text for suggestions
  },
})

-- Use buffer source for `/` and `?` (search)
cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

-- Use cmdline & path source for ':' (command mode)
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  })
})
