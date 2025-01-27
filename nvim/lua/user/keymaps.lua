local nnoremap = require("user.keymap_utils").nnoremap
local vnoremap = require("user.keymap_utils").vnoremap
local inoremap = require("user.keymap_utils").inoremap
local tnoremap = require("user.keymap_utils").tnoremap
local xnoremap = require("user.keymap_utils").xnoremap

local M = {}

local TERM = os.getenv("TERM")

-- Normal --
  nnoremap("p", "p=`]")
nnoremap("<C-j>", function()
	if vim.fn.exists(":KittyNavigateDown") ~= 0 and TERM == "xterm-kitty" then
		vim.cmd.KittyNavigateDown()
	elseif vim.fn.exists(":NvimTmuxNavigateDown") ~= 0 then
		vim.cmd.NvimTmuxNavigateDown()
	else
		vim.cmd.wincmd("j")
	end
end)

nnoremap("<C-k>", function()
	if vim.fn.exists(":KittyNavigateUp") ~= 0 and TERM == "xterm-kitty" then
		vim.cmd.KittyNavigateUp()
	elseif vim.fn.exists(":NvimTmuxNavigateUp") ~= 0 then
		vim.cmd.NvimTmuxNavigateUp()
	else
		vim.cmd.wincmd("k")
	end
end)

nnoremap("<C-l>", function()
	if vim.fn.exists(":KittyNavigateRight") ~= 0 and TERM == "xterm-kitty" then
		vim.cmd.KittyNavigateRight()
	elseif vim.fn.exists(":NvimTmuxNavigateRight") ~= 0 then
		vim.cmd.NvimTmuxNavigateRight()
	else
		vim.cmd.wincmd("l")
	end
end)

nnoremap("<C-h>", function()
	if vim.fn.exists(":KittyNavigateLeft") ~= 0 and TERM == "xterm-kitty" then
		vim.cmd.KittyNavigateLeft()
	elseif vim.fn.exists(":NvimTmuxNavigateLeft") ~= 0 then
		vim.cmd.NvimTmuxNavigateLeft()
	else
		vim.cmd.wincmd("h")
	end
end)

-- Delete text to black hole register
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- Disable Space bar since it'll be used as the leader key
nnoremap("<space>", "<nop>")
nnoremap("<leader>'", "<C-^>", { desc = "Switch to last buffer" })

-- Save with leader key
nnoremap("<leader>w", "<cmd>w<cr>", { silent = false })

-- Quit with leader key
nnoremap("<leader>q", "<cmd>q<cr>", { silent = false })

-- Map Oil to <leader>e
nnoremap("<leader>e", function()
	require("oil").toggle_float()
end)

-- Center buffer while navigating
nnoremap("<C-u>", "<C-u>zz")
nnoremap("<C-d>", "<C-d>zz")
nnoremap("{", "{zz")
nnoremap("}", "}zz")
nnoremap("N", "Nzz")
nnoremap("n", "nzz")
nnoremap("G", "Gzz")
nnoremap("gg", "ggzz")
nnoremap("<C-i>", "<C-i>zz")
nnoremap("<C-o>", "<C-o>zz")
nnoremap("%", "%zz")
nnoremap("*", "*zz")
nnoremap("#", "#zz")

-- Press 'S' for quick find/replace for the word under the cursor
nnoremap("S", function()
	local cmd = ":%s/<C-r><C-w>/<C-r><C-w>/gI<Left><Left><Left>"
	local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)
	vim.api.nvim_feedkeys(keys, "n", false)
end)

-- Open Spectre for global find/replace
nnoremap("<leader>S", function()
	require("spectre").toggle()
end)

-- Open Spectre for global find/replace for the word under the cursor in normal mode
nnoremap("<leader>sw", function()
	require("spectre").open_visual({ select_word = true })
end, { desc = "Search current word" })

-- Press 'H', 'L' to jump to start/end of a line (first/last char)
nnoremap("L", "$")
nnoremap("H", "^")

-- Press 'U' for redo
nnoremap("U", "<C-r>")

-- Turn off highlighted results
nnoremap("<leader>no", "<cmd>noh<cr>")

-- Diagnostics

-- Goto next diagnostic of any severity
nnoremap("]d", function()
	vim.diagnostic.goto_next({})
	vim.api.nvim_feedkeys("zz", "n", false)
end)

-- Goto previous diagnostic of any severity
nnoremap("[d", function()
	vim.diagnostic.goto_prev({})
	vim.api.nvim_feedkeys("zz", "n", false)
end)

-- Goto next error diagnostic
nnoremap("]e", function()
	vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
	vim.api.nvim_feedkeys("zz", "n", false)
end)

-- Goto previous error diagnostic
nnoremap("[e", function()
	vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
	vim.api.nvim_feedkeys("zz", "n", false)
end)

-- Goto next warning diagnostic
nnoremap("]w", function()
	vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN })
	vim.api.nvim_feedkeys("zz", "n", false)
end)

-- Goto previous warning diagnostic
nnoremap("[w", function()
	vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.WARN })
	vim.api.nvim_feedkeys("zz", "n", false)
end)

-- Open the diagnostic under the cursor in a float window
nnoremap("<leader>d", function()
	vim.diagnostic.open_float({
		border = "rounded",
	})
end)

-- Place all diagnostics into a qflist
nnoremap("<leader>ld", vim.diagnostic.setqflist, { desc = "Quickfix [L]ist [D]iagnostics" })

-- Navigate to next qflist item
nnoremap("<leader>cn", ":cnext<cr>zz")

-- Navigate to previous qflist item
nnoremap("<leader>cp", ":cprevious<cr>zz")

-- Open the qflist
-- nnoremap("<leader>co", ":copen<cr>zz")

-- Close the qflist
nnoremap("<leader>cc", ":cclose<cr>zz")

-- Map MaximizerToggle (szw/vim-maximizer) to leader-m
nnoremap("<leader>m", ":MaximizerToggle<cr>")

-- Resize split windows to be equal size
nnoremap("<leader>=", "<C-w>=")

-- Press leader f to format
nnoremap("<leader>f", function()
	require("conform").format()
end, { desc = "Format the current buffer" })

-- Press leader rw to rotate open windows
nnoremap("<leader>rw", ":RotateWindows<cr>", { desc = "[R]otate [W]indows" })

-- Press gx to open the link under the cursor
nnoremap("gx", ":sil !open <cWORD><cr>", { silent = true })

-- TSC autocommand keybind to run TypeScripts tsc
nnoremap("<leader>tc", ":TSC<cr>", { desc = "[T]ypeScript [C]ompile" })

-- Git keymaps --
nnoremap("<leader>prc", "<cmd>:Octo pr create<CR>", { desc = "[C]reate [P]ull [R]equest" })
nnoremap("<leader>pr", "<cmd>:Octo actions<CR>", { desc = "[O]cto [P]ull [R]equest actions" })
nnoremap("<leader>gb", "<cmd>BlameToggle<cr>")

-- LSP Keybinds (exports a function to be used in ../../after/plugin/lsp.lua b/c we need a reference to the current buffer) --
M.map_lsp_keybinds = function(buffer_number)
	nnoremap("<leader>rn", vim.lsp.buf.rename, { desc = "LSP: [R]e[n]ame", buffer = buffer_number })
	nnoremap("<leader>ca", vim.lsp.buf.code_action, { desc = "LSP: [C]ode [A]ction", buffer = buffer_number })

	nnoremap("gd", vim.lsp.buf.definition, { desc = "LSP: [G]oto [D]efinition", buffer = buffer_number })
	nnoremap("gr", "<cmd>Lspsaga finder ref<CR>", { desc = "LSP: [G]oto [R]eferences", buffer = buffer_number })
	nnoremap("gi", "<cmd>Lspsaga finder imp<CR>", { desc = "LSP: [G]oto [I]mplementation", buffer = buffer_number })

	-- See `:help K` for why this keymap
	nnoremap("K", vim.lsp.buf.hover, { desc = "LSP: Hover Documentation", buffer = buffer_number })
	nnoremap("<leader>k", vim.lsp.buf.signature_help, { desc = "LSP: Signature Documentation", buffer = buffer_number })
	inoremap("<C-k>", vim.lsp.buf.signature_help, { desc = "LSP: Signature Documentation", buffer = buffer_number })

	-- Lesser used LSP functionality
	nnoremap("gD", vim.lsp.buf.declaration, { desc = "LSP: [G]oto [D]eclaration", buffer = buffer_number })
	nnoremap("td", vim.lsp.buf.type_definition, { desc = "LSP: [T]ype [D]efinition", buffer = buffer_number })
end

nnoremap("<leader>pd", "<cmd>Lspsaga peek_definition<CR>", { desc = "LSP: Peek Definition" })

-- Symbol Outline keybind
nnoremap("<leader>so", ":SymbolsOutline<cr>")

-- nvim-ufo keybinds
nnoremap("zR", require("ufo").openAllFolds)
nnoremap("zM", require("ufo").closeAllFolds)

-- Ror keybinds
nnoremap("<leader>tr", "<cmd>lua _RAILS_TOGGLE()<CR>", { desc = "[R]ails[T]oggle" })
-- Rails Commands
nnoremap("<Leader>ro", ":RorCommands<CR>", { silent = true, desc = "RoR Commands" })
nnoremap("<Leader>rg", ":RorGenerators<CR>", { silent = true })
nnoremap("<Leader>rf", ":RorFinders<CR>", { silent = true })

-- Navigation
nnoremap("<Leader>rt", ":lua require('ror.navigations').go_to_test('vsplit')<CR>", { silent = true })
nnoremap("<Leader>rc", ":lua require('ror.navigations').go_to_controller('vsplit')<CR>", { silent = true })
nnoremap("<Leader>rm", ":lua require('ror.navigations').go_to_model('vsplit')<CR>", { silent = true })

--Finders
nnoremap("<Leader>rfv", ":lua require('ror.finders.view').find()<CR>", { silent = true })
nnoremap("<Leader>rfc", ":lua require('ror.finders.controller').find()<CR>", { silent = true })
nnoremap("<Leader>rfm", ":lua require('ror.finders.model').find()<CR>", { silent = true })
nnoremap("<Leader>rfg", ":lua require('ror.finders.migration').find()<CR>", { silent = true })

--Tests
nnoremap("<Leader>rrt", ":lua require('ror.test').run()<CR>", { silent = true })
nnoremap("<Leader>rtl", ":lua require('ror.test').run('Line')<CR>", { silent = true })

--Utilities
nnoremap("<Leader>rr", ":lua require('ror.routes').list_routes()<CR>", { silent = true })
nnoremap("<Leader>rdm", ":lua require('ror.runners.db_migrate').run()<CR>", { silent = true })
nnoremap("<Leader>rbi", ":lua require('ror.runners.bundle_install').run()<CR>", { silent = true })
nnoremap("<Leader>rdr", ":lua require('ror.runners.db_rollback').run()<CR>", { silent = true })

-- Insert --

-- Visual --
-- Disable Space bar since it'll be used as the leader key
vnoremap("<space>", "<nop>")

-- Press 'H', 'L' to jump to start/end of a line (first/last char)
vnoremap("L", "$<left>")
vnoremap("H", "^")

-- Paste without losing the contents of the register
vnoremap("<A-j>", ":m '>+1<CR>gv=gv")
vnoremap("<A-k>", ":m '<-2<CR>gv=gv")

-- Reselect the last visual selection
xnoremap("<<", function()
	xnoremap("<leader>p", '"_dP')

	-- Move selected text up/down in visual mode
	vim.cmd("normal! <<")
	vim.cmd("normal! gv")
end)

xnoremap(">>", function()
	vim.cmd("normal! >>")
	vim.cmd("normal! gv")
end)

-- Terminal --
-- Enter normal mode while in a terminal
tnoremap("jk", [[<C-\><C-n>]])

-- Window navigation from terminal
tnoremap("<C-h>", [[<Cmd>wincmd h<CR>]])
tnoremap("<C-j>", [[<Cmd>wincmd j<CR>]])
tnoremap("<C-k>", [[<Cmd>wincmd k<CR>]])
tnoremap("<C-l>", [[<Cmd>wincmd l<CR>]])
nnoremap("<leader>ld", "<cmd>lua _LAZYDOCKER_TOGGLE()<CR>", { desc = "[L]azydocker [T]oggle" })

-- Re-enable default <space> functionality to prevent input delay
tnoremap("<space>", "<space>")

-- ToggleTerm
nnoremap("<leader>tf", ":ToggleTerm direction=float<CR>")
nnoremap("<leader>th", ":ToggleTerm direction=horizontal<CR>")
nnoremap("<leader>tv", ":ToggleTerm direction=vertical<CR>")

nnoremap("<leader>sv", ":vsplit<CR>")
nnoremap("<leader>ss", ":split<Return><C-w>w", { desc = "Split window horizontally" })

return M
