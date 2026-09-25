local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- Shell
config.default_prog = { 'pwsh', '-NoLogo' }
config.default_cwd = wezterm.home_dir

-- Rendering
config.front_end = 'WebGpu'
config.max_fps = 144
config.animation_fps = 60

-- Look
config.font = wezterm.font 'IosevkaTerm Nerd Font Mono'
config.font_size = 22.0
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.window_decorations = 'TITLE | RESIZE'
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.adjust_window_size_when_changing_font_size = false
config.window_close_confirmation = 'NeverPrompt'

-- Alacritty default colors
config.colors = {
  foreground = '#d8d8d8',
  background = '#181818',
  cursor_bg = '#d8d8d8',
  cursor_fg = '#181818',
  cursor_border = '#d8d8d8',
  selection_bg = '#d8d8d8',
  selection_fg = '#181818',
  ansi = {
    '#181818', '#ac4242', '#90a959', '#f4bf75',
    '#6a9fb5', '#aa759f', '#75b5aa', '#d8d8d8',
  },
  brights = {
    '#6b6b6b', '#c55555', '#aac474', '#feca88',
    '#82b8c8', '#c28cb8', '#93d3c3', '#f8f8f8',
  },
  tab_bar = {
    background = '#181818',
    active_tab = { bg_color = '#282828', fg_color = '#d8d8d8' },
    inactive_tab = { bg_color = '#181818', fg_color = '#6b6b6b' },
    inactive_tab_hover = { bg_color = '#282828', fg_color = '#d8d8d8' },
    new_tab = { bg_color = '#181818', fg_color = '#6b6b6b' },
    new_tab_hover = { bg_color = '#282828', fg_color = '#d8d8d8' },
  },
}

-- Dim unfocused split panes
config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.6 }

-- Fixed window title instead of the shell path
wezterm.on('format-window-title', function()
  return 'WezTerm'
end)

-- Kitty-style splits and tabs
config.keys = {
  -- Windows Terminal style: auto split (Alt+Shift+D) picks the longer side
  {
    key = 'd', mods = 'ALT|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      local d = pane:get_dimensions()
      if d.pixel_width > d.pixel_height then
        window:perform_action(act.SplitHorizontal { domain = 'CurrentPaneDomain' }, pane)
      else
        window:perform_action(act.SplitVertical { domain = 'CurrentPaneDomain' }, pane)
      end
    end),
  },
  { key = '-', mods = 'ALT|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = '_', mods = 'ALT|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = '=', mods = 'ALT|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '+', mods = 'ALT|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = false } },
  { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'LeftArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
  { key = 'LeftArrow', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Left', 3 } },
  { key = 'RightArrow', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Right', 3 } },
  { key = 'UpArrow', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Up', 3 } },
  { key = 'DownArrow', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Down', 3 } },
  { key = 'z', mods = 'CTRL|SHIFT', action = act.TogglePaneZoomState },
}

-- Ctrl+scroll to zoom the font (Ctrl+0 resets)
config.mouse_bindings = {
  {
    event = { Down = { streak = 1, button = { WheelUp = 1 } } },
    mods = 'CTRL',
    action = act.IncreaseFontSize,
  },
  {
    event = { Down = { streak = 1, button = { WheelDown = 1 } } },
    mods = 'CTRL',
    action = act.DecreaseFontSize,
  },
}

return config
