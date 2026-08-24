local M = {}

local cache = { id = "", text = "" }

local SEP = "\x1f"
-- @ info: short change id + status flags
local INFO_TMPL = table.concat({
	"change_id.shortest(8)",
	'"' .. SEP .. '"',
	'if(empty, "empty", "")',
	'"' .. SEP .. '"',
	'if(conflict, "conflict", "")',
}, " ++ ")
-- nearest bookmark at or above @ (::@ includes @, so a bookmark on @ wins)
local BM_REVSET = "heads(bookmarks() & ::@)"
local BM_TMPL = 'local_bookmarks.map(|b| b.name()).join(",")'

-- run jj read-only; cb gets (ok, trimmed_stdout) on the main loop
local function jj(revset, template, cb)
	vim.system(
		{ "jj", "log", "--no-graph", "--color", "never", "--ignore-working-copy", "-r", revset, "-T", template },
		{ text = true },
		function(out)
			-- callback is a fast event context; vim.fn.* is banned there, so defer
			vim.schedule(function()
				cb(out.code == 0, vim.trim(out.stdout or ""))
			end)
		end
	)
end

local function refresh()
	if vim.fn.executable("jj") == 0 then
		return
	end
	jj("@", INFO_TMPL, function(ok, stdout)
		if not ok then
			cache = { id = "", text = "" }
			vim.cmd("redrawstatus")
			return
		end
		local id, empty, conflict = unpack(vim.split(stdout, SEP, { plain = true }))

		jj(BM_REVSET, BM_TMPL, function(_, bm)
			bm = vim.trim(bm)

			local label = bm ~= "" and bm or id -- detached: fall back to change id

			local parts = { "󱗆 " .. label }
			if conflict == "conflict" then
				parts[#parts + 1] = "✗"
			elseif empty == "empty" then
				parts[#parts + 1] = "(empty)"
			end

			cache = { id = id, text = table.concat(parts, " ") }
			vim.cmd("redrawstatus")
		end)
	end)
end

function M.section(args)
	if cache.text == "" then
		return ""
	end
	if MiniStatusline.is_truncated(args.trunc_width) then
		return "󱗆 " .. cache.id
	end
	return cache.text
end

function M.setup()
	local grp = vim.api.nvim_create_augroup("JjStatus", { clear = true })
	vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "DirChanged", "BufWritePost" }, {
		group = grp,
		callback = refresh,
	})
	vim.api.nvim_create_user_command("JjRefresh", refresh, {})
	refresh()
end

return M
