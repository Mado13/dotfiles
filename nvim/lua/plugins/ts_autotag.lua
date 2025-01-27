return {
	{
		"windwp/nvim-ts-autotag",
		dependencies = "nvim-treesitter/nvim-treesitter",
		config = function()
			require("nvim-ts-autotag").setup({
        aliases = {
          heex = "html",
        },
				filetypes = {
					"html",
					"heex",
					"xml",
					"eruby",
					"embedded_template",
					"javascript",
					"javascriptreact",
					"typescriptreact",
				},
			})
		end,
		lazy = true,
		event = "VeryLazy",
	},
}
