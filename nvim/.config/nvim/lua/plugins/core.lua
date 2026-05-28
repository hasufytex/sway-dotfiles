return {
  -- 1. Treesitter (Syntax Highlighting)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      -- Modern rewrite workaround: attempt to load the new config module safely
      local ok, treesitter_config = pcall(require, "nvim-treesitter.config")
      if not ok then
        -- Fallback to old module name if using an older pinned version
        ok, treesitter_config = pcall(require, "nvim-treesitter.configs")
      end

      -- If neither exists yet (because plugin is still downloading), exit cleanly instead of crashing
      if not ok then return end

      treesitter_config.setup({
        ensure_installed = { "lua", "vim", "vimdoc", "query", "javascript", "typescript", "python" },
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- 2. Telescope (Fuzzy Finder)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live Grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find Buffers" })
    end,
  },

  -- 3. Oil.nvim (File Explorer)
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup()
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open Parent Directory" })
    end,
  },
}
