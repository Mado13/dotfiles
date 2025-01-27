local M = {}

-- Cache for project size detection
local project_size_cache = {}

-- Helper to determine project size and complexity
local function get_project_info(bufnr)
    local cwd = vim.fn.getcwd()
    
    if project_size_cache[cwd] then
        return project_size_cache[cwd]
    end
    
    -- Count TypeScript/JavaScript files in project
    local ts_files = vim.fn.systemlist('find . -type f -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" | wc -l')
    local file_count = tonumber(ts_files[1]) or 0
    
    -- Check for specific React patterns
    local has_react = vim.fn.findfile("node_modules/react/package.json", ".;") ~= ""
    local is_next = vim.fn.findfile("next.config.js", ".;") ~= ""
    
    project_size_cache[cwd] = {
        size = file_count,
        is_large = file_count > 500,
        has_react = has_react,
        is_next = is_next
    }
    
    return project_size_cache[cwd]
end

-- Clear cache on relevant events
vim.api.nvim_create_autocmd({"DirChanged", "BufWritePost"}, {
    pattern = {"*.ts", "*.tsx", "*.js", "*.jsx"},
    callback = function()
        project_size_cache = {}
    end
})

M.setup = function(capabilities, on_attach)
    local function enhanced_on_attach(client, bufnr)
        local project_info = get_project_info(bufnr)
        local file_size = vim.fn.getfsize(vim.api.nvim_buf_get_name(bufnr))
        
        -- Optimize features based on file/project size
        if file_size > 500000 or project_info.is_large then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
            -- Disable some inlay hints for large files
            client.config.settings.vtsls.typescript.inlayHints.variableTypes.enabled = false
            client.config.settings.vtsls.typescript.inlayHints.parameterTypes.enabled = false
        end
        
        -- Call original on_attach
        on_attach(client, bufnr)
        
        -- Add React-specific keymaps if it's a React project
        if project_info.has_react then
            local function map(mode, lhs, rhs, desc)
                vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
            end
            
            -- React-specific actions
            map("n", "<leader>rc", function()
                require('typescript').actions.addMissingImports()
                require('typescript').actions.organizeImports()
            end, "Organize React imports")
            
            -- Toggle component/test file
            map("n", "<leader>rt", function()
                local current_file = vim.fn.expand('%')
                local test_file = current_file:gsub('%.tsx?$', '.test.tsx')
                if vim.fn.filereadable(test_file) == 1 then
                    vim.cmd('edit ' .. test_file)
                else
                    local component_file = current_file:gsub('%.test%.tsx?$', '.tsx')
                    vim.cmd('edit ' .. component_file)
                end
            end, "Toggle test file")
        end
    end

    -- Optimize capabilities for TypeScript/React
    local enhanced_capabilities = vim.tbl_deep_extend("force", capabilities, {
        textDocument = {
            completion = {
                completionItem = {
                    snippetSupport = true,
                    commitCharactersSupport = true,
                    deprecatedSupport = true,
                    preselectSupport = true,
                    tagSupport = {
                        valueSet = {
                            1  -- JSX/TSX tag completion
                        }
                    },
                    resolveSupport = {
                        properties = {
                            "documentation",
                            "detail",
                            "additionalTextEdits",
                        }
                    }
                },
                contextSupport = true
            },
            codeLens = {
                dynamicRegistration = false  -- Disable for performance
            }
        }
    })

    return {
        capabilities = enhanced_capabilities,
        on_attach = enhanced_on_attach,
        settings = {
            complete_function_calls = true,
            vtsls = {
                enableMoveToFileCodeAction = true,
                autoUseWorkspaceTsdk = true,
                experimental = {
                    completion = {
                        enableServerSideFuzzyMatch = true,
                        -- Enable caching for better performance
                        enableCache = true,
                        cacheSize = 100
                    },
                    diagnostics = {
                        ignoredCodes = {
                            7016,  -- Could not find declaration file
                            6133,  -- Declared but never used
                        }
                    },
                    enableProjectDiagnostics = true,
                },
                javascript = {
                    format = {
                        enable = false,  -- Use external formatter for better performance
                        insertSpaceAfterOpeningAndBeforeClosingEmptyBraces = false,
                        insertSpaceAfterOpeningAndBeforeClosingNonemptyBraces = false,
                    },
                    updateImportsOnFileMove = { 
                        enabled = "always",
                        allowRenames = true
                    },
                    suggest = { 
                        completeFunctionCalls = true,
                        classMemberSnippets = { enabled = true },
                        objectLiteralMethodSnippets = { enabled = true },
                        autoImports = true,
                        enabled = true
                    },
                    inlayHints = {
                        enumMemberValues = { enabled = true },
                        functionLikeReturnTypes = { enabled = true },
                        parameterNames = { enabled = "literals" },
                        parameterTypes = { enabled = true },
                        propertyDeclarationTypes = { enabled = true },
                        variableTypes = { enabled = false },  -- Disable for performance
                    },
                },
                typescript = {
                    updateImportsOnFileMove = { 
                        enabled = "always",
                        allowRenames = true
                    },
                    suggest = { 
                        completeFunctionCalls = true,
                        classMemberSnippets = { enabled = true },
                        objectLiteralMethodSnippets = { enabled = true },
                        autoImports = true,
                        enabled = true
                    },
                    format = {
                        enable = false,  -- Use external formatter for better performance
                        insertSpaceAfterOpeningAndBeforeClosingEmptyBraces = false,
                        insertSpaceAfterOpeningAndBeforeClosingNonemptyBraces = false,
                    },
                    inlayHints = {
                        enumMemberValues = { enabled = true },
                        functionLikeReturnTypes = { enabled = true },
                        parameterNames = { enabled = "literals" },
                        parameterTypes = { enabled = true },
                        propertyDeclarationTypes = { enabled = true },
                        variableTypes = { enabled = false },  -- Disable for performance
                    },
                },
                maxTsServerMemory = 4096,
                disableAutomaticTypingAcquisition = false,
                enableReferencesCodeLens = true,
                enableImplementationsCodeLens = true,
            },
        },
        flags = {
            debounce_text_changes = 150,
            allow_incremental_sync = true,
        },
    }
end

return M
