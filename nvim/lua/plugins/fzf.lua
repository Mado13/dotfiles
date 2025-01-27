-- Define reusable window options for visual consistency
local smallwin = {
	height = 0.25,
	width = 0.4,
	row = 0.5,
	hls = { normal = "Pmenu" },
	preview = {
		hidden = true,
	},
}

local default_winopts = {
	width = 0.8,
	height = 0.7,
	preview = {
		layout = "horizontal",
		horizontal = "down:40%",
		wrap = "wrap",
	},
}

-- Performance optimizations for file search
local function get_fd_opts()
	return {
		-- Exclude common large directories
		"--exclude",
		".git",
		"--exclude",
		"node_modules",
		"--exclude",
		"target",
		"--exclude",
		"dist",
		-- Add type filters for faster searches
		"--type",
		"f",
		"--type",
		"l",
		-- Follow symbolic links
		"-L",
		-- Add hidden files but respect gitignore
		"--hidden",
		"--no-ignore-vcs",
	}
end

-- Ripgrep performance optimizations
local function get_rg_opts()
	return {
		"--color=always",
		"--no-heading",
		"--smart-case",
		-- Add search type optimizations
		"--type-add=vue:*.vue",
		"--type-add=jsx:*.jsx",
		"--type-add=tsx:*.tsx",
		-- Ignore specific files/directories
		"--glob=!.git/*",
		"--glob=!node_modules/*",
		-- Thread count optimization
		"--threads=4",
		-- Add hidden files but respect gitignore
		"--hidden",
		"--no-ignore-vcs",
	}
end

return {
	{
		"ibhagwan/fzf-lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local fzf = require("fzf-lua")
			local config = require("fzf-lua.config")
			local actions = require("trouble.sources.fzf").actions

			-- Enhanced mappings with better mnemonics
			local mappings = {
				["<leader>ff"] = { "files", "Find files" },
				["<leader>fg"] = { "live_grep", "Live grep" },
				["<leader>/"] = { "grep_curbuf", "Fuzzy current buffer" },
				["<leader>?"] = { "oldfiles", "Recent files" },
				["<leader>fh"] = { "help_tags", "Help tags" },
				['""'] = { "registers", "Show registers" },
				["<leader>gb"] = { "git_branches", "Git branches" },
				["<leader>gc"] = { "git_bcommits", "Buffer commits" },
				["<leader>fs"] = { "spell_suggest", "Spell suggest" },
				["<leader>gs"] = { "git_status", "Git status" },
				["<leader>fw"] = { "grep_cword", "Grep current word" },
				-- New power-user mappings
				["<leader>ft"] = { "grep_cWORD", "Grep current WORD" },
				["<leader>fm"] = { "marks", "Browse marks" },
				["<leader>fj"] = { "jumps", "Browse jumps" },
				["<leader>fc"] = { "changes", "Browse changes" },
			}

			-- Setup enhanced actions
			local actions = {
				files = {
					["ctrl-x"] = { fn = fzf.actions.file_split },
					["ctrl-v"] = { fn = fzf.actions.file_vsplit },
					["ctrl-t"] = { fn = actions.open },
					["ctrl-q"] = { fn = fzf.actions.file_sel_to_qf },
				},
			}

			-- Enhanced FZF-Lua setup with performance optimizations
			fzf.setup({
				winopts = {
					on_create = function()
						-- Enhanced terminal mappings
						local term_maps = {
							["<C-j>"] = "<Down>",
							["<C-k>"] = "<Up>",
							["<C-n>"] = "<Down>",
							["<C-p>"] = "<Up>",
							["<C-u>"] = "<C-u>",
							["<C-d>"] = "<C-d>",
						}
						for k, v in pairs(term_maps) do
							vim.keymap.set("t", k, v, { silent = true, buffer = true })
						end
					end,
					default_winopts,
				},
				keymap = {
					-- Enhanced builtin mappings
					builtin = {
						["<C-d>"] = "preview-page-down",
						["<C-u>"] = "preview-page-up",
						["<C-/>"] = "toggle-preview",
					},
				},
				fzf_opts = {
					["--no-info"] = "",
					["--info"] = "hidden",
					["--no-scrollbar"] = "",
					-- Performance tweaks
					["--tiebreak"] = "length,begin,index",
					["--bind"] = table.concat({
						"ctrl-u:preview-page-up",
						"ctrl-d:preview-page-down",
						"ctrl-/:toggle-preview",
					}, ","),
				},
				files = {
					prompt = "Files❯ ",
					cmd = "fd",
					args = get_fd_opts(),
					action = actions.files,
					previewer = "bat",
					file_icons = true,
					color_icons = true,
					find_opts = [[-type f -not -path '*/\.git/*' -printf '%P\n']],
					rg_opts = get_rg_opts(),
					winopts = smallwin,
				},
				grep = {
					prompt = "Rg❯ ",
					input_prompt = "Grep For❯ ",
					cmd = "rg",
					args = get_rg_opts(),
					actions = actions.files,
					previewer = "bat",
				},
			})

			-- Apply mappings
			for keys, map in pairs(mappings) do
				vim.keymap.set("n", keys, function()
					fzf[map[1]]()
				end, { desc = map[2] })
			end
		end,
	},
}
