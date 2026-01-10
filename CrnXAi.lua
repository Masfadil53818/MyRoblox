--// Cornello Utility Hub NEXT LEVEL
--// Full Custom UI | Modal | Slider | Theme | Debug | FPS Saver

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
local UI = Instance.new("ScreenGui", CoreGui)
UI.Name = "CornelloUI"
UI.ResetOnSpawn = false

-- ================= THEME =================
local Themes = {
	Purple = Color3.fromRGB(90,60,160),
	Dark = Color3.fromRGB(40,40,40),
	Amoled = Color3.fromRGB(0,0,0)
}

local Accent = Themes[getgenv().CornelloConfig.Theme] or Themes.Purple

-- ================= TWEEN =================
local function Tween(o,t,p)
	TweenService:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),p):Play()
end

-- ================= LOG SYSTEM =================
local Logs = {}
local function Log(msg)
	table.insert(Logs, os.date("%X").." | "..msg)
end

-- ================= FLOATING ICON =================
local Icon = Instance.new("ImageButton", UI)
Icon.Size = UDim2.fromOffset(56,56)
Icon.Position = UDim2.fromScale(0.05,0.5)
Icon.Image = "rbxassetid://4483345998"
Icon.BackgroundColor3 = Accent
Icon.BackgroundTransparency = 0.2
Icon.Draggable = true
Icon.Active = true
Icon.BorderSizePixel = 0
Instance.new("UICorner", Icon).CornerRadius = UDim.new(1,0)

-- ================= MAIN WINDOW =================
local Main = Instance.new("Frame", UI)
Main.Size = UDim2.fromScale(0,0)
Main.Position = UDim2.fromScale(0.5,0.5)
Main.AnchorPoint = Vector2.new(0.5,0.5)
Main.BackgroundColor3 = Accent
Main.BackgroundTransparency = 0.15
Main.Visible = false
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,18)

Icon.MouseButton1Click:Connect(function()
	Main.Visible = true
	Main.Size = UDim2.fromScale(0,0)
	Tween(Main,0.25,{Size=UDim2.fromScale(0.35,0.45)})
end)

-- ================= CATEGORY =================
local function Category(name, callback)
	local B = Instance.new("TextButton", Main)
	B.Size = UDim2.new(1,-40,0,45)
	B.Position = UDim2.fromOffset(20, (#Main:GetChildren()-1)*55 + 20)
	B.Text = name
	B.BackgroundColor3 = Accent
	B.TextColor3 = Color3.new(1,1,1)
	B.Font = Enum.Font.Gotham
	B.TextSize = 15
	Instance.new("UICorner", B).CornerRadius = UDim.new(0,12)
	B.MouseButton1Click:Connect(callback)
end

-- ================= MODAL =================
local function Modal(title)
	local BG = Instance.new("Frame", UI)
	BG.Size = UDim2.fromScale(1,1)
	BG.BackgroundColor3 = Color3.new(0,0,0)
	BG.BackgroundTransparency = 0.4

	local M = Instance.new("Frame", BG)
	M.Size = UDim2.fromScale(0.32,0.45)
	M.Position = UDim2.fromScale(0.5,0.5)
	M.AnchorPoint = Vector2.new(0.5,0.5)
	M.BackgroundColor3 = Accent
	M.BackgroundTransparency = 0.15
	Instance.new("UICorner", M).CornerRadius = UDim.new(0,16)

	local T = Instance.new("TextLabel", M)
	T.Text = title
	T.Size = UDim2.new(1,-20,0,40)
	T.Position = UDim2.fromOffset(10,10)
	T.TextColor3 = Color3.new(1,1,1)
	T.BackgroundTransparency = 1
	T.Font = Enum.Font.GothamBold
	T.TextSize = 16
	T.TextXAlignment = Left

	BG.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			BG:Destroy()
		end
	end)

	return M
end

-- ================= FEATURES =================

Category("Utility", function()
	local M = Modal("Utility")
	Log("Open Utility")

	-- Anti AFK
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
	Log("Open Server")

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
	Log("Open Webhook")

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

-- ================= CORE =================

-- Anti AFK
task.spawn(function()
	while task.wait(getgenv().CornelloConfig.AFKDelay) do
		if getgenv().CornelloConfig.AntiAFK then
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end
	end
end)

-- FPS Saver
RunService.RenderStepped:Connect(function()
	if getgenv().CornelloConfig.FpsSaver then
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
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
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Masfadil53818/MyRoblox/main/crnloader.lua",true))()
	]])
end

Log("Script Loaded")
