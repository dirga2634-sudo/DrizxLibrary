--[[
    DrizxLibrary v13.2.0
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

    Full documentation: see README.md
]]--

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local DrizxUI = {}
DrizxUI.__index = DrizxUI
DrizxUI.Version = "13.2.0"
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
		Background   = Color3.fromRGB(13, 17, 23),
		Card         = Color3.fromRGB(13, 17, 23),
		Surface      = Color3.fromRGB(18, 22, 31),
		Raised       = Color3.fromRGB(28, 34, 46),
		Stroke       = Color3.fromRGB(45, 55, 72),
		Accent       = Color3.fromRGB(0, 162, 255),
		Text         = Color3.fromRGB(245, 247, 250),
		SubText      = Color3.fromRGB(160, 175, 195),
		Muted        = Color3.fromRGB(110, 125, 145),
		Success      = Color3.fromRGB(46, 160, 67),
		Notification = Color3.fromRGB(16, 20, 28),
		Danger       = Color3.fromRGB(235, 87, 87),
	},
	Light = {
		Background   = Color3.fromRGB(240, 243, 247),
		Card         = Color3.fromRGB(255, 255, 255),
		Surface      = Color3.fromRGB(232, 236, 242),
		Raised       = Color3.fromRGB(214, 221, 231),
		Stroke       = Color3.fromRGB(200, 208, 220),
		Accent       = Color3.fromRGB(0, 120, 230),
		Text         = Color3.fromRGB(22, 28, 38),
		SubText      = Color3.fromRGB(88, 101, 122),
		Muted        = Color3.fromRGB(125, 138, 156),
		Success      = Color3.fromRGB(40, 150, 60),
		Notification = Color3.fromRGB(255, 255, 255),
		Danger       = Color3.fromRGB(220, 60, 60),
	},
}
DrizxUI.Themes = Themes

-- A theme can be a name ("Dark" / "Light") or an override table,
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
local IconPresets = {
	["Home"]       = "rbxassetid://10723415903",
	["Settings"]   = "rbxassetid://10723405360",
	["Chat"]       = "rbxassetid://6023426915",
	["Player"]     = "rbxassetid://10723346959",
	["Zap"]        = "rbxassetid://10723376114",
	["Search"]     = "rbxassetid://10723344270",
	["Shield"]     = "rbxassetid://10723351330",
	["Code"]       = "rbxassetid://10723381668",
	["Bell"]       = "rbxassetid://10723345749",
	["Globe"]      = "rbxassetid://10723343321",
	["Key"]        = "rbxassetid://10723348003",
	["Palette"]    = "rbxassetid://10723341398"
}

-- Accepts a preset name ("Home"), an asset id (number or numeric string),
-- "rbxassetid://123", "rbxthumb://...", "rbxasset://...", or a roblox.com/asset/?id=123 link.
-- Returns "" when the input is not a recognized icon.
local function parseIcon(iconInput)
	if iconInput == nil or iconInput == "" then return "" end
	if type(iconInput) == "number" then
		return "rbxassetid://" .. string.format("%.0f", iconInput)
	end

	local text = tostring(iconInput)
	text = (string.gsub(text, "^%s+", ""))
	text = (string.gsub(text, "%s+$", ""))

	if IconPresets[text] then return IconPresets[text] end
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

-- Preset icons are glyphs that get tinted with the theme text color;
-- custom images (asset ids) are shown as-is.
local function isPresetIcon(iconInput)
	return IconPresets[tostring(iconInput)] ~= nil
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
	local connections = {}

	local function finish(cancelled)
		if not active then return end
		active = nil
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
		onBegin(input)
	end))

	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if not active then return end
		local isMouseMove = active.UserInputType == Enum.UserInputType.MouseButton1
			and input.UserInputType == Enum.UserInputType.MouseMovement
		local isTouchMove = active.UserInputType == Enum.UserInputType.Touch
			and input == active
		if isMouseMove or isTouchMove then
			onMove(input)
		end
	end))

	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if not active then return end
		local isSame = input == active
		local isMouseUp = active.UserInputType == Enum.UserInputType.MouseButton1
			and input.UserInputType == Enum.UserInputType.MouseButton1
		if isSame or isMouseUp then
			finish(false)
		end
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
	local logoAsset  = parseIcon(config.Logo or "Zap")

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
	}
	local menuPrefW = tonumber(menuInit.Width)
	local menuPrefH = tonumber(menuInit.Height)

	local Window = {
		CurrentTab = nil,
		Minimized = false,
		Tabs = {},
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
		local icon = parseIcon(notifConfig.Icon or "Bell")

		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 56)
		card.BackgroundColor3 = Theme.Notification
		card.BorderSizePixel = 0
		card.ClipsDescendants = true
		card.ZIndex = 1001
		card.Parent = notifContainer

		table.insert(Window.ActiveNotifications, card)

		local cCorner = Instance.new("UICorner")
		cCorner.CornerRadius = UDim.new(0, 8)
		cCorner.Parent = card

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = Theme.Stroke
		cStroke.Thickness = 1
		cStroke.Parent = card

		local iconImg = Instance.new("ImageLabel")
		iconImg.Size = UDim2.new(0, 18, 0, 18)
		iconImg.Position = UDim2.new(0, 10, 0, 10)
		iconImg.BackgroundTransparency = 1
		iconImg.Image = icon
		iconImg.ImageColor3 = Theme.Accent
		iconImg.ZIndex = 1002
		iconImg.Parent = card

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(1, -44, 0, 16)
		titleLbl.Position = UDim2.new(0, 34, 0, 8)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = title
		titleLbl.TextColor3 = Theme.Text
		titleLbl.TextSize = 11
		titleLbl.Font = Enum.Font.GothamBold
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
		titleLbl.ZIndex = 1002
		titleLbl.Parent = card

		local contentLbl = Instance.new("TextLabel")
		contentLbl.Size = UDim2.new(1, -44, 0, 22)
		contentLbl.Position = UDim2.new(0, 34, 0, 24)
		contentLbl.BackgroundTransparency = 1
		contentLbl.Text = content
		contentLbl.TextColor3 = Theme.SubText
		contentLbl.TextSize = 10
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
		pBar.BackgroundColor3 = Theme.Accent
		pBar.BorderSizePixel = 0
		pBar.ZIndex = 1003
		pBar.Parent = card

		-- Tween chain: progress -> fade -> remove. No threads are left waiting.
		playTween(pBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}, function(state)
			if state ~= Enum.PlaybackState.Completed then return end
			local fadeInfo = TweenInfo.new(0.2)
			playTween(iconImg, fadeInfo, {ImageTransparency = 1})
			playTween(titleLbl, fadeInfo, {TextTransparency = 1})
			playTween(contentLbl, fadeInfo, {TextTransparency = 1})
			playTween(pBar, fadeInfo, {BackgroundTransparency = 1})
			playTween(cStroke, fadeInfo, {Transparency = 1})
			playTween(card, fadeInfo, {BackgroundTransparency = 1}, function()
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
	toggleBtn.Image = logoAsset
	toggleBtn.ImageColor3 = iconTint(config.Logo or "Zap")
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

	local windowDragStart = Vector2.zero
	local windowStartPos = Vector2.zero

	-- The drag area covers only the left side of the header, so the minimize/close buttons don't trigger a drag.
	local dragHandle = Instance.new("Frame")
	dragHandle.Name = "DragHandle"
	dragHandle.Size = UDim2.new(1, -62, 1, 0)
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
	headerIcon.Image = logoAsset
	headerIcon.ImageColor3 = iconTint(config.Logo or "Zap")
	headerIcon.ZIndex = 3
	headerIcon.Parent = topBar

	local headerTitle = Instance.new("TextLabel")
	headerTitle.Size = UDim2.new(1, -95, 1, 0)
	headerTitle.Position = UDim2.new(0, 34, 0, 0)
	headerTitle.BackgroundTransparency = 1
	headerTitle.RichText = true
	headerTitle.Text = escapeRichText(titleText) .. " <font color=\"#708090\">| " .. escapeRichText(subTitle) .. "</font>"
	headerTitle.TextColor3 = Theme.Text
	headerTitle.TextSize = 10
	headerTitle.Font = Enum.Font.GothamBold
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.TextTruncate = Enum.TextTruncate.AtEnd
	headerTitle.ZIndex = 3
	headerTitle.Parent = topBar

	-- Button icons are drawn from Frames (not the "─" / "✕" characters), because those glyphs
	-- often fail to render in the Gotham font, leaving the buttons looking empty/missing.
	local function makeHeaderButton(offsetX)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 22, 0, 22)
		btn.Position = UDim2.new(1, offsetX, 0.5, -11)
		btn.BackgroundColor3 = Theme.Raised
		btn.BackgroundTransparency = 0.4
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.ZIndex = 3
		btn.Parent = topBar

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 4)
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

	local minimizeBtn = makeHeaderButton(-54)
	local minBar = makeIconBar(minimizeBtn, 10, 0)
	hookHeaderHover(minimizeBtn, {minBar}, Theme.Accent)

	local closeBtn = makeHeaderButton(-28)
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

		local notifWidth = math.clamp(vp.X - 20, 120, 240)
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
			local img = parseIcon(opts.Icon)
			if img ~= "" then
				toggleBtn.Image = img
				toggleBtn.ImageColor3 = iconTint(opts.Icon)
			else
				warn("[DrizxLibrary] FloatingButton.Icon is not a valid preset name or asset id: " .. tostring(opts.Icon))
			end
		end

		if typeof(opts.ImageColor) == "Color3" then
			toggleBtn.ImageColor3 = opts.ImageColor
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
			local img = parseIcon(opts.Icon)
			if img ~= "" then
				headerIcon.Image = img
				headerIcon.ImageColor3 = iconTint(opts.Icon)
			else
				warn("[DrizxLibrary] Menu.Icon is not a valid preset name or asset id: " .. tostring(opts.Icon))
			end
		end

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

	-- Tab Engine
	function Window:CreateTab(tabConfig, iconArg)
		tabConfig = typeof(tabConfig) == "table" and tabConfig or { Name = tostring(tabConfig) }
		local tabNameKey = tabConfig.Name or "Tab"
		local tabNameDisplay = tostring(tabNameKey)
		local tabIcon = parseIcon(tabConfig.Icon or iconArg or "Code")

		if Window.Tabs[tabNameKey] then
			return Window.Tabs[tabNameKey]
		end

		local Tab = { Name = tabNameKey, Connections = {}, Cancels = {} }

		local tabBtn = Instance.new("TextButton")
		tabBtn.Size = UDim2.new(1, -2, 0, 30)
		tabBtn.BackgroundColor3 = Theme.Surface
		tabBtn.BackgroundTransparency = 0.5
		tabBtn.BorderSizePixel = 0
		tabBtn.Text = ""
		tabBtn.ZIndex = 3
		tabBtn.Parent = tabButtonsContainer

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 5)
		btnCorner.Parent = tabBtn

		local iconImg = Instance.new("ImageLabel")
		iconImg.Size = UDim2.new(0, 14, 0, 14)
		iconImg.Position = UDim2.new(0, 8, 0.5, -7)
		iconImg.BackgroundTransparency = 1
		iconImg.Image = tabIcon
		iconImg.ImageColor3 = Theme.SubText
		iconImg.ZIndex = 4
		iconImg.Parent = tabBtn

		local labelTxt = Instance.new("TextLabel")
		labelTxt.Size = UDim2.new(1, -30, 1, 0)
		labelTxt.Position = UDim2.new(0, 26, 0, 0)
		labelTxt.BackgroundTransparency = 1
		labelTxt.Text = tabNameDisplay
		labelTxt.TextColor3 = Theme.SubText
		labelTxt.TextSize = 10
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
		tabScroll.ScrollBarThickness = 2
		tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		tabScroll.Visible = false
		tabScroll.ZIndex = 3
		tabScroll.Parent = contentArea

		local tabLayout = Instance.new("UIListLayout")
		tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
		tabLayout.Padding = UDim.new(0, 6)
		tabLayout.Parent = tabScroll

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
					local lbl = btn:FindFirstChildOfClass("TextLabel")
					if lbl then lbl.TextColor3 = Theme.SubText end
					local img = btn:FindFirstChildOfClass("ImageLabel")
					if img then img.ImageColor3 = Theme.SubText end
				end
			end
			tabScroll.Visible = true
			playTween(tabBtn, TweenInfo.new(0.2), {
				BackgroundTransparency = 0,
				BackgroundColor3 = Theme.Raised
			})
			labelTxt.TextColor3 = Theme.Text
			iconImg.ImageColor3 = Theme.Accent
			Window.CurrentTab = Tab
		end

		table.insert(Tab.Connections, tabBtn.MouseButton1Click:Connect(function() Tab:Activate() end))

		Tab.Button = tabBtn
		Tab.Container = tabScroll
		Window.Tabs[tabNameKey] = Tab

		if not Window.CurrentTab then
			Tab:Activate()
		end

		-- Components
		function Tab:CreateSection(text)
			if type(text) == "table" then text = text.Name or text.Title or "" end
			local secLabel = Instance.new("TextLabel")
			secLabel.Size = UDim2.new(1, 0, 0, 18)
			secLabel.BackgroundTransparency = 1
			secLabel.Text = string.upper(tostring(text))
			secLabel.TextColor3 = Theme.Muted
			secLabel.TextSize = 9
			secLabel.Font = Enum.Font.GothamBold
			secLabel.TextXAlignment = Enum.TextXAlignment.Left
			secLabel.ZIndex = 4
			secLabel.Parent = tabScroll
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

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = pFrame

			local pad = Instance.new("UIPadding")
			pad.PaddingTop = UDim.new(0, 6)
			pad.PaddingBottom = UDim.new(0, 6)
			pad.PaddingLeft = UDim.new(0, 8)
			pad.PaddingRight = UDim.new(0, 8)
			pad.Parent = pFrame

			local pLayout = Instance.new("UIListLayout")
			pLayout.SortOrder = Enum.SortOrder.LayoutOrder
			pLayout.Padding = UDim.new(0, 3)
			pLayout.Parent = pFrame

			local pTitle = Instance.new("TextLabel")
			pTitle.Size = UDim2.new(1, 0, 0, 16)
			pTitle.BackgroundTransparency = 1
			pTitle.Text = tostring(title)
			pTitle.TextColor3 = Theme.Text
			pTitle.TextSize = 10
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
			descLbl.TextSize = 9
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
			local baseColor = Theme.Card
			local pressColor = Theme.Accent

			local btnFrame = Instance.new("Frame")
			btnFrame.Size = UDim2.new(1, -4, 0, 32)
			btnFrame.BackgroundColor3 = baseColor
			btnFrame.BorderSizePixel = 0
			btnFrame.ZIndex = 4
			btnFrame.Parent = tabScroll

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = btnFrame

			local trigger = Instance.new("TextButton")
			trigger.Size = UDim2.new(1, 0, 1, 0)
			trigger.BackgroundTransparency = 1
			trigger.Text = "  " .. tostring(btnText)
			trigger.TextColor3 = Theme.Text
			trigger.TextSize = 10
			trigger.Font = Enum.Font.GothamMedium
			trigger.TextXAlignment = Enum.TextXAlignment.Left
			trigger.ZIndex = 5
			trigger.Parent = btnFrame

			table.insert(Tab.Connections, trigger.MouseButton1Click:Connect(function()
				if Window.IsDestroyed then return end
				playTween(btnFrame, TweenInfo.new(0.1), {BackgroundColor3 = pressColor}, function(state)
					if state ~= Enum.PlaybackState.Completed then return end
					playTween(btnFrame, TweenInfo.new(0.2), {BackgroundColor3 = baseColor})
				end)
				safeCall("Button", callback)
			end))
		end

		function Tab:CreateToggle(toggleText, defaultState, callback)
			if type(toggleText) == "table" then
				local opts = toggleText
				toggleText = opts.Name or opts.Title or "Toggle"
				defaultState = opts.Default
				callback = opts.Callback
			end
			callback = callback or function() end
			local state = (typeof(defaultState) == "boolean" and defaultState) or false
			local onColor = Theme.Success
			local offColor = Theme.Raised

			local tFrame = Instance.new("Frame")
			tFrame.Size = UDim2.new(1, -4, 0, 32)
			tFrame.BackgroundColor3 = Theme.Card
			tFrame.BorderSizePixel = 0
			tFrame.ZIndex = 4
			tFrame.Parent = tabScroll

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = tFrame

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -50, 1, 0)
			label.Position = UDim2.new(0, 10, 0, 0)
			label.BackgroundTransparency = 1
			label.Text = tostring(toggleText)
			label.TextColor3 = Theme.Text
			label.TextSize = 10
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.ZIndex = 5
			label.Parent = tFrame

			local switchBox = Instance.new("Frame")
			switchBox.Size = UDim2.new(0, 32, 0, 16)
			switchBox.Position = UDim2.new(1, -40, 0.5, -8)
			switchBox.BackgroundColor3 = state and onColor or offColor
			switchBox.BorderSizePixel = 0
			switchBox.ZIndex = 5
			switchBox.Parent = tFrame

			local sCorner = Instance.new("UICorner")
			sCorner.CornerRadius = UDim.new(1, 0)
			sCorner.Parent = switchBox

			local dot = Instance.new("Frame")
			dot.Size = UDim2.new(0, 12, 0, 12)
			dot.Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
			dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
			trigger.ZIndex = 7
			trigger.Parent = tFrame

			local function updateToggle(newState, fireCallback)
				if Window.IsDestroyed then return end
				state = newState
				playTween(switchBox, TweenInfo.new(0.2), {BackgroundColor3 = state and onColor or offColor})
				playTween(dot, TweenInfo.new(0.2), {
					Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
				})
				if fireCallback then
					safeCall("Toggle", callback, state)
				end
			end

			table.insert(Tab.Connections, trigger.MouseButton1Click:Connect(function()
				updateToggle(not state, true)
			end))

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
			if type(sliderText) == "table" then
				local opts = sliderText
				sliderText = opts.Name or opts.Title or "Slider"
				minVal = opts.Min
				maxVal = opts.Max
				defaultVal = opts.Default
				increment = tonumber(opts.Increment)
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

			local sFrame = Instance.new("Frame")
			sFrame.Size = UDim2.new(1, -4, 0, 44)
			sFrame.BackgroundColor3 = Theme.Card
			sFrame.BorderSizePixel = 0
			sFrame.Active = true -- sink input so the ScrollingFrame doesn't scroll while the slider is being dragged
			sFrame.ZIndex = 4
			sFrame.Parent = tabScroll

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = sFrame

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -55, 0, 18)
			label.Position = UDim2.new(0, 10, 0, 4)
			label.BackgroundTransparency = 1
			label.Text = tostring(sliderText)
			label.TextColor3 = Theme.Text
			label.TextSize = 10
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.ZIndex = 5
			label.Parent = sFrame

			local valLabel = Instance.new("TextLabel")
			valLabel.Size = UDim2.new(0, 40, 0, 18)
			valLabel.Position = UDim2.new(1, -48, 0, 4)
			valLabel.BackgroundTransparency = 1
			valLabel.Text = string.format("%." .. tostring(decimals) .. "f", value)
			valLabel.TextColor3 = Theme.SubText
			valLabel.TextSize = 10
			valLabel.Font = Enum.Font.GothamBold
			valLabel.TextXAlignment = Enum.TextXAlignment.Right
			valLabel.ZIndex = 5
			valLabel.Parent = sFrame

			local track = Instance.new("Frame")
			track.Size = UDim2.new(1, -20, 0, 5)
			track.Position = UDim2.new(0, 10, 0, 28)
			track.BackgroundColor3 = Theme.Raised
			track.BorderSizePixel = 0
			track.ZIndex = 5
			track.Parent = sFrame

			local tCorner = Instance.new("UICorner")
			tCorner.CornerRadius = UDim.new(1, 0)
			tCorner.Parent = track

			local fill = Instance.new("Frame")
			fill.Size = UDim2.new((value - minVal) / (maxVal - minVal), 0, 1, 0)
			fill.BackgroundColor3 = Theme.Accent
			fill.BorderSizePixel = 0
			fill.ZIndex = 6
			fill.Parent = track

			local fCorner = Instance.new("UICorner")
			fCorner.CornerRadius = UDim.new(1, 0)
			fCorner.Parent = fill

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

			-- The whole card is a touch target (a 5px track is too hard to press on mobile)
			local dragConns = bindDrag(sFrame,
				function(input)
					lockScroll()
					updateSlider(input)
				end,
				updateSlider,
				function()
					unlockScroll()
				end
			)
			registerDrag(dragConns.cancel)
			table.insert(Tab.Cancels, dragConns.cancel)
			for _, conn in ipairs(dragConns) do
				table.insert(Tab.Connections, conn)
			end

			return {
				SetValue = function(_, val) applySliderValue(val, false) end,
				GetValue = function(_) return value end
			}
		end

		function Tab:CreateDropdown(dropConfig)
			dropConfig = type(dropConfig) == "table" and dropConfig or {}
			local callback = dropConfig.Callback or function() end

			local HEADER_H = 32
			local OPTION_H = 26
			local OPTION_GAP = 2
			local MAX_LIST_H = 130

			local options = {}
			local selected = nil
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

			local dCorner = Instance.new("UICorner")
			dCorner.CornerRadius = UDim.new(0, 6)
			dCorner.Parent = dFrame

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -134, 0, HEADER_H)
			label.Position = UDim2.new(0, 10, 0, 0)
			label.BackgroundTransparency = 1
			label.Text = tostring(dropConfig.Name or "Dropdown")
			label.TextColor3 = Theme.Text
			label.TextSize = 10
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.ZIndex = 5
			label.Parent = dFrame

			local valueLbl = Instance.new("TextLabel")
			valueLbl.Size = UDim2.new(0, 95, 0, HEADER_H)
			valueLbl.Position = UDim2.new(1, -122, 0, 0)
			valueLbl.BackgroundTransparency = 1
			valueLbl.Text = "Select..."
			valueLbl.TextColor3 = Theme.SubText
			valueLbl.TextSize = 10
			valueLbl.Font = Enum.Font.GothamMedium
			valueLbl.TextXAlignment = Enum.TextXAlignment.Right
			valueLbl.TextTruncate = Enum.TextTruncate.AtEnd
			valueLbl.ZIndex = 5
			valueLbl.Parent = dFrame

			local arrow = Instance.new("TextLabel")
			arrow.Size = UDim2.new(0, 16, 0, HEADER_H)
			arrow.Position = UDim2.new(1, -24, 0, 0)
			arrow.BackgroundTransparency = 1
			arrow.Text = "▾"
			arrow.TextColor3 = Theme.SubText
			arrow.TextSize = 12
			arrow.Font = Enum.Font.GothamBold
			arrow.ZIndex = 5
			arrow.Parent = dFrame

			local list = Instance.new("ScrollingFrame")
			list.Size = UDim2.new(1, -12, 0, 0)
			list.Position = UDim2.new(0, 6, 0, HEADER_H + 2)
			list.BackgroundTransparency = 1
			list.BorderSizePixel = 0
			list.ScrollBarThickness = 2
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
			header.ZIndex = 8
			header.Parent = dFrame

			local function applySize()
				local listH = isOpenDrop and math.min(#options * (OPTION_H + OPTION_GAP), MAX_LIST_H) or 0
				local frameH = isOpenDrop and (HEADER_H + 6 + listH) or HEADER_H
				local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
				playTween(dFrame, info, {Size = UDim2.new(1, -4, 0, frameH)})
				playTween(list, info, {Size = UDim2.new(1, -12, 0, listH)})
				playTween(arrow, info, {Rotation = isOpenDrop and 180 or 0})
			end

			local function highlight()
				for opt, btn in pairs(optionButtons) do
					btn.TextColor3 = (opt == selected) and Theme.Accent or Theme.Text
				end
			end

			local function setSelected(opt, fireCallback)
				selected = opt
				valueLbl.Text = opt or "Select..."
				highlight()
				if fireCallback and opt ~= nil then
					safeCall("Dropdown", callback, opt)
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
					btn.TextSize = 10
					btn.Font = Enum.Font.GothamMedium
					btn.TextXAlignment = Enum.TextXAlignment.Left
					btn.TextTruncate = Enum.TextTruncate.AtEnd
					btn.LayoutOrder = i
					btn.ZIndex = 6
					btn.Parent = list

					local bCorner = Instance.new("UICorner")
					bCorner.CornerRadius = UDim.new(0, 5)
					bCorner.Parent = btn

					optionButtons[opt] = btn
					table.insert(optionConns, btn.MouseButton1Click:Connect(function()
						setSelected(opt, true)
						isOpenDrop = false
						applySize()
					end))
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
			if dropConfig.Default ~= nil and table.find(options, tostring(dropConfig.Default)) then
				setSelected(tostring(dropConfig.Default), false)
			end

			return {
				Set = function(_, option)
					local text = tostring(option)
					if table.find(options, text) then
						setSelected(text, false)
					end
				end,
				Get = function(_) return selected end,
				Refresh = function(_, newOptions)
					setOptions(newOptions)
					buildOptions()
					if selected and not table.find(options, selected) then
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
			bFrame.Size = UDim2.new(1, -4, 0, 32)
			bFrame.BackgroundColor3 = Theme.Card
			bFrame.BorderSizePixel = 0
			bFrame.ZIndex = 4
			bFrame.Parent = tabScroll

			local bCorner = Instance.new("UICorner")
			bCorner.CornerRadius = UDim.new(0, 6)
			bCorner.Parent = bFrame

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(0.5, -14, 1, 0)
			label.Position = UDim2.new(0, 10, 0, 0)
			label.BackgroundTransparency = 1
			label.Text = tostring(boxConfig.Name or "Textbox")
			label.TextColor3 = Theme.Text
			label.TextSize = 10
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.ZIndex = 5
			label.Parent = bFrame

			local input = Instance.new("TextBox")
			input.Size = UDim2.new(0.5, -14, 0, 22)
			input.Position = UDim2.new(0.5, 4, 0.5, -11)
			input.BackgroundColor3 = Theme.Surface
			input.BorderSizePixel = 0
			input.ClearTextOnFocus = boxConfig.ClearOnFocus == true
			input.ClipsDescendants = true
			input.PlaceholderText = tostring(boxConfig.Placeholder or "")
			input.PlaceholderColor3 = Theme.Muted
			input.Text = tostring(boxConfig.Default or "")
			input.TextColor3 = Theme.Text
			input.TextSize = 10
			input.Font = Enum.Font.GothamMedium
			input.TextXAlignment = Enum.TextXAlignment.Left
			input.ZIndex = 5
			input.Parent = bFrame

			local iCorner = Instance.new("UICorner")
			iCorner.CornerRadius = UDim.new(0, 4)
			iCorner.Parent = input

			local iPad = Instance.new("UIPadding")
			iPad.PaddingLeft = UDim.new(0, 6)
			iPad.PaddingRight = UDim.new(0, 6)
			iPad.Parent = input

			-- The callback fires when focus is lost (Enter, tapping outside the box, or the done button on mobile).
			table.insert(Tab.Connections, input.FocusLost:Connect(function(enterPressed)
				if Window.IsDestroyed then return end
				safeCall("Textbox", callback, input.Text, enterPressed)
			end))

			return {
				Set = function(_, text) input.Text = tostring(text) end,
				Get = function(_) return input.Text end
			}
		end


		return Tab
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
		loadLogo.Image = logoAsset
		loadLogo.ImageColor3 = iconTint(config.Logo or "Zap")
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
