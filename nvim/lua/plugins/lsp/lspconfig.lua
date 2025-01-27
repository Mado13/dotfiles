local M = {}

M.setup = function()
	return {
		{
			"williamboman/mason.nvim",
			cmd = "Mason",
			build = ":MasonUpdate",
			opts = {
				ui = { border = "rounded" },
			},
		},
		{
			"williamboman/mason-lspconfig.nvim",
			event = "VeryLazy",
			dependencies = { "mason.nvim", "nvim-lspconfig" },
			opts = {
				ensure_installed = {
					"tailwindcss",
					"cssls",
					"lua_ls",
					"eslint",
					"elixirls",
					"emmet_language_server",
					"bashls",
					"dockerls",
					"jsonls",
					"solargraph",
					"yamlls",
					"vtsls",
					"svelte",
				},
				automatic_installation = true,
			},
		},
		{
			"neovim/nvim-lspconfig",
			event = { "BufReadPre", "BufNewFile" },
			dependencies = {
				"mason.nvim",
				"mason-lspconfig.nvim",
				"hrsh7th/cmp-nvim-lsp",
				{ "folke/neodev.nvim", opts = {} },
			},
			config = function()
				-- Optimize diagnostic settings
				vim.diagnostic.config({
					virtual_text = {
						spacing = 4,
						prefix = "●",
						severity = { min = vim.diagnostic.severity.WARN },
						source = "if_many",
					},
					signs = true,
					severity_sort = true,
					underline = true,
					float = {
						border = "rounded",
						source = "if_many",
						max_width = 100,
						focusable = false,
					},
					update_in_insert = false,
				})

				vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
					border = "rounded", -- Options: 'none', 'single', 'double', 'rounded', 'solid', 'shadow'
				})

				-- Cache frequently used functions
				local lspconfig = require("lspconfig")
				local tbl_deep_extend = vim.tbl_deep_extend

				-- Define keymap function outside on_attach
				local function map_lsp_keys(bufnr)
					local function map(mode, keys, func, description)
						vim.keymap.set(
							mode,
							keys,
							func,
							{ buffer = bufnr, desc = description, noremap = true, silent = true }
						)
					end

					map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
					map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
					map("n", "gd", vim.lsp.buf.definition, "Goto Definition")
					map("n", "gl", vim.diagnostic.open_float, "Open diagnostics")
					map("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
					map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
					map("n", "<leader>hd", vim.lsp.buf.hover, "Hover Documentation")
					map("n", "gr", vim.lsp.buf.references, "Goto References")
					map("n", "gi", vim.lsp.buf.implementation, "Goto Implementation")
					map("n", "gD", vim.lsp.buf.declaration, "Goto Declaration")
					map("n", "td", vim.lsp.buf.type_definition, "Type Definition")
					map("n", "<leader>k", vim.lsp.buf.signature_help, "Signature Documentation")
					map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")
					map("n", "<leader>f", function()
						require("conform").format({ async = true, lsp_fallback = true })
					end, "Format buffer")
				end

				-- on_attach function with optimizations
				local function on_attach(client, bufnr)
					-- Cache file size
					local bufname = vim.api.nvim_buf_get_name(bufnr)
					local file_size = vim.fn.getfsize(bufname)
					local max_file_size = 100 * 1024 -- 100 KB

					if file_size > max_file_size then
						client.server_capabilities.semanticTokensProvider = nil
						vim.diagnostic.disable(bufnr)
					end

					map_lsp_keys(bufnr)

					-- Document highlight setup for small files
					if file_size <= max_file_size and client.server_capabilities.documentHighlightProvider then
						local group = vim.api.nvim_create_augroup("LSPDocumentHighlight", { clear = true })
						vim.opt.updatetime = 300

						vim.api.nvim_create_autocmd("CursorHold", {
							group = group,
							buffer = bufnr,
							callback = function()
								if not vim.b[bufnr].lsp_highlight_disabled then
									vim.lsp.buf.document_highlight()
								end
							end,
						})

						vim.api.nvim_create_autocmd("CursorMoved", {
							group = group,
							buffer = bufnr,
							callback = vim.lsp.buf.clear_references,
						})

						vim.api.nvim_buf_create_user_command(bufnr, "ToggleLspHighlight", function()
							vim.b[bufnr].lsp_highlight_disabled = not vim.b[bufnr].lsp_highlight_disabled
						end, { desc = "Toggle LSP document highlighting" })
					end
				end

				-- Define and optimize capabilities
				local capabilities = vim.lsp.protocol.make_client_capabilities()
				capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

				capabilities.textDocument.completion.completionItem = {
					snippetSupport = true,
					preselectSupport = false,
					insertReplaceSupport = false,
					labelDetailsSupport = false,
					deprecatedSupport = false,
					commitCharactersSupport = false,
					documentationFormat = { "markdown" },
					tagSupport = { valueSet = {} },
					resolveSupport = {
						properties = {
							"documentation",
							"detail",
							"additionalTextEdits",
						},
					},
				}

				-- Define default configuration
				local default_config = {
					capabilities = capabilities,
					on_attach = on_attach,
					flags = {
						debounce_text_changes = 150,
						allow_incremental_sync = true,
					},
				}

				-- Server-specific configurations
				local servers = {
					tailwindcss = {},
					emmet_language_server = require("plugins.lsp.servers.emmet").setup(capabilities, on_attach),
					bashls = { filetypes = { "sh", "zsh" } },
					cssls = require("plugins.lsp.servers.cssls").setup(capabilities, on_attach),
					elixirls = require("plugins.lsp.servers.elixirls").setup(capabilities, on_attach),
					yamlls = require("plugins.lsp.servers.yamlls").setup(capabilities, on_attach),
					jsonls = require("plugins.lsp.servers.jsonls").setup(capabilities, on_attach),
					solargraph = require("plugins.lsp.servers.solargraph").setup(capabilities, on_attach),
					vtsls = require("plugins.lsp.servers.vtsls").setup(capabilities, on_attach),
					svelte = require("plugins.lsp.servers.svelte").setup(capabilities, on_attach),
				}

				-- Setup each server with merged configurations
				for server, config in pairs(servers) do
					lspconfig[server].setup(tbl_deep_extend("force", default_config, config))
				end
			end,
		},
	}
end

return M
