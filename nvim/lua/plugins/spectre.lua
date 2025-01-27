return {
	{
		"nvim-pack/nvim-spectre",
		lazy = true,
		cmd = { "Spectre" },
		dependencies = {
			"nvim-lua/plenary.nvim",
			"catppuccin/nvim",
		},
		config = function()
			local configuration = vim.fn["gruvbox_material#get_configuration"]()
			local palette = vim.fn["gruvbox_material#get_palette"](
				configuration.background,
				configuration.foreground,
				configuration.colors_override
			)

			vim.api.nvim_set_hl(0, "SpectreSearch", { bg = palette.red[1] })
			vim.api.nvim_set_hl(0, "SpectreReplace", { bg = palette.green[1] })

			require("spectre").setup({
				highlight = {
					search = "SpectreSearch",
					replace = "SpectreReplace",
				},
				mapping = {
					["send_to_qf"] = {
						map = "<C-q>",
						cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
						desc = "send all items to quickfix",
					},
				},
				replace_engine = {
					sed = {
						cmd = "sed",
					},
				},
			})
		end,
	},
}
