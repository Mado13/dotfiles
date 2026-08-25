-- lua/config/autocmds.lua
-- Close certain read-only/utility buffers with a single "q" press
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "help", "qf", "checkhealth", "lspinfo", "gitsigns-blame" },
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.keymap.set("n", "q", function()
			vim.cmd("close")
			pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
		end, { buffer = event.buf, silent = true, desc = "Quit buffer" })
	end,
})

-- Line numbers are noise in utility/read-only buffers, turn them off there
vim.api.nvim_create_autocmd("FileType", {
	pattern = vim.g.util_filetypes,
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
	end,
})

-- Same for terminals (jjui and the float terminal both open as terminal buffers)
vim.api.nvim_create_autocmd("TermOpen", {
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
	end,
})

-- Reload buffers automatically if the file changed on disk (Claude Code edits, jj/git ops, etc.)
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
	callback = function()
		-- E11: checktime is one of the commands the cmdline window forbids
		if vim.fn.getcmdwintype() == "" then
			vim.cmd("checktime")
		end
	end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	callback = function()
		vim.hl.on_yank()
	end,
})

-- Jump back to last cursor position when reopening a file
vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function(event)
		local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
		local lcount = vim.api.nvim_buf_line_count(event.buf)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Don't auto-continue comment leaders onto a new line
vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		vim.opt_local.formatoptions:remove({ "o", "r" })
	end,
})

-- Keep splits evenly sized when the terminal window itself resizes
vim.api.nvim_create_autocmd("VimResized", {
	command = "tabdo wincmd =",
})

-- Big files: skip treesitter/undofile so opening a huge log or vendor
-- bundle doesn't hang the editor.
vim.api.nvim_create_autocmd("BufReadPre", {
	callback = function(event)
		local ok, stats = pcall(function()
			return vim.uv.fs_stat(vim.api.nvim_buf_get_name(event.buf))
		end)
		if ok and stats and stats.size > 1024 * 1024 then
			vim.b[event.buf].bigfile = true
			vim.opt_local.undofile = false
			vim.opt_local.swapfile = false
			pcall(vim.treesitter.stop, event.buf)
		end
	end,
})
