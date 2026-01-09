--[[ 
 CornelloTeam – Disconnect Notify v3.4.1
 FULL UI | SIDEBAR | CONFIG SAFE | AUTOEXEC FIX | TEST WEBHOOK
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

-- ================= FILE =================
local CONFIG_FILE = "Cornello_Disconnect.json"
local AUTOEXEC_FILE = "Cornello_AutoExec.flag"

pcall(function()
	-- Aktifkan mouse icon agar kursor terlihat
	UserInputService.MouseIconEnabled = true
end)

-- ================= DEFAULT CONFIG =================
local DefaultConfig = {
	Webhooks = {},
	DiscordID = "",

	Notify = true,
	AutoReconnect = true,
	ReconnectDelay = 5,

	AntiAFK = true,
	AutoClick = false,
	AutoClickDelay = 600,

	-- Tap settings for mobile/PC: relative 0..1 (x,y) measured from viewport
	TapLocation = { x = 0.5, y = 0.5 },
	ShowTapMarker = false,
	TapMarkerSize = 12,

	AutoSave = true,
	AutoExecute = false,

	ReconnectCount = 0,
	LastDisconnect = "None",
	SafeMode = true
}

local Config = table.clone(DefaultConfig)
local ConfigLoaded = false

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

local function ValidateConfig()
	for k,v in pairs(DefaultConfig) do
		if Config[k] == nil then
			Config[k] = v
		end
	end
end

local function LoadConfig()
	if isfile(CONFIG_FILE) then
		local ok,data = pcall(function()
			return HttpService:JSONDecode(readfile(CONFIG_FILE))
		end)
		if ok and type(data) == "table" then
			for k,v in pairs(data) do
				Config[k] = v
			end
		end
	end
	ValidateConfig()
	ConfigLoaded = true
end

local function SaveConfig(force)
	if not ConfigLoaded then return end
	if Config.AutoSave or force then
		pcall(function()
			writefile(CONFIG_FILE,HttpService:JSONEncode(Config))
		end)
	end
end

local function UpdateAutoExec()
	if Config.AutoExecute then
		writefile(AUTOEXEC_FILE,"true")
	else
		if isfile(AUTOEXEC_FILE) then delfile(AUTOEXEC_FILE) end
	end
end

-- ================= LOAD CONFIG FIRST =================
LoadConfig()

-- AUTOEXEC FIX (INI YANG KEMARIN HILANG)
if isfile(AUTOEXEC_FILE) then
	Config.AutoExecute = true
end

UpdateAutoExec()

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
	for _,k in ipairs({"disconnect","lost","internet","error"}) do
		if msg:find(k) then return true end
	end
	return false
end

local function SendWebhook(reason)
	if not Config.Notify then return end
	local time, day = GetTime()
	local ping = Config.DiscordID ~= "" and "<@"..Config.DiscordID..">" or ""

	Config.LastDisconnect = reason
	SaveConfig()

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
							{name="Reason",value=reason},
							{name="Reconnect Count",value=tostring(Config.ReconnectCount)}
						}
					}}
				})
			})
		end)
	end
end

-- ================= TEST WEBHOOK =================
local function TestWebhook()
	if #Config.Webhooks == 0 then
		Notify("Webhook","Belum ada webhook")
		return
	end

	local time, day = GetTime()

	for _,url in ipairs(Config.Webhooks) do
		pcall(function()
			request({
				Url = url,
				Method = "POST",
				Headers = {["Content-Type"]="application/json"},
				Body = HttpService:JSONEncode({
					content = Config.DiscordID ~= "" and "<@"..Config.DiscordID..">" or "",
					embeds = {{
						title = "Webhook Test",
						description = "Kalau ini masuk, webhook lu hidup dan tidak berkhianat.",
						color = 0x2ECC71,
						fields = {
							{name="Time",value=time,inline=true},
							{name="Date",value=day,inline=true},
							{name="Status",value="SUCCESS"}
						}
					}}
				})
			})
		end)
	end

	Notify("Webhook","Test dikirim")
end

local function TryReconnect(reason)
	if Config.SafeMode and reason:lower():find("kick") then return end
	if Config.AutoReconnect and ShouldReconnect(reason) then
		Config.ReconnectCount += 1
		SaveConfig()
		task.delay(Config.ReconnectDelay,function()
			TeleportService:Teleport(PLACE_ID,Player)
		end)
	end
end

-- ================= BACKGROUND =================

-- Helper: simulate a tap at configured location (touch-friendly). Uses Config.TapLocation if available.
local function SimulateTapAtLocation()
	local ok, camera = pcall(function() return workspace.CurrentCamera end)
	if not ok or not camera then return end

	local vp = camera.ViewportSize
	local tx = (Config.TapLocation and Config.TapLocation.x) or 0.5
	local ty = (Config.TapLocation and Config.TapLocation.y) or 0.5

	local vx = vp.X * tx
	local vy = vp.Y * ty

	-- small jitter to avoid always tapping same pixel
	local j = math.max(1, math.floor(math.min(vp.X, vp.Y) * 0.01)) -- ~1% of shorter side
	local jx = math.random(-j, j)
	local jy = math.random(-j, j)
	vx = vx + jx
	vy = vy + jy

	pcall(function()
		if VirtualInput and VirtualInput.SendTouchEvent then
			VirtualInput:SendTouchEvent(true, vx, vy, 0)
			task.wait(0.05)
			VirtualInput:SendTouchEvent(false, vx, vy, 0)
		else
			VirtualInput:SendMouseButtonEvent(vx, vy, 0, true, game, 0)
			task.wait(0.05)
			VirtualInput:SendMouseButtonEvent(vx, vy, 0, false, game, 0)
		end
	end)
end

-- seed random once
pcall(function() math.randomseed(tick()) end)

-- Tap marker UI and setter
local RunService = game:GetService("RunService")
local TapMarker = nil
local Overlay = nil

local function CreateTapMarker()
	if TapMarker and TapMarker.Parent then TapMarker:Destroy() TapMarker = nil end
	if not Config.ShowTapMarker then return end
	local ok, cam = pcall(function() return workspace.CurrentCamera end)
	if not ok or not cam then return end
	TapMarker = Instance.new("Frame", UI)
	TapMarker.Name = "TapMarker"
	TapMarker.Size = UDim2.new(0, Config.TapMarkerSize, 0, Config.TapMarkerSize)
	TapMarker.AnchorPoint = Vector2.new(0.5,0.5)
	TapMarker.BackgroundColor3 = Color3.fromRGB(255,255,255)
	TapMarker.BackgroundTransparency = 0.6
	TapMarker.BorderSizePixel = 0
	local uc = Instance.new("UICorner", TapMarker)
	uc.CornerRadius = UDim.new(1,0)

	local function update()
		local ok2, cam2 = pcall(function() return workspace.CurrentCamera end)
		if not ok2 or not cam2 then return end
		local vp = cam2.ViewportSize
		local x = (Config.TapLocation and Config.TapLocation.x or 0.5) * vp.X
		local y = (Config.TapLocation and Config.TapLocation.y or 0.5) * vp.Y
		TapMarker.Position = UDim2.fromOffset(x, y)
	end

	local conn
	conn = RunService.RenderStepped:Connect(function()
		if TapMarker and TapMarker.Parent then update() else if conn then conn:Disconnect() end end
	end)
end

local function RemoveTapMarker()
	if TapMarker and TapMarker.Parent then TapMarker:Destroy() end
	TapMarker = nil
end

local function StartTapSetter()
	if Overlay and Overlay.Parent then Overlay:Destroy() Overlay=nil end
	Overlay = Instance.new("TextButton", UI)
	Overlay.Name = "TapOverlay"
	Overlay.Size = UDim2.new(1,0,1,0)
	Overlay.Position = UDim2.new(0,0,0,0)
	Overlay.BackgroundTransparency = 0.5
	Overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
	Overlay.Text = "Click/Tap untuk set lokasi tap. Tekan ESC untuk batal."
	Overlay.Font = Enum.Font.GothamBold
	Overlay.TextSize = 24
	Overlay.TextColor3 = Color3.new(1,1,1)
	Overlay.TextWrapped = true
	Overlay.AutoButtonColor = false
	local conn1, conn2
	conn1 = Overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local pos = input.Position or UserInputService:GetMouseLocation()
			local ok, cam = pcall(function() return workspace.CurrentCamera end)
			if ok and cam then
				local vp = cam.ViewportSize
				Config.TapLocation = { x = math.clamp(pos.X / vp.X, 0, 1), y = math.clamp(pos.Y / vp.Y, 0, 1) }
				SaveConfig()
				CreateTapMarker()
				Notify("Tap","Lokasi tap disimpan")
			end
			Overlay:Destroy()
			if conn1 then conn1:Disconnect() end
			if conn2 then conn2:Disconnect() end
		end
	end)
	conn2 = UserInputService.InputBegan:Connect(function(inp, gp)
		if inp.KeyCode == Enum.KeyCode.Escape then
			Overlay:Destroy()
			if conn1 then conn1:Disconnect() end
			if conn2 then conn2:Disconnect() end
			Notify("Tap","Batal")
		end
	end)
end

-- Anti-AFK: perform a gentle tap at center every interval, but skip if user is typing in a textbox
task.spawn(function()
	while task.wait(60) do
		if Config.AntiAFK then
			local ok, focused = pcall(function() return UserInputService:GetFocusedTextBox() end)
			if ok and focused then
				-- user is typing; skip this tick
			else
				SimulateTapAtLocation()
			end
		end
	end
end)

-- AutoClick: perform repeated taps at center using AutoClickDelay, skip if user is interacting with text input
task.spawn(function()
	while task.wait() do
		if Config.AutoClick then
			local ok, focused = pcall(function() return UserInputService:GetFocusedTextBox() end)
			if ok and focused then
				-- avoid interfering with typing
				task.wait(0.25)
			else
				SimulateTapAtLocation()
				task.wait(Config.AutoClickDelay)
			end
		else
			task.wait(0.25)
		end
	end
end)

-- ================= UI ROOT =================
local UI = Instance.new("ScreenGui",CoreGui)
UI.Name = "CornelloTeamUI"
UI.ResetOnSpawn = false

-- ================= FLOAT ICON =================
local Icon = Instance.new("ImageButton", UI)
Icon.Name = "CornelloIcon"
Icon.Size = UDim2.fromScale(0.09, 0.09)
Icon.Position = UDim2.fromScale(0.05, 0.45)
Icon.BackgroundTransparency = 1
Icon.Image = "https://i.ibb.co/9mxLgNg7/thumbnail.png"
Icon.ScaleType = Enum.ScaleType.Fit
Icon.AutoButtonColor = true
Icon.Draggable = true
Instance.new("UICorner", Icon).CornerRadius = UDim.new(1, 0)

-- ================= MAIN =================
local Main = Instance.new("Frame",UI)
Main.Size = UDim2.fromScale(0.65,0.75)
Main.Position = UDim2.fromScale(0.175,0.12)
Main.BackgroundColor3 = Color3.fromRGB(22,22,30)
Main.Visible = false
Main.Draggable = true
Instance.new("UICorner",Main).CornerRadius = UDim.new(0,16)

Icon.MouseButton1Click:Connect(function()
	Main.Visible = true
	Icon.Visible = false
end)

-- ================= HEADER =================
local Header = Instance.new("TextButton",Main)
Header.Size = UDim2.new(1,0,0,40)
Header.Text = "CornelloTeam – Disconnect Notify v3.4.1"
Header.Font = Enum.Font.GothamBold
Header.TextSize = 14
Header.TextColor3 = Color3.new(1,1,1)
Header.BackgroundTransparency = 1
Header.MouseButton1Click:Connect(function()
	Main.Visible = false
	Icon.Visible = true
end)

-- ================= SIDEBAR =================
local Sidebar = Instance.new("Frame",Main)
Sidebar.Size = UDim2.new(0.26,0,1,-40)
Sidebar.Position = UDim2.new(0,0,0,40)
Sidebar.BackgroundColor3 = Color3.fromRGB(30,30,40)

local Content = Instance.new("ScrollingFrame",Main)
Content.Size = UDim2.new(0.74,0,1,-40)
Content.Position = UDim2.new(0.26,0,0,40)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.ScrollBarImageTransparency = 0.4
Content.BackgroundTransparency = 1
Instance.new("UIListLayout",Content).Padding = UDim.new(0,10)

local function Clear()
	for _,v in pairs(Content:GetChildren()) do
		if v:IsA("GuiObject") then v:Destroy() end
	end
	Instance.new("UIListLayout",Content).Padding = UDim.new(0,10)
end

local function Label(text)
	local l = Instance.new("TextLabel",Content)
	l.Size = UDim2.new(1,-20,0,30)
	l.Text = text
	l.Font = Enum.Font.GothamBold
	l.TextSize = 14
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextColor3 = Color3.fromRGB(200,170,255)
	l.BackgroundTransparency = 1
	return l
end

local function Toggle(text,value,callback)
	local b = Instance.new("TextButton",Content)
	b.Size = UDim2.new(1,-20,0,40)
	b.Text = text..": "..(value and "ON" or "OFF")
	b.Font = Enum.Font.Gotham
	b.TextSize = 14
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = value and Color3.fromRGB(120,80,160) or Color3.fromRGB(60,60,80)
	Instance.new("UICorner",b)
	b.MouseButton1Click:Connect(function()
		value = not value
		b.Text = text..": "..(value and "ON" or "OFF")
		b.BackgroundColor3 = value and Color3.fromRGB(120,80,160) or Color3.fromRGB(60,60,80)
		callback(value)
		SaveConfig()
	end)
	return b
end

local function Input(text,default,callback)
	local t = Instance.new("TextBox",Content)
	t.Size = UDim2.new(1,-20,0,40)
	t.PlaceholderText = text
	t.Text = tostring(default or "")
	t.Font = Enum.Font.Gotham
	t.TextSize = 14
	t.TextColor3 = Color3.new(1,1,1)
	t.BackgroundColor3 = Color3.fromRGB(50,50,70)
	Instance.new("UICorner",t)
	t.FocusLost:Connect(function()
		callback(t.Text)
		SaveConfig()
	end)
	return t
end

-- ================= PANELS =================
local function UtilityPanel()
	Clear()
	Label("UTILITY")
	Input("Discord ID",Config.DiscordID,function(v) Config.DiscordID=v end)
	Input("Webhook URL", "", function(v)
		if v ~= "" then
			table.insert(Config.Webhooks,v)
			Notify("Webhook","Ditambahkan")
		end
	end)

	local testBtn = Instance.new("TextButton",Content)
	testBtn.Size = UDim2.new(1,-20,0,40)
	testBtn.Text = "TEST WEBHOOK"
	testBtn.Font = Enum.Font.GothamBold
	testBtn.TextSize = 14
	testBtn.TextColor3 = Color3.new(1,1,1)
	testBtn.BackgroundColor3 = Color3.fromRGB(70,130,90)
	Instance.new("UICorner",testBtn)
	testBtn.MouseButton1Click:Connect(TestWebhook)

	Toggle("AutoSave",Config.AutoSave,function(v) Config.AutoSave=v end)
	Toggle("AutoExecute",Config.AutoExecute,function(v)
		Config.AutoExecute=v
		UpdateAutoExec()
	end)

	-- Tap location settings
	Toggle("Show Tap Marker", Config.ShowTapMarker, function(v)
		Config.ShowTapMarker = v
		if v then CreateTapMarker() else RemoveTapMarker() end
		SaveConfig()
	end)

	local tapLabel = Label("Tap Location: " .. (Config.TapLocation and (math.floor(Config.TapLocation.x*100) .. "% , " .. math.floor(Config.TapLocation.y*100) .. "%") or "Default (Center)"))

	local setTapBtn = Instance.new("TextButton",Content)
	setTapBtn.Size = UDim2.new(1,-20,0,40)
	setTapBtn.Text = "SET TAP LOCATION"
	setTapBtn.Font = Enum.Font.GothamBold
	setTapBtn.TextSize = 14
	setTapBtn.TextColor3 = Color3.new(1,1,1)
	setTapBtn.BackgroundColor3 = Color3.fromRGB(70,130,90)
	Instance.new("UICorner",setTapBtn)
	setTapBtn.MouseButton1Click:Connect(function()
		StartTapSetter()
		Notify("Tap","Klik layar untuk memilih lokasi")
		-- update label after a short delay in case user set
		task.delay(0.5, function()
			if Config.TapLocation then
				tapLabel.Text = "Tap Location: " .. math.floor(Config.TapLocation.x*100) .. "% , " .. math.floor(Config.TapLocation.y*100) .. "%"
			end
		end)
	end)

	local clearTapBtn = Instance.new("TextButton",Content)
	clearTapBtn.Size = UDim2.new(1,-20,0,40)
	clearTapBtn.Text = "CLEAR TAP LOCATION"
	clearTapBtn.Font = Enum.Font.GothamBold
	clearTapBtn.TextSize = 14
	clearTapBtn.TextColor3 = Color3.new(1,1,1)
	clearTapBtn.BackgroundColor3 = Color3.fromRGB(120,80,80)
	Instance.new("UICorner",clearTapBtn)
	clearTapBtn.MouseButton1Click:Connect(function()
		Config.TapLocation = { x = 0.5, y = 0.5 }
		SaveConfig()
		CreateTapMarker()
		tapLabel.Text = "Tap Location: Default (Center)"
		Notify("Tap","Lokasi tap di-reset ke pusat")
	end)

	local testTapBtn = Instance.new("TextButton",Content)
	testTapBtn.Size = UDim2.new(1,-20,0,40)
	testTapBtn.Text = "TEST TAP"
	testTapBtn.Font = Enum.Font.GothamBold
	testTapBtn.TextSize = 14
	testTapBtn.TextColor3 = Color3.new(1,1,1)
	testTapBtn.BackgroundColor3 = Color3.fromRGB(70,130,90)
	Instance.new("UICorner",testTapBtn)
	testTapBtn.MouseButton1Click:Connect(function()
		SimulateTapAtLocation()
		Notify("Tap","Test tap dikirim")
	end)
end

local function FeaturePanel()
	Clear()
	Label("FEATURES")
	Toggle("AutoReconnect",Config.AutoReconnect,function(v) Config.AutoReconnect=v end)
	Input("Reconnect Delay (sec)",Config.ReconnectDelay,function(v)
		Config.ReconnectDelay=tonumber(v) or 5
	end)
	Toggle("Anti AFK",Config.AntiAFK,function(v) Config.AntiAFK=v end)
	Toggle("Auto Click",Config.AutoClick,function(v) Config.AutoClick=v end)
	Input("AutoClick Delay (sec)",Config.AutoClickDelay,function(v)
		Config.AutoClickDelay=tonumber(v) or 600
	end)
end

local function NotifyPanel()
	Clear()
	Label("NOTIFY")
	Toggle("Discord Notify",Config.Notify,function(v) Config.Notify=v end)
	Toggle("Safe Mode",Config.SafeMode,function(v) Config.SafeMode=v end)
	Label("Reconnect Count: "..Config.ReconnectCount)
	Label("Last Disconnect: "..Config.LastDisconnect)
end

local function SideButton(text,callback,y)
	local b = Instance.new("TextButton",Sidebar)
	b.Size = UDim2.new(1,-10,0,36)
	b.Position = UDim2.new(0,5,0,y)
	b.Text = text
	b.Font = Enum.Font.Gotham
	b.TextSize = 13
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = Color3.fromRGB(60,60,80)
	Instance.new("UICorner",b)
	b.MouseButton1Click:Connect(callback)
end

SideButton("UTILITY",UtilityPanel,10)
SideButton("FEATURES",FeaturePanel,56)
SideButton("NOTIFY",NotifyPanel,102)

UtilityPanel()
if Config.ShowTapMarker then
	CreateTapMarker()
end

-- ================= EVENTS =================
GuiService.ErrorMessageChanged:Connect(function(msg)
	SendWebhook(msg)
	TryReconnect(msg)
end)

local RunService = game:GetService("RunService")
-- BindToClose is only available on server-side scripts. For client, use ancestry change to detect leave.
if RunService:IsServer() then
	game:BindToClose(function()
		pcall(SendWebhook, "Player Left")
	end)
else
	-- client fallback: when LocalPlayer is removed from the game hierarchy, send webhook
	Player.AncestryChanged:Connect(function(child, parent)
		if not parent then
			pcall(SendWebhook, "Player Left")
		end
	end)
end

Notify("CornelloTeam","v3.4.1 Loaded. AutoExec waras. Webhook bisa dites.")

-- Helper: play sound safely (asset may be private/unapproved for requester)
local function SafePlaySound(assetId)
	pcall(function()
		local s = Instance.new("Sound")
		s.SoundId = "rbxassetid://"..tostring(assetId)
		s.Parent = workspace
		s:Play()
		game:GetService("Debris"):AddItem(s, 5)
	end)
end
