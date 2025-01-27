return {
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		config = function()
			local conditions = {
				buffer_not_empty = function()
					return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
				end,
				hide_in_width = function()
					return vim.fn.winwidth(0) > 80
				end,
			}

			local config = {
				options = {
					theme = "gruvbox-material",

					globalstatus = true,
					component_separators = "│",
					section_separators = "",
				},
				sections = {
					lualine_a = {
						{
							function()
								return " "
							end,
							padding = { left = 0, right = 0 },
						},
					},
					lualine_b = {
						{
							"branch",
							icon = "",
						},
						{
							"diff",
							symbols = { added = " ", modified = " ", removed = " " },

							cond = conditions.hide_in_width,
						},
					},
					lualine_c = {
						{
							"filename",
							file_status = true,
							path = 1,
							symbols = {
								modified = "●",
								readonly = "",
								unnamed = "[No Name]",
							},
						},
					},
					lualine_x = {
						{
							"diagnostics",
							sources = { "nvim_diagnostic" },
							symbols = { error = " ", warn = " ", info = " ", hint = " " },
						},
						{
							function()
								local msg = "No LSP"
								local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
								local clients = vim.lsp.get_active_clients()
								if next(clients) == nil then
									return msg
								end
								for _, client in ipairs(clients) do
									local filetypes = client.config.filetypes
									if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
										return client.name
									end
								end
								return msg
							end,
							icon = " ",
						},
					},
					lualine_y = {
						{
							"filetype",
							colored = true,
							icon_only = false,
						},
						{
							"encoding",
							fmt = string.upper,
							cond = conditions.hide_in_width,
						},
					},
					lualine_z = {
						{
							"location",
						},
					},
				},
				inactive_sections = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = { "filename" },
					lualine_x = { "location" },
					lualine_y = {},
					lualine_z = {},
				},
				extensions = { "fugitive", "nvim-tree", "quickfix" },
			}

			require("lualine").setup(config)
		end,
	},
}
