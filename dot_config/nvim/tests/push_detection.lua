local HERE = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
package.path = HERE .. "../lua/?.lua;" .. package.path
local M = require("circleci")
local S = HERE
local fh = assert(io.open(S .. "oplog.bin")); local oplog = fh:read("*a"); fh:close()

local fails = 0
local function check(name, got, want)
  local ok = vim.deep_equal(got, want)
  if not ok then fails = fails + 1 end
  print((ok and "PASS " or "FAIL ") .. name)
  if not ok then print("  got:  " .. vim.inspect(got) .. "\n  want: " .. vim.inspect(want)) end
end

-- real op log, no stop point: every push in 300 ops
local names, bulk, newest = M.pushed_bookmarks(oplog, nil)
print(("real op log: %d pushes found, bulk=%s, newest=%s"):format(#names, tostring(bulk), newest))
for i = 1, math.min(3, #names) do print("  " .. names[i]) end
check("newest op is 12 hex chars", newest and #newest == 12 and newest:match("^%x+$") ~= nil, true)
check("found the known pushes", #names >= 4, true)

-- stopping at the newest op means nothing is new
local n2 = M.pushed_bookmarks(oplog, newest)
check("stop_at newest -> no pushes", #n2, 0)

-- synthetic: single, bulk, and a non-push op
local F, R = "\x1f", "\x1e"
local function rec(id, desc) return id .. F .. desc .. R end
local synth = rec("aaaaaaaaaaaa", "push bookmark feature/x to git remote origin")
  .. rec("bbbbbbbbbbbb", "abandon commit deadbeef")
  .. rec("cccccccccccc", "push all tracked bookmarks to git remote origin")
  .. rec("dddddddddddd", "snapshot working copy")
local sn, sb, snew = M.pushed_bookmarks(synth, nil)
check("named push extracted", sn, { "feature/x" })
check("bulk push detected", sb, true)
check("newest is first record", snew, "aaaaaaaaaaaa")

-- stop_at mid-list only reads newer ops
local sn2, sb2 = M.pushed_bookmarks(synth, "cccccccccccc")
check("stops before the bulk op", sn2, { "feature/x" })
check("and does not see it as bulk", sb2, false)

-- a deleted-bookmark push must not be read as a branch to watch
local del = rec("eeeeeeeeeeee", "push all deleted bookmarks to git remote origin")
local dn, db = M.pushed_bookmarks(del, nil)
check("deleted-bookmark push names nothing", #dn, 0)
check("but registers as bulk", db, true)

print(fails == 0 and "\nall passed" or ("\n" .. fails .. " FAILED"))
os.exit(fails == 0 and 0 or 1)
