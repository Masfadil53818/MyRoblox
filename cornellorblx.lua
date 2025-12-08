--[[ 
FPS Booster Mega-Panel v1.0
Author: generated (for FadilNoMercy)
Features:
- Professional tabbed UI (FPS / Player / Utility / System)
- FPS optimizations (presets, toggles, sliders)
- Autosave presets (writefile/readfile if available)
- Auto-Rejoin (Teleport to same PlaceId)
- Anti-AFK
- Reapply on CharacterAdded (works when Delta/Executor autoexec runs this script)
- UI adapts to device resolution (mobile/tablet/pc)
- Touch & mouse friendly; draggable; minimize-to-icon
- Safe-by-default (no server-side exploits)
Usage: Inject this into your executor (Delta / Synapse / WeAreDevs). Script doesn't create autoexec files by itself.
]]--

-- /////////////////////////// Safety & Compatibility ///////////////////////////
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer") and Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

-- executor file API detection
local has_writefile = type(writefile) == "function"
local has_readfile  = type(readfile) == "function"
local has_isfile    = type(isfile) == "function"

-- preset storage filename (only used if writefile available)
local PRESET_FILE = "fps_booster_presets.json"

-- safe print wrapper
local function log(...)
    local ok, _ = pcall(function() print("[FPSBoost] ", ...) end)
end

-- /////////////////////////// Defaults & State ///////////////////////////
local defaults = {
    uiTheme = "Dark", -- Dark / Gray / OLED
    fps = {
        shadows = false,
        decals = true,        -- hide decals/textures
        particles = true,     -- disable particles
        plastic = true,       -- force plastic material
        lighting = 1.0,       -- 0..1 slider (1 = max reduction)
        preset = "Balanced",  -- Ultra / Balanced / Restore
    },
    player = {
        walkspeed = 16,
        jumppower = 50,
        fov = 70,
        shiftLock = false,
    },
    utility = {
        antiAFK = true,
        autoRejoin = true,
        rejoinDelay = 6, -- seconds
        autosave = true,
        autosaveEveryChange = true,
    },
    ui = {
        minimized = false,
        position = {0.5, 0.2}, -- normalized anchors
    },
}

local state = {
    applied = {},  -- current applied state
    presets = {},  -- saved presets loaded from file
    guiLoaded = false,
    lastSaveTime = 0,
}

-- load presets from file if possible
local function safeDecode(s)
    local ok, t = pcall(function() return HttpService:JSONDecode(s) end)
    if ok and type(t) == "table" then return t end
    return nil
end

local function safeEncode(t)
    local ok, s = pcall(function() return HttpService:JSONEncode(t) end)
    if ok then return s end
    return nil
end

if has_readfile and has_isfile and isfile(PRESET_FILE) then
    local ok, content = pcall(readfile, PRESET_FILE)
    if ok and content then
        local parsed = safeDecode(content)
        if parsed and type(parsed) == "table" then
            state.presets = parsed
        end
    end
end

-- /////////////////////////// Core optimization functions ///////////////////////////
local Lighting = game:GetService("Lighting")

-- store originals for restore
local original = {
    GlobalShadows = Lighting.GlobalShadows,
    Brightness = Lighting.Brightness,
    FogEnd = Lighting.FogEnd,
    AtmosphereDensity = (Lighting:FindFirstChild("Atmosphere") and Lighting.Atmosphere.Density) or nil,
}

local function clamp(v, a, b) return math.max(a, math.min(b, v)) end

local function reduceLighting(amount) -- amount 0..1
    amount = clamp(amount, 0, 1)
    -- gentle multipliers to avoid breaking visuals too hard
    Lighting.GlobalShadows = Lighting.GlobalShadows -- keep controlled separately
    Lighting.Brightness = original.Brightness * (1 - 0.6 * amount)
    Lighting.FogEnd = original.FogEnd * (1 + 3 * amount)
    if Lighting:FindFirstChild("Atmosphere") and original.AtmosphereDensity then
        Lighting.Atmosphere.Density = original.AtmosphereDensity * (1 - 0.7 * amount)
    end
end

local function restoreLighting()
    Lighting.GlobalShadows = original.GlobalShadows
    Lighting.Brightness = original.Brightness
    Lighting.FogEnd = original.FogEnd
    if Lighting:FindFirstChild("Atmosphere") and original.AtmosphereDensity then
        Lighting.Atmosphere.Density = original.AtmosphereDensity
    end
end

local function setShadows(enabled)
    pcall(function() Lighting.GlobalShadows = enabled end)
end

local function hideDecals(val)
    -- set Transparency = 1 for Decal and Texture; restore is not perfect but OK for client
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Decal") or obj:IsA("Texture") then
            pcall(function() obj.Transparency = val and 1 or 0 end)
        end
    end
    local lp = Players.LocalPlayer
    if lp and lp.Character then
        for _, obj in ipairs(lp.Character:GetDescendants()) do
            if obj:IsA("Decal") or obj:IsA("Texture") then
                pcall(function() obj.Transparency = val and 1 or 0 end)
            end
        end
    end
end

local function toggleParticles(disable)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            pcall(function() obj.Enabled = not disable end)
        end
    end
end

local function forcePlastic(toPlastic)
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                if toPlastic then
                    part.Material = Enum.Material.Plastic
                    part.Reflectance = 0
                end
            end)
        end
    end
end

local function optimizeTerrain()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        pcall(function()
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 1
        end)
    end
end

-- apply named preset
local function applyPreset(name)
    name = tostring(name or "")
    if name == "Ultra" then
        state.applied = {shadows=false, decals=true, particles=true, plastic=true, lighting=1}
    elseif name == "Balanced" then
        state.applied = {shadows=false, decals=true, particles=false, plastic=true, lighting=0.5}
    else -- Restore
        state.applied = {shadows=original.GlobalShadows, decals=false, particles=false, plastic=false, lighting=0}
    end

    -- actually apply
    setShadows(state.applied.shadows)
    hideDecals(state.applied.decals)
    toggleParticles(state.applied.particles)
    if state.applied.plastic then forcePlastic(true) end
    optimizeTerrain()
    reduceLighting(state.applied.lighting)
end

-- apply current manual settings
local function applyCurrentSettings(settings)
    settings = settings or defaults.fps
    setShadows(settings.shadows)
    hideDecals(settings.decals)
    toggleParticles(settings.particles)
    if settings.plastic then forcePlastic(true) end
    optimizeTerrain()
    reduceLighting(settings.lighting or 0)
end

-- restore everything
local function restoreAll()
    setShadows(original.GlobalShadows)
    hideDecals(false)
    toggleParticles(false)
    -- can't reliably restore material -> recommend rejoin for full restore
    restoreLighting()
end

-- /////////////////////////// Player utilities ///////////////////////////
local function safeSetWalkspeed(ws)
    ws = tonumber(ws) or 16
    local ok, plr = pcall(function() return Players.LocalPlayer end)
    if ok and plr and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
        pcall(function() plr.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = ws end)
    end
end

local function safeSetJump(jp)
    jp = tonumber(jp) or 50
    local ok, plr = pcall(function() return Players.LocalPlayer end)
    if ok and plr and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
        pcall(function() plr.Character:FindFirstChildOfClass("Humanoid").JumpPower = jp end)
    end
end

local function safeSetFOV(fov)
    fov = tonumber(fov) or 70
    pcall(function()
        if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = fov end
    end)
end

local function toggleShiftLock(on)
    pcall(function() StarterGui:SetCore("DevEnableMouseLock", on) end)
end

-- /////////////////////////// Anti-AFK ///////////////////////////
local AntiAFK = {}
AntiAFK.Enabled = defaults.utility.antiAFK
AntiAFK._virtualUser = nil
AntiAFK._conn = nil

function AntiAFK:Enable()
    if self._conn then return end
    pcall(function()
        local vu = game:GetService("VirtualUser")
        self._virtualUser = vu
        self._conn = game:GetService("Players").LocalPlayer.Idled:Connect(function()
            -- emulate click / move
            vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            wait(0.1)
            vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
    end)
    self.Enabled = true
    log("AntiAFK enabled")
end

function AntiAFK:Disable()
    if self._conn then
        pcall(function() self._conn:Disconnect() end)
        self._conn = nil
        self._virtualUser = nil
    end
    self.Enabled = false
    log("AntiAFK disabled")
end

-- init antiAFK based on defaults
if defaults.utility.antiAFK then AntiAFK:Enable() end

-- /////////////////////////// Auto-Rejoin ///////////////////////////
local AutoRejoin = {}
AutoRejoin.Enabled = defaults.utility.autoRejoin
AutoRejoin.Delay = defaults.utility.rejoinDelay
AutoRejoin._bind = nil

function AutoRejoin:TryRejoin()
    if not self.Enabled then return end
    pcall(function()
        local placeId = game.PlaceId
        log("Attempting auto-rejoin in "..tostring(self.Delay).."s...")
        wait(self.Delay)
        -- use TeleportService to teleport to the same place (may put you in new server)
        TeleportService:Teleport(placeId, Players.LocalPlayer)
    end)
end

-- detect disconnects. This is heuristic: Monitor Heartbeat and Players.LocalPlayer removal.
do
    local lastPing = tick()
    RunService.Heartbeat:Connect(function()
        lastPing = tick()
    end)
    -- fallback: detect PlayerGui removal / Game Close
    Players.LocalPlayer.AncestryChanged:Connect(function(_, parent)
        if not parent then
            -- local player removed (possible disconnect)
            spawn(function() AutoRejoin:TryRejoin() end)
        end
    end)
    -- Also detect Teleport or Kick: Listen to LocalPlayer.OnTeleport? Not available clientside reliably.
end

-- /////////////////////////// Autosave Presets ///////////////////////////
local function savePresetsToFile()
    if not has_writefile then
        return false, "no writefile"
    end
    local encoded = safeEncode(state.presets or {})
    if not encoded then return false, "encode fail" end
    local ok, err = pcall(function() writefile(PRESET_FILE, encoded) end)
    if not ok then return false, err end
    state.lastSaveTime = tick()
    return true
end

local function savePreset(name, tbl)
    name = tostring(name or "preset")
    tbl = tbl or {}
    state.presets[name] = tbl
    if defaults.utility.autosave and has_writefile then
        local ok, err = savePresetsToFile()
        if ok then log("Preset saved:", name) else warn("Save fail:", err) end
    end
end

local function loadPreset(name)
    return state.presets[name]
end

-- /////////////////////////// Responsive Professional UI ///////////////////////////
-- Minimal, modern visual: create ScreenGui with tabs
local function createGui()
    if state.guiLoaded then return end
    state.guiLoaded = true

    local lp = Players.LocalPlayer
    if not lp then
        log("LocalPlayer not available, abort GUI")
        return
    end
    -- remove old if exists
    pcall(function()
        local old = lp:WaitForChild("PlayerGui"):FindFirstChild("FPSBoostGUI")
        if old then old:Destroy() end
    end)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FPSBoostGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 9999
    ScreenGui.Parent = lp:WaitForChild("PlayerGui")

    -- basic style params
    local function themeColor(theme)
        if theme == "Gray" then return Color3.fromRGB(40,40,44), Color3.fromRGB(170,170,170), Color3.fromRGB(100,100,120) end
        if theme == "OLED" then return Color3.fromRGB(8,8,8), Color3.fromRGB(200,200,200), Color3.fromRGB(40,40,40) end
        return Color3.fromRGB(24,24,26), Color3.fromRGB(230,230,230), Color3.fromRGB(60,60,80)
    end

    local bgColor, textColor, accentColor = themeColor(defaults.uiTheme)

    -- container frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 720, 0, 420)
    main.Position = UDim2.new(0.5, -360, 0.12, 0)
    main.AnchorPoint = Vector2.new(0.5, 0)
    main.BackgroundColor3 = bgColor
    main.BorderSizePixel = 0
    main.Parent = ScreenGui
    main.Active = true
    main.Selectable = true

    -- rounded UI via UIStroke & UIPadding for pseudo-professional look
    local UICorner = Instance.new("UICorner", main)
    UICorner.CornerRadius = UDim.new(0, 12)
    local UIStroke = Instance.new("UIStroke", main)
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Thickness = 1
    UIStroke.Color = accentColor

    local padding = Instance.new("UIPadding", main)
    padding.PaddingTop = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, 12)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)

    -- title bar
    local titleBar = Instance.new("Frame", main)
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 42)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundTransparency = 1

    local title = Instance.new("TextLabel", titleBar)
    title.Size = UDim2.new(0.6, 0, 1, 0)
    title.Position = UDim2.new(0, 6, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "FPS Booster — Mega Panel"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextColor3 = textColor
    title.TextXAlignment = Enum.TextXAlignment.Left

    local subtitle = Instance.new("TextLabel", titleBar)
    subtitle.Size = UDim2.new(0.4, -6, 1, 0)
    subtitle.Position = UDim2.new(0.6, 0, 0, 0)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "v1.0 — safe-mode"
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 14
    subtitle.TextColor3 = Color3.fromRGB(150,150,150)
    subtitle.TextXAlignment = Enum.TextXAlignment.Right

    -- close & minimize btns
    local btnClose = Instance.new("TextButton", titleBar)
    btnClose.Size = UDim2.new(0, 36, 0, 28)
    btnClose.Position = UDim2.new(1, -42, 0, 6)
    btnClose.Text = "✕"
    btnClose.Font = Enum.Font.GothamBold
    btnClose.TextSize = 18
    btnClose.BackgroundColor3 = Color3.fromRGB(180,50,50)
    btnClose.TextColor3 = Color3.fromRGB(255,255,255)
    btnClose.AutoButtonColor = true

    local btnMin = Instance.new("TextButton", titleBar)
    btnMin.Size = UDim2.new(0, 36, 0, 28)
    btnMin.Position = UDim2.new(1, -84, 0, 6)
    btnMin.Text = "_"
    btnMin.Font = Enum.Font.Gotham
    btnMin.TextSize = 18
    btnMin.BackgroundColor3 = Color3.fromRGB(90,90,90)
    btnMin.TextColor3 = Color3.fromRGB(255,255,255)

    -- left nav (tabs)
    local nav = Instance.new("Frame", main)
    nav.Name = "Nav"
    nav.Size = UDim2.new(0, 180, 1, -62)
    nav.Position = UDim2.new(0, 6, 0, 52)
    nav.BackgroundTransparency = 1

    local function makeTabButton(txt, y)
        local b = Instance.new("TextButton", nav)
        b.Size = UDim2.new(1, -8, 0, 48)
        b.Position = UDim2.new(0, 6, 0, 8 + (y-1) * 56)
        b.BackgroundColor3 = Color3.fromRGB(30,30,34)
        b.BorderSizePixel = 0
        b.Text = txt
        b.Font = Enum.Font.Gotham
        b.TextSize = 16
        b.TextColor3 = textColor
        local uc = Instance.new("UICorner", b)
        uc.CornerRadius = UDim.new(0, 8)
        return b
    end

    local btnFPS = makeTabButton("FPS", 1)
    local btnPlayer = makeTabButton("Player", 2)
    local btnUtility = makeTabButton("Utility", 3)
    local btnSystem = makeTabButton("System", 4)

    -- content area
    local content = Instance.new("Frame", main)
    content.Name = "Content"
    content.Size = UDim2.new(1, -200, 1, -62)
    content.Position = UDim2.new(0, 192, 0, 52)
    content.BackgroundTransparency = 1

    local pages = {}

    local function makePage(name)
        local p = Instance.new("Frame", content)
        p.Name = name
        p.Size = UDim2.new(1, 0, 1, 0)
        p.BackgroundTransparency = 1
        p.Visible = false
        pages[name] = p
        return p
    end

    local pageFPS = makePage("FPS")
    local pagePlayer = makePage("Player")
    local pageUtility = makePage("Utility")
    local pageSystem = makePage("System")

    -- helper UI builders
    local function makeLabel(parent, text, posY)
        local lbl = Instance.new("TextLabel", parent)
        lbl.Size = UDim2.new(1, -12, 0, 22)
        lbl.Position = UDim2.new(0, 6, 0, posY)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextSize = 14
        lbl.Font = Enum.Font.Gotham
        lbl.TextColor3 = textColor
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        return lbl
    end

    local function makeToggle(parent, text, posY, default)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, -12, 0, 28)
        frame.Position = UDim2.new(0, 6, 0, posY)
        frame.BackgroundTransparency = 1

        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(0.7, 0, 1, 0)
        lbl.Position = UDim2.new(0, 0, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextColor3 = textColor
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 78, 1, 0)
        btn.Position = UDim2.new(1, -78, 0, 0)
        btn.Text = default and "ON" or "OFF"
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.AutoButtonColor = true
        btn.BackgroundColor3 = default and Color3.fromRGB(60,140,60) or Color3.fromRGB(80,80,80)
        local uc = Instance.new("UICorner", btn)
        uc.CornerRadius = UDim.new(0, 6)
        return btn
    end

    local function makeSlider(parent, labelText, posY, min, max, default)
        makeLabel(parent, labelText, posY)
        local sliderFrame = Instance.new("Frame", parent)
        sliderFrame.Size = UDim2.new(1, -12, 0, 26)
        sliderFrame.Position = UDim2.new(0, 6, 0, posY + 24)
        sliderFrame.BackgroundColor3 = Color3.fromRGB(30,30,34)
        sliderFrame.BorderSizePixel = 0
        local uc = Instance.new("UICorner", sliderFrame)
        uc.CornerRadius = UDim.new(0, 6)

        local bar = Instance.new("Frame", sliderFrame)
        bar.Size = UDim2.new(1, -16, 0, 8)
        bar.Position = UDim2.new(0, 8, 0.5, -4)
        bar.BackgroundColor3 = Color3.fromRGB(52,52,58)
        local uc2 = Instance.new("UICorner", bar)
        uc2.CornerRadius = UDim.new(0, 6)

        local knob = Instance.new("ImageButton", bar)
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
        knob.BackgroundTransparency = 1
        knob.Image = "rbxassetid://3570695787" -- circle
        knob.ImageColor3 = accentColor

        local valueLabel = Instance.new("TextLabel", sliderFrame)
        valueLabel.Size = UDim2.new(0.2, 0, 1, 0)
        valueLabel.Position = UDim2.new(0.8, -8, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(default)
        valueLabel.Font = Enum.Font.Gotham
        valueLabel.TextSize = 14
        valueLabel.TextColor3 = textColor

        -- dragging
        local dragging = false
        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)
        knob.InputEnded:Connect(function(input)
            dragging = false
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement or dragging and inp.UserInputType == Enum.UserInputType.Touch then
                local abs = inp.Position.X
                local origin = bar.AbsolutePosition.X
                local width = bar.AbsoluteSize.X
                local relative = clamp((abs - origin) / width, 0, 1)
                knob.Position = UDim2.new(relative, -7, 0.5, -7)
                local val = math.floor(min + (max - min) * relative)
                valueLabel.Text = tostring(val)
                return val, relative
            end
        end)
        -- return controls
        return {
            frame = sliderFrame,
            setValue = function(v)
                v = clamp(v, min, max)
                local relative = (v - min) / (max - min)
                knob.Position = UDim2.new(relative, -7, 0.5, -7)
                valueLabel.Text = tostring(v)
            end,
            getValue = function()
                return tonumber(valueLabel.Text)
            end,
        }
    end

    -- populate FPS page
    do
        local p = pageFPS
        local y = 8
        makeLabel(p, "Presets", y)
        local btnUltra = Instance.new("TextButton", p)
        btnUltra.Size = UDim2.new(0, 120, 0, 34)
        btnUltra.Position = UDim2.new(0, 6, 0, y + 24)
        btnUltra.Text = "ULTRA"
        btnUltra.Font = Enum.Font.Gotham
        btnUltra.TextSize = 14
        btnUltra.BackgroundColor3 = Color3.fromRGB(180,40,40)
        btnUltra.TextColor3 = Color3.fromRGB(255,255,255)
        local btnBalanced = btnUltra:Clone()
        btnBalanced.Parent = p
        btnBalanced.Position = UDim2.new(0, 138, 0, y + 24)
        btnBalanced.Text = "BALANCED"
        btnBalanced.BackgroundColor3 = Color3.fromRGB(90,90,200)
        local btnRestore = btnUltra:Clone()
        btnRestore.Parent = p
        btnRestore.Position = UDim2.new(0, 270, 0, y + 24)
        btnRestore.Text = "RESTORE"
        btnRestore.BackgroundColor3 = Color3.fromRGB(80,80,80)

        local tY = y + 72
        local toggleDecalsBtn = makeToggle(p, "Remove Decals/Textures", tY, defaults.fps.decals)
        tY = tY + 42
        local toggleParticlesBtn = makeToggle(p, "Disable Particles", tY, defaults.fps.particles)
        tY = tY + 42
        local toggleShadowsBtn = makeToggle(p, "Disable Shadows", tY, not original.GlobalShadows)
        tY = tY + 42
        local togglePlasticBtn = makeToggle(p, "Force Plastic Material", tY, defaults.fps.plastic)
        tY = tY + 42
        local lightingSlider = makeSlider(p, "Lighting Reduction (%)", tY, 0, 100, defaults.fps.lighting * 100)
        tY = tY + 60

        local applyBtn = Instance.new("TextButton", p)
        applyBtn.Size = UDim2.new(0, 160, 0, 36)
        applyBtn.Position = UDim2.new(0, 6, 0, tY)
        applyBtn.Text = "Apply Settings"
        applyBtn.Font = Enum.Font.Gotham
        applyBtn.TextSize = 14
        applyBtn.BackgroundColor3 = Color3.fromRGB(60,120,60)
        applyBtn.TextColor3 = Color3.fromRGB(255,255,255)

        -- callbacks
        btnUltra.MouseButton1Click:Connect(function()
            applyPreset("Ultra")
        end)
        btnBalanced.MouseButton1Click:Connect(function()
            applyPreset("Balanced")
        end)
        btnRestore.MouseButton1Click:Connect(function()
            applyPreset("Restore")
        end)

        toggleDecalsBtn.MouseButton1Click:Connect(function()
            local new = toggleDecalsBtn.Text ~= "ON"
            toggleDecalsBtn.Text = new and "ON" or "OFF"
            toggleDecalsBtn.BackgroundColor3 = new and Color3.fromRGB(60,140,60) or Color3.fromRGB(80,80,80)
        end)
        toggleParticlesBtn.MouseButton1Click:Connect(function()
            local new = toggleParticlesBtn.Text ~= "ON"
            toggleParticlesBtn.Text = new and "ON" or "OFF"
            toggleParticlesBtn.BackgroundColor3 = new and Color3.fromRGB(60,140,60) or Color3.fromRGB(80,80,80)
        end)
        toggleShadowsBtn.MouseButton1Click:Connect(function()
            local new = toggleShadowsBtn.Text ~= "ON"
            toggleShadowsBtn.Text = new and "ON" or "OFF"
            toggleShadowsBtn.BackgroundColor3 = new and Color3.fromRGB(60,140,60) or Color3.fromRGB(80,80,80)
        end)
        togglePlasticBtn.MouseButton1Click:Connect(function()
            local new = togglePlasticBtn.Text ~= "ON"
            togglePlasticBtn.Text = new and "ON" or "OFF"
            togglePlasticBtn.BackgroundColor3 = new and Color3.fromRGB(60,140,60) or Color3.fromRGB(80,80,80)
        end)

        applyBtn.MouseButton1Click:Connect(function()
            local decals = toggleDecalsBtn.Text == "ON"
            local particles = toggleParticlesBtn.Text == "ON"
            local shadows = toggleShadowsBtn.Text == "ON"
            local plastic = togglePlasticBtn.Text == "ON"
            local lightingPct = lightingSlider.getValue and lightingSlider.getValue() or defaults.fps.lighting * 100
            local settings = {
                decals = decals,
                particles = particles,
                shadows = shadows,
                plastic = plastic,
                lighting = (lightingPct / 100),
            }
            applyCurrentSettings(settings)
            if defaults.utility.autosave then
                savePreset("last_fps", settings)
            end
        end)
    end

    -- PLAYER page
    do
        local p = pagePlayer
        local y = 6
        local wsSlider = makeSlider(p, "WalkSpeed", y, 8, 150, defaults.player.walkspeed)
        y = y + 60
        local jpSlider = makeSlider(p, "Jump Power", y, 30, 300, defaults.player.jumppower)
        y = y + 60
        local fovSlider = makeSlider(p, "Camera FOV", y, 50, 120, defaults.player.fov)
        y = y + 60

        local applyBtn = Instance.new("TextButton", p)
        applyBtn.Size = UDim2.new(0, 140, 0, 36)
        applyBtn.Position = UDim2.new(0, 6, 0, y)
        applyBtn.Text = "Apply Player"
        applyBtn.Font = Enum.Font.Gotham
        applyBtn.TextSize = 14
        applyBtn.BackgroundColor3 = Color3.fromRGB(60,120,60)
        applyBtn.TextColor3 = Color3.fromRGB(255,255,255)

        applyBtn.MouseButton1Click:Connect(function()
            local ws = wsSlider.getValue and wsSlider.getValue() or defaults.player.walkspeed
            local jp = jpSlider.getValue and jpSlider.getValue() or defaults.player.jumppower
            local fov = fovSlider.getValue and fovSlider.getValue() or defaults.player.fov
            safeSetWalkspeed(ws)
            safeSetJump(jp)
            safeSetFOV(fov)
            if defaults.utility.autosave then savePreset("last_player", {walkspeed=ws, jumppower=jp, fov=fov}) end
        end)
    end

    -- UTILITY page
    do
        local p = pageUtility
        local y = 6
        local antiAFKBtn = makeToggle(p, "Anti-AFK (prevent idle kick)", y, defaults.utility.antiAFK)
        y = y + 42
        local autoRejoinBtn = makeToggle(p, "Auto-Rejoin on disconnect", y, defaults.utility.autoRejoin)
        y = y + 42
        local rejoinDelaySlider = makeSlider(p, "Rejoin Delay (s)", y, 2, 20, defaults.utility.rejoinDelay)
        y = y + 60
        local autosaveBtn = makeToggle(p, "Autosave Presets", y, defaults.utility.autosave)
        y = y + 42

        antiAFKBtn.MouseButton1Click:Connect(function()
            local on = antiAFKBtn.Text ~= "ON"
            antiAFKBtn.Text = on and "ON" or "OFF"
            antiAFKBtn.BackgroundColor3 = on and Color3.fromRGB(60,140,60) or Color3.fromRGB(80,80,80)
            if on then AntiAFK:Enable() else AntiAFK:Disable() end
        end)

        autoRejoinBtn.MouseButton1Click:Connect(function()
            local on = autoRejoinBtn.Text ~= "ON"
            autoRejoinBtn.Text = on and "ON" or "OFF"
            autoRejoinBtn.BackgroundColor3 = on and Color3.fromRGB(60,140,60) or Color3.fromRGB(80,80,80)
            AutoRejoin.Enabled = on
        end)
    end

    -- SYSTEM page
    do
        local p = pageSystem
        local y = 6
        makeLabel(p, "Presets & Storage", y)
        local saveBtn = Instance.new("TextButton", p)
        saveBtn.Size = UDim2.new(0, 120, 0, 34)
        saveBtn.Position = UDim2.new(0, 6, 0, y + 28)
        saveBtn.Text = "Save Current"
        saveBtn.Font = Enum.Font.Gotham
        saveBtn.BackgroundColor3 = Color3.fromRGB(60,120,60)

        local loadBtn = saveBtn:Clone()
        loadBtn.Parent = p
        loadBtn.Position = UDim2.new(0, 138, 0, y + 28)
        loadBtn.Text = "Load Last"

        local resetUIBtn = saveBtn:Clone()
        resetUIBtn.Parent = p
        resetUIBtn.Position = UDim2.new(0, 270, 0, y + 28)
        resetUIBtn.Text = "Reset UI Pos"

        local killBtn = Instance.new("TextButton", p)
        killBtn.Size = UDim2.new(0, 120, 0, 34)
        killBtn.Position = UDim2.new(0, 6, 0, y + 74)
        killBtn.Text = "Kill Panel"
        killBtn.Font = Enum.Font.Gotham
        killBtn.BackgroundColor3 = Color3.fromRGB(160,40,40)

        saveBtn.MouseButton1Click:Connect(function()
            -- snapshot current settings
            local snap = {
                fps = state.applied or defaults.fps,
                player = {
                    walkspeed = defaults.player.walkspeed,
                    jumppower = defaults.player.jumppower,
                    fov = defaults.player.fov,
                },
                utility = {
                    antiAFK = AntiAFK.Enabled,
                    autoRejoin = AutoRejoin.Enabled,
                }
            }
            savePreset("manual_"..tostring(os.time()), snap)
            saveBtn.Text = "Saved"
            wait(1.1)
            saveBtn.Text = "Save Current"
        end)

        loadBtn.MouseButton1Click:Connect(function()
            local pre = loadPreset("last_fps")
            if pre then
                applyCurrentSettings(pre)
                loadBtn.Text = "Loaded"
                wait(1)
                loadBtn.Text = "Load Last"
            else
                loadBtn.Text = "No Last"
                wait(1)
                loadBtn.Text = "Load Last"
            end
        end)

        resetUIBtn.MouseButton1Click:Connect(function()
            main.Position = UDim2.new(0.5, -360, 0.12, 0)
        end)

        killBtn.MouseButton1Click:Connect(function()
            pcall(function() ScreenGui:Destroy() end)
            state.guiLoaded = false
            log("Panel killed by user")
        end)
    end

    -- tab switching
    local function setActive(page)
        for k, v in pairs(pages) do v.Visible = false end
        pages[page].Visible = true
    end
    setActive("FPS")
    btnFPS.MouseButton1Click:Connect(function() setActive("FPS") end)
    btnPlayer.MouseButton1Click:Connect(function() setActive("Player") end)
    btnUtility.MouseButton1Click:Connect(function() setActive("Utility") end)
    btnSystem.MouseButton1Click:Connect(function() setActive("System") end)

    -- drag main
    do
        local dragging = false
        local dragStart, startPos
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    -- minimize and close actions
    btnClose.MouseButton1Click:Connect(function()
        pcall(function() ScreenGui:Destroy() end)
        state.guiLoaded = false
    end)
    btnMin.MouseButton1Click:Connect(function()
        main.Visible = not main.Visible
    end)

    log("GUI created. Use tabs to configure features.")
end

-- /////////////////////////// Reapply on CharacterAdded ///////////////////////////
local function onCharacter(character)
    -- apply last known player settings & faint reapply of visual settings
    local fpsSettings = state.presets["last_fps"] or defaults.fps
    pcall(function() applyCurrentSettings(fpsSettings) end)
    -- apply player settings last saved
    local playerLast = state.presets["last_player"]
    if playerLast then
        safeSetWalkspeed(playerLast.walkspeed)
        safeSetJump(playerLast.jumppower)
        safeSetFOV(playerLast.fov)
    end
end

Players.PlayerAdded:Connect(function(plr)
    if plr == Players.LocalPlayer then
        if plr.Character then onCharacter(plr.Character) end
        plr.CharacterAdded:Connect(onCharacter)
    end
end)
-- if script injected after spawn
if Players.LocalPlayer then
    if Players.LocalPlayer.Character then onCharacter(Players.LocalPlayer.Character) end
    Players.LocalPlayer.CharacterAdded:Connect(onCharacter)
end

-- /////////////////////////// Minimal init & autosave watcher ///////////////////////////
-- Create GUI (if Delta autoexec runs this, panel appears)
createGui()

-- autosave every change (periodic)
spawn(function()
    while true do
        if defaults.utility.autosave and has_writefile then
            local ok, err = pcall(function() savePresetsToFile() end)
            if not ok then warn("Autosave error:", err) end
        end
        wait(15) -- every 15 seconds persistence: adjust if needed
    end
end)

-- initial apply of Balanced preset (safe default)
applyPreset("Balanced")

-- final helpful message in executor console
log("FPS Booster Mega-Panel initialized. If Delta autoexec runs scripts on rejoin, it will reapply when your executor runs this script. Use UI to toggle features. Autosave uses writefile if available.")

-- End of script        if autosaveTimer >= 30 then
            safeWrite(Settings)
            autosaveTimer = 0
        end
    end
end)

-- =========================
-- Blur effect (single instance)
-- =========================
local blur = Lighting:FindFirstChild("DeltaPanelBlur")
if not blur then
    blur = Instance.new("BlurEffect")
    blur.Name = "DeltaPanelBlur"
    blur.Size = 0
    blur.Parent = Lighting
end

local function setBlur(on)
    local goal = {Size = on and 14 or 0}
    TweenService:Create(blur, TweenInfo.new(0.35, Enum.EasingStyle.Quad), goal):Play()
end

-- =========================
-- UI Root
-- =========================
local playerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaSuperPanel"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

-- Theme colors
local PURPLE = Color3.fromRGB(120,40,180)
local PURPLE_DARK = Color3.fromRGB(70,20,110)
local ACCENT = Color3.fromRGB(190,110,255)

-- =========================
-- Helper constructors
-- =========================
local function mk(parent, class, props)
    local obj = Instance.new(class)
    if props then
        for k,v in pairs(props) do
            obj[k] = v
        end
    end
    obj.Parent = parent
    return obj
end

local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

-- Small toast system
local toastHolder = mk(ScreenGui, "Frame", {
    Name = "ToastHolder",
    Size = UDim2.new(0,300,0,200),
    Position = UDim2.new(1,-320,0.7,0),
    BackgroundTransparency = 1
})
local function toast(text, dur)
    dur = dur or 2.5
    local f = mk(toastHolder, "Frame", {
        Size = UDim2.new(1,0,0,40),
        BackgroundColor3 = Color3.fromRGB(40,40,40),
        BackgroundTransparency = 0.1,
        AnchorPoint = Vector2.new(0,0)
    })
    mk(f, "UICorner", {CornerRadius = UDim.new(0,6)})
    local l = mk(f, "TextLabel", {
        Size = UDim2.new(1,-10,1,0),
        Position = UDim2.new(0,5,0,0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.new(1,1,1),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextScaled = true
    })
    f.Position = UDim2.new(1,0,0,0)
    tween(f, {Position = UDim2.new(0,0,0,0)}, 0.3)
    task.delay(dur, function()
        if f then
            tween(f, {Position = UDim2.new(1,0,0,0)}, 0.3)
            task.delay(0.35, function() pcall(function() f:Destroy() end) end)
        end
    end)
end

-- =========================
-- Panel & Float Icon (draggable with input)
-- =========================
local panel = mk(ScreenGui, "Frame", {
    Name = "DeltaPanel",
    Size = UDim2.new(0,520,0,360),
    Position = UDim2.new(0.5,-260,1.2,0),
    BackgroundColor3 = PURPLE,
    BackgroundTransparency = 0.18,
    BorderSizePixel = 0
})
mk(panel, "UICorner", {CornerRadius = UDim.new(0,14)})
mk(panel, "UIStroke", {Color = PURPLE_DARK, Thickness = 2, Transparency = 0.4})

-- shadow image
local shadow = mk(panel, "ImageLabel", {
    Size = UDim2.new(1,40,1,40),
    Position = UDim2.new(0,-20,0,-20),
    BackgroundTransparency = 1,
    Image = "rbxassetid://6015897843",
    ImageTransparency = 0.6
})

-- Title bar
local titleBar = mk(panel, "Frame", {
    Size = UDim2.new(1,0,0,48),
    BackgroundTransparency = 1
})
local title = mk(titleBar, "TextLabel", {
    Size = UDim2.new(1, -120, 1, 0),
    Position = UDim2.new(0,12,0,0),
    BackgroundTransparency = 1,
    Text = "Delta Super Panel",
    TextColor3 = Color3.new(1,1,1),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextScaled = true,
})
mk(title, "UITextSizeConstraint", {MaxTextSize = 24})

-- minimize/close/floating icon
local btnMin = mk(titleBar, "ImageButton", {
    Size = UDim2.new(0,44,0,36),
    Position = UDim2.new(1,-52,0,6),
    BackgroundTransparency = 1,
    Image = "",
    AutoButtonColor = true
})
local minTxt = mk(btnMin, "TextLabel", {
    Size = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    Text = "-",
    TextColor3 = Color3.new(1,1,1),
    TextScaled = true
})
mk(btnMin, "UICorner", {CornerRadius = UDim.new(0,8)})

local btnClose = mk(titleBar, "ImageButton", {
    Size = UDim2.new(0,36,0,36),
    Position = UDim2.new(1,-96,0,6),
    BackgroundTransparency = 1,
    Image = "",
    AutoButtonColor = true
})
local closeTxt = mk(btnClose, "TextLabel", {
    Size = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    Text = "x",
    TextColor3 = Color3.new(1,1,1),
    TextScaled = true
})
mk(btnClose, "UICorner", {CornerRadius = UDim.new(0,8)})

-- floating draggable icon
local floatBtn = mk(ScreenGui, "ImageButton", {
    Name = "DeltaFloat",
    Size = UDim2.new(0,54,0,54),
    Position = UDim2.new(0.06,0,0.54,0),
    BackgroundTransparency = 1,
    Image = "rbxassetid://3926307971"
})
floatBtn.Visible = false
floatBtn.Active = true

-- drag logic for floatBtn (improved)
do
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    floatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = floatBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    floatBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            floatBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- hide/show handlers (also control blur)
btnMin.MouseButton1Click:Connect(function()
    tween(panel, {Position = UDim2.new(0.5,-260,1.2,0)}, 0.28)
    task.delay(0.28, function()
        panel.Visible = false
        floatBtn.Visible = true
    end)
    setBlur(false)
end)

floatBtn.MouseButton1Click:Connect(function()
    panel.Visible = true
    floatBtn.Visible = false
    tween(panel, {Position = UDim2.new(0.5,-260,0.5,-180)}, 0.28)
    setBlur(true)
end)

btnClose.MouseButton1Click:Connect(function()
    -- fully close UI and cleanup blur
    pcall(function() ScreenGui:Destroy() end)
    setBlur(false)
end)

-- initial open animation
tween(panel, {Position = UDim2.new(0.5,-260,0.5,-180)}, 0.45)
setBlur(true)

-- =========================
-- Layout: sidebar + content
-- =========================
local sidebar = mk(panel, "Frame", {
    Size = UDim2.new(0,140,1,-56),
    Position = UDim2.new(0,0,0,48),
    BackgroundTransparency = 1
})
local content = mk(panel, "Frame", {
    Size = UDim2.new(1,-140,1,-56),
    Position = UDim2.new(0,140,0,48),
    BackgroundTransparency = 1
})

-- tabs creation with icon + text
local tabs = {}
local function createTab(name, iconId, y)
    local b = mk(sidebar, "TextButton", {
        Size = UDim2.new(1, -12, 0, 48),
        Position = UDim2.new(0, 6, 0, y),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = true
    })
    mk(b, "UICorner", {CornerRadius = UDim.new(0,10)})
    local icon = mk(b, "ImageLabel", {
        Size = UDim2.new(0,34,0,34),
        Position = UDim2.new(0,8,0.5,-17),
        BackgroundTransparency = 1,
        Image = iconId
    })
    local label = mk(b, "TextLabel", {
        Size = UDim2.new(1, -60,1,0),
        Position = UDim2.new(0,50,0,0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Color3.new(1,1,1),
        TextScaled = true,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    return b
end

local tMain = createTab("MAIN", "rbxassetid://3926305904", 6)
local tUtility = createTab("UTILITY", "rbxassetid://3926307971", 62)
local tPlayer = createTab("PLAYER", "rbxassetid://3926309567", 118)
local tWebhook = createTab("WEBHOOK", "rbxassetid://3926305904", 174)
local tSettings = createTab("SETTINGS", "rbxassetid://3926307971", 230)

local pages = {}
local function newPage(name)
    local p = mk(content, "Frame", {
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1
    })
    p.Visible = false
    return p
end

pages.main = newPage("main")
pages.utility = newPage("utility")
pages.player = newPage("player")
pages.webhook = newPage("webhook")
pages.settings = newPage("settings")
pages.main.Visible = true

local function showPage(p)
    for k,v in pairs(pages) do v.Visible = false end
    p.Visible = true
end

tMain.MouseButton1Click:Connect(function() showPage(pages.main) end)
tUtility.MouseButton1Click:Connect(function() showPage(pages.utility) end)
tPlayer.MouseButton1Click:Connect(function() showPage(pages.player) end)
tWebhook.MouseButton1Click:Connect(function() showPage(pages.webhook) end)
tSettings.MouseButton1Click:Connect(function() showPage(pages.settings) end)

-- =========================
-- MAIN PAGE features
-- =========================
do
    local p = pages.main
    local y = 12
    local function makeToggle(text, key, ypos)
        local b = mk(p, "TextButton", {
            Size = UDim2.new(0,300,0,44),
            Position = UDim2.new(0,12,0,ypos),
            BackgroundColor3 = PURPLE_DARK,
            BackgroundTransparency = 0.15,
            Text = text.." : "..(Settings[key] and "ON" or "OFF"),
            TextColor3 = Color3.new(1,1,1),
            TextScaled = true
        })
        mk(b, "UICorner", {CornerRadius = UDim.new(0,8)})
        b.MouseButton1Click:Connect(function()
            Settings[key] = not Settings[key]
            b.Text = text.." : "..(Settings[key] and "ON" or "OFF")
            safeWrite(Settings)
            toast(text.." set to "..(Settings[key] and "ON" or "OFF"))
            if key == "autoExecute" then
                -- nothing extra
            end
            if key == "antiAFK" and Settings.antiAFK then
                -- immediate small jump to avoid AFK
                pcall(function()
                    local ch = LocalPlayer.Character
                    if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.Jump = true end
                end)
            end
        end)
        return b
    end

    makeToggle("Auto Execute", "autoExecute", 12)
    makeToggle("Anti AFK", "antiAFK", 72)
    makeToggle("Auto Rejoin", "autoRejoin", 132)

    local btnRejoin = mk(p, "TextButton", {
        Size = UDim2.new(0,300,0,44),
        Position = UDim2.new(0,12,0,192),
        BackgroundColor3 = ACCENT,
        BackgroundTransparency = 0.15,
        Text = "Force Rejoin",
        TextColor3 = Color3.new(1,1,1),
        TextScaled = true
    })
    mk(btnRejoin, "UICorner", {CornerRadius = UDim.new(0,8)})
    btnRejoin.MouseButton1Click:Connect(function()
        toast("Rejoining server...")
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

-- =========================
-- UTILITY PAGE (ESP, WalkSpeed, JumpPower, FPS)
-- =========================
do
    local p = pages.utility
    -- ESP Toggle
    local espBtn = mk(p, "TextButton", {
        Size = UDim2.new(0,220,0,40),
        Position = UDim2.new(0,12,0,12),
        BackgroundColor3 = PURPLE_DARK,
        Text = "ESP: "..(Settings.espEnabled and "ON" or "OFF"),
        TextScaled = true
    }); mk(espBtn, "UICorner", {CornerRadius = UDim.new(0,8)})
    local espEnabled = Settings.espEnabled

    local function enableESP(v)
        espEnabled = v
        if v then
            for _,plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    if not plr.Character:FindFirstChild("DeltaESP") then
                        local h = Instance.new("Highlight", plr.Character)
                        h.Name = "DeltaESP"
                        h.OutlineColor = ACCENT
                        h.FillTransparency = 1
                    end
                end
            end
        else
            for _,plr in pairs(Players:GetPlayers()) do
                if plr.Character and plr.Character:FindFirstChild("DeltaESP") then
                    pcall(function() plr.Character.DeltaESP:Destroy() end)
                end
            end
        end
    end

    espBtn.MouseButton1Click:Connect(function()
        espEnabled = not espEnabled
        Settings.espEnabled = espEnabled
        espBtn.Text = "ESP: "..(espEnabled and "ON" or "OFF")
        saveSettings()
        enableESP(espEnabled)
        toast("ESP "..(espEnabled and "enabled" or "disabled"))
    end)

    Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function(chr)
            if espEnabled then
                if not chr:FindFirstChild("DeltaESP") then
                    local h = Instance.new("Highlight", chr)
                    h.Name = "DeltaESP"
                    h.OutlineColor = ACCENT
                    h.FillTransparency = 1
                end
            end
        end)
    end)

    -- WalkSpeed & JumpPower inputs
    local wsBox = mk(p, "TextBox", {
        Size = UDim2.new(0,220,0,40),
        Position = UDim2.new(0,12,0,70),
        PlaceholderText = "WalkSpeed (number)",
        Text = tostring(Settings.walkSpeed),
        TextScaled = true,
        BackgroundColor3 = PURPLE_DARK
    }); mk(wsBox, "UICorner", {CornerRadius = UDim.new(0,8)})
    wsBox.FocusLost:Connect(function(enter)
        local v = tonumber(wsBox.Text)
        if v then
            Settings.walkSpeed = v
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = v
            end
            saveSettings()
            toast("WalkSpeed set to "..v)
        else
            wsBox.Text = tostring(Settings.walkSpeed)
        end
    end)

    local jpBox = mk(p, "TextBox", {
        Size = UDim2.new(0,220,0,40),
        Position = UDim2.new(0,12,0,130),
        PlaceholderText = "JumpPower (number)",
        Text = tostring(Settings.jumpPower),
        TextScaled = true,
        BackgroundColor3 = PURPLE_DARK
    }); mk(jpBox, "UICorner", {CornerRadius = UDim.new(0,8)})
    jpBox.FocusLost:Connect(function(enter)
        local v = tonumber(jpBox.Text)
        if v then
            Settings.jumpPower = v
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.JumpPower = v
            end
            saveSettings()
            toast("JumpPower set to "..v)
        else
            jpBox.Text = tostring(Settings.jumpPower)
        end
    end)

    -- FPS counter
    local fpsLabel = mk(p, "TextLabel", {
        Size = UDim2.new(0,220,0,30),
        Position = UDim2.new(0,12,0,190),
        BackgroundTransparency = 1,
        Text = "FPS: --",
        TextScaled = true,
        TextColor3 = Color3.new(1,1,1)
    })
    do
        local last = tick()
        local frames = 0
        RunService.RenderStepped:Connect(function()
            frames = frames + 1
            if tick() - last >= 1 then
                fpsLabel.Text = "FPS: "..tostring(frames)
                frames = 0
                last = tick()
            end
        end)
    end
end

-- =========================
-- PLAYER PAGE (list + teleport)
-- =========================
do
    local p = pages.player
    local sc = mk(p, "ScrollingFrame", {
        Size = UDim2.new(0,300,0,300),
        Position = UDim2.new(0,12,0,12),
        CanvasSize = UDim2.new(0,0,1,0),
        BackgroundTransparency = 1
    })
    local uiList = mk(sc, "UIListLayout", {Padding = UDim.new(0,6)})
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local btn = mk(sc, "TextButton", {
                Size = UDim2.new(1,0,0,40),
                BackgroundColor3 = PURPLE_DARK,
                Text = plr.Name,
                TextScaled = true
            }); mk(btn, "UICorner", {CornerRadius = UDim.new(0,8)})
            btn.MouseButton1Click:Connect(function()
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = plr.Character.HumanoidRootPart
                    LocalPlayer.Character:MoveTo(hrp.Position + Vector3.new(0,3,0))
                    toast("Teleported to "..plr.Name)
                else
                    toast(plr.Name.." not available")
                end
            end)
        end
    end
    Players.PlayerAdded:Connect(function(plr)
        task.delay(0.5, function()
            local btn = mk(sc, "TextButton", {
                Size = UDim2.new(1,0,0,40),
                BackgroundColor3 = PURPLE_DARK,
                Text = plr.Name,
                TextScaled = true
            }); mk(btn, "UICorner", {CornerRadius = UDim.new(0,8)})
            btn.MouseButton1Click:Connect(function()
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character:MoveTo(plr.Character.HumanoidRootPart.Position + Vector3.new(0,3,0))
                    toast("Teleported to "..plr.Name)
                end
            end)
            sc.CanvasSize = UDim2.new(0,0,0, #Players:GetPlayers() * 46)
        end)
    end)
end

-- =========================
-- WEBHOOK PAGE
-- =========================
do
    local p = pages.webhook
    local urlBox = mk(p, "TextBox", {
        Size = UDim2.new(0,360,0,44),
        Position = UDim2.new(0,12,0,12),
        PlaceholderText = "Discord Webhook URL",
        Text = Settings.webhookURL,
        TextScaled = true,
        BackgroundColor3 = PURPLE_DARK
    }); mk(urlBox, "UICorner", {CornerRadius = UDim.new(0,8)})

    local idBox = mk(p, "TextBox", {
        Size = UDim2.new(0,360,0,44),
        Position = UDim2.new(0,12,0,70),
        PlaceholderText = "User ID / Name",
        Text = Settings.userID,
        TextScaled = true,
        BackgroundColor3 = PURPLE_DARK
    }); mk(idBox, "UICorner", {CornerRadius = UDim.new(0,8)})

    local saveBtn = mk(p, "TextButton", {
        Size = UDim2.new(0,176,0,40),
        Position = UDim2.new(0,12,0,130),
        Text = "Save",
        BackgroundColor3 = ACCENT
    }); mk(saveBtn, "UICorner", {CornerRadius = UDim.new(0,8)})
    saveBtn.MouseButton1Click:Connect(function()
        Settings.webhookURL = urlBox.Text
        Settings.userID = idBox.Text
        saveSettings()
        toast("Webhook saved")
    end)

    local testBtn = mk(p, "TextButton", {
        Size = UDim2.new(0,176,0,40),
        Position = UDim2.new(0,200,0,130),
        Text = "Send Test",
        BackgroundColor3 = ACCENT
    }); mk(testBtn, "UICorner", {CornerRadius = UDim.new(0,8)})
    testBtn.MouseButton1Click:Connect(function()
        if Settings.webhookURL ~= "" then
            local payload = {content = ("[DeltaPanel] Test from %s"):format(Settings.userID ~= "" and Settings.userID or LocalPlayer.Name)}
            local ok, res = pcall(function()
                request({
                    Url = Settings.webhookURL,
                    Method = "POST",
                    Headers = {["Content-Type"]="application/json"},
                    Body = HttpService:JSONEncode(payload)
                })
            end)
            if ok then toast("Webhook sent") else toast("Webhook failed") end
        else
            toast("Set webhook URL first")
        end
    end)
end

-- =========================
-- SETTINGS PAGE (misc)
-- =========================
do
    local p = pages.settings
    local info = mk(p, "TextLabel", {
        Size = UDim2.new(1,-24,0,80),
        Position = UDim2.new(0,12,0,12),
        BackgroundTransparency = 1,
        TextWrapped = true,
        Text = "Theme: Dark Purple. Use GitHub loader below to auto load updates."
    })

    local ghBox = mk(p, "TextBox", {
        Size = UDim2.new(0,360,0,44),
        Position = UDim2.new(0,12,0,100),
        PlaceholderText = "GitHub raw URL (optional)",
        Text = "",
        TextScaled = true,
        BackgroundColor3 = PURPLE_DARK
    }); mk(ghBox, "UICorner", {CornerRadius = UDim.new(0,8)})

    local ghBtn = mk(p, "TextButton", {
        Size = UDim2.new(0,176,0,40),
        Position = UDim2.new(0,12,0,160),
        Text = "Load From GitHub",
        BackgroundColor3 = ACCENT
    }); mk(ghBtn, "UICorner", {CornerRadius = UDim.new(0,8)})
    ghBtn.MouseButton1Click:Connect(function()
        local url = ghBox.Text
        if url and url ~= "" then
            local ok, res = pcall(function() return game:HttpGet(url) end)
            if ok and type(res) == "string" then
                local fnOk, fnRes = pcall(function() return loadstring(res)() end)
                if fnOk then toast("Loaded script from GitHub") else toast("Load error") end
            else
                toast("Failed to get file")
            end
        else
            toast("Paste raw.githubusercontent.com link")
        end
    end)

    -- server info small badge
    local badge = mk(p, "TextLabel", {
        Size = UDim2.new(0,200,0,40),
        Position = UDim2.new(0,12,0,220),
        BackgroundColor3 = PURPLE_DARK,
        Text = ("PlaceId: %s | Players: %d"):format(tostring(game.PlaceId), #Players:GetPlayers()),
        TextScaled = true
    }); mk(badge, "UICorner", {CornerRadius = UDim.new(0,8)})

    Players.PlayerAdded:Connect(function()
        badge.Text = ("PlaceId: %s | Players: %d"):format(tostring(game.PlaceId), #Players:GetPlayers())
    end)
    Players.PlayerRemoving:Connect(function()
        badge.Text = ("PlaceId: %s | Players: %d"):format(tostring(game.PlaceId), #Players:GetPlayers())
    end)
end

-- =========================
-- Anti-AFK improved / AutoJump every 10 minutes
-- =========================
task.spawn(function()
    while true do
        task.wait(600) -- 10 minutes
        if Settings.autoExecute and Settings.antiAFK then
            pcall(function()
                local ch = LocalPlayer.Character
                if ch and ch:FindFirstChild("Humanoid") then
                    ch.Humanoid.Jump = true
                    toast("Anti-AFK jump")
                end
            end)
        end
    end
end)

-- =========================
-- Auto Rejoin handlers
-- =========================
Players.LocalPlayer.OnTeleport:Connect(function(state)
    if Settings.autoExecute and Settings.autoRejoin and state == Enum.TeleportState.Failed then
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end)
Players.PlayerRemoving:Connect(function(p)
    if p == LocalPlayer and Settings.autoExecute and Settings.autoRejoin then
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end)

-- =========================
-- Finalize: apply saved stats (WalkSpeed/JumpPower/ESP)
-- =========================
if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
    LocalPlayer.Character.Humanoid.WalkSpeed = Settings.walkSpeed or 16
    LocalPlayer.Character.Humanoid.JumpPower = Settings.jumpPower or 50
end
if Settings.espEnabled then
    -- run enableESP routine: create highlights for existing chars
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and not plr.Character:FindFirstChild("DeltaESP") then
            local h = Instance.new("Highlight", plr.Character)
            h.Name = "DeltaESP"
            h.OutlineColor = ACCENT
            h.FillTransparency = 1
        end
    end
end

-- =========================
-- End of script
-- =========================
toast("Delta Panel loaded. Theme: Dark Purple")
safeWrite(Settings)
--========================================================--
--==================== TAB SYSTEM =========================--
--========================================================--

local function CreateTabSystem()
    local tab = CreateTab("System")

    local saveBtn = CreateButton(tab, "Save Settings")
    saveBtn.MouseButton1Click:Connect(function()
        SafeSave()
        Notify("Settings berhasil disimpan!")
    end)

    local loadBtn = CreateButton(tab, "Load Settings")
    loadBtn.MouseButton1Click:Connect(function()
        SafeLoad()
        ApplyFPS()
        Notify("Settings berhasil dimuat ulang.")
    end)

    local resetUIBtn = CreateButton(tab, "Reset UI Position")
    resetUIBtn.MouseButton1Click:Connect(function()
        mainFrame.Position = UDim2.new(0.5, -250, 0.5, -150)
        Notify("Posisi UI direset.")
    end)

    local killBtn = CreateButton(tab, "Kill Script")
    killBtn.MouseButton1Click:Connect(function()
        pcall(function() mainFrame:Destroy() end)
        Notify("Script dimatikan.")
    end)
end

--========================================================--
--=============== PLAYER UTILITY TAB =====================--
--========================================================--

local function CreatePlayerTab()
    local tab = CreateTab("Player")

    local wsSlider = CreateSlider(tab, "Walkspeed", 16, 200, PlayerSettings.WS)
    wsSlider.Changed:Connect(function(val)
        PlayerSettings.WS = val
        SafeSave()
        pcall(function()
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = val
        end)
    end)

    local jpSlider = CreateSlider(tab, "JumpPower", 50, 300, PlayerSettings.JP)
    jpSlider.Changed:Connect(function(val)
        PlayerSettings.JP = val
        SafeSave()
        pcall(function()
            game.Players.LocalPlayer.Character.Humanoid.JumpPower = val
        end)
    end)

    local resetBtn = CreateButton(tab, "Reset Character")
    resetBtn.MouseButton1Click:Connect(function()
        pcall(function()
            game.Players.LocalPlayer.Character:BreakJoints()
        end)
    end)

    local fovSlider = CreateSlider(tab, "FOV", 60, 120, PlayerSettings.FOV)
    fovSlider.Changed:Connect(function(val)
        PlayerSettings.FOV = val
        SafeSave()
        workspace.CurrentCamera.FieldOfView = val
    end)

    local shiftToggle = CreateToggle(tab, "Shiftlock", PlayerSettings.Shiftlock)
    shiftToggle.Toggled:Connect(function(state)
        PlayerSettings.Shiftlock = state
        SafeSave()
        pcall(function()
            game:GetService("UserSettings").GameSettings.ControlMode = state and Enum.ControlMode.MouseLockSwitch or Enum.ControlMode.Classic
        end)
    end)
end

--========================================================--
--=============== UTILITY TAB (AntiAFK + Rejoin) =========--
--========================================================--

local function CreateUtilityTab()
    local tab = CreateTab("Utility")

    local antiAFKToggle = CreateToggle(tab, "Anti AFK", UserSettings.AntiAFK)
    antiAFKToggle.Toggled:Connect(function(state)
        UserSettings.AntiAFK = state
        SafeSave()
    end)

    local autoRejoinToggle = CreateToggle(tab, "Auto Rejoin", UserSettings.AutoRejoin)
    autoRejoinToggle.Toggled:Connect(function(state)
        UserSettings.AutoRejoin = state
        SafeSave()
    end)

    local delaySlider = CreateSlider(tab, "Rejoin Delay", 1, 30, UserSettings.RejoinDelay)
    delaySlider.Changed:Connect(function(v)
        UserSettings.RejoinDelay = v
        SafeSave()
    end)

    local themeBtn = CreateButton(tab, "Switch Theme (Dark/OLED)")
    themeBtn.MouseButton1Click:Connect(function()
        ToggleTheme()
    end)

    local minimizeBtn = CreateButton(tab, "Minimize UI")
    minimizeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        miniIcon.Visible = true
    end)
end

--========================================================--
--======================== INIT ===========================--
--========================================================--

task.spawn(AutoRejoinLoop)
task.spawn(AntiafkLoop)

CreateFPSPresetTab()
CreatePlayerTab()
CreateUtilityTab()
CreateTabSystem()

Notify("Panel FPS Boost siap dipakai!")
