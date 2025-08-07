return {
  "catppuccin/nvim",
  lazy = false,
  name = "catppuccin",
  priority = 1000,
  config = function()
    local catppuccin = require "catppuccin"

    catppuccin.setup {
      flavour = "macchiato",
      transparent_background = true,
      float = {
        transparent = true,
        solid = true,
      },
      auto_integrations = true,
    }
    vim.cmd.colorscheme "catppuccin"
  end,
}
