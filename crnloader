--[[ 
 CornelloTeam – Modern Loader
 Slide UI + Image | GitHub Raw Loader
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- ================= CONFIG =================
local GITHUB_USER = "Masfadil53818"
local GITHUB_REPO = "MyRoblox"
local BRANCH = "main"

local MAIN_URL = ("https://raw.githubusercontent.com/%s/%s/%s/CrnXAi.lua")
	:format(GITHUB_USER, GITHUB_REPO, BRANCH)

local VERSION_URL = ("https://raw.githubusercontent.com/%s/%s/%s/version.txt")
	:format(GITHUB_USER, GITHUB_REPO, BRANCH)

-- GANTI GAMBAR DI SINI (bebas, asal https)
local IMAGE_URL = "https://ibb.co.com/9mxLgNg7"

-- ================= UI =================
local gui = Instance.new("ScreenGui")
gui.Name = "CornelloLoader"
gui.IgnoreGuiInset = true
gui.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame", gui)
main.Size = UDim2.fromScale(0.45, 0.28)
main.Position = UDim2.fromScale(-0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(20,20,20)
main.BorderSizePixel = 0
main.ClipsDescendants = true

Instance.new("UICorner", main).CornerRadius = UDim.new(0,16)

-- Slide in
TweenService:Create(
	main,
	TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	{Position = UDim2.fromScale(0.5,0.5)}
):Play()

-- ================= IMAGE =================
local img = Instance.new("ImageLabel", main)
img.Size = UDim2.fromScale(0.38,1)
img.BackgroundTransparency = 1
img.Image = IMAGE_URL
img.ScaleType = Enum.ScaleType.Crop

-- ================= CONTENT =================
local content = Instance.new("Frame", main)
content.Position = UDim2.fromScale(0.38,0)
content.Size = UDim2.fromScale(0.62,1)
content.BackgroundTransparency = 1

local title = Instance.new("TextLabel", content)
title.Text = "CornelloTeam"
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextColor3 = Color3.fromRGB(255,255,255)
title.BackgroundTransparency = 1
title.Position = UDim2.fromScale(0.05,0.15)
title.Size = UDim2.fromScale(0.9,0.2)
title.TextXAlignment = Left

local status = Instance.new("TextLabel", content)
status.Text = "Initializing..."
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.TextColor3 = Color3.fromRGB(180,180,180)
status.BackgroundTransparency = 1
status.Position = UDim2.fromScale(0.05,0.38)
status.Size = UDim2.fromScale(0.9,0.2)
status.TextXAlignment = Left

-- ================= PROGRESS BAR =================
local barBg = Instance.new("Frame", content)
barBg.Position = UDim2.fromScale(0.05,0.65)
barBg.Size = UDim2.fromScale(0.9,0.08)
barBg.BackgroundColor3 = Color3.fromRGB(40,40,40)
barBg.BorderSizePixel = 0
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1,0)

local bar = Instance.new("Frame", barBg)
bar.Size = UDim2.fromScale(0,1)
bar.BackgroundColor3 = Color3.fromRGB(0,170,255)
bar.BorderSizePixel = 0
Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

local function setProgress(p, txt)
	status.Text = txt
	TweenService:Create(
		bar,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.fromScale(p,1)}
	):Play()
	task.wait(0.45)
end

-- ================= HTTP =================
local function httpget(url)
	return game:HttpGet(url)
end

-- ================= LOAD FLOW =================
setProgress(0.15,"Checking version...")
pcall(function()
	local v = httpget(VERSION_URL)
end)

setProgress(0.45,"Fetching script...")
local ok,src = pcall(function()
	return httpget(MAIN_URL)
end)

if not ok then
	status.Text = "Failed to load script"
	task.wait(2)
	gui:Destroy()
	return
end

setProgress(0.75,"Compiling...")
local fn,err = loadstring(src)
if not fn then
	status.Text = "Compile error"
	warn(err)
	task.wait(2)
	gui:Destroy()
	return
end

setProgress(1,"Launching...")
task.wait(0.4)

-- Slide out
TweenService:Create(
	main,
	TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
	{Position = UDim2.fromScale(1.5,0.5)}
):Play()

task.wait(0.6)
gui:Destroy()
fn()
