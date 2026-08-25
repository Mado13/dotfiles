vim.pack.add({
	-- projectionist is vim-rails' engine, not optional: :A/:R/:E* and
	-- .projections.json (custom alternate/related, STI, non-standard layouts)
	-- all come from it. Without it vim-rails runs degraded.
	{ src = "https://github.com/tpope/vim-projectionist" },
	{ src = "https://github.com/tpope/vim-rails" },
})

-- vim-rails is command-first. :A / :R and the :E* family (Emodel, Econtroller,
-- Eview, Espec, Emigration, Ejob, ... all tab-completable) carry most of the
-- weight. Types beyond vim-rails' own (policy, validator, serializer, ...) come
-- from rails-templates.lua.
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

		-- the :E commands run bare, jumping to the current file's sibling
		-- (controller -> model). When that fails (no sibling, or a type that needs
		-- a name like stimulus) the cmdline opens instead, <tab> completes names.
		-- The :S/:V/:T variants open the same thing in split/vsplit/tab.
		local edit = {
			m = { "model", "model" },
			c = { "controller", "controller" },
			v = { "view", "view" },
			j = { "job", "job" },
			h = { "helper", "helper" },
			M = { "mailer", "mailer" },
			s = { "spec", "spec" },
			d = { "migration", "migration" },
			p = { "policy", "policy" },
			V = { "validator", "validator" },
			S = { "serializer", "serializer" },
			C = { "concern", "concern" },
			t = { "stimulus", "stimulus controller" },
			L = { "cell", "cell" },
			E = { "resource", "resource" },
		}
		for key, e in pairs(edit) do
			map("<leader>r" .. key, function()
				if not pcall(vim.cmd, "E" .. e[1]) then
					vim.api.nvim_feedkeys(":E" .. e[1] .. " ", "n", false)
				end
			end, "Rails: edit " .. e[2])
		end
	end,
})
