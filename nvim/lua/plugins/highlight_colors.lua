return {
	"norcalli/nvim-colorizer.lua",
	config = function()
		require("colorizer").setup({
			"*", -- Highlight all files, replace with specific file types if needed
		}, {
			mode = "foreground", -- Set the colorization mode to foreground
		})
	end,
}
