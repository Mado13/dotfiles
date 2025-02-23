-- Automatically end a self-closing tag when pressing /
vim.keymap.set("i", "/", function()
	local node = vim.treesitter.get_node()
	if not node then
		return "/"
	end

	if node:type() == "jsx_opening_element" or node:type() == "jsx_self_closing_element" then
		local char_at_cursor = vim.fn.strcharpart(vim.fn.strpart(vim.fn.getline("."), vim.fn.col(".") - 2), 0, 1)
		local already_have_space = char_at_cursor == " "
		local char_after_cursor = vim.fn.strcharpart(vim.fn.strpart(vim.fn.getline("."), vim.fn.col(".") - 1), 0, 1)
		if char_after_cursor == ">" then
			return already_have_space and "/" or " /"
		end
		return already_have_space and "/>" or " />"
	end

	return "/"
end, { expr = true, buffer = true })
