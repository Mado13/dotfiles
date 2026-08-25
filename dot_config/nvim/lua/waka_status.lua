-- All-time Wakapi total for the current jj bookmark, the same one wakatime-jj reports
local M = {}

local text = ""
-- Wakapi ignores a branch filter here and returns every branch of the project
local URL = "http://127.0.0.1:3000/api/summary?interval=all_time&project=%s"
-- must match ~/.local/bin/wakatime-jj, or the lookup finds a branch nothing was logged under
local BM_REVSET = "latest(heads(::@ & bookmarks()))"
local BM_TMPL = 'local_bookmarks.map(|b| b.name()).join(",")'

local function auth()
	for line in io.lines(vim.fn.expand("~/.wakatime.cfg")) do
		local key = line:match("^api_key%s*=%s*(%S+)")
		if key then
			return "Authorization: Basic " .. vim.base64.encode(key)
		end
	end
end

local function set(new)
	text = new
	vim.schedule(function()
		vim.cmd("redrawstatus")
	end)
end

local function format(secs)
	local h, m = math.floor(secs / 3600), math.floor(secs % 3600 / 60)
	return h > 0 and ("%dh %dm"):format(h, m) or ("%dm"):format(m)
end

function M.refresh()
	local root = vim.fs.root(0, ".jj")
	if not root then
		return set("")
	end
	local header = auth()
	local jj = { "jj", "log", "--no-graph", "--ignore-working-copy", "-r", BM_REVSET, "-T", BM_TMPL }
	vim.system(jj, { text = true, cwd = root }, function(out)
		local branch = vim.trim(out.stdout or "")
		if out.code ~= 0 or branch == "" then
			return set("")
		end
		local project = vim.fs.basename(root)
		local url = URL:format(vim.uri_encode(project, "rfc3986"))
		vim.system({ "curl", "-sf", "-m", "5", "-H", header, url }, { text = true }, function(res)
			local ok, summary = pcall(vim.json.decode, res.stdout or "")
			local total = 0
			for _, b in ipairs(ok and summary.branches or {}) do
				if b.key == branch then
					total = b.total
				end
			end
			set("󱎫 " .. format(total))
		end)
	end)
end

function M.section()
	return text
end

function M.setup()
	local grp = vim.api.nvim_create_augroup("WakaStatus", { clear = true })
	vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "DirChanged" }, { group = grp, callback = M.refresh })
	vim.uv.new_timer():start(0, 60000, vim.schedule_wrap(M.refresh))
end

return M
