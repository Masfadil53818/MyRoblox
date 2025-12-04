-- SUPER FINAL: DARK PURPLE DELTA-LIKE PANEL (ALL FEATURES)
-- Requires executor with: writefile, readfile, isfile, request, loadstring (optional)
-- Tested logic only; adjust asset ids if needed

-- =========================
-- Services & Utilities
-- =========================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

-- Fallback safety for script run in Studio (avoid errors)
if not LocalPlayer then return end

-- =========================
-- Settings & Save
-- =========================
local SAVE_FILE = "delta_super_settings.json"
local Settings = {
    autoExecute = false,
    antiAFK = false,
    autoRejoin = false,
    webhookURL = "",
    userID = "",
    espEnabled = false,
    walkSpeed = 16,
    jumpPower = 50
}

local function safeWrite(data)
    if writefile then
        pcall(function()
            writefile(SAVE_FILE, HttpService:JSONEncode(data))
        end)
    end
end

local function safeRead()
    if isfile then
        if isfile(SAVE_FILE) then
            local ok, ret = pcall(function() return HttpService:JSONDecode(readfile(SAVE_FILE)) end)
            if ok and type(ret) == "table" then
                for k,v in pairs(ret) do Settings[k] = v end
            end
        end
    end
end

safeRead()

-- Autosave throttle
local autosaveTimer = 0
task.spawn(function()
    while true do
        task.wait(10)
        autosaveTimer = autosaveTimer + 10
        if autosaveTimer >= 30 then
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
