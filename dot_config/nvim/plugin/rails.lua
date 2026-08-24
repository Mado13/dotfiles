vim.pack.add({
	-- projectionist is vim-rails' engine, not optional: :A/:R/:E* and
	-- .projections.json (custom alternate/related, STI, non-standard layouts)
	-- all come from it. Without it vim-rails runs degraded.
	{ src = "https://github.com/tpope/vim-projectionist" },
	{ src = "https://github.com/tpope/vim-rails" },
})

-- vim-rails is command-first. :A / :R and the :E* family (Emodel, Econtroller,
-- Eview, Espec, Emigration, Ejob, ... all tab-completable) carry most of the
-- weight, so only the two navigation moves you hit constantly get keymaps.
--
-- Gated on the `User Rails` event (fired per-buffer when vim-rails detects a
-- rails app) so :A/:R only bind where they actually exist. Outside a rails repo
-- these keys stay unmapped instead of erroring with "not an editor command".
-- They're buffer-local, same as the LspAttach maps, and nest under <leader>rn
-- (rename): brief timeoutlen wait before rename fires. Move rename if it bugs you.
vim.api.nvim_create_autocmd("User", {
	pattern = "Rails",
	callback = function(ev)
		local function map(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
		end
		map("<leader>ra", "<cmd>A<cr>", "Rails: alternate (impl <-> spec)")
		map("<leader>rA", "<cmd>AV<cr>", "Rails: alternate in vsplit")
		map("<leader>rr", "<cmd>R<cr>", "Rails: related file")
		map("<leader>rR", "<cmd>RV<cr>", "Rails: related in vsplit")
	end,
})
