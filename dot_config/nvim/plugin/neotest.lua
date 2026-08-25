vim.pack.add({
	{ src = "https://github.com/nvim-neotest/nvim-nio" },
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/nvim-neotest/neotest" },
	{ src = "https://github.com/olimorris/neotest-rspec" },
})

require("neotest").setup({
	adapters = {
		require("neotest-rspec")({
			-- prefer the binstub, fall back to bundle exec
			rspec_cmd = function()
				if vim.fn.filereadable("bin/rspec") == 1 then
					return { "bin/rspec" }
				end
				return { "bundle", "exec", "rspec" }
			end,
		}),
	},
})

local nt = require("neotest")

vim.keymap.set("n", "<leader>tt", function() nt.run.run() end, { desc = "Test nearest" })
vim.keymap.set("n", "<leader>tf", function() nt.run.run(vim.fn.expand("%")) end, { desc = "Test file" })
vim.keymap.set("n", "<leader>ts", function() nt.run.run(vim.fn.getcwd()) end, { desc = "Test suite" })
vim.keymap.set("n", "<leader>tl", function() nt.run.run_last() end, { desc = "Test last" })
vim.keymap.set("n", "<leader>to", function() nt.output.open({ enter = true }) end, { desc = "Test output" })
vim.keymap.set("n", "<leader>tp", function() nt.output_panel.toggle() end, { desc = "Test output panel" })
vim.keymap.set("n", "<leader>tS", function() nt.summary.toggle() end, { desc = "Test summary tree" })
vim.keymap.set("n", "[T", function() nt.jump.prev({ status = "failed" }) end, { desc = "Prev failed test" })
vim.keymap.set("n", "]T", function() nt.jump.next({ status = "failed" }) end, { desc = "Next failed test" })

-- modus sets NeotestTest to bg_dim, a background value used as a foreground, so
-- it renders at 1.12:1 (theme.lua:472). NeotestWatching it doesn't set at all,
-- leaving neotest's own #FFEC63 at 1.20:1. Both re-set on ColorScheme.
local function neotest_hl()
	vim.api.nvim_set_hl(0, "NeotestTest", { link = "Normal" })
	vim.api.nvim_set_hl(0, "NeotestWatching", { fg = "#6f5500" })
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = neotest_hl })
neotest_hl()
