return {
	"echasnovski/mini.surround",
	version = false,
	event = "VeryLazy",
	opts = {},
	config = function(_, opts)
		require("mini.surround").setup(opts)
	end,
}
