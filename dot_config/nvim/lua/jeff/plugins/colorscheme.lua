return {
	"catppuccin/nvim",
	lazy = false,
	name = "catppuccin",
	priority = 1000,
	config = function()
		local catppuccin = require("catppuccin")

		catppuccin.setup({
			flavour = "macchiato",
			transparent_background = false,
			integrations = {
				telescope = {
					enabled = true,
				},
				cmp = true,
				treesitter = true,
				mason = true,
				alpha = true,
				which_key = true,
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
