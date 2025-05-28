return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		local themes = require("telescope.themes")

		-- Base dropdown config (no previewer)
		local dropdown_theme = themes.get_dropdown({
			previewer = false,
			winblend = 10,
			width = 0.8,
			hidden = true,
		})

		-- Custom dropdown with previewer for live_grep
		local dropdown_with_preview = themes.get_dropdown({
			previewer = true,
			winblend = 10,
			width = 0.8,
			hidden = true,
		})
		telescope.setup({
			defaults = {
				path_display = { "relative" },
				file_ignore_patterns = { "/.git/" },
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous,
						["<C-j>"] = actions.move_selection_next,
					},
				},
			},
			pickers = {
				find_files = dropdown_theme,
				oldfiles = dropdown_theme,
				buffers = dropdown_theme,
				help_tags = dropdown_theme,
				live_grep = dropdown_with_preview,
			},
		})

		telescope.load_extension("fzf")

		-- set keymaps
		local keymap = vim.keymap

		keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
		keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Find recent files" })
		keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string" })
		keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Find buffers" })
		keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Find help" })
	end,
}
