-- Only in the throwaway nvim that jj is blocked on, never a real session.
-- The var comes from ~/.config/jj/scripts/jj-editor.sh.
if vim.env.JJ_DESCRIPTION_EDITOR == "1" then
	-- <C-w>c on a last window is E444, so finishing has to quit instead.
	vim.keymap.set("n", "<leader>wd", "<cmd>xa<cr>", { buffer = true, desc = "Save description, back to jj" })

	-- Only a non-zero exit aborts. Quitting unsaved leaves jj the template,
	-- which already holds both descriptions, so the squash goes through anyway.
	vim.keymap.set("n", "<leader>qq", "<cmd>cq<cr>", { buffer = true, desc = "Abort, leave jj alone" })
end
