vim.pack.add({
	{ src = "https://github.com/mbbill/undotree" },
})

-- Tree + diff panel together on the right, focus jumps there so you can
-- navigate immediately instead of <C-w>w-ing into it.
vim.g.undotree_WindowLayout = 4
vim.g.undotree_SetFocusWhenToggle = 1
vim.g.undotree_SplitWidth = 40
vim.g.undotree_DiffpanelHeight = 12
vim.g.undotree_RelativeTimestamp = 1
vim.g.undotree_HighlightChangedText = 1
vim.g.undotree_HighlightChangedWithSign = 1

vim.keymap.set("n", "<leader>u", "<cmd>UndotreeToggle<cr>", { desc = "Toggle undo tree" })
