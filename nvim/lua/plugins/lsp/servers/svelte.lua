local M = {}

M.setup = function(capabilities, on_attach)
    return {
        cmd = { "svelteserver", "--stdio" },
        capabilities = capabilities,
        on_attach = function(client, bufnr)
            on_attach(client, bufnr)
            
            -- Watch for TypeScript/JavaScript file changes
            vim.api.nvim_create_autocmd("BufWritePost", {
                pattern = { "*.ts", "*.js", "*.tsx", "*.jsx" },
                callback = function(ctx)
                    -- Notify svelte server of TS/JS file changes
                    client.notify("$/onDidChangeTsOrJsFile", { uri = vim.uri_from_fname(ctx.file) })
                    
                    -- Force reload of all Svelte LSP servers
                    vim.schedule(function()
                        -- Get all buffer numbers
                        local bufs = vim.api.nvim_list_bufs()
                        
                        -- For each buffer
                        for _, buf in ipairs(bufs) do
                            -- Check if it's a .svelte file
                            local bufname = vim.api.nvim_buf_get_name(buf)
                            if bufname:match("%.svelte$") then
                                -- Get clients for this buffer
                                local clients = vim.lsp.get_active_clients({ bufnr = buf })
                                for _, c in ipairs(clients) do
                                    if c.name == "svelte" then
                                        -- Restart this specific client
                                        vim.schedule(function()
                                            c.stop()
                                            vim.defer_fn(function()
                                                require('lspconfig').svelte.launch()
                                            end, 100)
                                        end)
                                    end
                                end
                            end
                        end
                    end)
                end,
                group = vim.api.nvim_create_augroup("SvelteTypeScriptSync", { clear = true })
            })
        end,
        filetypes = { "svelte" },
        init_options = {
            configuration = {
                typescript = {
                    serverPath = "" -- This will use the locally installed TypeScript
                }
            }
        },
        settings = {
            svelte = {
                plugin = {
                    svelte = {
                        diagnostic = {
                            enable = true,
                            mode = "workspace",
                        },
                        format = { enable = true },
                        codeActions = {
                            enable = true,
                        },
                        hover = {
                            enable = true,
                        },
                        completions = {
                            enable = true,
                        },
                    },
                    typescript = {
                        enable = true,
                        diagnostics = {
                            enable = true,
                        },
                        hover = {
                            enable = true,
                        },
                        completions = {
                            enable = true,
                        },
                        codeActions = {
                            enable = true,
                        }
                    }
                }
            }
        }
    }
end

return M
