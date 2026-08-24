vim.pack.add({
	{ src = "https://github.com/folke/todo-comments.nvim" },
})

require("todo-comments").setup({
	signs = false, -- keep the gutter clean, rely on in-line highlighting
})

vim.keymap.set("n", "]t", function()
	require("todo-comments").jump_next()
end, { desc = "Next TODO/FIXME/NOTE" })
vim.keymap.set("n", "[t", function()
	require("todo-comments").jump_prev()
end, { desc = "Previous TODO/FIXME/NOTE" })
vim.keymap.set("n", "<leader>st", function()
	require("todo-comments.fzf").todo()
end, { desc = "Search TODOs project-wide" })
