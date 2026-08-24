require("circleci").setup()

vim.keymap.set("n", "<leader>ci", function()
	require("circleci").toggle()
end, { desc = "CircleCI: latest run for this bookmark" })

vim.keymap.set("n", "<leader>cI", function()
	require("circleci").refetch()
end, { desc = "CircleCI: refetch latest run" })
