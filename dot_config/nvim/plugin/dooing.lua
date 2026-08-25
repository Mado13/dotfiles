vim.pack.add({
	{ src = "https://github.com/atiladefreitas/dooing" },
})

-- solo dev ticket tracker. `x` cycles a ticket pending -> in progress -> done,
-- and each one gets a scratchpad for follow-up notes.
require("dooing").setup({
	window = {
		-- evaluated on every open, so the float tracks the terminal instead of
		-- claiming 30 of 36 rows on the laptop screen
		dimensions = function()
			return {
				width = math.min(80, math.floor(vim.o.columns * 0.6)),
				height = math.floor(vim.o.lines * 0.6),
			}
		end,
		border = "rounded",
	},

	-- style is the master switch. Without it the renderer stays classic and every
	-- toggle under it, sections included, is ignored. The rest default to true.
	ui = { style = "modern" },

	-- one ticket file per repo, created without asking
	per_project = {
		enabled = true,
		default_filename = "dooing.json",
		on_missing = "auto_create",
		auto_gitignore = false,
		auto_open_project_todos = false,
	},

	pretty_print_json = true, -- keeps the per-project file readable in a diff
	done_sort_by_completed_time = true,

	nested_tasks = {
		enabled = true,
		indent = 2,
		retain_structure_on_complete = true,
		move_completed_to_end = true,
		-- a sub-task of a P1 is a P1, so skip the picker
		inherit_priority = true,
	},

	-- on_startup fires a popup every time nvim opens, which gets old fast
	due_notifications = { enabled = true, on_startup = false, on_open = true },

	scratchpad = { syntax_highlight = "markdown" },

	keymaps = {
		-- <leader>t belongs to neotest
		open_project_todo = "<leader>kk",
		toggle_window = "<leader>kg",
		show_due_notification = "<leader>kn",

		-- the rest are buffer-local to the float. leader is <Space>, so nothing
		-- in here may start with <leader> or every <Space> waits on timeoutlen.
		new_todo = "i",
		create_nested_task = "o",
		edit_todo = "e",
		toggle_todo = "x",
		delete_todo = "d",
		delete_completed = "D",
		undo_delete = "u",
		remove_duplicates = "X",

		open_todo_scratchpad = "n",
		toggle_priority = "<Space>",
		edit_priorities = "p",

		add_due_date = "H",
		remove_due_date = "r",
		add_time_estimation = "T",
		remove_time_estimation = "R",

		search_todos = "/",
		toggle_tags = "t",
		clear_filter = "c",
		refresh_todos = "f",

		import_todos = "I",
		export_todos = "E",
		toggle_help = "?",
		close_window = "q",
	},
})
