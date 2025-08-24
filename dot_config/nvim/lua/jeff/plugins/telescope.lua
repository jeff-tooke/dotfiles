return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local telescope = require "telescope"
      telescope.setup {
        defaults = {
          path_display = { "smart" },
          preview = false,
          layout_strategy = "center",
          layout_config = {
            width = 0.75,
            height = 0.75,
          },
          hidden = true,
          no_ignore = false,
          file_ignore_patterns = {
            "node_modules/.*",
            ".git/.*",
            "%.DS_Store",
            "%.pyc",
            "__pycache__/.*",
          },
        },
        pickers = {
          find_files = {
            hidden = true,
          },
        },
      }
      telescope.load_extension "fzf"
      local keymap = vim.keymap
      keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files in current directory" })
      keymap.set("n", "<leader>fc", function()
        require("telescope.builtin").find_files { cwd = vim.fn.stdpath "config" }
      end, { desc = "Find config file" })
      keymap.set("n", "<leader><space>", "<cmd>Telescope find_files<cr>", { desc = "Find files in current directory" })
      keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Find recent files" })
      keymap.set("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", { desc = "Find keymaps" })
      keymap.set("n", "<leader>/", "<cmd>Telescope live_grep<cr>", { desc = "Find string in current directory" })
      keymap.set("n", "<leader>,", "<cmd>Telescope buffers<cr>", { desc = "Find open buffers" })
      keymap.set("n", "<leader>:", "<cmd>Telescope command_history<cr>", { desc = "Find recently executed commands" })
      keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags <cr>", { desc = "Find help tags" })
      keymap.set("n", "<leader>fm", "<cmd>Telescope man_pages<cr>", { desc = "Find man pages" })
    end,
  },
}
