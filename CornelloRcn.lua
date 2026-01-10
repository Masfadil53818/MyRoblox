--// CornelloTeam Auto Reconnect & Anti AFK
--// Version Loader + UI Revamp
--// Made to survive Roblox being Roblox

--==============================--
-- VERSION
--==============================--
local VERSION = "v0.0.1 [BETA]"
pcall(function()
    if isfile("version.txt") then
        VERSION = readfile("version.txt")
    end
end)

--==============================--
-- SERVICES
--==============================--
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
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
    if isfile(CONFIG_FILE) then
        Config = HttpService:JSONDecode(readfile(CONFIG_FILE))
    end
end)

local function SaveConfig()
    if Config.AutoSave and writefile then
        writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
    end
end

--==============================--
-- UTIL
--==============================--
local function GetTime()
    return os.date("%d-%m-%Y"), os.date("%H:%M:%S")
end

local function SendWebhook(title, fields)
    if not Config.WebhookEnabled or Config.WebhookURL == "" then return end

    local date, time = GetTime()
    local data = {
        embeds = {{
            title = title,
            color = 5793266,
            fields = fields,
            footer = { text = date.." | "..time }
        }}
    }

    pcall(function()
        syn.request({
            Url = Config.WebhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
end

--==============================--
-- CORE SYSTEM
--==============================--
if Config.AntiAFK then
    LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

game:GetService("GuiService").ErrorMessageChanged:Connect(function(msg)
    SendWebhook("Disconnect Detected", {
        {name="Reason", value="```"..msg.."```"}
    })

    if Config.AutoReconnect then
        task.wait(5)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end)

if Config.AutoExecute then
    queue_on_teleport([[
        loadstring(game:HttpGet("PASTE_RAW_URL_DISINI"))()
    ]])
end

--==============================--
-- UI
--==============================--
local GUI = Instance.new("ScreenGui", CoreGui)
GUI.Name = "CornelloTeamUI"

local Main = Instance.new("Frame", GUI)
Main.Size = UDim2.fromScale(0.35,0.45)
Main.Position = UDim2.fromScale(0.5,0.5)
Main.AnchorPoint = Vector2.new(0.5,0.5)
Main.BackgroundColor3 = Color3.fromRGB(20,20,25)
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = true
Main.BackgroundTransparency = 0

Instance.new("UICorner", Main).CornerRadius = UDim.new(0,16)

-- HEADER
local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1,0,0,45)
Header.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1,-50,1,0)
Title.Position = UDim2.new(0,15,0,0)
Title.Text = "CornelloTeam  "..VERSION
Title.TextColor3 = Color3.fromRGB(200,200,255)
Title.TextXAlignment = Left
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14

local Minimize = Instance.new("TextButton", Header)
Minimize.Size = UDim2.new(0,30,0,30)
Minimize.Position = UDim2.new(1,-35,0.5,-15)
Minimize.Text = "—"
Minimize.BackgroundColor3 = Color3.fromRGB(50,50,60)
Minimize.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", Minimize).CornerRadius = UDim.new(1,0)

-- BODY
local Body = Instance.new("Frame", Main)
Body.Position = UDim2.new(0,0,0,50)
Body.Size = UDim2.new(1,0,1,-50)
Body.BackgroundTransparency = 1

local Layout = Instance.new("UIListLayout", Body)
Layout.Padding = UDim.new(0,10)

-- TOGGLE CREATOR
local function CreateToggle(name, flag)
    local Holder = Instance.new("Frame", Body)
    Holder.Size = UDim2.new(1,-20,0,45)
    Holder.BackgroundColor3 = Color3.fromRGB(35,35,45)
    Instance.new("UICorner", Holder).CornerRadius = UDim.new(0,12)

    local Label = Instance.new("TextLabel", Holder)
    Label.Size = UDim2.new(0.7,0,1,0)
    Label.Position = UDim2.new(0,15,0,0)
    Label.Text = name
    Label.TextColor3 = Color3.new(1,1,1)
    Label.BackgroundTransparency = 1
    Label.TextXAlignment = Left
    Label.Font = Enum.Font.Gotham

    local Toggle = Instance.new("Frame", Holder)
    Toggle.Size = UDim2.new(0,50,0,25)
    Toggle.Position = UDim2.new(1,-65,0.5,-12)
    Toggle.BackgroundColor3 = Config[flag] and Color3.fromRGB(0,170,255) or Color3.fromRGB(70,70,70)
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(1,0)

    local Dot = Instance.new("Frame", Toggle)
    Dot.Size = UDim2.new(0,20,0,20)
    Dot.Position = Config[flag] and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)
    Dot.BackgroundColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1,0)

    Holder.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            Config[flag] = not Config[flag]
            SaveConfig()

            TweenService:Create(Toggle,TweenInfo.new(0.25),{
                BackgroundColor3 = Config[flag] and Color3.fromRGB(0,170,255) or Color3.fromRGB(70,70,70)
            }):Play()

            TweenService:Create(Dot,TweenInfo.new(0.25),{
                Position = Config[flag] and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)
            }):Play()
        end
    end)
end

-- TOGGLES
CreateToggle("Auto Reconnect","AutoReconnect")
CreateToggle("Anti AFK","AntiAFK")
CreateToggle("Webhook","WebhookEnabled")
CreateToggle("Auto Save","AutoSave")
CreateToggle("Auto Execute","AutoExecute")

-- WEBHOOK INPUT
local WebhookBox = Instance.new("TextBox", Body)
WebhookBox.Size = UDim2.new(1,-20,0,40)
WebhookBox.PlaceholderText = "Webhook URL"
WebhookBox.Text = Config.WebhookURL
WebhookBox.BackgroundColor3 = Color3.fromRGB(30,30,40)
WebhookBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", WebhookBox).CornerRadius = UDim.new(0,10)

WebhookBox.FocusLost:Connect(function()
    Config.WebhookURL = WebhookBox.Text
    SaveConfig()
end)

-- MINIMIZE
local minimized = false
Minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(Main,TweenInfo.new(0.3),{
        Size = minimized and UDim2.fromScale(0.35,0.08) or UDim2.fromScale(0.35,0.45)
    }):Play()
end)

print("CornelloTeam Loaded | "..VERSION)
