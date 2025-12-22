--[[ 
 CornelloTeam – Disconnect Notify v3.2.1
 FIXED UI | Categorized | Mobile Friendly
 Draggable Icon | Minimize Panel
 Delta Executor Compatible
--]]

-- ================= SERVICES =================
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local VirtualInput = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PLACE_ID = game.PlaceId
local CONFIG_FILE = "Cornello_Disconnect.json"
local AUTOEXEC_FILE = "Cornello_AutoExec.flag"

pcall(function()
	UserInputService.MouseIconEnabled = false
end)

-- ================= CONFIG =================
local Config = {
	Webhooks = {https://discord.com/api/webhooks/1442511515679981662/cgwIuR5PZwP0ak-SsC9tiVQJy3VchxUhhcYI1gVu0bIE_fHwjZJ4u6b-zTrri0tJ0W4z},
	DiscordID = "830801389558562817",

	Notify = true,
	AutoReconnect = true,
	ReconnectDelay = 5,

	AntiAFK = true,
	AutoClick = false,
	AutoClickDelay = 600,

	AutoSave = true,
	AutoExecute = false
}

-- ================= UTILS =================
local function Notify(t,d)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = t,
			Text = d,
			Duration = 4
		})
	end)
end

local function SaveConfig(force)
	if Config.AutoSave or force then
		pcall(function()
			writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
		end)
	end
end

local function LoadConfig()
	if isfile(CONFIG_FILE) then
		local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
		for k,v in pairs(data) do
			Config[k] = v
		end
	end
end

local function UpdateAutoExec()
	if Config.AutoExecute then
		writefile(AUTOEXEC_FILE,"true")
	else
		if isfile(AUTOEXEC_FILE) then delfile(AUTOEXEC_FILE) end
	end
end

-- ================= TIME =================
local function GetTime()
	local t = os.date("*t")
	return
		string.format("%02d:%02d:%02d", t.hour, t.min, t.sec),
		string.format("%02d/%02d/%04d", t.day, t.month, t.year)
end

-- ================= DISCONNECT =================
local function ShouldReconnect(msg)
	msg = string.lower(msg or "")
	for _,k in ipairs({"disconnect","lost","internet","error","kick"}) do
		if msg:find(k) then return true end
	end
	return false
end

local function SendWebhook(reason)
	if not Config.Notify then return end
	local time, day = GetTime()
	local ping = Config.DiscordID ~= "" and "<@"..Config.DiscordID..">" or ""

	for _,url in ipairs(Config.Webhooks) do
		pcall(function()
			request({
				Url = url,
				Method = "POST",
				Headers = {["Content-Type"]="application/json"},
				Body = HttpService:JSONEncode({
					content = ping,
					embeds = {{
						title = "Disconnect Detected",
						color = 0x9B59B6,
						fields = {
							{name="Player",value=Player.Name},
							{name="Time",value=time,inline=true},
							{name="Date",value=day,inline=true},
							{name="Reason",value=reason}
						}
					}}
				})
			})
		end)
	end
end

local function TryReconnect(reason)
	if Config.AutoReconnect and ShouldReconnect(reason) then
		task.delay(Config.ReconnectDelay,function()
			TeleportService:Teleport(PLACE_ID,Player)
		end)
	end
end

-- ================= BACKGROUND TASK =================
task.spawn(function()
	while task.wait(60) do
		if Config.AntiAFK then
			VirtualInput:SendKeyEvent(true,Enum.KeyCode.Space,false,game)
			task.wait(0.1)
			VirtualInput:SendKeyEvent(false,Enum.KeyCode.Space,false,game)
		end
	end
end)

task.spawn(function()
	while task.wait() do
		if Config.AutoClick then
			local vp = workspace.CurrentCamera.ViewportSize
			VirtualInput:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,true,game,0)
			task.wait(0.05)
			VirtualInput:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,false,game,0)
			task.wait(Config.AutoClickDelay/1000)
		else
			task.wait(0.2)
		end
	end
end)

-- ================= UI ROOT =================
local UI = Instance.new("ScreenGui",CoreGui)
UI.Name = "CornelloTeamUI"
UI.ResetOnSpawn = false

-- ================= FLOAT ICON =================
local Icon = Instance.new("ImageButton",UI)
Icon.Size = UDim2.fromScale(0.09,0.09)
Icon.Position = UDim2.fromScale(0.05,0.45)
Icon.Image = "rbxassetid://7072719338"
Icon.BackgroundColor3 = Color3.fromRGB(155,89,182)
Icon.Active = true
Icon.Draggable = true
Instance.new("UICorner",Icon).CornerRadius = UDim.new(1,0)

-- ================= MAIN PANEL =================
local Main = Instance.new("Frame",UI)
Main.Size = UDim2.fromScale(0.52,0.68)
Main.Position = UDim2.fromScale(0.24,0.16)
Main.BackgroundColor3 = Color3.fromRGB(22,22,30)
Main.Visible = false
Main.Active = true
Main.Draggable = true
Instance.new("UICorner",Main).CornerRadius = UDim.new(0,16)
Instance.new("UIStroke",Main).Color = Color3.fromRGB(155,89,182)

Icon.MouseButton1Click:Connect(function()
	Main.Visible = true
	Icon.Visible = false
end)

-- ================= HEADER =================
local Header = Instance.new("Frame",Main)
Header.Size = UDim2.new(1,0,0,44)
Header.BackgroundTransparency = 1

local Title = Instance.new("TextLabel",Header)
Title.Size = UDim2.new(1,-60,1,0)
Title.Position = UDim2.new(0,16,0,0)
Title.Text = "CornelloTeam – Disconnect Notify"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextColor3 = Color3.new(1,1,1)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1

local Min = Instance.new("TextButton",Header)
Min.Size = UDim2.new(0,32,0,32)
Min.Position = UDim2.new(1,-40,0.5,-16)
Min.Text = "—"
Min.Font = Enum.Font.GothamBold
Min.TextSize = 18
Min.TextColor3 = Color3.new(1,1,1)
Min.BackgroundColor3 = Color3.fromRGB(60,60,80)
Instance.new("UICorner",Min)

Min.MouseButton1Click:Connect(function()
	Main.Visible = false
	Icon.Visible = true
end)

-- ================= SCROLL =================
local Scroll = Instance.new("ScrollingFrame",Main)
Scroll.Position = UDim2.new(0,0,0,50)
Scroll.Size = UDim2.new(1,0,1,-50)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize = UDim2.new(0,0,0,0)
Scroll.ScrollBarImageTransparency = 0.4

local Layout = Instance.new("UIListLayout",Scroll)
Layout.Padding = UDim.new(0,10)

-- ================= UI HELPERS =================
local function Section(name)
	local f = Instance.new("TextLabel",Scroll)
	f.Size = UDim2.new(1,-20,0,28)
	f.Position = UDim2.new(0,10,0,0)
	f.Text = name
	f.Font = Enum.Font.GothamBold
	f.TextSize = 13
	f.TextColor3 = Color3.fromRGB(200,170,255)
	f.TextXAlignment = Enum.TextXAlignment.Left
	f.BackgroundTransparency = 1
	return f
end

local function Button(text,callback)
	local b = Instance.new("TextButton",Scroll)
	b.Size = UDim2.new(1,-20,0,40)
	b.Position = UDim2.new(0,10,0,0)
	b.Text = text
	b.Font = Enum.Font.Gotham
	b.TextSize = 14
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = Color3.fromRGB(50,50,70)
	Instance.new("UICorner",b)
	b.MouseButton1Click:Connect(function()
		callback(b)
		SaveConfig()
	end)
	return b
end

-- ================= SECTIONS =================
Section("SYSTEM")
Button("Save Config",function() SaveConfig(true) Notify("CornelloTeam","Config disimpan") end)
Button("Load Config",function() LoadConfig() Notify("CornelloTeam","Config dimuat") end)

Button("AutoSave: "..(Config.AutoSave and "ON" or "OFF"),function(b)
	Config.AutoSave = not Config.AutoSave
	b.Text = "AutoSave: "..(Config.AutoSave and "ON" or "OFF")
end)

Button("AutoExecute: "..(Config.AutoExecute and "ON" or "OFF"),function(b)
	Config.AutoExecute = not Config.AutoExecute
	UpdateAutoExec()
	b.Text = "AutoExecute: "..(Config.AutoExecute and "ON" or "OFF")
end)

Section("CONNECTION")
Button("Notify Discord: "..(Config.Notify and "ON" or "OFF"),function(b)
	Config.Notify = not Config.Notify
	b.Text = "Notify Discord: "..(Config.Notify and "ON" or "OFF")
end)

Button("AutoReconnect: "..(Config.AutoReconnect and "ON" or "OFF"),function(b)
	Config.AutoReconnect = not Config.AutoReconnect
	b.Text = "AutoReconnect: "..(Config.AutoReconnect and "ON" or "OFF")
end)

Section("UTILITY")
Button("Anti AFK: "..(Config.AntiAFK and "ON" or "OFF"),function(b)
	Config.AntiAFK = not Config.AntiAFK
	b.Text = "Anti AFK: "..(Config.AntiAFK and "ON" or "OFF")
end)

Button("Auto Click: "..(Config.AutoClick and "ON" or "OFF"),function(b)
	Config.AutoClick = not Config.AutoClick
	b.Text = "Auto Click: "..(Config.AutoClick and "ON" or "OFF")
end)

-- ================= EVENTS =================
GuiService.ErrorMessageChanged:Connect(function(msg)
	SendWebhook(msg)
	TryReconnect(msg)
end)

game:BindToClose(function()
	SendWebhook("Player Left")
end)

-- ================= INIT =================
LoadConfig()
UpdateAutoExec()
Notify("CornelloTeam","Loaded. Error-free, hidup damai.")
