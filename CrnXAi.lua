--// Cornello Utility Hub NEXT LEVEL (CLEAN)
--// Full Custom UI | Modal | Theme | Debug | FPS Saver | FIXED

if getgenv().CornelloLoaded then return end
getgenv().CornelloLoaded = true

-- ================= SERVICES =================
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer

-- ================= EXECUTOR =================
local queue = queue_on_teleport or (syn and syn.queue_on_teleport)
local request = http_request or request or (syn and syn.request)

-- ================= CONFIG =================
local CFG = "cornello_config.json"

getgenv().CornelloConfig = getgenv().CornelloConfig or {
	AntiAFK = false,
	AFKDelay = 600,
	AutoExecute = true,
	AutoReconnect = true,
	ReconnectDelay = 3,
	MaxRetry = 5,
	FpsSaver = false,
	SafeMode = false,
	Theme = "Purple",
	Webhook = ""
}

local function Save()
	writefile(CFG, HttpService:JSONEncode(getgenv().CornelloConfig))
end

pcall(function()
	if isfile(CFG) then
		getgenv().CornelloConfig = HttpService:JSONDecode(readfile(CFG))
	end
end)

-- ================= UI ROOT =================
local UI = Instance.new("ScreenGui")
UI.Name = "CornelloUI"
UI.ResetOnSpawn = false
UI.IgnoreGuiInset = true
UI.Parent = CoreGui

-- ================= THEME =================
local Themes = {
	Purple = Color3.fromRGB(90,60,160),
	Dark = Color3.fromRGB(40,40,40),
	Amoled = Color3.fromRGB(0,0,0)
}
local Accent = Themes[getgenv().CornelloConfig.Theme] or Themes.Purple

-- ================= TWEEN =================
local function Tween(o,t,p)
	TweenService:Create(
		o,
		TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		p
	):Play()
end

-- ================= FLOATING ICON =================
local Icon = Instance.new("ImageButton")
Icon.Size = UDim2.fromOffset(56,56)
Icon.Position = UDim2.fromScale(0.05,0.5)
Icon.Image = "rbxassetid://4483345998"
Icon.BackgroundColor3 = Accent
Icon.BackgroundTransparency = 0.2
Icon.BorderSizePixel = 0
Icon.Parent = UI
Icon.Active = true
Instance.new("UICorner", Icon).CornerRadius = UDim.new(1,0)

-- Drag manual (stable)
do
	local dragging, dragStart, startPos
	Icon.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = i.Position
			startPos = Icon.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = i.Position - dragStart
			Icon.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end

-- ================= MAIN WINDOW =================
local Main = Instance.new("Frame")
Main.Size = UDim2.fromScale(0,0)
Main.Position = UDim2.fromScale(0.5,0.5)
Main.AnchorPoint = Vector2.new(0.5,0.5)
Main.BackgroundColor3 = Accent
Main.BackgroundTransparency = 0.15
Main.Visible = false
Main.Parent = UI
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,18)

Icon.MouseButton1Click:Connect(function()
	Main.Visible = true
	Main.Size = UDim2.fromScale(0,0)
	Tween(Main,0.25,{Size=UDim2.fromScale(0.35,0.45)})
end)

-- ================= CATEGORY LAYOUT =================
local List = Instance.new("UIListLayout", Main)
List.Padding = UDim.new(0,10)
List.HorizontalAlignment = Enum.HorizontalAlignment.Center
List.VerticalAlignment = Enum.VerticalAlignment.Top

List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	Main.CanvasSize = UDim2.fromOffset(0, List.AbsoluteContentSize.Y)
end)

-- ================= CATEGORY BUTTON =================
local function Category(name, callback)
	local B = Instance.new("TextButton")
	B.Size = UDim2.new(1,-40,0,45)
	B.Text = name
	B.BackgroundColor3 = Accent
	B.TextColor3 = Color3.new(1,1,1)
	B.Font = Enum.Font.Gotham
	B.TextSize = 15
	B.Parent = Main
	Instance.new("UICorner", B).CornerRadius = UDim.new(0,12)
	B.MouseButton1Click:Connect(callback)
end

-- ================= MODAL =================
local function Modal(title)
	local BG = Instance.new("Frame")
	BG.Size = UDim2.fromScale(1,1)
	BG.BackgroundColor3 = Color3.new(0,0,0)
	BG.BackgroundTransparency = 0.4
	BG.Parent = UI

	local M = Instance.new("Frame")
	M.Size = UDim2.fromScale(0.32,0.45)
	M.Position = UDim2.fromScale(0.5,0.5)
	M.AnchorPoint = Vector2.new(0.5,0.5)
	M.BackgroundColor3 = Accent
	M.BackgroundTransparency = 0.15
	M.Parent = BG
	Instance.new("UICorner", M).CornerRadius = UDim.new(0,16)

	local T = Instance.new("TextLabel")
	T.Text = title
	T.Size = UDim2.new(1,-20,0,40)
	T.Position = UDim2.fromOffset(10,10)
	T.TextColor3 = Color3.new(1,1,1)
	T.BackgroundTransparency = 1
	T.Font = Enum.Font.GothamBold
	T.TextSize = 16
	T.TextXAlignment = Enum.TextXAlignment.Left
	T.Parent = M

	BG.MouseButton1Click:Connect(function()
		BG:Destroy()
	end)

	M.InputBegan:Connect(function() end) -- block close when clicking modal

	return M
end

-- ================= FEATURES =================
Category("Utility", function()
	local M = Modal("Utility")

	local B = Instance.new("TextButton", M)
	B.Size = UDim2.new(1,-40,0,40)
	B.Position = UDim2.fromOffset(20,60)
	B.Text = "Anti AFK: "..(getgenv().CornelloConfig.AntiAFK and "ON" or "OFF")
	B.BackgroundColor3 = Accent
	B.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", B).CornerRadius = UDim.new(0,12)

	B.MouseButton1Click:Connect(function()
		getgenv().CornelloConfig.AntiAFK = not getgenv().CornelloConfig.AntiAFK
		B.Text = "Anti AFK: "..(getgenv().CornelloConfig.AntiAFK and "ON" or "OFF")
		Save()
	end)
end)

Category("Server", function()
	local M = Modal("Server")

	local B = Instance.new("TextButton", M)
	B.Size = UDim2.new(1,-40,0,40)
	B.Position = UDim2.fromOffset(20,60)
	B.Text = "Auto Reconnect: "..(getgenv().CornelloConfig.AutoReconnect and "ON" or "OFF")
	B.BackgroundColor3 = Accent
	B.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", B).CornerRadius = UDim.new(0,12)

	B.MouseButton1Click:Connect(function()
		getgenv().CornelloConfig.AutoReconnect = not getgenv().CornelloConfig.AutoReconnect
		B.Text = "Auto Reconnect: "..(getgenv().CornelloConfig.AutoReconnect and "ON" or "OFF")
		Save()
	end)
end)

Category("Webhook", function()
	local M = Modal("Webhook")

	local Box = Instance.new("TextBox", M)
	Box.Size = UDim2.new(1,-40,0,40)
	Box.Position = UDim2.fromOffset(20,60)
	Box.Text = getgenv().CornelloConfig.Webhook
	Box.PlaceholderText = "Discord Webhook URL"
	Box.BackgroundColor3 = Accent
	Box.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", Box).CornerRadius = UDim.new(0,12)

	Box.FocusLost:Connect(function()
		getgenv().CornelloConfig.Webhook = Box.Text
		Save()
	end)
end)

-- ================= CORE SYSTEM =================

-- Anti AFK
task.spawn(function()
	while task.wait(getgenv().CornelloConfig.AFKDelay) do
		if getgenv().CornelloConfig.AntiAFK then
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end
	end
end)

-- FPS Saver (safe)
local lastQuality
RunService.Heartbeat:Connect(function()
	if getgenv().CornelloConfig.FpsSaver then
		if not lastQuality then
			lastQuality = settings().Rendering.QualityLevel
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		end
	elseif lastQuality then
		settings().Rendering.QualityLevel = lastQuality
		lastQuality = nil
	end
end)

-- Auto Reconnect
LP.OnTeleport:Connect(function(s)
	if s == Enum.TeleportState.Failed and getgenv().CornelloConfig.AutoReconnect then
		task.wait(getgenv().CornelloConfig.ReconnectDelay)
		TeleportService:Teleport(game.PlaceId, LP)
	end
end)

-- Auto Execute
if queue and getgenv().CornelloConfig.AutoExecute then
	queue([[
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Masfadil53818/MyRoblox/main/crnloader.lua", true))()
	]])
end
