-- One float, two callers: the fish shell and jjui. Keyed by command so each
-- keeps its own buffer and survives being hidden and reopened.
local M = {}

local states = {}

local function window_opts()
	local width = math.floor(vim.o.columns * 0.85)
	local height = math.floor(vim.o.lines * 0.85)
	return {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
	}
end

--- @param cmd string command to run in the terminal
--- @param filetype string|nil set on the buffer, for filetype-scoped keymaps
function M.toggle(cmd, filetype)
	local state = states[cmd] or {}
	states[cmd] = state

	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_hide(state.win)
		state.win = nil
		return
	end

	if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		state.win = vim.api.nvim_open_win(state.buf, true, window_opts())
	else
		state.buf = vim.api.nvim_create_buf(false, true)
		state.win = vim.api.nvim_open_win(state.buf, true, window_opts())
		vim.fn.jobstart(cmd, {
			term = true,
			on_exit = function()
				if state.win and vim.api.nvim_win_is_valid(state.win) then
					vim.api.nvim_win_hide(state.win)
				end
				state.win, state.buf = nil, nil
			end,
		})
		if filetype then
			vim.bo[state.buf].filetype = filetype
		end
	end

	-- the TUI paints its own background, so any cell it has not drawn should be
	-- the editor background rather than the darker NormalFloat
	vim.wo[state.win].winhighlight = "NormalFloat:Normal,FloatBorder:Normal"

	vim.cmd("startinsert")
end

--- Hide the float showing in `win`, if it is one of ours. Returns whether it was.
function M.hide(win)
	for _, state in pairs(states) do
		if state.win == win then
			vim.api.nvim_win_hide(win)
			state.win = nil
			return true
		end
	end
	return false
end

return M
