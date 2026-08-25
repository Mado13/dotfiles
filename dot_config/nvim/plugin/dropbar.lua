vim.pack.add({
	{ src = "https://github.com/Bekaboo/dropbar.nvim" },
})

local no_bar_ft = {}
for _, ft in ipairs(vim.g.util_filetypes) do
	no_bar_ft[ft] = true
end

require("dropbar").setup({
	bar = {
		enable = function(buf, win, _)
			buf = buf or vim.api.nvim_get_current_buf()
			win = win or vim.api.nvim_get_current_win()
			if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
				return false
			end
			-- gate on buftype, not filetype: BufWinEnter fires before FileType, so a
			-- filetype check runs too early and dropbar's attach never clears a bar
			-- it already set. claude terminal/grug-far/oil/help/... are all non-'' buftypes.
			if vim.fn.win_gettype(win) ~= "" or vim.bo[buf].buftype ~= "" then
				return false
			end
			return not no_bar_ft[vim.bo[buf].filetype]
		end,
	},
})

-- dropbar renders through its own DropBar* groups. They carry no bg of their
-- own, so this is what gives the whole bar its colour.
local function set_winbar_hl()
	for _, g in ipairs({ "WinBar", "WinBarNC" }) do
		vim.api.nvim_set_hl(0, g, { bg = "#f2f2f2", underline = true, sp = "#e9e9e9" })
	end
end

set_winbar_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_winbar_hl })
