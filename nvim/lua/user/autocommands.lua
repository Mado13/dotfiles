local ag = vim.api.nvim_create_augroup
local au = vim.api.nvim_create_autocmd

-- Highlight yanked text
local highlight_group = ag("YankHighlight", { clear = true })
au("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})

-- Disable eslint on node_modules
local disable_node_modules_eslint_group = ag("DisableEslintOnNodeModules", { clear = true })
au({ "BufNewFile", "BufRead" }, {
	pattern = { "**/node_modules/**", "node_modules", "/node_modules/*" },
	callback = function()
		vim.diagnostic.enable(false)
	end,
	group = disable_node_modules_eslint_group,
})

-- Disable commenting new lines
vim.cmd("autocmd BufEnter * set formatoptions-=cro")
vim.cmd("autocmd BufEnter * setlocal formatoptions-=cro")

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
	group = vim.api.nvim_create_augroup("edit_text", { clear = true }),
	pattern = { "gitcommit", "markdown", "txt" },
	desc = "Enable spell checking and text wrapping for certain filetypes",
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.spell = true
	end,
})

-- open file on place of last visit
vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

local conform_group = vim.api.nvim_create_augroup("ConformFormatOnInsertLeave", { clear = true })
vim.api.nvim_create_autocmd("InsertLeave", {
	group = conform_group,
	pattern = "*",
	desc = "Run Conform formatting when leaving insert mode",
	callback = function()
		-- Define the delay in milliseconds (e.g., 500ms)
		local delay = 1500
		-- Start a timer to delay the formatting
		vim.fn.timer_start(delay, function()
			require("conform").format()
		end)
	end,
})
