return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = function()
			require("nvim-treesitter.install").update({ with_sync = true })
		end,
		event = { "BufEnter" },
		dependencies = {
			-- Additional text objects for treesitter
			"nvim-treesitter/nvim-treesitter-textobjects",
			-- Ruby smart endwise
			"RRethy/nvim-treesitter-endwise",
		},
		config = function()
			---@diagnostic disable: missing-fields
			require("nvim-treesitter.configs").setup({
				highlight = {
					enable = true,
					additional_vim_regex_highlighting = false,
				},
				indent = {
					enable = true,
				},
				endwise = {
					enable = true,
				},
				ensure_installed = {
					"bash",
					"comment",
					"css",
					"diff",
					"dockerfile",
					"fish",
					"graphql",
					"html",
					"javascript",
					"json",
					"lua",
					"markdown",
					"markdown_inline",
					"prisma",
					"pug",
					"tsx",
					"ruby",
					"regex",
					"typescript",
					"tsx",
					"sql",
					"styled",
					"vim",
					"yaml",
				},
				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "<c-space>",
						node_incremental = "<c-space>",
						scope_incremental = "<c-s>",
						node_decremental = "<c-backspace>",
					},
				},

				sync_install = false,
				autopairs = {
					enable = true,
				},
				--[[ context_commentstring = {
					enable = true,
					enable_autocmd = false,
				}, ]]
				textobjects = {
					select = {
						enable = true,
						lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
						keymaps = {
							-- You can use the capture groups defined in textobjects.scm
							["aa"] = "@parameter.outer",
							["ia"] = "@parameter.inner",
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							["ic"] = "@class.inner",
							["a="] = "@assignment.outer",
							["i="] = "@assignment.inner",
							["l="] = "@assignment.lhs",
							["r="] = "@assignment.rhs",
							["ai"] = "@conditional.outer",
							["ii"] = "@conditional.inner",
						},
					},
					move = {
						enable = true,
						set_jumps = true, -- whether to set jumps in the jumplist
						goto_next_start = {
							["]m"] = "@function.outer",
							["]]"] = "@class.outer",
						},
						goto_next_end = {
							["]M"] = "@function.outer",
							["]["] = "@class.outer",
						},
						goto_previous_start = {
							["[m"] = "@function.outer",
							["[["] = "@class.outer",
						},
						goto_previous_end = {
							["[M"] = "@function.outer",
							["[]"] = "@class.outer",
						},
					},
				},
			})
		end,
	},
}
