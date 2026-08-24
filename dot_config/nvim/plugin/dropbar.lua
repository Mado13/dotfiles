vim.pack.add({
	{ src = "https://github.com/Bekaboo/dropbar.nvim" },
})

-- plugin-UI / read-only buffers don't benefit from a symbol breadcrumb
local no_bar_ft = {
	["claudecode"] = true,
	["oil"] = true,
	["trouble"] = true,
	["undotree"] = true,
	["diff"] = true,
	["grug-far"] = true,
	["help"] = true,
	["qf"] = true,
	["checkhealth"] = true,
	["lspinfo"] = true,
	["gitsigns-blame"] = true,
	["man"] = true,
}

require("dropbar").setup({
	bar = {
		enable = function(buf, win, _)
			buf = buf or vim.api.nvim_get_current_buf()
			win = win or vim.api.nvim_get_current_win()
			if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
				return false
			end
			-- gate on buftype, not filetype: BufWinEnter fires before FileType, so a
			-- filetype check runs too early and dropbar's attach never clears a bar
			-- it already set. claude terminal/grug-far/oil/help/... are all non-'' buftypes.
			if vim.fn.win_gettype(win) ~= "" or vim.bo[buf].buftype ~= "" then
				return false
			end
			return not no_bar_ft[vim.bo[buf].filetype]
		end,
	},
})

-- Neovim quirk (neovim/neovim#26037): any %#Group# cell in a winbar that
-- doesn't define its own bg falls back to Normal's bg, not WinBar's. Since
-- dropbar renders almost entirely via its own DropBar(Icon)Kind* groups
-- (confirmed by the maintainer in Bekaboo/dropbar.nvim#35), styling WinBar
-- itself never actually shows - every one of those groups needs its own bg.
local WINBAR_BG = "#E5DFC5"
local BORDER = "#D8D3BA"

local kinds = {
	"Array", "BlockMappingPair", "Boolean", "BreakStatement", "Call", "CaseStatement",
	"Class", "Constant", "Constructor", "ContinueStatement", "Declaration", "Default",
	"Delete", "Dir", "DoStatement", "Element", "ElseStatement", "Enum", "EnumMember", "Event",
	"Field", "File", "Folder", "ForStatement", "Function", "GotoStatement", "Identifier",
	"IfStatement", "Interface", "Keyword", "List", "Macro",
	"MarkdownH1", "MarkdownH2", "MarkdownH3", "MarkdownH4", "MarkdownH5", "MarkdownH6",
	"Method", "Module", "Namespace", "Null", "Number", "Object", "Operator", "Package",
	"Pair", "Property", "Reference", "Repeat", "ReturnStatement", "Rule", "RuleSet",
	"Scope", "Section", "Specifier", "Statement", "String", "Struct", "SwitchStatement",
	"Table", "Terminal", "Type", "TypeParameter", "Unit", "Value", "Variable",
	"WhileStatement",
}

local function set_winbar_hl()
	vim.api.nvim_set_hl(0, "WinBar", { bg = WINBAR_BG, underline = true, sp = BORDER })
	vim.api.nvim_set_hl(0, "WinBarNC", { bg = WINBAR_BG, underline = true, sp = BORDER })

	for _, suffix in ipairs({ "", "NC" }) do
		vim.api.nvim_set_hl(0, "DropBarIconUISeparator" .. suffix, {
			fg = BORDER,
			bg = WINBAR_BG,
		})
		for _, kind in ipairs(kinds) do
			local icon_group = "DropBarIconKind" .. kind .. suffix
			local icon_hl = vim.api.nvim_get_hl(0, { name = icon_group, link = false })
			vim.api.nvim_set_hl(0, icon_group, vim.tbl_extend("force", icon_hl, { bg = WINBAR_BG }))
			vim.api.nvim_set_hl(0, "DropBarKind" .. kind .. suffix, { bg = WINBAR_BG })
		end
	end
end

set_winbar_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_winbar_hl })
