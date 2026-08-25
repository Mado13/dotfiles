vim.pack.add({
	{ src = "https://github.com/dont-be-evil-company/kulala.nvim" },
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
		filetypes = { "http", "rest", "javascript" },
	},
})

-- the openapi panel hardcodes swagger's palette, which is built for a white
-- card on a dark page. Five of the seven verbs land under 4.5:1 here, PATCH at
-- 1.60:1. default = true, so defining them first wins.
local function kulala_method_hl()
	local verbs = {
		Get = "#0031a9", Post = "#006800", Put = "#6f5500", Delete = "#a60000",
		Patch = "#005e8b", Head = "#721045", Options = "#005077",
	}
	for verb, fg in pairs(verbs) do
		vim.api.nvim_set_hl(0, "KulalaOpenAPIMethod" .. verb, { fg = fg, bold = true })
	end
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = kulala_method_hl })
kulala_method_hl()
