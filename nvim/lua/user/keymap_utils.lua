local M = {}

---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@param opts? table
function M.safe_keymap_set(mode, lhs, rhs, opts)
	local modes = type(mode) == "string" and { mode } or mode
	opts = vim.tbl_extend("force", { silent = true }, opts or {})
	vim.keymap.set(modes, lhs, rhs, opts)
end

-- Create the map function directly
local map = M.safe_keymap_set

-- Usage examples:
-- map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Find Files" })
-- map({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
-- map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Down" })

return map
