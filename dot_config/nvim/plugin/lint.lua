-- lefthook rejects commits on slim-lint, stylelint and eslint. rubocop already
-- reaches you through ruby_lsp, these three had no way in.
vim.pack.add({
	{ src = "https://github.com/mfussenegger/nvim-lint" },
})

local lint = require("lint")

-- no slim language server exists, so this is the only route. --reporter=json
-- because bundler writes its own noise to stderr and the plain reporter would
-- have to be regex'd out of it.
lint.linters.slim_lint = {
	cmd = "bundle",
	args = { "exec", "slim-lint", "--reporter=json" },
	stdin = false,
	append_fname = true,
	stream = "stdout",
	ignore_exitcode = true,
	parser = function(output)
		local ok, decoded = pcall(vim.json.decode, output)
		if not ok or type(decoded) ~= "table" or not decoded.files then
			return {}
		end
		local severities = {
			error = vim.diagnostic.severity.ERROR,
			warning = vim.diagnostic.severity.WARN,
		}
		local out = {}
		for _, file in ipairs(decoded.files) do
			for _, o in ipairs(file.offenses or {}) do
				table.insert(out, {
					lnum = (o.location.line or 1) - 1,
					col = 0,
					message = o.message,
					source = o.linter,
					severity = severities[o.severity] or vim.diagnostic.severity.WARN,
				})
			end
		end
		return out
	end,
}

-- the repo pins its own stylelint, the global one resolves a different config
lint.linters.stylelint.cmd = function()
	local local_bin = vim.fs.joinpath(vim.fn.getcwd(), "node_modules", ".bin", "stylelint")
	return vim.fn.executable(local_bin) == 1 and local_bin or "stylelint"
end

-- eslint_d forks a daemon on its first call and answers that one with startup
-- chatter instead of the JSON array, which the parser reports as a decode error
local eslint_d = lint.linters.eslint_d
local eslint_d_parser = eslint_d.parser
eslint_d.parser = function(output, bufnr)
	if not output:match("^%s*%[") then
		return {}
	end
	return eslint_d_parser(output, bufnr)
end

lint.linters_by_ft = {
	slim = { "slim_lint" },
	scss = { "stylelint" },
	css = { "stylelint" },
	postcss = { "stylelint" },
	javascript = { "eslint_d" },
}

-- on write only. slim_lint shells out to bundler, which is ~0.7s a run
vim.api.nvim_create_autocmd("BufWritePost", {
	callback = function()
		lint.try_lint()
	end,
})
