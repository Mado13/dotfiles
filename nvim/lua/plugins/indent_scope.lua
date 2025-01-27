return {
  {
    "echasnovski/mini.indentscope",
    version = false,
    event = { "BufReadPre", "BufNewFile" },  -- More precise than BufEnter
    opts = {
      symbol = "│",
      options = { 
        try_as_border = true,
        priority = 2,  -- Prevent decoration conflicts
      },
      draw = {
        delay = 100,  -- Small delay to prevent performance impact
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "fzf",
          "help",
          "lazy",
          "mason",
          "notify",
          "oil",
          "Oil",
          "Trouble",
          "trouble",
        },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,
  },
}
