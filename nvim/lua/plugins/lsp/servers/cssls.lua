local M = {}

M.setup = function(capabilities, on_attach)
	return {
		capabilities = capabilities,
		on_attach = on_attach,
		settings = {
			css = {
				-- Ignore unknown at-rules (e.g., from PostCSS or SASS)
				lint = { unknownAtRules = "ignore" },

				-- Enable helpful CSS linting rules
				validate = true,

				-- Fine-tune hover and autocompletion settings
				completion = {
					triggerPropertyValueCompletion = true, -- Trigger suggestions for property values
					completePropertyWithSemicolon = true, -- Completes properties with semicolons
				},

				-- Enable custom data for CSS for any custom properties or additional frameworks
				customData = { "/path/to/custom/data.json" }, -- Specify path if using custom properties or frameworks
			},

			scss = {
				lint = {
					unknownAtRules = "ignore", -- Ignore at-rules like `@extend` or `@mixin`
				},
				validate = true,
			},

			less = {
				validate = true,
			},
		},
		filetypes = { "css", "scss", "less" },
	}
end

return M
