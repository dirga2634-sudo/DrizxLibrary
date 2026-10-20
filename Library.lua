--[[
    DrizxLibrary v13.6.0
    Lightweight Roblox UI library for touch screens (mobile) and PC.
    Creators: absorpohonods & haibung03

    Quick start:
        local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/dirga2634-sudo/DrizxLibrary/main/Library.lua"))()
        local Window = Library:CreateWindow({ Title = "Hub", SubTitle = "by you", Theme = "Dark" })
        local Tab = Window:CreateTab("Main", "Home")
        Tab:CreateButton({ Name = "Hello", Callback = function() Library:Notify({ Title = "Hi", Content = "Clicked!" }) end })

    Loading / window options for CreateWindow (all optional):
        Loading = true            -- show the loading animation when the window is created (false = disable)
        LoadingTitle = "Title"    -- text on the loading card (default: Title)
        LoadingDuration = 1.8     -- loading time in seconds
        LoadingSteps = { "Loading...", "Preparing...", "Done" }  -- status text for each stage
        AutoOpen = true           -- open the window automatically after loading finishes
        CloseAction = "Destroy"   -- X button: "Destroy" (remove the UI completely) or "Hide" (just hide it)

    Floating button (the round button that opens/closes the menu) - fully customizable:
        FloatingButton = {
            Icon = 123456789,                  -- any image asset id, "rbxassetid://...", or a preset name
            Size = 42,                         -- pixels (24 - 96)
            Shape = "Circle",                  -- "Circle", "Rounded" or "Square"
            CornerRadius = 8,                  -- optional, in pixels (overrides Shape)
            BackgroundColor = Color3.fromRGB(18, 22, 31),
            BackgroundTransparency = 0.15,
            StrokeColor = Color3.fromRGB(0, 255, 120),
            StrokeThickness = 1.2,
            ImageColor = Color3.new(1, 1, 1),  -- tint (custom images are not tinted by default)
            ScaleType = "Crop",                -- "Crop", "Fit" or "Stretch"
            Position = Vector2.new(15, 200),   -- start position in pixels
            Visible = true,
        }
        FloatingIcon = 123456789               -- shorthand for FloatingButton.Icon

    Menu (the main window) - fully customizable:
        Menu = {
            Width = 420, Height = 280,         -- preferred size in pixels (clamped to the screen)
            BackgroundColor = Color3.fromRGB(13, 17, 23),
            BackgroundTransparency = 0,
            BackgroundImage = 123456789,       -- image asset id shown behind the menu
            BackgroundImageTransparency = 0,
            CornerRadius = 10,
            StrokeColor = Color3.fromRGB(45, 55, 72),
            StrokeThickness = 1.2,
            Icon = 123456789,                  -- icon shown in the header
        }

    New methods: Window:Close() (remove the UI with an animation), Window:FinishLoading() (skip loading),
                 Window:SetFloatingButton(options or assetId), Window:SetMenu(options)  (change styling at runtime)

    New in 13.6.0:
        Window:Notify({ Type = "Success" | "Warning" | "Error" | "Info", ... })   -- colored notifications with matching icons
        Tab:CreateDropdown({ Multi = true, ... })    -- tick several options; the callback gets a list of names
        Tab:CreateKeybind({ Name, Default, Callback, OnChanged, Flag })   -- PC: click the box, press a key
        ToggleKey = Enum.KeyCode.RightShift          -- CreateWindow option: key that opens/closes the menu (PC)
        New preset icons: Info, Warning, Error.

    New in 13.5.0 (visual overhaul):
        Layered dark/light themes (cards stand out from the background), 5 new accent themes:
            Ocean, Emerald, Rose, Amethyst, Amber   (Theme = "Ocean")
        Tabs with an animated accent indicator, switch-style toggles, sliders with a draggable handle and a
        value pill, buttons with an arrow, dropdowns with a check mark, textboxes with a focus border,
        section headers with a line, bigger text and touch-friendly rows, hover highlights on PC,
        notifications that slide in with an icon bubble, subtle gradients on the window and header.
        New preset icons: ChevronRight, Check.

    New in 13.4.0:
        Preset icons are now vector icons drawn in code (no asset ids, nothing to fail to load):
            Home, Settings, Chat, Player, Zap, Search, Shield, Code, Bell, Globe, Key, Palette, Eye, Target, Folder, ChevronDown
        The dropdown arrow no longer shows as an empty box on phones.
        UI text is no longer auto-translated by Roblox (AutoLocalize = true brings the old behavior back).
        Idle sliders / pickers no longer keep global input listeners (less lag on PC).
        The menu shadow and the color picker map are drawn from frames/gradients, so the library needs no image assets at all.

    New in 13.3.0:
        Tab:CreateColorPicker({ Name, Default, Callback, Flag })   -- HSV picker, works with touch
        Tab:CreateDivider()  /  Tab:CreateLabel(text)
        Flag = "name" on Toggle / Slider / Dropdown / Textbox / ColorPicker -> saved in configs
        Window:SaveConfig(name) / LoadConfig(name) / ListConfigs() / DeleteConfig(name)   (needs executor file functions)
        Window:GetConfig() / ApplyConfig(table) / GetFlag(flag) / SetFlag(flag, value)
        Window:CreateConfigTab()  -- ready-made tab with name box, saved-config list, Save / Load / Delete buttons
        Menu.Shadow = true, Menu.ShadowTransparency = 0.55   -- soft drop shadow behind the menu
        ConfigFolder = "DrizxLibrary"                         -- folder used for config files

    Full documentation: see README.md
]]--

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local DrizxUI = {}
DrizxUI.__index = DrizxUI
DrizxUI.Version = "13.6.0"
DrizxUI.Windows = {}

local TOPBAR_H = 38
local TOGGLE_SIZE = 42
local DRAG_THRESHOLD = 6
local MIN_WIN_W = 220
local MIN_WIN_H = 170
local MIN_CONTENT_W = 100

-- Themes. Color tokens are used across all components.
local Themes = {
	Dark = {
		Background   = Color3.fromRGB(11, 14, 20),
		Card         = Color3.fromRGB(23, 28, 39),
		Surface      = Color3.fromRGB(16, 20, 28),
		Raised       = Color3.fromRGB(35, 42, 58),
		Stroke       = Color3.fromRGB(44, 52, 70),
		Accent       = Color3.fromRGB(0, 162, 255),
		Text         = Color3.fromRGB(240, 244, 250),
		SubText      = Color3.fromRGB(158, 172, 194),
		Muted        = Color3.fromRGB(104, 118, 140),
		Success      = Color3.fromRGB(46, 160, 67),
		Notification = Color3.fromRGB(19, 24, 34),
		Danger       = Color3.fromRGB(235, 87, 87),
	},
	Light = {
		Background   = Color3.fromRGB(233, 237, 244),
		Card         = Color3.fromRGB(255, 255, 255),
		Surface      = Color3.fromRGB(243, 246, 251),
		Raised       = Color3.fromRGB(222, 229, 240),
		Stroke       = Color3.fromRGB(205, 213, 227),
		Accent       = Color3.fromRGB(0, 120, 230),
		Text         = Color3.fromRGB(22, 28, 38),
		SubText      = Color3.fromRGB(84, 98, 120),
		Muted        = Color3.fromRGB(122, 136, 156),
		Success      = Color3.fromRGB(40, 150, 60),
		Notification = Color3.fromRGB(255, 255, 255),
		Danger       = Color3.fromRGB(220, 60, 60),
	},
}
DrizxUI.Themes = Themes

-- Accent variants of the dark theme: Theme = "Ocean", "Emerald", "Rose", "Amethyst" or "Amber"
local function darkVariant(accent)
	local theme = table.clone(Themes.Dark)
	theme.Accent = accent
	return theme
end
Themes.Ocean = darkVariant(Color3.fromRGB(0, 200, 220))
Themes.Emerald = darkVariant(Color3.fromRGB(0, 200, 140))
Themes.Rose = darkVariant(Color3.fromRGB(255, 82, 140))
Themes.Amethyst = darkVariant(Color3.fromRGB(150, 110, 255))
Themes.Amber = darkVariant(Color3.fromRGB(255, 170, 40))

-- A theme can be a name ("Dark", "Light", "Ocean", ...) or an override table,
-- for example { Base = "Light", Accent = Color3.fromRGB(255, 80, 120) }.
local function resolveTheme(input)
	local resolved = table.clone(Themes.Dark)
	local overrides = nil

	if type(input) == "string" then
		if Themes[input] then
			overrides = Themes[input]
		else
			warn("[DrizxLibrary] Theme '" .. input .. "' is unknown, using Dark.")
		end
	elseif type(input) == "table" then
		local baseName = input.Base or input.Preset
		if baseName ~= nil then
			if Themes[baseName] then
				for key, value in pairs(Themes[baseName]) do
					resolved[key] = value
				end
			else
				warn("[DrizxLibrary] Base theme '" .. tostring(baseName) .. "' is unknown, using Dark.")
			end
		end
		overrides = input
	end

	if overrides then
		for key, value in pairs(overrides) do
			if resolved[key] ~= nil and typeof(value) == "Color3" then
				resolved[key] = value
			end
		end
	end

	return resolved
end

-- Preset Icons Dictionary
-- Built-in vector icons -----------------------------------------------------------
-- Preset icons are drawn from Frames on a 16x16 grid, so they look the same on every device and do not
-- depend on any Roblox asset (assets can fail to load on some phones/regions, fonts can miss glyphs).
-- Primitives: {"l", x1, y1, x2, y2} line | {"r", cx, cy, D} ring (outer diameter)
--             {"d", cx, cy, D} filled dot | {"o", x, y, w, h, radius} outlined rounded rectangle
local ICON_GRID = 16
local ICON_STROKE = 1.7

local VectorIcons = {
	Home = {
		{"l", 2, 8.4, 8, 2.8},
		{"l", 8, 2.8, 14, 8.4},
		{"l", 3.9, 7.4, 3.9, 13.4},
		{"l", 12.1, 7.4, 12.1, 13.4},
		{"l", 3.9, 13.4, 12.1, 13.4},
		{"l", 8, 13.4, 8, 10},
	},
	Settings = {
		{"r", 8, 8, 9.4},
		{"d", 8, 8, 2.6},
		{"l", 13, 8, 15.4, 8},
		{"l", 11.54, 11.54, 13.23, 13.23},
		{"l", 8, 13, 8, 15.4},
		{"l", 4.46, 11.54, 2.77, 13.23},
		{"l", 3, 8, 0.6, 8},
		{"l", 4.46, 4.46, 2.77, 2.77},
		{"l", 8, 3, 8, 0.6},
		{"l", 11.54, 4.46, 13.23, 2.77},
	},
	Chat = {
		{"o", 2, 2.6, 12, 8.6, 3},
		{"l", 5.4, 11.2, 5.4, 13.9},
		{"l", 5.4, 13.9, 8.4, 11.2},
	},
	Player = {
		{"r", 8, 4.8, 5.6},
		{"o", 3, 9.6, 10, 5, 2.5},
	},
	Zap = {
		{"l", 9.6, 1.6, 3.4, 9},
		{"l", 3.4, 9, 7.8, 9},
		{"l", 7.8, 9, 6.4, 14.4},
		{"l", 6.4, 14.4, 12.6, 6.8},
		{"l", 12.6, 6.8, 8.2, 6.8},
		{"l", 8.2, 6.8, 9.6, 1.6},
	},
	Search = {
		{"r", 6.6, 6.6, 10.4},
		{"l", 10.6, 10.6, 14.2, 14.2},
	},
	Shield = {
		{"l", 8, 1.8, 13.4, 3.8},
		{"l", 13.4, 3.8, 13.4, 7.4},
		{"l", 13.4, 7.4, 8, 14.4},
		{"l", 8, 14.4, 2.6, 7.4},
		{"l", 2.6, 7.4, 2.6, 3.8},
		{"l", 2.6, 3.8, 8, 1.8},
	},
	Code = {
		{"l", 5.6, 3.6, 1.8, 8},
		{"l", 1.8, 8, 5.6, 12.4},
		{"l", 10.4, 3.6, 14.2, 8},
		{"l", 14.2, 8, 10.4, 12.4},
	},
	Bell = {
		{"l", 8, 2, 10.3, 2.9},
		{"l", 10.3, 2.9, 11.6, 5},
		{"l", 11.6, 5, 11.9, 8},
		{"l", 11.9, 8, 13.6, 10.6},
		{"l", 13.6, 10.6, 2.4, 10.6},
		{"l", 2.4, 10.6, 4.1, 8},
		{"l", 4.1, 8, 4.4, 5},
		{"l", 4.4, 5, 5.7, 2.9},
		{"l", 5.7, 2.9, 8, 2},
		{"d", 8, 13.3, 2.4},
	},
	Globe = {
		{"r", 8, 8, 13.2},
		{"o", 5.2, 1.4, 5.6, 13.2, 2.8},
		{"l", 2, 8, 14, 8},
	},
	Key = {
		{"r", 4.8, 11.2, 6.4},
		{"l", 7.4, 8.6, 14, 2},
		{"l", 11.4, 4.6, 13.2, 6.4},
		{"l", 9.2, 6.8, 10.6, 8.2},
	},
	Palette = {
		{"r", 8, 8, 13.4},
		{"d", 5.2, 6.4, 1.9},
		{"d", 8.4, 4.6, 1.9},
		{"d", 11.2, 7, 1.9},
		{"d", 5.8, 10.6, 1.9},
	},
	Eye = {
		{"l", 1.6, 8, 4.6, 5},
		{"l", 4.6, 5, 8, 3.8},
		{"l", 8, 3.8, 11.4, 5},
		{"l", 11.4, 5, 14.4, 8},
		{"l", 14.4, 8, 11.4, 11},
		{"l", 11.4, 11, 8, 12.2},
		{"l", 8, 12.2, 4.6, 11},
		{"l", 4.6, 11, 1.6, 8},
		{"d", 8, 8, 3.6},
	},
	Target = {
		{"r", 8, 8, 11.4},
		{"d", 8, 8, 2.6},
		{"l", 8, 1.2, 8, 3.8},
		{"l", 8, 12.2, 8, 14.8},
		{"l", 1.2, 8, 3.8, 8},
		{"l", 12.2, 8, 14.8, 8},
	},
	Folder = {
		{"o", 1.6, 5.2, 12.8, 8.8, 2},
		{"l", 2.6, 4.4, 6.4, 4.4},
	},
	ChevronDown = {
		{"l", 3.6, 6, 8, 10.4},
		{"l", 8, 10.4, 12.4, 6},
	},
	ChevronRight = {
		{"l", 6, 3.6, 10.4, 8},
		{"l", 10.4, 8, 6, 12.4},
	},
	Check = {
		{"l", 2.6, 8.6, 6.4, 12.2},
		{"l", 6.4, 12.2, 13.4, 4.4},
	},
	Info = {
		{"r", 8, 8, 13.4},
		{"l", 8, 7.2, 8, 11},
		{"d", 8, 4.9, 1.9},
	},
	Warning = {
		{"l", 8, 2.2, 14.4, 13.4},
		{"l", 14.4, 13.4, 1.6, 13.4},
		{"l", 1.6, 13.4, 8, 2.2},
		{"l", 8, 6.6, 8, 9.4},
		{"d", 8, 11.5, 1.7},
	},
	Error = {
		{"r", 8, 8, 13.4},
		{"l", 5.6, 5.6, 10.4, 10.4},
		{"l", 10.4, 5.6, 5.6, 10.4},
	},
}

-- Case-insensitive lookup: "home", "Home" and "HOME" all work. Returns the canonical name or nil.
local function vectorIconName(input)
	if input == nil then return nil end
	local text = tostring(input)
	if VectorIcons[text] then return text end
	local lower = string.lower(text)
	for name in pairs(VectorIcons) do
		if string.lower(name) == lower then return name end
	end
	return nil
end

-- Accepts an asset id (number or numeric string), "rbxassetid://123", "rbxthumb://...", "rbxasset://...",
-- or a roblox.com/asset/?id=123 link. Returns "" when the input is not a recognized image.
local function parseIcon(iconInput)
	if iconInput == nil or iconInput == "" then return "" end
	if type(iconInput) == "number" then
		return "rbxassetid://" .. string.format("%.0f", iconInput)
	end

	local text = tostring(iconInput)
	text = (string.gsub(text, "^%s+", ""))
	text = (string.gsub(text, "%s+$", ""))

	if string.match(text, "^%d+$") then return "rbxassetid://" .. text end
	if string.find(text, "^rbxassetid://") or string.find(text, "^rbxthumb://") or string.find(text, "^rbxasset://") then
		return text
	end
	if string.find(text, "roblox.com", 1, true) then
		local id = string.match(text, "[?&]id=(%d+)")
		if id then return "rbxassetid://" .. id end
	end
	return ""
end

-- Preset (vector) icons are tinted with the theme text color; custom images are shown as they are.
local function isPresetIcon(iconInput)
	return vectorIconName(iconInput) ~= nil
end

local function newCorner(parent, scale)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(scale, 0)
	corner.Parent = parent
	return corner
end

local function buildVectorIcon(host, name, color, fill)
	local container = Instance.new("Frame")
	container.Name = "VectorIcon"
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.fromScale(0.5, 0.5)
	container.Size = UDim2.fromScale(fill, fill)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0

	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1
	ratio.Parent = container

	local strokes = {}

	for _, prim in ipairs(VectorIcons[name]) do
		local kind = prim[1]
		if kind == "l" then
			local x1, y1, x2, y2 = prim[2], prim[3], prim[4], prim[5]
			local dx, dy = x2 - x1, y2 - y1
			local len = math.sqrt(dx * dx + dy * dy)
			local line = Instance.new("Frame")
			line.AnchorPoint = Vector2.new(0.5, 0.5)
			line.Position = UDim2.fromScale((x1 + x2) / 2 / ICON_GRID, (y1 + y2) / 2 / ICON_GRID)
			-- the line is lengthened by one stroke so its rounded ends overlap neatly at the joints
			line.Size = UDim2.fromScale((len + ICON_STROKE) / ICON_GRID, ICON_STROKE / ICON_GRID)
			line.Rotation = math.deg(math.atan2(dy, dx))
			line.BackgroundColor3 = color
			line.BorderSizePixel = 0
			line.Parent = container
			newCorner(line, 1)
		elseif kind == "d" then
			local D = prim[4] / ICON_GRID
			local dot = Instance.new("Frame")
			dot.AnchorPoint = Vector2.new(0.5, 0.5)
			dot.Position = UDim2.fromScale(prim[2] / ICON_GRID, prim[3] / ICON_GRID)
			dot.Size = UDim2.fromScale(D, D)
			dot.BackgroundColor3 = color
			dot.BorderSizePixel = 0
			dot.Parent = container
			newCorner(dot, 1)
		elseif kind == "r" or kind == "o" then
			-- Outlines are Frames with a UIStroke; the stroke grows outward, so the Frame is the inner size.
			local cx, cy, w, h, radius
			if kind == "r" then
				cx, cy, w, h, radius = prim[2], prim[3], prim[4], prim[4], prim[4] / 2
			else
				cx, cy, w, h, radius = prim[2] + prim[4] / 2, prim[3] + prim[5] / 2, prim[4], prim[5], prim[6]
			end
			local innerW = math.max(0.5, w - 2 * ICON_STROKE)
			local innerH = math.max(0.5, h - 2 * ICON_STROKE)
			local box = Instance.new("Frame")
			box.AnchorPoint = Vector2.new(0.5, 0.5)
			box.Position = UDim2.fromScale(cx / ICON_GRID, cy / ICON_GRID)
			box.Size = UDim2.fromScale(innerW / ICON_GRID, innerH / ICON_GRID)
			box.BackgroundTransparency = 1
			box.BorderSizePixel = 0
			box.Parent = container
			newCorner(box, math.clamp(math.max(0, radius - ICON_STROKE) / math.min(innerW, innerH), 0, 0.5))

			local stroke = Instance.new("UIStroke")
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Color = color
			stroke.Thickness = 1
			stroke.Parent = box
			table.insert(strokes, stroke)
		end
	end

	-- UIStroke thickness is in pixels, so it follows the icon's on-screen size
	local function updateStrokes()
		local size = container.AbsoluteSize.X
		if size <= 0 then return end
		local thickness = math.max(1, math.floor(size * ICON_STROKE / ICON_GRID * 2 + 0.5) / 2)
		for _, stroke in ipairs(strokes) do
			stroke.Thickness = thickness
		end
	end
	container:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateStrokes)
	updateStrokes()

	container.Parent = host
	return container
end

-- Puts an icon on an ImageLabel / ImageButton. Preset names are drawn as vector icons, anything else is
-- treated as an image asset. `fill` (0-1) is how much of the host a vector icon covers.
-- Returns false when the icon could not be understood.
local function applyIcon(host, input, color, fill)
	local name = vectorIconName(input)
	if name then
		local old = host:FindFirstChild("VectorIcon")
		if old then old:Destroy() end
		host.Image = ""
		buildVectorIcon(host, name, color, fill or 1)
		return true
	end
	local image = parseIcon(input)
	if image == "" then return false end
	local old = host:FindFirstChild("VectorIcon")
	if old then old:Destroy() end
	host.Image = image
	host.ImageColor3 = color
	return true
end

-- Names of the built-in preset icons (sorted).
function DrizxUI:GetIcons()
	local names = {}
	for name in pairs(VectorIcons) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

-- Recolors an icon placed with applyIcon (image tint or vector parts).
local function setIconColor(host, color)
	host.ImageColor3 = color
	local container = host:FindFirstChild("VectorIcon")
	if container then
		for _, part in ipairs(container:GetDescendants()) do
			if part:IsA("UIStroke") then
				part.Color = color
			elseif part:IsA("Frame") and part.BackgroundTransparency < 1 then
				part.BackgroundColor3 = color
			end
		end
	end
end


local function escapeRichText(text)
	local s = tostring(text)
	s = string.gsub(s, "&", "&amp;")
	s = string.gsub(s, "<", "&lt;")
	s = string.gsub(s, ">", "&gt;")
	s = string.gsub(s, '"', "&quot;")
	s = string.gsub(s, "'", "&apos;")
	return s
end

local function safeCall(label, fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[DrizxLibrary] Error in callback " .. label .. ": " .. tostring(err))
	end
end

-- Color helpers (color picker + config files)
local function colorToHex(color)
	return string.format("#%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5))
end

-- Accepts a Color3, "#RRGGBB" / "RRGGBB", or { R, G, B } (0-255). Returns nil if it can't be understood.
local function parseColor(value)
	if typeof(value) == "Color3" then
		return value
	end
	if type(value) == "string" then
		local hex = string.match(value, "^#?(%x%x%x%x%x%x)$")
		if hex then
			return Color3.fromRGB(
				tonumber(string.sub(hex, 1, 2), 16),
				tonumber(string.sub(hex, 3, 4), 16),
				tonumber(string.sub(hex, 5, 6), 16))
		end
	elseif type(value) == "table" then
		local r = tonumber(value.R or value[1])
		local g = tonumber(value.G or value[2])
		local b = tonumber(value.B or value[3])
		if r and g and b then
			return Color3.fromRGB(math.clamp(r, 0, 255), math.clamp(g, 0, 255), math.clamp(b, 0, 255))
		end
	end
	return nil
end

-- Accepts an Enum.KeyCode or its name ("F", "RightShift"). Returns nil if it can't be understood.
local function parseKeyCode(value)
	if typeof(value) == "EnumItem" then
		if value.EnumType == Enum.KeyCode then return value end
		return nil
	end
	if type(value) == "string" then
		local ok, key = pcall(function() return Enum.KeyCode[value] end)
		if ok and key then return key end
	end
	return nil
end

local function computeSidebarWidth(w)
	local sw = math.clamp(math.floor(w * 0.28), 80, 110)
	-- The sidebar yields if the content area would drop below MIN_CONTENT_W
	return math.min(sw, math.max(48, w - 18 - MIN_CONTENT_W))
end

-- prefW / prefH are optional custom sizes (Menu.Width / Menu.Height); they are always
-- clamped so the window never gets smaller than the minimum or larger than the screen.
local function computeWindowSize(vp, prefW, prefH)
	local minW = math.min(MIN_WIN_W, vp.X)
	local minH = math.min(MIN_WIN_H, vp.Y)
	local w, h
	if prefW then
		w = math.clamp(prefW, minW, math.max(minW, vp.X - 10))
	else
		w = math.clamp(vp.X - 20, minW, 480)
	end
	if prefH then
		h = math.clamp(prefH, minH, math.max(minH, vp.Y - 20))
	else
		h = math.clamp(vp.Y - 40, minH, 300)
	end
	return w, h
end

-- Universal drag helper (mouse + touch). Returns a list of connections;
-- the .cancel field holds a function that cancels the drag in progress.
-- onEnd(cancelled): cancelled = true when the drag was force-cancelled (not released by the user).
local function bindDrag(target, onBegin, onMove, onEnd)
	local active = nil
	local moveConn = nil
	local endConn = nil
	local connections = {}

	local function release()
		if moveConn then
			moveConn:Disconnect()
			moveConn = nil
		end
		if endConn then
			endConn:Disconnect()
			endConn = nil
		end
	end

	local function finish(cancelled)
		if not active then return end
		active = nil
		release()
		if onEnd then onEnd(cancelled) end
	end

	table.insert(connections, target.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end

		if active then
			-- The "release" event can be missed (e.g. the mouse is released outside the window).
			-- If the previous drag is already finished, clean it up first, then start a new one.
			local st = active.UserInputState
			if input == active or st == Enum.UserInputState.End or st == Enum.UserInputState.Cancel then
				finish(true)
			else
				return
			end
		end

		active = input

		-- The global input listeners only exist while a drag is in progress. Idle sliders, color pickers and
		-- buttons cost nothing (a permanent InputChanged listener runs on every mouse move, which adds up on PC).
		moveConn = UserInputService.InputChanged:Connect(function(changed)
			if not active then return end
			local isMouseMove = active.UserInputType == Enum.UserInputType.MouseButton1
				and changed.UserInputType == Enum.UserInputType.MouseMovement
			local isTouchMove = active.UserInputType == Enum.UserInputType.Touch
				and changed == active
			if isMouseMove or isTouchMove then
				onMove(changed)
			end
		end)

		endConn = UserInputService.InputEnded:Connect(function(ended)
			if not active then return end
			local isSame = ended == active
			local isMouseUp = active.UserInputType == Enum.UserInputType.MouseButton1
				and ended.UserInputType == Enum.UserInputType.MouseButton1
			if isSame or isMouseUp then
				finish(false)
			end
		end)

		onBegin(input)
	end))

	connections.cancel = function() finish(true) end
	return connections
end

-- Library-level helper: operates on the most recently created window.
function DrizxUI:Notify(notifConfig)
	local win = self.Windows[#self.Windows]
	if not win then
		warn("[DrizxLibrary] Notify was called before any window exists. Create a window first with CreateWindow.")
		return
	end
	win:Notify(notifConfig)
end

function DrizxUI:Destroy()
	local list = table.clone(self.Windows)
	self.Windows = {}
	for _, win in ipairs(list) do
		win:Destroy()
	end
end

function DrizxUI:CreateWindow(config)
	config = config or {}
	local Theme = resolveTheme(config.Theme)
	local titleText  = tostring(config.Title or "DrizxLibrary")
	local subTitle   = tostring(config.SubTitle or ("v" .. DrizxUI.Version))
	local logoInput  = config.Logo or "Zap"
	if not isPresetIcon(logoInput) and parseIcon(logoInput) == "" then
		warn("[DrizxLibrary] Logo is not a valid preset name or asset id: " .. tostring(logoInput) .. " (using Zap).")
		logoInput = "Zap"
	end

	local function iconTint(input)
		return isPresetIcon(input) and Theme.Text or Color3.new(1, 1, 1)
	end

	-- Floating button options: FloatingButton = { ... } or FloatingButton = assetId, plus the FloatingIcon shorthand.
	local floatCfg = config.FloatingButton
	if type(floatCfg) ~= "table" then
		floatCfg = { Icon = floatCfg or config.FloatingIcon }
	elseif floatCfg.Icon == nil and config.FloatingIcon ~= nil then
		floatCfg = table.clone(floatCfg)
		floatCfg.Icon = config.FloatingIcon
	end

	-- Menu (main window) options. The old top-level Background* options still work.
	local menuCfg = type(config.Menu) == "table" and config.Menu or {}
	local legacyImage = (config.BackgroundType == "Image") and config.BackgroundImage or nil
	local menuInit = {
		Width = menuCfg.Width,
		Height = menuCfg.Height,
		BackgroundColor = menuCfg.BackgroundColor or config.BackgroundColor,
		BackgroundTransparency = menuCfg.BackgroundTransparency or config.BackgroundTransparency,
		BackgroundImage = menuCfg.BackgroundImage or legacyImage,
		BackgroundImageTransparency = menuCfg.BackgroundImageTransparency,
		CornerRadius = menuCfg.CornerRadius,
		StrokeColor = menuCfg.StrokeColor,
		StrokeThickness = menuCfg.StrokeThickness,
		Icon = menuCfg.Icon,
		Shadow = menuCfg.Shadow,
		ShadowTransparency = menuCfg.ShadowTransparency,
	}
	local menuPrefW = tonumber(menuInit.Width)
	local menuPrefH = tonumber(menuInit.Height)

	local Window = {
		CurrentTab = nil,
		Minimized = false,
		Tabs = {},
		Flags = {},
		Connections = {},
		ActiveTweens = {},
		ActiveNotifications = {},
		DestroyCallbacks = {},
		IsAnimating = false,
		IsDestroyed = false
	}

	local dragCancels = {} -- set: [cancel function] = true

	local function registerDrag(cancel)
		dragCancels[cancel] = true
	end

	local function cancelAllDrags()
		for cancel in pairs(dragCancels) do
			pcall(cancel)
		end
	end

	local function trackAll(list)
		for _, conn in ipairs(list) do
			table.insert(Window.Connections, conn)
		end
		if list.cancel then
			registerDrag(list.cancel)
		end
	end

	-- Tracked tween: automatically cancelled by Destroy(); callbacks do not run after destroy.
	local function playTween(instance, info, goal, onDone)
		if Window.IsDestroyed then return nil end
		local tw = TweenService:Create(instance, info, goal)
		table.insert(Window.ActiveTweens, tw)
		tw.Completed:Connect(function(state)
			local idx = table.find(Window.ActiveTweens, tw)
			if idx then table.remove(Window.ActiveTweens, idx) end
			if onDone and not Window.IsDestroyed then
				onDone(state)
			end
		end)
		tw:Play()
		return tw
	end

	table.insert(DrizxUI.Windows, Window)

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DrizxLibrary_" .. tostring(math.random(10000, 99999))
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Roblox automatically translates UI text for players whose language is not English
	-- (for example "Settings" becomes "Pengaturan"). Keep the text exactly as written, unless AutoLocalize = true.
	if config.AutoLocalize ~= true then
		screenGui.AutoLocalize = false
		table.insert(Window.Connections, screenGui.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
				descendant.AutoLocalize = false
			end
		end))
	end
	screenGui.Parent = PlayerGui

	-- If the ScreenGui is removed from outside (e.g. by another script), clean up all connections too.
	local destroyedExternally = false
	table.insert(Window.Connections, screenGui.Destroying:Connect(function()
		destroyedExternally = true
		Window:Destroy()
	end))

	local function getViewport()
		local cam = Workspace.CurrentCamera
		if cam then
			return cam.ViewportSize
		end
		return Vector2.new(1024, 768)
	end

	local initialVp = getViewport()
	local winWidth, winHeight = computeWindowSize(initialVp, menuPrefW, menuPrefH)
	local sidebarWidth = computeSidebarWidth(winWidth)

	local isOpen = false
	local applyLayout
	local toggleWindow

	local function clampWindowPos(x, y)
		local vp = getViewport()
		local curH = (isOpen and not Window.Minimized) and winHeight or TOPBAR_H
		return math.clamp(x, 0, math.max(0, vp.X - winWidth)),
			math.clamp(y, 0, math.max(0, vp.Y - curH))
	end

	-- Notification container (size/position handled by applyLayout)
	local notifContainer = Instance.new("Frame")
	notifContainer.Name = "DrizxNotifContainer"
	notifContainer.Size = UDim2.new(0, 220, 1, -20)
	notifContainer.Position = UDim2.new(1, -230, 0, 10)
	notifContainer.BackgroundTransparency = 1
	notifContainer.ZIndex = 1000
	notifContainer.Parent = screenGui

	local notifLayout = Instance.new("UIListLayout")
	notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
	notifLayout.Padding = UDim.new(0, 8)
	notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	notifLayout.Parent = notifContainer

	function Window:Notify(notifConfig)
		if Window.IsDestroyed then return end
		notifConfig = notifConfig or {}
		local title = tostring(notifConfig.Title or "Notification")
		local content = tostring(notifConfig.Content or "")
		local duration = math.max(0.5, tonumber(notifConfig.Duration) or 3)
		-- Type changes the color and the default icon: "Info" (default), "Success", "Warning" or "Error"
		local kind = string.lower(tostring(notifConfig.Type or "info"))
		local tone = Theme.Accent
		local defaultIcon = "Bell"
		if kind == "success" then
			tone = Theme.Success
			defaultIcon = "Check"
		elseif kind == "warning" then
			tone = Color3.fromRGB(255, 170, 40)
			defaultIcon = "Warning"
		elseif kind == "error" then
			tone = Theme.Danger
			defaultIcon = "Error"
		end
		local iconInput = notifConfig.Icon or defaultIcon
		local NOTIF_H = 62

		-- The card starts with zero height and grows in, pushing older notifications up smoothly.
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 0)
		card.BackgroundColor3 = Theme.Notification
		card.BorderSizePixel = 0
		card.ClipsDescendants = true
		card.ZIndex = 1001
		card.Parent = notifContainer

		table.insert(Window.ActiveNotifications, card)

		local cCorner = Instance.new("UICorner")
		cCorner.CornerRadius = UDim.new(0, 10)
		cCorner.Parent = card

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = Theme.Stroke
		cStroke.Thickness = 1
		cStroke.Parent = card

		local accentBar = Instance.new("Frame")
		accentBar.Size = UDim2.new(0, 3, 1, 0)
		accentBar.BackgroundColor3 = tone
		accentBar.BorderSizePixel = 0
		accentBar.ZIndex = 1002
		accentBar.Parent = card

		-- Icon in a soft accent-colored bubble
		local bubble = Instance.new("Frame")
		bubble.Size = UDim2.new(0, 30, 0, 30)
		bubble.Position = UDim2.new(0, 14, 0, (NOTIF_H - 30) / 2)
		bubble.BackgroundColor3 = tone
		bubble.BackgroundTransparency = 0.85
		bubble.BorderSizePixel = 0
		bubble.ZIndex = 1002
		bubble.Parent = card

		local bubbleCorner = Instance.new("UICorner")
		bubbleCorner.CornerRadius = UDim.new(1, 0)
		bubbleCorner.Parent = bubble

		local iconImg = Instance.new("ImageLabel")
		iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
		iconImg.Size = UDim2.new(0, 16, 0, 16)
		iconImg.Position = UDim2.new(0.5, 0, 0.5, 0)
		iconImg.BackgroundTransparency = 1
		if not applyIcon(iconImg, iconInput, tone, 1) then
			applyIcon(iconImg, defaultIcon, tone, 1)
		end
		iconImg.ZIndex = 1003
		iconImg.Parent = bubble

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(1, -62, 0, 18)
		titleLbl.Position = UDim2.new(0, 54, 0, 9)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = title
		titleLbl.TextColor3 = Theme.Text
		titleLbl.TextSize = 12
		titleLbl.Font = Enum.Font.GothamBold
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
		titleLbl.ZIndex = 1002
		titleLbl.Parent = card

		local contentLbl = Instance.new("TextLabel")
		contentLbl.Size = UDim2.new(1, -62, 0, 26)
		contentLbl.Position = UDim2.new(0, 54, 0, 27)
		contentLbl.BackgroundTransparency = 1
		contentLbl.Text = content
		contentLbl.TextColor3 = Theme.SubText
		contentLbl.TextSize = 11
		contentLbl.Font = Enum.Font.GothamMedium
		contentLbl.TextXAlignment = Enum.TextXAlignment.Left
		contentLbl.TextYAlignment = Enum.TextYAlignment.Top
		contentLbl.TextWrapped = true
		contentLbl.TextTruncate = Enum.TextTruncate.AtEnd
		contentLbl.ZIndex = 1002
		contentLbl.Parent = card

		local pBar = Instance.new("Frame")
		pBar.Size = UDim2.new(1, 0, 0, 2)
		pBar.Position = UDim2.new(0, 0, 1, -2)
		pBar.BackgroundColor3 = tone
		pBar.BorderSizePixel = 0
		pBar.ZIndex = 1003
		pBar.Parent = card

		playTween(card, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, NOTIF_H)})

		-- Tween chain: progress -> fade -> remove. No threads are left waiting.
		playTween(pBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}, function(state)
			if state ~= Enum.PlaybackState.Completed then return end
			local fadeInfo = TweenInfo.new(0.22)
			iconImg.Visible = false
			playTween(bubble, fadeInfo, {BackgroundTransparency = 1})
			playTween(accentBar, fadeInfo, {BackgroundTransparency = 1})
			playTween(titleLbl, fadeInfo, {TextTransparency = 1})
			playTween(contentLbl, fadeInfo, {TextTransparency = 1})
			playTween(pBar, fadeInfo, {BackgroundTransparency = 1})
			playTween(cStroke, fadeInfo, {Transparency = 1})
			playTween(card, fadeInfo, {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)}, function()
				local idx = table.find(Window.ActiveNotifications, card)
				if idx then table.remove(Window.ActiveNotifications, idx) end
				if card.Parent then card:Destroy() end
			end)
		end)
	end

	-- Floating Toggle Button (drag + tap). Look is customizable via FloatingButton / Window:SetFloatingButton.
	local toggleSize = TOGGLE_SIZE
	local floatVisible = true
	local floatLoadingHidden = false
	local floatShape = "circle"
	local floatCorner = nil
	local toggleBtn = Instance.new("ImageButton")
	toggleBtn.Name = "DrizxToggleBtn"
	toggleBtn.Size = UDim2.new(0, toggleSize, 0, toggleSize)
	toggleBtn.Position = UDim2.fromOffset(15, math.floor(initialVp.Y / 2 - toggleSize / 2))
	applyIcon(toggleBtn, logoInput, iconTint(logoInput), 0.58)
	toggleBtn.ScaleType = Enum.ScaleType.Crop
	toggleBtn.AutoButtonColor = false
	toggleBtn.BackgroundTransparency = 0.15
	toggleBtn.BackgroundColor3 = Theme.Surface
	toggleBtn.Active = true
	toggleBtn.ZIndex = 200
	toggleBtn.Parent = screenGui

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(1, 0)
	toggleCorner.Parent = toggleBtn

	local toggleStroke = Instance.new("UIStroke")
	toggleStroke.Color = Theme.Accent
	toggleStroke.Thickness = 1.2
	toggleStroke.Parent = toggleBtn

	local toggleMoved = false
	local toggleStartInput = Vector2.zero
	local toggleStartPos = Vector2.zero

	trackAll(bindDrag(toggleBtn,
		function(input)
			toggleMoved = false
			toggleStartInput = Vector2.new(input.Position.X, input.Position.Y)
			toggleStartPos = Vector2.new(toggleBtn.Position.X.Offset, toggleBtn.Position.Y.Offset)
		end,
		function(input)
			local delta = Vector2.new(input.Position.X, input.Position.Y) - toggleStartInput
			if delta.Magnitude > DRAG_THRESHOLD then
				toggleMoved = true
			end
			local vp = getViewport()
			local newX = math.clamp(toggleStartPos.X + delta.X, 0, math.max(0, vp.X - toggleSize))
			local newY = math.clamp(toggleStartPos.Y + delta.Y, 0, math.max(0, vp.Y - toggleSize))
			toggleBtn.Position = UDim2.fromOffset(newX, newY)
		end,
		function(cancelled)
			if not cancelled and not toggleMoved and toggleWindow then
				toggleWindow()
			end
		end
	))

	-- Main Window Frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, winWidth, 0, winHeight)
	mainFrame.Position = UDim2.fromOffset(
		math.floor((initialVp.X - winWidth) / 2),
		math.floor((initialVp.Y - winHeight) / 2)
	)
	mainFrame.BackgroundColor3 = Theme.Background
	mainFrame.BackgroundTransparency = 0
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.Visible = false
	mainFrame.Parent = screenGui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 10)
	mainCorner.Parent = mainFrame

	local mainStroke = Instance.new("UIStroke")
	mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	mainStroke.Color = Theme.Stroke
	mainStroke.Thickness = 1.2
	mainStroke.Parent = mainFrame

	-- Subtle top-to-bottom shading (it multiplies the background color, so it works with any theme or color)
	local mainGradient = Instance.new("UIGradient")
	mainGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(222, 222, 222))
	mainGradient.Rotation = 90
	mainGradient.Parent = mainFrame

	-- Soft drop shadow behind the menu, built from a few stacked translucent rounded frames (no image asset,
	-- so it looks the same everywhere). It is a sibling of mainFrame (mainFrame clips its children) and
	-- follows the menu's position, size and visibility.
	local SHADOW_LAYERS = 5
	local SHADOW_STEP = 5
	local shadowEnabled = true
	local shadowTransparency = 0.55
	local shadowLayers = {}

	local shadowHolder = Instance.new("Frame")
	shadowHolder.Name = "MenuShadow"
	shadowHolder.Size = UDim2.fromScale(1, 1)
	shadowHolder.BackgroundTransparency = 1
	shadowHolder.BorderSizePixel = 0
	shadowHolder.ZIndex = 0
	shadowHolder.Visible = false
	shadowHolder.Parent = screenGui

	for i = 1, SHADOW_LAYERS do
		local layer = Instance.new("Frame")
		layer.BackgroundColor3 = Color3.new(0, 0, 0)
		layer.BorderSizePixel = 0
		layer.Parent = shadowHolder
		local layerCorner = Instance.new("UICorner")
		layerCorner.Parent = layer
		shadowLayers[i] = { frame = layer, corner = layerCorner }
	end

	local function syncShadow()
		if Window.IsDestroyed then return end
		shadowHolder.Visible = shadowEnabled and mainFrame.Visible
		if not shadowHolder.Visible then return end
		local pos = mainFrame.AbsolutePosition
		local size = mainFrame.AbsoluteSize
		local radius = mainCorner.CornerRadius.Offset
		local layerTransparency = 1 - (1 - shadowTransparency) / SHADOW_LAYERS
		for i, layer in ipairs(shadowLayers) do
			local grow = i * SHADOW_STEP
			layer.frame.Position = UDim2.fromOffset(pos.X - grow, pos.Y - grow + 4)
			layer.frame.Size = UDim2.fromOffset(size.X + grow * 2, size.Y + grow * 2)
			layer.frame.BackgroundTransparency = layerTransparency
			layer.corner.CornerRadius = UDim.new(0, radius + grow)
		end
	end
	table.insert(Window.Connections, mainFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(syncShadow))
	table.insert(Window.Connections, mainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncShadow))
	table.insert(Window.Connections, mainFrame:GetPropertyChangedSignal("Visible"):Connect(syncShadow))

	-- Background image: always created, shown only when Menu.BackgroundImage is set.
	local bgImg = Instance.new("ImageLabel")
	bgImg.Name = "MenuBackgroundImage"
	bgImg.Size = UDim2.new(1, 0, 1, 0)
	bgImg.BackgroundTransparency = 1
	bgImg.Image = ""
	bgImg.ScaleType = Enum.ScaleType.Crop
	bgImg.Visible = false
	bgImg.ZIndex = 0
	bgImg.Parent = mainFrame

	-- TopBar header (window drag handle)
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, TOPBAR_H)
	topBar.BackgroundColor3 = Theme.Surface
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 2
	topBar.Parent = mainFrame

	local topCorner = Instance.new("UICorner")
	topCorner.CornerRadius = UDim.new(0, 10)
	topCorner.Parent = topBar

	local topGradient = Instance.new("UIGradient")
	topGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(226, 226, 226))
	topGradient.Rotation = 90
	topGradient.Parent = topBar

	-- Accent line under the header that fades out to the right
	local topLine = Instance.new("Frame")
	topLine.Name = "AccentLine"
	topLine.Position = UDim2.new(0, 10, 1, -1)
	topLine.Size = UDim2.new(1, -20, 0, 1)
	topLine.BackgroundColor3 = Theme.Accent
	topLine.BorderSizePixel = 0
	topLine.ZIndex = 3
	topLine.Parent = topBar

	local topLineGradient = Instance.new("UIGradient")
	topLineGradient.Transparency = NumberSequence.new(0.1, 1)
	topLineGradient.Parent = topLine

	local windowDragStart = Vector2.zero
	local windowStartPos = Vector2.zero

	-- The drag area covers only the left side of the header, so the minimize/close buttons don't trigger a drag.
	local dragHandle = Instance.new("Frame")
	dragHandle.Name = "DragHandle"
	dragHandle.Size = UDim2.new(1, -70, 1, 0)
	dragHandle.BackgroundTransparency = 1
	dragHandle.Active = true
	dragHandle.ZIndex = 2
	dragHandle.Parent = topBar

	trackAll(bindDrag(dragHandle,
		function(input)
			windowDragStart = Vector2.new(input.Position.X, input.Position.Y)
			windowStartPos = Vector2.new(mainFrame.Position.X.Offset, mainFrame.Position.Y.Offset)
		end,
		function(input)
			local delta = Vector2.new(input.Position.X, input.Position.Y) - windowDragStart
			local x, y = clampWindowPos(windowStartPos.X + delta.X, windowStartPos.Y + delta.Y)
			mainFrame.Position = UDim2.fromOffset(x, y)
		end
	))

	local headerIcon = Instance.new("ImageLabel")
	headerIcon.Size = UDim2.new(0, 18, 0, 18)
	headerIcon.Position = UDim2.new(0, 10, 0.5, -9)
	headerIcon.BackgroundTransparency = 1
	applyIcon(headerIcon, logoInput, iconTint(logoInput), 1)
	headerIcon.ZIndex = 3
	headerIcon.Parent = topBar

	local headerTitle = Instance.new("TextLabel")
	headerTitle.Size = UDim2.new(1, -108, 1, 0)
	headerTitle.Position = UDim2.new(0, 34, 0, 0)
	headerTitle.BackgroundTransparency = 1
	headerTitle.RichText = true
	headerTitle.Text = escapeRichText(titleText) .. " <font color=\"" .. colorToHex(Theme.Muted) .. "\">| " .. escapeRichText(subTitle) .. "</font>"
	headerTitle.TextColor3 = Theme.Text
	headerTitle.TextSize = 12
	headerTitle.Font = Enum.Font.GothamBold
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.TextTruncate = Enum.TextTruncate.AtEnd
	headerTitle.ZIndex = 3
	headerTitle.Parent = topBar

	-- Button icons are drawn from Frames (not the dash / cross characters), because those glyphs
	-- often fail to render in the Gotham font, leaving the buttons looking empty/missing.
	local function makeHeaderButton(offsetX)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 24, 0, 24)
		btn.Position = UDim2.new(1, offsetX, 0.5, -12)
		btn.BackgroundColor3 = Theme.Raised
		btn.BackgroundTransparency = 0.4
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.ZIndex = 3
		btn.Parent = topBar

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = btn
		return btn
	end

	local function makeIconBar(parent, width, rotation)
		local bar = Instance.new("Frame")
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Position = UDim2.fromScale(0.5, 0.5)
		bar.Size = UDim2.fromOffset(width, 2)
		bar.Rotation = rotation
		bar.BackgroundColor3 = Theme.SubText
		bar.BorderSizePixel = 0
		bar.ZIndex = 4
		bar.Parent = parent

		local barCorner = Instance.new("UICorner")
		barCorner.CornerRadius = UDim.new(1, 0)
		barCorner.Parent = bar
		return bar
	end

	-- Hover/press effect: the button changes color and the icon turns white.
	local function hookHeaderHover(btn, bars, hoverColor)
		local info = TweenInfo.new(0.15)
		local function setHover(on)
			if Window.IsDestroyed then return end
			playTween(btn, info, {
				BackgroundColor3 = on and hoverColor or Theme.Raised,
				BackgroundTransparency = on and 0.1 or 0.4,
			})
			for _, bar in ipairs(bars) do
				playTween(bar, info, {BackgroundColor3 = on and Color3.new(1, 1, 1) or Theme.SubText})
			end
		end
		table.insert(Window.Connections, btn.MouseEnter:Connect(function() setHover(true) end))
		table.insert(Window.Connections, btn.MouseLeave:Connect(function() setHover(false) end))
	end

	local minimizeBtn = makeHeaderButton(-60)
	local minBar = makeIconBar(minimizeBtn, 10, 0)
	hookHeaderHover(minimizeBtn, {minBar}, Theme.Accent)

	local closeBtn = makeHeaderButton(-32)
	local closeBarA = makeIconBar(closeBtn, 12, 45)
	local closeBarB = makeIconBar(closeBtn, 12, -45)
	hookHeaderHover(closeBtn, {closeBarA, closeBarB}, Theme.Danger)

	-- Sidebar & Content Layout (sizes handled by applyLayout)
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, sidebarWidth, 1, -46)
	sidebar.Position = UDim2.new(0, 6, 0, TOPBAR_H + 4)
	sidebar.BackgroundTransparency = 1
	sidebar.ZIndex = 2
	sidebar.Parent = mainFrame

	local tabButtonsContainer = Instance.new("ScrollingFrame")
	tabButtonsContainer.Size = UDim2.new(1, 0, 1, 0)
	tabButtonsContainer.BackgroundTransparency = 1
	tabButtonsContainer.BorderSizePixel = 0
	tabButtonsContainer.ScrollBarThickness = 2
	tabButtonsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabButtonsContainer.ZIndex = 2
	tabButtonsContainer.Parent = sidebar

	local sidebarLayout = Instance.new("UIListLayout")
	sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sidebarLayout.Padding = UDim.new(0, 4)
	sidebarLayout.Parent = tabButtonsContainer

	table.insert(Window.Connections, sidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tabButtonsContainer.CanvasSize = UDim2.new(0, 0, 0, sidebarLayout.AbsoluteContentSize.Y + 5)
	end))

	local contentArea = Instance.new("Frame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, -(sidebarWidth + 18), 1, -50)
	contentArea.Position = UDim2.new(0, sidebarWidth + 12, 0, TOPBAR_H + 4)
	contentArea.BackgroundColor3 = Theme.Surface
	contentArea.BackgroundTransparency = 0
	contentArea.BorderSizePixel = 0
	contentArea.ClipsDescendants = true
	contentArea.ZIndex = 2
	contentArea.Parent = mainFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0, 8)
	contentCorner.Parent = contentArea

	local contentStroke = Instance.new("UIStroke")
	contentStroke.Color = Theme.Stroke
	contentStroke.Thickness = 1
	contentStroke.Parent = contentArea

	-- Responsive layout: called when the viewport changes & after animations finish
	applyLayout = function()
		if Window.IsDestroyed then return end
		local vp = getViewport()
		winWidth, winHeight = computeWindowSize(vp, menuPrefW, menuPrefH)
		sidebarWidth = computeSidebarWidth(winWidth)

		sidebar.Size = UDim2.new(0, sidebarWidth, 1, -46)
		contentArea.Size = UDim2.new(1, -(sidebarWidth + 18), 1, -50)
		contentArea.Position = UDim2.new(0, sidebarWidth + 12, 0, TOPBAR_H + 4)

		local notifWidth = math.clamp(vp.X - 20, 120, 260)
		notifContainer.Size = UDim2.new(0, notifWidth, 1, -20)
		notifContainer.Position = UDim2.new(1, -(notifWidth + 10), 0, 10)

		if isOpen and not Window.IsAnimating then
			mainFrame.Size = UDim2.new(0, winWidth, 0, Window.Minimized and TOPBAR_H or winHeight)
		end

		local x, y = clampWindowPos(mainFrame.Position.X.Offset, mainFrame.Position.Y.Offset)
		mainFrame.Position = UDim2.fromOffset(x, y)

		local tx = math.clamp(toggleBtn.Position.X.Offset, 0, math.max(0, vp.X - toggleSize))
		local ty = math.clamp(toggleBtn.Position.Y.Offset, 0, math.max(0, vp.Y - toggleSize))
		toggleBtn.Position = UDim2.fromOffset(tx, ty)
	end

	-- Live Viewport Listener
	local currentCamConn = nil
	local function setupCameraListener()
		if currentCamConn then
			currentCamConn:Disconnect()
			local oldIdx = table.find(Window.Connections, currentCamConn)
			if oldIdx then table.remove(Window.Connections, oldIdx) end
			currentCamConn = nil
		end
		local cam = Workspace.CurrentCamera
		if cam then
			currentCamConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(applyLayout)
			table.insert(Window.Connections, currentCamConn)
		end
		applyLayout()
	end

	setupCameraListener()
	table.insert(Window.Connections, Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(setupCameraListener))

	-- Floating button styling. Used at creation (FloatingButton = {...}) and at runtime
	-- through Window:SetFloatingButton. Only the fields you pass are changed.
	local function applyFloatingStyle(opts)
		if Window.IsDestroyed or type(opts) ~= "table" then return end

		if opts.Icon ~= nil and opts.Icon ~= "" then
			if not applyIcon(toggleBtn, opts.Icon, iconTint(opts.Icon), 0.58) then
				warn("[DrizxLibrary] FloatingButton.Icon is not a valid preset name or asset id: " .. tostring(opts.Icon))
			end
		end

		if typeof(opts.ImageColor) == "Color3" then
			setIconColor(toggleBtn, opts.ImageColor)
		end

		if opts.ScaleType ~= nil then
			local st = nil
			if typeof(opts.ScaleType) == "EnumItem" then
				if opts.ScaleType.EnumType == Enum.ScaleType then st = opts.ScaleType end
			else
				local ok, found = pcall(function() return Enum.ScaleType[tostring(opts.ScaleType)] end)
				if ok then st = found end
			end
			if st then
				toggleBtn.ScaleType = st
			else
				warn('[DrizxLibrary] FloatingButton.ScaleType must be "Crop", "Fit" or "Stretch".')
			end
		end

		if tonumber(opts.Size) then
			toggleSize = math.clamp(math.floor(tonumber(opts.Size)), 24, 96)
			toggleBtn.Size = UDim2.fromOffset(toggleSize, toggleSize)
		end

		if opts.Shape ~= nil then
			local shape = string.lower(tostring(opts.Shape))
			if shape == "circle" or shape == "rounded" or shape == "square" then
				floatShape = shape
				floatCorner = nil
			else
				warn('[DrizxLibrary] FloatingButton.Shape must be "Circle", "Rounded" or "Square".')
			end
		end
		if tonumber(opts.CornerRadius) then
			floatCorner = math.max(0, tonumber(opts.CornerRadius))
		end
		if floatCorner then
			toggleCorner.CornerRadius = UDim.new(0, floatCorner)
		elseif floatShape == "square" then
			toggleCorner.CornerRadius = UDim.new(0, 0)
		elseif floatShape == "rounded" then
			toggleCorner.CornerRadius = UDim.new(0, math.floor(toggleSize * 0.25))
		else
			toggleCorner.CornerRadius = UDim.new(1, 0)
		end

		if typeof(opts.BackgroundColor) == "Color3" then
			toggleBtn.BackgroundColor3 = opts.BackgroundColor
		end
		if tonumber(opts.BackgroundTransparency) then
			toggleBtn.BackgroundTransparency = math.clamp(tonumber(opts.BackgroundTransparency), 0, 1)
		end
		if typeof(opts.StrokeColor) == "Color3" then
			toggleStroke.Color = opts.StrokeColor
		end
		if tonumber(opts.StrokeThickness) then
			toggleStroke.Thickness = math.max(0, tonumber(opts.StrokeThickness))
		end

		if opts.Visible ~= nil then
			floatVisible = opts.Visible == true
		end
		toggleBtn.Visible = floatVisible and not floatLoadingHidden

		if opts.Position ~= nil then
			local vp = getViewport()
			local px, py = nil, nil
			if typeof(opts.Position) == "Vector2" then
				px, py = opts.Position.X, opts.Position.Y
			elseif typeof(opts.Position) == "UDim2" then
				px = opts.Position.X.Scale * vp.X + opts.Position.X.Offset
				py = opts.Position.Y.Scale * vp.Y + opts.Position.Y.Offset
			end
			if px and py then
				toggleBtn.Position = UDim2.fromOffset(px, py)
			end
		end

		-- Re-clamp the button to the screen (size/position may have changed)
		if applyLayout then applyLayout() end
	end

	-- Menu (main window) styling. Used at creation (Menu = {...}) and at runtime through
	-- Window:SetMenu. Only the fields you pass are changed.
	local function applyMenuStyle(opts)
		if Window.IsDestroyed or type(opts) ~= "table" then return end

		if typeof(opts.BackgroundColor) == "Color3" then
			mainFrame.BackgroundColor3 = opts.BackgroundColor
		end
		if tonumber(opts.BackgroundTransparency) then
			mainFrame.BackgroundTransparency = math.clamp(tonumber(opts.BackgroundTransparency), 0, 1)
		end

		if opts.BackgroundImage ~= nil then
			local img = parseIcon(opts.BackgroundImage)
			if img == "" and opts.BackgroundImage ~= "" then
				warn("[DrizxLibrary] Menu.BackgroundImage is not a valid asset id: " .. tostring(opts.BackgroundImage))
			end
			bgImg.Image = img
			bgImg.Visible = img ~= ""
			-- Let the image show through the content area a little
			contentArea.BackgroundTransparency = (img ~= "") and 0.25 or 0
		end
		if tonumber(opts.BackgroundImageTransparency) then
			bgImg.ImageTransparency = math.clamp(tonumber(opts.BackgroundImageTransparency), 0, 1)
		end

		if tonumber(opts.CornerRadius) then
			local radius = UDim.new(0, math.max(0, tonumber(opts.CornerRadius)))
			mainCorner.CornerRadius = radius
			topCorner.CornerRadius = radius
		end
		if typeof(opts.StrokeColor) == "Color3" then
			mainStroke.Color = opts.StrokeColor
		end
		if tonumber(opts.StrokeThickness) then
			mainStroke.Thickness = math.max(0, tonumber(opts.StrokeThickness))
		end

		if opts.Icon ~= nil and opts.Icon ~= "" then
			if not applyIcon(headerIcon, opts.Icon, iconTint(opts.Icon), 1) then
				warn("[DrizxLibrary] Menu.Icon is not a valid preset name or asset id: " .. tostring(opts.Icon))
			end
		end

		if opts.Shadow ~= nil then
			shadowEnabled = opts.Shadow == true
		end
		if tonumber(opts.ShadowTransparency) then
			shadowTransparency = math.clamp(tonumber(opts.ShadowTransparency), 0, 1)
		end
		syncShadow()

		local resized = false
		if tonumber(opts.Width) then
			menuPrefW = tonumber(opts.Width)
			resized = true
		end
		if tonumber(opts.Height) then
			menuPrefH = tonumber(opts.Height)
			resized = true
		end
		if resized and applyLayout then applyLayout() end
	end

	function Window:SetFloatingButton(opts)
		if type(opts) == "string" or type(opts) == "number" then
			opts = { Icon = opts }
		end
		applyFloatingStyle(opts)
	end

	function Window:SetMenu(opts)
		applyMenuStyle(opts)
	end

	applyFloatingStyle(floatCfg)
	applyMenuStyle(menuInit)

	-- Window Visibility Logic
	local function finishAnimation()
		Window.IsAnimating = false
		applyLayout()
	end

	toggleWindow = function()
		if Window.IsAnimating or Window.IsDestroyed then return end
		Window.IsAnimating = true
		isOpen = not isOpen
		cancelAllDrags()

		if isOpen then
			Window.Minimized = false
			sidebar.Visible = true
			contentArea.Visible = true
			mainFrame.Size = UDim2.new(0, winWidth, 0, 0)
			mainFrame.Visible = true
			playTween(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart),
				{Size = UDim2.new(0, winWidth, 0, winHeight)}, finishAnimation)
		else
			playTween(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart),
				{Size = UDim2.new(0, winWidth, 0, 0)}, function()
					if not isOpen then mainFrame.Visible = false end
					finishAnimation()
				end)
		end
	end

	local function toggleMinimize()
		if not isOpen or Window.IsAnimating or Window.IsDestroyed then return end
		Window.IsAnimating = true
		Window.Minimized = not Window.Minimized
		cancelAllDrags()

		if Window.Minimized then
			sidebar.Visible = false
			contentArea.Visible = false
			playTween(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart),
				{Size = UDim2.new(0, winWidth, 0, TOPBAR_H)}, finishAnimation)
		else
			sidebar.Visible = true
			contentArea.Visible = true
			playTween(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart),
				{Size = UDim2.new(0, winWidth, 0, winHeight)}, finishAnimation)
		end
	end

	function Window:Toggle()
		toggleWindow()
	end

	-- Register a cleanup function that runs when the window is destroyed
	-- (e.g. to disconnect connections owned by your own script).
	function Window:OnDestroy(callback)
		if type(callback) == "function" then
			table.insert(Window.DestroyCallbacks, callback)
		end
	end

	-- X button: fully removes the UI (window shrinks, floating button fades out, then Destroy).
	local closeDestroys = config.CloseAction ~= "Hide"
	local isClosing = false

	local function closeWindow()
		if Window.IsDestroyed or isClosing then return end
		isClosing = true
		Window.IsAnimating = true
		cancelAllDrags()

		local fadeInfo = TweenInfo.new(0.2)
		playTween(toggleBtn, fadeInfo, {BackgroundTransparency = 1, ImageTransparency = 1})
		playTween(toggleStroke, fadeInfo, {Transparency = 1})

		if mainFrame.Visible then
			playTween(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
				{Size = UDim2.new(0, mainFrame.AbsoluteSize.X, 0, 0)}, function()
					Window:Destroy()
				end)
		else
			Window:Destroy()
		end
	end

	function Window:Close()
		closeWindow()
	end

	table.insert(Window.Connections, closeBtn.MouseButton1Click:Connect(function()
		if closeDestroys then
			closeWindow()
		else
			toggleWindow()
		end
	end))
	table.insert(Window.Connections, minimizeBtn.MouseButton1Click:Connect(toggleMinimize))

	-- Flags: components created with Flag = "name" are stored here so they can be saved/loaded.
	-- Each entry has Get() (a serializable value) and Set(value) (applies the value AND fires the callback).
	local function registerFlag(tab, flag, kind, getter, setter)
		if flag == nil or flag == "" then return end
		flag = tostring(flag)
		if Window.Flags[flag] then
			warn("[DrizxLibrary] Flag '" .. flag .. "' is already used; the new component replaces the old one.")
		end
		local entry = { Type = kind, Get = getter, Set = setter }
		Window.Flags[flag] = entry
		tab.Flags = tab.Flags or {}
		tab.Flags[flag] = entry
	end

	-- Pointer position in the same coordinate space as GuiObject.AbsolutePosition.
	-- The window uses IgnoreGuiInset = true while InputObject.Position can be shifted by the top GUI inset,
	-- so the first press on an element calibrates which of the two matches (a press is known to be inside it).
	local insetMode = nil
	local function pointerPosition(input, target, calibrate)
		local insetY = 0
		pcall(function() insetY = GuiService:GetGuiInset().Y end)
		local x, y0 = input.Position.X, input.Position.Y
		local y1 = y0 + insetY
		if calibrate and insetY ~= 0 then
			local top = target.AbsolutePosition.Y
			local bottom = top + target.AbsoluteSize.Y
			local in0 = y0 >= top and y0 <= bottom
			local in1 = y1 >= top and y1 <= bottom
			if in0 and not in1 then
				insetMode = false
			elseif in1 and not in0 then
				insetMode = true
			end
		end
		if insetMode == false then
			return Vector2.new(x, y0)
		end
		return Vector2.new(x, y1)
	end

	-- Shared look ----------------------------------------------------------------
	local ROW_H = 38
	local canHover = UserInputService.MouseEnabled -- hover effects only make sense when there is a mouse
	local cardHoverColor = Theme.Card:Lerp(Theme.Raised, 0.5)

	-- Rounded card with a faint border. With a mouse the card lights up while hovered
	-- (hoverTarget is the button/frame that receives the mouse; pass nil for a static card).
	local function styleCard(card, connections, hoverTarget)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = card

		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = Theme.Stroke
		stroke.Transparency = 0.45
		stroke.Thickness = 1
		stroke.Parent = card

		if canHover and hoverTarget then
			local info = TweenInfo.new(0.15)
			table.insert(connections, hoverTarget.MouseEnter:Connect(function()
				if Window.IsDestroyed then return end
				playTween(card, info, {BackgroundColor3 = cardHoverColor})
				playTween(stroke, info, {Color = Theme.Accent, Transparency = 0.6})
			end))
			table.insert(connections, hoverTarget.MouseLeave:Connect(function()
				if Window.IsDestroyed then return end
				playTween(card, info, {BackgroundColor3 = Theme.Card})
				playTween(stroke, info, {Color = Theme.Stroke, Transparency = 0.45})
			end))
		end
		return stroke
	end

	-- Keybinds (PC): one shared keyboard listener for every Keybind in this window
	local keybinds = {}
	local keybindListening = nil
	local keybindConn = nil

	local function ensureKeybindListener()
		if keybindConn then return end
		keybindConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if Window.IsDestroyed then return end
			if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

			if keybindListening then
				-- the next key press becomes the binding (Escape clears it)
				local entry = keybindListening
				keybindListening = nil
				if input.KeyCode == Enum.KeyCode.Escape then
					entry.set(nil, true)
				else
					entry.set(input.KeyCode, true)
				end
				return
			end

			if gameProcessed then return end -- typing in a TextBox, chat, etc.
			for i = #keybinds, 1, -1 do
				local entry = keybinds[i]
				if not entry.alive() then
					table.remove(keybinds, i) -- its tab was destroyed
				elseif entry.key() == input.KeyCode then
					entry.fire()
				end
			end
		end)
		table.insert(Window.Connections, keybindConn)
	end

	-- Tab Engine
	function Window:CreateTab(tabConfig, iconArg)
		tabConfig = typeof(tabConfig) == "table" and tabConfig or { Name = tostring(tabConfig) }
		local tabNameKey = tabConfig.Name or "Tab"
		local tabNameDisplay = tostring(tabNameKey)
		local tabIconInput = tabConfig.Icon or iconArg or "Code"

		if Window.Tabs[tabNameKey] then
			return Window.Tabs[tabNameKey]
		end

		local Tab = { Name = tabNameKey, Connections = {}, Cancels = {}, Flags = {} }

		local tabBtn = Instance.new("TextButton")
		tabBtn.Size = UDim2.new(1, -2, 0, 34)
		tabBtn.BackgroundColor3 = Theme.Surface
		tabBtn.BackgroundTransparency = 0.5
		tabBtn.BorderSizePixel = 0
		tabBtn.Text = ""
		tabBtn.ZIndex = 3
		tabBtn.Parent = tabButtonsContainer

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 7)
		btnCorner.Parent = tabBtn

		local iconImg = Instance.new("ImageLabel")
		iconImg.Size = UDim2.new(0, 16, 0, 16)
		iconImg.Position = UDim2.new(0, 12, 0.5, -8)
		iconImg.BackgroundTransparency = 1
		if not applyIcon(iconImg, tabIconInput, Theme.SubText, 1) then
			warn("[DrizxLibrary] Tab icon is not a valid preset name or asset id: " .. tostring(tabIconInput))
			applyIcon(iconImg, "Code", Theme.SubText, 1)
		end
		iconImg.ZIndex = 4
		iconImg.Parent = tabBtn

		-- Accent indicator on the left edge, shown while the tab is active
		local indicator = Instance.new("Frame")
		indicator.Name = "Indicator"
		indicator.AnchorPoint = Vector2.new(0, 0.5)
		indicator.Position = UDim2.new(0, 2, 0.5, 0)
		indicator.Size = UDim2.new(0, 3, 0, 8)
		indicator.BackgroundColor3 = Theme.Accent
		indicator.BackgroundTransparency = 1
		indicator.BorderSizePixel = 0
		indicator.ZIndex = 4
		indicator.Parent = tabBtn

		local indicatorCorner = Instance.new("UICorner")
		indicatorCorner.CornerRadius = UDim.new(1, 0)
		indicatorCorner.Parent = indicator

		local labelTxt = Instance.new("TextLabel")
		labelTxt.Size = UDim2.new(1, -40, 1, 0)
		labelTxt.Position = UDim2.new(0, 34, 0, 0)
		labelTxt.BackgroundTransparency = 1
		labelTxt.Text = tabNameDisplay
		labelTxt.TextColor3 = Theme.SubText
		labelTxt.TextSize = 11
		labelTxt.Font = Enum.Font.GothamMedium
		labelTxt.TextXAlignment = Enum.TextXAlignment.Left
		labelTxt.TextTruncate = Enum.TextTruncate.AtEnd
		labelTxt.ZIndex = 4
		labelTxt.Parent = tabBtn

		local tabScroll = Instance.new("ScrollingFrame")
		tabScroll.Size = UDim2.new(1, -10, 1, -10)
		tabScroll.Position = UDim2.new(0, 5, 0, 5)
		tabScroll.BackgroundTransparency = 1
		tabScroll.BorderSizePixel = 0
		tabScroll.ScrollBarThickness = 3
		tabScroll.ScrollBarImageColor3 = Theme.Muted
		tabScroll.ScrollBarImageTransparency = 0.3
		tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		tabScroll.Visible = false
		tabScroll.ZIndex = 3
		tabScroll.Parent = contentArea

		local tabLayout = Instance.new("UIListLayout")
		tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
		tabLayout.Padding = UDim.new(0, 8)
		tabLayout.Parent = tabScroll

		-- A little breathing room so the cards' 1px borders are not clipped by the scrolling area
		local tabPad = Instance.new("UIPadding")
		tabPad.PaddingTop = UDim.new(0, 2)
		tabPad.PaddingBottom = UDim.new(0, 2)
		tabPad.PaddingLeft = UDim.new(0, 2)
		tabPad.PaddingRight = UDim.new(0, 2)
		tabPad.Parent = tabScroll

		table.insert(Tab.Connections, tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			tabScroll.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 8)
		end))

		-- Per-tab scroll lock: the original ScrollingEnabled value is saved when the first lock is taken
		-- and restored when the last lock is released.
		local scrollLocks = 0
		local scrollOriginal = true

		local function lockScroll()
			if scrollLocks == 0 then
				scrollOriginal = tabScroll.ScrollingEnabled
			end
			scrollLocks = scrollLocks + 1
			tabScroll.ScrollingEnabled = false
		end

		local function unlockScroll()
			if scrollLocks == 0 then return end
			scrollLocks = scrollLocks - 1
			if scrollLocks == 0 then
				tabScroll.ScrollingEnabled = scrollOriginal
			end
		end

		function Tab:Activate()
			if Window.IsDestroyed then return end
			cancelAllDrags()
			for _, child in ipairs(contentArea:GetChildren()) do
				if child:IsA("ScrollingFrame") then child.Visible = false end
			end
			for _, btn in ipairs(tabButtonsContainer:GetChildren()) do
				if btn:IsA("TextButton") then
					playTween(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.5})
					local ind = btn:FindFirstChild("Indicator")
					if ind then
						playTween(ind, TweenInfo.new(0.2), {BackgroundTransparency = 1, Size = UDim2.new(0, 3, 0, 8)})
					end
					local lbl = btn:FindFirstChildOfClass("TextLabel")
					if lbl then lbl.TextColor3 = Theme.SubText end
					local img = btn:FindFirstChildOfClass("ImageLabel")
					if img then setIconColor(img, Theme.SubText) end
				end
			end
			tabScroll.Visible = true
			playTween(tabBtn, TweenInfo.new(0.2), {
				BackgroundTransparency = 0,
				BackgroundColor3 = Theme.Raised
			})
			labelTxt.TextColor3 = Theme.Text
			setIconColor(iconImg, Theme.Accent)
			playTween(indicator, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0,
				Size = UDim2.new(0, 3, 0, 18),
			})
			Window.CurrentTab = Tab
		end

		table.insert(Tab.Connections, tabBtn.MouseButton1Click:Connect(function() Tab:Activate() end))

		if canHover then
			table.insert(Tab.Connections, tabBtn.MouseEnter:Connect(function()
				if Window.IsDestroyed or Window.CurrentTab == Tab then return end
				playTween(tabBtn, TweenInfo.new(0.12), {BackgroundTransparency = 0.2})
			end))
			table.insert(Tab.Connections, tabBtn.MouseLeave:Connect(function()
				if Window.IsDestroyed or Window.CurrentTab == Tab then return end
				playTween(tabBtn, TweenInfo.new(0.12), {BackgroundTransparency = 0.5})
			end))
		end

		Tab.Button = tabBtn
		Tab.Container = tabScroll
		Window.Tabs[tabNameKey] = Tab

		if not Window.CurrentTab then
			Tab:Activate()
		end

		-- Components
		function Tab:CreateSection(text)
			if type(text) == "table" then text = text.Name or text.Title or "" end
			local holder = Instance.new("Frame")
			holder.Size = UDim2.new(1, -4, 0, 26)
			holder.BackgroundTransparency = 1
			holder.ZIndex = 4
			holder.Parent = tabScroll

			local line = Instance.new("Frame")
			line.AnchorPoint = Vector2.new(0, 0.5)
			line.Position = UDim2.new(0, 0, 0.5, 2)
			line.Size = UDim2.new(1, 0, 0, 1)
			line.BackgroundColor3 = Theme.Stroke
			line.BackgroundTransparency = 0.3
			line.BorderSizePixel = 0
			line.ZIndex = 4
			line.Parent = holder

			-- The label sits on top of the line (same color as the content area), so the line only shows to its right.
			local secLabel = Instance.new("TextLabel")
			secLabel.AutomaticSize = Enum.AutomaticSize.X
			secLabel.Size = UDim2.new(0, 0, 1, 0)
			secLabel.BackgroundColor3 = Theme.Surface
			secLabel.BorderSizePixel = 0
			secLabel.Text = string.upper(tostring(text))
			secLabel.TextColor3 = Theme.Accent
			secLabel.TextSize = 11
			secLabel.Font = Enum.Font.GothamBold
			secLabel.ZIndex = 5
			secLabel.Parent = holder

			local secPad = Instance.new("UIPadding")
			secPad.PaddingLeft = UDim.new(0, 2)
			secPad.PaddingRight = UDim.new(0, 8)
			secPad.Parent = secLabel
		end

		function Tab:CreateParagraph(title, desc)
			if type(title) == "table" then
				local opts = title
				title = opts.Title or opts.Name or ""
				desc = opts.Content or opts.Description or ""
			end
			local pFrame = Instance.new("Frame")
			pFrame.Size = UDim2.new(1, -4, 0, 0)
			pFrame.AutomaticSize = Enum.AutomaticSize.Y
			pFrame.BackgroundColor3 = Theme.Card
			pFrame.BorderSizePixel = 0
			pFrame.ZIndex = 4
			pFrame.Parent = tabScroll
			styleCard(pFrame, Tab.Connections, nil)

			local pad = Instance.new("UIPadding")
			pad.PaddingTop = UDim.new(0, 9)
			pad.PaddingBottom = UDim.new(0, 10)
			pad.PaddingLeft = UDim.new(0, 12)
			pad.PaddingRight = UDim.new(0, 12)
			pad.Parent = pFrame

			local pLayout = Instance.new("UIListLayout")
			pLayout.SortOrder = Enum.SortOrder.LayoutOrder
			pLayout.Padding = UDim.new(0, 4)
			pLayout.Parent = pFrame

			local pTitle = Instance.new("TextLabel")
			pTitle.Size = UDim2.new(1, 0, 0, 18)
			pTitle.BackgroundTransparency = 1
			pTitle.Text = tostring(title)
			pTitle.TextColor3 = Theme.Text
			pTitle.TextSize = 12
			pTitle.Font = Enum.Font.GothamBold
			pTitle.TextXAlignment = Enum.TextXAlignment.Left
			pTitle.ZIndex = 5
			pTitle.Parent = pFrame

			local descLbl = Instance.new("TextLabel")
			descLbl.Size = UDim2.new(1, 0, 0, 0)
			descLbl.AutomaticSize = Enum.AutomaticSize.Y
			descLbl.BackgroundTransparency = 1
			descLbl.Text = tostring(desc)
			descLbl.TextColor3 = Theme.SubText
			descLbl.TextSize = 11
			descLbl.Font = Enum.Font.GothamMedium
			descLbl.TextXAlignment = Enum.TextXAlignment.Left
			descLbl.TextYAlignment = Enum.TextYAlignment.Top
			descLbl.TextWrapped = true
			descLbl.ZIndex = 5
			descLbl.Parent = pFrame
		end

		function Tab:CreateButton(btnText, callback)
			if type(btnText) == "table" then
				local opts = btnText
				btnText = opts.Name or opts.Title or "Button"
				callback = opts.Callback
			end
			callback = callback or function() end
			local pressColor = Theme.Accent:Lerp(Theme.Card, 0.35)

			local btnFrame = Instance.new("Frame")
			btnFrame.Size = UDim2.new(1, -4, 0, ROW_H)
			btnFrame.BackgroundColor3 = Theme.Card
			btnFrame.BorderSizePixel = 0
			btnFrame.ZIndex = 4
			btnFrame.Parent = tabScroll

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -44, 1, 0)
			label.Position = UDim2.new(0, 12, 0, 0)
			label.BackgroundTransparency = 1
			label.Text = tostring(btnText)
			label.TextColor3 = Theme.Text
			label.TextSize = 12
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.ZIndex = 5
			label.Parent = btnFrame

			local arrow = Instance.new("ImageLabel")
			arrow.Size = UDim2.new(0, 14, 0, 14)
			arrow.Position = UDim2.new(1, -26, 0.5, -7)
			arrow.BackgroundTransparency = 1
			arrow.ZIndex = 5
			applyIcon(arrow, "ChevronRight", Theme.SubText, 1)
			arrow.Parent = btnFrame

			local trigger = Instance.new("TextButton")
			trigger.Size = UDim2.new(1, 0, 1, 0)
			trigger.BackgroundTransparency = 1
			trigger.Text = ""
			trigger.AutoButtonColor = false
			trigger.ZIndex = 7
			trigger.Parent = btnFrame

			styleCard(btnFrame, Tab.Connections, trigger)

			table.insert(Tab.Connections, trigger.MouseButton1Click:Connect(function()
				if Window.IsDestroyed then return end
				playTween(btnFrame, TweenInfo.new(0.08), {BackgroundColor3 = pressColor}, function(state)
					if state ~= Enum.PlaybackState.Completed then return end
					playTween(btnFrame, TweenInfo.new(0.25), {BackgroundColor3 = Theme.Card})
				end)
				safeCall("Button", callback)
			end))

			return {
				SetText = function(_, text) label.Text = tostring(text) end,
			}
		end

		function Tab:CreateToggle(toggleText, defaultState, callback)
			local flag = nil
			if type(toggleText) == "table" then
				local opts = toggleText
				toggleText = opts.Name or opts.Title or "Toggle"
				defaultState = opts.Default
				flag = opts.Flag
				callback = opts.Callback
			end
			callback = callback or function() end
			local state = (typeof(defaultState) == "boolean" and defaultState) or false
			local onColor = Theme.Accent
			local offColor = Theme.Raised
			local knobOn = Color3.new(1, 1, 1)
			local knobOff = Color3.fromRGB(168, 178, 194)
			local KNOB_ON_POS = UDim2.new(0, 21, 0.5, -8)
			local KNOB_OFF_POS = UDim2.new(0, 3, 0.5, -8)

			local tFrame = Instance.new("Frame")
			tFrame.Size = UDim2.new(1, -4, 0, ROW_H)
			tFrame.BackgroundColor3 = Theme.Card
			tFrame.BorderSizePixel = 0
			tFrame.ZIndex = 4
			tFrame.Parent = tabScroll

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -66, 1, 0)
			label.Position = UDim2.new(0, 12, 0, 0)
			label.BackgroundTransparency = 1
			label.Text = tostring(toggleText)
			label.TextColor3 = Theme.Text
			label.TextSize = 12
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.ZIndex = 5
			label.Parent = tFrame

			local switchBox = Instance.new("Frame")
			switchBox.Size = UDim2.new(0, 40, 0, 22)
			switchBox.Position = UDim2.new(1, -52, 0.5, -11)
			switchBox.BackgroundColor3 = state and onColor or offColor
			switchBox.BorderSizePixel = 0
			switchBox.ZIndex = 5
			switchBox.Parent = tFrame

			local sCorner = Instance.new("UICorner")
			sCorner.CornerRadius = UDim.new(1, 0)
			sCorner.Parent = switchBox

			local dot = Instance.new("Frame")
			dot.Size = UDim2.new(0, 16, 0, 16)
			dot.Position = state and KNOB_ON_POS or KNOB_OFF_POS
			dot.BackgroundColor3 = state and knobOn or knobOff
			dot.BorderSizePixel = 0
			dot.ZIndex = 6
			dot.Parent = switchBox

			local dCorner = Instance.new("UICorner")
			dCorner.CornerRadius = UDim.new(1, 0)
			dCorner.Parent = dot

			local trigger = Instance.new("TextButton")
			trigger.Size = UDim2.new(1, 0, 1, 0)
			trigger.BackgroundTransparency = 1
			trigger.Text = ""
			trigger.AutoButtonColor = false
			trigger.ZIndex = 7
			trigger.Parent = tFrame

			styleCard(tFrame, Tab.Connections, trigger)

			local function updateToggle(newState, fireCallback)
				if Window.IsDestroyed then return end
				state = newState
				playTween(switchBox, TweenInfo.new(0.2), {BackgroundColor3 = state and onColor or offColor})
				playTween(dot, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Position = state and KNOB_ON_POS or KNOB_OFF_POS,
					BackgroundColor3 = state and knobOn or knobOff,
				})
				if fireCallback then
					safeCall("Toggle", callback, state)
				end
			end

			table.insert(Tab.Connections, trigger.MouseButton1Click:Connect(function()
				updateToggle(not state, true)
			end))

			registerFlag(Tab, flag, "Toggle",
				function() return state end,
				function(value)
					if typeof(value) == "boolean" then
						updateToggle(value, false)
						safeCall("Toggle", callback, state)
					end
				end)

			return {
				SetState = function(_, val)
					if typeof(val) == "boolean" then
						updateToggle(val, false)
					end
				end,
				GetState = function(_) return state end
			}
		end

		function Tab:CreateSlider(sliderText, minVal, maxVal, defaultVal, callback)
			local increment = nil
			local flag = nil
			if type(sliderText) == "table" then
				local opts = sliderText
				sliderText = opts.Name or opts.Title or "Slider"
				minVal = opts.Min
				maxVal = opts.Max
				defaultVal = opts.Default
				increment = tonumber(opts.Increment)
				flag = opts.Flag
				callback = opts.Callback
			end
			callback = callback or function() end
			minVal = tonumber(minVal) or 0
			maxVal = tonumber(maxVal) or 100
			if maxVal <= minVal then maxVal = minVal + 1 end

			-- Increment: defaults to 1 for integer ranges, continuous (1 decimal) otherwise.
			if not increment or increment <= 0 then
				increment = (minVal % 1 == 0 and maxVal % 1 == 0) and 1 or 0
			end
			local decimals = 0
			if increment == 0 then
				decimals = 1
			elseif increment < 1 then
				decimals = math.clamp(math.ceil(-math.log10(increment) - 1e-9), 1, 4)
			end
			local function snap(v)
				if increment > 0 then
					v = minVal + math.floor((v - minVal) / increment + 0.5) * increment
				end
				return math.clamp(v, minVal, maxVal)
			end

			local value = snap(math.clamp(tonumber(defaultVal) or minVal, minVal, maxVal))
			local startPos = (value - minVal) / (maxVal - minVal)

			local sFrame = Instance.new("Frame")
			sFrame.Size = UDim2.new(1, -4, 0, 54)
			sFrame.BackgroundColor3 = Theme.Card
			sFrame.BorderSizePixel = 0
			sFrame.Active = true -- sink input so the ScrollingFrame doesn't scroll while the slider is being dragged
			sFrame.ZIndex = 4
			sFrame.Parent = tabScroll
			styleCard(sFrame, Tab.Connections, sFrame)

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -86, 0, 20)
			label.Position = UDim2.new(0, 12, 0, 7)
			label.BackgroundTransparency = 1
			label.Text = tostring(sliderText)
			label.TextColor3 = Theme.Text
			label.TextSize = 12
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.ZIndex = 5
			label.Parent = sFrame

			-- Current value shown in a small pill
			local valPill = Instance.new("Frame")
			valPill.Size = UDim2.new(0, 56, 0, 20)
			valPill.Position = UDim2.new(1, -68, 0, 7)
			valPill.BackgroundColor3 = Theme.Raised
			valPill.BorderSizePixel = 0
			valPill.ZIndex = 5
			valPill.Parent = sFrame

			local pillCorner = Instance.new("UICorner")
			pillCorner.CornerRadius = UDim.new(0, 6)
			pillCorner.Parent = valPill

			local valLabel = Instance.new("TextLabel")
			valLabel.Size = UDim2.new(1, 0, 1, 0)
			valLabel.BackgroundTransparency = 1
			valLabel.Text = string.format("%." .. tostring(decimals) .. "f", value)
			valLabel.TextColor3 = Theme.Text
			valLabel.TextSize = 11
			valLabel.Font = Enum.Font.GothamBold
			valLabel.ZIndex = 6
			valLabel.Parent = valPill

			local track = Instance.new("Frame")
			track.Size = UDim2.new(1, -28, 0, 6)
			track.Position = UDim2.new(0, 14, 0, 38)
			track.BackgroundColor3 = Theme.Raised
			track.BorderSizePixel = 0
			track.ZIndex = 5
			track.Parent = sFrame

			local tCorner = Instance.new("UICorner")
			tCorner.CornerRadius = UDim.new(1, 0)
			tCorner.Parent = track

			local fill = Instance.new("Frame")
			fill.Size = UDim2.new(startPos, 0, 1, 0)
			fill.BackgroundColor3 = Theme.Accent
			fill.BorderSizePixel = 0
			fill.ZIndex = 6
			fill.Parent = track

			local fCorner = Instance.new("UICorner")
			fCorner.CornerRadius = UDim.new(1, 0)
			fCorner.Parent = fill

			local fillGradient = Instance.new("UIGradient")
			fillGradient.Color = ColorSequence.new(Theme.Accent:Lerp(Color3.new(0, 0, 0), 0.25), Theme.Accent:Lerp(Color3.new(1, 1, 1), 0.2))
			fillGradient.Parent = fill

			-- Round handle on the end of the fill; it grows a little while you drag
			local knob = Instance.new("Frame")
			knob.AnchorPoint = Vector2.new(0.5, 0.5)
			knob.Size = UDim2.fromOffset(16, 16)
			knob.Position = UDim2.new(startPos, 0, 0.5, 0)
			knob.BackgroundColor3 = Color3.new(1, 1, 1)
			knob.BorderSizePixel = 0
			knob.ZIndex = 7
			knob.Parent = track

			local knobCorner = Instance.new("UICorner")
			knobCorner.CornerRadius = UDim.new(1, 0)
			knobCorner.Parent = knob

			local knobStroke = Instance.new("UIStroke")
			knobStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			knobStroke.Color = Theme.Accent
			knobStroke.Thickness = 2
			knobStroke.Parent = knob

			local function applySliderValue(newValue, fireCallback)
				if Window.IsDestroyed then return end
				local num = tonumber(newValue)
				if not num then return end
				local snapped = snap(num)
				local changed = snapped ~= value
				value = snapped
				local pos = (value - minVal) / (maxVal - minVal)
				valLabel.Text = string.format("%." .. tostring(decimals) .. "f", value)
				fill.Size = UDim2.new(pos, 0, 1, 0)
				knob.Position = UDim2.new(pos, 0, 0.5, 0)
				if fireCallback then
					if changed then safeCall("Slider", callback, value) end
				end
			end

			local function updateSlider(input)
				local trackSize = track.AbsoluteSize.X
				if trackSize <= 0 then return end
				local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / trackSize, 0, 1)
				applySliderValue(minVal + (maxVal - minVal) * pos, true)
			end

			-- The whole card is a touch target (a 6px track is too hard to press on mobile)
			local dragConns = bindDrag(sFrame,
				function(input)
					lockScroll()
					playTween(knob, TweenInfo.new(0.12), {Size = UDim2.fromOffset(20, 20)})
					updateSlider(input)
				end,
				updateSlider,
				function()
					unlockScroll()
					if not Window.IsDestroyed then
						playTween(knob, TweenInfo.new(0.15), {Size = UDim2.fromOffset(16, 16)})
					end
				end
			)
			registerDrag(dragConns.cancel)
			table.insert(Tab.Cancels, dragConns.cancel)
			for _, conn in ipairs(dragConns) do
				table.insert(Tab.Connections, conn)
			end

			registerFlag(Tab, flag, "Slider",
				function() return value end,
				function(newValue)
					if tonumber(newValue) then
						applySliderValue(newValue, false)
						safeCall("Slider", callback, value)
					end
				end)

			return {
				SetValue = function(_, val) applySliderValue(val, false) end,
				GetValue = function(_) return value end
			}
		end

		function Tab:CreateDropdown(dropConfig)
			dropConfig = type(dropConfig) == "table" and dropConfig or {}
			local callback = dropConfig.Callback or function() end
			local multi = dropConfig.Multi == true -- Multi = true lets the player tick several options

			local HEADER_H = ROW_H
			local OPTION_H = 32
			local OPTION_GAP = 3
			local MAX_LIST_H = 150

			local options = {}
			local selected = nil -- single mode: the chosen option
			local chosen = {}    -- multi mode: the chosen options (kept in the same order as `options`)
			local isOpenDrop = false
			local optionButtons = {}
			local optionConns = {}

			local dFrame = Instance.new("Frame")
			dFrame.Size = UDim2.new(1, -4, 0, HEADER_H)
			dFrame.BackgroundColor3 = Theme.Card
			dFrame.BorderSizePixel = 0
			dFrame.ClipsDescendants = true
			dFrame.ZIndex = 4
			dFrame.Parent = tabScroll

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -142, 0, HEADER_H)
			label.Position = UDim2.new(0, 12, 0, 0)
			label.BackgroundTransparency = 1
			label.Text = tostring(dropConfig.Name or "Dropdown")
			label.TextColor3 = Theme.Text
			label.TextSize = 12
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.ZIndex = 5
			label.Parent = dFrame

			local valueLbl = Instance.new("TextLabel")
			valueLbl.Size = UDim2.new(0, 100, 0, HEADER_H)
			valueLbl.Position = UDim2.new(1, -132, 0, 0)
			valueLbl.BackgroundTransparency = 1
			valueLbl.Text = "Select..."
			valueLbl.TextColor3 = Theme.SubText
			valueLbl.TextSize = 11
			valueLbl.Font = Enum.Font.GothamMedium
			valueLbl.TextXAlignment = Enum.TextXAlignment.Right
			valueLbl.TextTruncate = Enum.TextTruncate.AtEnd
			valueLbl.ZIndex = 5
			valueLbl.Parent = dFrame

			-- Chevron drawn from Frames (a text arrow glyph shows as an empty box on many phones)
			local arrow = Instance.new("ImageLabel")
			arrow.AnchorPoint = Vector2.new(0.5, 0.5)
			arrow.Size = UDim2.new(0, 16, 0, 16)
			arrow.Position = UDim2.new(1, -20, 0, HEADER_H / 2)
			arrow.BackgroundTransparency = 1
			arrow.ZIndex = 5
			applyIcon(arrow, "ChevronDown", Theme.SubText, 1)
			arrow.Parent = dFrame

			local list = Instance.new("ScrollingFrame")
			list.Size = UDim2.new(1, -14, 0, 0)
			list.Position = UDim2.new(0, 7, 0, HEADER_H + 2)
			list.BackgroundTransparency = 1
			list.BorderSizePixel = 0
			list.ScrollBarThickness = 3
			list.ScrollBarImageColor3 = Theme.Muted
			list.CanvasSize = UDim2.new(0, 0, 0, 0)
			list.ZIndex = 5
			list.Parent = dFrame

			local listLayout = Instance.new("UIListLayout")
			listLayout.SortOrder = Enum.SortOrder.LayoutOrder
			listLayout.Padding = UDim.new(0, OPTION_GAP)
			listLayout.Parent = list

			local header = Instance.new("TextButton")
			header.Size = UDim2.new(1, 0, 0, HEADER_H)
			header.BackgroundTransparency = 1
			header.Text = ""
			header.AutoButtonColor = false
			header.ZIndex = 8
			header.Parent = dFrame

			styleCard(dFrame, Tab.Connections, header)

			local function isChosen(opt)
				if multi then
					return table.find(chosen, opt) ~= nil
				end
				return opt == selected
			end

			local function valueText()
				if multi then
					if #chosen == 0 then return "Select..." end
					if #chosen == 1 then return chosen[1] end
					return tostring(#chosen) .. " selected"
				end
				return selected or "Select..."
			end

			local function applySize()
				local listH = isOpenDrop and math.min(#options * (OPTION_H + OPTION_GAP), MAX_LIST_H) or 0
				local frameH = isOpenDrop and (HEADER_H + 8 + listH) or HEADER_H
				local info = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
				playTween(dFrame, info, {Size = UDim2.new(1, -4, 0, frameH)})
				playTween(list, info, {Size = UDim2.new(1, -14, 0, listH)})
				playTween(arrow, info, {Rotation = isOpenDrop and 180 or 0})
			end

			local function highlight()
				for opt, btn in pairs(optionButtons) do
					local isSelected = isChosen(opt)
					btn.TextColor3 = isSelected and Theme.Accent or Theme.Text
					btn.BackgroundColor3 = isSelected and Theme.Raised or Theme.Surface
					local check = btn:FindFirstChild("Check")
					if check then check.Visible = isSelected end
				end
			end

			-- single mode
			local function setSelected(opt, fireCallback)
				selected = opt
				valueLbl.Text = valueText()
				highlight()
				if fireCallback and opt ~= nil then
					safeCall("Dropdown", callback, opt)
				end
			end

			-- multi mode: `list` is an array of option names; unknown names are ignored
			local function setChosen(values, fireCallback)
				local wanted = {}
				for _, opt in ipairs(values or {}) do
					wanted[tostring(opt)] = true
				end
				chosen = {}
				for _, opt in ipairs(options) do
					if wanted[opt] then table.insert(chosen, opt) end
				end
				valueLbl.Text = valueText()
				highlight()
				if fireCallback then
					safeCall("Dropdown", callback, table.clone(chosen))
				end
			end

			local function setOptions(newOptions)
				options = {}
				local seen = {}
				for _, opt in ipairs(newOptions or {}) do
					local text = tostring(opt)
					if not seen[text] then
						seen[text] = true
						table.insert(options, text)
					end
				end
			end

			local function buildOptions()
				for _, conn in ipairs(optionConns) do
					conn:Disconnect()
				end
				optionConns = {}
				for _, btn in pairs(optionButtons) do
					btn:Destroy()
				end
				optionButtons = {}

				for i, opt in ipairs(options) do
					local btn = Instance.new("TextButton")
					btn.Size = UDim2.new(1, -4, 0, OPTION_H)
					btn.BackgroundColor3 = Theme.Surface
					btn.BorderSizePixel = 0
					btn.AutoButtonColor = false
					btn.Text = "  " .. opt
					btn.TextSize = 12
					btn.Font = Enum.Font.GothamMedium
					btn.TextXAlignment = Enum.TextXAlignment.Left
					btn.TextTruncate = Enum.TextTruncate.AtEnd
					btn.LayoutOrder = i
					btn.ZIndex = 6
					btn.Parent = list

					local bCorner = Instance.new("UICorner")
					bCorner.CornerRadius = UDim.new(0, 6)
					bCorner.Parent = btn

					-- check mark on the selected option(s) (drawn from Frames, shown by highlight())
					local check = Instance.new("ImageLabel")
					check.Name = "Check"
					check.AnchorPoint = Vector2.new(1, 0.5)
					check.Size = UDim2.new(0, 14, 0, 14)
					check.Position = UDim2.new(1, -10, 0.5, 0)
					check.BackgroundTransparency = 1
					check.Visible = false
					check.ZIndex = 7
					applyIcon(check, "Check", Theme.Accent, 1)
					check.Parent = btn

					optionButtons[opt] = btn
					table.insert(optionConns, btn.MouseButton1Click:Connect(function()
						if multi then
							-- tick / untick, and keep the list open so several options can be picked
							local current = table.clone(chosen)
							local idx = table.find(current, opt)
							if idx then table.remove(current, idx) else table.insert(current, opt) end
							setChosen(current, true)
						else
							setSelected(opt, true)
							isOpenDrop = false
							applySize()
						end
					end))
					if canHover then
						table.insert(optionConns, btn.MouseEnter:Connect(function()
							if not isChosen(opt) and not Window.IsDestroyed then
								playTween(btn, TweenInfo.new(0.12), {BackgroundColor3 = Theme.Raised})
							end
						end))
						table.insert(optionConns, btn.MouseLeave:Connect(function()
							if not isChosen(opt) and not Window.IsDestroyed then
								playTween(btn, TweenInfo.new(0.12), {BackgroundColor3 = Theme.Surface})
							end
						end))
					end
				end

				list.CanvasSize = UDim2.new(0, 0, 0, #options * (OPTION_H + OPTION_GAP))
				highlight()
			end

			table.insert(Tab.Connections, header.MouseButton1Click:Connect(function()
				if Window.IsDestroyed then return end
				isOpenDrop = not isOpenDrop
				applySize()
			end))

			setOptions(dropConfig.Options)
			buildOptions()
			if multi then
				local defaults = dropConfig.Default
				if type(defaults) ~= "table" and defaults ~= nil then defaults = {defaults} end
				setChosen(defaults, false)
			elseif dropConfig.Default ~= nil and table.find(options, tostring(dropConfig.Default)) then
				setSelected(tostring(dropConfig.Default), false)
			end

			registerFlag(Tab, dropConfig.Flag, "Dropdown",
				function()
					if multi then return table.clone(chosen) end
					return selected
				end,
				function(value)
					if multi then
						if type(value) == "table" then
							setChosen(value, true)
						end
					else
						local text = tostring(value)
						if table.find(options, text) then
							setSelected(text, false)
							safeCall("Dropdown", callback, selected)
						end
					end
				end)

			return {
				Set = function(_, value)
					if multi then
						if type(value) == "table" then setChosen(value, false) end
					else
						local text = tostring(value)
						if table.find(options, text) then
							setSelected(text, false)
						end
					end
				end,
				Get = function(_)
					if multi then return table.clone(chosen) end
					return selected
				end,
				Refresh = function(_, newOptions)
					setOptions(newOptions)
					buildOptions()
					if multi then
						setChosen(chosen, false)
					elseif selected and not table.find(options, selected) then
						setSelected(nil, false)
					end
					if isOpenDrop then applySize() end
				end
			}
		end

		function Tab:CreateTextbox(boxConfig)
			boxConfig = type(boxConfig) == "table" and boxConfig or {}
			local callback = boxConfig.Callback or function() end

			local bFrame = Instance.new("Frame")
			bFrame.Size = UDim2.new(1, -4, 0, ROW_H)
			bFrame.BackgroundColor3 = Theme.Card
			bFrame.BorderSizePixel = 0
			bFrame.ZIndex = 4
			bFrame.Parent = tabScroll
			styleCard(bFrame, Tab.Connections, nil)

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(0.5, -14, 1, 0)
			label.Position = UDim2.new(0, 12, 0, 0)
			label.BackgroundTransparency = 1
			label.Text = tostring(boxConfig.Name or "Textbox")
			label.TextColor3 = Theme.Text
			label.TextSize = 12
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.ZIndex = 5
			label.Parent = bFrame

			local input = Instance.new("TextBox")
			input.Size = UDim2.new(0.5, -18, 0, 26)
			input.Position = UDim2.new(0.5, 6, 0.5, -13)
			input.BackgroundColor3 = Theme.Surface
			input.BorderSizePixel = 0
			input.ClearTextOnFocus = boxConfig.ClearOnFocus == true
			input.ClipsDescendants = true
			input.PlaceholderText = tostring(boxConfig.Placeholder or "")
			input.PlaceholderColor3 = Theme.Muted
			input.Text = tostring(boxConfig.Default or "")
			input.TextColor3 = Theme.Text
			input.TextSize = 11
			input.Font = Enum.Font.GothamMedium
			input.TextXAlignment = Enum.TextXAlignment.Left
			input.ZIndex = 5
			input.Parent = bFrame

			local iCorner = Instance.new("UICorner")
			iCorner.CornerRadius = UDim.new(0, 6)
			iCorner.Parent = input

			local iPad = Instance.new("UIPadding")
			iPad.PaddingLeft = UDim.new(0, 8)
			iPad.PaddingRight = UDim.new(0, 8)
			iPad.Parent = input

			-- The border turns to the accent color while the box has focus
			local inputStroke = Instance.new("UIStroke")
			inputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			inputStroke.Color = Theme.Stroke
			inputStroke.Transparency = 0.3
			inputStroke.Thickness = 1
			inputStroke.Parent = input

			table.insert(Tab.Connections, input.Focused:Connect(function()
				if Window.IsDestroyed then return end
				playTween(inputStroke, TweenInfo.new(0.15), {Color = Theme.Accent, Transparency = 0})
			end))

			-- The callback fires when focus is lost (Enter, tapping outside the box, or the done button on mobile).
			table.insert(Tab.Connections, input.FocusLost:Connect(function(enterPressed)
				if Window.IsDestroyed then return end
				playTween(inputStroke, TweenInfo.new(0.15), {Color = Theme.Stroke, Transparency = 0.3})
				safeCall("Textbox", callback, input.Text, enterPressed)
			end))

			registerFlag(Tab, boxConfig.Flag, "Textbox",
				function() return input.Text end,
				function(text)
					input.Text = tostring(text)
					safeCall("Textbox", callback, input.Text, false)
				end)

			return {
				Set = function(_, text) input.Text = tostring(text) end,
				Get = function(_) return input.Text end
			}
		end

		-- Keybind (PC): click the key box, then press a key. Escape clears it.
		-- Callback runs every time the key is pressed; OnChanged(keyName) runs when the binding changes.
		function Tab:CreateKeybind(kbConfig)
			kbConfig = type(kbConfig) == "table" and kbConfig or {}
			local callback = kbConfig.Callback or function() end
			local onChanged = kbConfig.OnChanged or function() end
			local key = parseKeyCode(kbConfig.Default)

			local kFrame = Instance.new("Frame")
			kFrame.Size = UDim2.new(1, -4, 0, ROW_H)
			kFrame.BackgroundColor3 = Theme.Card
			kFrame.BorderSizePixel = 0
			kFrame.ZIndex = 4
			kFrame.Parent = tabScroll
			styleCard(kFrame, Tab.Connections, nil)

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -118, 1, 0)
			label.Position = UDim2.new(0, 12, 0, 0)
			label.BackgroundTransparency = 1
			label.Text = tostring(kbConfig.Name or "Keybind")
			label.TextColor3 = Theme.Text
			label.TextSize = 12
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.ZIndex = 5
			label.Parent = kFrame

			local pill = Instance.new("TextButton")
			pill.Size = UDim2.new(0, 90, 0, 26)
			pill.Position = UDim2.new(1, -102, 0.5, -13)
			pill.BackgroundColor3 = Theme.Raised
			pill.BorderSizePixel = 0
			pill.AutoButtonColor = false
			pill.TextSize = 11
			pill.Font = Enum.Font.GothamBold
			pill.TextTruncate = Enum.TextTruncate.AtEnd
			pill.ZIndex = 5
			pill.Parent = kFrame

			local pillCorner = Instance.new("UICorner")
			pillCorner.CornerRadius = UDim.new(0, 6)
			pillCorner.Parent = pill

			local pillStroke = Instance.new("UIStroke")
			pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			pillStroke.Thickness = 1
			pillStroke.Parent = pill

			local entry = nil

			local function refreshPill(listening)
				if Window.IsDestroyed then return end
				if listening then
					pill.Text = "Press a key..."
					pill.TextColor3 = Theme.Accent
					pillStroke.Color = Theme.Accent
					pillStroke.Transparency = 0
				else
					pill.Text = key and key.Name or "None"
					pill.TextColor3 = Theme.Text
					pillStroke.Color = Theme.Stroke
					pillStroke.Transparency = 0.3
				end
			end
			refreshPill(false)

			local function setKey(newKey, notifyChange)
				key = newKey
				refreshPill(false)
				if notifyChange then
					safeCall("Keybind", onChanged, key and key.Name or nil)
				end
			end

			entry = {
				alive = function() return kFrame.Parent ~= nil end,
				key = function() return key end,
				fire = function() safeCall("Keybind", callback, key) end,
				set = setKey,
				reset = function() refreshPill(false) end,
			}
			table.insert(keybinds, entry)
			ensureKeybindListener()

			table.insert(Tab.Connections, pill.MouseButton1Click:Connect(function()
				if Window.IsDestroyed then return end
				if keybindListening == entry then
					keybindListening = nil
					refreshPill(false)
					return
				end
				if keybindListening then keybindListening.reset() end
				keybindListening = entry
				refreshPill(true)
			end))

			registerFlag(Tab, kbConfig.Flag, "Keybind",
				function() return key and key.Name or "None" end,
				function(value)
					if value == "None" then
						setKey(nil, true)
					else
						local parsed = parseKeyCode(value)
						if parsed then setKey(parsed, true) end
					end
				end)

			return {
				Set = function(_, newKey) setKey(parseKeyCode(newKey), false) end,
				Get = function(_) return key end,
			}
		end

		-- Divider: a thin line to separate groups of components
		function Tab:CreateDivider()
			local holder = Instance.new("Frame")
			holder.Size = UDim2.new(1, -4, 0, 8)
			holder.BackgroundTransparency = 1
			holder.ZIndex = 4
			holder.Parent = tabScroll

			local line = Instance.new("Frame")
			line.AnchorPoint = Vector2.new(0, 0.5)
			line.Position = UDim2.new(0, 0, 0.5, 0)
			line.Size = UDim2.new(1, 0, 0, 1)
			line.BackgroundColor3 = Theme.Stroke
			line.BorderSizePixel = 0
			line.ZIndex = 5
			line.Parent = holder
		end

		-- Label: plain text line that can be changed later (Set / Get)
		function Tab:CreateLabel(labelConfig)
			if type(labelConfig) ~= "table" then
				labelConfig = { Text = labelConfig }
			end
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, -4, 0, 0)
			lbl.AutomaticSize = Enum.AutomaticSize.Y
			lbl.BackgroundTransparency = 1
			lbl.Text = tostring(labelConfig.Text or labelConfig.Name or "")
			lbl.TextColor3 = Theme.SubText
			lbl.TextSize = 11
			lbl.Font = Enum.Font.GothamMedium
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.TextYAlignment = Enum.TextYAlignment.Top
			lbl.TextWrapped = true
			lbl.ZIndex = 4
			lbl.Parent = tabScroll

			local lblPad = Instance.new("UIPadding")
			lblPad.PaddingLeft = UDim.new(0, 4)
			lblPad.PaddingRight = UDim.new(0, 4)
			lblPad.Parent = lbl

			return {
				Set = function(_, text) lbl.Text = tostring(text) end,
				Get = function(_) return lbl.Text end,
			}
		end

		-- Color picker: tap the card to open a saturation/value map + hue bar. Works with mouse and touch.
		function Tab:CreateColorPicker(cpConfig)
			cpConfig = type(cpConfig) == "table" and cpConfig or {}
			local callback = cpConfig.Callback or function() end

			local HEADER_H = ROW_H
			local MAP_H = 92
			local BAR_H = 12
			local PANEL_TOP = HEADER_H + 4
			local PANEL_H = MAP_H + 8 + BAR_H + 8 + 14
			local OPEN_H = PANEL_TOP + PANEL_H + 8

			local current = parseColor(cpConfig.Default) or Color3.fromRGB(255, 80, 80)
			local hue, sat, val = Color3.toHSV(current)
			local isOpenPicker = false

			local cFrame = Instance.new("Frame")
			cFrame.Size = UDim2.new(1, -4, 0, HEADER_H)
			cFrame.BackgroundColor3 = Theme.Card
			cFrame.BorderSizePixel = 0
			cFrame.ClipsDescendants = true
			cFrame.ZIndex = 4
			cFrame.Parent = tabScroll

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -70, 0, HEADER_H)
			label.Position = UDim2.new(0, 12, 0, 0)
			label.BackgroundTransparency = 1
			label.Text = tostring(cpConfig.Name or cpConfig.Title or "Color")
			label.TextColor3 = Theme.Text
			label.TextSize = 12
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.ZIndex = 5
			label.Parent = cFrame

			local swatch = Instance.new("Frame")
			swatch.Size = UDim2.new(0, 42, 0, 22)
			swatch.Position = UDim2.new(1, -54, 0, 8)
			swatch.BackgroundColor3 = current
			swatch.BorderSizePixel = 0
			swatch.ZIndex = 5
			swatch.Parent = cFrame

			local swatchCorner = Instance.new("UICorner")
			swatchCorner.CornerRadius = UDim.new(0, 4)
			swatchCorner.Parent = swatch

			local swatchStroke = Instance.new("UIStroke")
			swatchStroke.Color = Theme.Stroke
			swatchStroke.Thickness = 1
			swatchStroke.Parent = swatch

			local header = Instance.new("TextButton")
			header.Size = UDim2.new(1, 0, 0, HEADER_H)
			header.BackgroundTransparency = 1
			header.Text = ""
			header.ZIndex = 7
			header.Parent = cFrame

			styleCard(cFrame, Tab.Connections, header)

			local panel = Instance.new("Frame")
			panel.Size = UDim2.new(1, -20, 0, PANEL_H)
			panel.Position = UDim2.new(0, 10, 0, PANEL_TOP)
			panel.BackgroundTransparency = 1
			panel.Visible = false
			panel.ZIndex = 5
			panel.Parent = cFrame

			-- Saturation (left to right) / value (bottom to top) map. The base color is the pure hue; a white overlay
			-- (opaque on the left, clear on the right) and a black overlay (clear on top, opaque at the bottom) are
			-- drawn with gradients, so no image asset is needed.
			local map = Instance.new("Frame")
			map.Size = UDim2.new(1, 0, 0, MAP_H)
			map.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
			map.BorderSizePixel = 0
			map.Active = true
			map.ZIndex = 6
			map.Parent = panel

			local mapCorner = Instance.new("UICorner")
			mapCorner.CornerRadius = UDim.new(0, 6)
			mapCorner.Parent = map

			local whiteOverlay = Instance.new("Frame")
			whiteOverlay.Size = UDim2.fromScale(1, 1)
			whiteOverlay.BackgroundColor3 = Color3.new(1, 1, 1)
			whiteOverlay.BorderSizePixel = 0
			whiteOverlay.Parent = map
			local whiteCorner = Instance.new("UICorner")
			whiteCorner.CornerRadius = UDim.new(0, 6)
			whiteCorner.Parent = whiteOverlay
			local whiteGradient = Instance.new("UIGradient")
			whiteGradient.Transparency = NumberSequence.new(0, 1)
			whiteGradient.Parent = whiteOverlay

			local blackOverlay = Instance.new("Frame")
			blackOverlay.Size = UDim2.fromScale(1, 1)
			blackOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
			blackOverlay.BorderSizePixel = 0
			blackOverlay.Parent = map
			local blackCorner = Instance.new("UICorner")
			blackCorner.CornerRadius = UDim.new(0, 6)
			blackCorner.Parent = blackOverlay
			local blackGradient = Instance.new("UIGradient")
			blackGradient.Rotation = 90
			blackGradient.Transparency = NumberSequence.new(1, 0)
			blackGradient.Parent = blackOverlay

			local mapKnob = Instance.new("Frame")
			mapKnob.AnchorPoint = Vector2.new(0.5, 0.5)
			mapKnob.Size = UDim2.new(0, 12, 0, 12)
			mapKnob.BackgroundColor3 = current
			mapKnob.BorderSizePixel = 0
			mapKnob.ZIndex = 8
			mapKnob.Parent = map

			local mapKnobCorner = Instance.new("UICorner")
			mapKnobCorner.CornerRadius = UDim.new(1, 0)
			mapKnobCorner.Parent = mapKnob

			local mapKnobStroke = Instance.new("UIStroke")
			mapKnobStroke.Color = Color3.new(1, 1, 1)
			mapKnobStroke.Thickness = 2
			mapKnobStroke.Parent = mapKnob

			local hueBar = Instance.new("Frame")
			hueBar.Position = UDim2.new(0, 0, 0, MAP_H + 8)
			hueBar.Size = UDim2.new(1, 0, 0, BAR_H)
			hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
			hueBar.BorderSizePixel = 0
			hueBar.Active = true
			hueBar.ZIndex = 6
			hueBar.Parent = panel

			local hueCorner = Instance.new("UICorner")
			hueCorner.CornerRadius = UDim.new(0, 6)
			hueCorner.Parent = hueBar

			local hueKeys = {}
			for i = 0, 6 do
				table.insert(hueKeys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
			end
			local hueGradient = Instance.new("UIGradient")
			hueGradient.Color = ColorSequence.new(hueKeys)
			hueGradient.Parent = hueBar

			local hueKnob = Instance.new("Frame")
			hueKnob.AnchorPoint = Vector2.new(0.5, 0.5)
			hueKnob.Size = UDim2.new(0, 6, 0, 18)
			hueKnob.BackgroundColor3 = Color3.new(1, 1, 1)
			hueKnob.BorderSizePixel = 0
			hueKnob.ZIndex = 8
			hueKnob.Parent = hueBar

			local hueKnobCorner = Instance.new("UICorner")
			hueKnobCorner.CornerRadius = UDim.new(0, 3)
			hueKnobCorner.Parent = hueKnob

			local hueKnobStroke = Instance.new("UIStroke")
			hueKnobStroke.Color = Color3.new(0, 0, 0)
			hueKnobStroke.Transparency = 0.4
			hueKnobStroke.Thickness = 1
			hueKnobStroke.Parent = hueKnob

			local hexLbl = Instance.new("TextLabel")
			hexLbl.Position = UDim2.new(0, 0, 0, MAP_H + 8 + BAR_H + 8)
			hexLbl.Size = UDim2.new(1, 0, 0, 14)
			hexLbl.BackgroundTransparency = 1
			hexLbl.TextColor3 = Theme.SubText
			hexLbl.TextSize = 10
			hexLbl.Font = Enum.Font.GothamMedium
			hexLbl.TextXAlignment = Enum.TextXAlignment.Left
			hexLbl.ZIndex = 6
			hexLbl.Parent = panel

			local function refresh(fireCallback)
				if Window.IsDestroyed then return end
				current = Color3.fromHSV(hue, sat, val)
				swatch.BackgroundColor3 = current
				map.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
				mapKnob.Position = UDim2.new(sat, 0, 1 - val, 0)
				mapKnob.BackgroundColor3 = current
				hueKnob.Position = UDim2.new(hue, 0, 0.5, 0)
				hexLbl.Text = colorToHex(current)
				if fireCallback then
					safeCall("ColorPicker", callback, current)
				end
			end
			refresh(false)

			local function setOpen(open)
				if Window.IsDestroyed then return end
				isOpenPicker = open
				local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				if open then
					panel.Visible = true
					playTween(cFrame, info, {Size = UDim2.new(1, -4, 0, OPEN_H)})
				else
					playTween(cFrame, info, {Size = UDim2.new(1, -4, 0, HEADER_H)}, function()
						if not isOpenPicker and not Window.IsDestroyed then
							panel.Visible = false
						end
					end)
				end
			end

			table.insert(Tab.Connections, header.MouseButton1Click:Connect(function()
				setOpen(not isOpenPicker)
			end))

			-- Dragging on the map / hue bar (locks the tab scroll while dragging, like the slider)
			local function bindPicker(target, onPress, onDrag)
				local dragConns = bindDrag(target,
					function(input)
						lockScroll()
						onPress(input)
					end,
					onDrag,
					function()
						unlockScroll()
					end
				)
				registerDrag(dragConns.cancel)
				table.insert(Tab.Cancels, dragConns.cancel)
				for _, conn in ipairs(dragConns) do
					table.insert(Tab.Connections, conn)
				end
			end

			local function updateMap(input, calibrate)
				local size = map.AbsoluteSize
				if size.X <= 0 or size.Y <= 0 then return end
				local point = pointerPosition(input, map, calibrate)
				sat = math.clamp((point.X - map.AbsolutePosition.X) / size.X, 0, 1)
				val = 1 - math.clamp((point.Y - map.AbsolutePosition.Y) / size.Y, 0, 1)
				refresh(true)
			end
			bindPicker(map,
				function(input) updateMap(input, true) end,
				function(input) updateMap(input, false) end)

			local function updateHue(input)
				local width = hueBar.AbsoluteSize.X
				if width <= 0 then return end
				hue = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / width, 0, 1)
				refresh(true)
			end
			bindPicker(hueBar, updateHue, updateHue)

			registerFlag(Tab, cpConfig.Flag, "ColorPicker",
				function() return colorToHex(current) end,
				function(value)
					local parsed = parseColor(value)
					if parsed then
						hue, sat, val = Color3.toHSV(parsed)
						refresh(true)
					end
				end)

			return {
				Set = function(_, color)
					local parsed = parseColor(color)
					if parsed then
						hue, sat, val = Color3.toHSV(parsed)
						refresh(false) -- does not fire the callback
					end
				end,
				Get = function(_) return current end,
			}
		end

		return Tab
	end

	-- Config system ----------------------------------------------------------
	-- Components created with Flag = "name" are saved to / loaded from JSON files in the executor's
	-- workspace folder. Needs the executor file functions (writefile, readfile, ...); without them the
	-- Save/Load methods just return false and a message.
	local configFolder = tostring(config.ConfigFolder or "DrizxLibrary")

	local function cleanConfigName(name)
		local cleaned = string.gsub(tostring(name or ""), "[^%w%-_ ]", "")
		cleaned = string.gsub(cleaned, "^%s+", "")
		cleaned = string.gsub(cleaned, "%s+$", "")
		if cleaned == "" then return nil end
		return cleaned
	end

	local function configPath(name)
		return configFolder .. "/" .. name .. ".json"
	end

	local function ensureConfigFolder()
		if type(makefolder) ~= "function" then return end
		if type(isfolder) == "function" then
			local ok, exists = pcall(isfolder, configFolder)
			if ok and exists then return end
		end
		pcall(makefolder, configFolder)
	end

	-- Current value of every flag, as a table that can be JSON-encoded.
	function Window:GetConfig()
		local data = {}
		for flag, entry in pairs(Window.Flags) do
			local ok, value = pcall(entry.Get)
			if ok and value ~= nil then
				data[flag] = value
			end
		end
		return data
	end

	-- Applies values to the matching flags (callbacks fire). Returns how many flags were applied.
	function Window:ApplyConfig(data)
		if type(data) ~= "table" then return 0 end
		local applied = 0
		for flag, value in pairs(data) do
			local entry = Window.Flags[flag]
			if entry then
				local ok, err = pcall(entry.Set, value)
				if ok then
					applied = applied + 1
				else
					warn("[DrizxLibrary] Could not apply flag '" .. tostring(flag) .. "': " .. tostring(err))
				end
			end
		end
		return applied
	end

	function Window:GetFlag(flag)
		local entry = Window.Flags[tostring(flag)]
		if not entry then return nil end
		local ok, value = pcall(entry.Get)
		if ok then return value end
		return nil
	end

	function Window:SetFlag(flag, value)
		local entry = Window.Flags[tostring(flag)]
		if not entry then return false end
		return (pcall(entry.Set, value))
	end

	-- Returns true + the saved name, or false + an error message.
	function Window:SaveConfig(name)
		if Window.IsDestroyed then return false, "Window is destroyed." end
		local clean = cleanConfigName(name)
		if not clean then return false, "Invalid config name." end
		if type(writefile) ~= "function" then return false, "This executor does not support writefile." end

		local okEncode, json = pcall(function()
			return HttpService:JSONEncode(Window:GetConfig())
		end)
		if not okEncode then return false, tostring(json) end

		ensureConfigFolder()
		local okWrite, err = pcall(writefile, configPath(clean), json)
		if not okWrite then return false, tostring(err) end
		return true, clean
	end

	-- Returns true + the number of applied flags, or false + an error message.
	function Window:LoadConfig(name)
		if Window.IsDestroyed then return false, "Window is destroyed." end
		local clean = cleanConfigName(name)
		if not clean then return false, "Invalid config name." end
		if type(readfile) ~= "function" then return false, "This executor does not support readfile." end

		local path = configPath(clean)
		if type(isfile) == "function" then
			local okExists, exists = pcall(isfile, path)
			if okExists and not exists then return false, "Config '" .. clean .. "' does not exist." end
		end

		local okRead, raw = pcall(readfile, path)
		if not okRead then return false, tostring(raw) end
		local okDecode, data = pcall(function() return HttpService:JSONDecode(raw) end)
		if not okDecode or type(data) ~= "table" then return false, "Config file is not valid JSON." end
		return true, Window:ApplyConfig(data)
	end

	function Window:DeleteConfig(name)
		local clean = cleanConfigName(name)
		if not clean then return false, "Invalid config name." end
		if type(delfile) ~= "function" then return false, "This executor does not support delfile." end

		local path = configPath(clean)
		if type(isfile) == "function" then
			local okExists, exists = pcall(isfile, path)
			if okExists and not exists then return false, "Config '" .. clean .. "' does not exist." end
		end
		local ok, err = pcall(delfile, path)
		if not ok then return false, tostring(err) end
		return true, clean
	end

	-- Names of the saved configs (empty if the executor has no listfiles).
	function Window:ListConfigs()
		local names = {}
		if type(listfiles) ~= "function" then return names end
		local ok, files = pcall(listfiles, configFolder)
		if not ok or type(files) ~= "table" then return names end
		for _, path in ipairs(files) do
			local name = string.match(tostring(path), "([^/\\]+)%.json$")
			if name then table.insert(names, name) end
		end
		table.sort(names)
		return names
	end

	-- Ready-made tab: config name box, saved-config list and Save / Load / Delete buttons.
	function Window:CreateConfigTab(tabName, icon)
		local ConfigTab = Window:CreateTab(tabName or "Config", icon or "Settings")
		local selected = ""

		local function report(title, content)
			if not Window.IsDestroyed then
				Window:Notify({ Title = title, Content = tostring(content), Duration = 2.5 })
			end
		end

		local function currentName()
			if selected ~= "" then return selected end
			return "default"
		end

		ConfigTab:CreateSection("Configs")

		if type(writefile) ~= "function" or type(readfile) ~= "function" then
			ConfigTab:CreateParagraph({
				Title = "File saving unavailable",
				Content = "Your executor does not provide file functions (writefile / readfile), so configs cannot be saved or loaded.",
			})
			return ConfigTab
		end

		local nameBox = ConfigTab:CreateTextbox({
			Name = "Config name",
			Placeholder = "default",
			Callback = function(text) selected = tostring(text) end,
		})

		local savedList = ConfigTab:CreateDropdown({
			Name = "Saved configs",
			Options = Window:ListConfigs(),
			Callback = function(option)
				selected = tostring(option)
				nameBox:Set(selected)
			end,
		})

		ConfigTab:CreateButton({
			Name = "Save config",
			Callback = function()
				local ok, result = Window:SaveConfig(currentName())
				if ok then
					report("Config saved", result)
					savedList:Refresh(Window:ListConfigs())
				else
					report("Save failed", result)
				end
			end,
		})

		ConfigTab:CreateButton({
			Name = "Load config",
			Callback = function()
				local ok, result = Window:LoadConfig(currentName())
				if ok then
					report("Config loaded", tostring(result) .. " settings applied")
				else
					report("Load failed", result)
				end
			end,
		})

		ConfigTab:CreateButton({
			Name = "Delete config",
			Callback = function()
				local ok, result = Window:DeleteConfig(currentName())
				if ok then
					report("Config deleted", result)
					savedList:Refresh(Window:ListConfigs())
				else
					report("Delete failed", result)
				end
			end,
		})

		ConfigTab:CreateButton({
			Name = "Refresh list",
			Callback = function()
				savedList:Refresh(Window:ListConfigs())
			end,
		})

		return ConfigTab
	end

	-- Window Management API
	function Window:DestroyTab(tabName)
		local tabObj = Window.Tabs[tabName]
		if tabObj then
			for _, cancel in ipairs(tabObj.Cancels) do
				pcall(cancel)
				dragCancels[cancel] = nil
			end
			for _, conn in ipairs(tabObj.Connections) do
				pcall(function() conn:Disconnect() end)
			end
			for flagName, entry in pairs(tabObj.Flags or {}) do
				if Window.Flags[flagName] == entry then
					Window.Flags[flagName] = nil
				end
			end
			if tabObj.Button then tabObj.Button:Destroy() end
			if tabObj.Container then tabObj.Container:Destroy() end
			Window.Tabs[tabName] = nil

			if Window.CurrentTab == tabObj then
				Window.CurrentTab = nil
				if not Window.IsDestroyed then
					for _, t in pairs(Window.Tabs) do
						t:Activate()
						break
					end
				end
			end
		end
	end

	-- Complete Lifecycle Cleanup
	function Window:Destroy()
		if Window.IsDestroyed then return end
		Window.IsDestroyed = true

		local destroyCallbacks = Window.DestroyCallbacks
		Window.DestroyCallbacks = {}
		for _, cb in ipairs(destroyCallbacks) do
			safeCall("OnDestroy", cb)
		end
		Window.IsAnimating = false
		cancelAllDrags()

		-- Cancel all active tweens (their callbacks are already guarded by IsDestroyed)
		local tweens = Window.ActiveTweens
		Window.ActiveTweens = {}
		for _, tw in ipairs(tweens) do
			pcall(function() tw:Cancel() end)
		end

		-- Remove notification cards
		local cards = Window.ActiveNotifications
		Window.ActiveNotifications = {}
		for _, card in ipairs(cards) do
			if card and card.Parent then
				pcall(function() card:Destroy() end)
			end
		end

		-- Clean up all tabs
		local tabNames = {}
		for tabName, _ in pairs(Window.Tabs) do
			table.insert(tabNames, tabName)
		end
		for _, tabName in ipairs(tabNames) do
			Window:DestroyTab(tabName)
		end

		-- Disconnect all window connections
		for _, conn in ipairs(Window.Connections) do
			pcall(function() conn:Disconnect() end)
		end
		Window.Connections = {}

		local libIdx = table.find(DrizxUI.Windows, Window)
		if libIdx then table.remove(DrizxUI.Windows, libIdx) end

		if screenGui and not destroyedExternally then
			screenGui:Destroy()
		end
	end

	-- Optional keyboard shortcut (PC) that opens/closes the menu, e.g. ToggleKey = Enum.KeyCode.RightShift
	local toggleKey = parseKeyCode(config.ToggleKey)
	if config.ToggleKey ~= nil and not toggleKey then
		warn("[DrizxLibrary] ToggleKey is not a valid KeyCode: " .. tostring(config.ToggleKey))
	end
	if toggleKey then
		table.insert(Window.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed or Window.IsDestroyed then return end
			if input.KeyCode == toggleKey and toggleWindow then
				toggleWindow()
			end
		end))
	end

	-- Loading animation: dimmed backdrop + a card with a spinning spinner, progress bar, and status text.
	-- When done the card fades out, the floating button appears, then the window opens automatically.
	local loadingDone = config.Loading == false
	local loadingTween = nil
	local spinTween = nil
	local finishLoading = nil

	if not loadingDone then
		local loadTitle = tostring(config.LoadingTitle or titleText)
		local loadDuration = math.max(0.3, tonumber(config.LoadingDuration) or 1.8)
		local steps = {"Loading modules...", "Preparing UI...", "Almost done..."}
		if type(config.LoadingSteps) == "table" and #config.LoadingSteps > 0 then
			steps = config.LoadingSteps
		end

		floatLoadingHidden = true
		toggleBtn.Visible = false

		local backdrop = Instance.new("Frame")
		backdrop.Name = "DrizxLoadingBackdrop"
		backdrop.Size = UDim2.fromScale(1, 1)
		backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
		backdrop.BackgroundTransparency = 1
		backdrop.BorderSizePixel = 0
		backdrop.Active = true
		backdrop.ZIndex = 500
		backdrop.Parent = screenGui

		local cardW = math.clamp(getViewport().X - 40, 160, 220)
		local cardH = 118

		-- CanvasGroup so the whole card can fade in/out at once via GroupTransparency.
		local loadCard = Instance.new("CanvasGroup")
		loadCard.Name = "DrizxLoadingCard"
		loadCard.AnchorPoint = Vector2.new(0.5, 0.5)
		loadCard.Position = UDim2.fromScale(0.5, 0.5)
		loadCard.Size = UDim2.fromOffset(math.floor(cardW * 0.9), math.floor(cardH * 0.9))
		loadCard.BackgroundColor3 = Theme.Notification
		loadCard.BorderSizePixel = 0
		loadCard.GroupTransparency = 1
		loadCard.ZIndex = 501
		loadCard.Parent = screenGui

		local loadCorner = Instance.new("UICorner")
		loadCorner.CornerRadius = UDim.new(0, 12)
		loadCorner.Parent = loadCard

		local loadStroke = Instance.new("UIStroke")
		loadStroke.Color = Theme.Stroke
		loadStroke.Thickness = 1.2
		loadStroke.Parent = loadCard

		-- Spinner: dim ring + a spinning accent arc (UIGradient on a UIStroke)
		local SPIN = 34
		local ring = Instance.new("Frame")
		ring.AnchorPoint = Vector2.new(0.5, 0)
		ring.Position = UDim2.new(0.5, 0, 0, 14)
		ring.Size = UDim2.fromOffset(SPIN, SPIN)
		ring.BackgroundTransparency = 1
		ring.Parent = loadCard

		local ringCorner = Instance.new("UICorner")
		ringCorner.CornerRadius = UDim.new(1, 0)
		ringCorner.Parent = ring

		local ringStroke = Instance.new("UIStroke")
		ringStroke.Color = Theme.Stroke
		ringStroke.Thickness = 3
		ringStroke.Parent = ring

		local arc = Instance.new("Frame")
		arc.Size = UDim2.fromScale(1, 1)
		arc.BackgroundTransparency = 1
		arc.Parent = ring

		local arcCorner = Instance.new("UICorner")
		arcCorner.CornerRadius = UDim.new(1, 0)
		arcCorner.Parent = arc

		local arcStroke = Instance.new("UIStroke")
		arcStroke.Color = Theme.Accent
		arcStroke.Thickness = 3
		arcStroke.Parent = arc

		local arcGradient = Instance.new("UIGradient")
		arcGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.6, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		arcGradient.Parent = arcStroke

		local loadLogo = Instance.new("ImageLabel")
		loadLogo.AnchorPoint = Vector2.new(0.5, 0.5)
		loadLogo.Position = UDim2.fromScale(0.5, 0.5)
		loadLogo.Size = UDim2.fromOffset(14, 14)
		loadLogo.BackgroundTransparency = 1
		applyIcon(loadLogo, logoInput, iconTint(logoInput), 1)
		loadLogo.Parent = ring

		local loadTitleLbl = Instance.new("TextLabel")
		loadTitleLbl.Position = UDim2.new(0, 8, 0, 56)
		loadTitleLbl.Size = UDim2.new(1, -16, 0, 16)
		loadTitleLbl.BackgroundTransparency = 1
		loadTitleLbl.Text = loadTitle
		loadTitleLbl.TextColor3 = Theme.Text
		loadTitleLbl.TextSize = 12
		loadTitleLbl.Font = Enum.Font.GothamBold
		loadTitleLbl.TextTruncate = Enum.TextTruncate.AtEnd
		loadTitleLbl.Parent = loadCard

		local loadStatusLbl = Instance.new("TextLabel")
		loadStatusLbl.Position = UDim2.new(0, 8, 0, 73)
		loadStatusLbl.Size = UDim2.new(1, -16, 0, 14)
		loadStatusLbl.BackgroundTransparency = 1
		loadStatusLbl.Text = tostring(steps[1]) .. " 0%"
		loadStatusLbl.TextColor3 = Theme.SubText
		loadStatusLbl.TextSize = 10
		loadStatusLbl.Font = Enum.Font.GothamMedium
		loadStatusLbl.TextTruncate = Enum.TextTruncate.AtEnd
		loadStatusLbl.Parent = loadCard

		local barTrack = Instance.new("Frame")
		barTrack.Position = UDim2.new(0, 16, 0, 98)
		barTrack.Size = UDim2.new(1, -32, 0, 4)
		barTrack.BackgroundColor3 = Theme.Raised
		barTrack.BorderSizePixel = 0
		barTrack.Parent = loadCard

		local barTrackCorner = Instance.new("UICorner")
		barTrackCorner.CornerRadius = UDim.new(1, 0)
		barTrackCorner.Parent = barTrack

		local barFill = Instance.new("Frame")
		barFill.Size = UDim2.new(0, 0, 1, 0)
		barFill.BackgroundColor3 = Theme.Accent
		barFill.BorderSizePixel = 0
		barFill.Parent = barTrack

		local barFillCorner = Instance.new("UICorner")
		barFillCorner.CornerRadius = UDim.new(1, 0)
		barFillCorner.Parent = barFill

		-- Progress value 0..100 is tweened; the bar and text follow its changes.
		local progress = Instance.new("NumberValue")
		progress.Parent = loadCard
		table.insert(Window.Connections, progress.Changed:Connect(function(v)
			local pct = math.clamp(math.floor(v + 0.5), 0, 100)
			local idx = math.min(#steps, math.floor(pct / 100 * #steps) + 1)
			barFill.Size = UDim2.new(pct / 100, 0, 1, 0)
			loadStatusLbl.Text = tostring(steps[idx]) .. " " .. tostring(pct) .. "%"
		end))

		finishLoading = function()
			if loadingDone or Window.IsDestroyed then return end
			loadingDone = true
			if loadingTween then pcall(function() loadingTween:Cancel() end) end
			if spinTween then pcall(function() spinTween:Cancel() end) end

			barFill.Size = UDim2.new(1, 0, 1, 0)
			local outInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			playTween(backdrop, outInfo, {BackgroundTransparency = 1})
			playTween(loadCard, outInfo, {
				GroupTransparency = 1,
				Size = UDim2.fromOffset(math.floor(cardW * 0.9), math.floor(cardH * 0.9)),
			}, function()
				loadCard:Destroy()
				backdrop:Destroy()
				floatLoadingHidden = false
				toggleBtn.Visible = floatVisible
				if config.AutoOpen ~= false and not isOpen then
					toggleWindow()
				end
			end)
		end

		-- Enter: backdrop dims, card appears while growing
		local inInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		playTween(backdrop, TweenInfo.new(0.25), {BackgroundTransparency = 0.45})
		playTween(loadCard, inInfo, {
			GroupTransparency = 0,
			Size = UDim2.fromOffset(cardW, cardH),
		})

		-- Spinner keeps spinning until loading finishes
		spinTween = playTween(arcGradient,
			TweenInfo.new(0.9, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
			{Rotation = 360})

		loadingTween = playTween(progress,
			TweenInfo.new(loadDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{Value = 100},
			function(state)
				if state == Enum.PlaybackState.Completed then
					finishLoading()
				end
			end)
	end

	-- Skip/finish loading early (e.g. once all tabs have been created)
	function Window:FinishLoading()
		if finishLoading then finishLoading() end
	end

	return Window
end

return DrizxUI
