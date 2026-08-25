-- jjui.nvim was 375 lines to open a float. Its one feature beyond that,
-- use_neovim_remote, is the one ~/.config/jj/scripts/jj-editor.sh deliberately
-- avoids: it closed the float on BufLeave, so the editor split tore the window
-- down mid-squash.
local float = require("float_term")

vim.keymap.set("n", "<leader>jj", function()
	float.toggle("jjui", "jjui")
end, { desc = "jjui" })

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
