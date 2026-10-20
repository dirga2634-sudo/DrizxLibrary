# DrizxLibrary

Lightweight Roblox UI library built for touch screens (mobile) and PC.

**Version:** 13.6.0
**Creators:** absorpohonods & haibung03

## Features

- Works with both mouse and touch input
- Draggable window and draggable floating toggle button
- **Fully customizable floating button** (your own asset id, size, shape, colors, border) and **customizable menu** (size, background color/image, corners, border, header icon)
- Animated **loading screen** (spinner, progress bar, status text)
- **Minimize** (collapse to the header) and **Close** (remove the UI completely)
- Tabs with icons, plus Section, Paragraph, Label, Divider, Button, Toggle, Slider, Dropdown, Textbox and **ColorPicker** components
- **Config saving/loading** (flags): save every setting to a file and load it back later
- Soft drop shadow behind the menu
- **Built-in vector icons** (no asset ids needed, so they work on every phone and PC)
- 7 built-in themes (`Dark`, `Light`, `Ocean`, `Emerald`, `Rose`, `Amethyst`, `Amber`) with per-color overrides
- Polished look: animated tab indicator, switch-style toggles, sliders with a draggable handle, dropdown check marks, input focus borders, hover highlights on PC, slide-in notifications, touch-friendly rows and larger text
- Notifications
- Responsive layout that follows the viewport size
- Clean teardown: every connection, tween and drag is cleaned up on destroy

## Installation

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/dirga2634-sudo/DrizxLibrary/main/Library.lua"))()
```

## Quick start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/dirga2634-sudo/DrizxLibrary/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "My Hub",
    SubTitle = "by you",
    Theme = "Dark",
})

local Tab = Window:CreateTab("Main", "Home")

Tab:CreateSection("Actions")

Tab:CreateButton({
    Name = "Say hello",
    Callback = function()
        Library:Notify({ Title = "Hello", Content = "Button clicked!" })
    end,
})

Tab:CreateToggle({
    Name = "Auto farm",
    Default = false,
    Callback = function(state)
        print("Auto farm:", state)
    end,
})
```

When the script runs, a loading card appears first. After it finishes, the window opens automatically.

---

## Window controls

| Control | What it does |
| --- | --- |
| Floating round button | Tap to open / close the window. Drag to move it. |
| Header | Drag to move the window. |
| Minimize button (`─`) | Collapses the window to just its header. Press again to restore. |
| Close button (`✕`) | **Removes the UI completely** (window shrinks, floating button fades out, everything is destroyed). |

The minimize and close icons are drawn from Frames instead of text characters, so they render correctly on every device and font.

If you would rather have the X button only hide the window (so it can be reopened from the floating button), use `CloseAction = "Hide"`.

---

## Library API

### `Library:CreateWindow(config)` → `Window`

All fields are optional.

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| `Title` | string | `"DrizxLibrary"` | Window title shown in the header. |
| `SubTitle` | string | `"v" .. Library.Version` | Text shown after the title. |
| `Logo` | string / number | `"Zap"` | Icon preset name, asset id, or `rbxassetid://...`. Used in the header, floating button and loading card. |
| `Theme` | string / table | `"Dark"` | A theme name (`"Dark"`, `"Light"`, `"Ocean"`, `"Emerald"`, `"Rose"`, `"Amethyst"`, `"Amber"`) or an override table (see [Themes](#themes)). |
| `FloatingButton` | table / asset id | `nil` | Customize the floating button. See [Floating button](#floating-button). |
| `FloatingIcon` | string / number | `nil` | Shorthand for `FloatingButton.Icon`. |
| `Menu` | table | `nil` | Customize the menu (main window). See [Menu](#menu). |
| `BackgroundType` | string | `"Color"` | Legacy. `"Color"` or `"Image"`. Prefer `Menu.BackgroundImage`. |
| `BackgroundColor` | Color3 | theme `Background` | Legacy. Prefer `Menu.BackgroundColor`. |
| `BackgroundImage` | string / number | `""` | Legacy. Used when `BackgroundType = "Image"`. Prefer `Menu.BackgroundImage`. |
| `BackgroundTransparency` | number | `0` | Legacy. Prefer `Menu.BackgroundTransparency`. |
| `Loading` | boolean | `true` | Show the loading animation. Set to `false` to disable it. |
| `LoadingTitle` | string | `Title` | Title text on the loading card. |
| `LoadingDuration` | number | `1.8` | Loading time in seconds (minimum `0.3`). |
| `LoadingSteps` | table | `{"Loading modules...", "Preparing UI...", "Almost done..."}` | Status texts shown as the progress advances. |
| `AutoOpen` | boolean | `true` | Open the window automatically once loading finishes. |
| `CloseAction` | string | `"Destroy"` | `"Destroy"` removes the UI; `"Hide"` only hides the window. |
| `ConfigFolder` | string | `"DrizxLibrary"` | Folder (in the executor workspace) where config files are stored. |
| `ToggleKey` | `Enum.KeyCode` / string | `nil` | PC shortcut that opens and closes the menu, e.g. `Enum.KeyCode.RightShift` or `"RightShift"`. |
| `AutoLocalize` | boolean | `false` | Roblox auto-translates UI text for players with a non-English language ("Settings" becomes "Pengaturan"). The library turns that off so your text stays as written. Set `true` to allow translation. |

### `Library:Notify(config)`

Shows a notification on the most recently created window. Create a window first.

### `Library:Destroy()`

Destroys every window created by the library.

### Other fields

| Field | Description |
| --- | --- |
| `Library.Version` | Library version string. |
| `Library.Windows` | List of live windows. |
| `Library.Themes` | The built-in `Dark` and `Light` theme tables. |

---

## Floating button

The round button that opens and closes the menu. Everything about it can be customized, including the image: just give it your own asset id.

```lua
local Window = Library:CreateWindow({
    Title = "My Hub",
    FloatingButton = {
        Icon = 1234567890,                      -- your image asset id
        Size = 48,
        Shape = "Circle",
        StrokeColor = Color3.fromRGB(0, 255, 120),
        StrokeThickness = 2,
    },
})
```

Shortcuts:

```lua
FloatingIcon = 1234567890                 -- same as FloatingButton = { Icon = 1234567890 }
FloatingButton = 1234567890               -- also works
```

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `Icon` | string / number | `Logo` | Image asset id, `"rbxassetid://..."`, or a preset icon name. |
| `Size` | number | `42` | Size in pixels (clamped between `24` and `96`). |
| `Shape` | string | `"Circle"` | `"Circle"`, `"Rounded"` or `"Square"`. |
| `CornerRadius` | number | from `Shape` | Corner radius in pixels. Overrides `Shape`. |
| `BackgroundColor` | Color3 | theme `Surface` | Color behind the image. |
| `BackgroundTransparency` | number | `0.15` | `0` (solid) to `1` (invisible). |
| `StrokeColor` | Color3 | theme `Accent` | Border (ring) color. |
| `StrokeThickness` | number | `1.2` | Border thickness. Use `0` for no border. |
| `ImageColor` | Color3 | white for custom images | Tint applied to the image. |
| `ScaleType` | string | `"Crop"` | `"Crop"`, `"Fit"` or `"Stretch"`. |
| `Position` | Vector2 / UDim2 | left edge, vertically centered | Start position in pixels. |
| `Visible` | boolean | `true` | Set to `false` to hide the button (open the menu with `Window:Toggle()`). |

Only the options you pass are changed, and you can change them at any time:

```lua
Window:SetFloatingButton({ Icon = 9876543210, StrokeColor = Color3.fromRGB(255, 80, 80) })
Window:SetFloatingButton(9876543210) -- icon only
```

The button stays draggable, and is always kept inside the screen.

---

## Menu

The menu is the main window. Size, background, corners, border and header icon are all customizable.

```lua
local Window = Library:CreateWindow({
    Title = "My Hub",
    Menu = {
        Width = 440,
        Height = 280,
        BackgroundColor = Color3.fromRGB(10, 10, 16),
        BackgroundImage = 1234567890,        -- your image asset id
        BackgroundImageTransparency = 0.3,
        CornerRadius = 14,
        StrokeColor = Color3.fromRGB(0, 255, 120),
        StrokeThickness = 1.5,
        Icon = 1234567890,                   -- icon in the header
    },
})
```

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `Width` | number | auto | Preferred width in pixels. Always clamped to the screen and a sensible minimum. |
| `Height` | number | auto | Preferred height in pixels. Always clamped to the screen and a sensible minimum. |
| `BackgroundColor` | Color3 | theme `Background` | Window background color. |
| `BackgroundTransparency` | number | `0` | `0` (solid) to `1` (invisible). |
| `BackgroundImage` | string / number | `nil` | Image asset id shown behind the menu. |
| `BackgroundImageTransparency` | number | `0` | `0` (fully visible) to `1` (hidden). |
| `CornerRadius` | number | `10` | Corner radius in pixels. |
| `StrokeColor` | Color3 | theme `Stroke` | Border color. |
| `StrokeThickness` | number | `1.2` | Border thickness. |
| `Icon` | string / number | `Logo` | Icon shown in the header. |
| `Shadow` | boolean | `true` | Soft drop shadow behind the menu. |
| `ShadowTransparency` | number | `0.55` | `0` (dark) to `1` (invisible). |

Change it at any time:

```lua
Window:SetMenu({ BackgroundImage = 9876543210, CornerRadius = 6 })
Window:SetMenu({ BackgroundImage = "" }) -- remove the background image
```

For colors of the content inside the menu (cards, text, accent), use [Themes](#themes).

---

## Loading screen

```lua
local Window = Library:CreateWindow({
    Title = "My Hub",
    LoadingTitle = "My Hub",
    LoadingDuration = 2.5,
    LoadingSteps = { "Connecting...", "Loading features...", "Ready!" },
    AutoOpen = true,
})
```

- The dimmed backdrop and loading card fade in, the spinner rotates, and the progress bar fills over `LoadingDuration`.
- The status text changes as the progress passes each step.
- When loading finishes, the card fades out, the floating button appears, and the window opens (unless `AutoOpen = false`).
- Disable it completely with `Loading = false`.
- To end it early (for example after you finish building your tabs), call `Window:FinishLoading()`.

---

## Window API

### `Window:CreateTab(name, icon)` / `Window:CreateTab({ Name, Icon })` → `Tab`

Creates a tab in the sidebar. The icon defaults to `"Code"`. Calling it again with the same name returns the existing tab. The first tab you create is activated automatically.

### `Window:Notify(config)`

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| `Title` | string | `"Notification"` | Notification title. |
| `Content` | string | `""` | Notification body text. |
| `Duration` | number | `3` | Seconds before it fades out (minimum `0.5`). |
| `Type` | string | `"Info"` | `"Info"`, `"Success"`, `"Warning"` or `"Error"`. Changes the color and the default icon. |
| `Icon` | string / number | depends on `Type` | Icon preset name or asset id (`Bell` for Info, `Check`, `Warning`, `Error`). |

### `Window:Toggle()`

Opens the window if it is closed, or hides it if it is open.

### Config methods

| Method | Returns | Description |
| --- | --- | --- |
| `Window:SaveConfig(name)` | `true, name` or `false, message` | Writes all flags to a file. |
| `Window:LoadConfig(name)` | `true, appliedCount` or `false, message` | Reads a file and applies it (callbacks fire). |
| `Window:DeleteConfig(name)` | `true, name` or `false, message` | Deletes a config file. |
| `Window:ListConfigs()` | table of names | Saved configs (empty if the executor has no `listfiles`). |
| `Window:GetConfig()` | table | Current value of every flag. |
| `Window:ApplyConfig(table)` | number | Applies a table of flag values. |
| `Window:GetFlag(flag)` / `Window:SetFlag(flag, value)` | value / boolean | Read or set a single flag (`SetFlag` fires the callback). |
| `Window:CreateConfigTab(name, icon)` | `Tab` | Ready-made config tab (default name `"Config"`). |

### `Window:SetFloatingButton(options)` / `Window:SetFloatingButton(assetId)`

Changes the floating button's look at runtime. See [Floating button](#floating-button).

### `Window:SetMenu(options)`

Changes the menu's look at runtime. See [Menu](#menu).

### `Window:Close()`

Removes the UI with the close animation. Same as pressing the X button (with the default `CloseAction`).

### `Window:FinishLoading()`

Skips the rest of the loading animation.

### `Window:OnDestroy(callback)`

Registers a function that runs when the window is destroyed. Useful for disconnecting your own connections.

```lua
Window:OnDestroy(function()
    myConnection:Disconnect()
end)
```

### `Window:DestroyTab(name)`

Removes a single tab. If it was the active tab, another tab is activated.

### `Window:Destroy()`

Destroys the window immediately, without an animation.

### Window fields

| Field | Description |
| --- | --- |
| `Window.Minimized` | `true` while the window is collapsed to its header. |
| `Window.IsDestroyed` | `true` after the window is destroyed. |
| `Window.Tabs` | Table of tabs, keyed by tab name. |
| `Window.CurrentTab` | The active tab. |

---

## Tab components

Every component accepts either a config table (recommended) or positional arguments.

### `Tab:CreateSection(text)`

A small uppercase heading. Accepts a string or `{ Name = "..." }`.

### `Tab:CreateParagraph({ Title, Content })`

A card with a title and a wrapped description. Also accepts `Tab:CreateParagraph(title, description)`.

### `Tab:CreateButton({ Name, Callback })`

```lua
Tab:CreateButton({
    Name = "Click me",
    Callback = function() print("clicked") end,
})
```

### `Tab:CreateToggle({ Name, Default, Callback })`

The callback receives the new state (`true` / `false`).

```lua
local toggle = Tab:CreateToggle({
    Name = "ESP",
    Default = false,
    Callback = function(state) print(state) end,
})

toggle:SetState(true) -- does not fire the callback
print(toggle:GetState())
```

### `Tab:CreateSlider({ Name, Min, Max, Default, Increment, Callback })`

The callback receives the new value, and only fires when the value actually changes.

| Field | Default | Description |
| --- | --- | --- |
| `Min` | `0` | Minimum value. |
| `Max` | `100` | Maximum value. |
| `Default` | `Min` | Starting value. |
| `Increment` | `1` for integer ranges, otherwise continuous (1 decimal) | Step size. |

```lua
local slider = Tab:CreateSlider({
    Name = "Walk speed",
    Min = 16,
    Max = 100,
    Default = 16,
    Increment = 1,
    Callback = function(value) print(value) end,
})

slider:SetValue(50) -- does not fire the callback
print(slider:GetValue())
```

### `Tab:CreateDropdown({ Name, Options, Default, Multi, Callback, Flag })`

The callback receives the selected option (as a string). Duplicate options are removed. The selected option gets a check mark.

```lua
local dropdown = Tab:CreateDropdown({
    Name = "Mode",
    Options = { "Easy", "Normal", "Hard" },
    Default = "Normal",
    Callback = function(option) print(option) end,
})

dropdown:Set("Hard")               -- does not fire the callback
print(dropdown:Get())
dropdown:Refresh({ "A", "B", "C" }) -- replace the options
```

With `Multi = true` the player can tick several options. The list stays open while picking, the callback receives a **list** of the selected names, and `Default`, `Set`, `Get` and the saved config value are lists too.

```lua
Tab:CreateDropdown({
    Name = "ESP parts",
    Options = { "Box", "Skeleton", "Distance", "Health" },
    Default = { "Box" },
    Multi = true,
    Flag = "esp_parts",
    Callback = function(list)
        print(table.concat(list, ", "))
    end,
})
```

### `Tab:CreateTextbox({ Name, Placeholder, Default, ClearOnFocus, Callback })`

The callback fires when the box loses focus and receives `(text, enterPressed)`.

```lua
local box = Tab:CreateTextbox({
    Name = "Username",
    Placeholder = "Type here...",
    Callback = function(text, enterPressed) print(text, enterPressed) end,
})

box:Set("hello")
print(box:Get())
```

### `Tab:CreateKeybind({ Name, Default, Callback, OnChanged, Flag })`

For keyboards (PC). Click the key box, then press a key to bind it; `Escape` clears the binding. `Callback` runs every time the bound key is pressed (not while typing in a text box). `OnChanged(keyName)` runs when the binding changes.

```lua
local bind = Tab:CreateKeybind({
    Name = "Toggle ESP",
    Default = "E",                  -- an Enum.KeyCode or its name
    Flag = "esp_key",
    Callback = function(key)
        print("pressed", key)
    end,
})

bind:Set("Q")      -- does not fire the callbacks
print(bind:Get())  -- Enum.KeyCode.Q (or nil)
```

### `Tab:CreateColorPicker({ Name, Default, Callback, Flag })`

Tap the card to open a saturation/value map and a hue bar. Drag on either one (mouse or touch). The callback receives a `Color3` and fires while you drag.

```lua
local picker = Tab:CreateColorPicker({
    Name = "Box color",
    Default = Color3.fromRGB(255, 50, 50),
    Callback = function(color)
        print(color)
    end,
})

picker:Set(Color3.fromRGB(0, 255, 120)) -- also accepts "#00FF78"; does not fire the callback
print(picker:Get())                       -- Color3
```

### `Tab:CreateLabel(text)` / `Tab:CreateLabel({ Text })`

A plain text line you can change later.

```lua
local status = Tab:CreateLabel("Waiting...")
status:Set("Connected")
print(status:Get())
```

### `Tab:CreateDivider()`

A thin line to separate groups of components.

---

## Flags and configs

Give a component a `Flag` and its value becomes part of the window's config. Flags work on Toggle, Slider, Dropdown, Textbox, Keybind and ColorPicker.

```lua
Tab:CreateToggle({ Name = "ESP", Default = false, Flag = "esp_enabled", Callback = function(v) print(v) end })
Tab:CreateSlider({ Name = "FOV", Min = 40, Max = 120, Default = 70, Flag = "fov", Callback = print })
Tab:CreateColorPicker({ Name = "Box color", Flag = "box_color", Callback = print })

-- A ready-made tab with a name box, the list of saved configs, and Save / Load / Delete buttons:
Window:CreateConfigTab()
```

Or use the methods directly:

```lua
local ok, result = Window:SaveConfig("legit")   -- true, "legit"
local ok, applied = Window:LoadConfig("legit")  -- true, number of settings applied
```

- Loading a config applies the values **and fires each component's callback**, so your script's own state is updated too.
- Configs are JSON files in `<ConfigFolder>/<name>.json`. Colors are stored as `"#RRGGBB"`.
- Saving needs the executor's file functions (`writefile`, `readfile`, and for the list/delete features `listfiles`, `delfile`, `isfile`, `makefolder`). If something is missing, the method returns `false` and a message, and nothing breaks.
- Config names may contain letters, numbers, spaces, `-` and `_`.

---

## Themes

`Theme` can be a preset name or a table. Built-in presets:

| Preset | Look |
| --- | --- |
| `Dark` | Default. Layered dark blue-gray with a blue accent. |
| `Light` | Light gray and white with a blue accent. |
| `Ocean` | Dark with a cyan accent. |
| `Emerald` | Dark with a green accent. |
| `Rose` | Dark with a pink accent. |
| `Amethyst` | Dark with a purple accent. |
| `Amber` | Dark with an orange accent. |

```lua
Library:CreateWindow({ Theme = "Ocean" })
```

You can also start from a preset and change single colors:

```lua
-- Preset
Library:CreateWindow({ Theme = "Light" })

-- Override colors on top of a preset
Library:CreateWindow({
    Theme = {
        Base = "Dark",
        Accent = Color3.fromRGB(255, 80, 120),
    },
})
```

Available color tokens:

| Token | Used for |
| --- | --- |
| `Background` | Window background |
| `Card` | Component cards |
| `Surface` | Header, sidebar, content area |
| `Raised` | Active tab, buttons, tracks |
| `Stroke` | Borders |
| `Accent` | Toggles, slider fill, active tab, section titles, spinner, focus borders |
| `Text` | Primary text |
| `SubText` | Secondary text |
| `Muted` | Section headings, placeholders |
| `Success` | Toggle "on" color |
| `Notification` | Notification and loading card background |
| `Danger` | Close button hover color |

Unknown theme names fall back to `Dark` with a warning in the output.

---

## Icons

Anywhere an icon is accepted (`Logo`, `FloatingButton.Icon`, `Menu.Icon`, tab icons, notification icons) you can pass:

- a **preset name** (not case sensitive): `Home`, `Settings`, `Chat`, `Player`, `Zap`, `Search`, `Shield`, `Code`, `Bell`, `Globe`, `Key`, `Palette`, `Eye`, `Target`, `Folder`, `ChevronDown`, `ChevronRight`, `Check`, `Info`, `Warning`, `Error`
- an **asset id** (number or numeric string), e.g. `10723415903`
- a full asset string, e.g. `"rbxassetid://10723415903"` (`rbxthumb://` and `rbxasset://` also work)
- a `roblox.com/asset/?id=...` link

`Library:GetIcons()` returns the list of preset names.

**Preset icons are drawn in code** from simple shapes on a 16x16 grid. They need no asset, so they look the same on every phone and PC, scale to any size, and follow the theme colors (text color normally, accent color for the active tab).

**Your own images** (asset ids) are shown exactly as they are, with no tint, unless you set `ImageColor`. If your image shows up blank, make sure you are using the **Image** asset id and not the **Decal** id, and that the asset is public.

If a tab icon can't be understood, the library prints a warning and uses the `Code` icon instead.

---

## Full example

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/dirga2634-sudo/DrizxLibrary/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Drizx Hub",
    SubTitle = "v1.0",
    Theme = { Base = "Dark", Accent = Color3.fromRGB(0, 200, 140) },
    FloatingButton = { Icon = 1234567890, Size = 46, StrokeColor = Color3.fromRGB(0, 200, 140) },
    Menu = { Width = 440, Height = 280, CornerRadius = 14 },
    LoadingDuration = 2,
    LoadingSteps = { "Connecting...", "Loading features...", "Ready!" },
})

local Main = Window:CreateTab("Main", "Home")
local Settings = Window:CreateTab("Settings", "Settings")

Main:CreateSection("Player")
Main:CreateSlider({ Name = "Walk speed", Min = 16, Max = 100, Default = 16, Callback = function(v)
    local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end })

Main:CreateToggle({ Name = "Notify on join", Default = true, Callback = print })

Settings:CreateParagraph({ Title = "About", Content = "Built with DrizxLibrary." })
Settings:CreateDropdown({ Name = "Language", Options = { "English", "Indonesian" }, Default = "English", Callback = print })
Settings:CreateTextbox({ Name = "Nickname", Placeholder = "Type here...", Callback = function(text) print(text) end })
Settings:CreateButton({ Name = "Close UI", Callback = function() Window:Close() end })

Window:OnDestroy(function()
    print("UI removed")
end)
```

---

## Troubleshooting

### `attempt to call a nil value` on line 1

The error points at line 1 of your own script, not at the library. It means `loadstring(...)` returned `nil`, so the loader line `loadstring(game:HttpGet(url))()` ended up calling `nil`. The usual cause is that the URL did not return the library code (for example `404: Not Found`: wrong username/repo/branch/file name, the file was not pushed yet, or the repo is private). Raw GitHub links can also be cached for a few minutes after you push a change.

Use this loader to see the real reason:

```lua
local url = "https://raw.githubusercontent.com/USERNAME/REPO/main/Library.lua"

local ok, src = pcall(game.HttpGet, game, url)
if not ok then return warn("HttpGet failed:", src) end
print("fetched", #src, "characters, starts with:", string.sub(src, 1, 40))

local fn, err = loadstring(src)
if not fn then return warn("loadstring failed:", err) end

local Library = fn()
```

- Starts with `404: Not Found` or `<!DOCTYPE`: the URL is wrong or the file is not published at that path.
- Starts with `--[[` and the size looks right (around 70,000 characters): the file was fetched correctly.
- `loadstring failed: ...`: the message includes the line number of the problem inside the file.

To rule out the network completely, put `Library.lua` in your executor's workspace folder and load it locally:

```lua
local Library = loadstring(readfile("Library.lua"))()
```

---

## Changelog

### 13.6.0
- Notifications have a `Type` (`Info`, `Success`, `Warning`, `Error`) that sets the color and the default icon.
- Dropdowns support `Multi = true` (tick several options, the callback gets a list).
- New `Tab:CreateKeybind` component and a `ToggleKey` window option for PC. All keybinds share one keyboard listener.
- New preset icons: `Info`, `Warning`, `Error`.

### 13.5.0
- Visual overhaul. Cards now stand out from the background (layered colors, faint borders, subtle gradients on the window and header, accent line under the header).
- Tabs: animated accent indicator, icon and text turn to the accent color, hover highlight on PC.
- Components: switch-style toggle, slider with a draggable handle and a value pill, buttons with an arrow and a press flash, dropdown with a check mark on the selected option, textbox with an accent border while typing, color picker and paragraph restyled, section headers with a line.
- Larger text and taller rows (easier to read and tap on phones). Hover effects only appear when a mouse is present.
- Notifications slide in with an icon bubble and an accent edge.
- New themes: `Ocean`, `Emerald`, `Rose`, `Amethyst`, `Amber`. New icons: `ChevronRight`, `Check`.
- Toggles and sliders now use the theme's accent color instead of a fixed green.

### 13.4.0
- Preset icons are now vector icons drawn in code instead of Roblox asset ids. Some of the old assets failed to load on certain devices (blank icons), and a few did not match their names. Added `Eye`, `Target`, `Folder` and `ChevronDown`, and `Library:GetIcons()`.
- The dropdown arrow is drawn from shapes too (the old text arrow showed as an empty box on many phones).
- UI text is no longer auto-translated by Roblox (`AutoLocalize` option).
- Less lag on PC: sliders, color pickers and buttons no longer keep global input listeners while idle; they only listen while you are dragging.
- Invalid `Logo` values now fall back to the `Zap` icon with a warning.
- The menu shadow and the color picker map no longer use image assets (stacked translucent frames and gradients instead), so the library works without loading any asset.

### 13.3.0
- Added `Tab:CreateColorPicker` (saturation/value map + hue bar, touch friendly).
- Added `Tab:CreateLabel` and `Tab:CreateDivider`.
- Added flags and configs: `Flag` option, `Window:SaveConfig`, `LoadConfig`, `DeleteConfig`, `ListConfigs`, `GetConfig`, `ApplyConfig`, `GetFlag`, `SetFlag`, `CreateConfigTab`, and the `ConfigFolder` window option. Needs executor file functions; everything is guarded when they are missing.
- Added a soft drop shadow behind the menu (`Menu.Shadow`, `Menu.ShadowTransparency`).

### 13.2.0
- The floating button is now fully customizable: your own asset id, size, shape, colors, border, position (`FloatingButton`, `FloatingIcon`, `Window:SetFloatingButton`).
- The menu is now customizable: size, background color/image, corner radius, border, header icon (`Menu`, `Window:SetMenu`).
- Icons now also accept `rbxthumb://`, `rbxasset://` and `roblox.com/asset/?id=` links, and long asset ids are handled correctly.
- Custom images are no longer tinted with the theme text color.

### 13.1.0
- Added an animated loading screen (`Loading`, `LoadingTitle`, `LoadingDuration`, `LoadingSteps`, `AutoOpen`, `Window:FinishLoading()`).
- The close (X) button now removes the UI completely, with an animation. Added `CloseAction` and `Window:Close()`.
- Minimize and close icons are now drawn from Frames so they always render, and have hover effects.
- Added the `Danger` theme color.
- All library text, comments and messages are now in English.

### 13.0.0
- Previous release.
