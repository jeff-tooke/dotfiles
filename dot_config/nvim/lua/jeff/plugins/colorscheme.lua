return {
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
    priority = 1000,
    config = function()
      local catppuccin = require("catppuccin")

      catppuccin.setup({
	      flavour = "macchiato",
        transparent_background = true,
        integrations = {
          telescope = true,
        },
	      dim_inactive = {
	        enabled = true,
	        shade = "dark",
	        percentage = 0.15,
	      },
    })
    vim.cmd.colorscheme("catppuccin")
  end,
}
