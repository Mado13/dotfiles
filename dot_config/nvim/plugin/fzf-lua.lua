vim.pack.add({ "https://github.com/ibhagwan/fzf-lua" })

local utils = require("fzf-lua.utils")

-- stacked rather than side by side: the default right:60% leaves the list about
-- 49 columns at this font size.
local with_preview = {
	height = 0.85,
	width = 0.85,
	row = 0.5,
	preview = { hidden = false, layout = "vertical", vertical = "down:50%" },
}

-- snacks' vscode layout with a lower floor, 80 is the width we already had at 154
local function narrow()
	return {
		height = 0.35,
		width = math.max(72, math.floor(vim.o.columns * 0.4)),
		row = 0.2,
		preview = { hidden = true },
	}
end

-- filename_first v2, except the parent is cut at the front. fzf cuts the back, which
-- drops the dir nearest the file. the full path rides along in the v2 postfix
local trunc_parent = {
	-- values are baked in, the process listing the files loads this on its own and
	-- upvalues don't survive the trip. 8 columns go to the border, pointer, icon, tab
	_to = function(o)
		local _, hl = utils.ansi_from_hl(o.hls.dir_part, "")
		local w = tonumber(o.winopts.width)
		return ([[
			return function(s, _, m)
				local tail, parent = m.path.tail(s), m.path.parent(s)
				local postfix = "\xc2\xa0" .. string.rep(" ", 200) .. s
				if not parent then return tail, postfix end
				parent = m.path.remove_trailing(parent)
				local room = %d - #tail
				if #parent > room then
					local at = parent:find("/", #parent - room + 2, true) or parent:match(".*()/")
					parent = "…" .. parent:sub(at or 1)
				end
				return tail .. "\t%s" .. parent .. m.utils.ansi_escseq.clear, postfix
			end
		]]):format((w > 1 and w or math.floor(vim.o.columns * w)) - 8, hl or "")
	end,
	from = function(s)
		local head, full = s:match("^(.*)\xc2\xa0 +(.+)$")
		local tab = head and head:find("\t", 1, true)
		if not tab then return head or s end
		-- the [bufnr] buffers and tabs put in front has to survive
		return (head:sub(1, tab):match("^.*" .. utils.nbsp) or "")
			.. full .. (head:sub(tab):match("^\t[^:]*(:.*)$") or "")
	end,
}

require("fzf-lua").setup({
	formatters = { path = { trunc_parent = trunc_parent } },
	defaults = {
		-- "fzf.lua  lua/fzf-lua/previewer" instead of "lua/fzf-lua/previewer/fzf.lua".
		-- The parent is painted by FzfLuaDirPart, which modus already sets to fg_dim.
		formatter = "path.trunc_parent",
		fzf_opts = { ["--tabstop"] = 1, ["--ellipsis"] = " ", ["--no-hscroll"] = true },
	},
	-- preview on by default: grep hits, diagnostics, lsp locations, marks, jumps and
	-- the undo tree are all a position in a file, the row alone doesn't tell you which
	winopts = with_preview,
	-- off where the row is the whole answer and you already know what you're picking.
	-- colorschemes previews on the real editor, so the pane would sit there empty
	files = { winopts = narrow },
	git = { files = { winopts = narrow } },
	keymaps = { winopts = narrow },
	registers = { winopts = narrow },
	commands = { winopts = narrow },
	colorschemes = { winopts = narrow },
})

vim.keymap.set("n", "<leader>u", "<cmd>FzfLua undotree<cr>", { desc = "Undo history" })

-- fzf-lua's own default is #ff82ab, 2.32:1 on a light background
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function() vim.api.nvim_set_hl(0, "FzfLuaLivePrompt", { fg = "#721045" }) end,
})
vim.api.nvim_set_hl(0, "FzfLuaLivePrompt", { fg = "#721045" })
