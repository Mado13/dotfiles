return {
	{
		"gelguy/wilder.nvim",
		keys = {
			":",
			"/",
			"?",
		},
		config = function()
			local wilder = require("wilder")

			-- Colors for Gruvbox Material Dark Gogh
			local colors = {
				fg = "#d4be98", -- Gruvbox foreground
				bg = "#282828", -- Gruvbox background
				bg_soft = "#32302f", -- Gruvbox softer background
				grey = "#928374", -- Gruvbox grey
				accent = "#89b482", -- Gruvbox aqua
				selected_bg = "#45403d", -- Gruvbox bg1
				selected_fg = "#d4be98", -- Same as normal fg for consistency
			}

			local text_highlight = wilder.make_hl("WilderText", { { a = 1 }, { a = 1 }, { foreground = colors.fg } })

			local accent_highlight =
				wilder.make_hl("WilderAccent", { { a = 1 }, { a = 1 }, { foreground = colors.accent } })

			local selected_highlight = wilder.make_hl("WilderSelected", {
				{ a = 1 },
				{ a = 1 },
				{
					foreground = colors.selected_fg,
					background = colors.selected_bg,
				},
			})

			-- Enable wilder
			wilder.setup({ modes = { ":", "/", "?" } })

			-- Pipeline configuration
			wilder.set_option("pipeline", {
				wilder.branch(
					wilder.cmdline_pipeline({
						fuzzy = 1,
						set_pcre2_pattern = 1,
					}),
					wilder.vim_search_pipeline({
						fuzzy = 1,
						pattern = wilder.python_fuzzy_pattern(),
					})
				),
			})

			-- Renderer configuration
			wilder.set_option(
				"renderer",
				wilder.popupmenu_renderer(wilder.popupmenu_border_theme({
					highlighter = wilder.basic_highlighter(),
					highlights = {
						default = text_highlight,
						border = text_highlight, -- Using main text color for border
						accent = accent_highlight,
						selected = selected_highlight,
					},
					pumblend = 0,
					min_width = "100%",
					min_height = "25%",
					max_height = "25%",
					border = "rounded",
					-- Menu items
					left = {
						" ",
						wilder.popupmenu_devicons(),
						wilder.popupmenu_buffer_flags({
							flags = " a + ",
							icons = { ["+"] = "", a = "", h = "" },
						}),
					},
					right = {
						" ",
						wilder.popupmenu_scrollbar({
							thumb_char = "▐",
							scrollbar_bg = accent_highlight,
						}),
					},
				}))
			)
		end,
	},
}
