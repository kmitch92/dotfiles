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
    { Foreground = { Color = '#cdd6f4' } },
    { Background = { Color = '#313244' } },
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

-- Catppuccin Mocha Color Scheme
config.colors = {
  foreground = '#cdd6f4',
  background = '#1e1e2e',
  cursor_bg = '#f5e0dc',
  cursor_border = '#f5e0dc',
  cursor_fg = '#1e1e2e',
  selection_bg = '#585b70',
  selection_fg = '#cdd6f4',
  
  ansi = {
    '#45475a', -- black
    '#f38ba8', -- red
    '#a6e3a1', -- green
    '#f9e2af', -- yellow
    '#89b4fa', -- blue
    '#f5c2e7', -- magenta
    '#94e2d5', -- cyan
    '#bac2de', -- white
  },
  
  brights = {
    '#585b70', -- bright black
    '#f38ba8', -- bright red
    '#a6e3a1', -- bright green
    '#f9e2af', -- bright yellow
    '#89b4fa', -- bright blue
    '#f5c2e7', -- bright magenta
    '#94e2d5', -- bright cyan
    '#a6adc8', -- bright white
  },
  
  tab_bar = {
    background = '#1e1e2e',
    active_tab = {
      bg_color = '#cba6f7',
      fg_color = '#11111b',
      intensity = 'Normal',
      underline = 'None',
      italic = false,
      strikethrough = false,
    },
    inactive_tab = {
      bg_color = '#181825',
      fg_color = '#cdd6f4',
    },
    inactive_tab_hover = {
      bg_color = '#313244',
      fg_color = '#cdd6f4',
    },
    new_tab = {
      bg_color = '#181825',
      fg_color = '#cdd6f4',
    },
    new_tab_hover = {
      bg_color = '#313244',
      fg_color = '#cdd6f4',
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
