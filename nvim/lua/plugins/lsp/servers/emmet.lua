local M = {}
M.setup = function(capabilities, on_attach)
	return {
		filetypes = {
			"html",
			"css",
			"scss",
			"javascript",
			"typescriptreact",
			"vue",
			"svelte",
			"markdown",
			"xml",
		},
		init_options = {
			preferences = {},
			showAbbreviationSuggestions = true,
			showExpandedAbbreviation = "always",
			showSuggestionsAsSnippets = true,
		},
		settings = {
			emmet = {
				excludeLanguages = { "javascript", "typescript" },
				includeLanguages = {
					["svelte"] = "html",
				},
				-- Add these Svelte-specific settings
				syntaxProfiles = {
					svelte = {
						scriptType = "text/typescript", -- Helps identify script tags
					},
				},
				-- Configure which tags/attributes should be excluded
				excludeAttributesAndTags = {
					script = true, -- Exclude script tags
					style = false, -- Keep style tags enabled
				},
			},
		},
	}
end
return M
