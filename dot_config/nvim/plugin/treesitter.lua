vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  -- only here for its textobjects.scm queries, mini.ai's `af`/`ac` read them
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
})

-- nvim core has no .slim rule, so filetype stays empty and the FileType
-- autocmd below never starts treesitter for slim files
vim.filetype.add({
  extension = { slim = "slim" },
})

require("nvim-treesitter").setup({
  install_dir = vim.fn.stdpath("data") .. "/site",
})

-- Parsers matching your actual stack: Ruby/Rails, Elixir/Phoenix, Svelte, JS/TS
require("nvim-treesitter").install({
  "lua", "vim", "vimdoc", "query",
  "ruby", "slim",
  "elixir", "heex", "eex",
  "javascript", "typescript", "tsx", "svelte",
  "html", "css", "json", "yaml", "toml",
  "bash", "markdown", "markdown_inline",
  "git_config", "gitcommit", "gitignore", "diff", "jjdescription",
})

-- Manually enable highlighting per buffer (main branch doesn't auto-enable anything)
vim.api.nvim_create_autocmd("FileType", {
  callback = function(event)
    if vim.b[event.buf].bigfile then
      return
    end
    pcall(vim.treesitter.start)
  end,
})
