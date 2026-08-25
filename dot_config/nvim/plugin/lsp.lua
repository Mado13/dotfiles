vim.pack.add({
	{ src = "https://github.com/neovim/nvim-lspconfig" },
})

vim.diagnostic.config({
	update_in_insert = false,
	severity_sort = true,
	underline = { severity = { min = vim.diagnostic.severity.WARN } },
	-- virtual_lines only under the cursor: it needs a whole line per diagnostic, so
	-- every one on screen shifts the code below it and the relative numbers with it.
	-- The line I'm reading is the one that needs the room; the rest get an eol note.
	virtual_lines = { current_line = true },
	virtual_text = { current_line = false },
	float = { source = "if_many" },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "✘",
			[vim.diagnostic.severity.WARN] = "▲",
			[vim.diagnostic.severity.INFO] = "●",
			[vim.diagnostic.severity.HINT] = "○",
		},
	},
	jump = {
		on_jump = function(_, bufnr)
			vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
		end,
	},
})

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = { globals = { "vim" } },
			workspace = {
				checkThirdParty = false,
				library = { vim.env.VIMRUNTIME },
			},
			telemetry = { enable = false },
		},
	},
})

vim.lsp.config("ruby_lsp", {
	init_options = {
		formatter = "auto",
		linters = { "rubocop" },
	},
})

-- the server only knows css/scss/less language ids, so .pcss has to pass as css
vim.lsp.config("cssls", {
	filetypes = { "css", "scss", "less", "postcss" },
	get_language_id = function(_, ft)
		return ft == "postcss" and "css" or ft
	end,
})

-- The two halves of the svelte <-> typescript bridge:
--
-- ts -> svelte: nvim-lspconfig's svelte config already sends
-- $/onDidChangeTsOrJsFile on BufWritePost for *.js/*.ts, so the svelte server
-- re-reads them (sveltejs/language-tools#2008). Nothing to do here.
--
-- svelte -> ts: tsserver can't read .svelte on its own. typescript-svelte-plugin
-- teaches it to, which is what makes gr/rename on a symbol in a .ts file find
-- its uses inside components. Registered the same way the VS Code extension
-- does it, via vtsls' globalPlugins.
--
-- location is a probe dir: tsserver requires <location>/node_modules/<name>,
-- so this is `npm root -g` minus the node_modules segment.
-- Install with: npm i -g typescript-svelte-plugin
vim.lsp.config("vtsls", {
	settings = {
		vtsls = {
			-- tsserver otherwise hands blink every global in scope on each keystroke,
			-- thousands in a big project, and blink filters them again anyway
			experimental = {
				completion = { enableServerSideFuzzyMatch = true, entriesLimit = 200 },
			},
			tsserver = {
				globalPlugins = {
					{
						name = "typescript-svelte-plugin",
						location = "/opt/homebrew/lib",
						-- projects pin their own typescript, so the probe path has
						-- to be passed for those too, not just the bundled tsdk
						enableForWorkspaceTypeScriptVersions = true,
					},
					{
						name = "@astrojs/ts-plugin",
						location = "/opt/homebrew/lib",
						enableForWorkspaceTypeScriptVersions = true,
					},
				},
			},
		},
	},
})

-- Third half of the bridge: changes made outside a nvim buffer (an agent, jj,
-- another editor) never reach the server. nvim's fs_event maps an atomic write
-- (temp file + rename) to Created, and svelte-language-server only re-reads a
-- snapshot on Changed - Created just adds unknown files to the project. So a
-- Props edit leaves the call site's error up until a restart. Re-send every
-- Created as a Changed too; the server's updateExistingFile is guarded by
-- hasFile, so it no-ops for a file that really is new.
vim.lsp.config("svelte", {
	on_init = function(client)
		local notify = client.notify
		client.notify = function(self, method, params)
			if method == "workspace/didChangeWatchedFiles" and params and params.changes then
				local changed = {}
				for _, change in ipairs(params.changes) do
					if change.type == 1 then
						table.insert(changed, { uri = change.uri, type = 2 })
					end
				end
				vim.list_extend(params.changes, changed)
			end
			return notify(self, method, params)
		end
	end,
})

-- astro-ls resolves typescript.tsdk from the project's own node_modules, so an
-- astro repo needs typescript as a devDep or the server won't start. Pin it to
-- 6.x: TS 7 dropped tsserverlibrary.js, which is the file that lookup wants.
-- Install with: npm i -g @astrojs/language-server @astrojs/ts-plugin

-- nvim only keeps .git, node_modules and .hg out of LSP file watchers, so one
-- vite build hands every server a few hundred changes and svelte answers each
-- batch with a workspace-wide diagnostic refresh. Generated output only, and
-- .svelte-kit stays in: the server wants its types/ back.
-- _poll_exclude_pattern is private, so skip it if an upgrade moves it.
local watchfiles_ok, watchfiles = pcall(require, "vim.lsp._watchfiles")
if watchfiles_ok and watchfiles._poll_exclude_pattern then
	for _, glob in ipairs({
		"**/dist/**",
		"**/build/**",
		"**/_build/**",
		"**/.next/**",
		"**/coverage/**",
		"**/tmp/**",
		-- capacitor copies the built bundle into both native projects
		"**/android/app/src/main/assets/**",
		"**/ios/App/App/public/**",
	}) do
		watchfiles._poll_exclude_pattern = watchfiles._poll_exclude_pattern + vim.glob.to_lpeg(glob)
	end
end

-- scss/css, json and the locale ymls had no server at all. Defaults are fine
-- for all three, they just need enabling. vscode-langservers-extracted also
-- ships an eslint server: nvim-lint covers eslint already, but switch to that
-- one if you ever want its "fix this rule" code actions.
vim.lsp.enable({
	"lua_ls",
	"ruby_lsp",
	"expert",
	"vtsls",
	"svelte",
	"astro",
	"cssls",
	"jsonls",
	"yamlls",
})

-- nvim keeps a server running after its last buffer closes, so a long session
-- piles up one per language I've touched. vim.lsp.enable starts it again on the
-- next matching FileType.
local idle_stop_ms = 5 * 60 * 1000
vim.api.nvim_create_autocmd("LspDetach", {
	callback = function(args)
		local id = args.data.client_id
		vim.defer_fn(function()
			local client = vim.lsp.get_client_by_id(id)
			if client and not client:is_stopped() and vim.tbl_isempty(client.attached_buffers) then
				client:stop()
			end
		end, idle_stop_ms)
	end,
})

-- Off by default in 0.12. Global enable is safe, it only attaches to clients
-- advertising textDocument/linkedEditingRange. Overlaps nvim-ts-autotag's tag
-- rename, but not its auto-close, so both stay.
vim.lsp.linked_editing_range.enable()

-- nvim binds gra/gri/grn/grr/grt/grx globally at startup, so a bare `gr` has to
-- wait timeoutlen to see whether a third key is coming. `gr` is references below
-- and gets pressed constantly, so drop the defaults and rebind the three that
-- have no equivalent here. gra/grn/grr duplicate <leader>ca, <leader>rn and gr.
for _, lhs in ipairs({ "gra", "gri", "grn", "grr", "grt", "grx" }) do
	pcall(vim.keymap.del, "n", lhs)
end

-- Keymaps only activate in buffers where a server actually attached
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local opts = { buffer = args.buf }
		vim.keymap.set("n", "gI", function()
			require("fzf-lua").lsp_implementations()
		end, opts)
		vim.keymap.set("n", "gy", function()
			require("fzf-lua").lsp_typedefs()
		end, opts)
		vim.keymap.set("n", "<leader>cl", vim.lsp.codelens.run, opts)
		vim.keymap.set("n", "gd", function()
			require("fzf-lua").lsp_definitions()
		end, opts)
		vim.keymap.set("n", "gr", function()
			require("fzf-lua").lsp_references()
		end, opts)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "[d", function()
			vim.diagnostic.jump({ count = -1 })
		end, opts)
		vim.keymap.set("n", "]d", function()
			vim.diagnostic.jump({ count = 1 })
		end, opts)
	end,
})

-- Not gated on LspAttach: if bound buffer-local only, pressing this before
-- the server attaches falls through to flash.nvim's bare "s" jump mapping
-- instead. fzf-lua just reports "no clients" if none are attached yet.
vim.keymap.set("n", "<leader>ss", function()
	require("fzf-lua").lsp_document_symbols()
end, { desc = "Document symbols" })
vim.keymap.set("n", "<leader>sS", function()
	require("fzf-lua").lsp_live_workspace_symbols()
end, { desc = "Workspace symbols" })

-- Fetch, not a view: results land in vim.diagnostic for files you never opened,
-- so <leader>xw / <leader>xx pick them up afterwards. Silent no-op on servers
-- that don't answer workspace/diagnostic.
vim.keymap.set("n", "<leader>xW", function()
	vim.lsp.buf.workspace_diagnostics()
end, { desc = "Pull project-wide diagnostics" })
