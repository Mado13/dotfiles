vim.pack.add({
	{ src = "https://github.com/rafamadriz/friendly-snippets" },
	{ src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.*") },
})

require("blink.cmp").setup({
	keymap = { preset = "default" },
	appearance = { nerd_font_variant = "mono" },
	completion = {
		documentation = { auto_show = false, auto_show_delay_ms = 500 },
	},
	sources = {
		default = { "lsp", "path", "snippets" },
	},
	fuzzy = { implementation = "prefer_rust" },
	signature = { enabled = true },
	cmdline = {
		completion = {
			-- blink only auto-shows the cmdline menu in the command-line window by
			-- default. At the ":" prompt you get ghost text and have to ask for the
			-- rest, which is the half that felt missing.
			menu = { auto_show = true },
		},
	},
})
