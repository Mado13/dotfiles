vim.pack.add({
	{ src = "https://github.com/echasnovski/mini.statusline" },
})

local jj = require("jj_status")
jj.setup()

local ci = require("circleci")

local waka = require("waka_status")
waka.setup()

require("mini.statusline").setup({
	use_icons = true,
	content = {
		active = function()
			local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
			local diff = MiniStatusline.section_diff({ trunc_width = 75 })
			local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
			local lsp = MiniStatusline.section_lsp({ trunc_width = 75 })
			local filename = MiniStatusline.section_filename({ trunc_width = 140 })
			local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = 120 })
			local location = MiniStatusline.section_location({ trunc_width = 75 })
			local search = MiniStatusline.section_searchcount({ trunc_width = 75 })
			-- its own group so the icon can carry its own colour next to the bookmark
			local ci_icon, ci_hl = ci.statusline()

			return MiniStatusline.combine_groups({
				{ hl = mode_hl, strings = { mode } },
				{ hl = "MiniStatuslineDevinfo", strings = { jj.section({ trunc_width = 75 }) } },
				{ hl = ci_hl, strings = { ci_icon } },
				{ hl = "MiniStatuslineDevinfo", strings = { diff, diagnostics, lsp } },
				"%<",
				{ hl = "MiniStatuslineFilename", strings = { filename } },
				"%=",
				{ hl = "MiniStatuslineFileinfo", strings = { waka.section(), fileinfo } },
				{ hl = mode_hl, strings = { search, location } },
			})
		end,
	},
})
