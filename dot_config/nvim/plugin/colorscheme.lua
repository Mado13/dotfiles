vim.pack.add({ "https://github.com/miikanissi/modus-themes.nvim" })

vim.o.background = "light"

-- default, not tinted. tinted puts floats and selections at L* 76 on an L* 97 bg
require("modus-themes").setup({
	-- FloatBorder and FloatTitle ship with bg_main while NormalFloat gets
	-- bg_popup, so a bordered float came out grey inside a white ring.
	on_highlights = function(hl, c)
		hl.FloatBorder = { fg = c.border, bg = c.bg_popup }
		hl.FloatTitle = { fg = c.fg_main, bg = c.bg_popup, bold = true }
		-- signs ship with bg_added/changed/removed, which fills the cell and hides
		-- the glyph. sign_column_background = false swaps it for bg_main, a white
		-- hole in a bg_dim gutter, so drop the background instead.
		-- fg_*_intense sits at L* 35-37, which reads black in a one-cell glyph.
		-- The *_intense accents are 12-17 points lighter and still clear 3:1.
		hl.GitSignsAdd = { fg = c.green_intense }
		hl.GitSignsChange = { fg = c.yellow_intense }
		hl.GitSignsDelete = { fg = c.red_intense }
		-- RenderMarkdownCode links to markdownCodeBlock, which is fg-only cyan.
		-- The block extmark then paints every line cyan over the injected
		-- syntax, and the block itself gets no background. bg only, so lua in a
		-- fence keeps its own colors.
		hl.RenderMarkdownCode = { bg = c.bg_dim }
		-- the █ run that fills the fence row takes this group's bg as its fg
		hl.RenderMarkdownCodeBorder = { bg = c.bg_dim }
		-- ==highlight== inherits RenderMarkdownCodeInline, so it was the same
		-- cyan as `inline code`
		hl.RenderMarkdownInlineHighlight = { fg = c.fg_main, bg = c.bg_yellow_subtle }
	end,
})

vim.cmd("colorscheme modus")

-- modus's util.lua maps n_0 to bg_main, so ANSI 0 came out white and 8 came out
-- #f2f2f2. Dim TUI text drawn in 8 vanished.
-- Slots 0/7/8/15 here are the theme's own fg_term_* values, which util.lua
-- never reads. 9-14 are the faint accents. Intense is chroma 81, too loud.
local ANSI = {
	"#000000", "#a60000", "#006800", "#6f5500", "#0031a9", "#721045", "#005e8b", "#a6a6a6",
	"#595959", "#7f0000", "#2a5045", "#624416", "#003497", "#7c318f", "#005077", "#ffffff",
}

local function ansi()
	for i, hex in ipairs(ANSI) do
		vim.g["terminal_color_" .. (i - 1)] = hex
	end
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = ansi })
ansi()
