return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		"MunifTanjim/nui.nvim",
		"rcarriga/nvim-notify",
	},
	config = function()
		require("noice").setup({
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},
			presets = {
				bottom_search = true,
				command_palette = false, -- <== turn this off
				long_message_to_split = true,
				inc_rename = false,
				lsp_doc_border = false,
			},
			views = {
				cmdline_popup = {
					position = {
						row = "35%",
						col = "50%",
					},
					size = {
						width = 60,
						height = "auto",
					},
				},
				cmdline_popupmenu = {
					position = {
						row = "45%",
						col = "50%",
					},
					size = {
						width = 60,
						height = "auto",
						max_height = 15,
					},
				},
			},
		})
	end,
}
