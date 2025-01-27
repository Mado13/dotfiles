local wezterm = require("wezterm")
local mux = wezterm.mux
local act = wezterm.action

-- Get home directory
local home = os.getenv("HOME")
local config_dir = home .. "/.config/wezterm"

-- Utility for custom tab title
local function tab_title(tab_info)
	local title = tab_info.tab_title
	if title and #title > 0 then
		return title
	end
	return tab_info.active_pane.title
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = tab_title(tab)
	return " " .. tab.tab_index + 1 .. ": " .. title .. " "
end)

wezterm.on("gui-startup", function()
	local tab, pane, window = mux.spawn_window({})
	window:gui_window():maximize()
end)

-- Update SSH domains if needed
local ssh_domains = {
	{
		-- Example SSH domain configuration
		name = "my-server",
		remote_address = "user@hostname",
		multiplexing = "None", -- or 'Control' for multiplexed connections
	},
}

return {
	default_prog = { "/opt/homebrew/bin/fish", "-l" },
	window_decorations = "RESIZE",
	font = wezterm.font({
		family = "Maple Mono",
		harfbuzz_features = { "cv01", "cv02", "ss01", "ss02", "ss03" },
		weight = "Regular",
		style = "Normal",
	}),
	color_scheme = "Gruvbox Material (Gogh)",
	font_size = 12,
	line_height = 1,
	use_dead_keys = false,
	scrollback_lines = 10000,
	adjust_window_size_when_changing_font_size = false,
	hide_tab_bar_if_only_one_tab = true,

	-- Window management
	window_close_confirmation = "AlwaysPrompt",
	window_frame = {
		font = wezterm.font({ family = "Noto Sans", weight = "Regular" }),
		font_size = 12.0,
	},

	-- Terminal features
	automatically_reload_config = true,
	exit_behavior = "Close",
	status_update_interval = 1000,

	-- Mouse configurations
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

	-- Key bindings
	keys = {
		{ key = "d", mods = "CMD", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "d", mods = "CMD|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "w", mods = "CMD", action = act.CloseCurrentPane({ confirm = true }) },
		{ key = "h", mods = "CMD", action = act.ActivatePaneDirection("Left") },
		{ key = "l", mods = "CMD", action = act.ActivatePaneDirection("Right") },
		{ key = "k", mods = "CMD", action = act.ActivatePaneDirection("Up") },
		{ key = "j", mods = "CMD", action = act.ActivatePaneDirection("Down") },
		{ key = "LeftArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
		{ key = "RightArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },
		{ key = "UpArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
		{ key = "DownArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
		{
			key = ",",
			mods = "CMD",
			action = act.SpawnCommandInNewTab({
				args = { "/opt/homebrew/bin/nvim", home .. "/.config/wezterm/wezterm.lua" },
			}),
		},
		{ key = "f", mods = "CMD", action = act.Search("CurrentSelectionOrEmptyString") },
		{ key = "f", mods = "CMD|SHIFT", action = act.ToggleFullScreen },
	},

	-- Advanced features
	ssh_domains = ssh_domains,

	-- Performance tweaks
	animation_fps = 1,
	max_fps = 60,
	front_end = "WebGpu",
	webgpu_power_preference = "HighPerformance",

	-- Window padding
	window_padding = {
		left = 2,
		right = 2,
		top = 0,
		bottom = 0,
	},

	-- Tab bar styling with Gruvbox Material colors
	use_fancy_tab_bar = false,
	tab_bar_at_bottom = true,
	tab_max_width = 32,
	colors = {
		tab_bar = {
			background = "#282828", -- Gruvbox dark background
			active_tab = {
				bg_color = "#b8bb26", -- Gruvbox bright green
				fg_color = "#282828", -- Dark background for contrast
				intensity = "Bold",
			},
			inactive_tab = {
				bg_color = "#3c3836", -- Gruvbox dark1
				fg_color = "#a89984", -- Gruvbox light4
			},
			inactive_tab_hover = {
				bg_color = "#504945", -- Gruvbox dark2
				fg_color = "#ebdbb2", -- Gruvbox light0
			},
			new_tab = {
				bg_color = "#3c3836", -- Gruvbox dark1
				fg_color = "#a89984", -- Gruvbox light4
			},
			new_tab_hover = {
				bg_color = "#504945", -- Gruvbox dark2
				fg_color = "#ebdbb2", -- Gruvbox light0
			},
		},
	},
	
	-- Clean tab bar appearance
	tab_bar_style = {
		window_hide = " ⨉",
		window_hide_hover = " ⨉",
		new_tab = " +",
		new_tab_hover = " +",
	},
}
