-- jjui browses, this runs the one-shot commands. Both names are registered
-- because jj_status.lua owns JjRefresh: ":J" is otherwise ambiguous and ":Jj"
-- resolves to JjRefresh and rejects the arguments.

-- these open $EDITOR, which is this nvim, so they need a terminal or they deadlock
local EDITOR_CMDS = { "c", "ci", "commit", "desc", "describe", "diffedit", "resolve", "si", "split" }

--- @return string[] stdout lines, empty if the command failed
local function jj(args)
	local res = vim.system(vim.list_extend({ "jj" }, args), { text = true }):wait()
	return res.code == 0 and vim.split(vim.trim(res.stdout or ""), "\n", { trimempty = true }) or {}
end

local function refresh()
	vim.cmd("checktime")
	pcall(vim.cmd, "JjRefresh")
	pcall(require("gitsigns").refresh)
	require("waka_status").refresh()
end

local function run(argstr)
	-- a shell, not an argv list: nvim's fargs ignores quotes, so a quoted -m
	-- value would arrive as several arguments
	local cmd = { "sh", "-c", "jj " .. argstr }
	local sub = argstr:match("^%s*(%S+)") or ""

	if vim.tbl_contains(EDITOR_CMDS, sub) and not argstr:match("%-%-?m%f[%s=]") then
		vim.cmd("botright 15split")
		vim.fn.jobstart(cmd, { term = true, on_exit = vim.schedule_wrap(refresh) })
		vim.cmd("startinsert")
		return
	end

	vim.system(cmd, { text = true }, vim.schedule_wrap(function(res)
		local out = vim.trim((res.stdout or "") .. (res.stderr or ""))
		if out ~= "" then
			vim.notify(out, res.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
		end
		refresh()
	end))
end

local subcommands
local function complete(arglead, cmdline)
	local candidates
	if cmdline:match("^%s*Jj?%s+%S+%s") then
		candidates = jj({ "bookmark", "list", "--all-remotes", "-T", 'name ++ "\\n"' })
		vim.list_extend(candidates, { "@", "@-", "trunk()" })
	else
		if not subcommands then
			subcommands = {}
			for _, alias in ipairs(jj({ "config", "list", "aliases", "-T", 'name ++ "\\n"' })) do
				subcommands[#subcommands + 1] = alias:gsub("^aliases%.", "")
			end
			-- jj --help indents each subcommand by two spaces
			for _, line in ipairs(jj({ "--help" })) do
				local name = line:match("^  ([a-z][a-z%-]+)%s")
				subcommands[#subcommands + 1] = name or nil
			end
		end
		candidates = subcommands
	end
	return vim.tbl_filter(function(c)
		return vim.startswith(c, arglead)
	end, vim.fn.uniq(vim.fn.sort(candidates)))
end

for _, name in ipairs({ "J", "Jj" }) do
	vim.api.nvim_create_user_command(name, function(opts)
		run(opts.args)
	end, { nargs = "+", complete = complete, desc = "Run a jj command" })
end
