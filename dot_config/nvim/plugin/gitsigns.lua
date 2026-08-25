vim.pack.add({
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
})

require("gitsigns").setup({
	signs = {
		add = { text = "┃" },
		-- dashed, because add and change are only a hue apart and a one-cell
		-- glyph carries hue badly. Shape does the work, colour confirms it.
		change = { text = "┇" },
		delete = { text = "_" },
		topdelete = { text = "‾" },
		changedelete = { text = "~" },
		untracked = { text = "┆" },
	},
	signs_staged_enable = false, -- jj colocated repos don't use git's staging area — this distinction is meaningless here
	on_attach = function(bufnr)
		local gs = require("gitsigns")
		local opts = { buffer = bufnr }

		vim.keymap.set("n", "]c", function()
			gs.nav_hunk("next")
		end, opts)
		vim.keymap.set("n", "[c", function()
			gs.nav_hunk("prev")
		end, opts)
		vim.keymap.set("n", "<leader>hp", gs.preview_hunk, opts)
		vim.keymap.set("n", "<leader>hb", gs.blame_line, opts)
		vim.keymap.set("n", "<leader>hB", gs.blame, opts) -- full-file blame, <M-cr> for commit menu, s/S to open commit
		vim.keymap.set("n", "<leader>hd", gs.diffthis, opts)
	end,
})
