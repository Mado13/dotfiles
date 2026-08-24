vim.pack.add({
	{ src = "https://github.com/MagicDuck/grug-far.nvim" },
})

require("grug-far").setup({})

vim.keymap.set("n", "<leader>sr", "<cmd>GrugFar<cr>", { desc = "Search and replace (project)" })
vim.keymap.set("x", "<leader>sr", function()
	require("grug-far").with_visual_selection()
end, { desc = "Search and replace (selection)" })

vim.api.nvim_create_autocmd("FileType", {
	pattern = "grug-far",
	callback = function(event)
		vim.keymap.set("n", "q", function()
			local inst = require("grug-far").get_instance(event.buf)
			if inst then
				inst:close()
			end
		end, { buffer = event.buf, desc = "Close grug-far" })
	end,
})
