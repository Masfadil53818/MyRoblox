-- CornelloFishIt — v0.0.2
-- Reworked: Utility, Misc, Info, Script, Webhook, Server panels with modal UI and draggable icon

-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local VirtualInput = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
if not Player then warn("CornelloFishIt: LocalPlayer not found. Run as LocalScript") return end

-- Config
local CONFIG_FILE = "CornelloFishIt.json"
local Default = {
  AutoClick = false,
  AutoClickDelay = 0.6,
  AntiAFK = true,
  TapLocation = { x = 0.5, y = 0.5 },
  ShowTapMarker = false,
  TapMarkerSize = 12,
  IconPos = { x = 0.03, y = 0.45 },
  Webhooks = {},
  DiscordID = "",
  SavedScripts = {}
}
local Config = (type(table.clone)=="function" and table.clone(Default)) or (function(t)local o={} for k,v in pairs(t) do o[k]=v end return o end)(Default)
local function LoadConfig()
  if isfile and isfile(CONFIG_FILE) then
    local ok,data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
    if ok and type(data)=="table" then for k,v in pairs(data) do Config[k]=v end end
  end
end
local function SaveConfig(force)
  if not isfile then return end
  if Config.AutoSave==nil then Config.AutoSave = true end
  pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(Config)) end)
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
  if not ok then warn("CornelloFishIt: request failed", res) end
  return ok,res
end

local function now()
  local t = os.date("*t")
  return string.format("%02d:%02d:%02d", t.hour,t.min,t.sec), string.format("%02d/%02d/%04d", t.day,t.month,t.year)
end

-- Webhook helpers
local function SendWebhook(reason)
  if #Config.Webhooks==0 then return false end
  local time, day = now()
  local ping = (Config.DiscordID ~= "") and ("<@"..Config.DiscordID..">") or ""
  for _,url in ipairs(Config.Webhooks) do
    local ok,_ = safeRequest({
      Url = url,
      Method = "POST",
      Headers = { ["Content-Type"] = "application/json" },
      Body = HttpService:JSONEncode({ content = ping, embeds = {{ title = "Cornello Alert", color = 0x8E44AD, fields = {{name="Player", value = Player.Name}, {name="Time", value = time, inline=true}, {name="Date", value = day, inline=true}, {name="Reason", value = reason}, {name="PlaceId", value = tostring(game.PlaceId)} } } } )
    })
    if not ok then warn("CornelloFishIt: webhook failed for", url) end
  end
  return true
end
local function TestWebhook()
  if #Config.Webhooks == 0 then Notify("Webhook","Belum ada webhook") return end
  local time,day = now()
  for _,url in ipairs(Config.Webhooks) do
    safeRequest({Url=url, Method="POST", Headers={ ["Content-Type"]="application/json" }, Body=HttpService:JSONEncode({ content = (Config.DiscordID ~= "" and ("<@"..Config.DiscordID..">") or ""), embeds={{ title = "Webhook Test", description = "CornelloFishIt v0.0.2 - Test", color = 0x8E44AD, fields = {{name="Time", value=time, inline=true}, {name="Date", value=day, inline=true}} } } ) })
  end
  Notify("Webhook","Test dikirim")
end

-- Tap simulator
local function SimulateTap(xFrac, yFrac)
  local ok, cam = pcall(function() return workspace.CurrentCamera end)
  if not ok or not cam then return end
  local vp = cam.ViewportSize
  local vx, vy = vp.X * (xFrac or Config.TapLocation.x), vp.Y * (yFrac or Config.TapLocation.y)
  pcall(function()
    if VirtualInput and VirtualInput.SendTouchEvent then
      VirtualInput:SendTouchEvent(true, vx, vy, 0)
      task.wait(0.04)
      VirtualInput:SendTouchEvent(false, vx, vy, 0)
    else
      VirtualInput:SendMouseButtonEvent(vx, vy, 0, true, game, 0)
      task.wait(0.04)
      VirtualInput:SendMouseButtonEvent(vx, vy, 0, false, game, 0)
    end
  end)
end

-- UI root
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CornelloFishItUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = (pcall(function() return Player:WaitForChild("PlayerGui",6) end) and Player.PlayerGui) or game:GetService("CoreGui")

-- Modal helper
local Modal = Instance.new("Frame")
Modal.Size = UDim2.new(1,0,1,0)
Modal.BackgroundTransparency = 0.5
Modal.BackgroundColor3 = Color3.fromRGB(10,10,12)
Modal.Visible = false
Modal.ZIndex = 3000
Modal.Parent = ScreenGui
local ModalContent = Instance.new("Frame", Modal)
ModalContent.Size = UDim2.new(0.6,0,0.6,0)
ModalContent.Position = UDim2.new(0.2,0,0.2,0)
ModalContent.BackgroundColor3 = Color3.fromRGB(40,20,70)
Instance.new("UICorner", ModalContent).CornerRadius = UDim.new(0,10)
local ModalHeader = Instance.new("TextLabel", ModalContent)
ModalHeader.Size = UDim2.new(1,0,0,36)
ModalHeader.BackgroundTransparency = 1
ModalHeader.Font = Enum.Font.GothamBold
ModalHeader.TextColor3 = Color3.new(1,1,1)
ModalHeader.Text = ""
local ModalClose = Instance.new("TextButton", ModalContent)
ModalClose.Size = UDim2.new(0,80,0,28)
ModalClose.Position = UDim2.new(1,-90,0,4)
ModalClose.Text = "Close"
ModalClose.BackgroundColor3 = Color3.fromRGB(120,60,120)
Instance.new("UICorner", ModalClose)
ModalClose.MouseButton1Click:Connect(function() Modal.Visible = false end)

local function ShowModal(title, buildFn)
  ModalHeader.Text = title or "Modal"
  for _,v in pairs(ModalContent:GetChildren()) do if v~=ModalHeader and v~=ModalClose then v:Destroy() end end
  if type(buildFn)=="function" then buildFn(ModalContent) end
  Modal.Visible = true
end

-- Draggable icon
local Icon = Instance.new("TextButton", ScreenGui)
Icon.Name = "FishItIcon"
Icon.Size = UDim2.fromScale(0.08, 0.08)
Icon.Position = UDim2.fromScale(Config.IconPos.x, Config.IconPos.y)
Icon.BackgroundColor3 = Color3.fromRGB(110,50,170)
Icon.BackgroundTransparency = 0.12
Icon.Text = "C"
Icon.Font = Enum.Font.GothamBlack
Icon.TextScaled = true
Icon.TextColor3 = Color3.fromRGB(255,230,255)
Instance.new("UICorner", Icon).CornerRadius = UDim.new(1,0)

-- Main panel (compact launcher)
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromScale(0.22, 0.28)
Main.Position = UDim2.fromScale(0.13, 0.14)
Main.BackgroundColor3 = Color3.fromRGB(80,36,140)
Main.BackgroundTransparency = 0.55
Instance.new('UICorner', Main).CornerRadius = UDim.new(0,10)

local Header = Instance.new('TextLabel', Main)
Header.Size = UDim2.new(1,0,0,30)
Header.BackgroundTransparency = 1
Header.Text = 'Cornello Tool'
Header.Font = Enum.Font.GothamBold
Header.TextColor3 = Color3.new(1,1,1)

local btns = {}
local function AddMainButton(text, cb, y)
  local b = Instance.new('TextButton', Main)
  b.Size = UDim2.new(1,-12,0,28)
  b.Position = UDim2.new(0,6,0,34 + (y or (#btns*34)))
  b.Text = text
  b.BackgroundColor3 = Color3.fromRGB(110,60,180)
  Instance.new('UICorner', b)
  b.MouseButton1Click:Connect(cb)
  table.insert(btns,b)
  return b
end

AddMainButton('UTILITY', function() ShowModal('UTILITY', function(parent)
  local y=40
  local t = Instance.new('TextLabel', parent); t.Position = UDim2.new(0,12,0,40); t.Size = UDim2.new(1,-24,0,24); t.Text = 'AutoClick: '..(Config.AutoClick and 'ON' or 'OFF'); t.BackgroundTransparency=1; t.Font=Enum.Font.Gotham; t.TextColor3=Color3.new(1,1,1)
  local tb = Instance.new('TextButton', parent); tb.Position = UDim2.new(0,12,0,68); tb.Size=UDim2.new(0,160,0,32); tb.Text='Toggle AutoClick'; tb.BackgroundColor3 = Color3.fromRGB(120,70,160); Instance.new('UICorner',tb)
  tb.MouseButton1Click:Connect(function() Config.AutoClick = not Config.AutoClick; SaveConfig(); Notify('Utility','AutoClick '..(Config.AutoClick and 'ON' or 'OFF')); ShowModal('UTILITY', function() end) end)
  local inpt = Instance.new('TextBox', parent); inpt.Position = UDim2.new(0,12,0,108); inpt.Size=UDim2.new(0,160,0,28); inpt.PlaceholderText = 'AutoClick Delay (sec)'; inpt.Text = tostring(Config.AutoClickDelay or 0.6); inpt.FocusLost:Connect(function() Config.AutoClickDelay = tonumber(inpt.Text) or Config.AutoClickDelay; SaveConfig(); Notify('Utility','Delay set') end)
end) end)

AddMainButton('MISC', function() ShowModal('MISC', function(parent)
  local t = Instance.new('TextLabel', parent); t.Position = UDim2.new(0,12,0,40); t.Size = UDim2.new(1,-24,0,24); t.Text = 'AntiAFK: '..(Config.AntiAFK and 'ON' or 'OFF'); t.BackgroundTransparency=1; t.Font=Enum.Font.Gotham; t.TextColor3=Color3.new(1,1,1)
  local btn = Instance.new('TextButton', parent); btn.Position = UDim2.new(0,12,0,72); btn.Size = UDim2.new(0,160,0,32); btn.Text = 'Toggle AntiAFK'; Instance.new('UICorner', btn); btn.BackgroundColor3 = Color3.fromRGB(120,70,160)
  btn.MouseButton1Click:Connect(function() Config.AntiAFK = not Config.AntiAFK; SaveConfig(); Notify('Misc','AntiAFK '..(Config.AntiAFK and 'ON' or 'OFF')) end)
  local setTap = Instance.new('TextButton', parent); setTap.Position = UDim2.new(0,12,0,112); setTap.Size = UDim2.new(0,160,0,32); setTap.Text = 'Set Tap Location'; setTap.BackgroundColor3 = Color3.fromRGB(100,80,160); Instance.new('UICorner', setTap)
  setTap.MouseButton1Click:Connect(function() StartTapSetter(); Notify('Tap','Klik layar untuk set lokasi') end)
end) end)

AddMainButton('WEBHOOK', function() ShowModal('WEBHOOK', function(parent)
  local input = Instance.new('TextBox', parent); input.Position = UDim2.new(0,12,0,40); input.Size = UDim2.new(1,-24,0,30); input.PlaceholderText = 'Webhook URL'; Instance.new('UICorner', input)
  local add = Instance.new('TextButton', parent); add.Position = UDim2.new(0,12,0,78); add.Size = UDim2.new(0,140,0,32); add.Text='ADD WEBHOOK'; add.BackgroundColor3 = Color3.fromRGB(90,140,90); Instance.new('UICorner', add)
  add.MouseButton1Click:Connect(function() if input.Text~='' then table.insert(Config.Webhooks, input.Text); SaveConfig(); Notify('Webhook','Ditambahkan') end end)
  local test = Instance.new('TextButton', parent); test.Position = UDim2.new(0,160,0,78); test.Size=UDim2.new(0,120,0,32); test.Text = 'TEST'; test.BackgroundColor3 = Color3.fromRGB(100,160,120); Instance.new('UICorner', test)
  test.MouseButton1Click:Connect(TestWebhook)
  local y = 120
  for i,u in ipairs(Config.Webhooks) do local lbl = Instance.new('TextLabel', parent); lbl.Position = UDim2.new(0,12,0,y); lbl.Size = UDim2.new(1,-96,0,24); lbl.Text = u; lbl.BackgroundTransparency=1; local del = Instance.new('TextButton', parent); del.Position = UDim2.new(1,-76,0,y); del.Size = UDim2.new(0,64,0,24); del.Text='DEL'; del.BackgroundColor3 = Color3.fromRGB(160,80,80); Instance.new('UICorner',del); del.MouseButton1Click:Connect(function() table.remove(Config.Webhooks,i); SaveConfig(); ShowModal('WEBHOOK', function() end) end) y = y + 30 end
end) end)

AddMainButton('SERVER', function() ShowModal('SERVER', function(parent)
  local p = Instance.new('TextLabel', parent); p.Position = UDim2.new(0,12,0,40); p.Size = UDim2.new(1,-24,0,24); p.Text = 'PlaceId: '..tostring(game.PlaceId); p.BackgroundTransparency = 1
  local j = Instance.new('TextLabel', parent); j.Position = UDim2.new(0,12,0,72); j.Size = UDim2.new(1,-24,0,24); j.Text = 'JobId: '..tostring(game.JobId or 'N/A'); j.BackgroundTransparency = 1
  local send = Instance.new('TextButton', parent); send.Position = UDim2.new(0,12,0,108); send.Size = UDim2.new(0,160,0,32); send.Text='SEND SERVER INFO'; send.BackgroundColor3 = Color3.fromRGB(100,120,180); Instance.new('UICorner', send)
  send.MouseButton1Click:Connect(function() SendWebhook('Server info requested'); Notify('Server','Info dikirim via webhook') end)
end) end)

AddMainButton('SCRIPT', function() ShowModal('SCRIPT', function(parent)
  local editor = Instance.new('TextBox', parent); editor.Size = UDim2.new(1,-24,0,240); editor.Position = UDim2.new(0,12,0,40); editor.ClearTextOnFocus = false; editor.TextWrapped = true; editor.Text = table.concat(Config.SavedScripts and Config.SavedScripts[1] or {""},"\n"); editor.Font = Enum.Font.Code; Instance.new('UICorner', editor)
  local run = Instance.new('TextButton', parent); run.Position = UDim2.new(0,12,0,292); run.Size = UDim2.new(0,120,0,32); run.Text='RUN'; run.BackgroundColor3 = Color3.fromRGB(100,160,120); Instance.new('UICorner', run)
  local save = Instance.new('TextButton', parent); save.Position = UDim2.new(0,140,0,292); save.Size = UDim2.new(0,120,0,32); save.Text='SAVE'; save.BackgroundColor3 = Color3.fromRGB(100,120,200); Instance.new('UICorner', save)
  run.MouseButton1Click:Connect(function() local ok,err = pcall(function() local f = loadstring(editor.Text) if type(f)=="function" then f() end end) if not ok then Notify('Script','Runtime error: '..tostring(err)) else Notify('Script','Executed') end end)
  save.MouseButton1Click:Connect(function() Config.SavedScripts = Config.SavedScripts or {}; Config.SavedScripts[1] = {editor.Text}; SaveConfig(); Notify('Script','Saved') end)
end) end)

-- Tap marker
local TapMarker
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
  Overlay = Instance.new('TextButton', ScreenGui); Overlay.Size = UDim2.new(1,0,1,0); Overlay.BackgroundTransparency = 0.5; Overlay.Text = 'Klik untuk set tap. ESC untuk batal'; Overlay.Font = Enum.Font.Gotham; Overlay.BackgroundColor3 = Color3.fromRGB(40,10,70); Overlay.AutoButtonColor = false
  local c1 = Overlay.MouseButton1Click:Connect(function()
    local pos = UserInputService:GetMouseLocation(); local ok, cam = pcall(function() return workspace.CurrentCamera end)
    if ok and cam then local vp = cam.ViewportSize Config.TapLocation = { x = math.clamp(pos.X / vp.X, 0, 1), y = math.clamp(pos.Y / vp.Y, 0, 1) } SaveConfig(); CreateTapMarker(); Notify('Tap','Lokasi disimpan') end
    if c1 then c1:Disconnect() end
    Overlay:Destroy()
  end)
  local conn = UserInputService.InputBegan:Connect(function(inp) if inp.KeyCode == Enum.KeyCode.Escape then if Overlay and Overlay.Parent then Overlay:Destroy() end conn:Disconnect(); Notify('Tap','Batal') end end)
end

-- Dragging icon
local dragging = false
local dragOffset = Vector2.new(0,0)
Icon.InputBegan:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.MouseButton1 then
    dragging = true
    local mousePos = UserInputService:GetMouseLocation()
    dragOffset = Vector2.new(mousePos.X - Icon.AbsolutePosition.X, mousePos.Y - Icon.AbsolutePosition.Y)
  elseif input.UserInputType == Enum.UserInputType.Touch then
    -- open main on touch
    Main.Visible = not Main.Visible
  end
end)
UserInputService.InputChanged:Connect(function(input)
  if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
    local pos = UserInputService:GetMouseLocation()
    local nx, ny = (pos.X - dragOffset.X)/workspace.CurrentCamera.ViewportSize.X, (pos.Y - dragOffset.Y)/workspace.CurrentCamera.ViewportSize.Y
    Icon.Position = UDim2.fromScale(math.clamp(nx, 0, 0.9), math.clamp(ny, 0, 0.9))
  end
end)
UserInputService.InputEnded:Connect(function(input)
  if dragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
    dragging = false
    local p = Icon.Position
    Config.IconPos = { x = p.X.Scale, y = p.Y.Scale }
    SaveConfig()
  end
end)
Icon.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)

-- Events
GuiService.ErrorMessageChanged:Connect(function(msg) pcall(SendWebhook, msg) end)
Player.AncestryChanged:Connect(function(_,parent) if not parent then pcall(SendWebhook, 'Player Left') end end)

if Config.ShowTapMarker then CreateTapMarker() end
Notify('CornelloFishIt','v0.0.2 loaded')
print('CornelloFishIt v0.0.2 loaded')
