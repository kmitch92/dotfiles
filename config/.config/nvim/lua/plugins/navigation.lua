-- Simple, effective navigation keymaps.
-- The telescope + neo-tree LazyVim extras wire most defaults already;
-- here we configure neo-tree to follow the current file and re-assert a
-- small, opinionated set of movement keymaps.
return {
  -- Configure neo-tree to follow the current file and watch the filesystem.
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
      },
    },
    -- stylua: ignore
    keys = {
      {
        "<leader>e",
        function()
          require("neo-tree.command").execute({ toggle = true, reveal = true, dir = require("lazyvim.util").root() })
        end,
        desc = "Explorer NeoTree (reveal current file)",
      },
      {
        "<leader>o",
        function()
          require("neo-tree.command").execute({ action = "focus" })
        end,
        desc = "Focus NeoTree",
      },
    },
  },

  -- Telescope movement keymaps (root-relative where it matters).
  {
    "nvim-telescope/telescope.nvim",
    -- stylua: ignore
    keys = {
      { "<leader><space>", function() require("telescope.builtin").find_files({ cwd = require("lazyvim.util").root() }) end, desc = "Find Files (root)" },
      { "<leader>/",       function() require("telescope.builtin").live_grep({ cwd = require("lazyvim.util").root() }) end,  desc = "Live Grep (root)" },
      { "<leader>,",       "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>",                                   desc = "Buffers" },
      { "<leader>fr",      "<cmd>Telescope oldfiles<cr>",                                                                   desc = "Recent Files" },
    },
  },
}
