local HERE = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
package.path = HERE .. "../lua/?.lua;" .. package.path
local M = require("circleci")
local fails = 0
local function check(name, got, want)
  local ok = vim.deep_equal(got, want)
  if not ok then fails = fails + 1 end
  print((ok and "PASS " or "FAIL ") .. name)
  if not ok then print("  got " .. vim.inspect(got) .. " want " .. vim.inspect(want)) end
end

-- every job-level outcome circleci can report, observed and documented
local OBSERVED = { "succeeded", "failed", "canceled" }
local DOCUMENTED = { "infrastructure_fail", "timedout", "error", "unauthorized", "not_run", "blocked", "terminated" }

local function run_with(job_outcome, phase)
  return { workflows = { { jobs = { { id = "j", name = "build", phase = phase or "ended", outcome = job_outcome } } } } }
end

-- a pass and a cancel are not failures to investigate
check("succeeded -> no failed jobs", #M.failed_jobs(run_with("succeeded")), 0)
check("canceled  -> no failed jobs", #M.failed_jobs(run_with("canceled")), 0)
check("cancelled (double l) too",    #M.failed_jobs(run_with("cancelled")), 0)
check("failed    -> one failed job", #M.failed_jobs(run_with("failed")), 1)

-- every other ended outcome must surface rather than be silently dropped
for _, o in ipairs(DOCUMENTED) do
  check("surfaces " .. o, #M.failed_jobs(run_with(o)), 1)
end

-- a job still going is never a failure, whatever it claims
for _, p in ipairs({ "started", "queued", "created", "pending", "blocked", "running" }) do
  check("phase " .. p .. " is not counted", #M.failed_jobs(run_with("failed", p)), 0)
end
check("nil outcome on an ended job is not a failure", #M.failed_jobs(run_with(nil, "ended")), 0)

-- degenerate payloads must not throw
for name, payload in pairs({
  ["empty table"] = {},
  ["no workflows"] = { id = "x" },
  ["workflows not a list"] = { workflows = {} },
  ["workflow with no jobs"] = { workflows = { { id = "w" } } },
  ["job with no name"] = { workflows = { { jobs = { { id = "j", phase = "ended", outcome = "failed" } } } } },
  ["job with no id"] = { workflows = { { jobs = { { name = "n", phase = "ended", outcome = "failed" } } } } },
}) do
  local ok, res = pcall(M.failed_jobs, payload)
  check(name .. " -> no crash, no jobs", ok and #res, 0)
end

-- qf_items on junk input
check("qf_items on nil", #M.qf_items(nil, "/r"), 0)
check("qf_items on empty", #M.qf_items("", "/r"), 0)
check("qf_items skips unparseable lines", #M.qf_items("not json\n{oops\n", "/r"), 0)
check("qf_items skips passing results",
  #M.qf_items('{"result":"success","classname":"spec.a","name":"n"}', "/r"), 0)
check("qf_items keeps errors as well as failures",
  #M.qf_items('{"result":"error","classname":"spec.a","name":"n","message":"# ./spec/a.rb:3:in x"}', "/r"), 1)
check("qf_items survives a missing message",
  #M.qf_items('{"result":"failure","classname":"spec.a","name":"n"}', "/r"), 1)
check("qf_items survives a missing classname",
  #M.qf_items('{"result":"failure","name":"n","message":"nope"}', "/r"), 1)

-- decode on junk
local _, e1 = M.decode({ stdout = "", stderr = "" });               check("decode empty", e1 ~= nil, true)
local _, e2 = M.decode({ stdout = "not json", stderr = "boom" });   check("decode junk uses stderr", e2, "boom")
local _, e3 = M.decode({ stdout = "[1,2,3]", stderr = "" })
check("decode of an array is not an error", e3, nil)

-- failed_step on junk
check("failed_step with no executions", M.failed_step({}), nil)
check("failed_step with no failed step",
  M.failed_step({ executions = { { index = 0, steps = { { num = 1, outcome = "succeeded" } } } } }), nil)

-- pushed_bookmarks on junk
local n, b, newest = M.pushed_bookmarks("", nil)
check("pushed_bookmarks on empty", { #n, b, newest }, { 0, false, nil })
local n2 = M.pushed_bookmarks("garbage with no separators", nil)
check("pushed_bookmarks on garbage", #n2, 0)

print(fails == 0 and "\nall passed" or ("\n" .. fails .. " FAILED"))
os.exit(fails == 0 and 0 or 1)
