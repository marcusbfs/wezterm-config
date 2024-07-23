local wezterm = require("wezterm")
local mux = wezterm.mux

local is_linux = wezterm.target_triple:find("linux") ~= nil

local font_ = wezterm.font(is_linux and "JetBrains Mono" or "FiraMono Nerd Font")
local default_cwd_ = is_linux and (wezterm.home_dir .. "/workspace") or "d:\\workspace"

wezterm.on("toggle-ligature", function(window, pane)
	local overrides = window:get_config_overrides() or {}
	if not overrides.harfbuzz_features then
		-- If we haven't overridden it yet, then override with ligatures disabled
		overrides.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
	else
		-- else we did already, and we should disable out override now
		overrides.harfbuzz_features = nil
	end
	window:set_config_overrides(overrides)
end)

local commonOpts = {
	enable_wayland = false,
	window_decorations = "RESIZE",

	default_cwd = default_cwd_,

	-- Font
	font = font_,
	font_size = 14.0,

	-- Cursor
	default_cursor_style = "SteadyBar",
	color_scheme = "Modus-Vivendi",
	-- padding
	window_padding = {
		top = 0,
		bottom = 0,
		left = 5,
		right = 2,
	},
	-- tab config
	hide_tab_bar_if_only_one_tab = true,
	-- timeout_milliseconds defaults to 1000 and can be omitted
	leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 },
	-- mappings
	keys = {
		-- Disable ctrl-l
		-- {key = "l", mods = "CTRL", action = wezterm.action {SendString = "clear"}},
		-- Disable alt+number to change tabs. I used this in vim
		{ key = "1", mods = "ALT", action = { SendKey = { key = "1", mods = "ALT" } } },
		{ key = "2", mods = "ALT", action = { SendKey = { key = "2", mods = "ALT" } } },
		{ key = "3", mods = "ALT", action = { SendKey = { key = "3", mods = "ALT" } } },
		{ key = "4", mods = "ALT", action = { SendKey = { key = "4", mods = "ALT" } } },
		{ key = "5", mods = "ALT", action = { SendKey = { key = "5", mods = "ALT" } } },
		{ key = "6", mods = "ALT", action = { SendKey = { key = "6", mods = "ALT" } } },
		{ key = "7", mods = "ALT", action = { SendKey = { key = "7", mods = "ALT" } } },
		{ key = "8", mods = "ALT", action = { SendKey = { key = "8", mods = "ALT" } } },

		{
			key = "Enter",
			mods = "ALT",
			action = wezterm.action.DisableDefaultAssignment,
		},

		-- Create panes
		{
			key = "_",
			mods = "LEADER|SHIFT",
			action = wezterm.action({ SplitHorizontal = { domain = "CurrentPaneDomain" } }),
		},
		{ key = "-", mods = "LEADER", action = wezterm.action({ SplitVertical = { domain = "CurrentPaneDomain" } }) },
		-- Move between panes
		{ key = "j", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Down" }) },
		{ key = "k", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Up" }) },
		{ key = "l", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Right" }) },
		{ key = "h", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Left" }) },
		-- Close current pane
		{ key = "c", mods = "LEADER", action = wezterm.action({ CloseCurrentPane = { confirm = true } }) },
		-- Send "CTRL-A" to the terminal when pressing CTRL-A, CTRL-A
		{ key = "a", mods = "LEADER|CTRL", action = wezterm.action({ SendString = "\x01" }) },
		-- Toggle ligatures
		{ key = "t", mods = "LEADER", action = wezterm.action.EmitEvent("toggle-ligature") },
		-- Handy layout
		{
			key = "L",
			mods = "LEADER|SHIFT",
			action = wezterm.action_callback(function(window, pane)
				window:perform_action(wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }), pane)
				window:perform_action(wezterm.action.AdjustPaneSize({ "Down", 13 }), pane)
				window:perform_action(wezterm.action.ActivatePaneDirection("Up"), pane)
			end),
		},
	},
}

if not is_linux then
	commonOpts.default_prog = { "cmd.exe", "/k", "%CMDER_ROOT%\\vendor\\init.bat" }
end

wezterm.on("gui-startup", function()
	local tab, pane, window = mux.spawn_window({})
	window:gui_window():maximize()
end)

return commonOpts
