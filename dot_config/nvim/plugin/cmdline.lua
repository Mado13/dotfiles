-- ui2 is core's cmdline/message redesign. It already draws the cmdline as a
-- real floating window, it just pins it under the statusline. tiny-cmdline
-- moves that window to the middle on CmdlineEnter and puts it back on leave,
-- so messages still land at the bottom.
--
-- Riding ui2 is what keeps this working: nvim stays in real cmdline mode, so
-- 'inccommand' still previews and blink still completes. Anything that fakes
-- the cmdline with a scratch buffer loses both.
-- tiny-cmdline sets cmdheight=0 with noautocmd, so ui2 never hears about it and
-- leaves its cmdline window over the statusline. Starting at 0 keeps them in sync.
vim.o.cmdheight = 0
require("vim._core.ui2").enable()

vim.pack.add({
	{ src = "https://github.com/rachartier/tiny-cmdline.nvim" },
})

require("tiny-cmdline").setup()

-- tiny-cmdline moves the native popup along when the box resizes, but blink's
-- menu stays where it opened until the next keystroke. menu is blink's internal
-- module, so skip quietly if it moves.
vim.api.nvim_create_autocmd("User", {
	pattern = "TinyCmdlineMoved",
	callback = function()
		vim.schedule(function()
			local ok, menu = pcall(require, "blink.cmp.completion.windows.menu")
			if ok and menu.win:is_open() then
				menu.update_position()
			end
		end)
	end,
})

-- tiny-cmdline points its interior at MsgArea, which modus never defines, so the
-- box came out with a background on the border and none inside. FloatBorder is
-- squared up against NormalFloat in plugin/colorscheme.lua.
local function theme()
	vim.api.nvim_set_hl(0, "TinyCmdlineNormal", { link = "NormalFloat" })
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = theme })
theme()
