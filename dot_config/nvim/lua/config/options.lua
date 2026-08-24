vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.undofile = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.termguicolors = true
-- one border for every float, so plugins stop each needing their own setting
vim.opt.winborder = "rounded"
vim.opt.scrolloff = 8
vim.opt.inccommand = "split"
vim.opt.confirm = true
vim.opt.breakindent = true
vim.opt.swapfile = false
vim.opt.timeoutlen = 500
vim.opt.synmaxcol = 300
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoread = true
-- treesitter drives folds, no plugin needed. buffers without a parser just get no folds
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevelstart = 99 -- everything open on open, fold on demand
vim.opt.foldtext = "" -- keeps syntax highlighting on the folded line
vim.opt.foldcolumn = "1"
-- blank out the dot fill, the open-fold markers and the nesting digits, so the gutter only marks closed folds
vim.opt.fillchars:append({ fold = " ", foldopen = " ", foldsep = " ", foldclose = "❯", foldinner = " " })
vim.opt.guicursor = table.concat({
	"n-v-c-sm:block", -- solid block: Normal, Visual, Cmdline, Select
	"i-ci-ve:hor20-blinkwait700-blinkoff400-blinkon250", -- blinking underline: Insert, Cmdline-insert, Visual-exclusive
	"r-cr-o:hor20", -- static underline: Replace, Cmdline-replace, Operator-pending
}, ",")
