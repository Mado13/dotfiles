local M = {}

M.setup = function(capabilities, on_attach)
	return {
		cmd = { "/Users/Matan/.local/share/nvim/mason/bin/elixir-ls" },
		capabilities = capabilities,
		on_attach = on_attach,
		settings = {
			elixirLS = {
				-- Enable dialyzer for static analysis and type checking
				dialyzerEnabled = true,
				
				-- Disable fetching deps automatically to prevent delays; fetch them manually if needed
				fetchDeps = false,

				-- Enable signature help and autocompletion
				suggestSpecs = true, -- Suggest specs for functions to improve type safety
				signatureHelp = true, -- Shows function parameter hints
				experimental = {
					goToDefinitionWhenFunctionIsCalled = true, -- Jumps to the definition on function calls
				},

				-- Auto-formatting settings
				formatter = {
					enable = false, -- Disable if using a separate formatter like `mix format`
				},

				-- Enable project-specific analysis for better performance and less noise
			},
		},
		filetypes = { "elixir", "eelixir" },
	}
end

return M
