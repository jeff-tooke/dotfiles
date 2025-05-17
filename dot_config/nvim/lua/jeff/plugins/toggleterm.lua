return {
	"akinsho/toggleterm.nvim",
	version = "*",

	config = function()
		local toggleterm = require("toggleterm")

		toggleterm.setup({
			direction = "vertical",
			start_in_insert = true,
			close_on_exit = true,
			shell = vim.o.shell,
			size = function(term)
				if term.direction == "horizontal" then
					return 15
				elseif term.direction == "vertical" then
					return math.floor(vim.o.columns * 0.5)
				end
			end,
		})

		--set keymaps
		local keymap = vim.keymap

		keymap.set("n", "<leader>t", "<cmd>ToggleTerm direction=vertical<cr>", { desc = "Toggle vertical terminal" })
	end,
}
