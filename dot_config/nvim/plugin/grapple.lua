-- plugin/grapple.lua
vim.pack.add({
	{ src = "https://github.com/cbochs/grapple.nvim" },
})

require("grapple").setup({
	scope = "git", -- tags scoped to the current git repo (works fine with jj's colocated .git)
	icons = false,
})

vim.keymap.set("n", "<leader>m", "<cmd>Grapple toggle<cr>", { desc = "Tag/untag file" })
vim.keymap.set("n", "<leader>M", "<cmd>Grapple toggle_tags<cr>", { desc = "Open tag list" })
vim.keymap.set("n", "<leader>n", "<cmd>Grapple cycle_tags next<cr>", { desc = "Next tagged file" })
vim.keymap.set("n", "<leader>p", "<cmd>Grapple cycle_tags prev<cr>", { desc = "Previous tagged file" })
vim.keymap.set("n", "<leader>1", "<cmd>Grapple select index=1<cr>", { desc = "Go to tag 1" })
vim.keymap.set("n", "<leader>2", "<cmd>Grapple select index=2<cr>", { desc = "Go to tag 2" })
vim.keymap.set("n", "<leader>3", "<cmd>Grapple select index=3<cr>", { desc = "Go to tag 3" })
vim.keymap.set("n", "<leader>4", "<cmd>Grapple select index=4<cr>", { desc = "Go to tag 4" })
