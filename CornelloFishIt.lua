-- CornelloFishIt — v0.0.1
-- Lightweight fishing helper for "Fish It" with draggable icon UI

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local VirtualInput = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
if not Player then warn("CornelloFishIt: LocalPlayer not found. Run as LocalScript") return end

-- Config
local CONFIG_FILE = "CornelloFishIt.json"
local Default = {
  AutoFish = false,
  FishInterval = 1.8,
  TapLocation = { x = 0.5, y = 0.5 },
  ShowTapMarker = false,
  TapMarkerSize = 12,
  IconPos = { x = 0.03, y = 0.45 }
}
local Config = (type(table.clone)=="function" and table.clone(Default)) or (function(t)local o={} for k,v in pairs(t) do o[k]=v end return o end)(Default)
local function LoadConfig()
  if isfile and isfile(CONFIG_FILE) then
    local ok,data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
    if ok and type(data)=="table" then for k,v in pairs(data) do Config[k]=v end end
  end
end
local function SaveConfig()
  if not isfile then return end
  pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(Config)) end)
end
LoadConfig()

-- Notification helper
local function Notify(title, text)
  pcall(function() StarterGui:SetCore("SendNotification", {Title = title or "FishIt", Text = text or "", Duration = 3}) end)
end

-- Tap simulator
local function SimulateTapAt(xFrac, yFrac)
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

-- AutoFish loop
task.spawn(function()
  while true do
    if Config.AutoFish then
      SimulateTapAt()
      task.wait(math.max(0.05, tonumber(Config.FishInterval) or 1.8))
    else
      task.wait(0.5)
    end
  end
end)

-- UI root
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CornelloFishItUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (pcall(function() return Player:WaitForChild("PlayerGui",5) end) and Player.PlayerGui) or game:GetService("CoreGui")

-- Draggable icon
local Icon = Instance.new("TextButton")
Icon.Name = "FishItIcon"
Icon.Size = UDim2.fromScale(0.08, 0.08)
Icon.Position = UDim2.fromScale(Config.IconPos.x, Config.IconPos.y)
Icon.BackgroundColor3 = Color3.fromRGB(110,50,170)
Icon.BackgroundTransparency = 0.12
Icon.AutoButtonColor = true
Icon.Text = "F"
Icon.Font = Enum.Font.GothamBlack
Icon.TextScaled = true
Icon.TextColor3 = Color3.fromRGB(255,240,255)
Instance.new("UICorner", Icon).CornerRadius = UDim.new(1,0)
Icon.Parent = ScreenGui

-- Main panel
local Main = Instance.new("Frame")
Main.Size = UDim2.fromScale(0.42, 0.5)
Main.Position = UDim2.fromScale(0.13, 0.15)
Main.BackgroundColor3 = Color3.fromRGB(90,40,150)
Main.BackgroundTransparency = 0.6
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,10)
Main.Visible = false
Main.Parent = ScreenGui

local Header = Instance.new("TextLabel", Main)
Header.Size = UDim2.new(1,0,0,36)
Header.BackgroundTransparency = 1
Header.Text = "CornelloFishIt"
Header.Font = Enum.Font.GothamBold
Header.TextColor3 = Color3.new(1,1,1)
Header.TextScaled = true

local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1,0,1,-36)
Content.Position = UDim2.new(0,0,0,36)
Content.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", Content)
layout.Padding = UDim.new(0,8)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local function MakeToggle(text, initial, onChange)
  local btn = Instance.new("TextButton", Content)
  btn.Size = UDim2.new(1,-16,0,36)
  btn.BackgroundColor3 = initial and Color3.fromRGB(160,100,200) or Color3.fromRGB(70,60,80)
  btn.Text = text..": "..(initial and "ON" or "OFF")
  btn.Font = Enum.Font.Gotham
  Instance.new("UICorner", btn)
  btn.MouseButton1Click:Connect(function()
    initial = not initial
    btn.Text = text..": "..(initial and "ON" or "OFF")
    btn.BackgroundColor3 = initial and Color3.fromRGB(160,100,200) or Color3.fromRGB(70,60,80)
    onChange(initial)
    SaveConfig()
  end)
  return btn
end

local function MakeInput(placeholder, value, onSet)
  local tb = Instance.new("TextBox", Content)
  tb.Size = UDim2.new(1,-16,0,36)
  tb.PlaceholderText = placeholder
  tb.Text = tostring(value or "")
  tb.Font = Enum.Font.Gotham
  Instance.new("UICorner", tb)
  tb.FocusLost:Connect(function()
    local v = tonumber(tb.Text) or value
    onSet(v)
    SaveConfig()
  end)
  return tb
end

local autoBtn = MakeToggle("AutoFish", Config.AutoFish, function(v) Config.AutoFish = v end)
local intervalInput = MakeInput("Fish Interval (sec)", Config.FishInterval, function(v) Config.FishInterval = v end)
local showMarkerBtn = MakeToggle("Show Tap Marker", Config.ShowTapMarker, function(v) Config.ShowTapMarker = v if v then CreateTapMarker() else RemoveTapMarker() end end)

local setTapBtn = Instance.new("TextButton", Content)
setTapBtn.Size = UDim2.new(1,-16,0,36)
setTapBtn.Text = "SET TAP LOCATION"
setTapBtn.BackgroundColor3 = Color3.fromRGB(100,80,160)
Instance.new("UICorner", setTapBtn)
setTapBtn.MouseButton1Click:Connect(function() StartTapSetter(); Notify('Tap','Klik layar untuk set lokasi') end)

local testBtn = Instance.new("TextButton", Content)
testBtn.Size = UDim2.new(1,-16,0,36)
testBtn.Text = "TEST FISH"
testBtn.BackgroundColor3 = Color3.fromRGB(100,160,120)
Instance.new("UICorner", testBtn)
testBtn.MouseButton1Click:Connect(function() SimulateTap(); Notify('Fishing','Test fish dikirim') end)

local infoLabel = Instance.new("TextLabel", Content)
infoLabel.Size = UDim2.new(1,-16,0,24)
infoLabel.Text = "Version: v0.0.1 — Fish It helper"
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.fromRGB(230,220,255)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 14

-- Tap marker
local TapMarker
function CreateTapMarker()
  if TapMarker and TapMarker.Parent then TapMarker:Destroy() end
  if not Config.ShowTapMarker then return end
  local ok, cam = pcall(function() return workspace.CurrentCamera end)
  if not ok or not cam then return end
  TapMarker = Instance.new('Frame', ScreenGui)
  TapMarker.Size = UDim2.new(0, Config.TapMarkerSize or 12, 0, Config.TapMarkerSize or 12)
  TapMarker.AnchorPoint = Vector2.new(0.5,0.5)
  TapMarker.BackgroundColor3 = Color3.fromRGB(230,200,255)
  Instance.new('UICorner', TapMarker)
  task.spawn(function()
    while TapMarker and TapMarker.Parent do
      local ok2, cam2 = pcall(function() return workspace.CurrentCamera end)
      if ok2 and cam2 then local vp = cam2.ViewportSize TapMarker.Position = UDim2.fromOffset((Config.TapLocation.x or 0.5)*vp.X, (Config.TapLocation.y or 0.5)*vp.Y) end
      task.wait(0.4)
    end
  end)
end
function RemoveTapMarker() if TapMarker and TapMarker.Parent then TapMarker:Destroy() end TapMarker = nil end

-- Tap setter overlay
local Overlay
function StartTapSetter()
  if Overlay and Overlay.Parent then Overlay:Destroy() end
  Overlay = Instance.new('TextButton', ScreenGui)
  Overlay.Size = UDim2.new(1,0,1,0)
  Overlay.BackgroundTransparency = 0.5
  Overlay.Text = 'Klik untuk set tap. ESC untuk batal'
  Overlay.Font = Enum.Font.Gotham
  Overlay.BackgroundColor3 = Color3.fromRGB(40,10,70)
  Overlay.AutoButtonColor = false
  local c
  c = Overlay.MouseButton1Click:Connect(function()
    local pos = UserInputService:GetMouseLocation(); local ok, cam = pcall(function() return workspace.CurrentCamera end)
    if ok and cam then local vp = cam.ViewportSize Config.TapLocation = { x = math.clamp(pos.X / vp.X, 0, 1), y = math.clamp(pos.Y / vp.Y, 0, 1) } SaveConfig(); CreateTapMarker(); Notify('Tap','Lokasi disimpan') end
    if c then c:Disconnect() end
    if Overlay and Overlay.Parent then Overlay:Destroy() end
  end)
  local conn = UserInputService.InputBegan:Connect(function(inp) if inp.KeyCode == Enum.KeyCode.Escape then if Overlay and Overlay.Parent then Overlay:Destroy() end conn:Disconnect(); Notify('Tap','Batal') end end)
end

-- Draggable icon behavior
local dragging = false
local dragOffset = Vector2.new(0,0)
Icon.InputBegan:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.MouseButton1 then
    dragging = true
    local mousePos = UserInputService:GetMouseLocation()
    dragOffset = Vector2.new(mousePos.X - Icon.AbsolutePosition.X, mousePos.Y - Icon.AbsolutePosition.Y)
  elseif input.UserInputType == Enum.UserInputType.Touch then -- tap toggles main
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

-- Click icon to toggle
Icon.MouseButton1Click:Connect(function()
  Main.Visible = not Main.Visible
end)

-- Events
Player.AncestryChanged:Connect(function(_,parent) if not parent then pcall(SimulateTapAt) end end)

if Config.ShowTapMarker then CreateTapMarker() end
Notify('CornelloFishIt','v0.0.1 loaded')
print('CornelloFishIt v0.0.1 loaded')
