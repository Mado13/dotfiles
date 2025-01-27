return {
	"mistweaverco/kulala.nvim",
	ft = { "http", "json" },
	config = function()
		require("kulala").setup({})
	end,
}
