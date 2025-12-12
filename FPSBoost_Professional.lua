--[[
    ═══════════════════════════════════════════════════════════════
    FPS BOOST PROFESSIONAL PANEL v2.0
    ═══════════════════════════════════════════════════════════════
    Features:
    ✓ Advanced FPS Optimization (Shadows, Particles, Decals, Terrain)
    ✓ Anti-AFK with Virtual User
    ✓ Auto-Rejoin on Disconnect
    ✓ Professional Responsive UI
    ✓ Minimize to Icon
    ✓ User Settings & Presets
    ✓ Mobile/Tablet/PC Support
    ✓ Autosave Configuration
    ═══════════════════════════════════════════════════════════════
]]--

-- ═════════════════════════════════════════════════════════════
-- 1. INITIALIZATION & SERVICES
-- ═════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Check executor capabilities
local has_writefile = type(writefile) == "function"
local has_readfile = type(readfile) == "function"
local has_isfile = type(isfile) == "function"

-- ═════════════════════════════════════════════════════════════
-- 2. CONFIGURATION & SETTINGS
-- ═════════════════════════════════════════════════════════════
local CONFIG_FILE = "fps_boost_pro_config.json"

local DEFAULT_SETTINGS = {
    -- FPS Settings
    fps = {
        shadowsEnabled = false,
        particlesEnabled = false,
        decalsEnabled = false,
        plasticsEnabled = true,
        lightingQuality = 0.5,
        terrainQuality = 0,
        textureQuality = 0.3,
    },
    -- Player Settings
    player = {
        walkSpeed = 16,
        jumpPower = 50,
        fieldOfView = 70,
    },
    -- Utility Settings
    utility = {
        antiAFK = true,
        antiAFKInterval = 3,
        autoRejoin = true,
        rejoinDelay = 10,
    },
    -- UI Settings
    ui = {
        theme = "Dark",
        minimized = false,
        position = {x = 0.5, y = 0.5},
    },
}

-- Global state
local Settings = {}
local OriginalValues = {}
local ActiveConnections = {}

-- Deep copy function
local function deepCopy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local result = {}
    for k, v in pairs(tbl) do
        result[k] = deepCopy(v)
    end
    return result
end

-- Initialize settings
function LoadSettings()
    Settings = deepCopy(DEFAULT_SETTINGS)
    
    if has_readfile and has_isfile and isfile(CONFIG_FILE) then
        local ok, data = pcall(readfile, CONFIG_FILE)
        if ok and data then
            local decoded = HttpService:JSONDecode(data)
            if decoded then
                Settings = decoded
            end
        end
    end
end

function SaveSettings()
    if not has_writefile then return end
    local encoded = HttpService:JSONEncode(Settings)
    pcall(writefile, CONFIG_FILE, encoded)
end

LoadSettings()

-- Store original lighting values
OriginalValues.GlobalShadows = Lighting.GlobalShadows
OriginalValues.Brightness = Lighting.Brightness
OriginalValues.FogEnd = Lighting.FogEnd
OriginalValues.Atmosphere = (Lighting:FindFirstChild("Atmosphere") and Lighting.Atmosphere.Density) or nil

-- ═════════════════════════════════════════════════════════════
-- 3. UTILITY FUNCTIONS
-- ═════════════════════════════════════════════════════════════
local function log(msg)
    print("[FPS BOOST PRO] " .. tostring(msg))
end

local function notify(title, text, duration)
    duration = duration or 3
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration
        })
    end)
end

local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Get device type
local function getDeviceType()
    local size = Mouse.ViewSizeX
    if size < 600 then return "mobile" end
    if size < 1200 then return "tablet" end
    return "desktop"
end

-- Tween helper
local function tweenObject(object, properties, duration)
    duration = duration or 0.3
    local tweenInfo = TweenInfo.new(
        duration,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

-- ═════════════════════════════════════════════════════════════
-- 4. FPS OPTIMIZATION FUNCTIONS
-- ═════════════════════════════════════════════════════════════
local function SetShadows(enabled)
    pcall(function()
        Lighting.GlobalShadows = enabled
    end)
end

local function ToggleParticles(enabled)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") then
            obj.Enabled = enabled
        end
    end
end

local function ToggleDecals(enabled)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = enabled and 0 or 1
        end
    end
end

local function SetPlastics(enabled)
    if not enabled then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                pcall(function()
                    obj.Material = Enum.Material.Plastic
                end)
            end
        end
    end
end

local function OptimizeTerrain()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        pcall(function()
            terrain:FillBall(Vector3.new(0, 0, 0), 0)
        end)
    end
end

local function ReduceLighting(amount)
    amount = clamp(amount, 0, 1)
    Lighting.Brightness = OriginalValues.Brightness * (1 - 0.6 * amount)
    Lighting.FogEnd = OriginalValues.FogEnd * (1 + 3 * amount)
    if Lighting:FindFirstChild("Atmosphere") and OriginalValues.Atmosphere then
        Lighting.Atmosphere.Density = OriginalValues.Atmosphere * (1 - 0.7 * amount)
    end
end

local function RestoreLighting()
    Lighting.GlobalShadows = OriginalValues.GlobalShadows
    Lighting.Brightness = OriginalValues.Brightness
    Lighting.FogEnd = OriginalValues.FogEnd
    if Lighting:FindFirstChild("Atmosphere") and OriginalValues.Atmosphere then
        Lighting.Atmosphere.Density = OriginalValues.Atmosphere
    end
end

local function ApplyFPSSettings()
    local fps = Settings.fps
    SetShadows(fps.shadowsEnabled)
    ToggleParticles(fps.particlesEnabled)
    ToggleDecals(fps.decalsEnabled)
    SetPlastics(fps.plasticsEnabled)
    ReduceLighting(fps.lightingQuality)
    OptimizeTerrain()
end

-- ═════════════════════════════════════════════════════════════
-- 5. PLAYER UTILITIES
-- ═════════════════════════════════════════════════════════════
local function SetPlayerStats()
    if LocalPlayer and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            pcall(function()
                humanoid.WalkSpeed = Settings.player.walkSpeed
                humanoid.JumpPower = Settings.player.jumpPower
            end)
        end
    end
end

local function SetFieldOfView(fov)
    pcall(function()
        workspace.CurrentCamera.FieldOfView = clamp(fov, 1, 120)
    end)
end

-- ═════════════════════════════════════════════════════════════
-- 6. ANTI-AFK SYSTEM
-- ═════════════════════════════════════════════════════════════
local AntiAFK = {
    enabled = Settings.utility.antiAFK,
    interval = Settings.utility.antiAFKInterval,
    connection = nil,
}

function AntiAFK:Enable()
    if self.connection then return end
    self.enabled = true
    self.connection = RunService.Heartbeat:Connect(function()
        if self.enabled then
            pcall(function()
                local args = {game:GetService("VirtualUser"), {
                    KeyCode.Space,
                    KeyCode.E,
                }}
                if game:GetService("VirtualUser") then
                    game:GetService("VirtualUser"):Button1Down(Vector2.new(0, 0))
                    game:wait(0.1)
                    game:GetService("VirtualUser"):Button1Up(Vector2.new(0, 0))
                end
            end)
        end
    end)
    log("Anti-AFK Enabled")
end

function AntiAFK:Disable()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    self.enabled = false
    log("Anti-AFK Disabled")
end

-- ═════════════════════════════════════════════════════════════
-- 7. AUTO-REJOIN SYSTEM
-- ═════════════════════════════════════════════════════════════
local AutoRejoin = {
    enabled = Settings.utility.autoRejoin,
    delay = Settings.utility.rejoinDelay,
}

function AutoRejoin:Rejoin()
    if not self.enabled then return end
    task.wait(self.delay)
    pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

-- Detect disconnection
Players.LocalPlayer.AncestryChanged:Connect(function()
    if LocalPlayer and LocalPlayer.Parent == nil then
        AutoRejoin:Rejoin()
    end
end)

-- ═════════════════════════════════════════════════════════════
-- 8. PROFESSIONAL UI CREATION
-- ═════════════════════════════════════════════════════════════

-- Remove old GUI if exists
pcall(function()
    LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("FPSBoostProPanel"):Destroy()
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FPSBoostProPanel"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Get device type
local deviceType = getDeviceType()

-- Responsive sizes
local panelSize = deviceType == "mobile" and {w = 300, h = 400} or 
                  deviceType == "tablet" and {w = 450, h = 500} or 
                  {w = 600, h = 550}

-- Color scheme
local COLORS = {
    bg = Color3.fromRGB(20, 20, 30),
    secondary = Color3.fromRGB(35, 35, 50),
    accent = Color3.fromRGB(100, 200, 255),
    text = Color3.fromRGB(240, 240, 240),
    success = Color3.fromRGB(100, 200, 100),
    danger = Color3.fromRGB(255, 100, 100),
}

-- Create main panel
local MainPanel = Instance.new("Frame")
MainPanel.Name = "MainPanel"
MainPanel.Size = UDim2.new(0, panelSize.w, 0, panelSize.h)
MainPanel.Position = UDim2.new(0.5, -panelSize.w/2, 0.5, -panelSize.h/2)
MainPanel.BackgroundColor3 = COLORS.bg
MainPanel.BorderSizePixel = 0
MainPanel.Parent = ScreenGui

local UICorner = Instance.new("UICorner", MainPanel)
UICorner.CornerRadius = UDim.new(0, 15)

local UIStroke = Instance.new("UIStroke", MainPanel)
UIStroke.Color = COLORS.accent
UIStroke.Thickness = 2
UIStroke.Transparency = 0.5

-- Title bar
local TitleBar = Instance.new("Frame", MainPanel)
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = COLORS.secondary
TitleBar.BorderSizePixel = 0

local TitleCorner = Instance.new("UICorner", TitleBar)
TitleCorner.CornerRadius = UDim.new(0, 15)

local Title = Instance.new("TextLabel", TitleBar)
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ FPS BOOST PRO"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = COLORS.text
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Position = UDim2.new(0, 12, 0, 0)

-- Minimize button
local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Name = "MinBtn"
MinBtn.Size = UDim2.new(0, 40, 0, 40)
MinBtn.Position = UDim2.new(1, -50, 0, 5)
MinBtn.BackgroundColor3 = COLORS.secondary
MinBtn.TextColor3 = COLORS.text
MinBtn.TextSize = 20
MinBtn.Text = "−"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0

local MinCorner = Instance.new("UICorner", MinBtn)
MinCorner.CornerRadius = UDim.new(0, 8)

-- Close button
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -95, 0, 5)
CloseBtn.BackgroundColor3 = COLORS.danger
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 20
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0

local CloseCorner = Instance.new("UICorner", CloseBtn)
CloseCorner.CornerRadius = UDim.new(0, 8)

-- Tab system
local TabContainer = Instance.new("Frame", MainPanel)
TabContainer.Name = "Tabs"
TabContainer.Size = UDim2.new(0, 150, 1, -50)
TabContainer.Position = UDim2.new(0, 0, 0, 50)
TabContainer.BackgroundColor3 = COLORS.secondary
TabContainer.BorderSizePixel = 0

local TabLayout = Instance.new("UIListLayout", TabContainer)
TabLayout.Padding = UDim.new(0, 5)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder

local TabPadding = Instance.new("UIPadding", TabContainer)
TabPadding.PaddingTop = UDim.new(0, 8)
TabPadding.PaddingLeft = UDim.new(0, 8)
TabPadding.PaddingRight = UDim.new(0, 8)

-- Content area
local ContentArea = Instance.new("Frame", MainPanel)
ContentArea.Name = "Content"
ContentArea.Size = UDim2.new(1, -158, 1, -50)
ContentArea.Position = UDim2.new(0, 150, 0, 50)
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel = 0
ContentArea.ClipsDescendants = true

-- Floating icon (when minimized)
local FloatingIcon = Instance.new("ImageButton", ScreenGui)
FloatingIcon.Name = "FloatingIcon"
FloatingIcon.Size = UDim2.new(0, 60, 0, 60)
FloatingIcon.Position = UDim2.new(0.05, 0, 0.5, 0)
FloatingIcon.BackgroundColor3 = COLORS.accent
FloatingIcon.BorderSizePixel = 0
FloatingIcon.Visible = false

local FloatingCorner = Instance.new("UICorner", FloatingIcon)
FloatingCorner.CornerRadius = UDim.new(0, 15)

local FloatingText = Instance.new("TextLabel", FloatingIcon)
FloatingText.Size = UDim2.new(1, 0, 1, 0)
FloatingText.BackgroundTransparency = 1
FloatingText.Text = "⚡"
FloatingText.TextSize = 30
FloatingText.TextColor3 = COLORS.bg
FloatingText.Font = Enum.Font.GothamBold

-- ═════════════════════════════════════════════════════════════
-- 9. TAB CREATION HELPER
-- ═════════════════════════════════════════════════════════════
local tabs = {}
local currentTab = "fps"

local function CreateTabButton(name, icon, order)
    local btn = Instance.new("TextButton", TabContainer)
    btn.Name = name .. "Tab"
    btn.Size = UDim2.new(1, 0, 0, 45)
    btn.BackgroundColor3 = COLORS.secondary
    btn.TextColor3 = COLORS.text
    btn.Text = icon .. " " .. name
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order

    local Corner = Instance.new("UICorner", btn)
    Corner.CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        currentTab = name:lower()
        for tabName, page in pairs(tabs) do
            page.Visible = (tabName == name:lower())
        end
        for _, button in ipairs(TabContainer:GetChildren()) do
            if button:IsA("TextButton") then
                button.BackgroundColor3 = (button.Name == name .. "Tab") and COLORS.accent or COLORS.secondary
            end
        end
    end)

    return btn
end

local function CreateTabPage(name)
    local page = Instance.new("ScrollingFrame", ContentArea)
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 8
    page.Visible = (name == "fps")

    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local padding = Instance.new("UIPadding", page)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)

    tabs[name:lower()] = page
    return page
end

-- ═════════════════════════════════════════════════════════════
-- 10. UI ELEMENT HELPERS
-- ═════════════════════════════════════════════════════════════
local function CreateToggle(parent, text, default, callback)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 40)
    container.BackgroundColor3 = COLORS.secondary
    container.BorderSizePixel = 0

    local Corner = Instance.new("UICorner", container)
    Corner.CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = COLORS.text
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.new(0, 10, 0, 0)

    local toggle = Instance.new("TextButton", container)
    toggle.Size = UDim2.new(0, 50, 0, 24)
    toggle.Position = UDim2.new(1, -60, 0.5, -12)
    toggle.BackgroundColor3 = default and COLORS.success or COLORS.secondary
    toggle.TextColor3 = Color3.fromRGB(0, 0, 0)
    toggle.Text = default and "ON" or "OFF"
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 12
    toggle.BorderSizePixel = 0

    local ToggleCorner = Instance.new("UICorner", toggle)
    ToggleCorner.CornerRadius = UDim.new(0, 6)

    toggle.MouseButton1Click:Connect(function()
        default = not default
        toggle.BackgroundColor3 = default and COLORS.success or COLORS.secondary
        toggle.Text = default and "ON" or "OFF"
        if callback then callback(default) end
    end)

    return toggle, default
end

local function CreateSlider(parent, text, min, max, default, callback)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 60)
    container.BackgroundColor3 = COLORS.secondary
    container.BorderSizePixel = 0

    local Corner = Instance.new("UICorner", container)
    Corner.CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(math.floor(default * 100) / 100)
    label.TextColor3 = COLORS.text
    label.TextSize = 12
    label.Font = Enum.Font.Gotham

    local sliderBg = Instance.new("Frame", container)
    sliderBg.Size = UDim2.new(1, -20, 0, 6)
    sliderBg.Position = UDim2.new(0, 10, 0, 32)
    sliderBg.BackgroundColor3 = COLORS.bg
    sliderBg.BorderSizePixel = 0

    local sliderBgCorner = Instance.new("UICorner", sliderBg)
    sliderBgCorner.CornerRadius = UDim.new(0, 3)

    local sliderFill = Instance.new("Frame", sliderBg)
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = COLORS.accent
    sliderFill.BorderSizePixel = 0

    local sliderCorner = Instance.new("UICorner", sliderFill)
    sliderCorner.CornerRadius = UDim.new(0, 3)

    local value = default

    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local connection
            connection = UserInputService.InputChanged:Connect(function(input2)
                if input2.UserInputType == Enum.UserInputType.MouseMovement then
                    local size = sliderBg.AbsoluteSize.X
                    local pos = Mouse.X - sliderBg.AbsolutePosition.X
                    pos = clamp(pos, 0, size)
                    local ratio = pos / size
                    value = min + (max - min) * ratio
                    sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
                    label.Text = text .. ": " .. tostring(math.floor(value * 100) / 100)
                    if callback then callback(value) end
                end
            end)

            UserInputService.InputEnded:Connect(function(input3)
                if input3.UserInputType == Enum.UserInputType.MouseButton1 then
                    connection:Disconnect()
                end
            end)
        end
    end)

    return sliderFill, value
end

local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = COLORS.accent
    btn.TextColor3 = COLORS.bg
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0

    local Corner = Instance.new("UICorner", btn)
    Corner.CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        btn.BackgroundColor3 = COLORS.success
        if callback then callback() end
        task.wait(0.2)
        btn.BackgroundColor3 = COLORS.accent
    end)

    return btn
end

-- ═════════════════════════════════════════════════════════════
-- 11. BUILD UI TABS
-- ═════════════════════════════════════════════════════════════

-- Create tabs
CreateTabButton("FPS", "⚡", 1)
CreateTabButton("Player", "👤", 2)
CreateTabButton("Utility", "🛠️", 3)
CreateTabButton("Settings", "⚙️", 4)

local fpsBtnRef = TabContainer:FindFirstChild("fpstab")
fpsBtnRef.BackgroundColor3 = COLORS.accent

local fpsPage = CreateTabPage("fps")
local playerPage = CreateTabPage("player")
local utilityPage = CreateTabPage("utility")
local settingsPage = CreateTabPage("settings")

-- FPS TAB
do
    local order = 1
    
    local shadowToggle, shadowState = CreateToggle(fpsPage, "Disable Shadows", Settings.fps.shadowsEnabled, function(state)
        Settings.fps.shadowsEnabled = state
        SetShadows(state)
        SaveSettings()
    end)
    shadowToggle.LayoutOrder = order; order = order + 1

    local particlesToggle, particlesState = CreateToggle(fpsPage, "Enable Particles", Settings.fps.particlesEnabled, function(state)
        Settings.fps.particlesEnabled = state
        ToggleParticles(state)
        SaveSettings()
    end)
    particlesToggle.LayoutOrder = order; order = order + 1

    local decalsToggle, decalsState = CreateToggle(fpsPage, "Hide Decals", Settings.fps.decalsEnabled, function(state)
        Settings.fps.decalsEnabled = state
        ToggleDecals(state)
        SaveSettings()
    end)
    decalsToggle.LayoutOrder = order; order = order + 1

    local lightingSlider, lightingValue = CreateSlider(fpsPage, "Lighting Quality", 0, 1, Settings.fps.lightingQuality, function(value)
        Settings.fps.lightingQuality = value
        ReduceLighting(value)
        SaveSettings()
    end)
    lightingSlider.LayoutOrder = order; order = order + 1

    local restoreBtn = CreateButton(fpsPage, "Restore Graphics", function()
        RestoreLighting()
        notify("FPS Settings", "Graphics restored to defaults", 2)
    end)
    restoreBtn.LayoutOrder = order
end

-- PLAYER TAB
do
    local order = 1

    local wsLabel = Instance.new("TextLabel", playerPage)
    wsLabel.Size = UDim2.new(1, 0, 0, 25)
    wsLabel.BackgroundTransparency = 1
    wsLabel.Text = "Walk Speed: " .. Settings.player.walkSpeed
    wsLabel.TextColor3 = COLORS.text
    wsLabel.TextSize = 12
    wsLabel.Font = Enum.Font.Gotham
    wsLabel.LayoutOrder = order; order = order + 1

    local wsSlider, wsValue = CreateSlider(playerPage, "Speed", 10, 100, Settings.player.walkSpeed, function(value)
        Settings.player.walkSpeed = value
        SetPlayerStats()
        wsLabel.Text = "Walk Speed: " .. tostring(math.floor(value))
        SaveSettings()
    end)
    wsSlider.LayoutOrder = order; order = order + 1

    local jpLabel = Instance.new("TextLabel", playerPage)
    jpLabel.Size = UDim2.new(1, 0, 0, 25)
    jpLabel.BackgroundTransparency = 1
    jpLabel.Text = "Jump Power: " .. Settings.player.jumpPower
    jpLabel.TextColor3 = COLORS.text
    jpLabel.TextSize = 12
    jpLabel.Font = Enum.Font.Gotham
    jpLabel.LayoutOrder = order; order = order + 1

    local jpSlider, jpValue = CreateSlider(playerPage, "Jump", 10, 100, Settings.player.jumpPower, function(value)
        Settings.player.jumpPower = value
        SetPlayerStats()
        jpLabel.Text = "Jump Power: " .. tostring(math.floor(value))
        SaveSettings()
    end)
    jpSlider.LayoutOrder = order; order = order + 1

    local fovLabel = Instance.new("TextLabel", playerPage)
    fovLabel.Size = UDim2.new(1, 0, 0, 25)
    fovLabel.BackgroundTransparency = 1
    fovLabel.Text = "FOV: " .. Settings.player.fieldOfView
    fovLabel.TextColor3 = COLORS.text
    fovLabel.TextSize = 12
    fovLabel.Font = Enum.Font.Gotham
    fovLabel.LayoutOrder = order; order = order + 1

    local fovSlider, fovValue = CreateSlider(playerPage, "Field of View", 1, 120, Settings.player.fieldOfView, function(value)
        Settings.player.fieldOfView = value
        SetFieldOfView(value)
        fovLabel.Text = "FOV: " .. tostring(math.floor(value))
        SaveSettings()
    end)
    fovSlider.LayoutOrder = order
end

-- UTILITY TAB
do
    local order = 1

    local antiAFKToggle, antiAFKState = CreateToggle(utilityPage, "Anti-AFK", Settings.utility.antiAFK, function(state)
        Settings.utility.antiAFK = state
        if state then
            AntiAFK:Enable()
        else
            AntiAFK:Disable()
        end
        SaveSettings()
    end)
    antiAFKToggle.LayoutOrder = order; order = order + 1

    local autoRejoinToggle, autoRejoinState = CreateToggle(utilityPage, "Auto-Rejoin", Settings.utility.autoRejoin, function(state)
        Settings.utility.autoRejoin = state
        AutoRejoin.enabled = state
        SaveSettings()
    end)
    autoRejoinToggle.LayoutOrder = order; order = order + 1

    local rejoinBtn = CreateButton(utilityPage, "Rejoin Server Now", function()
        notify("Auto-Rejoin", "Rejoining server...", 2)
        task.wait(1)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
    rejoinBtn.LayoutOrder = order; order = order + 1

    local infoLabel = Instance.new("TextLabel", utilityPage)
    infoLabel.Size = UDim2.new(1, 0, 0, 60)
    infoLabel.BackgroundColor3 = COLORS.secondary
    infoLabel.TextColor3 = COLORS.text
    infoLabel.Text = "PlaceID: " .. game.PlaceId .. "\nPlayers: " .. #Players:GetPlayers()
    infoLabel.TextSize = 11
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.WordWrap = true
    infoLabel.LayoutOrder = order

    local Corner = Instance.new("UICorner", infoLabel)
    Corner.CornerRadius = UDim.new(0, 8)
end

-- SETTINGS TAB
do
    local order = 1

    local themeLabel = Instance.new("TextLabel", settingsPage)
    themeLabel.Size = UDim2.new(1, 0, 0, 25)
    themeLabel.BackgroundTransparency = 1
    themeLabel.Text = "Theme: " .. Settings.ui.theme
    themeLabel.TextColor3 = COLORS.text
    themeLabel.TextSize = 12
    themeLabel.Font = Enum.Font.Gotham
    themeLabel.LayoutOrder = order; order = order + 1

    local versionLabel = Instance.new("TextLabel", settingsPage)
    versionLabel.Size = UDim2.new(1, 0, 0, 50)
    versionLabel.BackgroundColor3 = COLORS.secondary
    versionLabel.TextColor3 = COLORS.text
    versionLabel.Text = "FPS BOOST PRO v2.0\nDevice: " .. deviceType:upper() .. "\nAuthor: Pro Developer"
    versionLabel.TextSize = 11
    versionLabel.Font = Enum.Font.Gotham
    versionLabel.WordWrap = true
    versionLabel.LayoutOrder = order; order = order + 1

    local Corner = Instance.new("UICorner", versionLabel)
    Corner.CornerRadius = UDim.new(0, 8)

    local saveBtn = CreateButton(settingsPage, "💾 Save & Apply All", function()
        SaveSettings()
        ApplyFPSSettings()
        notify("Settings", "Configuration saved!", 2)
    end)
    saveBtn.LayoutOrder = order; order = order + 1

    local resetBtn = CreateButton(settingsPage, "🔄 Reset to Defaults", function()
        Settings = deepCopy(DEFAULT_SETTINGS)
        SaveSettings()
        notify("Settings", "Reset to defaults", 2)
    end)
    resetBtn.LayoutOrder = order
end

-- ═════════════════════════════════════════════════════════════
-- 12. WINDOW CONTROLS
-- ═════════════════════════════════════════════════════════════

-- Minimize functionality
MinBtn.MouseButton1Click:Connect(function()
    tweenObject(MainPanel, {Size = UDim2.new(0, 50, 0, 50)}, 0.3)
    task.wait(0.3)
    MainPanel.Visible = false
    FloatingIcon.Visible = true
    Settings.ui.minimized = true
    SaveSettings()
end)

-- Restore from floating icon
FloatingIcon.MouseButton1Click:Connect(function()
    MainPanel.Visible = true
    tweenObject(MainPanel, {Size = UDim2.new(0, panelSize.w, 0, panelSize.h)}, 0.3)
    FloatingIcon.Visible = false
    Settings.ui.minimized = false
    SaveSettings()
end)

-- Close button
CloseBtn.MouseButton1Click:Connect(function()
    tweenObject(MainPanel, {Position = UDim2.new(0.5, -panelSize.w/2, 1.5, 0)}, 0.3)
    task.wait(0.3)
    ScreenGui:Destroy()
    log("Panel closed")
end)

-- Draggable window
local dragging = false
local dragStart = nil
local startPos = nil

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainPanel.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainPanel.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ═════════════════════════════════════════════════════════════
-- 13. INITIALIZATION
-- ═════════════════════════════════════════════════════════════

-- Apply settings on spawn
if LocalPlayer.Character then
    SetPlayerStats()
    ApplyFPSSettings()
end

-- Apply on character respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    SetPlayerStats()
    ApplyFPSSettings()
end)

-- Initialize Anti-AFK
if Settings.utility.antiAFK then
    AntiAFK:Enable()
end

-- Final notification
notify("FPS BOOST PRO", "Panel loaded successfully! ⚡", 3)
log("Script initialized - All systems online")
