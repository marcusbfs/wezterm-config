local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

-- wezterm.plugin.update_all()

-- resurrect.periodic_save({ interval_seconds = 15 * 60, save_workspaces = true, save_windows = true, save_tabs = false })

local is_linux = wezterm.target_triple:find("linux") ~= nil

local font_ = { family = "CaskaydiaMono Nerd Font", weight = "Regular" }
local font_size_ = 12

local default_cwd_ = is_linux and (wezterm.home_dir .. "/workspace") or "d:\\workspace"

local enter = is_linux and "\n" or "\r\n"
local osep = is_linux and " ; " or " || "
local asep = " && "

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

local function is_vim(pane)
	-- this is set by the plugin, and unset on ExitPre in Neovim
	return pane:get_user_vars().IS_NVIM == "true"
end

local direction_keys = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

local function split_nav(resize_or_move, key)
	return {
		key = key,
		mods = resize_or_move == "resize" and "META" or "CTRL",
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				-- pass the keys through to vim/nvim
				win:perform_action({
					SendKey = { key = key, mods = resize_or_move == "resize" and "META" or "CTRL" },
				}, pane)
			else
				if resize_or_move == "resize" then
					win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
				else
					win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
				end
			end
		end),
	}
end

local function uri_to_path(cwd_uri)
	-- cwd_uri may be a FilePath (userdata) or a string like "file:///C:/..."
	local s = cwd_uri
	if type(cwd_uri) ~= "string" then
		s = cwd_uri.file_path or tostring(cwd_uri)
	end

	-- Strip URI prefix if present
	s = s:gsub("^file://", "")

	-- Windows quirk: sometimes begins with "/C:/..."
	if s:match("^/[A-Za-z]:/") then
		s = s:sub(2)
	end

	-- Normalize slashes
	s = s:gsub("\\", "/")
	return s
end

local function shorten_home(path)
	local home = wezterm.home_dir:gsub("\\", "/")
	-- case-insensitive compare for Windows
	local p_low = path:lower()
	local h_low = home:lower()
	if p_low:sub(1, #h_low) == h_low then
		return "~" .. path:sub(#home + 1)
	end
	return path
end

local function starship_compact(path)
	-- example: "/Users/Marcus/dev/my-project/src" -> "~/d/my-project/src"
	-- assume home already collapsed to "~"
	local parts = {}
	for part in path:gmatch("[^/]+") do
		table.insert(parts, part)
	end
	if #parts <= 2 then
		return path
	end
	for i = 2, #parts - 1 do
		if parts[i] ~= "~" and parts[i] ~= "" then
			parts[i] = parts[i]:sub(1, 1)
		end
	end
	return table.concat(parts, "/")
end

wezterm.on("format-tab-title", function(tab)
	local path = uri_to_path(tab.active_pane.current_working_dir or "")
	if path ~= "" then
		local short = shorten_home(path)
		-- choose ONE:
		-- 1) just basename:
		-- local basename = short:match("([^/\\]+)$") or short
		-- return basename
		-- 2) full shortened path:
		return short
		-- 3) starship-like compact path:
		-- return starship_compact(short)
	end
	return tab.active_pane.title
end)

local commonOpts = {
	set_environment_variables = {
		WEZTERM_SHELL_INHERIT_CWD = "1",
	},
	enable_wayland = false,
	window_decorations = "RESIZE",
	max_fps = 144,

	audible_bell = "Disabled",
	scrollback_lines = 10000,
	enable_scroll_bar = true,

	default_cwd = default_cwd_,

	-- Font
	font = wezterm.font_with_fallback({ font_, "FontAwesome", "Symbols Nerd Font Mono" }),
	font_size = font_size_,
	warn_about_missing_glyphs = false,

	-- Cursor
	default_cursor_style = "SteadyBar",
	color_scheme = "Modus-Operandi",
	-- color_scheme = "Modus-Vivendi",
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
		-- Clear screen with  ctrl-shift-l
		{
			key = "L",
			mods = "CTRL|SHIFT",
			action = act.Multiple({
				-- act.ClearScrollback("ScrollbackAndViewport"),
				act.SendKey({ key = "L", mods = "CTRL" }),
			}),
		},

		{
			key = "Enter",
			mods = "ALT",
			action = wezterm.action.DisableDefaultAssignment,
		},

		{
			key = "n",
			mods = "CTRL",
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
		split_nav("move", "h"),
		split_nav("move", "j"),
		split_nav("move", "k"),
		split_nav("move", "l"),
		-- Close current pane
		{ key = "c", mods = "LEADER", action = wezterm.action({ CloseCurrentPane = { confirm = true } }) },
		-- Send "CTRL-A" to the terminal when pressing CTRL-A, CTRL-A
		{ key = "a", mods = "LEADER|CTRL", action = wezterm.action({ SendString = "\x01" }) },
		-- Toggle ligatures
		{ key = "t", mods = "LEADER", action = wezterm.action.EmitEvent("toggle-ligature") },
		-- Handy layout
		{
			key = "L",
			mods = "LEADER|SHIFT|CTRL",
			action = wezterm.action_callback(function(window, pane)
				window:perform_action(wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }), pane)
				window:perform_action(wezterm.action.AdjustPaneSize({ "Down", 19 }), pane)
				window:perform_action(wezterm.action.ActivatePaneDirection("Up"), pane)
			end),
		},
		{
			key = "!",
			mods = "LEADER|SHIFT",
			action = wezterm.action_callback(function(win, pane)
				pane:move_to_new_window()
			end),
		},
		{
			key = "!",
			mods = "LEADER|SHIFT|CTRL",
			action = wezterm.action_callback(function(win, pane)
				pane:move_to_new_tab()
			end),
		},
		{
			key = "r",
			mods = "LEADER",
			action = act.ActivateKeyTable({
				name = "resize_pane",
				one_shot = false,
			}),
		},
		{
			key = "g",
			mods = "ALT",
			action = wezterm.action_callback(function(window, pane)
				local current_tab_id = pane:tab():tab_id()
				local cmd = "lazygit"
					.. osep
					.. "wezterm cli activate-tab --tab-id "
					.. current_tab_id
					.. osep
					.. "exit"
					.. enter
				local tab, tab_pane, _ = window:mux_window():spawn_tab({})
				tab_pane:send_text(cmd)
				tab:set_title(wezterm.nerdfonts.dev_git .. " Lazygit")
			end),
		},
		{
			key = "n",
			mods = "ALT",
			action = act.SendString("nix develop\nzsh\n"),
		},
		{
			key = "U",
			mods = "LEADER|SHIFT",
			action = wezterm.action_callback(function(window, pane)
				local update_title = wezterm.nerdfonts.md_update .. " Update"
				local update_cmd = 'notify-send "' .. update_title .. '" "finished"'
				local tab, top_pane, _ = window:mux_window():spawn_tab({})
				tab:set_title(update_title)

				local bottom_left_pane = top_pane:split({ direction = "Bottom" })
				local bottom_right_pane = bottom_left_pane:split({ direction = "Right" })

				top_pane:send_text(
					is_linux
							and ("cd ~/workspace" .. osep .. "sudo echo starting update" .. osep .. osep .. "rustup update" .. osep .. "yes | yay --answerdiff None --answerclean None --mflags --noconfirm" .. osep .. update_cmd)
						or ("rustup update" .. asep .. "update-all-but-nvim" .. enter)
				)

				local vim_sleep_time = "45"
				bottom_left_pane:send_text(
					is_linux
							and ("cd ~/.config/home-manager" .. osep .. "nvim --version" .. osep .. "sleep " .. vim_sleep_time .. asep .. "nix flake update" .. osep .. "home-manager switch --impure" .. osep .. "nvim --version")
						or ("sleep " .. vim_sleep_time .. asep .. "update-nvim") .. enter
				)
				bottom_right_pane:send_text(
					'nvim --headless "+Lazy! sync" "+TSUpdate" "+MasonUpdate" "+MasonUpdateAll" +qa' .. enter
				)
				top_pane:activate()
			end),
		},
		{
			key = "$",
			mods = "LEADER|SHIFT",
			action = wezterm.action.PromptInputLine({
				description = "New name for current workspace",
				action = wezterm.action_callback(function(window, pane, line)
					if line then
						wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
					end
				end),
			}),
		},
		{
			key = "s",
			mods = "LEADER",
			action = workspace_switcher.switch_workspace(),
		},
		{
			key = "S",
			mods = "LEADER|SHIFT",
			action = wezterm.action_callback(function(win, pane)
				resurrect.save_state(resurrect.workspace_state.get_workspace_state())
			end),
		},
		{
			key = "L",
			mods = "LEADER|SHIFT",
			action = wezterm.action_callback(function(win, pane)
				resurrect.fuzzy_load(win, pane, function(id, label)
					local type = string.match(id, "^([^/]+)") -- match before '/'
					id = string.match(id, "([^/]+)$") -- match after '/'
					id = string.match(id, "(.+)%..+$") -- remove file extension
					local opts = {
						spawn_in_workspace = true,
						relative = true,
						restore_text = true,
						on_pane_restore = resurrect.tab_state.default_on_pane_restore,
					}
					if type == "workspace" then
						local state = resurrect.load_state(id, "workspace")
						resurrect.workspace_state.restore_workspace(state, opts)
					elseif type == "window" then
						local state = resurrect.load_state(id, "window")
						resurrect.window_state.restore_window(pane:window(), state, opts)
					elseif type == "tab" then
						local state = resurrect.load_state(id, "tab")
						resurrect.tab_state.restore_tab(pane:tab(), state, opts)
					end
				end)
			end),
		},
		{
			key = "d",
			mods = "ALT",
			action = wezterm.action_callback(function(win, pane)
				resurrect.fuzzy_load(win, pane, function(id)
					resurrect.delete_state(id)
				end, {
					title = "Delete State",
					description = "Select State to Delete and press Enter = accept, Esc = cancel, / = filter",
					fuzzy_description = "Search State to Delete: ",
					is_fuzzy = true,
				})
			end),
		},
	},
	key_tables = {
		-- Defines the keys that are active in our resize-pane mode.
		-- Since we're likely to want to make multiple adjustments,
		-- we made the activation one_shot=false. We therefore need
		-- to define a key assignment for getting out of this mode.
		-- 'resize_pane' here corresponds to the name="resize_pane" in
		-- the key assignments above.
		resize_pane = {
			{ key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
			{ key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
			{ key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
			{ key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
			-- Cancel the mode by pressing escape
			{ key = "Escape", action = "PopKeyTable" },
		},
	},
}

for i = 1, 8 do
	-- CTRL + number to activate that tab
	table.insert(commonOpts.keys, {
		key = tostring(i),
		mods = "CTRL",
		action = act.ActivateTab(i - 1),
	})
	-- CTRL + ALT + number to move to that position
	table.insert(commonOpts.keys, {
		key = tostring(i),
		mods = "CTRL|ALT",
		action = wezterm.action.MoveTab(i - 1),
	})
end

local resurrect_event_listeners = {
	"resurrect.error",
	"resurrect.save_state.finished",
}
for _, event in ipairs(resurrect_event_listeners) do
	wezterm.on(event, function(...)
		local args = { ... }
		local msg = event
		for _, v in ipairs(args) do
			msg = msg .. " " .. tostring(v)
		end
		wezterm.gui.gui_windows()[1]:toast_notification("Wezterm - resurrect", msg, nil, 4000)
	end)
end

if not is_linux then
	local default_prog = {
		"pwsh.exe",
		"-NoLogo",
	}

	-- commonOpts.default_prog = { "cmd.exe", "/k", "%CMDER_ROOT%\\vendor\\init.bat" }
	commonOpts.default_prog = default_prog

	-- commonOpts.front_end = "Software"

	wezterm.on("gui-startup", function()
		local tab, pane, window = mux.spawn_window({})
		window:gui_window():maximize()
	end)

	resurrect.save_state_dir = "D:\\workspace\\wezterm-state\\"
end

return commonOpts
