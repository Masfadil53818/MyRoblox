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
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PLACE_ID = game.PlaceId

-- Ensure script runs on the client (LocalScript). If LocalPlayer is not available, abort early with warning.
if not Player then
	warn("CrnXAi: LocalPlayer not found. Ensure this script is a LocalScript placed under StarterPlayerScripts or StarterGui.")
	return
end

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

	-- Icon image (can be customized via Utility panel)
	IconImage = "https://i.ibb.co/9mxLgNg7/thumbnail.png",
	IconBackup = "",

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
local ok_ui, UI = pcall(function()
	local gui = Instance.new("ScreenGui")
	gui.Name = "CornelloTeamUI"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 999 -- ensure on top
	-- try to parent to PlayerGui, wait briefly if needed
	local parentGui = nil
	local ok_pg, pg = pcall(function() return Player:FindFirstChild("PlayerGui") end)
	if ok_pg and pg then
		parentGui = pg
	else
		-- wait up to 5s for PlayerGui to appear
		local ok_wait, pg2 = pcall(function() return Player:WaitForChild("PlayerGui", 5) end)
		if ok_wait and pg2 then
			parentGui = pg2
		else
			parentGui = CoreGui -- fallback, may be blocked
		end
	end
	gui.Parent = parentGui
	return gui
end)
if not ok_ui or not UI then
	warn("CrnXAi: failed to create UI root")
	pcall(Notify, "CornelloTeam", "Gagal membuat UI root")
	return
end
print("CrnXAi: UI root created (parent=" .. (UI.Parent and UI.Parent.Name or "nil") .. ")")
pcall(Notify, "CornelloTeam", "UI root dibuat")
-- create a visible large test label to confirm visibility
local ok_test = pcall(function()
	local test = Instance.new("TextLabel")
	test.Name = "CrnXAi_TEST_VISIBLE"
	test.Size = UDim2.fromScale(0.5, 0.1)
	test.Position = UDim2.fromScale(0.25, 0.45)
	test.BackgroundColor3 = Color3.fromRGB(30,160,100)
	test.TextColor3 = Color3.new(1,1,1)
	test.Font = Enum.Font.GothamBold
	test.TextSize = 26
	test.Text = "CrnXAi: UI VISIBLE"
	test.TextWrapped = true
	test.Parent = UI
	task.delay(6, function() if test and test.Parent then test:Destroy() end end)
end)
if not ok_test then warn("CrnXAi: test label failed") end
-- also create an alternate UI in CoreGui (if different) to maximize chance of display
pcall(function()
	if UI.Parent ~= CoreGui then
		local alt = CoreGui:FindFirstChild("CornelloTeamUI_Alt")
		if not alt then
			alt = Instance.new("ScreenGui") alt.Name = "CornelloTeamUI_Alt" alt.ResetOnSpawn = false alt.DisplayOrder = 1000
			alt.Parent = CoreGui
			print("CrnXAi: Alt UI created in CoreGui")
		end
		-- small visible marker in alt too
		if alt and not alt:FindFirstChild("CrnXAi_TEST_VISIBLE_ALT") then
			local t2 = Instance.new("TextLabel", alt)
			t2.Name = "CrnXAi_TEST_VISIBLE_ALT"
			t2.Size = UDim2.fromScale(0.4, 0.06)
			t2.Position = UDim2.fromScale(0.3, 0.01)
			t2.BackgroundColor3 = Color3.fromRGB(160,40,80)
			t2.TextColor3 = Color3.new(1,1,1)
			t2.Font = Enum.Font.GothamBold
			t2.TextSize = 18
			t2.Text = "CrnXAi ALT: UI loaded"
			task.delay(6, function() if t2 and t2.Parent then t2:Destroy() end end)
		end
	end
end)
-- diagnostic prints
pcall(function()
	print("CrnXAi: Player has PlayerGui?", Player:FindFirstChild("PlayerGui") ~= nil)
	print("CrnXAi: UI parent name:", UI.Parent and UI.Parent.Name or "nil")
	if UI.Parent then
		print("CrnXAi: UI children:")
		for i,v in ipairs(UI:GetChildren()) do print(" -", v.Name, v.ClassName) end
	end
end)

-- ================= FLOAT ICON =================
local ok_icon, Icon = pcall(function()
	local b = Instance.new("ImageButton")
	b.Name = "CornelloIcon"
	b.Size = UDim2.fromScale(0.09, 0.09)
	b.Position = UDim2.fromScale(0.05, 0.45)
	b.BackgroundTransparency = 1
	b.Image = (Config.IconImage ~= "" and Config.IconImage) or "https://i.ibb.co/9mxLgNg7/thumbnail.png"
	b.ScaleType = Enum.ScaleType.Fit
	b.AutoButtonColor = true
	b.Draggable = true
	Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
	b.Visible = true
	b.Parent = UI
	return b
end)
if not ok_icon or not Icon then
	warn("CrnXAi: failed to create Icon")
	pcall(Notify, "CornelloTeam", "Gagal membuat ikon UI")
	-- fallback icon in CoreGui (if allowed)
	pcall(function()
		local fb = Instance.new("TextButton")
		fb.Name = "CornelloIconFallback"
		fb.Size = UDim2.fromScale(0.09, 0.09)
		fb.Position = UDim2.fromScale(0.05, 0.45)
		fb.BackgroundColor3 = Color3.fromRGB(50,50,60)
fb.Text = ((Config.IconBackup ~= "" ) and Config.IconBackup) or "C"
		fb.Font = Enum.Font.GothamBold
		fb.TextSize = 28
		fb.TextColor3 = Color3.new(1,1,1)
		Instance.new("UICorner", fb).CornerRadius = UDim.new(1,0)
		fb.AutoButtonColor = true
		fb.Parent = CoreGui
		fb.MouseButton1Click:Connect(function()
			local ok, _ = pcall(function() if _G.ShowMain then _G.ShowMain() else if Main and Main.Visible ~= nil then Main.Visible = true end end end)
			if Icon then Icon.Visible = false end
			fb.Visible = false
		end)
	end)
else
	print("CrnXAi: Icon created (parent=" .. (Icon.Parent and Icon.Parent.Name or "nil") .. ")")
	pcall(Notify, "CornelloTeam", "Ikon UI dibuat")
	-- enforce visibility settings and diagnostics
	Icon.ZIndex = 1000
	Icon.Visible = false -- will be shown after preload succeeds
	print("CrnXAi: Icon.Image =", Icon.Image)
	print("CrnXAi: Icon parent =", Icon.Parent and Icon.Parent:GetFullName())
	-- short on-screen debug label showing current image
	pcall(function()
		local d = Instance.new("TextLabel", UI)
		d.Name = "CrnXAi_IconDebug"
		d.Size = UDim2.fromScale(0.2,0.04)
		d.Position = Icon.Position + UDim2.fromScale(0, -0.06)
		d.BackgroundColor3 = Color3.fromRGB(20,20,30)
		d.TextColor3 = Color3.new(1,1,1)
		d.Font = Enum.Font.Gotham
		d.TextSize = 12
		d.Text = "Icon: " .. tostring(Icon.Image)
		Instance.new("UICorner", d).CornerRadius = UDim.new(0,6)
		task.delay(6, function() if d and d.Parent then d:Destroy() end end)
	end)
	-- Preload image to detect load failure and create fallback if needed
	local ContentProvider = game:GetService("ContentProvider")
	local function ensureIconLoaded()
		local function createFallback(parent)
			local fb = parent:FindFirstChild("CornelloIconFallback")
			if not fb then
				fb = Instance.new("TextButton")
				fb.Name = "CornelloIconFallback"
				fb.Size = Icon.Size
				fb.Position = Icon.Position
				fb.AnchorPoint = Icon.AnchorPoint or Vector2.new(0,0)
				fb.BackgroundColor3 = Color3.fromRGB(48,48,58)
				fb.Text = "C"
				fb.Font = Enum.Font.GothamBold
				fb.TextSize = 28
				fb.TextColor3 = Color3.new(1,1,1)
				fb.TextScaled = true
				fb.AutoButtonColor = true
				Instance.new("UICorner", fb).CornerRadius = UDim.new(1,0)
				fb.Visible = false
				fb.ZIndex = 500
				fb.Parent = parent
				fb.MouseButton1Click:Connect(function()
					pcall(function() if _G.ShowMain then _G.ShowMain() elseif Main and Main.Visible ~= nil then Main.Visible = true end end)
					if Icon then Icon.Visible = false end
					fb.Visible = false
				end)
			end
			return fb
		end

		local parent = Icon.Parent or UI or CoreGui
		local fb = createFallback(parent)

		-- attempt preload with retries
		local ok_preload = false
		for i=1,3 do
			local ok, err = pcall(function() ContentProvider:PreloadAsync({Icon}) end)
			if ok then ok_preload = true break end
			task.wait(0.6)
		end
		if ok_preload then
			print("CrnXAi: Icon image preloaded successfully")
			if fb and fb.Parent then pcall(function() fb:Destroy() end) end
			Icon.Visible = true
		else
			warn("CrnXAi: Icon image failed to preload")
			pcall(Notify, "CornelloTeam", "Gagal memuat ikon, menampilkan fallback")
			if fb then fb.Visible = true end
			Icon.Visible = false
		end
	end
	-- initial check (async to avoid blocking)
	task.spawn(ensureIconLoaded)
	-- re-check when Image property changes
	Icon:GetPropertyChangedSignal("Image"):Connect(function()
		task.spawn(ensureIconLoaded)
	end)
	-- also try to create an alternate icon directly in CoreGui in case UI parent is blocked
	pcall(function()
		if CoreGui and not CoreGui:FindFirstChild("CornelloIconAlt") then
			local alt = Instance.new("ImageButton")
			alt.Name = "CornelloIconAlt"
			alt.Size = Icon.Size
			alt.Position = Icon.Position
			alt.BackgroundTransparency = 1
			alt.Image = Icon.Image
			alt.Parent = CoreGui
			Instance.new("UICorner", alt).CornerRadius = UDim.new(1,0)
			alt.MouseButton1Click:Connect(function()
				local ok, _ = pcall(function() if _G.ShowMain then _G.ShowMain() else if Main and Main.Visible ~= nil then Main.Visible = true end end end)
				if Icon then Icon.Visible = false end
				alt.Visible = false
			end)
		end
	end)
end
if not ok_icon or not Icon then
	warn("CrnXAi: failed to create Icon")
	pcall(Notify, "CornelloTeam", "Gagal membuat ikon UI")
	-- create visible fallback so user still has a way to open UI (try UI parent first)
	local parent = UI or CoreGui
	local fb = Instance.new("TextButton")
	fb.Name = "CornelloIconFallback"
	fb.Size = UDim2.fromScale(0.09, 0.09)
	fb.Position = UDim2.fromScale(0.05, 0.45)
	fb.AnchorPoint = Vector2.new(0,0)
	fb.BackgroundColor3 = Color3.fromRGB(48,48,58)
	fb.Text = "C"
	fb.Font = Enum.Font.GothamBold
	fb.TextSize = 28
	fb.TextScaled = true
	fb.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", fb).CornerRadius = UDim.new(1,0)
	fb.AutoButtonColor = true
	fb.Parent = parent
	fb.ZIndex = 500
	fb.MouseButton1Click:Connect(function()
		pcall(function() if _G.ShowMain then _G.ShowMain() elseif Main and Main.Visible ~= nil then Main.Visible = true end end)
		if Icon then Icon.Visible = false end
		fb.Visible = false
	end)
else
	print("CrnXAi: Icon created")
	pcall(Notify, "CornelloTeam", "Ikon UI dibuat")
	-- Preload image to detect load failure and create fallback if needed
	local ContentProvider = game:GetService("ContentProvider")
	local function ensureIconLoaded()
		local function createFallbackInUI()
			local fb = UI:FindFirstChild("CornelloIconFallback")
			if not fb then
				fb = Instance.new("TextButton")
				fb.Name = "CornelloIconFallback"
				fb.Size = Icon.Size
				fb.Position = Icon.Position
				fb.AnchorPoint = Icon.AnchorPoint or Vector2.new(0,0)
				fb.BackgroundColor3 = Color3.fromRGB(48,48,58)
			fb.Text = ((Config.IconBackup ~= "" ) and Config.IconBackup) or "C"
				fb.Font = Enum.Font.GothamBold
				fb.TextSize = 28
				fb.TextScaled = true
				fb.TextColor3 = Color3.new(1,1,1)
				fb.AutoButtonColor = true
				Instance.new("UICorner", fb).CornerRadius = UDim.new(1,0)
				fb.Visible = false
				fb.Parent = UI
				fb.ZIndex = 500
				fb.MouseButton1Click:Connect(function()
					pcall(function() if _G.ShowMain then _G.ShowMain() elseif Main and Main.Visible ~= nil then Main.Visible = true end end)
					if Icon then Icon.Visible = false end
					fb.Visible = false
				end)
			end
			return fb
		end

		local fb = createFallbackInUI()

		local ok_preload = false
		for i=1,3 do
			local ok, err = pcall(function() ContentProvider:PreloadAsync({Icon}) end)
			if ok then ok_preload = true break end
			task.wait(0.6)
		end
		if ok_preload then
			print("CrnXAi: Icon image preloaded successfully")
			if fb and fb.Parent then pcall(function() fb:Destroy() end) end
			Icon.Visible = true
		else
			warn("CrnXAi: Icon image failed to preload")
			pcall(Notify, "CornelloTeam", "Gagal memuat ikon, menampilkan fallback")
			if fb then fb.Visible = true end
			Icon.Visible = false
		end
	end
	-- initial check (async to avoid blocking)
	task.spawn(ensureIconLoaded)
	-- expose a global reload helper so Apply button can trigger a fresh check
	_G.ReloadIcon = function() task.spawn(ensureIconLoaded) end
	-- re-check when Image property changes
	Icon:GetPropertyChangedSignal("Image"):Connect(function()
		task.spawn(ensureIconLoaded)
	end)

	-- visibility sanity check: if neither icon nor fallback visible after 3s, show big debug message
	task.delay(3, function()
		local fb = UI:FindFirstChild("CornelloIconFallback") or CoreGui:FindFirstChild("CornelloIconFallback")
		if (not Icon or not Icon.Parent or not Icon.Visible) and (not fb or not fb.Parent or not fb.Visible) then
			warn("CrnXAi: Neither icon nor fallback is visible — creating forced overlay")
			pcall(Notify, "CornelloTeam", "Icon tidak tampil — menampilkan overlay debug")
			pcall(function()
				local overlay = Instance.new("Frame", UI)
				overlay.Name = "CrnXAi_IconForce"
				overlay.Size = UDim2.fromScale(0.25, 0.08)
				overlay.Position = UDim2.fromScale(0.02, 0.02)
				overlay.BackgroundColor3 = Color3.fromRGB(200,50,50)
				Instance.new("UICorner", overlay).CornerRadius = UDim.new(0,6)
				local txt = Instance.new("TextLabel", overlay)
				txt.Size = UDim2.fromScale(1,1)
				txt.BackgroundTransparency = 1
				txt.Text = "CrnXAi: ICON MISSING"
				txt.Font = Enum.Font.GothamBold
				txt.TextColor3 = Color3.new(1,1,1)
				Task = task.delay(6, function() if overlay and overlay.Parent then overlay:Destroy() end end)
			end)
		end
	end)end

-- ================= MAIN =================
local Main = Instance.new("Frame",UI)
Main.Size = UDim2.fromScale(0.65,0.75)
Main.Position = UDim2.fromScale(0.175,0.12)
Main.BackgroundColor3 = Color3.fromRGB(22,22,30)
Main.BackgroundTransparency = 1
Main.Visible = false
Main.Draggable = true
Instance.new("UICorner",Main).CornerRadius = UDim.new(0,16)
-- modern accents
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(80,60,120)
stroke.Thickness = 1
local grad = Instance.new("UIGradient", Main)
grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(28,24,38)), ColorSequenceKeypoint.new(1, Color3.fromRGB(18,18,26))}

-- animation helpers
local function tweenObject(inst, props, dur, style, dir)
	local info = TweenInfo.new(dur or 0.28, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
	local tw = TweenService:Create(inst, info, props)
	tw:Play()
	return tw
end

local mainTargetPos = Main.Position
Main.Position = UDim2.new(mainTargetPos.X.Scale, mainTargetPos.X.Offset, mainTargetPos.Y.Scale - 0.06, mainTargetPos.Y.Offset)

local function showMain()
	Main.Visible = true
	tweenObject(Main, {BackgroundTransparency = 0, Position = mainTargetPos}, 0.36, Enum.EasingStyle.Back)
	if Icon then
		tweenObject(Icon, {Size = UDim2.fromScale(0.07,0.07)}, 0.12)
		task.delay(0.14, function() Icon.Visible = false end)
	end
end

local function hideMain()
	local upPos = UDim2.new(mainTargetPos.X.Scale, mainTargetPos.X.Offset, mainTargetPos.Y.Scale - 0.06, mainTargetPos.Y.Offset)
	tweenObject(Main, {BackgroundTransparency = 1, Position = upPos}, 0.22, Enum.EasingStyle.Quad)
	task.delay(0.22, function()
		Main.Visible = false
		if Icon then Icon.Visible = true tweenObject(Icon, {Size = UDim2.fromScale(0.09,0.09)}, 0.22, Enum.EasingStyle.Elastic) end
	end)
end

_G.ShowMain = showMain
_G.HideMain = hideMain

-- Ensure existing fallback buttons call the same animated show
pcall(function()
	local fb = UI:FindFirstChild("CornelloIconFallback") or CoreGui:FindFirstChild("CornelloIconFallback")
	if fb then
		fb.MouseButton1Click:Connect(function()
			pcall(function() if _G.ShowMain then _G.ShowMain() else if Main and Main.Visible ~= nil then Main.Visible = true end end end)
			if Icon then Icon.Visible = false end
			fb.Visible = false
		end)
	end
	local alt = CoreGui:FindFirstChild("CornelloIconAlt") or UI:FindFirstChild("CornelloIconAlt")
	if alt then
		alt.MouseButton1Click:Connect(function()
			pcall(function() if _G.ShowMain then _G.ShowMain() else if Main and Main.Visible ~= nil then Main.Visible = true end end end)
			if Icon then Icon.Visible = false end
			alt.Visible = false
		end)
	end
end)

if Icon then
	Icon.MouseEnter:Connect(function() pcall(function() tweenObject(Icon, {Size = UDim2.fromScale(0.10,0.10)}, 0.12) end) end)
	Icon.MouseLeave:Connect(function() pcall(function() tweenObject(Icon, {Size = UDim2.fromScale(0.09,0.09)}, 0.12) end) end)
	Icon.MouseButton1Click:Connect(function() pcall(showMain) end)
end

-- ================= HEADER =================
local Header = Instance.new("TextButton",Main)
Header.Size = UDim2.new(1,0,0,40)
Header.Text = "CornelloTeam – Disconnect Notify v3.4.1"
Header.Font = Enum.Font.GothamBold
Header.TextSize = 14
Header.TextColor3 = Color3.new(1,1,1)
Header.BackgroundTransparency = 1
Header.MouseButton1Click:Connect(function()
	pcall(hideMain)
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
	-- General utility settings live here (icon, tap settings etc.)
	-- Webhook/notify settings moved to the NOTIFY panel for clarity


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

	-- ICON SETTINGS
	Label("ICON")
	Input("Icon Image URL", Config.IconImage, function(v) Config.IconImage = v SaveConfig() end)
	Input("Fallback Text", Config.IconBackup, function(v) Config.IconBackup = v SaveConfig() end)

	local applyIconBtn = Instance.new("TextButton",Content)
	applyIconBtn.Size = UDim2.new(1,-20,0,40)
	applyIconBtn.Text = "APPLY ICON"
	applyIconBtn.Font = Enum.Font.GothamBold
	applyIconBtn.TextSize = 14
	applyIconBtn.TextColor3 = Color3.new(1,1,1)
	applyIconBtn.BackgroundColor3 = Color3.fromRGB(70,130,90)
	Instance.new("UICorner",applyIconBtn)
	applyIconBtn.MouseButton1Click:Connect(function()
		if Config.IconImage and Config.IconImage ~= "" then
			if Icon then Icon.Image = Config.IconImage end
			SaveConfig()
			Notify("Icon","Mencoba memuat ikon baru")
			pcall(function() if _G.ReloadIcon then _G.ReloadIcon() end end)
		else
			Notify("Icon","URL ikon kosong")
		end
	end)

	local resetIconBtn = Instance.new("TextButton",Content)
	resetIconBtn.Size = UDim2.new(1,-20,0,40)
	resetIconBtn.Text = "RESET ICON"
	resetIconBtn.Font = Enum.Font.GothamBold
	resetIconBtn.TextSize = 14
	resetIconBtn.TextColor3 = Color3.new(1,1,1)
	resetIconBtn.BackgroundColor3 = Color3.fromRGB(120,80,80)
	Instance.new("UICorner",resetIconBtn)
	resetIconBtn.MouseButton1Click:Connect(function()
		Config.IconImage = DefaultConfig.IconImage
		Config.IconBackup = "C"
		if Icon then Icon.Image = Config.IconImage end
		SaveConfig()
		Notify("Icon","Ikon di-reset ke default")
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
	Toggle("Discord Notify",Config.Notify,function(v) Config.Notify=v SaveConfig() end)
	Toggle("Safe Mode",Config.SafeMode,function(v) Config.SafeMode=v SaveConfig() end)
	Label("Reconnect Count: "..Config.ReconnectCount)
	Label("Last Disconnect: "..Config.LastDisconnect)

	-- Discord settings & webhook management
	Label("DISCORD")
	Input("Discord ID", Config.DiscordID, function(v) Config.DiscordID = v SaveConfig() end)

	local newWebhook = ""
	local webhookRow = Instance.new("Frame", Content)
	webhookRow.Size = UDim2.new(1, -20, 0, 40)
	webhookRow.BackgroundTransparency = 1
	local whInput = Instance.new("TextBox", webhookRow)
	whInput.Size = UDim2.new(1, -130, 1, 0)
	whInput.PlaceholderText = "Webhook URL"
	whInput.Text = ""
	whInput.Font = Enum.Font.Gotham
	whInput.TextSize = 14
	whInput.TextColor3 = Color3.new(1,1,1)
	whInput.BackgroundColor3 = Color3.fromRGB(50,50,70)
	Instance.new("UICorner", whInput)
	whInput:GetPropertyChangedSignal("Text"):Connect(function() newWebhook = whInput.Text end)

	local addBtn = Instance.new("TextButton", webhookRow)
	addBtn.Size = UDim2.new(0,120,1,0)
	addBtn.Position = UDim2.new(1, -10, 0, 0)
	addBtn.AnchorPoint = Vector2.new(1,0)
	addBtn.Text = "ADD WEBHOOK"
	addBtn.Font = Enum.Font.GothamBold
	addBtn.TextSize = 14
	addBtn.TextColor3 = Color3.new(1,1,1)
	addBtn.BackgroundColor3 = Color3.fromRGB(70,130,90)
	Instance.new("UICorner", addBtn)
	addBtn.MouseButton1Click:Connect(function()
		if newWebhook and newWebhook ~= "" then
			table.insert(Config.Webhooks, newWebhook)
			SaveConfig()
			Notify("Webhook","Ditambahkan")
			NotifyPanel()
		end
	end)

	-- list existing webhooks
	local whList = Instance.new("Frame", Content)
	whList.Size = UDim2.new(1, -20, 0, 0)
	whList.BackgroundTransparency = 1
	local listLayout = Instance.new("UIListLayout", whList)
	listLayout.Padding = UDim.new(0,6)

	for i,url in ipairs(Config.Webhooks) do
		local row = Instance.new("Frame", whList)
		row.Size = UDim2.new(1, 0, 0, 34)
		row.BackgroundTransparency = 1
		local lbl = Instance.new("TextLabel", row)
		lbl.Size = UDim2.new(1, -80, 1, 0)
		lbl.Text = url
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 12
		lbl.TextColor3 = Color3.new(1,1,1)
		lbl.BackgroundTransparency = 1
		lbl.TextXAlignment = Enum.TextXAlignment.Left

		local del = Instance.new("TextButton", row)
		del.Size = UDim2.new(0,70,1,0)
		del.Position = UDim2.new(1,-70,0,0)
		del.AnchorPoint = Vector2.new(1,0)
		del.Text = "REMOVE"
		del.Font = Enum.Font.GothamBold
		del.TextSize = 12
		del.TextColor3 = Color3.new(1,1,1)
		del.BackgroundColor3 = Color3.fromRGB(120,60,60)
		Instance.new("UICorner", del)
		del.MouseButton1Click:Connect(function()
			table.remove(Config.Webhooks, i)
			SaveConfig()
			Notify("Webhook","Dihapus")
			NotifyPanel()
		end)
	end

	-- test button
	local testBtn2 = Instance.new("TextButton",Content)
	testBtn2.Size = UDim2.new(1,-20,0,40)
	testBtn2.Text = "TEST WEBHOOK"
	testBtn2.Font = Enum.Font.GothamBold
	testBtn2.TextSize = 14
	testBtn2.TextColor3 = Color3.new(1,1,1)
	testBtn2.BackgroundColor3 = Color3.fromRGB(70,130,90)
	Instance.new("UICorner",testBtn2)
	testBtn2.MouseButton1Click:Connect(TestWebhook)
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
