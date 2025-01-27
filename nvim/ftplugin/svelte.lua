-- Automatically end a self-closing tag when pressing / in Svelte files
vim.keymap.set("i", "/", function()
	local node = vim.treesitter.get_node()
	if not node then
		return "/"
	end

	-- Check if the node is a Svelte element node by looking up the tag structure
	local node_type = node:type()
	if node_type == "start_tag" or node_type == "self_closing_tag" then
		local line = vim.fn.getline(".")
		local col = vim.fn.col(".") - 2
		local char_at_cursor = vim.fn.strcharpart(vim.fn.strpart(line, col), 0, 1)
		local already_have_space = char_at_cursor == " "
		local char_after_cursor = vim.fn.strcharpart(vim.fn.strpart(line, col + 1), 0, 1)

		if char_after_cursor == ">" then
			return already_have_space and "/" or " /"
		end
		return already_have_space and "/>" or " />"
	end

	return "/"
end, { expr = true, buffer = true })
