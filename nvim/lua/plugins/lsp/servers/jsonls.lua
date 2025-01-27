
local M = {}

M.setup = function(capabilities, on_attach)
	return {
		capabilities = capabilities,
		on_attach = on_attach,
		settings = {
			json = {
				schemas = require('schemastore').json.schemas(),
				validate = { enable = true },
			},
		},
	}
end

return M

