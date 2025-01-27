local factor = { width = 0.5, height = 0.5 }
local scale = require("util.utils").screen_scale(factor)
if not scale or not scale.width or not scale.height then
	error("Failed to get screen scale. Check the implementation of util.screen_scale.")
end

local opts = {
	keymaps = {
		["g?"] = "actions.show_help",
		["<CR>"] = "actions.select",
		["<C-s>"] = "actions.select_split",
		["<C-v>"] = "actions.select_vsplit",
		["<C-t>"] = "actions.select_tab",
		["<C-p>"] = "actions.preview",
		["q"] = "actions.close",
		["<C-c>"] = "actions.close",
		["<C-r>"] = "actions.refresh",
		["-"] = "actions.parent",
		["_"] = "actions.open_cwd",
		["`"] = "actions.cd",
		["~"] = "actions.tcd",
		["gs"] = "actions.change_sort",
		["gx"] = "actions.open_external",
		["g."] = "actions.toggle_hidden",
		["g\\"] = "actions.toggle_trash",
	},

	win_options = {
		cursorcolumn = false,
		number = false,
		relativenumber = false,
		signcolumn = "no",
		wrap = false,
		spell = false,
		conceallevel = 3,
	},

	use_default_keymaps = false,

	float = {
		padding = 8,
		max_width = scale.width,
		max_height = scale.height,
		border = "single",
		win_options = {
			winblend = 5,
			winhighlight = "Normal:Normal,FloatBorder:Comment,CursorLine:Visual",
		},
	},

	view_options = {
		show_hidden = true,
		is_always_hidden = function(name, _)
			local hidden_patterns = {
				"^%.git$",
				"^%.DS_Store$",
				"^%..",
				"^node_modules$",
				"^%.env.*$",
				"^%.vscode$",
				"^%.idea$",
				"^__pycache__$",
				"^%.pytest_cache$",
			}

			for _, pattern in ipairs(hidden_patterns) do
				if name:match(pattern) then
					return true
				end
			end
			return false
		end,
	},

	preview = {
		width = nil,
		height = nil,
		border = "single",
		win_options = {
			winblend = 0,
			number = true,
			relativenumber = false,
			cursorline = true,
			cursorcolumn = false,
			signcolumn = "no",
			wrap = false,
			spell = false,
			winhighlight = "Normal:Normal,FloatBorder:Comment,CursorLine:Visual",
		},
	},
}

return {
	"stevearc/oil.nvim",
	opts = opts,
	config = function(_, opts)
		require("oil").setup(opts)
		vim.api.nvim_create_autocmd("VimEnter", {
			callback = function()
				if vim.fn.argc() == 0 then
					require("oil").open_float()
				end
			end,
		})
	end,
	default_file_explorer = true,
	delete_to_trash = true,
	skip_confirm_for_simple_edits = true,
}
