return {
	{
		"sainnhe/gruvbox-material",
		lazy = false,
		priority = 1000,
		config = function()
			vim.g.gruvbox_material_background = "soft"
			vim.g.gruvbox_material_foreground = "mix"
			vim.g.gruvbox_material_enable_italic = 1
			vim.g.gruvbox_material_disable_italic_comment = 0
			vim.g.gruvbox_material_better_performance = 1
			vim.g.gruvbox_material_current_word = "grey background"
			vim.g.gruvbox_material_diagnostic_line_highlight = 1
			vim.g.gruvbox_material_diagnostic_text_highlight = 1
			vim.g.gruvbox_material_diagnostic_virtual_text = "colored"
			vim.g.gruvbox_material_enable_bold = 0

			local palette = {
				bg0 = "#32302f",
				bg1 = "#3c3836",
				bg2 = "#45403d",
				bg3 = "#504945",
				bg4 = "#5a524c",
				bg5 = "#665c54",
				bg_visual = "#503946",
				bg_red = "#4e3e43",
				bg_green = "#404d44",
				bg_blue = "#394f5a",
				bg_yellow = "#4a4940",

				fg0 = "#e2cca9",
				fg1 = "#e2cca9",
				fg2 = "#e2cca9",
				fg3 = "#e2cca9",
				fg4 = "#e2cca9",

				red = "#f2594b",
				orange = "#f28534",
				yellow = "#e9b143",
				green = "#b0b846",
				aqua = "#8bba7f",
				blue = "#80aa9e",
				purple = "#d3869b",

				grey0 = "#7c6f64",
				grey1 = "#928374",
				grey2 = "#a89984",
			}

			vim.g.gruvbox_material_custom_colors = {
				bg_dim = palette.bg0,
				fg0 = palette.fg0,
				fg1 = palette.fg1,
				grey0 = palette.grey0,
				grey1 = palette.grey1,
				grey2 = palette.grey2,
			}

			vim.g.gruvbox_material_ui_contrast = "high"
			vim.g.gruvbox_material_float_style = "dim"

			local highlights = {
				Normal = { fg = palette.fg0, bg = palette.bg0 },
				SignColumn = { bg = palette.bg0 },
				StatusLine = { fg = palette.fg1, bg = palette.bg3 },
				StatusLineNC = { fg = palette.grey1, bg = palette.bg1 },
				Search = { fg = palette.bg0, bg = palette.yellow },
				IncSearch = { fg = palette.bg0, bg = palette.orange },
				CursorLine = { bg = palette.bg1 },
				CursorLineNr = { fg = palette.yellow },
				_Function = { fg = palette.blue, italic = true },
				_Keyword = { fg = palette.red, italic = true },
				_Type = { fg = palette.yellow, italic = true },
				_String = { fg = palette.green },
				_Variable = { fg = palette.fg0 },
				_Comment = { fg = palette.grey1, italic = true },
				_PreProc = { fg = palette.purple, italic = true },
				_Special = { fg = palette.orange, italic = true },
				_Error = { fg = palette.red },
				_Todo = { fg = palette.purple, italic = true },
				_Directory = { fg = palette.blue },
				_Title = { fg = palette.blue, italic = true },
				NvimTreeNormal = { bg = palette.bg0 },
				TelescopeNormal = { bg = palette.bg0 },
				TelescopeBorder = { fg = palette.bg4, bg = palette.bg0 },
				GitSignsAdd = { fg = palette.green },
				GitSignsChange = { fg = palette.blue },
				GitSignsDelete = { fg = palette.red },
				DiagnosticError = { fg = palette.red },
				DiagnosticWarn = { fg = palette.yellow },
				DiagnosticInfo = { fg = palette.blue },
				DiagnosticHint = { fg = palette.aqua },
				LspReferenceText = { bg = palette.bg3 },
				LspReferenceRead = { bg = palette.bg3 },
				LspReferenceWrite = { bg = palette.bg3 },
			}

			vim.cmd.colorscheme("gruvbox-material")

			for group, settings in pairs(highlights) do
				vim.api.nvim_set_hl(0, group, settings)
			end

			vim.opt.background = "dark"
			vim.opt.termguicolors = true
			vim.opt.cursorline = true
		end,
	},
}
