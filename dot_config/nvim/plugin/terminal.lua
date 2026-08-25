local float = require("float_term")

vim.keymap.set("n", "<leader>ft", function()
	float.toggle("fish")
end, { desc = "Floating terminal (fish)" })

-- q in normal mode closes any terminal buffer. A float has to be hidden through
-- float_term so its state stays in sync and the buffer can be reused.
vim.api.nvim_create_autocmd("TermOpen", {
	callback = function(event)
		vim.keymap.set("n", "q", function()
			if not float.hide(vim.api.nvim_get_current_win()) then
				vim.cmd("close")
			end
		end, { buffer = event.buf, silent = true, desc = "Close terminal" })
	end,
})
