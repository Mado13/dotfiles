local M = {}

-- Cache the bundler check result
local bundler_check_cache = {}
local function has_bundler()
	local cwd = vim.fn.getcwd()
	if bundler_check_cache[cwd] == nil then
		local gemfile = cwd .. "/Gemfile"
		bundler_check_cache[cwd] = vim.fn.filereadable(gemfile) == 1
	end
	return bundler_check_cache[cwd]
end

-- Clear cache when directory changes
vim.api.nvim_create_autocmd("DirChanged", {
	callback = function()
		bundler_check_cache = {}
	end,
})

local function ruby_on_attach(client, bufnr, base_on_attach)
	base_on_attach(client, bufnr)

	-- Get file size for conditional features
	local file_size = vim.fn.getfsize(vim.api.nvim_buf_get_name(bufnr))
	local max_file_size = 500 * 1024 -- 500KB threshold

	-- Disable heavy features for large files
	if file_size > max_file_size then
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentRangeFormattingProvider = false
		client.server_capabilities.documentHighlightProvider = false
	end

	local function map(mode, lhs, rhs, desc)
		vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
	end

	-- Optimize Ruby file execution with async job
	map("n", "<leader>rt", function()
		local cmd = has_bundler() and "bundle exec ruby -w " or "ruby -w "
		local file = vim.fn.expand("%")

		vim.fn.jobstart(cmd .. file, {
			stdout_buffered = true,
			stderr_buffered = true,
			on_stdout = function(_, data)
				if data then
					vim.schedule(function()
						vim.notify(table.concat(data, "\n"), vim.log.levels.INFO)
					end)
				end
			end,
			on_stderr = function(_, data)
				if data then
					vim.schedule(function()
						vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
					end)
				end
			end,
		})
	end, "Run Ruby file")

	-- Optimize RSpec execution with async job
	map("n", "<leader>rs", function()
		local cmd = has_bundler() and "bundle exec rspec " or "rspec "
		local file = vim.fn.expand("%")

		vim.fn.jobstart(cmd .. file, {
			stdout_buffered = true,
			stderr_buffered = true,
			on_stdout = function(_, data)
				if data then
					vim.schedule(function()
						vim.notify(table.concat(data, "\n"), vim.log.levels.INFO)
					end)
				end
			end,
			on_stderr = function(_, data)
				if data then
					vim.schedule(function()
						vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
					end)
				end
			end,
		})
	end, "Run RSpec file")
end

M.setup = function(capabilities, on_attach)
	-- Cache the command determination
	local cmd = has_bundler() and { "bundle", "exec", "solargraph", "stdio" }
		or { "asdf", "exec", "solargraph", "stdio" }

	-- Optimize capabilities for better performance
	local optimized_capabilities = vim.tbl_deep_extend("force", capabilities, {
		textDocument = {
			completion = {
				completionItem = {
					snippetSupport = true,
					resolveSupport = {
						properties = { "documentation", "detail" },
					},
					-- Limit the number of completion items for better performance
					dynamicRegistration = false,
					commitCharactersSupport = false,
				},
			},
			-- Disable sync features that might not be necessary
			synchronization = {
				dynamicRegistration = false,
				willSave = false,
				willSaveWaitUntil = false,
				didSave = true,
			},
		},
	})

	return {
		cmd = cmd,
		capabilities = optimized_capabilities,
		on_attach = function(client, bufnr)
			ruby_on_attach(client, bufnr, on_attach)
		end,
		settings = {
			solargraph = {
				diagnostics = false, -- Disable built-in diagnostics for better performance
				completion = true,
				hover = true,
				folding = false,
				useBundler = has_bundler(),
				logLevel = "warn",
				maxPreloadFileSize = 500000,
				checkGemVersion = false,
				formatting = false,
				completion_links = false,
				inlayHints = { enabled = false },
				-- Add performance-related settings
				transport = "stdio", -- More efficient than HTTP
				promptTimeout = 2000, -- 2 second timeout
				commandPath = "", -- Let solargraph find its own path
				bundlerPath = "bundle",
				viewsPath = nil, -- Disable view path searching
				maxFilesInProject = 5000,
				reporters = {}, -- Disable reporters for better performance
			},
		},
		init_options = {
			maxComputationTime = 2000,
			formatting = false,
			-- Add caching options
			cacheDirectory = vim.fn.stdpath("cache") .. "/solargraph",
			enableCacheSync = true,
		},
		flags = {
			debounce_text_changes = 150, -- Increased debounce time
			allow_incremental_sync = true,
			-- Add additional performance flags
			exit_timeout = 5000, -- 5 second timeout for exit
			sync_timeout = 2000, -- 2 second timeout for sync
		},
		filetypes = { "ruby", "rakefile", "rb" },
		root_dir = require("lspconfig.util").root_pattern("Gemfile", ".git"),
		-- Add single_file_support for better standalone file handling
		single_file_support = true,
	}
end

return M
