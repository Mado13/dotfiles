vim.pack.add({
	{ src = "https://github.com/mistweaverco/kulala.nvim" },
})

vim.filetype.add({
	extension = {
		http = "http",
		rest = "rest",
	},
})

require("kulala").setup({
	global_keymaps = true,
	global_keymaps_prefix = "<leader>R",

	-- "b" keeps the picked env per buffer, so a second .http file silently
	-- falls back to `default` and you fire staging requests at prod
	environment_scope = "g",

	ui = {
		display_mode = "split",
		split_direction = "right",
		win_opts = {
			wo = { wrap = true, number = false, signcolumn = "no" },
		},
		-- 32k default truncates any real index endpoint
		max_response_size = 512 * 1024,
		scratchpad_default_contents = {
			"@base = http://localhost:3000",
			"",
			"# @name scratch",
			"GET {{base}}/",
			"accept: application/json",
			"",
		},
	},

	lsp = {
		-- default also attaches to every lua buffer for *.http.lua scripting
		filetypes = { "http", "rest", "javascript", "typescript" },
	},
})
