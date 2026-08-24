vim.pack.add({
	{ src = "https://github.com/HotThoughts/jjui.nvim" },
})

require("jjui").setup({})

-- The <Esc><Esc> map in keymaps.lua ejects to normal mode on the jjui buffer,
-- where q closes the float. Press it while jj is waiting on the description
-- editor and jj is left blocked on a pty you can't see anymore. jjui binds esc
-- to cancel and q to quit itself, so both should just reach jjui.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "jjui",
	callback = function(ev)
		vim.keymap.set("t", "<Esc><Esc>", "<Esc><Esc>", { buffer = ev.buf })
	end,
})
