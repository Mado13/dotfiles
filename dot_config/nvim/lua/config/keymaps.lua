-- fzf-lua
vim.keymap.set("n", "<leader>fb", "<cmd>FzfLua buffers<cr>", { desc = "List open buffers" })
vim.keymap.set("n", "<leader>fh", "<cmd>FzfLua help_tags<cr>", { desc = "Search help" })
vim.keymap.set("n", "<leader>ff", "<cmd>FzfLua files<cr>", { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", "<cmd>FzfLua live_grep<cr>", { desc = "Live grep" })
vim.keymap.set("n", "<leader>fw", "<cmd>FzfLua grep_cword<cr>", { desc = "Grep word under cursor" })
vim.keymap.set("n", "<leader>sw", "<cmd>FzfLua grep_cword<cr>", { desc = "Grep word under cursor" })
vim.keymap.set("x", "<leader>sw", "<cmd>FzfLua grep_visual<cr>", { desc = "Grep selection" })
vim.keymap.set("n", "<leader>/", "<cmd>FzfLua live_grep<cr>", { desc = "Grep project-wide" })
vim.keymap.set("n", "<leader>fm", "<cmd>FzfLua marks<cr>", { desc = "List marks (ctrl-x deletes)" })
vim.keymap.set("n", "<leader>fk", "<cmd>FzfLua keymaps<cr>", { desc = "Search keymaps" })
vim.keymap.set("n", "<leader>fr", function()
	-- v:oldfiles is frozen at startup, so without the session buffers this list has
	-- nothing you opened today in it
	require("fzf-lua").oldfiles({ cwd_only = true, include_current_session = true })
end, { desc = "Recent files (project)" })

-- Alternate with the last real file buffer (skip oil/terminal/claude/etc. via
-- buftype). Plain `:e #` would happily jump you into those.
vim.keymap.set("n", "<leader>bb", function()
	local cur = vim.api.nvim_get_current_buf()
	local target, latest = nil, -1
	for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
		if info.bufnr ~= cur and info.name ~= "" and vim.bo[info.bufnr].buftype == "" and info.lastused > latest then
			target, latest = info.bufnr, info.lastused
		end
	end
	if target then
		vim.api.nvim_set_current_buf(target)
	else
		vim.notify("no other real buffer", vim.log.levels.INFO)
	end
end, { desc = "Alternate real buffer" })

-- oil.nvim
vim.keymap.set("n", "<leader>e", function()
	require("oil").toggle_float()
end, { desc = "Toggle file explorer (float)" })
vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })

-- conform.nvim
vim.keymap.set({ "n", "v" }, "<leader>cf", function()
	require("conform").format({ lsp_format = "fallback" })
end, { desc = "Format buffer/selection" })

-- Save / quit
vim.keymap.set("n", "<leader>s", "<cmd>w<cr>", { desc = "Save buffer" })

-- Clear search highlight
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Exit terminal mode without the obscure default chord
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to upper window" })

-- Window resizing
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Balance the code splits without dragging the side panels along. `wincmd =`
-- already honours winfixwidth/winfixheight (that's why quickfix survives it, it
-- sets winfixheight itself), so flag the panels, balance, then put the flags
-- back. claudecode's native provider is the reason: it vsplits at 30% and never
-- fixes its width, so a bare <C-w>= blows it up to half the screen.
local panel_buftypes = { terminal = true, quickfix = true, nofile = true, help = true, prompt = true }

vim.keymap.set("n", "<leader>=", function()
	local saved = {}
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		-- floats aren't part of the layout, wincmd = ignores them anyway
		if vim.api.nvim_win_get_config(win).relative == "" then
			local buf = vim.api.nvim_win_get_buf(win)
			if panel_buftypes[vim.bo[buf].buftype] then
				saved[win] = { vim.wo[win].winfixwidth, vim.wo[win].winfixheight }
				vim.wo[win].winfixwidth = true
				vim.wo[win].winfixheight = true
			end
		end
	end

	vim.cmd("wincmd =")

	for win, fixed in pairs(saved) do
		if vim.api.nvim_win_is_valid(win) then
			vim.wo[win].winfixwidth, vim.wo[win].winfixheight = fixed[1], fixed[2]
		end
	end
end, { desc = "Balance windows (keep panels)" })

-- Move by visual line when a line wraps ("better up/down")
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Move selected lines up/down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep cursor centered while scrolling / jumping search results
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down, centered" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up, centered" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result, centered" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result, centered" })

-- Wheel scrolls the focused window, not whatever the pointer hovers over.
-- Default routes wheel by pointer position, so scrolling the CodeCompanion
-- split moves the code pane underneath it (:help scroll-mouse-wheel). 3 keeps
-- pace with mousescroll=ver:3.
vim.keymap.set("", "<ScrollWheelUp>", "3<C-y>", { desc = "Scroll up (focused window)" })
vim.keymap.set("", "<ScrollWheelDown>", "3<C-e>", { desc = "Scroll down (focused window)" })

-- Keep selection after indenting
vim.keymap.set("v", "<", "<gv", { desc = "Indent left, keep selection" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right, keep selection" })

-- Paste over selection without losing your yanked text
vim.keymap.set("v", "p", '"_dP', { desc = "Paste without overwriting register" })

-- Delete without yanking
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yanking" })

vim.keymap.set("n", "<D-s>", "<cmd>w<cr>", { desc = "Save (Cmd+S)" })
vim.keymap.set("i", "<D-s>", "<Esc><cmd>w<cr>", { desc = "Save (Cmd+S)" })
vim.keymap.set("v", "<D-s>", "<Esc><cmd>w<cr>", { desc = "Save (Cmd+S)" })

vim.keymap.set("n", "<leader>|", "<C-w>v", { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>-", "<C-w>s", { desc = "Split window horizontally" })

vim.keymap.set("n", "U", "<C-r>", { desc = "Redo" })
vim.keymap.set("n", "<leader>qq", "<cmd>qa!<cr>", { desc = "Quit Neovim (discard all unsaved changes)" })
vim.keymap.set("n", "<leader>wd", "<C-w>c", { desc = "Close window" })

vim.keymap.set("n", "<leader>xx", "<cmd>FzfLua diagnostics_workspace<cr>", { desc = "All diagnostics (project)" })

-- Soft line wrap toggle (window-local)
vim.keymap.set("n", "<leader>uw", function()
	vim.wo.wrap = not vim.wo.wrap
	vim.notify("wrap " .. (vim.wo.wrap and "on" or "off"))
end, { desc = "Toggle soft line wrap" })
