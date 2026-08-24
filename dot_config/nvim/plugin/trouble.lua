vim.pack.add({
	{ src = "https://github.com/folke/trouble.nvim" },
})

require("trouble").setup({})

-- Send fzf-lua results (grep, files, lsp refs, etc.) into trouble with <C-t>
require("fzf-lua.config").defaults.actions.files["ctrl-t"] = require("trouble.sources.fzf").actions.open

vim.keymap.set("n", "<leader>xw", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (workspace)" })
vim.keymap.set("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Diagnostics (buffer)" })
vim.keymap.set("n", "<leader>xq", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix list" })
vim.keymap.set("n", "<leader>xl", "<cmd>Trouble loclist toggle<cr>", { desc = "Location list" })
