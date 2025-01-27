local M = {}

M.setup = function(capabilities, on_attach)
	return {
		capabilities = capabilities,
		on_attach = on_attach,
		settings = {
			yaml = {
				schemaStore = {
					enable = true,
					-- Avoid TypeError: Cannot read properties of undefined (reading 'length')
					url = "",
				},
				schemas = require("schemastore").yaml.schemas(),
			},
		},
	}
end

return M
