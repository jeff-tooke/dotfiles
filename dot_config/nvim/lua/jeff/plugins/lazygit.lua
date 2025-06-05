return {
  "kdheepak/lazygit.nvim",
  lazy = false,
  cmd = {
    "Lazygit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },

  dependencies = {
    "nvim-lua/plenary.nvim",
  },

  config = function()
    vim.g.lazygit_floating_window_scaling_factor = 0.75
    vim.g.lazygit_floating_window_winblend = 10
  end,

  keys = {
    { "<leader>gg", "<cmd>LazyGit<cr>", desc = "Open lazy git" },
  },
}
