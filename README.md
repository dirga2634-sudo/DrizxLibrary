# DrizxLibrary

Lightweight Roblox UI library built for touch screens (mobile) and PC.

**Version:** 13.1.0
**Creators:** absorpohonods & haibung03

## Features

- Works with both mouse and touch input
- Draggable window and draggable floating toggle button
- Animated **loading screen** (spinner, progress bar, status text)
- **Minimize** (collapse to the header) and **Close** (remove the UI completely)
- Tabs with icons, plus Section, Paragraph, Button, Toggle, Slider, Dropdown and Textbox components
- Dark / Light themes with per-color overrides
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
| `Theme` | string / table | `"Dark"` | `"Dark"`, `"Light"`, or an override table (see [Themes](#themes)). |
| `BackgroundType` | string | `"Color"` | `"Color"` or `"Image"`. |
| `BackgroundColor` | Color3 | theme `Background` | Window background color. |
| `BackgroundImage` | string / number | `""` | Image used when `BackgroundType = "Image"`. |
| `BackgroundTransparency` | number | `0` | Window background transparency. |
| `Loading` | boolean | `true` | Show the loading animation. Set to `false` to disable it. |
| `LoadingTitle` | string | `Title` | Title text on the loading card. |
| `LoadingDuration` | number | `1.8` | Loading time in seconds (minimum `0.3`). |
| `LoadingSteps` | table | `{"Loading modules...", "Preparing UI...", "Almost done..."}` | Status texts shown as the progress advances. |
| `AutoOpen` | boolean | `true` | Open the window automatically once loading finishes. |
| `CloseAction` | string | `"Destroy"` | `"Destroy"` removes the UI; `"Hide"` only hides the window. |

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
| `Icon` | string / number | `"Bell"` | Icon preset name or asset id. |

### `Window:Toggle()`

Opens the window if it is closed, or hides it if it is open.

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

### `Tab:CreateDropdown({ Name, Options, Default, Callback })`

The callback receives the selected option (as a string). Duplicate options are removed.

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

---

## Themes

`Theme` can be a preset name or a table:

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
| `Accent` | Highlights, progress, spinner |
| `Text` | Primary text |
| `SubText` | Secondary text |
| `Muted` | Section headings, placeholders |
| `Success` | Toggle "on" color |
| `Notification` | Notification and loading card background |
| `Danger` | Close button hover color |

Unknown theme names fall back to `Dark` with a warning in the output.

---

## Icons

Anywhere an icon is accepted (`Logo`, tab icons, notification icons) you can pass:

- a preset name: `Home`, `Settings`, `Chat`, `Player`, `Zap`, `Search`, `Shield`, `Code`, `Bell`, `Globe`, `Key`, `Palette`
- an asset id (number or numeric string), e.g. `10723415903`
- a full asset string, e.g. `"rbxassetid://10723415903"`

---

## Full example

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/dirga2634-sudo/DrizxLibrary/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Drizx Hub",
    SubTitle = "v1.0",
    Theme = { Base = "Dark", Accent = Color3.fromRGB(0, 200, 140) },
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

## Changelog

### 13.1.0
- Added an animated loading screen (`Loading`, `LoadingTitle`, `LoadingDuration`, `LoadingSteps`, `AutoOpen`, `Window:FinishLoading()`).
- The close (X) button now removes the UI completely, with an animation. Added `CloseAction` and `Window:Close()`.
- Minimize and close icons are now drawn from Frames so they always render, and have hover effects.
- Added the `Danger` theme color.
- All library text, comments and messages are now in English.

### 13.0.0
- Previous release.
