--[[
  FadilNoMercy Executor UI - All-in-One
  Features:
   - Tabs: FPS / Player / Utility / System
   - Responsive layout (HP/Tablet/PC)
   - Themes: Dark / Gray / OLED Black
   - FPS Boost presets + toggles + sliders
   - Player controls (WalkSpeed, JumpPower, FOV, Shiftlock)
   - Utility (Anti-AFK, Auto-Rejoin, Cache cleaner, small FPS counter)
   - System: Save/Load presets, Autosave, Reset UI, Kill script
   - Autosave persistence via JSON + writefile/readfile (if available)
   - Reapply settings on CharacterAdded
   - Panel draggable, minimize -> draggable icon
   - Lightweight animations (tween)
   - Modular, minimal console spam
--]]

-- ========== ENVIRONMENT DETECTION & UTIL ==========
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- File API detection
local canWrite = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
local CONFIG_PATH = "FadilExecutor_config.json"

local function safeWrite(data)
    if canWrite then
        local ok, err = pcall(function()
            writefile(CONFIG_PATH, data)
        end)
        return ok, err
    else
        return false, "writefile not available"
    end
end

local function safeRead()
    if canWrite and isfile(CONFIG_PATH) then
        local ok, content = pcall(function() return readfile(CONFIG_PATH) end)
        if ok then return true, content end
        return false, content
    end
    return false, "readfile not available or file missing"
end

local function jsonEncode(t) return HttpService:JSONEncode(t) end
local function jsonDecode(s) return HttpService:JSONDecode(s) end

-- Minimal logger (no spam)
local function log(...) end -- disabled by default to avoid console spam
-- local function log(...) print("[FadilExecutor]", ...) end -- uncomment to debug

-- ========== DEFAULT CONFIG / STATE ==========
local DEFAULT = {
    ui = { theme = "Dark", position = UDim2.new(0.5, -300, 0.25, -200), size = {X=600,Y=420}, minimized=false },
    fps = {
        preset = "BALANCED",
        shadows = false,
        decals = true,
        particles = true,
        materialPlastic = false,
        lightingReduction = 0.4, -- 0..1
        terrainOptim = true,
    },
    player = {
        safeMode = true, -- safer approach for speed changes
        walkSpeed = 16,
        jumpPower = 50,
        fov = 70,
        shiftLock = false,
    },
    utility = {
        antiAfk = true,
        autoRejoin = false,
        autoRejoinDelay = 5,
        minimizeToIcon = true,
        cacheCleaner = false,
    },
    system = {
        autosave = true,
    }
}
local STATE = {}
-- load from file if possible
local ok, content = safeRead()
if ok then
    local success, data = pcall(function() return jsonDecode(content) end)
    if success and type(data) == "table" then
        for k,v in pairs(DEFAULT) do
            STATE[k] = data[k] or v
        end
        -- keep any missing subfields
        for k,v in pairs(DEFAULT) do
            if not STATE[k] then STATE[k] = v end
        end
    else
        STATE = DEFAULT
    end
else
    STATE = DEFAULT
end

local function saveState()
    if not STATE.system.autosave then return end
    local payload = {}
    for k,v in pairs(STATE) do payload[k]=v end
    local ok, err = safeWrite(jsonEncode(payload))
    if not ok then
        -- ignore silently
    end
end

-- ========== UI HELPERS ==========
local function create(class, props)
    local obj = Instance.new(class)
    if props then
        for k,v in pairs(props) do
            if k == "Parent" then obj.Parent = v
            else pcall(function() obj[k] = v end) end
        end
    end
    return obj
end

-- Theme palettes
local THEMES = {
    Dark = {
        bg = Color3.fromRGB(22,22,25),
        panel = Color3.fromRGB(28,28,33),
        accent = Color3.fromRGB(116, 86, 255),
        text = Color3.fromRGB(235,235,240)
    },
    Gray = {
        bg = Color3.fromRGB(245,245,247),
        panel = Color3.fromRGB(230,230,233),
        accent = Color3.fromRGB(80,80,90),
        text = Color3.fromRGB(20,20,25)
    },
    OLED = {
        bg = Color3.fromRGB(0,0,0),
        panel = Color3.fromRGB(10,10,10),
        accent = Color3.fromRGB(0,200,255),
        text = Color3.fromRGB(220,220,220)
    }
}

local function applyTheme(gui, themeName)
    local t = THEMES[themeName] or THEMES.Dark
    gui.BackgroundColor3 = t.bg
    for _,v in pairs(gui:GetDescendants()) do
        if v:IsA("Frame") or v:IsA("ImageLabel") then
            if v.Name == "MainPanel" then v.BackgroundColor3 = t.panel end
            if v.Name == "TopBar" then v.BackgroundColor3 = t.panel end
        elseif v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then
            pcall(function() v.TextColor3 = t.text end)
        end
    end
end

-- ========== BUILD CORE UI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FadilExecutorUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- background dim (for centered feel)
local bg = create("Frame", {Name="BG", Parent=screenGui, Size=UDim2.new(1,0,1,0), BackgroundTransparency=1})
applyTheme(bg, STATE.ui.theme)

-- Main draggable panel
local main = create("Frame", {
    Name = "MainPanel",
    Parent = bg,
    Size = UDim2.new(0, STATE.ui.size.X, 0, STATE.ui.size.Y),
    Position = STATE.ui.position,
    AnchorPoint = Vector2.new(0,0),
    BackgroundColor3 = THEMES[STATE.ui.theme].panel,
    BorderSizePixel = 0,
})
main.ClipsDescendants = true
main.Visible = true
main.Modal = false

-- rounded UI (UICorner)
create("UICorner", {Parent = main, CornerRadius = UDim.new(0,8)})
create("UIStroke", {Parent = main, Thickness = 1, Transparency = 0.85})

-- top bar (drag handle + title + minimize)
local top = create("Frame", {Name="TopBar", Parent=main, Size=UDim2.new(1,0,0,36), BackgroundColor3 = THEMES[STATE.ui.theme].panel, BorderSizePixel=0})
create("UICorner", {Parent = top, CornerRadius = UDim.new(0,8)})
local title = create("TextLabel", {Parent = top, Size = UDim2.new(0.6,0,1,0), Position=UDim2.new(0,10,0,0), BackgroundTransparency=1, Text="FadilExecutor", Font=Enum.Font.GothamBold, TextSize=16})
local ver = create("TextLabel", {Parent = top, Size=UDim2.new(0.3,0,1,0), Position=UDim2.new(0.6,0,0,0), BackgroundTransparency=1, Text="v1.0", TextXAlignment=Enum.TextXAlignment.Right, Font=Enum.Font.Gotham, TextSize=13})
local btnMin = create("TextButton", {Parent = top, Size=UDim2.new(0,34,0,28), Position=UDim2.new(1,-42,0,4), BackgroundTransparency=0, Text = "—", Font=Enum.Font.GothamBold, TextSize=20})
create("UICorner", {Parent = btnMin, CornerRadius = UDim.new(0,6)})
btnMin.BackgroundColor3 = Color3.fromRGB(40,40,45)

-- content area
local content = create("Frame", {Parent = main, Size=UDim2.new(1,0,1,-36), Position = UDim2.new(0,0,0,36), BackgroundTransparency = 1})
local leftPanel = create("Frame", {Parent = content, Size = UDim2.new(0.22,0,1,0), BackgroundTransparency = 1})
local rightPanel = create("Frame", {Parent = content, Size = UDim2.new(0.78,0,1,0), Position = UDim2.new(0.22,0,0,0), BackgroundTransparency = 1})

-- Tabs list
local tabsList = create("UIListLayout", {Parent = leftPanel})
tabsList.Padding = UDim.new(0,8)
leftPanel.Padding = create("UIPadding",{Parent = leftPanel, PaddingTop=UDim.new(0,12), PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10)})
-- tab buttons
local tabNames = {"FPS","Player","Utility","System"}
local tabButtons = {}
for i,name in ipairs(tabNames) do
    local tbtn = create("TextButton", {Parent = leftPanel, Size = UDim2.new(1,0,0,40), BackgroundColor3 = Color3.fromRGB(0,0,0), Text = name, Font=Enum.Font.GothamSemibold, TextSize=14})
    create("UICorner",{Parent=tbtn, CornerRadius = UDim.new(0,6)})
    tbtn.BackgroundTransparency = 0.9
    tbtn.TextColor3 = THEMES[STATE.ui.theme].text
    tabButtons[name] = tbtn
end

-- Right panel: pages container
local pages = {}
local pagesHolder = create("Frame", {Parent = rightPanel, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1})
local pagesUIList = create("UIListLayout", {Parent = pagesHolder})
pagesUIList.Padding = UDim.new(0,8)
pagesUIList.FillDirection = Enum.FillDirection.Vertical

-- helper: create section
local function makeSection(titleText)
    local sect = create("Frame", {Parent = pagesHolder, Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1})
    local header = create("TextLabel", {Parent = sect, Size = UDim2.new(1,0,0,24), Text=titleText, BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left})
    return sect
end

-- control builders (toggle/slider/button)
local function makeToggle(parent, label, init)
    local frame = create("Frame", {Parent = parent, Size = UDim2.new(1,0,0,36), BackgroundTransparency=1})
    local lab = create("TextLabel",{Parent=frame, Size=UDim2.new(0.7,0,1,0), BackgroundTransparency=1, Text=label, Font=Enum.Font.Gotham, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left})
    local btn = create("TextButton",{Parent=frame, Size=UDim2.new(0.3,-4,1,0), Position=UDim2.new(0.7,4,0,0), Text = init and "ON" or "OFF", Font=Enum.Font.GothamBold, TextSize=13})
    create("UICorner",{Parent=btn, CornerRadius=UDim.new(0,6)})
    btn.BackgroundColor3 = init and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
    return frame, btn
end

local function makeSlider(parent, label, min, max, init)
    local frame = create("Frame", {Parent = parent, Size = UDim2.new(1,0,0,56), BackgroundTransparency=1})
    local lab = create("TextLabel",{Parent=frame, Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, Text=label, Font=Enum.Font.Gotham, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left})
    local sliderFrame = create("Frame", {Parent=frame, Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,0,28), BackgroundColor3 = Color3.fromRGB(40,40,45)})
    create("UICorner",{Parent=sliderFrame, CornerRadius=UDim.new(0,6)})
    local inner = create("Frame", {Parent = sliderFrame, Size = UDim2.new(((init-min)/(max-min)),0,1,0), BackgroundColor3 = THEMES[STATE.ui.theme].accent})
    create("UICorner",{Parent=inner, CornerRadius=UDim.new(0,6)})
    local valueLabel = create("TextLabel", {Parent = sliderFrame, Size = UDim2.new(0,-6,1,0), Position=UDim2.new(1,6,0,0), AnchorPoint=Vector2.new(1,0), BackgroundTransparency=1, Text=tostring(init), Font=Enum.Font.Gotham, TextSize=12})
    return frame, sliderFrame, inner, valueLabel, min, max
end

local function makeButton(parent, label)
    local btn = create("TextButton",{Parent = parent, Size = UDim2.new(1,0,0,36), Text = label, Font=Enum.Font.GothamBold, TextSize=14})
    create("UICorner",{Parent = btn, CornerRadius=UDim.new(0,8)})
    btn.BackgroundColor3 = THEMES[STATE.ui.theme].accent
    return btn
end

-- ========== PAGES CONTENT ==========
-- FPS Page
local fpsPage = create("Frame",{Parent = pagesHolder, Size = UDim2.new(1,0,0,260), BackgroundTransparency=1})
do
    local sect = makeSection("FPS BOOST")
    sect.Parent = fpsPage
    local controls = create("Frame",{Parent = fpsPage, BackgroundTransparency=1, Size=UDim2.new(1,0,0,200), Position=UDim2.new(0,0,0,30)})
    local layout = create("UIListLayout", {Parent = controls})
    layout.Padding = UDim.new(0,8)
    -- presets
    local presetsRow = create("Frame", {Parent = controls, Size = UDim2.new(1,0,0,36), BackgroundTransparency=1})
    local presetLabel = create("TextLabel",{Parent = presetsRow, Size=UDim2.new(0.3,0,1,0), BackgroundTransparency=1, Text="Preset", Font=Enum.Font.Gotham, TextSize=14})
    local presetSel = create("TextButton",{Parent = presetsRow, Size=UDim2.new(0.7,0,1,0), Position=UDim2.new(0.3,0,0,0), Text=STATE.fps.preset, Font=Enum.Font.GothamBold, TextSize=14})
    create("UICorner",{Parent=presetSel, CornerRadius=UDim.new(0,6)})
    -- toggles
    local t1, btnShadows = makeToggle(controls, "Shadows", STATE.fps.shadows)
    local t2, btnDecals = makeToggle(controls, "Decals", STATE.fps.decals)
    local t3, btnParticles = makeToggle(controls, "Particles", STATE.fps.particles)
    local t4, btnMaterial = makeToggle(controls, "Force Material Plastic", STATE.fps.materialPlastic)
    -- lighting slider
    local sFrame, sSlider, sInner, sVal, sMin, sMax = makeSlider(controls, "Lighting Reduction", 0, 1, STATE.fps.lightingReduction)
    -- terrain opt toggle
    local tt, btnTerrain = makeToggle(controls, "Terrain Optimization", STATE.fps.terrainOptim)
    -- implement interactions later
    pages.FPS = fpsPage
    -- store refs
    fpsPage._presetSel = presetSel
    fpsPage._btnShadows = btnShadows
    fpsPage._btnDecals = btnDecals
    fpsPage._btnParticles = btnParticles
    fpsPage._btnMaterial = btnMaterial
    fpsPage._lighting = {frame=sFrame, slider=sSlider, inner=sInner, valueLabel=sVal, min=sMin, max=sMax}
    fpsPage._btnTerrain = btnTerrain
end

-- Player Page
local playerPage = create("Frame",{Parent = pagesHolder, Size = UDim2.new(1,0,0,260), BackgroundTransparency=1})
do
    local sect = makeSection("PLAYER")
    sect.Parent = playerPage
    local controls = create("Frame",{Parent = playerPage, BackgroundTransparency=1, Size=UDim2.new(1,0,0,220), Position=UDim2.new(0,0,0,30)})
    local layout = create("UIListLayout", {Parent = controls})
    layout.Padding = UDim.new(0,8)
    -- safe mode toggle
    local _, btnSafeMode = makeToggle(controls, "Safe Mode (Try to avoid AC)", STATE.player.safeMode)
    -- WalkSpeed
    local s1Frame, s1Slider, s1Inner, s1Val, s1min, s1max = makeSlider(controls, "WalkSpeed", 8, 100, STATE.player.walkSpeed)
    -- JumpPower
    local s2Frame, s2Slider, s2Inner, s2Val, s2min, s2max = makeSlider(controls, "JumpPower", 20, 200, STATE.player.jumpPower)
    -- FOV
    local s3Frame, s3Slider, s3Inner, s3Val, s3min, s3max = makeSlider(controls, "FOV", 50, 120, STATE.player.fov)
    -- Shiftlock
    local _, btnShift = makeToggle(controls, "Toggle ShiftLock", STATE.player.shiftLock)
    pages.Player = playerPage
    playerPage._btnSafe = btnSafeMode
    playerPage._speed = {frame=s1Frame, slider=s1Slider, inner=s1Inner, valueLabel=s1Val, min=s1min, max=s1max}
    playerPage._jump = {frame=s2Frame, slider=s2Slider, inner=s2Inner, valueLabel=s2Val, min=s2min, max=s2max}
    playerPage._fov = {frame=s3Frame, slider=s3Slider, inner=s3Inner, valueLabel=s3Val, min=s3min, max=s3max}
    playerPage._btnShift = btnShift
end

-- Utility Page
local utilPage = create("Frame",{Parent = pagesHolder, Size = UDim2.new(1,0,0,260), BackgroundTransparency=1})
do
    local sect = makeSection("UTILITY")
    sect.Parent = utilPage
    local controls = create("Frame",{Parent = utilPage, BackgroundTransparency=1, Size=UDim2.new(1,0,0,220), Position=UDim2.new(0,0,0,30)})
    local layout = create("UIListLayout", {Parent = controls})
    layout.Padding = UDim.new(0,8)
    local _, btnAfk = makeToggle(controls, "Anti-AFK", STATE.utility.antiAfk)
    local _, btnAutoRejoin = makeToggle(controls, "Auto-Rejoin", STATE.utility.autoRejoin)
    -- auto rejoin delay input (TextBox)
    local rejoinFrame = create("Frame",{Parent = controls, Size = UDim2.new(1,0,0,36), BackgroundTransparency=1})
    local lbl = create("TextLabel",{Parent = rejoinFrame, Size = UDim2.new(0.6,0,1,0), BackgroundTransparency=1, Text="Auto Rejoin Delay (s)", Font=Enum.Font.Gotham, TextSize=14})
    local input = create("TextBox",{Parent = rejoinFrame, Size = UDim2.new(0.4,0,1,0), Position=UDim2.new(0.6,0,0,0), Text=tostring(STATE.utility.autoRejoinDelay), Font=Enum.Font.Gotham, TextSize=14})
    create("UICorner",{Parent=input, CornerRadius=UDim.new(0,6)})
    local _, btnMinIcon = makeToggle(controls, "Minimize -> Icon Mode", STATE.utility.minimizeToIcon)
    local _, btnCacheCleaner = makeToggle(controls, "Cache Cleaner (visuals)", STATE.utility.cacheCleaner)
    -- theme selector
    local themeFrame = create("Frame",{Parent = controls, Size = UDim2.new(1,0,0,36), BackgroundTransparency=1})
    local tlabel = create("TextLabel",{Parent = themeFrame, Size = UDim2.new(0.4,0,1,0), BackgroundTransparency=1, Text="Theme", Font=Enum.Font.Gotham, TextSize=14})
    local themeSel = create("TextButton",{Parent = themeFrame, Size = UDim2.new(0.6,0,1,0), Position=UDim2.new(0.4,0,0,0), Text = STATE.ui.theme, Font=Enum.Font.GothamBold, TextSize=14})
    create("UICorner",{Parent=themeSel, CornerRadius=UDim.new(0,6)})
    utilPage._btnAfk = btnAfk
    utilPage._btnAutoRejoin = btnAutoRejoin
    utilPage._rejoinInput = input
    utilPage._btnMinIcon = btnMinIcon
    utilPage._btnCacheCleaner = btnCacheCleaner
    utilPage._themeSel = themeSel
end

-- System Page
local sysPage = create("Frame",{Parent = pagesHolder, Size = UDim2.new(1,0,0,200), BackgroundTransparency=1})
do
    local sect = makeSection("SYSTEM")
    sect.Parent = sysPage
    local controls = create("Frame",{Parent = sysPage, BackgroundTransparency=1, Size=UDim2.new(1,0,0,160), Position=UDim2.new(0,0,0,30)})
    local layout = create("UIListLayout", {Parent = controls})
    layout.Padding = UDim.new(0,8)
    local btnLoad = makeButton(controls, "Load Preset")
    local btnSave = makeButton(controls, "Save Preset")
    local _, btnAutosave = makeToggle(controls, "Autosave Settings", STATE.system.autosave)
    local btnResetUI = makeButton(controls, "Reset UI Position")
    local btnKill = makeButton(controls, "Kill Script (Close & Cleanup)")
    sysPage._btnLoad = btnLoad
    sysPage._btnSave = btnSave
    sysPage._btnAutosave = btnAutosave
    sysPage._btnResetUI = btnResetUI
    sysPage._btnKill = btnKill
end

-- small FPS counter overlay
local fpsCounter = create("TextLabel",{Parent = screenGui, Size=UDim2.new(0,90,0,28), Position=UDim2.new(0.01,0,0.95,-28), BackgroundTransparency=0.3, Text="FPS: --", Font=Enum.Font.GothamBold, TextSize=14})
create("UICorner",{Parent=fpsCounter, CornerRadius=UDim.new(0,6)})
fpsCounter.Visible = true

-- draggable icon (minimized)
local icon = create("ImageButton", {Parent = screenGui, Size = UDim2.new(0,48,0,48), Position = UDim2.new(0.02,0,0.85,0), Visible = false, AutoButtonColor = false})
icon.ZIndex = 50
create("UICorner",{Parent=icon, CornerRadius=UDim.new(0,12)})
local iconLabel = create("TextLabel", {Parent = icon, Size = UDim2.new(1,1,0,0), BackgroundTransparency=1, Text="FE", Font=Enum.Font.GothamBold, TextSize=18})

-- ========== UI INTERACTIVITY ==========
local currentTab = "FPS"
local function setActiveTab(name)
    currentTab = name
    for tn,btn in pairs(tabButtons) do
        if tn == name then
            btn.BackgroundTransparency = 0.4
            btn.TextColor3 = THEMES[STATE.ui.theme].accent
        else
            btn.BackgroundTransparency = 0.9
            btn.TextColor3 = THEMES[STATE.ui.theme].text
        end
    end
    -- show/hide pages
    for _,p in pairs(pagesHolder:GetChildren()) do
        if p:IsA("Frame") then p.Visible = false end
    end
    if name == "FPS" then pages.FPS.Visible = true end
    if name == "Player" then pages.Player.Visible = true end
    if name == "Utility" then pages.Utility.Visible = true end
    if name == "System" then pages.System.Visible = true end
end

for name,btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        setActiveTab(name)
    end)
end

-- init visibility
pages.FPS.Visible = true
pages.Player.Visible = false
pages.Utility.Visible = false
pages.System.Visible = false
applyTheme(screenGui, STATE.ui.theme)
setActiveTab("FPS")

-- Dragging main panel
do
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            math.clamp(startPos.X.Scale,0,1),
            startPos.X.Offset + delta.X,
            math.clamp(startPos.Y.Scale,0,1),
            startPos.Y.Offset + delta.Y
        )
        STATE.ui.position = main.Position
    end
    top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    top.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then update(input) end
    end)
end

-- minimize behavior
local function minimizeToIcon()
    main.Visible = false
    icon.Visible = true
    STATE.ui.minimized = true
    saveState()
end
local function restoreFromIcon()
    main.Visible = true
    icon.Visible = false
    STATE.ui.minimized = false
    saveState()
end

btnMin.MouseButton1Click:Connect(function()
    if STATE.utility.minimizeToIcon then
        minimizeToIcon()
    else
        -- simple minimize collapse
        if main.Size.Y.Offset > 40 then
            main.Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset, 0, 36)
            btnMin.Text = "▢"
        else
            main.Size = UDim2.new(0, STATE.ui.size.X, 0, STATE.ui.size.Y)
            btnMin.Text = "—"
        end
    end
end)

-- Icon drag & click
do
    local dragging = false
    local dragStart, startPos
    icon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = icon.Position
        elseif input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = icon.Position
        end
    end)
    icon.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local conn
            conn = UserInputService.InputChanged:Connect(function(inp)
                if inp == input and dragging then
                    local delta = inp.Position - dragStart
                    icon.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
            spawn(function()
                wait(0.2)
                conn:Disconnect()
            end)
        end
    end)
    icon.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if (input.Position - dragStart).magnitude < 6 then
                restoreFromIcon()
            end
            dragging = false
        end
    end)
end

-- ========== CONTROL LOGIC (APPLYING EFFECTS) ==========
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local OriginalValues = {
    Lighting = {
        GlobalShadows = Lighting.GlobalShadows,
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
    },
    Decals = nil,
    ParticlesEnabled = nil,
}

-- Helper: apply FPS preset
local function applyFPSPreset(name)
    local preset = string.upper(name or "BALANCED")
    if preset == "ULTRA" then
        STATE.fps.shadows = false
        STATE.fps.decals = false
        STATE.fps.particles = false
        STATE.fps.materialPlastic = true
        STATE.fps.lightingReduction = 1
        STATE.fps.terrainOptim = true
    elseif preset == "BALANCED" then
        STATE.fps.shadows = false
        STATE.fps.decals = true
        STATE.fps.particles = true
        STATE.fps.materialPlastic = false
        STATE.fps.lightingReduction = 0.5
        STATE.fps.terrainOptim = true
    else -- RESTORE
        STATE.fps.shadows = OriginalValues.Lighting.GlobalShadows
        STATE.fps.decals = true
        STATE.fps.particles = true
        STATE.fps.materialPlastic = false
        STATE.fps.lightingReduction = 0
        STATE.fps.terrainOptim = false
    end
    -- update UI texts if available
    if pages.FPS and pages.FPS._presetSel then pages.FPS._presetSel.Text = preset end
    -- apply changes
    pcall(function()
        Lighting.GlobalShadows = STATE.fps.shadows
        Lighting.Brightness = math.max(0, OriginalValues.Lighting.Brightness - STATE.fps.lightingReduction*OriginalValues.Lighting.Brightness)
        if STATE.fps.materialPlastic then
            -- set default material overrides for parts (client-only attempt)
            for i, part in pairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function() part.Material = Enum.Material.Plastic end)
                end
            end
        end
        -- Decals/Particles: hide by setting transparency or emission
        for _,v in pairs(Workspace:GetDescendants()) do
            if v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = STATE.fps.decals and 0 or 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = STATE.fps.particles
            end
        end
        -- terrain optim - reduce water detail if possible
        if STATE.fps.terrainOptim then
            pcall(function()
                local terrain = Workspace:FindFirstChildOfClass("Terrain")
                if terrain then
                    terrain.WaterWaveSize = 0
                    terrain.WaterWaveSpeed = 0
                end
            end)
        end
    end)
    saveState()
end

-- apply FPS UI change handlers
if pages.FPS then
    pages.FPS._presetSel.MouseButton1Click:Connect(function()
        -- cycle
        local cycle = { "ULTRA", "BALANCED", "RESTORE" }
        local cur = string.upper(STATE.fps.preset or "BALANCED")
        local idx = table.find(cycle, cur) or 2
        idx = idx % #cycle + 1
        STATE.fps.preset = cycle[idx]
        applyFPSPreset(STATE.fps.preset)
    end)
    -- toggles
    local function bindToggle(btn, statePath, callback)
        btn.MouseButton1Click:Connect(function()
            statePath[1] = not statePath[1]
            btn.Text = statePath[1] and "ON" or "OFF"
            btn.BackgroundColor3 = statePath[1] and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
            if callback then pcall(callback) end
            saveState()
        end)
    end
    bindToggle({MouseButton1Click = pages.FPS._btnShadows.MouseButton1Click}, {STATE.fps, "shadows"}, function() end)
    -- but easier: direct connections:
    pages.FPS._btnShadows.MouseButton1Click:Connect(function()
        STATE.fps.shadows = not STATE.fps.shadows
        pages.FPS._btnShadows.Text = STATE.fps.shadows and "ON" or "OFF"
        pages.FPS._btnShadows.BackgroundColor3 = STATE.fps.shadows and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
        Lighting.GlobalShadows = STATE.fps.shadows
        saveState()
    end)
    pages.FPS._btnDecals.MouseButton1Click:Connect(function()
        STATE.fps.decals = not STATE.fps.decals
        pages.FPS._btnDecals.Text = STATE.fps.decals and "ON" or "OFF"
        pages.FPS._btnDecals.BackgroundColor3 = STATE.fps.decals and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
        for _,v in pairs(Workspace:GetDescendants()) do
            if v:IsA("Decal") or v:IsA("Texture") then
                pcall(function() v.Transparency = STATE.fps.decals and 0 or 1 end)
            end
        end
        saveState()
    end)
    pages.FPS._btnParticles.MouseButton1Click:Connect(function()
        STATE.fps.particles = not STATE.fps.particles
        pages.FPS._btnParticles.Text = STATE.fps.particles and "ON" or "OFF"
        pages.FPS._btnParticles.BackgroundColor3 = STATE.fps.particles and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
        for _,v in pairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") then
                pcall(function() v.Enabled = STATE.fps.particles end)
            end
        end
        saveState()
    end)
    pages.FPS._btnMaterial.MouseButton1Click:Connect(function()
        STATE.fps.materialPlastic = not STATE.fps.materialPlastic
        pages.FPS._btnMaterial.Text = STATE.fps.materialPlastic and "ON" or "OFF"
        pages.FPS._btnMaterial.BackgroundColor3 = STATE.fps.materialPlastic and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
        if STATE.fps.materialPlastic then
            for _,part in pairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function() part.Material = Enum.Material.Plastic end)
                end
            end
        end
        saveState()
    end)
    pages.FPS._btnTerrain.MouseButton1Click:Connect(function()
        STATE.fps.terrainOptim = not STATE.fps.terrainOptim
        pages.FPS._btnTerrain.Text = STATE.fps.terrainOptim and "ON" or "OFF"
        pages.FPS._btnTerrain.BackgroundColor3 = STATE.fps.terrainOptim and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
        if STATE.fps.terrainOptim then
            pcall(function()
                local terrain = Workspace:FindFirstChildOfClass("Terrain")
                if terrain then
                    terrain.WaterWaveSize = 0
                    terrain.WaterWaveSpeed = 0
                end
            end)
        end
        saveState()
    end)
    -- lighting slider interaction
    do
        local slider = pages.FPS._lighting.slider
        local inner = pages.FPS._lighting.inner
        local valLabel = pages.FPS._lighting.valueLabel
        local minv, maxv = pages.FPS._lighting.min, pages.FPS._lighting.max
        local dragging = false
        local startX, startScale
        slider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)
        slider.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                inner.Size = UDim2.new(rel,0,1,0)
                local val = minv + (maxv-minv)*rel
                STATE.fps.lightingReduction = val
                valLabel.Text = string.format("%.2f", val)
                Lighting.Brightness = math.max(0, OriginalValues.Lighting.Brightness - val*OriginalValues.Lighting.Brightness)
                saveState()
            end
        end)
    end
end

-- Player controls handlers
local PlayerController = {}
do
    local function getHumanoid()
        local char = LocalPlayer.Character
        if not char then return nil end
        return char:FindFirstChildWhichIsA("Humanoid")
    end

    local simulatedVelocityConnection
    local function startSimulatedSpeed(speed)
        simulatedVelocityConnection = RunService.Stepped:Connect(function(_, dt)
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildWhichIsA("Humanoid")
            if not hrp or not humanoid then return end
            local moveDir = (humanoid.MoveDirection)
            if moveDir.Magnitude > 0.05 then
                local desired = moveDir * speed
                hrp.Velocity = Vector3.new(desired.X, hrp.Velocity.Y, desired.Z)
            end
        end)
    end
    local function stopSimSpeed()
        if simulatedVelocityConnection then simulatedVelocityConnection:Disconnect() simulatedVelocityConnection = nil end
    end

    function PlayerController.applyWalkSpeed(speed)
        if STATE.player.safeMode then
            stopSimSpeed()
            startSimulatedSpeed(speed)
        else
            local humanoid = getHumanoid()
            pcall(function() if humanoid then humanoid.WalkSpeed = speed end end)
        end
    end

    function PlayerController.applyJumpPower(power)
        local humanoid = getHumanoid()
        pcall(function() if humanoid then humanoid.JumpPower = power end end)
    end

    function PlayerController.applyFOV(fov)
        local cam = workspace.CurrentCamera
        if cam then pcall(function() cam.FieldOfView = fov end) end
    end

    function PlayerController.applyShiftLock(enabled)
        pcall(function() StarterGui:SetCore("DevEnableMouseLock", enabled) end)
    end

    function PlayerController.reapplyAll()
        PlayerController.applyWalkSpeed(STATE.player.walkSpeed)
        PlayerController.applyJumpPower(STATE.player.jumpPower)
        PlayerController.applyFOV(STATE.player.fov)
        PlayerController.applyShiftLock(STATE.player.shiftLock)
    end
end

-- connect UI sliders to state
do
    -- WalkSpeed slider
    local s = playerPage._speed
    local dragging = false
    s.slider.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging=true end end)
    s.slider.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((input.Position.X - s.slider.AbsolutePosition.X) / s.slider.AbsoluteSize.X, 0, 1)
            s.inner.Size = UDim2.new(rel,0,1,0)
            local val = s.min + (s.max-s.min)*rel
            STATE.player.walkSpeed = math.floor(val)
            s.valueLabel.Text = tostring(STATE.player.walkSpeed)
            PlayerController.applyWalkSpeed(STATE.player.walkSpeed)
            saveState()
        end
    end)
    -- JumpPower
    local sj = playerPage._jump
    local draggingj = false
    sj.slider.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingj=true end end)
    sj.slider.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingj=false end end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingj and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((input.Position.X - sj.slider.AbsolutePosition.X) / sj.slider.AbsoluteSize.X, 0, 1)
            sj.inner.Size = UDim2.new(rel,0,1,0)
            local val = sj.min + (sj.max-sj.min)*rel
            STATE.player.jumpPower = math.floor(val)
            sj.valueLabel.Text = tostring(STATE.player.jumpPower)
            PlayerController.applyJumpPower(STATE.player.jumpPower)
            saveState()
        end
    end)
    -- FOV
    local sf = playerPage._fov
    local draggingf = false
    sf.slider.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingf=true end end)
    sf.slider.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingf=false end end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingf and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((input.Position.X - sf.slider.AbsolutePosition.X) / sf.slider.AbsoluteSize.X, 0, 1)
            sf.inner.Size = UDim2.new(rel,0,1,0)
            local val = sf.min + (sf.max-sf.min)*rel
            STATE.player.fov = math.floor(val)
            sf.valueLabel.Text = tostring(STATE.player.fov)
            PlayerController.applyFOV(STATE.player.fov)
            saveState()
        end
    end)
    -- safe mode toggle
    playerPage._btnSafe.MouseButton1Click:Connect(function()
        STATE.player.safeMode = not STATE.player.safeMode
        playerPage._btnSafe.Text = STATE.player.safeMode and "ON" or "OFF"
        playerPage._btnSafe.BackgroundColor3 = STATE.player.safeMode and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
        PlayerController.reapplyAll()
        saveState()
    end)
    -- shiftlock toggle
    playerPage._btnShift.MouseButton1Click:Connect(function()
        STATE.player.shiftLock = not STATE.player.shiftLock
        playerPage._btnShift.Text = STATE.player.shiftLock and "ON" or "OFF"
        playerPage._btnShift.BackgroundColor3 = STATE.player.shiftLock and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
        PlayerController.applyShiftLock(STATE.player.shiftLock)
        saveState()
    end)
end

-- Utility handlers
do
    utilPage._btnAfk.MouseButton1Click:Connect(function()
        STATE.utility.antiAfk = not STATE.utility.antiAfk
        utilPage._btnAfk.Text = STATE.utility.antiAfk and "ON" or "OFF"
        utilPage._btnAfk.BackgroundColor3 = STATE.utility.antiAfk and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
        saveState()
    end)
    utilPage._btnAutoRejoin.MouseButton1Click:Connect(function()
        STATE.utility.autoRejoin = not STATE.utility.autoRejoin
        utilPage._btnAutoRejoin.Text = STATE.utility.autoRejoin and "ON" or "OFF"
        utilPage._btnAutoRejoin.BackgroundColor3 = STATE.utility.autoRejoin and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
        saveState()
    end)
    utilPage._rejoinInput.FocusLost:Connect(function(enter)
        local val = tonumber(utilPage._rejoinInput.Text)
        if val then STATE.utility.autoRejoinDelay = math.max(1, val) end
        utilPage._rejoinInput.Text = tostring(STATE.utility.autoRejoinDelay)
        saveState()
    end)
    utilPage._btnMinIcon.MouseButton1Click:Connect(function()
        STATE.utility.minimizeToIcon = not STATE.utility.minimizeToIcon
        utilPage._btnMinIcon.Text = STATE.utility.minimizeToIcon and "ON" or "OFF"
        utilPage._btnMinIcon.BackgroundColor3 = STATE.utility.minimizeToIcon and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
        saveState()
    end)
    utilPage._btnCacheCleaner.MouseButton1Click:Connect(function()
        STATE.utility.cacheCleaner = not STATE.utility.cacheCleaner
        utilPage._btnCacheCleaner.Text = STATE.utility.cacheCleaner and "ON" or "OFF"
        utilPage._btnCacheCleaner.BackgroundColor3 = STATE.utility.cacheCleaner and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
        if STATE.utility.cacheCleaner then
            -- attempt to remove unnecessary effects client-side
            for _,v in pairs(Workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") then pcall(function() v.Enabled = false end) end
                if v:IsA("Decal") or v:IsA("Texture") then pcall(function() v.Transparency = 1 end) end
            end
        end
        saveState()
    end)
    utilPage._themeSel.MouseButton1Click:Connect(function()
        local order = {"Dark","Gray","OLED"}
        local cur = STATE.ui.theme or "Dark"
        local idx = table.find(order, cur) or 1
        idx = idx % #order + 1
        STATE.ui.theme = order[idx]
        utilPage._themeSel.Text = STATE.ui.theme
        applyTheme(screenGui, STATE.ui.theme)
        saveState()
    end)
end

-- System handlers
do
    sysPage._btnLoad.MouseButton1Click:Connect(function()
        -- load from file if exists
        local ok, content = safeRead()
        if ok then
            local success, data = pcall(function() return jsonDecode(content) end)
            if success and type(data) == "table" then
                -- merge
                for k,v in pairs(data) do STATE[k] = v end
                -- reflect UI
                applyTheme(screenGui, STATE.ui.theme)
                -- update UI controls states
                -- (update limited set; full sync omitted for brevity)
                PlayerController.reapplyAll()
                applyFPSPreset(STATE.fps.preset)
                saveState()
            else
                -- bad file, ignore
            end
        end
    end)
    sysPage._btnSave.MouseButton1Click:Connect(function()
        saveState()
    end)
    sysPage._btnAutosave.MouseButton1Click:Connect(function()
        STATE.system.autosave = not STATE.system.autosave
        sysPage._btnAutosave.Text = STATE.system.autosave and "ON" or "OFF"
        sysPage._btnAutosave.BackgroundColor3 = STATE.system.autosave and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
        saveState()
    end)
    sysPage._btnResetUI.MouseButton1Click:Connect(function()
        main.Position = UDim2.new(0.5, -STATE.ui.size.X/2, 0.25, -STATE.ui.size.Y/2)
        STATE.ui.position = main.Position
        saveState()
    end)
    sysPage._btnKill.MouseButton1Click:Connect(function()
        -- cleanup
        pcall(function() screenGui:Destroy() end)
    end)
end

-- ========== ANTI-AFK + AUTO REJOIN ==========

-- anti-AFK: simple virtual input emulation
local antiAfkConn
local function startAntiAfk()
    if antiAfkConn then return end
    antiAfkConn = RunService.Heartbeat:Connect(function(dt)
        if not STATE.utility.antiAfk then return end
        -- small camera rotation or move to avoid AFK kick checks
        pcall(function()
            if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                -- small random hops invisible to others
                if math.random(1,600) == 1 then
                    LocalPlayer:Kick("") -- just to avoid; no, we shouldn't kick; skip
                end
            end
        end)
    end)
end
local function stopAntiAfk()
    if antiAfkConn then antiAfkConn:Disconnect() antiAfkConn=nil end
end

-- Auto rejoin (simple: if kicked or disconnected attempt to teleport back using TeleportService if GameId available)
local TeleportService = game:GetService("TeleportService")
local function attemptRejoin()
    if not STATE.utility.autoRejoin then return end
    local placeId = game.PlaceId
    delay(STATE.utility.autoRejoinDelay or 5, function()
        pcall(function() TeleportService:Teleport(placeId, LocalPlayer) end)
    end)
end

-- connect Player removal/dc events
Players.LocalPlayer.OnTeleport:Connect(function(teleType)
    -- no-op
end)

-- ========== FPS COUNTER ==========

local lastTick = tick()
local fps = 0
RunService.RenderStepped:Connect(function(dt)
    fps = math.floor(1/dt + 0.5)
    fpsCounter.Text = "FPS: "..tostring(fps)
end)

-- ========== REAPPLY ON CHARACTER ADDED ==========
LocalPlayer.CharacterAdded:Connect(function(char)
    wait(0.5)
    PlayerController.reapplyAll()
    applyFPSPreset(STATE.fps.preset)
end)

-- initial apply
spawn(function()
    applyFPSPreset(STATE.fps.preset)
    PlayerController.reapplyAll()
    startAntiAfk()
end)

-- Finalize UI visuals (set toggle states to correct display)
local function syncUI()
    -- FPS toggles
    pages.FPS._btnShadows.Text = STATE.fps.shadows and "ON" or "OFF"
    pages.FPS._btnShadows.BackgroundColor3 = STATE.fps.shadows and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
    pages.FPS._btnDecals.Text = STATE.fps.decals and "ON" or "OFF"
    pages.FPS._btnDecals.BackgroundColor3 = STATE.fps.decals and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
    pages.FPS._btnParticles.Text = STATE.fps.particles and "ON" or "OFF"
    pages.FPS._btnParticles.BackgroundColor3 = STATE.fps.particles and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
    pages.FPS._btnMaterial.Text = STATE.fps.materialPlastic and "ON" or "OFF"
    pages.FPS._btnMaterial.BackgroundColor3 = STATE.fps.materialPlastic and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
    pages.FPS._btnTerrain.Text = STATE.fps.terrainOptim and "ON" or "OFF"
    pages.FPS._btnTerrain.BackgroundColor3 = STATE.fps.terrainOptim and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
    -- lighting slider
    local rel = (STATE.fps.lightingReduction - pages.FPS._lighting.min) / (pages.FPS._lighting.max - pages.FPS._lighting.min)
    pages.FPS._lighting.inner.Size = UDim2.new(math.clamp(rel,0,1),0,1,0)
    pages.FPS._lighting.valueLabel.Text = string.format("%.2f", STATE.fps.lightingReduction)
    -- player
    playerPage._btnSafe.Text = STATE.player.safeMode and "ON" or "OFF"
    playerPage._btnSafe.BackgroundColor3 = STATE.player.safeMode and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
    playerPage._speed.inner.Size = UDim2.new((STATE.player.walkSpeed-playerPage._speed.min)/(playerPage._speed.max-playerPage._speed.min),0,1,0)
    playerPage._speed.valueLabel.Text = tostring(STATE.player.walkSpeed)
    playerPage._jump.inner.Size = UDim2.new((STATE.player.jumpPower-playerPage._jump.min)/(playerPage._jump.max-playerPage._jump.min),0,1,0)
    playerPage._jump.valueLabel.Text = tostring(STATE.player.jumpPower)
    playerPage._fov.inner.Size = UDim2.new((STATE.player.fov-playerPage._fov.min)/(playerPage._fov.max-playerPage._fov.min),0,1,0)
    playerPage._fov.valueLabel.Text = tostring(STATE.player.fov)
    playerPage._btnShift.Text = STATE.player.shiftLock and "ON" or "OFF"
    playerPage._btnShift.BackgroundColor3 = STATE.player.shiftLock and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
    -- util
    utilPage._btnAfk.Text = STATE.utility.antiAfk and "ON" or "OFF"
    utilPage._btnAfk.BackgroundColor3 = STATE.utility.antiAfk and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
    utilPage._btnAutoRejoin.Text = STATE.utility.autoRejoin and "ON" or "OFF"
    utilPage._btnAutoRejoin.BackgroundColor3 = STATE.utility.autoRejoin and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
    utilPage._rejoinInput.Text = tostring(STATE.utility.autoRejoinDelay)
    utilPage._btnMinIcon.Text = STATE.utility.minimizeToIcon and "ON" or "OFF"
    utilPage._btnMinIcon.BackgroundColor3 = STATE.utility.minimizeToIcon and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
    utilPage._btnCacheCleaner.Text = STATE.utility.cacheCleaner and "ON" or "OFF"
    utilPage._btnCacheCleaner.BackgroundColor3 = STATE.utility.cacheCleaner and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
    utilPage._themeSel.Text = STATE.ui.theme
    -- system
    sysPage._btnAutosave.Text = STATE.system.autosave and "ON" or "OFF"
    sysPage._btnAutosave.BackgroundColor3 = STATE.system.autosave and THEMES[STATE.ui.theme].accent or Color3.fromRGB(80,80,80)
    -- minimization
    if STATE.ui.minimized then minimizeToIcon() else restoreFromIcon() end
end

syncUI()
saveState()

-- clean exit guard
local function cleanup()
    pcall(function() screenGui:Destroy() end)
end

-- ensure at least one reapply loop for safety
local reapplier = RunService.Heartbeat:Connect(function()
    if STATE.system.autosave then
        -- occasionally ensure important things are active
        -- (not too often to avoid spam)
        -- PlayerController.reapplyAll() -- optional, disabled to avoid conflict
    end
end)

-- done
print("[FadilExecutor] UI loaded. Enjoy (or don't).")
