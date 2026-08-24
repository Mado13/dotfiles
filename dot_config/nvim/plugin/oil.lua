vim.pack.add({
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/echasnovski/mini.icons" },
})

require("oil").setup({
	default_file_explorer = true,
	delete_to_trash = true,
	skip_confirm_for_simple_edits = true,
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

-- Oil-specific buffer tweaks — belongs here, not in global options.lua,
-- since it only applies to oil's own filetype.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "oil",
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
	end,
})
