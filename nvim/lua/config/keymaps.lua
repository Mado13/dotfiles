local map = require("user.keymap_utils")

-- better up/down
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- Move Lines
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- Clear search and stop snippet on escape
map({ "i", "n", "s" }, "<esc>", function()
	vim.cmd("noh")
	-- LazyVim.cmp.actions.snippet_stop() - Need to implement the cmp action
	return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Add undo break-points
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- commenting
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

-- lazy
map("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- lists
map("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
map("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })
map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- diagnostic
local diagnostic_goto = function(next, severity)
	local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
	severity = severity and vim.diagnostic.severity[severity] or nil
	return function()
		go({ severity = severity })
	end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

-- quit
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })

-- highlights under cursor
map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
map("n", "<leader>uI", "<cmd>InspectTree<cr>", { desc = "Inspect Tree" })

-- windows
map("n", "<leader>w", "<c-w>", { desc = "Windows", remap = true })
map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })

-- save
map({ "i", "x", "n", "s" }, "<D-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- delete text to black hole register
map({ "n", "v" }, "<leader>d", [["_d]])

-- switch lasy buffer
map("n", "<leader>'", "<C-^>", { desc = "Switch to last buffer" })

-- Map Oil to <leader>e
map("n", "<leader>e", function()
	require("oil").toggle_float()
end)

-- -- Center buffer while navigating
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up and center" })
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down and center" })
map("n", "{", "{zz", { desc = "Previous paragraph and center" })
map("n", "}", "}zz", { desc = "Next paragraph and center" })
map("n", "N", "Nzz", { desc = "Previous search result and center" })
map("n", "n", "nzz", { desc = "Next search result and center" })
map("n", "G", "Gzz", { desc = "Go to end of file and center" })
map("n", "gg", "ggzz", { desc = "Go to start of file and center" })
map("n", "<C-i>", "<C-i>zz", { desc = "Jump forward and center" })
map("n", "<C-o>", "<C-o>zz", { desc = "Jump back and center" })
map("n", "%", "%zz", { desc = "Match bracket and center" })
map("n", "*", "*zz", { desc = "Search word under cursor and center" })
map("n", "#", "#zz", { desc = "Search word under cursor backwards and center" })

-- Press 'S' for quick find/replace for the word under the cursor
map("n", "S", function()
	local cmd = ":%s/<C-r><C-w>/<C-r><C-w>/gI<Left><Left><Left>"
	local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)
	vim.api.nvim_feedkeys(keys, "n", false)
end, { desc = "Replace word under cursor" })

-- Open Spectre for global find/replace
map("n", "<leader>S", function()
	require("spectre").toggle()
end)

-- Open Spectre for global find/replace for the word under the cursor in normal mode
map("n", "<leader>sw", function()
	require("spectre").open_visual({ select_word = true })
end, { desc = "Search current word" })

-- Place all diagnostics into a qflist
map("n", "<leader>ld", vim.diagnostic.setqflist, { desc = "Set Diagnostics to Quickfix" })

-- Press leader rw to rotate open windows
map("n", "<leader>rw", ":RotateWindows<cr>", { desc = "[R]otate [W]indows" })

-- Press gx to open the link under the cursor
map("n", "gx", ":sil !open <cWORD><cr>", { silent = true })

-- TSC autocommand keybind to run TypeScripts tsc
map("n", "<leader>tc", ":TSC<cr>", { desc = "[T]ypeScript [C]ompile" })

-- Git keymaps --
map("n", "<leader>gb", "<cmd>BlameToggle<cr>")

-- nvim-ufo keybinds
map("n", "zR", require("ufo").openAllFolds, { desc = "Open all folds" })
map("n", "zM", require("ufo").closeAllFolds, { desc = "Close all folds" })

-- Paste without losing the contents of the register
map("x", "<leader>p", '"_dP', { desc = "Paste without yank" })

-- Terminal --
-- Enter normal mode while in a terminal
map("t", "<Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- -- Window navigation from terminal
map("t", "<C-h>", [[<Cmd>wincmd h<CR>]], { desc = "Go to left window" })
map("t", "<C-j>", [[<Cmd>wincmd j<CR>]], { desc = "Go to lower window" })
map("t", "<C-k>", [[<Cmd>wincmd k<CR>]], { desc = "Go to upper window" })
map("t", "<C-l>", [[<Cmd>wincmd l<CR>]], { desc = "Go to right window" })

map("n", "<leader>ld", "<cmd>lua _LAZYDOCKER_TOGGLE()<CR>", { desc = "[L]azydocker [T]oggle" })

-- ToggleTerm
map("n", "<leader>tf", ":ToggleTerm direction=float<CR>")
map("n", "<leader>th", ":ToggleTerm direction=horizontal<CR>")
map("n", "<leader>tv", ":ToggleTerm direction=vertical<CR>")
