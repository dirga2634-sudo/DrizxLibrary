--[[
    DrizxUI Library v12.1.3
    Creators: absorpohonods & haibung03

    Perubahan v12.1.3 (patch):
    - Slider tidak lagi memaksa ScrollingEnabled = true: nilai asli disimpan dan dipulihkan lewat
      penghitung kunci per tab (aman untuk dua slider yang digeser bersamaan).

    Perubahan v12.1.2 (patch):
    - Lebar sidebar dibatasi supaya area konten selalu punya ruang minimum (computeSidebarWidth).
    - Notifikasi memudar utuh (kartu, ikon, teks, progress bar, dan garis tepi).
    - Koneksi kamera lama dihapus dari Window.Connections saat diputus.

    Perubahan v12.1.1 (patch):
    - Area drag jendela dipisah dari tombol header (minimize/close tidak ikut memicu drag).
    - bindDrag bisa dibatalkan & mendeteksi akhir drag yang terlewat. Drag dibatalkan otomatis saat
      jendela dibuka/ditutup/diminimize, ganti tab, atau Destroy() -> scroll tidak bisa macet.
    - Ukuran minimum jendela memakai batas desain (220x170) dan tidak pernah melebihi viewport.
    - Destroy() mereset IsAnimating; ScreenGui yang dihancurkan dari luar ikut membersihkan semua koneksi.

    Perubahan v12.1:
    - Drag jendela utama, tombol melayang, dan slider kini pakai satu helper (bindDrag)
      dengan pola input yang sama untuk mouse & touch.
    - Tombol melayang: clamp Y diperbaiki (posisi dipakai dalam pixel, bukan campur scale).
    - ScreenGui.IgnoreGuiInset = true supaya AbsolutePosition, input.Position, dan
      ViewportSize berada di ruang koordinat yang sama.
    - Ukuran jendela & sidebar adaptif, tidak lagi melebihi layar kecil.
    - Notifikasi adaptif + tanpa thread menunggu (rantai Tween.Completed), jadi Destroy() bersih.
    - Judul & subjudul di-escape sebelum masuk RichText.
    - Callback user dibungkus pcall + warn supaya error tidak hilang diam-diam.
    - Slider: seluruh kartu jadi area sentuh, scroll dimatikan saat slider digeser.
]]--

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local DrizxUI = {}
DrizxUI.__index = DrizxUI

local TOPBAR_H = 38
local TOGGLE_SIZE = 42
local DRAG_THRESHOLD = 6
local MIN_WIN_W = 220
local MIN_WIN_H = 170
local MIN_CONTENT_W = 100

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
		warn("[DrizxUI] Error di callback " .. label .. ": " .. tostring(err))
	end
end

local function computeSidebarWidth(w)
	local sw = math.clamp(math.floor(w * 0.28), 80, 110)
	-- Sidebar mengalah kalau area konten bakal kurang dari MIN_CONTENT_W
	return math.min(sw, math.max(48, w - 18 - MIN_CONTENT_W))
end

local function computeWindowSize(vp)
	local w = math.clamp(vp.X - 20, math.min(MIN_WIN_W, vp.X), 480)
	local h = math.clamp(vp.Y - 40, math.min(MIN_WIN_H, vp.Y), 300)
	return w, h
end

-- Helper drag universal (mouse + touch). Mengembalikan daftar koneksi;
-- field .cancel berisi fungsi untuk membatalkan drag yang sedang berjalan.
-- onEnd(cancelled): cancelled = true bila drag dibatalkan paksa (bukan dilepas oleh user).
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
			-- Event "lepas" bisa terlewat (misalnya mouse dilepas di luar jendela).
			-- Kalau drag lama sudah berstatus selesai, bersihkan dulu lalu mulai yang baru.
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

function DrizxUI:CreateWindow(config)
	config = config or {}
	local titleText  = tostring(config.Title or "Drizx Framework")
	local subTitle   = tostring(config.SubTitle or "v12.1.3")
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
		ActiveNotifications = {},
		IsAnimating = false,
		IsDestroyed = false
	}

	local dragCancels = {} -- set: [fungsi cancel] = true

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

	-- Tween terlacak: otomatis dibatalkan oleh Destroy(), callback tidak jalan setelah destroy.
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

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DrizxUI_" .. tostring(math.random(10000, 99999))
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = PlayerGui

	-- Kalau ScreenGui dihapus dari luar (misalnya script lain), bersihkan semua koneksi juga.
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
	local winWidth, winHeight = computeWindowSize(initialVp)
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

	-- Notification Container (ukuran/posisi diatur oleh applyLayout)
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
		local title = tostring(notifConfig.Title or "Notifikasi")
		local content = tostring(notifConfig.Content or "")
		local duration = math.max(0.5, tonumber(notifConfig.Duration) or 3)
		local icon = parseIcon(notifConfig.Icon or "Bell")

		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 56)
		card.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
		card.BorderSizePixel = 0
		card.ClipsDescendants = true
		card.ZIndex = 1001
		card.Parent = notifContainer

		table.insert(Window.ActiveNotifications, card)

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
		titleLbl.Size = UDim2.new(1, -44, 0, 16)
		titleLbl.Position = UDim2.new(0, 34, 0, 8)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = title
		titleLbl.TextColor3 = Color3.fromRGB(245, 247, 250)
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
		contentLbl.TextColor3 = Color3.fromRGB(160, 175, 195)
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
		pBar.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
		pBar.BorderSizePixel = 0
		pBar.ZIndex = 1003
		pBar.Parent = card

		-- Rantai tween: progress -> fade -> hapus. Tidak ada thread yang menunggu.
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

	-- Floating Toggle Button (drag + tap)
	local toggleBtn = Instance.new("ImageButton")
	toggleBtn.Name = "DrizxToggleBtn"
	toggleBtn.Size = UDim2.new(0, TOGGLE_SIZE, 0, TOGGLE_SIZE)
	toggleBtn.Position = UDim2.fromOffset(15, math.floor(initialVp.Y / 2 - TOGGLE_SIZE / 2))
	toggleBtn.Image = logoAsset
	toggleBtn.AutoButtonColor = false
	toggleBtn.BackgroundTransparency = 0.15
	toggleBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
	toggleBtn.Active = true
	toggleBtn.ZIndex = 200
	toggleBtn.Parent = screenGui

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(1, 0)
	toggleCorner.Parent = toggleBtn

	local toggleStroke = Instance.new("UIStroke")
	toggleStroke.Color = Color3.fromRGB(0, 162, 255)
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
			local newX = math.clamp(toggleStartPos.X + delta.X, 0, math.max(0, vp.X - TOGGLE_SIZE))
			local newY = math.clamp(toggleStartPos.Y + delta.Y, 0, math.max(0, vp.Y - TOGGLE_SIZE))
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

	-- TopBar Header (drag jendela)
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, TOPBAR_H)
	topBar.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 2
	topBar.Parent = mainFrame

	local topCorner = Instance.new("UICorner")
	topCorner.CornerRadius = UDim.new(0, 10)
	topCorner.Parent = topBar

	local windowDragStart = Vector2.zero
	local windowStartPos = Vector2.zero

	-- Area drag hanya di sisi kiri header, supaya tombol minimize/close tidak ikut memicu drag.
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
	headerIcon.ZIndex = 3
	headerIcon.Parent = topBar

	local headerTitle = Instance.new("TextLabel")
	headerTitle.Size = UDim2.new(1, -95, 1, 0)
	headerTitle.Position = UDim2.new(0, 34, 0, 0)
	headerTitle.BackgroundTransparency = 1
	headerTitle.RichText = true
	headerTitle.Text = escapeRichText(titleText) .. " <font color=\"#708090\">| " .. escapeRichText(subTitle) .. "</font>"
	headerTitle.TextColor3 = Color3.fromRGB(245, 247, 250)
	headerTitle.TextSize = 10
	headerTitle.Font = Enum.Font.GothamBold
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.TextTruncate = Enum.TextTruncate.AtEnd
	headerTitle.ZIndex = 3
	headerTitle.Parent = topBar

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

	-- Sidebar & Content Layout (ukuran diatur oleh applyLayout)
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

	-- Layout responsif: dipanggil saat viewport berubah & setelah animasi selesai
	applyLayout = function()
		if Window.IsDestroyed then return end
		local vp = getViewport()
		winWidth, winHeight = computeWindowSize(vp)
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

		local tx = math.clamp(toggleBtn.Position.X.Offset, 0, math.max(0, vp.X - TOGGLE_SIZE))
		local ty = math.clamp(toggleBtn.Position.Y.Offset, 0, math.max(0, vp.Y - TOGGLE_SIZE))
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

	table.insert(Window.Connections, closeBtn.MouseButton1Click:Connect(toggleWindow))
	table.insert(Window.Connections, minimizeBtn.MouseButton1Click:Connect(toggleMinimize))

	-- Tab Engine
	function Window:CreateTab(tabConfig)
		tabConfig = typeof(tabConfig) == "table" and tabConfig or { Name = tostring(tabConfig) }
		local tabNameKey = tabConfig.Name or "Tab"
		local tabNameDisplay = tostring(tabNameKey)
		local tabIcon = parseIcon(tabConfig.Icon or "Code")

		if Window.Tabs[tabNameKey] then
			return Window.Tabs[tabNameKey]
		end

		local Tab = { Name = tabNameKey, Connections = {}, Cancels = {} }

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
		labelTxt.Size = UDim2.new(1, -30, 1, 0)
		labelTxt.Position = UDim2.new(0, 26, 0, 0)
		labelTxt.BackgroundTransparency = 1
		labelTxt.Text = tabNameDisplay
		labelTxt.TextColor3 = Color3.fromRGB(160, 175, 195)
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

		-- Kunci scroll per tab: nilai asli ScrollingEnabled disimpan saat kunci pertama dipasang
		-- dan dipulihkan saat kunci terakhir dilepas.
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
					if lbl then lbl.TextColor3 = Color3.fromRGB(160, 175, 195) end
					local img = btn:FindFirstChildOfClass("ImageLabel")
					if img then img.ImageColor3 = Color3.fromRGB(160, 175, 195) end
				end
			end
			tabScroll.Visible = true
			playTween(tabBtn, TweenInfo.new(0.2), {
				BackgroundTransparency = 0,
				BackgroundColor3 = Color3.fromRGB(28, 34, 46)
			})
			labelTxt.TextColor3 = Color3.fromRGB(245, 247, 250)
			iconImg.ImageColor3 = Color3.fromRGB(0, 162, 255)
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
			local secLabel = Instance.new("TextLabel")
			secLabel.Size = UDim2.new(1, 0, 0, 18)
			secLabel.BackgroundTransparency = 1
			secLabel.Text = string.upper(tostring(text))
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

			local pTitle = Instance.new("TextLabel")
			pTitle.Size = UDim2.new(1, 0, 0, 16)
			pTitle.BackgroundTransparency = 1
			pTitle.Text = tostring(title)
			pTitle.TextColor3 = Color3.fromRGB(245, 247, 250)
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
			local baseColor = Color3.fromRGB(13, 17, 23)
			local pressColor = Color3.fromRGB(0, 162, 255)

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
			trigger.TextColor3 = Color3.fromRGB(245, 247, 250)
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
			callback = callback or function() end
			local state = (typeof(defaultState) == "boolean" and defaultState) or false
			local onColor = Color3.fromRGB(46, 160, 67)
			local offColor = Color3.fromRGB(28, 34, 46)

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
			label.Text = tostring(toggleText)
			label.TextColor3 = Color3.fromRGB(245, 247, 250)
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
			callback = callback or function() end
			minVal = tonumber(minVal) or 0
			maxVal = tonumber(maxVal) or 100
			if maxVal <= minVal then maxVal = minVal + 1 end

			local value = math.clamp(tonumber(defaultVal) or minVal, minVal, maxVal)

			local sFrame = Instance.new("Frame")
			sFrame.Size = UDim2.new(1, -4, 0, 44)
			sFrame.BackgroundColor3 = Color3.fromRGB(13, 17, 23)
			sFrame.BorderSizePixel = 0
			sFrame.Active = true -- sink input supaya ScrollingFrame tidak ikut menggulung saat slider digeser
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
			label.TextColor3 = Color3.fromRGB(245, 247, 250)
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

			local function applySliderValue(newValue, fireCallback)
				if Window.IsDestroyed then return end
				local num = tonumber(newValue)
				if not num then return end
				value = math.clamp(num, minVal, maxVal)
				local pos = (value - minVal) / (maxVal - minVal)
				valLabel.Text = string.format("%.1f", value)
				fill.Size = UDim2.new(pos, 0, 1, 0)
				if fireCallback then
					safeCall("Slider", callback, value)
				end
			end

			local function updateSlider(input)
				local trackSize = track.AbsoluteSize.X
				if trackSize <= 0 then return end
				local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / trackSize, 0, 1)
				applySliderValue(minVal + (maxVal - minVal) * pos, true)
			end

			-- Seluruh kartu jadi area sentuh (track setebal 5px terlalu sulit ditekan di HP)
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
		Window.IsAnimating = false
		cancelAllDrags()

		-- Batalkan semua tween aktif (callback-nya sudah dijaga IsDestroyed)
		local tweens = Window.ActiveTweens
		Window.ActiveTweens = {}
		for _, tw in ipairs(tweens) do
			pcall(function() tw:Cancel() end)
		end

		-- Hapus kartu notifikasi
		local cards = Window.ActiveNotifications
		Window.ActiveNotifications = {}
		for _, card in ipairs(cards) do
			if card and card.Parent then
				pcall(function() card:Destroy() end)
			end
		end

		-- Bersihkan semua tab
		local tabNames = {}
		for tabName, _ in pairs(Window.Tabs) do
			table.insert(tabNames, tabName)
		end
		for _, tabName in ipairs(tabNames) do
			Window:DestroyTab(tabName)
		end

		-- Putus semua koneksi window
		for _, conn in ipairs(Window.Connections) do
			pcall(function() conn:Disconnect() end)
		end
		Window.Connections = {}

		if screenGui and not destroyedExternally then
			screenGui:Destroy()
		end
	end

	return Window
end

return DrizxUI
