local term_state = { buf = nil, win = nil }

local function toggle_float_terminal()
	if term_state.win and vim.api.nvim_win_is_valid(term_state.win) then
		vim.api.nvim_win_hide(term_state.win)
		term_state.win = nil
		return
	end

	local width = math.floor(vim.o.columns * 0.85)
	local height = math.floor(vim.o.lines * 0.85)
	local opts = {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
	}

	if term_state.buf and vim.api.nvim_buf_is_valid(term_state.buf) then
		term_state.win = vim.api.nvim_open_win(term_state.buf, true, opts)
	else
		term_state.buf = vim.api.nvim_create_buf(false, true)
		term_state.win = vim.api.nvim_open_win(term_state.buf, true, opts)
		vim.fn.jobstart("fish", { term = true })
	end

	vim.cmd("startinsert")
end

vim.keymap.set("n", "<leader>ft", toggle_float_terminal, { desc = "Floating terminal (fish)" })

-- q in normal mode closes any terminal buffer (the floating one hides via the
-- same path as the toggle keymap, so term_state stays in sync for reuse)
vim.api.nvim_create_autocmd("TermOpen", {
	callback = function(event)
		vim.keymap.set("n", "q", function()
			local win = vim.api.nvim_get_current_win()
			if win == term_state.win then
				vim.api.nvim_win_hide(win)
				term_state.win = nil
			else
				vim.cmd("close")
			end
		end, { buffer = event.buf, silent = true, desc = "Close terminal" })
	end,
})
