-- packadd! so plugin/wakatime.vim doesn't auto-init first: the CLI path is resolved only once
vim.pack.add({ "https://github.com/wakatime/vim-wakatime" }, {
	load = function(p)
		vim.cmd.packadd({ p.spec.name, bang = true })
	end,
})

-- the wrapper reports the jj bookmark as the branch
require("wakatime").setup({
	cli_path = vim.fn.expand("~/.local/bin/wakatime-jj"),
	-- lua/waka_status.lua shows per-bookmark time instead of today's total
	status_bar_enabled = false,
})
