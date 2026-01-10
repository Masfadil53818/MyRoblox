--// Cornello Utility Hub ULTIMATE
--// Stable | Animated | Webhook | FPS Boost | Fixed AFK

if getgenv().CornelloLoaded then return end
getgenv().CornelloLoaded = true

-- ================= SERVICES =================
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local request = http_request or request or (syn and syn.request)

-- ================= CONFIG =================
local CFG = "cornello_config.json"
getgenv().CornelloConfig = {
	AntiAFK = false,
	AutoReconnect = true,
	AutoSave = true,
	FPSBoost = "OFF",
	WebhookEnabled = false,
	WebhookURL = "",
	Theme = "Purple"
}

pcall(function()
	if isfile(CFG) then
		getgenv().CornelloConfig = HttpService:JSONDecode(readfile(CFG))
	end
end)

local function Save()
	if getgenv().CornelloConfig.AutoSave then
		writefile(CFG, HttpService:JSONEncode(getgenv().CornelloConfig))
	end
end

-- ================= THEME =================
local Themes = {
	Purple = {
		Accent = Color3.fromRGB(140,90,220),
		Dark = Color3.fromRGB(28,28,34)
	},
	Blue = {
		Accent = Color3.fromRGB(80,140,255),
		Dark = Color3.fromRGB(24,26,32)
	}
}

local Theme = Themes[getgenv().CornelloConfig.Theme]

-- ================= UI ROOT =================
local UI = Instance.new("ScreenGui", CoreGui)
UI.Name = "CornelloUI"
UI.ResetOnSpawn = false

local function Tween(o,t,p)
	TweenService:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),p):Play()
end

-- ================= FLOAT ICON (LOGO C) =================
local Icon = Instance.new("TextButton", UI)
Icon.Size = UDim2.fromOffset(56,56)
Icon.Position = UDim2.fromScale(0.05,0.5)
Icon.Text = "C"
Icon.Font = Enum.Font.GothamBlack
Icon.TextSize = 26
Icon.TextColor3 = Color3.new(1,1,1)
Icon.BackgroundColor3 = Theme.Accent
Icon.BackgroundTransparency = 0.15
Instance.new("UICorner", Icon).CornerRadius = UDim.new(1,0)

do
	local drag,start,pos
	Icon.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then
			drag=true start=i.Position pos=Icon.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
			local d=i.Position-start
			Icon.Position=UDim2.new(pos.X.Scale,pos.X.Offset+d.X,pos.Y.Scale,pos.Y.Offset+d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
	end)
end

-- ================= MAIN WINDOW =================
local Main = Instance.new("Frame", UI)
Main.Size = UDim2.fromScale(0,0)
Main.Position = UDim2.fromScale(0.5,0.5)
Main.AnchorPoint = Vector2.new(0.5,0.5)
Main.BackgroundColor3 = Theme.Dark
Main.Visible = false
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,18)

-- Header
local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1,0,0,46)
Header.BackgroundColor3 = Theme.Accent
Instance.new("UICorner", Header).CornerRadius = UDim.new(0,18)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1,-80,1,0)
Title.Position = UDim2.fromOffset(12,0)
Title.Text = "Cornello Utility Hub"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextColor3 = Color3.new(1,1,1)
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize
local Min = Instance.new("TextButton", Header)
Min.Size = UDim2.fromOffset(36,36)
Min.Position = UDim2.new(1,-42,0.5,-18)
Min.Text = "–"
Min.Font = Enum.Font.GothamBold
Min.TextSize = 22
Min.TextColor3 = Color3.new(1,1,1)
Min.BackgroundTransparency = 1

Min.MouseButton1Click:Connect(function()
	Tween(Main,0.25,{Size=UDim2.fromScale(0,0)})
	task.delay(0.25,function() Main.Visible=false end)
end)

-- ================= CONTENT (SCROLL FIX) =================
local Content = Instance.new("ScrollingFrame", Main)
Content.Position = UDim2.fromOffset(0,56)
Content.Size = UDim2.new(1,0,1,-60)
Content.CanvasSize = UDim2.new(0,0,0,0)
Content.ScrollBarImageTransparency = 0.8
Content.BackgroundTransparency = 1
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y

local Layout = Instance.new("UIListLayout", Content)
Layout.Padding = UDim.new(0,10)

-- ================= CATEGORY =================
local function Category(name)
	local Holder = Instance.new("Frame", Content)
	Holder.Size = UDim2.new(1,-30,0,46)
	Holder.BackgroundTransparency = 1

	local Btn = Instance.new("TextButton", Holder)
	Btn.Size = UDim2.new(1,0,0,46)
	Btn.Text = name
	Btn.Font = Enum.Font.GothamMedium
	Btn.TextSize = 15
	Btn.TextColor3 = Color3.new(1,1,1)
	Btn.BackgroundColor3 = Theme.Accent
	Instance.new("UICorner", Btn).CornerRadius = UDim.new(0,12)

	local Panel = Instance.new("Frame", Holder)
	Panel.Position = UDim2.fromOffset(0,52)
	Panel.Size = UDim2.new(1,0,0,0)
	Panel.ClipsDescendants = true
	Panel.BackgroundColor3 = Color3.fromRGB(40,40,50)
	Instance.new("UICorner", Panel).CornerRadius = UDim.new(0,12)

	local PL = Instance.new("UIListLayout", Panel)
	PL.Padding = UDim.new(0,8)

	local open=false
	local function Refresh()
		local h=open and (PL.AbsoluteContentSize.Y+12) or 0
		Tween(Panel,0.25,{Size=UDim2.new(1,0,0,h)})
		Tween(Holder,0.25,{Size=UDim2.new(1,-30,0,46+h)})
	end

	Btn.MouseButton1Click:Connect(function()
		open=not open
		Refresh()
	end)

	return Panel
end

local function Button(parent,text,callback)
	local B=Instance.new("TextButton",parent)
	B.Size=UDim2.new(1,-20,0,36)
	B.Text=text
	B.Font=Enum.Font.Gotham
	B.TextSize=14
	B.TextColor3=Color3.new(1,1,1)
	B.BackgroundColor3=Theme.Accent
	Instance.new("UICorner",B).CornerRadius=UDim.new(0,10)
	B.MouseButton1Click:Connect(callback)
	return B
end

-- ================= UTILITY =================
local Utility = Category("Utility")

local AntiBtn
AntiBtn = Button(Utility,"Anti AFK: OFF",function()
	getgenv().CornelloConfig.AntiAFK = not getgenv().CornelloConfig.AntiAFK
	AntiBtn.Text = "Anti AFK: "..(getgenv().CornelloConfig.AntiAFK and "ON" or "OFF")
	Save()
end)

Button(Utility,"FPS Booster: LOW",function()
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") then v.Material=Enum.Material.Plastic v.Reflectance=0 end
	end
end)

-- ================= WEBHOOK =================
local Webhook = Category("Webhook")

Button(Webhook,"Toggle Webhook",function()
	getgenv().CornelloConfig.WebhookEnabled = not getgenv().CornelloConfig.WebhookEnabled
	Save()
end)

Button(Webhook,"Test Webhook",function()
	if request and getgenv().CornelloConfig.WebhookURL ~= "" then
		request({
			Url = getgenv().CornelloConfig.WebhookURL,
			Method = "POST",
			Headers = {["Content-Type"]="application/json"},
			Body = HttpService:JSONEncode({
				content = "Cornello Utility Webhook Test"
			})
		})
	end
end)

-- ================= INFO =================
local Info = Category("Info")
Button(Info,"Cornello Utility Hub v1.0",function() end)
Button(Info,"Executor Friendly Script",function() end)
Button(Info,"Author: CornelloTeam",function() end)

-- ================= CORE =================
task.spawn(function()
	while task.wait(600) do
		if getgenv().CornelloConfig.AntiAFK then
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end
	end
end)

Icon.MouseButton1Click:Connect(function()
	Main.Visible = true
	Main.Size = UDim2.fromScale(0,0)
	Tween(Main,0.25,{Size=UDim2.fromScale(0.4,0.6)})
end)
