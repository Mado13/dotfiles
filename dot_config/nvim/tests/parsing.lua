-- exercise the parsing against real captured payloads
local HERE = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
package.path = HERE .. "../lua/?.lua;" .. package.path
local M = require("circleci")
local S = HERE

local function read(f)
	local fh = assert(io.open(S .. f))
	local s = fh:read("*a")
	fh:close()
	return s
end

local fails = 0
local function check(name, got, want)
	local ok = vim.deep_equal(got, want)
	if not ok then
		fails = fails + 1
	end
	print(("%s %s"):format(ok and "PASS" or "FAIL", name))
	if not ok then
		print("  got:  " .. vim.inspect(got))
		print("  want: " .. vim.inspect(want))
	end
end

-- spec_file / localize
check("spec_file dots to path", M.spec_file("spec.system.gauges_exports_spec"), "spec/system/gauges_exports_spec.rb")
check("localize strips ./", M.localize("./spec/foo_spec.rb"), "spec/foo_spec.rb")
check("localize strips container prefix", M.localize("/home/circleci/project/spec/foo_spec.rb"), "spec/foo_spec.rb")

-- qf_items against the real testresult JSONL
local items = M.qf_items(read("testresult.json"), "/repo")
check("one failure parsed", #items, 1)
-- must pick the spec frame (:98), not the topmost helper frame (csv_helpers:16)
check("locates the spec frame", items[1] and items[1].filename, "/repo/spec/system/gauges_exports_spec.rb")
check("locates the spec line", items[1] and items[1].lnum, 98)
-- a plain expect failure has no exception header, so the first line is all there is
check(
	"summary strips Failure/Error",
	items[1] and items[1].text:match("^[^|]+| (.*)$"),
	"expect(csv.headers).to eq expected_headers"
)
check("qf item carries the full message", #(items[1] and items[1].user_data or {}), 9)

-- an exception: the first line is the code that raised, the reason is further down
local RAISED = "Failure/Error: element = find(from)\n\n"
	.. "Capybara::ElementNotFound:\n"
	.. '  Unable to find visible css "#chart_started_on_source"\n\n'
	.. "[Screenshot Image]: /home/circleci/project/tmp/capybara/failures_x_27.png \n\n"
	.. "# ./spec/support/javascript_helpers.rb:77:in 'JavascriptHelpers#fill_select'"
check(
	"summary prefers the exception over the raising line",
	M.summary(RAISED),
	'Capybara::ElementNotFound: Unable to find visible css "#chart_started_on_source"'
)
check("detail drops blank lines but keeps the rest", #M.detail(RAISED), 5)
check("detail keeps indentation", M.detail(RAISED)[3], '  Unable to find visible css "#chart_started_on_source"')
-- a bracketed label ends in a colon too, but it is not an exception header
check(
	"summary does not read a screenshot label as an exception",
	M.summary("[Screenshot Image]: /tmp/x.png\nnext line"),
	"[Screenshot Image]: /tmp/x.png"
)
check("summary on nothing", M.summary(nil), "")
check("detail on nothing", M.detail(nil), {})

-- rspec prints backtraces both bare and `# `-commented depending on the
-- formatter. The rails app emits the first form, assessments the second.
local commented = {
	classname = "spec.system.survey_fill_out_answers.assigned_users_spec",
	result = "failure",
	name = "cannot change the assigned users",
	message = 'Failure/Error: expect(page).to have_text "x"\n\n'
		.. "# ./spec/system/survey_fill_out_answers/assigned_users_spec.rb:105:in 'block (4 levels) in <main>'",
}
local at = M.locate(commented)
check("locates a `# `-prefixed frame", at and at.filename, "spec/system/survey_fill_out_answers/assigned_users_spec.rb")
check("with its line", at and at.lnum, 105)

-- a capybara screenshot path must not be mistaken for a frame
check("ignores non-.rb paths in the message", M.locate({
	classname = "spec.foo_spec",
	message = "[Screenshot Image]: /home/circleci/project/tmp/capybara/failures_x_791.png",
}), nil)

-- failed_step on the real job payload
local job = vim.json.decode(read("jobget.json"), { luanil = { object = true } })
local step, exec = M.failed_step(job)
check("found a failed step", step ~= nil, true)
-- parallel job: the failed step is in execution 2, so exec must be threaded
-- through to `job output get` rather than hardcoded to 0
check("execution index of the failed step", exec, 2)
print("  failed step: " .. vim.inspect(step and { num = step.num, name = step.name }))

-- failed_jobs on the genuinely failed run
local failed = M.failed_jobs(vim.json.decode(read("run_failed.json"), { luanil = { object = true } }))
check("failed run -> 1 failed job", #failed, 1)
check("and it is build", failed[1] and failed[1].name, "build")

-- the re-run payload: build_and_lint appears twice, one ended/failed one started
local rerun = vim.json.decode(read("run_rerun.json"), { luanil = { object = true } })
print("\nre-run payload workflows: " .. #rerun.workflows)
for _, wf in ipairs(rerun.workflows) do
	local names = {}
	for _, j in ipairs(wf.jobs or {}) do
		names[#names + 1] = ("%s=%s"):format(j.name, j.outcome or j.current_outcome or "?")
	end
	print(("  %s phase=%s outcome=%s jobs[%s]"):format(wf.name, wf.phase, wf.outcome or "-", table.concat(names, " ")))
end
print("failed_jobs -> " .. vim.inspect(vim.tbl_map(function(j)
	return j.name
end, M.failed_jobs(rerun))))

-- a queued job reports current_outcome=succeeded optimistically. that must not
-- cancel out a real ended failure of the same job name.
local queued_trap = {
	workflows = {
		{ name = "w", phase = "ended", jobs = { { id = "a", name = "build", phase = "ended", outcome = "failed" } } },
		{
			name = "w",
			phase = "started",
			jobs = { { id = "b", name = "build", phase = "queued", current_outcome = "succeeded" } },
		},
	},
}
check("queued job does not mask a real failure", vim.tbl_map(function(j)
	return j.name
end, M.failed_jobs(queued_trap)), { "build" })

-- but a genuine ended re-run pass does clear it
local rerun_pass = {
	workflows = {
		{ name = "w", phase = "ended", jobs = { { id = "a", name = "build", phase = "ended", outcome = "failed" } } },
		{ name = "w", phase = "ended", jobs = { { id = "b", name = "build", phase = "ended", outcome = "succeeded" } } },
	},
}
check("re-run pass clears the earlier failure", #M.failed_jobs(rerun_pass), 0)

-- decode surfaces API errors from the body
local _, err = M.decode({ stdout = '{"error":true,"message":"no runs found","exit_code":4}', stderr = "" })
check("decode surfaces api error", err, "no runs found")


---------------------------------------------------- rspec example location

-- example_at recognises the openers and pulls the literal description
check("scenario with :js", { M.example_at("  scenario 'to a sibling', :js do") }, { true, "to a sibling" })
check("it with parens", { M.example_at('  it("does a thing") do') }, { true, "does a thing" })
check("specify", { M.example_at("specify 'x' do") }, { true, "x" })
check("example", { M.example_at("  example 'y' do") }, { true, "y" })
check("a one-liner it has no description", { M.example_at("  it { is_expected.to be_ok }") }, { true })
check("it_behaves_like is not an example", M.example_at("  it_behaves_like 'shared'"), false)
check("describe is not an example", M.example_at("  describe 'Thing' do"), false)
check("context is not an example", M.example_at("  context 'when x' do"), false)
check("plain code is not an example", M.example_at("  expect(page).to have_text 'it works'"), false)

-- the real shape: the failure is 11 lines into the example
local src = {}
for i = 1, 330 do src[i] = "  # filler" end
src[300] = "  context 'moves entity' do"
src[310] = "  scenario 'to a sibling', :js do"
src[321] = "  expect(page.success_flash_message).to have_content('x')"
local NAME = "Entities Entity Admin moves entity to a sibling"
check("walks up to the example", M.example_line(src, 321, NAME), 310)
check("a failure on the opener itself", M.example_line(src, 310, NAME), 310)

-- Must refuse to guess rather than point at the wrong test. The distractor goes
-- between the example and the failure, so the upward walk reaches it first.
src[315] = "  scenario 'something else entirely' do"
check("nearest example does not match -> nil", M.example_line(src, 321, NAME), nil)
src[315] = "  # filler"
check("unrelated name -> nil", M.example_line(src, 321, "Totally Different Test"), nil)
src[315] = "  it { is_expected.to be_ok }"
check("a one-liner example above -> nil, no guessing", M.example_line(src, 321, NAME), nil)
src[315] = "  # filler"
check("no example anywhere above -> nil", M.example_line(src, 5, NAME), nil)

-- Hostile descriptions. The pattern only nominates a candidate; the suffix match
-- against the API's own test name is what accepts it. None of these may produce
-- a wrong line: either the real example, or nil to fall back to the backtrace.
local HOSTILE = {
	["interpolated"] = '  scenario "moves to #{target} sibling" do',
	["escaped quote"] = "  scenario 'to a \\'sibling\\'' do",
	["opener with no description"] = "  scenario(",
	["percent literal"] = "  scenario %q{to a sibling} do",
	["heredoc description"] = "  scenario(<<~DESC) do",
	["bare opener"] = "  scenario do",
	["unicode description"] = "  scenario 'møves tø a sibling' do",
	["empty description"] = "  scenario '' do",
}
for what, line in pairs(HOSTILE) do
	src[315] = line
	local got = M.example_line(src, 321, NAME)
	check("degrades safely: " .. what, got == nil or got == 310, true)
	src[315] = "  # filler"
end

-- a commented-out example must never be nominated
src[315] = "  # scenario 'to a sibling' do"
check("a commented example is ignored", M.example_line(src, 321, NAME), 310)
src[315] = "  # filler"

-- prose that merely mentions a keyword
src[315] = "  expect(page).to have_text 'it is a sibling'"
check("prose mentioning a keyword is ignored", M.example_line(src, 321, NAME), 310)
src[315] = "  # filler"

-- a stale checkout: the file is shorter than the reported line
local short = { "  scenario 'to a sibling' do", "  expect(1).to eq 2" }
check("line past end of file does not throw", M.example_line(short, 999, NAME), 1)

-- end to end through qf_items, with the file injected so this stays offline
local FAIL = vim.json.encode({
  classname = "spec.system.entities_spec", name = NAME, result = "failure",
  message = "Failure/Error: return find('.x') if js?\n\n"
    .. "./spec/support/pages/page.rb:81:in 'Page#success_flash_message'\n"
    .. "./spec/system/entities_spec.rb:321:in 'block (4 levels) in <main>'",
})
local got = M.qf_items(FAIL, "/repo", function() return src end)
check("qf item lands on the example line", got[1].lnum, 310)
check("qf item keeps the file", got[1].filename, "/repo/spec/system/entities_spec.rb")
check("qf text carries the raising line", got[1].text:find(":321", 1, true) ~= nil, true)

-- when the file cannot be read we must fall back to the backtrace line
local nofile = M.qf_items(FAIL, "/repo", function() return nil end)
check("unreadable file falls back to the frame", nofile[1].lnum, 321)
print(fails == 0 and "\nall passed" or ("\n" .. fails .. " FAILED"))
os.exit(fails == 0 and 0 or 1)
