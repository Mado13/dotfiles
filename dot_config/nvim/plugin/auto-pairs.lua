vim.pack.add({
	{ src = "https://github.com/windwp/nvim-autopairs" },
})

local npairs = require("nvim-autopairs")
npairs.setup({
	check_ts = true,
	disable_in_replace_mode = true,
})

npairs.add_rules(require("nvim-autopairs.rules.endwise-ruby"))
npairs.add_rules(require("nvim-autopairs.rules.endwise-lua"))
npairs.add_rules(require("nvim-autopairs.rules.endwise-elixir"))
