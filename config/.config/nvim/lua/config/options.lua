-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Soft-wrap long lines instead of letting them run off the right edge.
-- LazyVim defaults to `wrap = false`; toggle per-buffer with <leader>uw.
-- Note: `linebreak = true` is already set by LazyVim, so wrapping breaks at
-- word boundaries rather than mid-word.
vim.opt.wrap = true
vim.opt.breakindent = true -- continuation lines keep the original indentation
vim.opt.showbreak = "↪ " -- marker at the start of each wrapped segment
