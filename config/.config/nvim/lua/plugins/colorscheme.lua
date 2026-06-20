-- Gruvbox colorscheme, matched to terminal "Gruvbox Dark Hard".
return {
  -- Install and configure gruvbox.
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      contrast = "hard", -- matches terminal Gruvbox Dark Hard
      transparent_mode = false,
      bold = true,
      italic = {
        strings = false,
        comments = true,
        operators = false,
        folds = true,
      },
      undercurl = true,
      underline = true,
      strikethrough = true,
      invert_selection = false,
      invert_signs = false,
      invert_tabline = false,
      invert_intend_guides = false,
      inverse = true,
      dim_inactive = false,
    },
  },

  -- Tell LazyVim to use gruvbox as the active colorscheme.
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
