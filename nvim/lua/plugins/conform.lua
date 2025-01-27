return {
	"stevearc/conform.nvim",
	cmd = { "ConformInfo" },
	keys = {
		-- Simple format
		{
			"<leader>fm",
			function()
				require("conform").format()
			end,
			desc = "Format current buffer",
		},
		{
			"<leader>fr",
			function()
				require("conform").format({ range = true })
			end,
			mode = { "v" },
			desc = "Format range",
		},
		{
			"<leader>fw",
			function()
				require("conform").format({
					async = true,
					lsp_fallback = true,
					callback = function(err)
						if not err then
							vim.cmd("write")
						end
					end,
				})
			end,
			desc = "Format and write",
		},
	},
	opts = {
		format_on_save = {
			timeout_ms = 3000,
			lsp_fallback = true,
		},
		-- Move the format check to the root level
		format = function(bufnr)
			-- Check if buffer exists and is valid
			if not bufnr or type(bufnr) ~= "number" then
				bufnr = vim.api.nvim_get_current_buf()
			end

			-- Check file size
			local line_count = vim.api.nvim_buf_line_count(bufnr)
			if line_count > 10000 then
				return
			end

			return {
				timeout_ms = 3000,
				lsp_fallback = true,
			}
		end,
		formatters = {
			rubocop = {
				args = { "--server", "--auto-correct-all", "--stderr", "--force-exclusion", "--stdin", "$FILENAME" },
			},
		},
		notify_on_error = true,
		formatters_by_ft = {
			javascript = { "prettierd" },
			javascriptreact = { "prettierd" },
			typescript = { "prettierd" },
			typescriptreact = { "prettierd" },
			svelte = { "prettierd" },
			elixir = { "mix" },
			ruby = { "rubocop" },
			lua = { "stylua" },
			pug = { "prettierd" },
			sql = { "sqlfmt" },
			yaml = { "yamlfmt" },
			php = { "pretty-php" },
			vue = { "prettierd" },
		},
	},
}
