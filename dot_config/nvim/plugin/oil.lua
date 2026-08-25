-- canola is the maintained continuation of oil.nvim, which last shipped in June
-- 2026 with 154 issues open. It keeps the `oil` module, :Oil and the 'oil'
-- filetype, and its options are a strict superset, so nothing else here changed.
vim.pack.add({
	-- GitHub copy goes away 2026-10-31
	{ src = "https://forge.barrettruth.com/barrettruth/canola.nvim" },
})

require("oil").setup({
	default_file_explorer = true,
	delete_to_trash = true,
	skip_confirm_for_simple_edits = true,
	-- without this a file deleted here leaves its buffer open, pointing at nothing
	cleanup_buffers_on_delete = true,
	-- jj rewrites the working copy under you, so an open listing goes stale
	watch_for_changes = true,
	lsp_file_methods = {
		-- renaming a file updates the references the LSP knows about. "unmodified"
		-- writes only the buffers that had nothing unsaved, so a rename can't
		-- silently commit an edit you were part-way through.
		autosave_changes = "unmodified",
	},
	view_options = {
		show_hidden = true,
	},
	float = {
		padding = 2,
		max_width = 90,
		max_height = 30,
	},
	keymaps = {
		["q"] = "actions.close",
		["gy"] = { "actions.yank_entry", opts = { modify = ":." } },
	},
})
