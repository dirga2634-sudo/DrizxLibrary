--[[
    DrizxUI Library - Production v6.0 (Fully Stabilized & Lifecycle Proof)
    Creators: absorpohonods & haibung03
]]--

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local DrizxUI = {}
DrizxUI.__index = DrizxUI

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

local function parseIcon(iconInput)
	if not iconInput or iconInput == "" then return "" end
	if IconPresets[iconInput] then return IconPresets[iconInput] end
	if tonumber(iconInput) then return "rbxassetid://" .. tostring(iconInput) end
	if string.find(tostring(iconInput), "rbxassetid://") then return iconInput end
	return ""
end

function DrizxUI:CreateWindow(config)
	config = config or {}
	local titleText  = config.Title or "Drizx Framework"
	local subTitle   = config.SubTitle or "v6.0 • Pro Edition"
	local logoAsset  = parseIcon(config.Logo or "Zap")
	
	local bgType     = config.BackgroundType or "Color"
	local bgColor    = config.BackgroundColor or Color3.fromRGB(13, 17, 23)
	local bgImage    = config.BackgroundImage or ""
	local bgTransp   = config.BackgroundTransparency or 0

	local Window = { 
		CurrentTab = nil, 
		Minimized = false, 
		Tabs = {}, 
		Connections = {},
		ActiveTweens = {},
		IsAnimating = false,
		IsDestroyed = false
	}

	local targetParent = PlayerGui

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DrizxUI_" .. tostring(math.random(10000, 99999))
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = targetParent

	-- Safe Viewport & Dynamic Sizing State
	local function getViewport()
		local cam = Workspace.CurrentCamera
		if cam then
			return cam.ViewportSize
		end
		return Vector2.new(1024, 768)
	end

	local initialVp = getViewport()
	local winWidth = math.clamp(initialVp.X - 30, 280, 480)
	local winHeight = math.clamp(initialVp.Y - 50, 220, 300)

	-- Notification Container
	local notifContainer = Instance.new("Frame")
	notifContainer.Name = "DrizxNotifContainer"
	notifContainer.Size = UDim2.new(0, math.clamp(initialVp.X - 30, 180, 240), 1, -20)
	notifContainer.Position = UDim2.new(1, -math.clamp(initialVp.X - 20, 190, 250), 0, 10)
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
		local title = notifConfig.Title or "Notifikasi"
		local content = notifConfig.Content or ""
		local duration = notifConfig.Duration or 3
		local icon = parseIcon(notifConfig.Icon or "Bell")

		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 56)
		card.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
		card.BorderSizePixel = 0
		card.ClipsDescendants = true
		card.ZIndex = 1001
		card.Parent = notifContainer

		local cCorner = Instance.new("UICorner")
		cCorner.CornerRadius = UDim.new(0, 8)
		cCorner.Parent = card

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = Color3.fromRGB(45, 55, 72)
		cStroke.Thickness = 1
		cStroke.Parent = card

		local iconImg = Instance.new("ImageLabel")
		iconImg.Size = UDim2.new(0, 18, 0, 18)
		iconImg.Position = UDim2.new(0, 10, 0, 10)
		iconImg.BackgroundTransparency = 1
		iconImg.Image = icon
		iconImg.ImageColor3 = Color3.fromRGB(0, 162, 255)
		iconImg.ZIndex = 1002
		iconImg.Parent = card

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(1, -38, 0, 16)
		titleLbl.Position = UDim2.new(0, 34, 0, 8)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = title
		titleLbl.TextColor3 = Color3.fromRGB(245, 247, 250)
		titleLbl.TextSize = 11
		titleLbl.Font = Enum.Font.GothamBold
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.ZIndex = 1002
		titleLbl.Parent = card

		local contentLbl = Instance.new("TextLabel")
		contentLbl.Size = UDim2.new(1, -38, 0, 22)
		contentLbl.Position = UDim2.new(0, 34, 0, 24)
		contentLbl.BackgroundTransparency = 1
		contentLbl.Text = content
		contentLbl.TextColor3 = Color3.fromRGB(160, 175, 195)
		contentLbl.TextSize = 10
		contentLbl.Font = Enum.Font.GothamMedium
		contentLbl.TextXAlignment = Enum.TextXAlignment.Left
		contentLbl.TextYAlignment = Enum.TextYAlignment.Top
		contentLbl.TextWrapped = true
		contentLbl.ZIndex = 1002
		contentLbl.Parent = card

		local pBar = Instance.new("Frame")
		pBar.Size = UDim2.new(1, 0, 0, 2)
		pBar.Position = UDim2.new(0, 0, 1, -2)
		pBar.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
		pBar.BorderSizePixel = 0
		pBar.ZIndex = 1003
		pBar.Parent = card

		task.spawn(function()
			if Window.IsDestroyed then return end
			local tw = TweenService:Create(pBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)})
			table.insert(Window.ActiveTweens, tw)
			tw.Completed:Connect(function()
				local idx = table.find(Window.ActiveTweens, tw)
				if idx then table.remove(Window.ActiveTweens, idx) end
			end)
			tw:Play()
			
			task.wait(duration)
			if Window.IsDestroyed then return end
			
			local fadeTw = TweenService:Create(card, TweenInfo.new(0.2), {BackgroundTransparency = 1})
			table.insert(Window.ActiveTweens, fadeTw)
			fadeTw.Completed:Connect(function()
				local idx = table.find(Window.ActiveTweens, fadeTw)
				if idx then table.remove(Window.ActiveTweens, idx) end
			end)
			fadeTw:Play()
			
			task.wait(0.2)
			if card and card.Parent then
				card:Destroy()
			end
		end)
	end

	-- Floating Toggle Button
	local toggleBtn = Instance.new("ImageButton")
	toggleBtn.Name = "DrizxToggleBtn"
	toggleBtn.Size = UDim2.new(0, 42, 0, 42)
	toggleBtn.Position = UDim2.new(0, 15, 0.5, -21)
	toggleBtn.Image = logoAsset
	toggleBtn.BackgroundTransparency = 0.15
	toggleBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
	toggleBtn.Active = true
	toggleBtn.Draggable = true
	toggleBtn.ZIndex = 200
	toggleBtn.Parent = screenGui

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(1, 0)
	toggleCorner.Parent = toggleBtn

	local toggleStroke = Instance.new("UIStroke")
	toggleStroke.Color = Color3.fromRGB(0, 162, 255)
	toggleStroke.Thickness = 1.2
	toggleStroke.Parent = toggleBtn

	-- Main Window Frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, winWidth, 0, winHeight)
	mainFrame.Position = UDim2.new(0.5, -winWidth/2, 0.5, -winHeight/2)
	mainFrame.BackgroundColor3 = bgColor
	mainFrame.BackgroundTransparency = bgTransp
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.Visible = false
	mainFrame.Parent = screenGui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 10)
	mainCorner.Parent = mainFrame

	local mainStroke = Instance.new("UIStroke")
	mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	mainStroke.Color = Color3.fromRGB(45, 55, 72)
	mainStroke.Thickness = 1.2
	mainStroke.Parent = mainFrame

	if bgType == "Image" and bgImage ~= "" then
		local bgImg = Instance.new("ImageLabel")
		bgImg.Size = UDim2.new(1, 0, 1, 0)
		bgImg.BackgroundTransparency = 1
		bgImg.Image = parseIcon(bgImage)
		bgImg.ScaleType = Enum.ScaleType.Crop
		bgImg.ZIndex = 0
		bgImg.Parent = mainFrame
	end

	-- Robust Camera & Viewport Resize Listener (Live Tracking)
	local currentCamConn = nil
	local function setupCameraListener()
		if currentCamConn then
			currentCamConn:Disconnect()
			currentCamConn = nil
		end
		local cam = Workspace.CurrentCamera
		if cam then
			currentCamConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				local newVp = cam.ViewportSize
				winWidth = math.clamp(newVp.X - 30, 280, 480)
				winHeight = math.clamp(newVp.Y - 50, 220, 300)
				if not Window.Minimized then
					mainFrame.Size = UDim2.new(0, winWidth, 0, winHeight)
				end
				notifContainer.Size = UDim2.new(0, math.clamp(newVp.X - 30, 180, 240), 1, -20)
			end)
			table.insert(Window.Connections, currentCamConn)
		end
	end

	setupCameraListener()
	local camChangeConn = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(setupCameraListener)
	table.insert(Window.Connections, camChangeConn)

	-- TopBar Header
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 38)
	topBar.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 2
	topBar.Parent = mainFrame

	local topCorner = Instance.new("UICorner")
	topCorner.CornerRadius = UDim.new(0, 10)
	topCorner.Parent = topBar

	-- Clean TopBar Dragging Logic
	local dragging, dragInput, dragStart, startPos

	local dragBeganConn = topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
		end
	end)
	table.insert(Window.Connections, dragBeganConn)

	local dragChangedConn = topBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	table.insert(Window.Connections, dragChangedConn)

	local dragGlobalConn = UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	table.insert(Window.Connections, dragGlobalConn)

	local dragEndedConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	table.insert(Window.Connections, dragEndedConn)

	local headerIcon = Instance.new("ImageLabel")
	headerIcon.Size = UDim2.new(0, 18, 0, 18)
	headerIcon.Position = UDim2.new(0, 10, 0.5, -9)
	headerIcon.BackgroundTransparency = 1
	headerIcon.Image = logoAsset
	headerIcon.ZIndex = 3
	headerIcon.Parent = topBar

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, -95, 1, 0)
	titleLbl.Position = UDim2.new(0, 34, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = titleText .. " <font color=\"#708090\">| " .. subTitle .. "</font>"
	titleLbl.RichText = true
	titleLbl.TextColor3 = Color3.fromRGB(245, 247, 250)
	titleLbl.TextSize = 10
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.ZIndex = 3
	titleLbl.Parent = topBar

	local minimizeBtn = Instance.new("TextButton")
	minimizeBtn.Size = UDim2.new(0, 22, 0, 22)
	minimizeBtn.Position = UDim2.new(1, -54, 0.5, -11)
	minimizeBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 46)
	minimizeBtn.BackgroundTransparency = 0.4
	minimizeBtn.Text = "─"
	minimizeBtn.TextColor3 = Color3.fromRGB(160, 175, 195)
	minimizeBtn.TextSize = 10
	minimizeBtn.Font = Enum.Font.GothamBold
	minimizeBtn.ZIndex = 3
	minimizeBtn.Parent = topBar

	local minCorner = Instance.new("UICorner")
	minCorner.CornerRadius = UDim.new(0, 4)
	minCorner.Parent = minimizeBtn

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 22, 0, 22)
	closeBtn.Position = UDim2.new(1, -28, 0.5, -11)
	closeBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 46)
	closeBtn.BackgroundTransparency = 0.4
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(160, 175, 195)
	closeBtn.TextSize = 10
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.ZIndex = 3
	closeBtn.Parent = topBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 4)
	closeCorner.Parent = closeBtn

	-- Sidebar & Content Layout
	local sidebarWidth = 110

	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, sidebarWidth, 1, -46)
	sidebar.Position = UDim2.new(0, 6, 0, 42)
	sidebar.BackgroundTransparency = 1
	sidebar.ZIndex = 2
	sidebar.Parent = mainFrame

	local tabButtonsContainer = Instance.new("ScrollingFrame")
	tabButtonsContainer.Size = UDim2.new(1, 0, 1, 0)
	tabButtonsContainer.BackgroundTransparency = 1
	tabButtonsContainer.BorderSizePixel = 0
	tabButtonsContainer.ScrollBarThickness = 2
	tabButtonsContainer.ZIndex = 2
	tabButtonsContainer.Parent = sidebar

	local sidebarLayout = Instance.new("UIListLayout")
	sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sidebarLayout.Padding = UDim.new(0, 4)
	sidebarLayout.Parent = tabButtonsContainer

	local sbSignal = sidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tabButtonsContainer.CanvasSize = UDim2.new(0, 0, 0, sidebarLayout.AbsoluteContentSize.Y + 5)
	end)
	table.insert(Window.Connections, sbSignal)

	local contentArea = Instance.new("Frame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, -(sidebarWidth + 18), 1, -50)
	contentArea.Position = UDim2.new(0, sidebarWidth + 12, 0, 42)
	contentArea.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
	contentArea.BackgroundTransparency = (bgType == "Image" and 0.25 or 0)
	contentArea.BorderSizePixel = 0
	contentArea.ClipsDescendants = true
	contentArea.ZIndex = 2
	contentArea.Parent = mainFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0, 8)
	contentCorner.Parent = contentArea

	local contentStroke = Instance.new("UIStroke")
	contentStroke.Color = Color3.fromRGB(45, 55, 72)
	contentStroke.Thickness = 1
	contentStroke.Parent = contentArea

	-- Window Visibility Logic
	local isOpen = false

	local function toggleWindow()
		if Window.IsAnimating or Window.IsDestroyed then return end
		Window.IsAnimating = true
		isOpen = not isOpen

		if isOpen then
			Window.Minimized = false
			sidebar.Visible = true
			contentArea.Visible = true
			mainFrame.Visible = true
			mainFrame.Size = UDim2.new(0, winWidth, 0, 0)
			local tw = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0, winWidth, 0, winHeight)})
			table.insert(Window.ActiveTweens, tw)
			tw.Completed:Connect(function()
				local idx = table.find(Window.ActiveTweens, tw)
				if idx then table.remove(Window.ActiveTweens, idx) end
			end)
			tw:Play()
			task.wait(0.3)
		else
			local tw = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0, winWidth, 0, 0)})
			table.insert(Window.ActiveTweens, tw)
			tw.Completed:Connect(function()
				local idx = table.find(Window.ActiveTweens, tw)
				if idx then table.remove(Window.ActiveTweens, idx) end
			end)
			tw:Play()
			task.wait(0.3)
			if not isOpen and mainFrame then mainFrame.Visible = false end
		end
		Window.IsAnimating = false
	end

	local function toggleMinimize()
		if not isOpen or Window.IsAnimating or Window.IsDestroyed then return end
		Window.IsAnimating = true
		Window.Minimized = not Window.Minimized

		if Window.Minimized then
			sidebar.Visible = false
			contentArea.Visible = false
			local tw = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0, winWidth, 0, 38)})
			table.insert(Window.ActiveTweens, tw)
			tw.Completed:Connect(function()
				local idx = table.find(Window.ActiveTweens, tw)
				if idx then table.remove(Window.ActiveTweens, idx) end
			end)
			tw:Play()
			task.wait(0.3)
		else
			sidebar.Visible = true
			contentArea.Visible = true
			local tw = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0, winWidth, 0, winHeight)})
			table.insert(Window.ActiveTweens, tw)
			tw.Completed:Connect(function()
				local idx = table.find(Window.ActiveTweens, tw)
				if idx then table.remove(Window.ActiveTweens, idx) end
			end)
			tw:Play()
			task.wait(0.3)
		end
		Window.IsAnimating = false
	end

	local tConn1 = toggleBtn.MouseButton1Click:Connect(toggleWindow)
	local tConn2 = closeBtn.MouseButton1Click:Connect(toggleWindow)
	local tConn3 = minimizeBtn.MouseButton1Click:Connect(toggleMinimize)
	table.insert(Window.Connections, tConn1)
	table.insert(Window.Connections, tConn2)
	table.insert(Window.Connections, tConn3)

	-- Tab Engine
	function Window:CreateTab(tabConfig)
		tabConfig = typeof(tabConfig) == "table" and tabConfig or { Name = tostring(tabConfig) }
		local tabName = tabConfig.Name or "Tab"
		local tabIcon = parseIcon(tabConfig.Icon or "Code")

		if Window.Tabs[tabName] then
			return Window.Tabs[tabName]
		end

		local Tab = { Name = tabName, Connections = {} }

		local tabBtn = Instance.new("TextButton")
		tabBtn.Size = UDim2.new(1, -2, 0, 30)
		tabBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
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
		iconImg.ImageColor3 = Color3.fromRGB(160, 175, 195)
		iconImg.ZIndex = 4
		iconImg.Parent = tabBtn

		local labelTxt = Instance.new("TextLabel")
		labelTxt.Size = UDim2.new(1, -26, 1, 0)
		labelTxt.Position = UDim2.new(0, 24, 0, 0)
		labelTxt.BackgroundTransparency = 1
		labelTxt.Text = tabName
		labelTxt.TextColor3 = Color3.fromRGB(160, 175, 195)
		labelTxt.TextSize = 10
		labelTxt.Font = Enum.Font.GothamMedium
		labelTxt.TextXAlignment = Enum.TextXAlignment.Left
		labelTxt.ZIndex = 4
		labelTxt.Parent = tabBtn

		local tabScroll = Instance.new("ScrollingFrame")
		tabScroll.Size = UDim2.new(1, -10, 1, -10)
		tabScroll.Position = UDim2.new(0, 5, 0, 5)
		tabScroll.BackgroundTransparency = 1
		tabScroll.BorderSizePixel = 0
		tabScroll.ScrollBarThickness = 2
		tabScroll.Visible = false
		tabScroll.ZIndex = 3
		tabScroll.Parent = contentArea

		local tabLayout = Instance.new("UIListLayout")
		tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
		tabLayout.Padding = UDim.new(0, 6)
		tabLayout.Parent = tabScroll

		local tlSignal = tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			tabScroll.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 8)
		end)
		table.insert(Tab.Connections, tlSignal)

		function Tab:Activate()
			for _, child in ipairs(contentArea:GetChildren()) do
				if child:IsA("ScrollingFrame") then child.Visible = false end
			end
			for _, btn in ipairs(tabButtonsContainer:GetChildren()) do
				if btn:IsA("TextButton") then
					local tw = TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.5})
					table.insert(Window.ActiveTweens, tw)
					tw:Play()
					if btn:FindFirstChild("TextLabel") then btn.TextLabel.TextColor3 = Color3.fromRGB(160, 175, 195) end
					if btn:FindFirstChild("ImageLabel") then btn.ImageLabel.ImageColor3 = Color3.fromRGB(160, 175, 195) end
				end
			end
			tabScroll.Visible = true
			local tw2 = TweenService:Create(tabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(28, 34, 46)})
			table.insert(Window.ActiveTweens, tw2)
			tw2:Play()
			labelTxt.TextColor3 = Color3.fromRGB(245, 247, 250)
			iconImg.ImageColor3 = Color3.fromRGB(0, 162, 255)
			Window.CurrentTab = Tab
		end

		local clickConn = tabBtn.MouseButton1Click:Connect(function() Tab:Activate() end)
		table.insert(Tab.Connections, clickConn)

		Tab.Button = tabBtn
		Tab.Container = tabScroll
		Window.Tabs[tabName] = Tab

		if not Window.CurrentTab then
			Tab:Activate()
		end

		-- Components
		function Tab:CreateSection(text)
			local secLabel = Instance.new("TextLabel")
			secLabel.Size = UDim2.new(1, 0, 0, 18)
			secLabel.BackgroundTransparency = 1
			secLabel.Text = string.upper(text)
			secLabel.TextColor3 = Color3.fromRGB(110, 125, 145)
			secLabel.TextSize = 9
			secLabel.Font = Enum.Font.GothamBold
			secLabel.TextXAlignment = Enum.TextXAlignment.Left
			secLabel.ZIndex = 4
			secLabel.Parent = tabScroll
		end

		function Tab:CreateParagraph(title, desc)
			local pFrame = Instance.new("Frame")
			pFrame.Size = UDim2.new(1, -4, 0, 0)
			pFrame.AutomaticSize = Enum.AutomaticSize.Y
			pFrame.BackgroundColor3 = Color3.fromRGB(13, 17, 23)
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

			local titleLbl = Instance.new("TextLabel")
			titleLbl.Size = UDim2.new(1, 0, 0, 16)
			titleLbl.BackgroundTransparency = 1
			titleLbl.Text = title
			titleLbl.TextColor3 = Color3.fromRGB(245, 247, 250)
			titleLbl.TextSize = 10
			titleLbl.Font = Enum.Font.GothamBold
			titleLbl.TextXAlignment = Enum.TextXAlignment.Left
			titleLbl.ZIndex = 5
			titleLbl.Parent = pFrame

			local descLbl = Instance.new("TextLabel")
			descLbl.Size = UDim2.new(1, 0, 0, 0)
			descLbl.AutomaticSize = Enum.AutomaticSize.Y
			descLbl.BackgroundTransparency = 1
			descLbl.Text = desc
			descLbl.TextColor3 = Color3.fromRGB(160, 175, 195)
			descLbl.TextSize = 9
			descLbl.Font = Enum.Font.GothamMedium
			descLbl.TextXAlignment = Enum.TextXAlignment.Left
			descLbl.TextYAlignment = Enum.TextYAlignment.Top
			descLbl.TextWrapped = true
			descLbl.ZIndex = 5
			descLbl.Parent = pFrame
		end

		function Tab:CreateButton(btnText, callback)
			callback = callback or function() end
			local btnFrame = Instance.new("Frame")
			btnFrame.Size = UDim2.new(1, -4, 0, 32)
			btnFrame.BackgroundColor3 = Color3.fromRGB(13, 17, 23)
			btnFrame.BorderSizePixel = 0
			btnFrame.ZIndex = 4
			btnFrame.Parent = tabScroll

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = btnFrame

			local trigger = Instance.new("TextButton")
			trigger.Size = UDim2.new(1, 0, 1, 0)
			trigger.BackgroundTransparency = 1
			trigger.Text = "  " .. btnText
			trigger.TextColor3 = Color3.fromRGB(245, 247, 250)
			trigger.TextSize = 10
			trigger.Font = Enum.Font.GothamMedium
			trigger.TextXAlignment = Enum.TextXAlignment.Left
			trigger.ZIndex = 5
			trigger.Parent = btnFrame

			local btnConn = trigger.MouseButton1Click:Connect(function()
				local tw1 = TweenService:Create(btnFrame, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(0, 162, 255)})
				tw1:Play()
				task.wait(0.1)
				local tw2 = TweenService:Create(btnFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(13, 17, 23)})
				tw2:Play()
				pcall(callback)
			end)
			table.insert(Tab.Connections, btnConn)
		end

		function Tab:CreateToggle(toggleText, defaultState, callback)
			callback = callback or function() end
			local state = (typeof(defaultState) == "boolean" and defaultState) or false

			local tFrame = Instance.new("Frame")
			tFrame.Size = UDim2.new(1, -4, 0, 32)
			tFrame.BackgroundColor3 = Color3.fromRGB(13, 17, 23)
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
			label.Text = toggleText
			label.TextColor3 = Color3.fromRGB(245, 247, 250)
			label.TextSize = 10
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.ZIndex = 5
			label.Parent = tFrame

			local switchBox = Instance.new("Frame")
			switchBox.Size = UDim2.new(0, 32, 0, 16)
			switchBox.Position = UDim2.new(1, -40, 0.5, -8)
			switchBox.BackgroundColor3 = state and Color3.fromRGB(46, 160, 67) or Color3.fromRGB(28, 34, 46)
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

			local tConn = trigger.MouseButton1Click:Connect(function()
				state = not state
				TweenService:Create(switchBox, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(46, 160, 67) or Color3.fromRGB(28, 34, 46)}):Play()
				TweenService:Create(dot, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}):Play()
				pcall(callback, state)
			end)
			table.insert(Tab.Connections, tConn)
		end

		function Tab:CreateSlider(sliderText, minVal, maxVal, defaultVal, callback)
			callback = callback or function() end
			minVal = tonumber(minVal) or 0
			maxVal = tonumber(maxVal) or 100
			if maxVal <= minVal then maxVal = minVal + 1 end
			
			local value = math.clamp(tonumber(defaultVal) or minVal, minVal, maxVal)

			local sFrame = Instance.new("Frame")
			sFrame.Size = UDim2.new(1, -4, 0, 44)
			sFrame.BackgroundColor3 = Color3.fromRGB(13, 17, 23)
			sFrame.BorderSizePixel = 0
			sFrame.ZIndex = 4
			sFrame.Parent = tabScroll

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = sFrame

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -55, 0, 18)
			label.Position = UDim2.new(0, 10, 0, 4)
			label.BackgroundTransparency = 1
			label.Text = sliderText
			label.TextColor3 = Color3.fromRGB(245, 247, 250)
			label.TextSize = 10
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.ZIndex = 5
			label.Parent = sFrame

			local valLabel = Instance.new("TextLabel")
			valLabel.Size = UDim2.new(0, 40, 0, 18)
			valLabel.Position = UDim2.new(1, -48, 0, 4)
			valLabel.BackgroundTransparency = 1
			valLabel.Text = string.format("%.1f", value)
			valLabel.TextColor3 = Color3.fromRGB(160, 175, 195)
			valLabel.TextSize = 10
			valLabel.Font = Enum.Font.GothamBold
			valLabel.TextXAlignment = Enum.TextXAlignment.Right
			valLabel.ZIndex = 5
			valLabel.Parent = sFrame

			local track = Instance.new("Frame")
			track.Size = UDim2.new(1, -20, 0, 5)
			track.Position = UDim2.new(0, 10, 0, 28)
			track.BackgroundColor3 = Color3.fromRGB(28, 34, 46)
			track.BorderSizePixel = 0
			track.ZIndex = 5
			track.Parent = sFrame

			local tCorner = Instance.new("UICorner")
			tCorner.CornerRadius = UDim.new(1, 0)
			tCorner.Parent = track

			local fill = Instance.new("Frame")
			fill.Size = UDim2.new((value - minVal) / (maxVal - minVal), 0, 1, 0)
			fill.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
			fill.BorderSizePixel = 0
			fill.ZIndex = 6
			fill.Parent = track

			local fCorner = Instance.new("UICorner")
			fCorner.CornerRadius = UDim.new(1, 0)
			fCorner.Parent = fill

			local activeInput = nil
			local function updateSlider(input)
				local trackSize = track.AbsoluteSize.X
				if trackSize <= 0 then return end
				local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / trackSize, 0, 1)
				value = minVal + (maxVal - minVal) * pos
				valLabel.Text = string.format("%.1f", value)
				fill.Size = UDim2.new(pos, 0, 1, 0)
				pcall(callback, value)
			end

			local sBegan = track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					activeInput = input
					updateSlider(input)
				end
			end)
			table.insert(Tab.Connections, sBegan)

			local sChanged = UserInputService.InputChanged:Connect(function(input)
				if activeInput then
					if input == activeInput or input.UserInputType == Enum.UserInputType.MouseMovement then
						updateSlider(input)
					end
				end
			end)
			table.insert(Tab.Connections, sChanged)

			local sEnded = UserInputService.InputEnded:Connect(function(input)
				if activeInput and (input == activeInput or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
					activeInput = nil
				end
			end)
			table.insert(Tab.Connections, sEnded)
		end

		return Tab
	end

	-- Window Management API (Safe Iteration)
	function Window:DestroyTab(tabName)
		local tabObj = Window.Tabs[tabName]
		if tabObj then
			for _, conn in ipairs(tabObj.Connections) do
				pcall(function() conn:Disconnect() end)
			end
			if tabObj.Button then tabObj.Button:Destroy() end
			if tabObj.Container then tabObj.Container:Destroy() end
			Window.Tabs[tabName] = nil
			
			if Window.CurrentTab == tabObj then
				Window.CurrentTab = nil
				for _, t in pairs(Window.Tabs) do
					t:Activate()
					break
				end
			end
		end
	end

	-- Complete Lifecycle Cleanup
	function Window:Destroy()
		Window.IsDestroyed = true
		for _, tw in ipairs(Window.ActiveTweens) do
			pcall(function() tw:Cancel() end)
		end
		Window.ActiveTweens = {}

		local tabNames = {}
		for tabName, _ in pairs(Window.Tabs) do
			table.insert(tabNames, tabName)
		end
		for _, tabName in ipairs(tabNames) do
			Window:DestroyTab(tabName)
		end

		for _, conn in ipairs(Window.Connections) do
			pcall(function() conn:Disconnect() end)
		end
		Window.Connections = {}

		if screenGui then
			screenGui:Destroy()
		end
	end

	return Window
end

return DrizxUI
