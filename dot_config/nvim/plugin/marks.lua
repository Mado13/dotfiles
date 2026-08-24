-- native marks in the gutter. keys follow chentoast/marks.nvim, listing and
-- deleting is fzf-lua's marks picker (enter jumps, ctrl-x deletes)
local ns = vim.api.nvim_create_namespace("mark-signs")
local LETTERS = "abcdefghijklmnopqrstuvwxyz"

local function letter(mark)
	return mark:sub(2)
end

local function place(buf, name, line)
	for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })) do
		if vim.trim(m[4].sign_text or "") == name then
			vim.api.nvim_buf_del_extmark(buf, ns, m[1])
		end
	end
	if line > 0 then
		vim.api.nvim_buf_set_extmark(buf, ns, line - 1, 0, {
			sign_text = name,
			sign_hl_group = "DiagnosticHint",
			priority = 20, -- over gitsigns' 6, so the letter wins the one column on a changed line
		})
	end
end

local function buf_marks(buf)
	local out = {}
	for _, m in ipairs(vim.fn.getmarklist(buf)) do
		if letter(m.mark):match("%l") then
			out[#out + 1] = { name = letter(m.mark), line = m.pos[2] }
		end
	end
	local name = vim.api.nvim_buf_get_name(buf)
	for _, m in ipairs(vim.fn.getmarklist()) do
		if letter(m.mark):match("%u") and vim.fn.fnamemodify(m.file, ":p") == name then
			out[#out + 1] = { name = letter(m.mark), line = m.pos[2] }
		end
	end
	return out
end

vim.api.nvim_create_autocmd("MarkSet", {
	pattern = "[a-zA-Z]",
	callback = function(ev)
		place(ev.buf, ev.data.name, ev.data.line)
	end,
})

-- shada restores A-Z marks without firing MarkSet, so redraw them on open
vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function(ev)
		for _, m in ipairs(buf_marks(ev.buf)) do
			place(ev.buf, m.name, m.line)
		end
	end,
})

local function marks_on_line(buf, lnum)
	return vim.tbl_filter(function(m)
		return m.line == lnum
	end, buf_marks(buf))
end

local function next_free(buf)
	local used = {}
	for _, m in ipairs(buf_marks(buf)) do
		used[m.name] = true
	end
	for c in LETTERS:gmatch(".") do
		if not used[c] then
			return c
		end
	end
end

local function set_next()
	local buf, lnum = vim.api.nvim_get_current_buf(), vim.fn.line(".")
	local c = next_free(buf)
	if not c then
		vim.notify("a-z all taken", vim.log.levels.WARN)
		return
	end
	vim.api.nvim_buf_set_mark(buf, c, lnum, 0, {})
	vim.notify("mark " .. c)
end

vim.keymap.set("n", "m,", set_next, { desc = "Set next free mark" })

vim.keymap.set("n", "m;", function()
	local buf, lnum = vim.api.nvim_get_current_buf(), vim.fn.line(".")
	local here = marks_on_line(buf, lnum)
	if #here == 0 then
		set_next()
		return
	end
	for _, m in ipairs(here) do
		vim.cmd("delmarks " .. m.name)
	end
end, { desc = "Toggle mark on this line" })

vim.keymap.set("n", "dm", function()
	local ch = vim.fn.getcharstr()
	local buf = vim.api.nvim_get_current_buf()
	if ch == "-" then
		for _, m in ipairs(marks_on_line(buf, vim.fn.line("."))) do
			vim.cmd("delmarks " .. m.name)
		end
	elseif ch == " " then
		for _, m in ipairs(buf_marks(buf)) do
			vim.cmd("delmarks " .. m.name)
		end
	elseif ch:match("^[a-zA-Z]$") then
		vim.cmd("delmarks " .. ch)
	end
end, { desc = "Delete mark: letter, - for line, <space> for buffer" })
