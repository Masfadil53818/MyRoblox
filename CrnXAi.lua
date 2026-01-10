-- CornelloTeam — v0.0.1 [BETA]
-- Minimal, clean rewrite with purple transparent UI

-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local VirtualInput = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PLACE_ID = game.PlaceId
if not Player then warn("Cornello: LocalPlayer not found — run as LocalScript") return end

-- Config
local CONFIG_FILE = "Cornello_v001.json"
local DefaultConfig = {
  Webhooks = {},
  DiscordID = "",
  Notify = true,
  AutoReconnect = true,
  ReconnectDelay = 5,
  AntiAFK = true,
  AutoClick = false,
  AutoClickDelay = 0.6,
  TapLocation = { x = 0.5, y = 0.5 },
  ShowTapMarker = false,
  TapMarkerSize = 12,
  AutoSave = true,
  AutoExecute = false,
  AutoFish = false,
  FishInterval = 2,
}
local Config = (type(table.clone)=="function" and table.clone(DefaultConfig)) or (function(t)local o={} for k,v in pairs(t) do o[k]=v end return o end)(DefaultConfig)
local function LoadConfig()
  if isfile and isfile(CONFIG_FILE) then
    local ok,data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
    if ok and type(data)=="table" then for k,v in pairs(data) do Config[k]=v end end
  end
end
local function SaveConfig(force)
  if not isfile then return end
  if Config.AutoSave or force then pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(Config)) end) end
end
LoadConfig()

-- Helpers
local function Notify(title, text, dur)
  pcall(function() StarterGui:SetCore("SendNotification", {Title = title or "Cornello", Text = text or "", Duration = dur or 4}) end)
end

local request_func = request or (syn and syn.request) or http_request or (http and http.request) or (fluxus and fluxus.request) or (Krnl and Krnl.request)
local function safeRequest(opts)
  if not request_func then return false, "no_request" end
  local ok,res = pcall(request_func, opts)
  if not ok then warn("Cornello: request failed", res) end
  return ok,res
end

local function now()
  local t = os.date("*t")
  return string.format("%02d:%02d:%02d", t.hour,t.min,t.sec), string.format("%02d/%02d/%04d", t.day,t.month,t.year)
end

-- Webhooks
local function SendWebhook(reason)
  if not Config.Notify then return end
  local time, day = now()
  local ping = (Config.DiscordID ~= "") and ("<@"..Config.DiscordID..">") or ""
  for _,url in ipairs(Config.Webhooks) do
    local ok,_ = safeRequest({
      Url = url,
      Method = "POST",
      Headers = { ["Content-Type"] = "application/json" },
      Body = HttpService:JSONEncode({ content = ping, embeds = {{ title = "Cornello Alert", color = 0x8E44AD, fields = {{name="Player", value = Player.Name}, {name="Time", value = time, inline=true}, {name="Date", value = day, inline=true}, {name="Reason", value = reason}, {name="PlaceId", value = tostring(PLACE_ID)} } } } )
    })
    if not ok then warn("Cornello: webhook failed for", url) end
  end
end
local function TestWebhook()
  if #Config.Webhooks == 0 then Notify("Webhook","Belum ada webhook") return end
  local time,day = now()
  for _,url in ipairs(Config.Webhooks) do
    safeRequest({Url=url, Method="POST", Headers={ ["Content-Type"]="application/json" }, Body=HttpService:JSONEncode({ content = (Config.DiscordID ~= "" and ("<@"..Config.DiscordID..">") or ""), embeds={{ title = "Webhook Test", description = "Cornello v0.0.1 [BETA] - Test", color = 0x8E44AD, fields = {{name="Time", value=time, inline=true}, {name="Date", value=day, inline=true}} } } ) })
  end
  Notify("Webhook","Test dikirim")
end

-- Tap / Auto features
local function SimulateTap()
  local ok, cam = pcall(function() return workspace.CurrentCamera end)
  if not ok or not cam then return end
  local vp = cam.ViewportSize
  local tx = (Config.TapLocation and Config.TapLocation.x) or 0.5
  local ty = (Config.TapLocation and Config.TapLocation.y) or 0.5
  local vx,vy = vp.X * tx, vp.Y * ty
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

task.spawn(function()
  while true do
    if Config.AutoFish then SimulateTap(); task.wait(math.max(0.1, tonumber(Config.FishInterval) or 2)) else task.wait(0.5) end
  end
end)

task.spawn(function()
  while task.wait(60) do if Config.AntiAFK then local ok,f = pcall(function() return UserInputService:GetFocusedTextBox() end) if not (ok and f) then SimulateTap() end end end
end)

task.spawn(function()
  while true do
    if Config.AutoClick then SimulateTap(); task.wait(math.max(0.05, tonumber(Config.AutoClickDelay) or 0.6)) else task.wait(0.25) end
  end
end)

-- UI (Purple Transparent)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Cornello_Clean_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = (pcall(function() return Player:WaitForChild("PlayerGui",6) end) and Player.PlayerGui) or CoreGui

local Icon = Instance.new("TextButton", ScreenGui)
Icon.Name = "CornelloIcon"
Icon.Size = UDim2.fromScale(0.08, 0.08)
Icon.Position = UDim2.fromScale(0.03, 0.45)
Icon.BackgroundColor3 = Color3.fromRGB(110,50,170)
Icon.BackgroundTransparency = 0.12
Instance.new("UICorner", Icon).CornerRadius = UDim.new(1,0)
local il = Instance.new("TextLabel", Icon); il.Size = UDim2.fromScale(1,1); il.BackgroundTransparency = 1; il.Text = "C"; il.Font = Enum.Font.GothamBlack; il.TextScaled = true; il.TextColor3 = Color3.fromRGB(255,230,255)

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromScale(0.7,0.78)
Main.Position = UDim2.fromScale(0.16,0.11)
Main.BackgroundColor3 = Color3.fromRGB(120,60,180)
Main.BackgroundTransparency = 0.6
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,12)
Main.Visible = false
local Header = Instance.new("TextLabel", Main); Header.Size = UDim2.new(1,0,0,44); Header.BackgroundTransparency = 1; Header.Text = "Cornello • v0.0.1 [BETA]"; Header.Font = Enum.Font.GothamBold; Header.TextColor3 = Color3.new(1,1,1)

local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0.24,0,1,-44); Sidebar.Position = UDim2.new(0,0,0,44); Sidebar.BackgroundTransparency = 1
local Content = Instance.new("ScrollingFrame", Main); Content.Size = UDim2.new(0.76,0,1,-44); Content.Position = UDim2.new(0.24,0,0,44); Content.BackgroundTransparency = 1; Content.AutomaticCanvasSize = Enum.AutomaticSize.Y

local function ClearContent(); for _,v in pairs(Content:GetChildren()) do if v:IsA("GuiObject") then v:Destroy() end end; Instance.new("UIListLayout", Content).Padding = UDim.new(0,10) end
local function AddLabel(text)
  local l = Instance.new("TextLabel", Content)
  l.Size = UDim2.new(1,-20,0,28)
  l.Text = text
  l.Font = Enum.Font.Gotham
  l.TextSize = 14
  l.TextColor3 = Color3.fromRGB(230,210,255)
  l.BackgroundTransparency = 1
  l.TextXAlignment = Enum.TextXAlignment.Left
  return l
end
local function AddToggle(text, val, cb)
  local b = Instance.new("TextButton", Content)
  b.Size = UDim2.new(1,-20,0,36)
  b.Text = text..": "..(val and "ON" or "OFF")
  b.BackgroundColor3 = val and Color3.fromRGB(160,100,200) or Color3.fromRGB(70,60,80)
  Instance.new("UICorner", b)
  b.MouseButton1Click:Connect(function() val = not val; b.Text = text..": "..(val and "ON" or "OFF"); cb(val); SaveConfig() end)
  return b
end
local function AddInput(placeholder, def, cb)
  local t = Instance.new("TextBox", Content)
  t.Size = UDim2.new(1,-20,0,36)
  t.PlaceholderText = placeholder
  t.Text = tostring(def or "")
  t.FocusLost:Connect(function() cb(t.Text); SaveConfig() end)
  Instance.new("UICorner", t)
  return t
end
local function SideButton(text, cb, y)
  local b = Instance.new("TextButton", Sidebar)
  b.Size = UDim2.new(1,-10,0,34)
  b.Position = UDim2.new(0,5,0,y)
  b.Text = text
  b.BackgroundColor3 = Color3.fromRGB(90,50,170)
  Instance.new("UICorner", b)
  b.MouseButton1Click:Connect(cb)
  return b
end

-- Panels
local function Panel_WEBHOOK()
  ClearContent(); AddLabel("WEBHOOKS"); AddToggle("Discord Notify", Config.Notify, function(v) Config.Notify = v end)
  local url = ""
  local row = Instance.new("Frame", Content); row.Size = UDim2.new(1,-20,0,36); row.BackgroundTransparency = 1
  local tb = Instance.new("TextBox", row); tb.Size = UDim2.new(1,-130,1,0); tb.PlaceholderText = "Webhook URL"; tb:GetPropertyChangedSignal("Text"):Connect(function() url = tb.Text end); Instance.new("UICorner", tb)
  local add = Instance.new("TextButton", row); add.Size = UDim2.new(0,120,1,0); add.Position = UDim2.new(1,-10,0,0); add.Text = "ADD"; add.BackgroundColor3 = Color3.fromRGB(100,140,100); Instance.new("UICorner", add)
  add.MouseButton1Click:Connect(function() if url~="" then table.insert(Config.Webhooks, url); SaveConfig(); Notify("Webhook","Ditambahkan"); Panel_WEBHOOK() end end)
  AddLabel("Stored Webhooks:")
  for i,u in ipairs(Config.Webhooks) do local r=Instance.new("Frame", Content); r.Size=UDim2.new(1,-20,0,28); r.BackgroundTransparency=1; local l=Instance.new("TextLabel", r); l.Size=UDim2.new(1,-80,1,0); l.BackgroundTransparency=1; l.Text=u; l.Font=Enum.Font.Gotham; local d=Instance.new("TextButton", r); d.Size=UDim2.new(0,70,1,0); d.Position=UDim2.new(1,-70,0,0); d.Text="DEL"; d.BackgroundColor3=Color3.fromRGB(140,80,80); Instance.new("UICorner", d); d.MouseButton1Click:Connect(function() table.remove(Config.Webhooks,i); SaveConfig(); Notify("Webhook","Dihapus"); Panel_WEBHOOK() end) end
  local test = Instance.new("TextButton", Content); test.Size=UDim2.new(1,-20,0,36); test.Text='TEST WEBHOOK'; test.BackgroundColor3=Color3.fromRGB(100,160,120); Instance.new('UICorner', test); test.MouseButton1Click:Connect(TestWebhook)
end
local function Panel_UTILITY()
  ClearContent(); AddLabel('UTILITY'); AddToggle('AutoSave', Config.AutoSave, function(v) Config.AutoSave=v end)
  AddToggle('AutoExecute', Config.AutoExecute, function(v) Config.AutoExecute=v if v and isfile then pcall(function() writefile('Cornello_AutoExec.flag','true') end) elseif isfile then pcall(delfile,'Cornello_AutoExec.flag') end end)
  AddToggle('Show Tap Marker', Config.ShowTapMarker, function(v) Config.ShowTapMarker=v if v then CreateTapMarker() else RemoveTapMarker() end end)
  local sb = Instance.new('TextButton', Content); sb.Size=UDim2.new(1,-20,0,36); sb.Text='SET TAP LOCATION'; sb.BackgroundColor3=Color3.fromRGB(100,80,160); Instance.new('UICorner', sb); sb.MouseButton1Click:Connect(function() StartTapSetter(); Notify('Tap','Klik untuk set lokasi') end)
end
local function Panel_FISH()
  ClearContent(); AddLabel('FISHING'); AddToggle('AutoFish', Config.AutoFish, function(v) Config.AutoFish=v end); AddInput('Fish Interval (sec)', Config.FishInterval or 2, function(v) Config.FishInterval=tonumber(v) or 2 end)
  local t = Instance.new('TextButton', Content); t.Size=UDim2.new(1,-20,0,36); t.Text='TEST FISH'; t.BackgroundColor3=Color3.fromRGB(120,90,200); Instance.new('UICorner', t); t.MouseButton1Click:Connect(function() SimulateTap(); Notify('Fishing','Test fish') end)
end
local function Panel_MISC()
  ClearContent(); AddLabel('MISC'); AddToggle('Anti AFK', Config.AntiAFK, function(v) Config.AntiAFK=v end); AddToggle('Auto Click', Config.AutoClick, function(v) Config.AutoClick=v end); AddInput('AutoClick Delay (sec)', Config.AutoClickDelay or 0.6, function(v) Config.AutoClickDelay = tonumber(v) or 0.6 end)
end
local function Panel_SERVER()
  ClearContent(); AddLabel('SERVER'); AddLabel('PlaceId: '..tostring(PLACE_ID)); AddLabel('JobId: '..tostring(game.JobId or 'N/A'))
  local b = Instance.new('TextButton', Content); b.Size=UDim2.new(1,-20,0,36); b.Text='SEND SERVER INFO'; b.BackgroundColor3=Color3.fromRGB(100,120,180); Instance.new('UICorner', b); b.MouseButton1Click:Connect(function() SendWebhook('Server info requested'); Notify('Server','Info dikirim via webhook') end)
end
local function Panel_INFO()
  ClearContent(); AddLabel('INFO'); AddLabel('Version: v0.0.1 [BETA]'); AddLabel('Author: CornelloTeam')
end

SideButton('WEBHOOK', Panel_WEBHOOK, 8); SideButton('UTILITY', Panel_UTILITY, 54); SideButton('FISH', Panel_FISH, 100); SideButton('MISC', Panel_MISC, 146); SideButton('SERVER', Panel_SERVER, 192); SideButton('INFO', Panel_INFO, 238)
Panel_WEBHOOK()

-- Tap marker & setter
local TapMarker, Overlay = nil, nil
function CreateTapMarker()
  if TapMarker and TapMarker.Parent then TapMarker:Destroy() end
  if not Config.ShowTapMarker then return end
  local ok, cam = pcall(function() return workspace.CurrentCamera end)
  if not ok or not cam then return end
  TapMarker = Instance.new('Frame', ScreenGui); TapMarker.Size = UDim2.new(0, Config.TapMarkerSize or 12, 0, Config.TapMarkerSize or 12); TapMarker.AnchorPoint = Vector2.new(0.5,0.5); TapMarker.BackgroundColor3 = Color3.fromRGB(230,200,255); Instance.new('UICorner', TapMarker)
  task.spawn(function() while TapMarker and TapMarker.Parent do local ok2, cam2 = pcall(function() return workspace.CurrentCamera end) if ok2 and cam2 then local vp = cam2.ViewportSize TapMarker.Position = UDim2.fromOffset((Config.TapLocation.x or 0.5)*vp.X, (Config.TapLocation.y or 0.5)*vp.Y) end task.wait(0.4) end end)
end
function RemoveTapMarker() if TapMarker and TapMarker.Parent then TapMarker:Destroy() end TapMarker = nil end
function StartTapSetter()
  if Overlay and Overlay.Parent then Overlay:Destroy() end
  Overlay = Instance.new('TextButton', ScreenGui); Overlay.Size = UDim2.new(1,0,1,0); Overlay.BackgroundTransparency = 0.5; Overlay.Text = 'Klik untuk set tap. ESC untuk batal'; Overlay.Font = Enum.Font.Gotham; Overlay.TextSize = 24; Overlay.BackgroundColor3 = Color3.fromRGB(40,10,70); Overlay.AutoButtonColor = false
  local c1 = Overlay.MouseButton1Click:Connect(function()
    local pos = UserInputService:GetMouseLocation(); local ok, cam = pcall(function() return workspace.CurrentCamera end)
    if ok and cam then local vp = cam.ViewportSize Config.TapLocation = { x = math.clamp(pos.X / vp.X, 0, 1), y = math.clamp(pos.Y / vp.Y, 0, 1) } SaveConfig(); CreateTapMarker(); Notify('Tap','Lokasi disimpan') end
    if c1 then c1:Disconnect() end
    Overlay:Destroy()
  end)
  local conn = UserInputService.InputBegan:Connect(function(inp) if inp.KeyCode == Enum.KeyCode.Escape then if Overlay and Overlay.Parent then Overlay:Destroy() end conn:Disconnect(); Notify('Tap','Batal') end end)
end

-- Events
GuiService.ErrorMessageChanged:Connect(function(msg) pcall(SendWebhook, msg) end)
Player.AncestryChanged:Connect(function(_,parent) if not parent then pcall(SendWebhook, 'Player Left') end end)

if Config.ShowTapMarker then CreateTapMarker() end
Notify('Cornello','v0.0.1 [BETA] loaded — purple transparent UI')
print('Cornello v0.0.1 [BETA] loaded')
