return {
	{
		"slim-template/vim-slim",
		ft = "slim", -- Only load for .slim files
		event = { "BufReadPre", "BufNewFile" }, -- Load when needed
		lazy = true, -- Enable lazy loading (default is already true in Lazy.nvim)
	},
}
