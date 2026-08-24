-- plugin/illuminate.lua
vim.pack.add({
	{ src = "https://github.com/RRethy/vim-illuminate" },
})

require("illuminate").configure({
	-- lsp is most accurate; fall back to treesitter, then regex so plain-text
	-- and unsupported filetypes still light up
	providers = { "lsp", "treesitter", "regex" },
	delay = 100,
	-- don't bother highlighting a word that only appears once
	min_count_to_highlight = 2,
	filetypes_denylist = {
		"oil",
		"trouble",
		"grug-far",
		"undotree",
		"fzf",
		"help",
		"checkhealth",
		"gitcommit",
	},
})

-- default is an underline; we want a grey background block instead. Re-link on
-- ColorScheme since the plugin resets these when the scheme reloads.
local function set_hl()
	for _, g in ipairs({ "IlluminatedWordText", "IlluminatedWordRead", "IlluminatedWordWrite" }) do
		vim.api.nvim_set_hl(0, g, { link = "Visual" })
	end
end
set_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })

-- n stays search (nzzzv); alt-n/p walk the instances of the word under cursor
vim.keymap.set("n", "<a-n>", function()
	require("illuminate").goto_next_reference(true)
end, { desc = "Next word instance" })
vim.keymap.set("n", "<a-p>", function()
	require("illuminate").goto_prev_reference(true)
end, { desc = "Prev word instance" })
