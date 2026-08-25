vim.pack.add({
	{ src = "https://github.com/coder/claudecode.nvim" },
})

-- Bridges nvim to the real `claude` CLI over the same WebSocket/MCP protocol the
-- VS Code extension uses. terminal_cmd stays nil so it launches whatever `claude`
-- is on $PATH, and the account comes from CLAUDE_CONFIG_DIR below.
-- provider = native because snacks.nvim isn't installed (auto would fall back to
-- it anyway); add folke/snacks.nvim and drop this line for a nicer terminal.

local accounts = {
	personal = vim.fn.expand("~/.claude-personal"),
	work = vim.fn.expand("~/.claude-work"),
}

-- Claude Code has no account switcher of its own, CLAUDE_CONFIG_DIR is the whole
-- mechanism. It has to be set on nvim itself, not just on the terminal: the plugin
-- writes its handshake lock to $CLAUDE_CONFIG_DIR/ide and the CLI only looks under
-- its own config dir, so a mismatch means no diffs and no selection, silently.
local function set_account(name)
	local dir = accounts[name]
	if not dir then
		vim.notify("unknown claude account: " .. name, vim.log.levels.ERROR)
		return
	end

	local claudecode = require("claudecode")
	local was_running = claudecode.state.server ~= nil
	if was_running then
		claudecode.stop() -- removes the lock from the old dir, so do it first
	end

	vim.env.CLAUDE_CONFIG_DIR = dir
	require("claudecode.lockfile").lock_dir = dir .. "/ide"

	if was_running then
		claudecode.start(false)
	end

	-- a live claude keeps the account it launched with
	require("claudecode.terminal").close()
	vim.notify("claude account: " .. name)
end

-- respects `CLAUDE_CONFIG_DIR=... nvim` if I launched it that way
vim.env.CLAUDE_CONFIG_DIR = vim.env.CLAUDE_CONFIG_DIR or accounts.personal

vim.api.nvim_create_user_command("ClaudeAccount", function(opts)
	set_account(opts.args)
end, {
	nargs = 1,
	desc = "Switch Claude account",
	complete = function()
		return vim.tbl_keys(accounts)
	end,
})

require("claudecode").setup({
	log_level = "warn",
	terminal = {
		provider = "native",
		-- default jumps back to the prompt on every <C-w> into the split, losing
		-- the spot I scrolled up to read. `i` to type.
		auto_insert = false,
	},
})

vim.keymap.set("n", "<leader>ac", "<cmd>ClaudeCode<cr>", { desc = "Toggle Claude" })
vim.keymap.set("n", "<leader>af", "<cmd>ClaudeCodeFocus<cr>", { desc = "Focus Claude" })
vim.keymap.set("n", "<leader>ar", "<cmd>ClaudeCode --resume<cr>", { desc = "Resume Claude" })
vim.keymap.set("n", "<leader>aC", "<cmd>ClaudeCode --continue<cr>", { desc = "Continue Claude" })
vim.keymap.set("n", "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", { desc = "Select Claude model" })
vim.keymap.set("n", "<leader>aw", "<cmd>ClaudeAccount work<cr>", { desc = "Claude work account" })
vim.keymap.set("n", "<leader>ap", "<cmd>ClaudeAccount personal<cr>", { desc = "Claude personal account" })
vim.keymap.set("n", "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", { desc = "Add current buffer" })
vim.keymap.set("v", "<leader>as", "<cmd>ClaudeCodeSend<cr>", { desc = "Send selection to Claude" })
vim.keymap.set("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", { desc = "Accept diff" })
vim.keymap.set("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", { desc = "Deny diff" })

-- Tag the claude terminal with a filetype (native provider leaves it blank) so
-- the rest of the config keys off ft == "claudecode", not a bufname match. This
-- is the only place the bufname is inspected.
vim.api.nvim_create_autocmd("TermOpen", {
	callback = function(event)
		local cmd = vim.api.nvim_buf_get_name(event.buf):match("//%d+:(.*)$")
		if cmd and cmd:lower():find("claude", 1, true) then
			vim.bo[event.buf].filetype = "claudecode"
		end
	end,
})

-- mini.* expose no ft-ignore option, so silence them per-buffer here. Window-
-- locals strip the gutter so the TUI fits the split (no h-scroll clipping the
-- left edge). BufWinEnter too, because toggling reuses the buffer in a fresh
-- window that loses window-local options.
vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
	callback = function(event)
		if vim.bo[event.buf].filetype ~= "claudecode" then
			return
		end
		vim.b[event.buf].ministatusline_disable = true
		vim.b[event.buf].miniindentscope_disable = true
		vim.wo.winbar = ""
		vim.wo.number = false
		vim.wo.relativenumber = false
		vim.wo.signcolumn = "no"
		vim.wo.scrolloff = 0
		vim.wo.sidescrolloff = 0
	end,
})

-- add file under cursor from the tree/picker
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "oil", "netrw", "snacks_picker_list" },
	callback = function(event)
		vim.keymap.set("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>",
			{ buffer = event.buf, desc = "Add file to Claude" })
	end,
})

-- diff_inline.lua hardcodes #2a4a2a / #4a2a2a for the add and delete bands,
-- dark-theme values that come out at 2.11:1 and 1.66:1 here and read as grey
-- rather than green and red. It sets them with default = true, so defining them
-- first wins. Same colours as diffview and delta use.
local function claude_diff_hl()
	vim.api.nvim_set_hl(0, "ClaudeCodeInlineDiffAdd", { bg = "#c1f2d1" })
	vim.api.nvim_set_hl(0, "ClaudeCodeInlineDiffDelete", { bg = "#ffd8d5", strikethrough = true })
	vim.api.nvim_set_hl(0, "ClaudeCodeInlineDiffAddSign", { fg = "#006800" })
	vim.api.nvim_set_hl(0, "ClaudeCodeInlineDiffDeleteSign", { fg = "#a60000" })
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = claude_diff_hl })
claude_diff_hl()
