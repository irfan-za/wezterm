local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

local is_windows = os.getenv("OS") and os.getenv("OS"):lower():find("windows")
local is_macos = wezterm.target_triple:lower():find("darwin") ~= nil

-- rose-pine-moon palette, reused by the tab bar and the window buttons
local palette = {
  base = "#232136",
  surface = "#2a273f",
  overlay = "#393552",
  muted = "#6e6a86",
  subtle = "#908caa",
  text = "#e0def4",
  love = "#eb6f92",
  gold = "#f6c177",
  rose = "#ea9a97",
  pine = "#3e8fb0",
  foam = "#9ccfd8",
  iris = "#c4a7e7",
  highlight_med = "#44415a",
}

local color_scheme = "rose-pine-moon"

--------------------------------------------------------------------------------
-- appearance
--------------------------------------------------------------------------------

config.color_scheme = color_scheme
config.font_size = 13
config.max_fps = 120
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"

config.font = wezterm.font_with_fallback({
  { family = "Hack Nerd Font", weight = "Regular" },
  "Symbols Nerd Font Mono",
})
config.warn_about_missing_glyphs = false

config.window_frame = {
  font = wezterm.font("Hack Nerd Font", { weight = "Bold" }),
}
config.inactive_pane_hsb = {
  saturation = 0.9,
  brightness = 0.7,
}

config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

config.scrollback_lines = 10000
config.audible_bell = "Disabled"
config.adjust_window_size_when_changing_font_size = false
config.use_dead_keys = false

--------------------------------------------------------------------------------
-- tab bar
--------------------------------------------------------------------------------

config.enable_tab_bar = true
-- Must stay false: with INTEGRATED_BUTTONS the minimize/maximize/close buttons
-- live inside the tab bar, so hiding the bar also hides the buttons.
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = false
config.use_fancy_tab_bar = false
config.tab_max_width = 32
config.switch_to_last_active_tab_when_closing_tab = true

-- tabline.wez (https://github.com/michaelbrusegard/tabline.wez): retro tab bar
-- with lualine-style sections. Wrapped in pcall so a failed clone (no network on
-- first launch) degrades to the built-in fancy tab bar instead of breaking the config.
local ok, tabline = pcall(wezterm.plugin.require, "https://github.com/michaelbrusegard/tabline.wez")

if ok then
  tabline.setup({
    options = {
      icons_enabled = true,
      theme = color_scheme,
      tabs_enabled = true,
      theme_overrides = {
        normal_mode = {
          a = { fg = palette.base, bg = palette.iris },
          b = { fg = palette.iris, bg = palette.overlay },
          c = { fg = palette.text, bg = palette.base },
        },
        copy_mode = {
          a = { fg = palette.base, bg = palette.gold },
          b = { fg = palette.gold, bg = palette.overlay },
          c = { fg = palette.text, bg = palette.base },
        },
        search_mode = {
          a = { fg = palette.base, bg = palette.foam },
          b = { fg = palette.foam, bg = palette.overlay },
          c = { fg = palette.text, bg = palette.base },
        },
        tab = {
          active = { fg = palette.iris, bg = palette.overlay },
          inactive = { fg = palette.subtle, bg = palette.base },
          inactive_hover = { fg = palette.foam, bg = palette.surface },
        },
      },
    },
    sections = {
      tabline_a = { "mode" },
      tabline_b = { "workspace" },
      tabline_c = { " " },
      tab_active = {
        "index",
        { "parent", padding = 0 },
        "/",
        { "cwd", padding = { left = 0, right = 1 } },
        { "zoomed", padding = 0 },
      },
      tab_inactive = {
        "index",
        { "process", padding = { left = 0, right = 1 } },
      },
       tabline_x = {
    { "ram", use_pwsh = true },
    { "cpu", use_pwsh = true },
  },
      tabline_y = { { "datetime", style = "%H:%M" }, "battery" },
      -- leave room on the right for the integrated window buttons
      tabline_z = { "domain" },
    },
    extensions = {},
  })

  -- NOTE: apply_to_config() force-sets window_decorations = "RESIZE" and zeroes
  -- window_padding, so everything it clobbers is restored below it.
  tabline.apply_to_config(config)
end

--------------------------------------------------------------------------------
-- window frame + clickable integrated buttons
--------------------------------------------------------------------------------

-- RESIZE keeps the drag-to-resize border; INTEGRATED_BUTTONS draws clickable
-- minimize/maximize/close inside the tab bar in place of the OS title bar.
config.window_decorations = "RESIZE|INTEGRATED_BUTTONS"
config.integrated_title_button_style = is_macos and "MacOsNative" or "Windows"
config.integrated_title_buttons = { "Hide", "Maximize", "Close" }
config.integrated_title_button_alignment = "Right"
config.integrated_title_button_color = "Auto"

config.window_padding = {
  left = 8,
  right = 8,
  top = 0,
  bottom = 4,
}

-- The retro tab bar draws the window buttons as text, so they need explicit glyphs.
local function button(glyph, fg, bg)
  return wezterm.format({
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Text = " " .. glyph .. " " },
  })
end

local glyph = {
  hide = wezterm.nerdfonts.md_window_minimize or "_",
  maximize = wezterm.nerdfonts.md_window_maximize or "[]",
  close = wezterm.nerdfonts.md_window_close or "X",
}

config.tab_bar_style = {
  window_hide = button(glyph.hide, palette.subtle, palette.base),
  window_hide_hover = button(glyph.hide, palette.text, palette.highlight_med),
  window_maximize = button(glyph.maximize, palette.subtle, palette.base),
  window_maximize_hover = button(glyph.maximize, palette.text, palette.highlight_med),
  window_close = button(glyph.close, palette.subtle, palette.base),
  window_close_hover = button(glyph.close, palette.base, palette.love),
}

--------------------------------------------------------------------------------
-- keys
--------------------------------------------------------------------------------

config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }
config.unzoom_on_switch_pane = true
config.disable_default_key_bindings = false

config.keys = {
  -- panes
  { key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
  { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
  { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
  { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
  { key = "o", mods = "LEADER", action = act.RotatePanes("Clockwise") },

  -- pane resize (hold LEADER, then repeat with the arrow keys)
  { key = "LeftArrow", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
  { key = "RightArrow", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
  { key = "UpArrow", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
  { key = "DownArrow", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },

  -- tabs
  { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
  { key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
  { key = "w", mods = "LEADER", action = act.ShowTabNavigator },
  {
    key = "r",
    mods = "LEADER",
    action = act.PromptInputLine({
      description = "Rename tab:",
      action = wezterm.action_callback(function(window, _, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    }),
  },

  -- workspaces
  { key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
  {
    key = "S",
    mods = "LEADER|SHIFT",
    action = act.PromptInputLine({
      description = "New workspace:",
      action = wezterm.action_callback(function(window, pane, line)
        if line and line ~= "" then
          window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
        end
      end),
    }),
  },

  -- misc
  { key = "f", mods = "LEADER", action = act.Search({ CaseInSensitiveString = "" }) },
  { key = "e", mods = "LEADER", action = act.QuickSelect },
  { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
  { key = "p", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },
  { key = "Enter", mods = "ALT", action = act.ToggleFullScreen },
  { key = "k", mods = "CTRL|SHIFT", action = act.ClearScrollback("ScrollbackAndViewport") },
}

-- LEADER + 1..9 jumps straight to a tab
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "LEADER",
    action = act.ActivateTab(i - 1),
  })
end

config.key_tables = {
  resize_pane = {
    { key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 3 }) },
    { key = "RightArrow", action = act.AdjustPaneSize({ "Right", 3 }) },
    { key = "UpArrow", action = act.AdjustPaneSize({ "Up", 3 }) },
    { key = "DownArrow", action = act.AdjustPaneSize({ "Down", 3 }) },
    { key = "h", action = act.AdjustPaneSize({ "Left", 3 }) },
    { key = "l", action = act.AdjustPaneSize({ "Right", 3 }) },
    { key = "k", action = act.AdjustPaneSize({ "Up", 3 }) },
    { key = "j", action = act.AdjustPaneSize({ "Down", 3 }) },
    { key = "Escape", action = "PopKeyTable" },
    { key = "Enter", action = "PopKeyTable" },
  },
}

config.mouse_bindings = {
  -- CTRL+click opens the hovered link; a plain click still just moves the cursor
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "CTRL",
    action = act.OpenLinkAtMouseCursor,
  },
  {
    event = { Down = { streak = 1, button = "Left" } },
    mods = "CTRL",
    action = act.Nop,
  },
}

--------------------------------------------------------------------------------
-- quick select / hyperlinks
--------------------------------------------------------------------------------

config.quick_select_patterns = {
  "[0-9a-f]{7,40}", -- git hashes
  "[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+", -- paths and owner/repo
}

config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, {
  regex = [[["']?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["']?]],
  format = "https://www.github.com/$1/$3",
})

--------------------------------------------------------------------------------
-- platform
--------------------------------------------------------------------------------

if is_windows then
  config.win32_system_backdrop = "Acrylic"
  config.window_background_opacity = 0.5
  config.window_frame.font_size = 10.0
  config.wsl_domains = {
    {
      name = "WSL:Ubuntu",
      distribution = "Ubuntu",
      username = "irfan",
      default_cwd = "/home/irfan/experiment",
    },
  }
  config.default_domain = "WSL:Ubuntu"
  config.launch_menu = {
    { label = "WSL: Ubuntu", domain = { DomainName = "WSL:Ubuntu" } },
    { label = "PowerShell", args = { "powershell.exe", "-NoLogo" } },
    { label = "Command Prompt", args = { "cmd.exe" } },
  }
end

if is_macos then
  config.window_background_opacity = 0.8
  config.macos_window_background_blur = 50
  config.font_size = 15.0
  config.window_frame.font_size = 13.0
end

return config
