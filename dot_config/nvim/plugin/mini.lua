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

-- mini.notify paints the whole body with one group, and modus bolds every
-- Diagnostic*. DiagnosticInfo is chroma 101, so an FYI arrived as a wall of bold
-- navy. Own groups instead: info is plain text, only warn and error carry colour.
local function notify_hl()
	vim.api.nvim_set_hl(0, "NotifyInfo", { fg = "#000000" })
	vim.api.nvim_set_hl(0, "NotifyWarn", { fg = "#6f5500" })
	vim.api.nvim_set_hl(0, "NotifyError", { fg = "#a60000" })
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = notify_hl })
notify_hl()

-- make_notify's signature is (msg, level) only, a third opts arg is dropped
vim.notify = require("mini.notify").make_notify({
	ERROR = { duration = 7000, hl_group = "NotifyError" },
	WARN = { duration = 6000, hl_group = "NotifyWarn" },
	INFO = { duration = 4000, hl_group = "NotifyInfo" },
})
