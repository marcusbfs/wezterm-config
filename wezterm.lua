local wezterm = require "wezterm"

return {
    default_cwd = "d:\\workspace",
    -- Font
    font = wezterm.font("FiraCode NF"),
    font_size = 14.0,
    -- Cursor
    default_cursor_style = "SteadyBar",
    -- Start Cmderr: cmd.exe /k %CMDER_ROOT%\\vendor\\init.bat
    default_prog = {"cmd.exe", "/k", "%CMDER_ROOT%\\vendor\\init.bat"},
    color_scheme = "Gruvbox Dark",
    -- padding
    window_padding = {
        top = 0,
        bottom = 0,
        left = 5,
        right = 2
    },
    -- tab config
    hide_tab_bar_if_only_one_tab = true,
    -- timeout_milliseconds defaults to 1000 and can be omitted
    leader = {key = "a", mods = "CTRL", timeout_milliseconds = 1000},
    -- mappings
    keys = {
        -- Disable ctrl-l
        -- {key = "l", mods = "CTRL", action = wezterm.action {SendString = "clear"}},
        -- Disable alt+number to change tabs. I used this in vim
        {key = "1", mods = "ALT", action = {SendKey = {key = "1", mods = "ALT"}}},
        {key = "2", mods = "ALT", action = {SendKey = {key = "2", mods = "ALT"}}},
        {key = "3", mods = "ALT", action = {SendKey = {key = "3", mods = "ALT"}}},
        {key = "4", mods = "ALT", action = {SendKey = {key = "4", mods = "ALT"}}},
        {key = "5", mods = "ALT", action = {SendKey = {key = "5", mods = "ALT"}}},
        {key = "6", mods = "ALT", action = {SendKey = {key = "6", mods = "ALT"}}},
        {key = "7", mods = "ALT", action = {SendKey = {key = "7", mods = "ALT"}}},
        {key = "8", mods = "ALT", action = {SendKey = {key = "8", mods = "ALT"}}},
        -- Create panes
        {key = "_", mods = "LEADER|SHIFT", action = wezterm.action {SplitHorizontal = {domain = "CurrentPaneDomain"}}},
        {key = "-", mods = "LEADER", action = wezterm.action {SplitVertical = {domain = "CurrentPaneDomain"}}},
        -- Move between panes
        {key = "j", mods = "LEADER", action = wezterm.action {ActivatePaneDirection = "Down"}},
        {key = "k", mods = "LEADER", action = wezterm.action {ActivatePaneDirection = "Up"}},
        {key = "l", mods = "LEADER", action = wezterm.action {ActivatePaneDirection = "Right"}},
        {key = "h", mods = "LEADER", action = wezterm.action {ActivatePaneDirection = "Left"}},
        -- Close current pane
        {key = "c", mods = "LEADER", action = wezterm.action {CloseCurrentPane = {confirm = true}}},
        -- Send "CTRL-A" to the terminal when pressing CTRL-A, CTRL-A
        {key = "a", mods = "LEADER|CTRL", action = wezterm.action {SendString = "\x01"}}
    }
}
