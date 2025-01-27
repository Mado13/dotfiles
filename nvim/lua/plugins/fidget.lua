return {
	{
		"j-hui/fidget.nvim",
		tag = "legacy",
		event = { "BufEnter" },
		config = function()
			require("fidget").setup({
				notification = {
					window = {
						winblend = 0,
					},
				},
				text = {
					spinner = "dots_negative",
				},
			})
		end,
	},
}
