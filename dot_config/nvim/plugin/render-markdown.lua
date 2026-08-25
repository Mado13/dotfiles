vim.pack.add({
	{ src = "https://github.com/MeanderingProgrammer/render-markdown.nvim", version = vim.version.range("*") },
})

require("render-markdown").setup({})

vim.keymap.set("n", "<leader>um", "<cmd>RenderMarkdown buf_toggle<cr>", { desc = "Toggle markdown render" })
