--// CornelloTeam Auto Reconnect & Anti AFK
--// Cyberpunk UI Edition + Tab System + Webhook + AutoExecute FIX
--// v0.0.3 [BETA] - FULL FIXED

--==============================--
-- GITHUB SOURCE
--==============================--
local RAW_SCRIPT_URL = "https://raw.githubusercontent.com/USERNAME/REPO/main/script.lua"
local VERSION_URL    = "https://raw.githubusercontent.com/USERNAME/REPO/main/version.txt"

--==============================--
-- VERSION
--==============================--
local VERSION = "v0.0.3 [BETA]"

--==============================--
-- SERVICES
--==============================--
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

--==============================--
-- CONFIG
--==============================--
local CONFIG_FILE = "AutoReconnectConfig.json"

local Config = {
    AutoReconnect = true,
    AntiAFK = true,
    WebhookEnabled = false,
    WebhookURL = "",
    AutoSave = true,
    AutoExecute = true
}

pcall(function()
    if isfile and isfile(CONFIG_FILE) then
        Config = HttpService:JSONDecode(readfile(CONFIG_FILE))
    end
end)

local function SaveConfig()
    if Config.AutoSave and writefile then
        writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
    end
end

--==============================--
-- AUTO EXECUTE AFTER TELEPORT (FIX)
--==============================--
pcall(function()
    if queue_on_teleport and Config.AutoExecute then
        queue_on_teleport([[
            task.wait(2)
            loadstring(game:HttpGet("]] .. RAW_SCRIPT_URL .. [["))()
        ]])
    end
end)

--==============================--
-- VERSION CHECK AUTO UPDATE
--==============================--
task.spawn(function()
    if not Config.AutoExecute then return end
    if not game:IsLoaded() then game.Loaded:Wait() end

    pcall(function()
        local onlineVersion = game:HttpGet(VERSION_URL)
        if onlineVersion and onlineVersion ~= VERSION then
            loadstring(game:HttpGet(RAW_SCRIPT_URL))()
        end
    end)
end)

--==============================--
-- WEBHOOK SYSTEM
--==============================--
local function SendWebhook(title, desc, color)
    if not Config.WebhookEnabled or Config.WebhookURL == "" then return end
    pcall(function()
        request({
            Url = Config.WebhookURL,
            Method = "POST",
            Headers = {["Content-Type"]="application/json"},
            Body = HttpService:JSONEncode({
                embeds = {{
                    title = title,
                    description = desc,
                    color = color or 65535,
                    footer = {text="CornelloTeam | "..VERSION}
                }}
            })
        })
    end)
end

--==============================--
-- ANTI AFK
--==============================--
if Config.AntiAFK then
    LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

--==============================--
-- DISCONNECT / KICK DETECT
--==============================--
GuiService.ErrorMessageChanged:Connect(function(msg)
    SendWebhook(
        "❌ Disconnected / Kicked",
        "**User:** "..LocalPlayer.Name.."\n**Reason:** "..msg,
        16711680
    )

    if Config.AutoReconnect then
        task.wait(5)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end)

--==============================--
-- TELEPORT FAILED DETECT
--==============================--
TeleportService.TeleportInitFailed:Connect(function(player, result)
    if player ~= LocalPlayer then return end
    SendWebhook(
        "⚠️ Teleport Failed",
        "**Reason:** ".. tostring(result),
        16744192
    )
    task.wait(3)
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

--==============================--
-- REJOIN SUCCESS DETECT
--==============================--
LocalPlayer.CharacterAdded:Connect(function()
    SendWebhook(
        "✅ Rejoined Successfully",
        "**User:** "..LocalPlayer.Name.."\n**Status:** Connected",
        65280
    )
end)

--==============================--
-- UI ROOT (FIX UI KOSONG)
--==============================--
local GUI = Instance.new("ScreenGui")
GUI.Name = "CornelloTeamCyberUI"
GUI.ResetOnSpawn = false
GUI.DisplayOrder = 999999
GUI.Enabled = true

pcall(function()
    GUI.Parent = CoreGui
end)

--==============================--
-- FLOAT ICON
--==============================--
local MiniIcon = Instance.new("TextButton", GUI)
MiniIcon.Size = UDim2.new(0,48,0,48)
MiniIcon.Position = UDim2.new(0.02,0,0.4,0)
MiniIcon.Text = "CT"
MiniIcon.Font = Enum.Font.GothamBlack
MiniIcon.TextColor3 = Color3.fromRGB(0,255,255)
MiniIcon.BackgroundColor3 = Color3.fromRGB(20,20,30)
MiniIcon.Visible = false
MiniIcon.Active = true
MiniIcon.Draggable = true
Instance.new("UICorner", MiniIcon).CornerRadius = UDim.new(1,0)

--==============================--
-- MAIN UI
--==============================--
local Main = Instance.new("Frame", GUI)
Main.Size = UDim2.fromScale(0.36,0.46)
Main.Position = UDim2.fromScale(0.5,0.5)
Main.AnchorPoint = Vector2.new(0.5,0.5)
Main.BackgroundColor3 = Color3.fromRGB(14,14,20)
Main.Active = true
Main.Draggable = true
Main.Visible = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,18)

--==============================--
-- HEADER
--==============================--
local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1,0,0,54)
Header.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1,-160,1,0)
Title.Position = UDim2.new(0,70,0,0)
Title.Text = "CornelloTeam "..VERSION
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextColor3 = Color3.fromRGB(220,220,255)
Title.BackgroundTransparency = 1

local function IOS(color, x)
    local b = Instance.new("TextButton", Header)
    b.Size = UDim2.new(0,14,0,14)
    b.Position = UDim2.new(1,x,0.5,-7)
    b.BackgroundColor3 = color
    b.Text = ""
    Instance.new("UICorner", b).CornerRadius = UDim.new(1,0)
    return b
end

local Close = IOS(Color3.fromRGB(255,90,90), -22)
local Minimize = IOS(Color3.fromRGB(255,200,60), -44)

--==============================--
-- BUTTON ACTION
--==============================--
Minimize.MouseButton1Click:Connect(function()
    Main.Visible = false
    MiniIcon.Visible = true
end)

MiniIcon.MouseButton1Click:Connect(function()
    Main.Visible = true
    MiniIcon.Visible = false
end)

Close.MouseButton1Click:Connect(function()
    GUI:Destroy()
end)

print("✅ CornelloTeam Cyberpunk UI Loaded | "..VERSION)
