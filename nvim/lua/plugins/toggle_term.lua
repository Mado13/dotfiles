local u = require("util.utils")
local t = require("util.toggle")
local m = u.lazy_map
local opts = t.toggleterm_opts
local modes = { "n", "t" }

return {
	"akinsho/toggleterm.nvim",
	opts = opts,
	config = function()
		-- Setup for toggleterm
		require("toggleterm").setup({
			-- Configuration options
			size = 20,
			open_mapping = [[<c-\>]],
			hide_numbers = true,
			shade_filetypes = {},
			shade_terminals = true,
			shading_factor = 2,
			start_in_insert = true,
			insert_mappings = true,
			persist_size = true,
			direction = "horizontal",
			close_on_exit = true,
			shell = "/opt/homebrew/bin/fish",
			float_opts = {
				border = "curved",
				winblend = 0,
				highlights = {
					border = "Normal",
					background = "Normal",
				},
			},
		})

		-- Terminal configurations
		local Terminal = require("toggleterm.terminal").Terminal
		local lazygit = Terminal:new({ cmd = "lazygit", hidden = true, direction = "float" })
		local node = Terminal:new({ cmd = "node", hidden = true })
		local python = Terminal:new({ cmd = "python3", hidden = true })
		local rails = Terminal:new({ cmd = "rails c", hidden = true })
		local lazydocker = Terminal:new({ cmd = "lazydocker", hidden = true, direction = "float" })
		local pr_create = Terminal:new({ cmd = "gh pr create", hidden = true })

		-- Function definitions
		_G._LAZYGIT_TOGGLE = function()
			lazygit:toggle()
		end

		_G._NODE_TOGGLE = function()
			node:toggle()
		end

		_G._PYTHON_TOGGLE = function()
			python:toggle()
		end

		_G._RAILS_TOGGLE = function()
			rails:toggle()
		end

		_G._LAZYDOCKER_TOGGLE = function()
			lazydocker:toggle()
		end
	end,
}
