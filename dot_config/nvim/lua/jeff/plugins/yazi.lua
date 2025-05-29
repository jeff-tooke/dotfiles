return {
  "mikavilpas/yazi.nvim",
  event = "VeryLazy",
  dependencies = {
    "folke/snacks.nvim",
    keys = {
      { "<leader>fe", mode = { "n", "v" }, "<cmd>Yazi cwd<cr>", desc = "Open file manager in current working directory" },
      { "<leader>-", mode = { "n", "v" }, "<cmd>Yazi<cr>", desc = "Open file manager at current file" },
      { "<c-up>", "<cmd>Yazi toggle<cr>", desc = "Resume the last file manager session" },
    },
  },
  opts = {
    open_for_directories = true,
    floating_window_scaling_factor = 0.75,
    yazi_floating_window_winblend = 10,
  },
  init = function()
    vim.g.loaded_netrwPlugin = 1
  end,
}
