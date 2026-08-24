local wezterm = require("wezterm")
local mux = wezterm.mux
local act = wezterm.action

local home = os.getenv("HOME")

local function tab_title(tab_info)
	local title = tab_info.tab_title
	if title and #title > 0 then
		return title
	end

	local pane_title = tab_info.active_pane.title or ""
	local clean_title = pane_title:match("([^/]+)$") or pane_title
	clean_title = clean_title:gsub("^%s*(.-)%s*$", "%1")

	if #clean_title > 20 then
		clean_title = clean_title:sub(1, 17) .. "..."
	end

	return clean_title ~= "" and clean_title or "Terminal"
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = tab_title(tab)
	local tab_index = tab.tab_index + 1
	-- same rendering for active/hover/inactive (you can style later if you want)
	return " " .. tab_index .. " " .. title .. " "
end)

wezterm.on("gui-startup", function()
	local tab, pane, window = mux.spawn_window({})
	window:gui_window():maximize()
end)

-- Build config as a table so we can extend key tables later
local config = {
	default_prog = { "/opt/homebrew/bin/fish", "-l" },
	window_decorations = "RESIZE",
	bidi_enabled = true,
	unicode_version = 15,

	font = wezterm.font({
		family = "Monolisa",
		harfbuzz_features = {
			"zero=1",
			"ss01=1",
			"ss04=1",
			"ss05=1",
			"ss06=1",
			"ss07=1",
			"ss12=1",
			"ss15=1",
			"ss16=1",
			"calt=1",
		},
	}),

	enable_kitty_graphics = true,
	allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace",
	color_scheme = "Gruvbox Material (Gogh)",
	font_size = 12.5,
	line_height = 1.15,

	-- Scrollback + behavior
	scrollback_lines = 50000, -- was 10000
	enable_scroll_bar = true,
	scroll_to_bottom_on_input = true,

	hide_tab_bar_if_only_one_tab = true,
	window_close_confirmation = "AlwaysPrompt",
	automatically_reload_config = true,
	exit_behavior = "Close",

	-- UI perf/feel
	animation_fps = 60, -- was 1
	max_fps = 60,
	front_end = "WebGpu",
	webgpu_power_preference = "HighPerformance",
	adjust_window_size_when_changing_font_size = false,

	window_padding = {
		left = 2,
		right = 2,
		top = 0,
		bottom = 0,
	},

	use_fancy_tab_bar = false,
	tab_bar_at_bottom = true,
	tab_max_width = 32,

	tab_bar_style = {
		window_hide = " ⨉",
		window_hide_hover = " ⨉",
		new_tab = " +",
		new_tab_hover = " +",
	},

	-- Quick-select patterns (copy without typing)
	quick_select_patterns = {
		-- URLs
		[[https?://[^)\]\s<>"]+]],
		-- Git SHAs (7–40)
		[[\b[0-9a-f]{7,40}\b]],
		-- Jira-like keys
		[[\b[A-Z][A-Z0-9]+-\d+\b]],
	},

	mouse_bindings = {
		{
			event = { Down = { streak = 1, button = "Right" } },
			mods = "NONE",
			action = act.PasteFrom("Clipboard"),
		},
		{
			event = { Down = { streak = 2, button = "Left" } },
			mods = "NONE",
			action = act.SelectTextAtMouseCursor("Word"),
		},
	},

	keys = {
		-- Splits / panes
		{ key = "d", mods = "CMD", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "d", mods = "CMD|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "w", mods = "CMD", action = act.CloseCurrentPane({ confirm = true }) },
		{ key = "h", mods = "CMD", action = act.ActivatePaneDirection("Left") },
		{ key = "l", mods = "CMD", action = act.ActivatePaneDirection("Right") },
		{ key = "k", mods = "CMD", action = act.ActivatePaneDirection("Up") },
		{ key = "j", mods = "CMD", action = act.ActivatePaneDirection("Down") },

		-- Send Ctrl-s (e.g., to TUI apps)
		{ key = "s", mods = "CMD", action = act.SendKey({ key = "s", mods = "CTRL" }) },

		-- Clear scrollback + viewport (upgrade from ScrollbackOnly)
		{ key = "k", mods = "CMD", action = act.ClearScrollback("ScrollbackAndViewport") },

		-- Resize pane
		{ key = "LeftArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
		{ key = "RightArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },
		{ key = "UpArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
		{ key = "DownArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },

		-- Edit config
		{
			key = ",",
			mods = "CMD",
			action = act.SpawnCommandInNewTab({
				args = { "/opt/homebrew/bin/nvim", home .. "/.config/wezterm/wezterm.lua" },
			}),
		},

		-- Search ergonomics
		-- CMD+f: open empty case-insensitive search (predictable)
		{ key = "f", mods = "CMD", action = act.Search({ CaseInSensitiveString = "" }) },
		-- CMD+SHIFT+R: open empty regex search (no clash with your fullscreen)
		{ key = "R", mods = "CMD|SHIFT", action = act.Search({ Regex = "" }) },
		-- Jump between matches from normal view
		{ key = "g", mods = "CTRL|SHIFT", action = act.CopyMode("NextMatch") },
		{ key = "G", mods = "CTRL|SHIFT", action = act.CopyMode("PriorMatch") },

		-- Quick-select URLs on demand
		{ key = "U", mods = "CTRL|SHIFT", action = act.QuickSelectArgs({ patterns = { [[https?://[^)\]\s<>"]+]] } }) },

		-- Enter copy mode fast
		{ key = "e", mods = "CTRL|SHIFT", action = act.ActivateCopyMode },
	},
}

-- Extend default key tables (don’t replace wholesale)
local defaults = wezterm.gui.default_key_tables()
defaults.search_mode = defaults.search_mode or {}
defaults.copy_mode = defaults.copy_mode or {}

-- Search overlay: close with 'q', Enter/Shift-Enter to step
table.insert(defaults.search_mode, { key = "q", mods = "NONE", action = act.CopyMode("Close") })
table.insert(defaults.search_mode, { key = "Enter", mods = "NONE", action = act.CopyMode("NextMatch") })
table.insert(defaults.search_mode, { key = "Enter", mods = "SHIFT", action = act.CopyMode("PriorMatch") })

-- Copy mode: yank + exit with 'y'
table.insert(defaults.copy_mode, {
	key = "y",
	mods = "NONE",
	action = act.Multiple({
		act.CopyTo("ClipboardAndPrimarySelection"),
		act.CopyMode("Close"),
	}),
})

config.key_tables = defaults

return config
