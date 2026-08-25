-- sindrets/diffview.nvim has had no commit since Aug 2024 and the jj adapter
-- (issue #562) never landed there. diffview-plus is the maintained fork.
vim.pack.add({
	{ src = "https://github.com/dlyongemallo/diffview-plus.nvim" },
})

-- vim paints a changed line the same colour on both sides, so a diff reads as
-- "something moved here" with no direction to it. These are modus's
-- bg_removed / bg_added and their faint variants, matching delta's
-- minus/plus in ~/.gitconfig, so the two tools agree about the same change.
local ns_old = vim.api.nvim_create_namespace("diffview_old")
local ns_new = vim.api.nvim_create_namespace("diffview_new")

vim.api.nvim_set_hl(ns_old, "DiffChange", { bg = "#ffe9e9" })
vim.api.nvim_set_hl(ns_old, "DiffText", { bg = "#ffd8d5" })
vim.api.nvim_set_hl(ns_new, "DiffChange", { bg = "#d8f8e1" })
vim.api.nvim_set_hl(ns_new, "DiffText", { bg = "#c1f2d1" })

require("diffview").setup({
	-- colocated repos have both .git and .jj, so the adapter has to be named
	preferred_adapter = "jj",
	enhanced_diff_hl = true,
	view = {
		default = { layout = "diff2_horizontal", winbar_info = true },
		file_history = { layout = "diff2_horizontal", winbar_info = true },
	},
	file_panel = {
		listing_style = "tree",
		win_config = { position = "left", width = 35 },
	},
	-- 12 lines instead of vim's 6 before unchanged code folds away, zR opens
	-- the rest
	diffopt = { algorithm = "histogram", context = 12, linematch = 40 },
	hooks = {
		diff_buf_win_enter = function(_, winid, ctx)
			-- global relativenumber counts from the cursor, so the same line
			-- gets a different number on each side
			vim.opt_local.relativenumber = false
			vim.opt_local.number = true
			-- the default "-" fills a deleted region with a full-width rule
			vim.opt_local.fillchars:append({ diff = "╱" })
			vim.api.nvim_win_set_hl_ns(winid, ctx.symbol == "a" and ns_old or ns_new)
		end,
	},
})

-- nvim 0.12 defaults to inline:char, which highlights every character run two
-- paired lines happen to share. When linematch pairs a line with its rewrite
-- rather than its edit, that is a scatter of blue over coincidences. Word
-- granularity lights up the whole line instead, which is the honest answer.
vim.opt.diffopt:remove("inline:char")
vim.opt.diffopt:append("inline:word")

-- <leader>d is taken by "delete without yanking" in config/keymaps.lua
local map = function(lhs, rhs, desc)
	vim.keymap.set("n", "<leader>g" .. lhs, rhs, { desc = desc })
end

map("d", "<cmd>DiffviewToggle<cr>", "Diffview: working copy (editable)")
map("D", "<cmd>DiffviewOpen trunk()..@<cr>", "Diffview: stack vs trunk, one diff")
-- DiffviewOpen collapses a range into a single before/after, so there is nothing
-- to step through. FileHistory lists a commit per entry and <tab> walks them
-- without closing. The short -r form fails to parse, --revisions= is required.
map("l", "<cmd>DiffviewFileHistory --revisions=trunk()..@<cr>", "Diffview: step through the stack")
map("h", "<cmd>DiffviewFileHistory %<cr>", "Diffview: file history")
map("H", "<cmd>DiffviewFileHistory<cr>", "Diffview: repo history")
map("q", "<cmd>DiffviewClose<cr>", "Diffview: close")
