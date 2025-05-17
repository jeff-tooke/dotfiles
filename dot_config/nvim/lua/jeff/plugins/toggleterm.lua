return {
  "akinsho/toggleterm.nvim",
  version = "*",

  config = function()
    local toggleterm = require "toggleterm"

    toggleterm.setup {
      direction = "vertical",
      start_in_insert = true,
      close_on_exit = true,
      shell = vim.o.shell,
    }

    --set keymaps
    local keymap = vim.keymap

    keymap.set("n", "<leader>t", "<cmd>ToggleTerm direction=vertical<cr>", { desc = "Toggle vertical terminal" })
    keymap.set("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", { desc = "Toggle horizontal terminal" })
    keymap.set("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", { desc = "Toggle floating terminal" })
    keymap.set("n", "<leader>tt", "<cmd>ToggleTerm direction=tab<cr>", { desc = "Toggle tabbed terminal" })
  end,
}
