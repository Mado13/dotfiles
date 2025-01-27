local m = require("util.utils").lazy_map

local opts = {
	signs = true,
	sign_priority = 8,
	keywords = {
		FIX = {
			icon = " ",
			color = "error",
			alt = { "FIXME", "BUG", "FIXIT", "ISSUE" },
		},
		TODO = { icon = " ", color = "info" },
		HACK = { icon = " ", color = "warning" },
		WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
		PERF = { icon = " ", color = "#e78a4e", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
		NOTE = { icon = " ", color = "hint", alt = { "INFO", "QUESTION" } },
		TEST = { icon = "⏲ ", color = "test" },
		REF = { icon = "", color = "warning" },
	},
	gui_style = {
		fg = "NONE", -- The gui style to use for the fg highlight group.
		bg = "BOLD", -- The gui style to use for the bg highlight group.
	},
	merge_keywords = true,
	highlight = {
		before = "",
		keyword = "wide",
		after = "fg",
		comments_only = true,
		max_line_len = 400,
		exclude = {},
	},
	colors = {
		error = { "DiagnosticError", "ErrorMsg", "#ea6962" },
		warning = { "DiagnosticWarning", "WarningMsg", "#d8a657" },
		info = { "DiagnosticInfo", "#7daea3" },
		hint = { "DiagnosticHint", "#d3869b" },
		default = { "Identifier", "#e78a4e" },
		test = { "Identifier", "#FF00FF" },
	},
	search = {
		command = "rg",
		args = {
			"--color=never",
			"--no-heading",
			"--with-filename",
			"--line-number",
			"--column",
		},
		pattern = [[\b(KEYWORDS):]],
	},
}

return {
	"folke/todo-comments.nvim",
	opts = opts,
	event = "BufReadPre",
	keys = {
		m("<leader>tr", [[TodoQuickFix]]),
	},
	dependencies = "nvim-lua/plenary.nvim",
}
