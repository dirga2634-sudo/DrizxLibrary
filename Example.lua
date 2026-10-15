-- DrizxLibrary example script (v13.3.0)
-- Shows: custom floating button + menu, tabs, every component, flags and the config tab.

-- Load the library (replace the URL with your own if you host it elsewhere)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/dirga2634-sudo/DrizxLibrary/main/Library.lua"))()
-- Local alternative: put Library.lua in your executor's workspace folder and use:
-- local Library = loadstring(readfile("Library.lua"))()

local Lighting = game:GetService("Lighting")
local camera = workspace.CurrentCamera

-- Remember the original values so they can be restored when the UI is closed
local originalFov = camera.FieldOfView
local originalClock = Lighting.ClockTime
local originalAmbient = Lighting.Ambient
local notifyOnChange = true

local Window = Library:CreateWindow({
    Title = "Drizx Hub",
    SubTitle = "example",
    Theme = { Base = "Dark", Accent = Color3.fromRGB(0, 200, 140) },
    ConfigFolder = "DrizxHub", -- where saved configs go

    -- Loading screen
    LoadingDuration = 2,
    LoadingSteps = { "Connecting...", "Loading features...", "Ready!" },

    -- Floating button: swap Icon for your own image asset id, e.g. Icon = 1234567890
    FloatingButton = {
        Icon = "Zap",
        Size = 46,
        Shape = "Circle",
        StrokeColor = Color3.fromRGB(0, 200, 140),
        StrokeThickness = 2,
    },

    -- Menu (main window)
    Menu = {
        Width = 440,
        Height = 280,
        CornerRadius = 14,
        StrokeColor = Color3.fromRGB(0, 200, 140),
        Shadow = true,
        -- BackgroundImage = 1234567890, -- optional: your own image asset id
    },
})

-- Tab 1: Visuals
local Visuals = Window:CreateTab("Visuals", "Palette")

Visuals:CreateSection("Camera")

local fovLabel = Visuals:CreateLabel("Field of view: " .. math.floor(originalFov))

Visuals:CreateSlider({
    Name = "Field of view",
    Min = 40,
    Max = 120,
    Default = math.floor(originalFov),
    Increment = 1,
    Flag = "fov", -- saved in configs
    Callback = function(value)
        camera.FieldOfView = value
        fovLabel:Set("Field of view: " .. value)
    end,
})

Visuals:CreateDivider()

Visuals:CreateSection("World")

local timePresets = {
    Morning = 8,
    Noon = 14,
    Evening = 18,
    Midnight = 0,
}

Visuals:CreateDropdown({
    Name = "Time of day",
    Options = { "Morning", "Noon", "Evening", "Midnight" },
    Default = "Noon",
    Flag = "time_of_day",
    Callback = function(option)
        Lighting.ClockTime = timePresets[option]
        if notifyOnChange then
            Window:Notify({ Title = "Time of day", Content = "Set to " .. option, Duration = 2 })
        end
    end,
})

Visuals:CreateColorPicker({
    Name = "Ambient color",
    Default = originalAmbient,
    Flag = "ambient_color",
    Callback = function(color)
        Lighting.Ambient = color
    end,
})

-- Tab 2: Settings
local Settings = Window:CreateTab("Settings", "Settings")

Settings:CreateSection("General")

Settings:CreateToggle({
    Name = "Show notifications",
    Default = true,
    Flag = "notify",
    Callback = function(state)
        notifyOnChange = state
    end,
})

Settings:CreateTextbox({
    Name = "Nickname",
    Placeholder = "Type your nickname...",
    Flag = "nickname",
    Callback = function(text, enterPressed)
        if text ~= "" then
            Window:Notify({ Title = "Saved", Content = "Hello, " .. text .. "!", Icon = "Player" })
        end
    end,
})

Settings:CreateButton({
    Name = "Test notification",
    Callback = function()
        Window:Notify({ Title = "It works", Content = "This is a notification.", Duration = 3 })
    end,
})

Settings:CreateParagraph({
    Title = "About",
    Content = "Built with DrizxLibrary. Use the Config tab to save and load every setting that has a Flag.",
})

Settings:CreateButton({
    Name = "Close UI",
    Callback = function()
        Window:Close()
    end,
})

-- Tab 3: Config (name box, saved-config list, Save / Load / Delete buttons)
Window:CreateConfigTab("Config", "Settings")

-- Restore everything when the UI is destroyed (X button, Window:Close() or Window:Destroy())
Window:OnDestroy(function()
    camera.FieldOfView = originalFov
    Lighting.ClockTime = originalClock
    Lighting.Ambient = originalAmbient
end)
