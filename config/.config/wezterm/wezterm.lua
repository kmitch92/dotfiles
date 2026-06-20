-- WezTerm Configuration
-- https://wezfurlong.org/wezterm/config/files.html

local wezterm = require 'wezterm'
local config = {}

-- Use config builder for better error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Font Configuration
config.font = wezterm.font 'JetBrains Mono'
config.font_size = 13.0
config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' } -- Disable ligatures

-- Window Configuration
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}
config.window_background_opacity = 0.95
config.macos_window_background_blur = 20
config.window_decorations = "RESIZE"
config.native_macos_fullscreen_mode = false

-- Tab Bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = true
config.tab_max_width = 25
config.show_tab_index_in_tab_bar = true
config.switch_to_last_active_tab_when_closing_tab = true

-- Status Bar (custom implementation)
wezterm.on('update-right-status', function(window, pane)
  -- Get current working directory
  local cwd = pane:get_current_working_dir()
  local cwd_path = ''
  if cwd then
    cwd_path = cwd.file_path:gsub(os.getenv('HOME'), '~')
  end
  
  -- Get time
  local time = wezterm.strftime('%H:%M:%S')
  
  -- Get date
  local date = wezterm.strftime('%a %b %d')
  
  -- Get battery info (macOS)
  local battery = ''
  for _, b in ipairs(wezterm.battery_info()) do
    local battery_state = ''
    if b.state == 'Charging' then
      battery_state = '⚡'
    elseif b.state == 'Discharging' then
      battery_state = '🔋'
    else
      battery_state = '🔌'
    end
    battery = string.format('%s %.0f%%', battery_state, b.state_of_charge * 100)
  end
  
  -- Combine elements
  local elements = {}
  if cwd_path ~= '' then
    table.insert(elements, cwd_path)
  end
  if battery ~= '' then
    table.insert(elements, battery)
  end
  table.insert(elements, date)
  table.insert(elements, time)
  
  window:set_right_status(wezterm.format({
    { Foreground = { Color = '#ebdbb2' } },
    { Background = { Color = '#3c3836' } },
    { Text = ' ' .. table.concat(elements, ' │ ') .. ' ' },
  }))
end)

-- Scrollback
config.scrollback_lines = 10000

-- Cursor
config.default_cursor_style = 'BlinkingBlock'
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

-- Mouse
config.hide_mouse_cursor_when_typing = true

-- Performance
config.animation_fps = 60
config.max_fps = 60
config.front_end = "WebGpu"

-- Shell
config.default_prog = { '/bin/zsh', '-l' }

-- Gruvbox Dark Hard Color Scheme
config.colors = {
  foreground = '#ebdbb2',
  background = '#1d2021',
  cursor_bg = '#ebdbb2',
  cursor_border = '#ebdbb2',
  cursor_fg = '#1d2021',
  selection_bg = '#504945',
  selection_fg = '#ebdbb2',

  ansi = {
    '#282828', -- black
    '#cc241d', -- red
    '#98971a', -- green
    '#d79921', -- yellow
    '#458588', -- blue
    '#b16286', -- magenta
    '#689d6a', -- cyan
    '#a89984', -- white
  },

  brights = {
    '#928374', -- bright black
    '#fb4934', -- bright red
    '#b8bb26', -- bright green
    '#fabd2f', -- bright yellow
    '#83a598', -- bright blue
    '#d3869b', -- bright magenta
    '#8ec07c', -- bright cyan
    '#ebdbb2', -- bright white
  },

  tab_bar = {
    background = '#1d2021',
    active_tab = {
      bg_color = '#fe8019',
      fg_color = '#1d2021',
      intensity = 'Normal',
      underline = 'None',
      italic = false,
      strikethrough = false,
    },
    inactive_tab = {
      bg_color = '#282828',
      fg_color = '#a89984',
    },
    inactive_tab_hover = {
      bg_color = '#3c3836',
      fg_color = '#ebdbb2',
    },
    new_tab = {
      bg_color = '#282828',
      fg_color = '#a89984',
    },
    new_tab_hover = {
      bg_color = '#3c3836',
      fg_color = '#ebdbb2',
    },
  },
}

-- Key Bindings
config.keys = {
  -- Tab navigation
  { key = 't', mods = 'CMD', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CMD', action = wezterm.action.CloseCurrentTab { confirm = true } },
  { key = ']', mods = 'CMD|SHIFT', action = wezterm.action.ActivateTabRelative(1) },
  { key = '[', mods = 'CMD|SHIFT', action = wezterm.action.ActivateTabRelative(-1) },
  
  -- Pane splitting
  { key = 'd', mods = 'CMD', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'CMD|SHIFT', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },
  
  -- Font size
  { key = '+', mods = 'CMD', action = wezterm.action.IncreaseFontSize },
  { key = '-', mods = 'CMD', action = wezterm.action.DecreaseFontSize },
  { key = '0', mods = 'CMD', action = wezterm.action.ResetFontSize },
  
  -- Copy/Paste
  { key = 'c', mods = 'CMD', action = wezterm.action.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CMD', action = wezterm.action.PasteFrom 'Clipboard' },
  
  -- Search
  { key = 'f', mods = 'CMD', action = wezterm.action.Search 'CurrentSelectionOrEmptyString' },
}

-- macOS specific settings
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

return config
