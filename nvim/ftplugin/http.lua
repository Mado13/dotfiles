local nnoremap = require("user.keymap_utils").nnoremap
local vnoremap = require("user.keymap_utils").vnoremap
local inoremap = require("user.keymap_utils").inoremap
local tnoremap = require("user.keymap_utils").tnoremap
local xnoremap = require("user.keymap_utils").xnoremap

nnoremap("<C-k>", ":lua require('kulala').jump_prev()<CR>", { noremap = true, silent = true })
nnoremap("<C-j>", ":lua require('kulala').jump_next()<CR>", { noremap = true, silent = true })
nnoremap("<C-l>", ":lua require('kulala').run()<CR>", { noremap = true, silent = true })
