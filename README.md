# DrizxLibrary
DrizxUI Library v6.0

A Modern, Responsive, and Customizable UI Library for Roblox.

DrizxUI is a lightweight Roblox UI library built with Lua. It features a modern dark interface, blue accents, smooth animations, interactive components, and lifecycle management.

✨ Features

- Modern dark-themed interface with blue accents
- Responsive window sizing based on the screen viewport
- Draggable main window and floating toggle button
- Smooth open, close, and minimize animations
- Customizable window title, subtitle, logo, and background
- Image and solid-color background support
- Tab system with automatic tab switching
- Built-in notification system with animated progress bars
- Preset icons and custom Roblox asset IDs
- Interactive buttons with callback support
- Toggle switches with state callbacks
- Adjustable sliders with live value updates
- Sections and paragraphs for organizing content
- Scrollable tab navigation and content
- Safe tab destruction and window cleanup
- Connection and tween lifecycle management
- Protected callbacks to reduce runtime interruptions

📦 Installation

local DrizxUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dirga2634-sudo/DrizxLibrary/main/DrizxUI.lua"
))()

local Window = DrizxUI:CreateWindow({
	Title = "Drizx Hub Pro",
	SubTitle = "v2.5 • Open Source",
	Logo = "Zap",
	BackgroundType = "Color",
	BackgroundColor = Color3.fromRGB(13, 17, 23)
})

DrizxUI:Notify({
	Title = "work!",
	Content = "Good.",
	Duration = 4,
	Icon = "Zap"
})

local MainTab = Window:CreateTab({ Name = "Utama", Icon = "Home" })

MainTab:CreateSection("Fitur Utama")

MainTab:CreateButton("Teleport ke Spawn", function()
	print("Berteleportasi...")
end)

MainTab:CreateToggle("Auto Farm Mode", false, function(state)
	print("Auto Farm:", state)
end)

MainTab:CreateSlider("Kecepatan Jalan", 16, 250, 16, function(val)
	game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = val
end)


🚀 Quick Start

local DrizxUI = require(path.to.DrizxUI)

local Window = DrizxUI:CreateWindow({
    Title = "My Project",
    SubTitle = "Powered by DrizxUI",
    Logo = "Zap",
    BackgroundType = "Color",
    BackgroundColor = Color3.fromRGB(13, 17, 23)
})

local MainTab = Window:CreateTab({
    Name = "Home",
    Icon = "Home"
})

MainTab:CreateSection("Main Controls")

MainTab:CreateParagraph(
    "Welcome",
    "Welcome to my Roblox project."
)

MainTab:CreateButton("Click Me", function()
    Window:Notify({
        Title = "DrizxUI",
        Content = "Button clicked!",
        Duration = 3,
        Icon = "Bell"
    })
end)

MainTab:CreateToggle("Enable Feature", false, function(state)
    print("Toggle state:", state)
end)

MainTab:CreateSlider("Adjust Value", 0, 100, 50, function(value)
    print("Current value:", value)
end)

Replace "path.to.DrizxUI" with the actual location of your ModuleScript.

🧩 Available Components

Component| Description
"CreateWindow()"| Creates the main UI window
"CreateTab()"| Creates a navigation tab
"CreateSection()"| Adds a section heading
"CreateParagraph()"| Adds a title and description
"CreateButton()"| Creates a clickable button
"CreateToggle()"| Creates an interactive toggle
"CreateSlider()"| Creates an adjustable slider
"Notify()"| Displays a temporary notification
"DestroyTab()"| Removes a tab and its connections
"Destroy()"| Cleans up the window and its resources

🎨 Window Configuration

local Window = DrizxUI:CreateWindow({
    Title = "DrizxUI",
    SubTitle = "v6.0",
    Logo = "Zap",
    BackgroundType = "Color",
    BackgroundColor = Color3.fromRGB(13, 17, 23),
    BackgroundTransparency = 0
})

Set "BackgroundType" to ""Image"" and provide a valid "BackgroundImage" asset ID to use an image background.

🖼️ Icon Support

DrizxUI supports preset icon names and custom Roblox asset IDs.

Available presets:

"Home", "Settings", "Chat", "Player", "Zap", "Search", "Shield", "Code", "Bell", "Globe", "Key", "Palette"

You can also provide a numeric asset ID or a full "rbxassetid://" string.

🔔 Notifications

Window:Notify({
    Title = "Notification",
    Content = "Your settings have been updated.",
    Duration = 3,
    Icon = "Bell"
})

🧹 Cleanup

Destroy individual tabs when they are no longer needed:

Window:DestroyTab("Home")

Destroy the entire UI and clean up its managed connections and active tweens:

Window:Destroy()

📱 Compatibility

Designed for Roblox experiences using client-side Lua UI components. The interface includes viewport-based sizing and mouse/touch input handling.

Test the library in your target devices and Roblox environments before release.

👨‍💻 Credits

Creators: absorpohonods & haibung03

Library: DrizxUI
Version: 6.0
Language: Roblox Lua (Luau)

📄 License

No license has been specified in this repository. Please contact the creators for permission before redistributing or modifying the library for public release.

---

DrizxUI Library
Designed for developers. Built for customization.
