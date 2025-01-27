local M = {}

M.setup = function(capabilities, on_attach)
	return {
		capabilities = capabilities,
		on_attach = on_attach,
		settings = {
			-- Disable ESLint formatting if using Prettier or another formatter
			format = false, 

			-- ESLint settings to control linting behavior
			-- This setting will try to fix problems on save, non-intrusively
			autoFixOnSave = true,
			autoFixOnFormat = false, -- Disable to avoid conflict with other formatters

			-- Run ESLint in "onSave" or "onType" mode; "onSave" reduces noise
			run = "onSave",

			-- ESLint library location, useful if using a workspace version
			packageManager = "yarn", -- or "npm" based on project setup

			-- Display diagnostics only for problems
			diagnostics = {
				severity = "warning", -- Show warnings and errors only, no info or hint level
			},
		},
	}
end

return M
