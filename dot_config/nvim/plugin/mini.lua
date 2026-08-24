vim.pack.add({
	{ src = "https://github.com/echasnovski/mini.icons" },
	{ src = "https://github.com/echasnovski/mini.bufremove" },
	{ src = "https://github.com/echasnovski/mini.ai" },
	{ src = "https://github.com/echasnovski/mini.surround" },
	{ src = "https://github.com/echasnovski/mini.indentscope" },
	{ src = "https://github.com/echasnovski/mini.notify" },
})

require("mini.icons").setup({
	-- slim is a ruby templating lang, group it with the rest of the rails stack
	extension = { slim = { glyph = "", hl = "MiniIconsRed" } },
	filetype = { slim = { glyph = "", hl = "MiniIconsRed" } },
})
require("mini.bufremove").setup()
require("mini.indentscope").setup({
	symbol = "│",
	options = { try_as_border = true },
})

local ai = require("mini.ai")
ai.setup({
	n_lines = 500,
	custom_textobjects = {
		f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
		c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
	},
})

require("mini.surround").setup()

require("mini.notify").setup({
	-- lsp_progress off: this takes over vim.notify globally, and every server's
	-- progress spinner would land in the corner as a notification
	lsp_progress = { enable = false },
	content = {
		-- default prepends a timestamp, which is noise for a toast that lives 4s
		format = function(notif)
			return notif.msg
		end,
	},
	window = {
		winblend = 0, -- opaque, the default 25 muddies text over code
		max_width_share = 0.45,
	},
})

-- make_notify's signature is (msg, level) only, a third opts arg is dropped
vim.notify = require("mini.notify").make_notify({
	ERROR = { duration = 7000, hl_group = "DiagnosticError" },
	WARN = { duration = 6000, hl_group = "DiagnosticWarn" },
	INFO = { duration = 4000, hl_group = "DiagnosticInfo" },
})
