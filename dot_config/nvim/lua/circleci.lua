-- CircleCI for the current jj bookmark, in two halves.
--
-- Pull: <leader>ci asks about the latest run and gets out of the way.
--   running or green -> a toast, nothing opens
--   tests failed     -> one trouble row per failure, za for the full rspec output
--   lint failed      -> the failed steps' raw output in a float, q to close
-- The result is cached, so pressing it again just toggles the panel. Only
-- <leader>cI goes back to the API, which costs about 2s.
--
-- Push: after `jj git push` (from the CLI or jjui) the run is watched in the
-- background and you get one toast when it lands. It never steals your window,
-- because by then you are usually on a different bookmark. Go to the failed one
-- and press <leader>ci to see why. The statusline carries ✓ / ✗ / ◌ meanwhile.

local M = {}

-- nearest non-trunk bookmark at or below @. `@-` is wrong: it misses a bookmark
-- sitting on @ itself and reports the parent's bookmark (usually main) instead.
local BM_REVSET = "heads(::@ & bookmarks() ~ trunk())"
local BM_TMPL = 'local_bookmarks.map(|b| b.name()).join(",")'

local FIELD, RECORD = "\x1f", "\x1e"
local OP_TMPL = ("id.short(12) ++ %q ++ description ++ %q"):format(FIELD, RECORD)

local TICK_MS = 15000 -- how often to look for a new push
local POLL_MS = 30000 -- how often to re-ask about a run we are waiting on
local MAX_POLLS = 90 -- give up after 45 minutes

local state = {
	bookmark = nil,
	kind = nil, -- "qf" | "raw", nil when there is nothing to show
	payload = nil, -- quickfix items, or lines of raw output
	busy = false,
	buf = nil,
	win = nil,
}

local watches = {} -- branch -> { commit or run_id, root, polls }
local resume -- defined with the watch code, but fetch below needs to call it
local outcomes = {} -- branch -> "running" | "succeeded" | "failed"
local last_op = nil -- newest jj operation we have already looked at
local seeded = false -- whether we have established that starting point yet
local current = nil -- current bookmark, for the statusline
local timer = nil

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO)
end

local function label(branch, text)
	return ("󱗆 %s  %s"):format(branch or "?", text)
end

-- Outcomes that ended without anything to investigate. Everything else that has
-- ended is treated as a failure worth opening, because circleci also emits
-- infrastructure_fail, timedout, error and unauthorized, and shrugging at an
-- outcome we forgot to enumerate would hide a real failure.
local SETTLED_OK = { succeeded = true, canceled = true, cancelled = true }

local function is_failure(outcome)
	return outcome ~= nil and not SETTLED_OK[outcome]
end

-- nil when not inside a repo. Walks up from cwd rather than the current buffer,
-- because this also runs from a background timer where the buffer may be a
-- terminal with no path at all.
local function root()
	return vim.fs.root(vim.fn.getcwd(), { ".jj", ".git" })
end

local function sh(cmd, cb, cwd)
	vim.system(cmd, { text = true, cwd = cwd or root() }, function(out)
		vim.schedule(function()
			cb(out)
		end)
	end)
end

-- Everything needed before this can say anything useful. vim.system throws on a
-- missing executable, and without .circleci the CLI answers with a confusing VCS
-- error instead of "this repo has no CI".
local function usable()
	if vim.fn.executable("jj") == 0 or vim.fn.executable("circleci") == 0 then
		return false, "jj and circleci must both be on PATH"
	end
	local repo = root()
	if not repo then
		return false, "not inside a jj repo"
	end
	-- anchored to the repo root, never a cwd fallback: ~/.circleci is the CLI's
	-- own config dir, so falling back would say yes anywhere under $HOME
	if not vim.uv.fs_stat(repo .. "/.circleci") then
		return false, "no .circleci in this repo"
	end
	return true
end

-------------------------------------------------------------------------- parsing

-- the CLI reports API failures as a JSON body on stdout *and* a non-zero exit,
-- so the body is worth reading either way
function M.decode(out)
	local ok, data = pcall(vim.json.decode, out.stdout or "", { luanil = { object = true } })
	if not ok or type(data) ~= "table" then
		local err = vim.trim(out.stderr or "")
		return nil, err ~= "" and err or "circleci call failed"
	end
	if data.error then
		return nil, data.message or "circleci call failed"
	end
	return data
end

-- backtrace paths arrive as ./spec/foo_spec.rb, or absolute under the container
function M.localize(path)
	path = path:gsub("^/home/circleci/project/", "")
	return (path:gsub("^%./", ""))
end

-- rspec dots its classname: spec.system.gauges_exports_spec
function M.spec_file(classname)
	return (classname or ""):gsub("%.", "/") .. ".rb"
end

-- Prefer the frame in the spec file itself (where the test is) over the topmost
-- frame, which is usually a shared helper.
-- The `#` is optional because rspec prints backtraces both ways depending on the
-- formatter: bare `./spec/foo.rb:1:in ...` and commented `# ./spec/foo.rb:1:in ...`
function M.locate(tr)
	local want, first = M.spec_file(tr.classname), nil
	for line in (tr.message or ""):gmatch("[^\n]+") do
		local path, lnum = line:match("^%s*#?%s*([^:%s]+%.rb):(%d+)")
		if path then
			local frame = { filename = M.localize(path), lnum = tonumber(lnum) }
			first = first or frame
			if frame.filename == want then
				return frame
			end
		end
	end
	return first
end

-- non-blank lines of a failure message, indentation kept
function M.detail(msg)
	local out = {}
	for line in (msg or ""):gmatch("[^\n]+") do
		if vim.trim(line) ~= "" then
			out[#out + 1] = (line:gsub("%s+$", ""))
		end
	end
	return out
end

-- The first line is always `Failure/Error: <the code that raised>`, which says
-- nothing about why. When rspec has an exception it prints the class on its own
-- line with the reason indented under it, and that pair is the useful part.
-- A plain `expect` failure has no such header, so fall back to the first line.
function M.summary(msg)
	local lines = M.detail(msg)
	for i, line in ipairs(lines) do
		local class = vim.trim(line):match("^(%u[%w_:]*):$")
		if class and lines[i + 1] then
			return class .. ": " .. vim.trim(lines[i + 1])
		end
	end
	return lines[1] and (vim.trim(lines[1]):gsub("^Failure/Error:%s*", "")) or ""
end

-- A re-run leaves the superseded workflow in the run, so the same job name can
-- appear twice with different outcomes. A later pass wins over an earlier fail.
-- Only ended jobs count: current_outcome on a queued or running job is a
-- prediction ("nothing has failed yet") and would mask a real failure.
function M.failed_jobs(run)
	local best, order = {}, {}
	for _, wf in ipairs(run.workflows or {}) do
		for _, job in ipairs(wf.jobs or {}) do
			if job.name and job.id and job.phase == "ended" then
				if best[job.name] == nil then
					order[#order + 1] = job.name
					best[job.name] = { id = job.id, name = job.name, outcome = job.outcome }
				elseif job.outcome == "succeeded" then
					best[job.name] = { id = job.id, name = job.name, outcome = job.outcome }
				end
			end
		end
	end
	local out = {}
	for _, name in ipairs(order) do
		if is_failure(best[name].outcome) then
			out[#out + 1] = best[name]
		end
	end
	return out
end

local EXAMPLE_KEYWORDS = { it = true, scenario = true, specify = true, example = true }

-- is this line an rspec example opener, and what is its literal description?
function M.example_at(line)
	local kw = line:match("^%s*([a-z_]+)")
	if not kw or not EXAMPLE_KEYWORDS[kw] then
		return false
	end
	return true, line:match("^%s*[a-z_]+%s*%(?%s*['\"]([^'\"]*)['\"]")
end

-- The line rspec prints in its rerun command, which is also what the CircleCI UI
-- shows. It is not in the payload anywhere: the backtrace gives the line that
-- raised, usually somewhere further into the example. Examples cannot nest, so
-- the one that encloses the failure is the nearest opener above it.
function M.example_line(lines, from, name)
	for i = math.min(from, #lines), 1, -1 do
		local is_example, desc = M.example_at(lines[i])
		if is_example then
			-- the full name is the describe/context chain plus this string, so a
			-- suffix match confirms this is the right example and not a neighbour
			if desc and desc ~= "" and name:sub(-#desc) == desc then
				return i
			end
			return nil -- an example, but not this one: do not guess
		end
	end
end

-- `testresult list` is JSONL, one object per line, not an array
function M.qf_items(stdout, base, read)
	read = read
		or function(path)
			return vim.fn.filereadable(path) == 1 and vim.fn.readfile(path) or nil
		end
	local cache = {}
	local function source(path)
		if cache[path] == nil then
			cache[path] = read(path) or false
		end
		return cache[path] or nil
	end

	local items = {}
	for line in (stdout or ""):gmatch("[^\n]+") do
		local ok, tr = pcall(vim.json.decode, line, { luanil = { object = true } })
		if ok and type(tr) == "table" and (tr.result == "failure" or tr.result == "error") then
			local at = M.locate(tr) or { filename = M.spec_file(tr.classname), lnum = 1 }
			local name = tr.name or "?"
			local path = base .. "/" .. at.filename
			local lnum, text = at.lnum, name .. " | " .. M.summary(tr.message)

			local lines = source(path)
			local example = lines and M.example_line(lines, at.lnum, name)
			if example then
				-- land on the example, keep the raising line in the text
				lnum = example
				text = ("%s | :%d %s"):format(name, at.lnum, M.summary(tr.message))
			end

			-- user_data because setqflist round-trips that one and ignores the rest
			items[#items + 1] =
				{ filename = path, lnum = lnum, text = text, type = "E", user_data = M.detail(tr.message) }
		end
	end
	return items
end

-- first failed step, and which parallel execution it ran in
function M.failed_step(job_json)
	for _, ex in ipairs(job_json.executions or {}) do
		for _, s in ipairs(ex.steps or {}) do
			if s.outcome == "failed" then
				return s, ex.index or 0
			end
		end
	end
end

-- a single-bookmark push names it; bulk pushes do not, so those fall back to
-- whatever bookmark we are on
function M.pushed_bookmarks(stdout, stop_at)
	local names, bulk, newest = {}, false, nil
	for _, record in ipairs(vim.split(stdout or "", RECORD, { plain = true })) do
		local id, desc = unpack(vim.split(record, FIELD, { plain = true }))
		id = id and vim.trim(id) or ""
		if id ~= "" then
			if id == stop_at then
				break
			end
			newest = newest or id
			desc = desc or ""
			local name = desc:match("^push bookmark (%S+) to git remote")
			if name then
				names[#names + 1] = name
			elseif desc:match("^push .*bookmarks? to git remote") then
				bulk = true
			end
		end
	end
	return names, bulk, newest
end

-------------------------------------------------------------------------- display

local function open_float()
	if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
		state.buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, state.payload)
		vim.bo[state.buf].modifiable = false
		vim.keymap.set("n", "q", function()
			if state.win and vim.api.nvim_win_is_valid(state.win) then
				vim.api.nvim_win_close(state.win, true)
				state.win = nil
			end
		end, { buffer = state.buf, silent = true, desc = "Close" })
	end

	local width = math.floor(vim.o.columns * 0.85)
	local height = math.floor(vim.o.lines * 0.85)
	state.win = vim.api.nvim_open_win(state.buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		title = (" 󱗆 %s "):format(state.bookmark or "?"),
		title_pos = "center",
	})
	vim.wo[state.win].cursorline = true
end

-- A trouble mode of our own, so each failure gets its own fold. The rspec output
-- hangs off the failure as child *items* rather than under a group node: trouble
-- only previews and jumps from real items, so a group would make the failure row
-- itself dead. Children share the failure's position, so walking the backtrace
-- leaves the preview sitting on the example instead of chasing the cursor.
local MODE = "circleci"
local registered = nil

local function trouble_items()
	local Item = require("trouble.item")
	local per_file = {}
	for _, qi in ipairs(state.payload or {}) do
		per_file[qi.filename] = (per_file[qi.filename] or 0) + 1
	end

	local out = {}
	for _, qi in ipairs(state.payload or {}) do
		local shared = {
			source = MODE,
			filename = qi.filename,
			pos = { qi.lnum, 0 },
			-- {count} counts rows under the file, which is backtrace lines and not
			-- failed tests, so the header carries its own number
			failures = (" %d "):format(per_file[qi.filename]),
		}
		local failure = Item.new(vim.tbl_extend("error", shared, {
			text = qi.text,
			at = ("[%d]"):format(qi.lnum),
			icon = "✘",
			severity = vim.diagnostic.severity.ERROR,
		}))
		out[#out + 1] = failure
		for _, line in ipairs(qi.user_data or {}) do
			out[#out + 1] = Item.new(vim.tbl_extend("error", vim.deepcopy(shared), {
				text = line,
				parent = failure,
			}))
		end
	end
	-- every row of a failure shares its position, so the text breaks the tie
	Item.add_id(out, { "text" })
	return out
end

local function register()
	if registered == nil then
		registered = pcall(function()
			require("trouble.sources").register(MODE, {
				get = function(cb)
					cb(trouble_items())
				end,
				config = {
					modes = {
						[MODE] = {
							desc = "CircleCI",
							source = MODE,
							groups = {
								{ "filename", format = "{file_icon} {filename} {failures}" },
							},
							-- not {severity_icon}/{pos}: those render on every row, and
							-- the backtrace lines want to stay bare
							format = "{icon:DiagnosticError} {text} {at}",
						},
					},
				},
			})
		end)
	end
	return registered
end

-- trouble renders this far better, but nothing here should break without it
local function trouble(action)
	if not register() then
		return false
	end
	local ok, res = pcall(function()
		return require("trouble")[action](MODE)
	end)
	return ok, res
end

local function open_panel()
	if state.kind == "raw" then
		return open_float()
	end
	vim.fn.setqflist({}, " ", { title = "circleci: " .. (state.bookmark or "?"), items = state.payload })
	local ok, view = trouble("open")
	if not ok then
		return vim.cmd("copen")
	end
	-- the fold level cannot come from the mode config, trouble force-merges its
	-- own Window.FOLDS over win.wo. Depth 1 is the file and 2 the test, so level
	-- 1 leaves the files open with every failure folded.
	pcall(function()
		view:wait(function()
			view:fold_level({ level = 1 })
		end)
	end)
end

local function panel_open()
	if state.kind == "raw" then
		return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
	end
	local ok, open = trouble("is_open")
	if ok then
		return open
	end
	return vim.fn.getqflist({ winid = 0 }).winid ~= 0
end

local function close_panel()
	if state.kind == "raw" then
		if state.win and vim.api.nvim_win_is_valid(state.win) then
			vim.api.nvim_win_close(state.win, true)
		end
		state.win = nil
	elseif not trouble("close") then
		vim.cmd("cclose")
	end
end

-- Every fetch path ends in exactly one of these two, which is what clears
-- `busy`. Keeping that in one place is why a failed call can't wedge the keymap.
local function panel(kind, payload)
	state.busy = false
	state.buf = nil -- a new result needs a fresh buffer, the old one is frozen
	state.kind = kind
	state.payload = payload
	open_panel()
end

local function message(msg, level)
	state.busy = false
	state.kind = nil
	state.payload = nil
	notify(msg, level)
end

-- remember the outcome so the statusline can show it without asking again
local function record(branch, outcome)
	outcomes[branch] = outcome
	vim.cmd("redrawstatus")
end

-------------------------------------------------------------------------- fetching

-- nil when there is no bookmark. the caller decides whether that is worth saying,
-- because the background tick must stay silent.
local function resolve_bookmark(cb)
	local cmd =
		{ "jj", "log", "--no-graph", "--color", "never", "--ignore-working-copy", "-r", BM_REVSET, "-T", BM_TMPL }
	sh(cmd, function(out)
		local name = vim.split(vim.trim(out.stdout or ""), ",", { plain = true })[1]
		cb(out.code == 0 and name ~= "" and name or nil)
	end)
end

-- --limit 0 stops a long failure list getting truncated
local function test_failures(jobs, cb)
	local items, pending = {}, #jobs
	if pending == 0 then
		return cb(items)
	end
	local base = root() or vim.fn.getcwd()
	for _, job in ipairs(jobs) do
		sh({ "circleci", "testresult", "list", job.id, "--json", "--limit", "0" }, function(out)
			vim.list_extend(items, M.qf_items(out.stdout, base))
			pending = pending - 1
			if pending == 0 then
				cb(items)
			end
		end)
	end
end

-- lint has no structured results, so fall back to the failed step's raw output
local function raw_output(job, cb)
	sh({ "circleci", "job", "get", job.id, "--json" }, function(out)
		local data, err = M.decode(out)
		if not data then
			return cb({ ("%s: %s"):format(job.name, err) })
		end
		local step, exec = M.failed_step(data)
		if not step then
			return cb({ ("%s: failed with no failed step"):format(job.name) })
		end
		-- exec matters: on a parallel job the failed step is often not execution 0
		local cmd = {
			"circleci",
			"job",
			"output",
			"get",
			job.id,
			"--step-num",
			tostring(step.num),
			"--execution",
			tostring(exec),
			"--strip-ansi",
		}
		sh(cmd, function(o)
			local header = ("── %s / step %d: %s ──"):format(job.name, step.num, step.name)
			if o.code ~= 0 then
				local e = vim.trim(o.stderr or "")
				return cb({ header, "", e ~= "" and e or "no output" })
			end
			local lines = vim.split(o.stdout or "", "\n", { plain = true })
			table.insert(lines, 1, "")
			table.insert(lines, 1, header)
			cb(lines)
		end)
	end)
end

local function raw_outputs(jobs, cb)
	local chunks, pending = {}, #jobs
	if pending == 0 then
		return cb({})
	end
	for i, job in ipairs(jobs) do
		raw_output(job, function(lines)
			chunks[i] = lines
			pending = pending - 1
			if pending > 0 then
				return
			end
			local all = {}
			for _, chunk in ipairs(chunks) do
				vim.list_extend(all, chunk)
			end
			cb(all)
		end)
	end
end

local function on_failed(run)
	local jobs = M.failed_jobs(run)
	if #jobs == 0 then
		local why = ("✗ %s but no job did, check the web UI"):format(run.current_outcome or "run failed")
		return message(label(state.bookmark, why), vim.log.levels.WARN)
	end

	local names = {}
	for _, job in ipairs(jobs) do
		names[#names + 1] = job.name
	end
	local failed = table.concat(names, ", ")

	local tests = vim.tbl_filter(function(j)
		return not j.name:match("^lint")
	end, jobs)

	test_failures(tests, function(items)
		if #items > 0 then
			local plural = #items == 1 and "failure" or "failures"
			notify(label(state.bookmark, ("✗ %d test %s in %s"):format(#items, plural, failed)), vim.log.levels.WARN)
			return panel("qf", items)
		end
		-- nothing structured: lint, or a build that died before the specs ran
		raw_outputs(jobs, function(lines)
			notify(label(state.bookmark, ("✗ %s failed"):format(failed)), vim.log.levels.WARN)
			panel("raw", lines)
		end)
	end)
end

local function fetch()
	sh({ "circleci", "run", "get", "--branch", state.bookmark, "--json" }, function(out)
		local run, err = M.decode(out)
		if not run then
			record(state.bookmark, nil)
			return message(label(state.bookmark, err), vim.log.levels.WARN)
		end
		-- current_outcome is the only populated one; `outcome` is always null
		-- here, and it is absent entirely while the run is still going
		if run.phase ~= "ended" then
			record(state.bookmark, "running")
			resume(state.bookmark, run.id)
			return message(label(state.bookmark, ("◌ still running (%s), watching"):format(run.revision or "?")))
		end
		if run.current_outcome == "succeeded" then
			record(state.bookmark, "succeeded")
			return message(label(state.bookmark, "✓ passed"))
		end
		if not is_failure(run.current_outcome) then
			record(state.bookmark, nil)
			return message(label(state.bookmark, "• " .. (run.current_outcome or "ended with no outcome")))
		end
		record(state.bookmark, "failed")
		on_failed(run)
	end)
end

-- resolve the bookmark, then hand off. `reuse` keeps a cached result when we are
-- still on the same bookmark it came from.
local function start(reuse)
	if state.busy then
		return
	end
	local ok, why = usable()
	if not ok then
		return notify(why, vim.log.levels.WARN)
	end
	state.busy = true
	resolve_bookmark(function(name)
		if not name then
			return message("no bookmark on @ or its ancestors", vim.log.levels.WARN)
		end
		current = name
		if reuse and state.kind and name == state.bookmark then
			state.busy = false
			return open_panel()
		end
		state.bookmark = name
		fetch()
	end)
end

-------------------------------------------------------------------- watching a push

-- Is this the run we are waiting for? A run id is exact. A pushed commit has to
-- be prefix-matched against the short revision circleci reports, because right
-- after a push the branch still resolves to the *previous* run.
local function is_ours(w, run)
	if not run then
		return false
	end
	if w.run_id then
		return true
	end
	return run.revision ~= nil and w.commit:sub(1, #run.revision) == run.revision
end

-- A watch is either "the next run for this branch, identified by the commit that
-- got pushed" or "this exact run, which we already found running". The first
-- cannot use a run id because the run does not exist yet.
local function poll(branch)
	local w = watches[branch]
	if not w then
		return
	end
	local cmd = w.run_id and { "circleci", "run", "get", w.run_id, "--json" }
		or { "circleci", "run", "get", "--branch", branch, "--json" }
	sh(cmd, function(out)
		if watches[branch] ~= w then
			return -- superseded by a newer push, or cancelled
		end
		local run = M.decode(out)
		local ours = is_ours(w, run)
		if ours and run.phase == "ended" then
			watches[branch] = nil
			if run.current_outcome == "succeeded" then
				record(branch, "succeeded")
				return notify(label(branch, "✓ passed"))
			end
			-- a cancel is not a failure: pushing again cancels the run in flight
			if not is_failure(run.current_outcome) then
				record(branch, nil)
				return notify(label(branch, "• " .. (run.current_outcome or "ended with no outcome")))
			end
			record(branch, "failed")
			return notify(label(branch, "✗ failed, <leader>ci on that bookmark for details"), vim.log.levels.WARN)
		end

		w.polls = w.polls + 1
		if w.polls >= MAX_POLLS then
			watches[branch] = nil
			record(branch, nil)
			return notify(label(branch, "gave up waiting on CI"), vim.log.levels.WARN)
		end
		vim.defer_fn(function()
			poll(branch)
		end, POLL_MS)
	end, w.root)
end

-- The commit is resolved from the remote bookmark, not the local one: that is
-- what CircleCI actually built, and it cannot drift while we wait.
local function watch(branch, repo)
	local cmd = {
		"jj",
		"log",
		"--no-graph",
		"--color",
		"never",
		"--ignore-working-copy",
		"-r",
		branch .. "@origin",
		"-T",
		"commit_id",
	}
	sh(cmd, function(out)
		local commit = vim.trim(out.stdout or "")
		if out.code ~= 0 or not commit:match("^%x+$") then
			return
		end
		watches[branch] = { commit = commit, root = repo, polls = 0 }
		record(branch, "running")
		poll(branch)
	end, repo)
end

-- Pick up a run that was already going, so closing nvim mid-run and pressing
-- <leader>ci later still gets you the toast. An existing watch wins: it was
-- started by an actual push and knows which commit it is waiting for.
function resume(branch, run_id)
	if not run_id or watches[branch] then
		return
	end
	watches[branch] = { run_id = run_id, root = root(), polls = 0 }
	-- no immediate poll, we just read this run's state
	vim.defer_fn(function()
		poll(branch)
	end, POLL_MS)
end

local function tick()
	if not usable() then
		return
	end
	local repo = root()

	resolve_bookmark(function(name)
		if name ~= current then
			current = name
			vim.cmd("redrawstatus")
		end
	end)

	local cmd = { "jj", "op", "log", "--no-graph", "--ignore-working-copy", "--limit", "30", "-T", OP_TMPL }
	sh(cmd, function(out)
		if out.code ~= 0 then
			return
		end
		local names, bulk, newest = M.pushed_bookmarks(out.stdout, last_op)
		last_op = newest or last_op
		-- the first tick only records where the op log is; old pushes are not news.
		-- this is a flag rather than `last_op == nil` so that an empty read still
		-- counts as seeded, otherwise the next real push looks like the first one
		if not seeded then
			seeded = true
			return
		end
		if bulk and current then
			names[#names + 1] = current
		end
		for _, branch in ipairs(names) do
			watch(branch, repo)
		end
	end, repo)
end

------------------------------------------------------------------------- public

function M.toggle()
	if state.kind and panel_open() then
		return close_panel()
	end
	start(true)
end

function M.refetch()
	if state.kind and panel_open() then
		close_panel()
	end
	state.kind = nil
	start(false)
end

-- icon plus its highlight, for mini.statusline's combine_groups
function M.statusline()
	local outcome = current and outcomes[current]
	if outcome == "running" then
		return "◌", "DiagnosticHint"
	end
	if outcome == "succeeded" then
		return "✓", "DiagnosticOk"
	end
	if outcome == "failed" then
		return "✗", "DiagnosticError"
	end
	return "", nil
end

function M.setup()
	if timer then
		return
	end
	timer = vim.uv.new_timer()
	timer:start(1000, TICK_MS, vim.schedule_wrap(tick))

	local grp = vim.api.nvim_create_augroup("CircleCiWatch", { clear = true })
	-- FocusGained catches the common case: push in a terminal, come back to nvim
	vim.api.nvim_create_autocmd("FocusGained", { group = grp, callback = tick })
	-- a different repo has its own op log, so re-seed rather than read across it.
	-- in-flight watches keep their own repo root and carry on.
	vim.api.nvim_create_autocmd("DirChanged", {
		group = grp,
		callback = function()
			last_op, seeded, current = nil, false, nil
			tick()
		end,
	})
end

return M
