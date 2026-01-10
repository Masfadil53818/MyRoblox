
--[[  
 CornelloTeam – Advanced Multi Script Loader  
 Smooth Animation • Loading Effect • Progress Bar  
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- ================= CONFIG =================
local GITHUB_USER = "Masfadil53818"
local GITHUB_REPO = "MyRoblox"
local BRANCH = "main"

local SCRIPTS = {
	{Name = "CrnX AI", Path = "CrnXAi.lua"},
	{Name = "Auto Farm", Path = "AutoFarm.lua"},
	{Name = "ESP + Aimbot", Path = "EspAimbot.lua"},
}

local IMAGE_URL = "https://ibb.co.com/9mxLgNg7"

-- ================= UI ROOT =================
local gui = Instance.new("ScreenGui")
gui.Name = "CornelloLoader"
gui.IgnoreGuiInset = true
gui.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame", gui)
main.Size = UDim2.fromScale(0.52, 0.36)
main.Position = UDim2.fromScale(-0.6, 0.5)
main.AnchorPoint = Vector2.new(0.5,0.5)
main.BackgroundColor3 = Color3.fromRGB(16,16,16)
main.BorderSizePixel = 0
main.ClipsDescendants = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0,18)

TweenService:Create(
	main,
	TweenInfo.new(0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	{Position = UDim2.fromScale(0.5,0.5)}
):Play()

-- ================= IMAGE =================
local img = Instance.new("ImageLabel", main)
img.Size = UDim2.fromScale(0.34,1)
img.BackgroundTransparency = 1
img.Image = IMAGE_URL
img.ScaleType = Enum.ScaleType.Crop

-- ================= CONTENT =================
local content = Instance.new("Frame", main)
content.Position = UDim2.fromScale(0.34,0)
content.Size = UDim2.fromScale(0.66,1)
content.BackgroundTransparency = 1

local title = Instance.new("TextLabel", content)
title.Text = "CornelloTeam Loader"
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.Position = UDim2.fromScale(0.05,0.05)
title.Size = UDim2.fromScale(0.9,0.14)
title.TextXAlignment = Left

local status = Instance.new("TextLabel", content)
status.Text = "Select a script"
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.TextColor3 = Color3.fromRGB(170,170,170)
status.BackgroundTransparency = 1
status.Position = UDim2.fromScale(0.05,0.2)
status.Size = UDim2.fromScale(0.9,0.1)
status.TextXAlignment = Left

-- ================= SCRIPT LIST =================
local list = Instance.new("Frame", content)
list.Position = UDim2.fromScale(0.05,0.32)
list.Size = UDim2.fromScale(0.9,0.38)
list.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0,8)

-- ================= PROGRESS =================
local barBg = Instance.new("Frame", content)
barBg.Position = UDim2.fromScale(0.05,0.78)
barBg.Size = UDim2.fromScale(0.9,0.07)
barBg.BackgroundColor3 = Color3.fromRGB(35,35,35)
barBg.BorderSizePixel = 0
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1,0)

local bar = Instance.new("Frame", barBg)
bar.Size = UDim2.fromScale(0,1)
bar.BackgroundColor3 = Color3.fromRGB(0,170,255)
bar.BorderSizePixel = 0
Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

-- glow
local glow = Instance.new("UIGradient", bar)
glow.Rotation = 0
glow.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0,170,255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0,255,255))
}

-- ================= LOADING DOTS =================
local dots = 0
local loading = false

task.spawn(function()
	while true do
		if loading then
			dots = (dots % 3) + 1
			status.Text = status.Text:gsub("%.*$", "") .. string.rep(".", dots)
		end
		task.wait(0.5)
	end
end)

-- ================= PROGRESS FUNCTION =================
local function setProgress(p, txt)
	status.Text = txt
	TweenService:Create(
		bar,
		TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{Size = UDim2.fromScale(p,1)}
	):Play()
end

-- ================= LOAD SCRIPT =================
local function loadScript(path)
	loading = true
	list.Visible = false

	local url = ("https://raw.githubusercontent.com/%s/%s/%s/%s")
		:format(GITHUB_USER, GITHUB_REPO, BRANCH, path)

	setProgress(0.2,"Fetching script")
	task.wait(0.6)

	local ok, src = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok then
		status.Text = "Failed to fetch script"
		loading = false
		return
	end

	setProgress(0.55,"Compiling")
	task.wait(0.6)

	local fn, err = loadstring(src)
	if not fn then
		status.Text = "Compile error"
		warn(err)
		loading = false
		return
	end

	setProgress(1,"Launching")
	task.wait(0.5)

	loading = false

	TweenService:Create(
		main,
		TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
		{Position = UDim2.fromScale(1.6,0.5), BackgroundTransparency = 1}
	):Play()

	task.wait(0.7)
	gui:Destroy()
	fn()
end

-- ================= BUTTONS =================
for _,info in ipairs(SCRIPTS) do
	local btn = Instance.new("TextButton", list)
	btn.Size = UDim2.fromScale(1,0)
	btn.AutomaticSize = Y
	btn.Text = info.Name
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.new(1,1,1)
	btn.BackgroundColor3 = Color3.fromRGB(28,28,28)
	btn.BorderSizePixel = 0
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundColor3 = Color3.fromRGB(40,40,40)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundColor3 = Color3.fromRGB(28,28,28)}):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		loadScript(info.Path)
	end)
end
