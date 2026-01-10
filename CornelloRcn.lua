--// CornelloTeam Auto Reconnect & Anti AFK
--// UI Scrollable + Mobile Friendly
--// v0.0.1 [BETA]

--==============================--
-- VERSION
--==============================--
local VERSION = "v0.0.1 [BETA]"
pcall(function()
    if isfile and isfile("version.txt") then
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
-- CORE SYSTEM
--==============================--
if Config.AntiAFK then
    LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

GuiService.ErrorMessageChanged:Connect(function()
    if Config.AutoReconnect then
        task.wait(5)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end)

if Config.AutoExecute and queue_on_teleport then
    queue_on_teleport([[
        loadstring(game:HttpGet("PASTE_RAW_URL_DISINI"))()
    ]])
end

--==============================--
-- UI ROOT
--==============================--
local GUI = Instance.new("ScreenGui")
GUI.Name = "CornelloTeamUI"
GUI.ResetOnSpawn = false
GUI.Parent = CoreGui

local Main = Instance.new("Frame", GUI)
Main.Size = UDim2.fromScale(0.35,0.45)
Main.Position = UDim2.fromScale(0.5,0.5)
Main.AnchorPoint = Vector2.new(0.5,0.5)
Main.BackgroundColor3 = Color3.fromRGB(18,18,23)
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = false
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,16)

--==============================--
-- HEADER
--==============================--
local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1,0,0,46)
Header.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1,-50,1,0)
Title.Position = UDim2.new(0,16,0,0)
Title.Text = "CornelloTeam  "..VERSION
Title.TextColor3 = Color3.fromRGB(200,200,255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14

local Minimize = Instance.new("TextButton", Header)
Minimize.Size = UDim2.new(0,32,0,32)
Minimize.Position = UDim2.new(1,-38,0.5,-16)
Minimize.Text = "—"
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 16
Minimize.BackgroundColor3 = Color3.fromRGB(50,50,60)
Minimize.TextColor3 = Color3.new(1,1,1)
Minimize.AutoButtonColor = false
Instance.new("UICorner", Minimize).CornerRadius = UDim.new(1,0)

--==============================--
-- SCROLL BODY (FIXED)
--==============================--
local Body = Instance.new("ScrollingFrame", Main)
Body.Position = UDim2.new(0,0,0,50)
Body.Size = UDim2.new(1,0,1,-50)
Body.CanvasSize = UDim2.new(0,0,0,0)
Body.ScrollBarImageTransparency = 0.4
Body.ScrollBarThickness = 5
Body.ScrollingEnabled = true
Body.Active = true
Body.BackgroundTransparency = 1
Body.BorderSizePixel = 0
Body.AutomaticCanvasSize = Enum.AutomaticSize.None
Body.ScrollingDirection = Enum.ScrollingDirection.Y
Body.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable

local Padding = Instance.new("UIPadding", Body)
Padding.PaddingLeft = UDim.new(0,10)
Padding.PaddingRight = UDim.new(0,10)
Padding.PaddingTop = UDim.new(0,10)
Padding.PaddingBottom = UDim.new(0,10)

local Layout = Instance.new("UIListLayout", Body)
Layout.Padding = UDim.new(0,10)

Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Body.CanvasSize = UDim2.new(0,0,0,Layout.AbsoluteContentSize.Y + 20)
end)

--==============================--
-- TOGGLE CREATOR
--==============================--
local function CreateToggle(text, flag)
    local Holder = Instance.new("Frame", Body)
    Holder.Size = UDim2.new(1,0,0,45)
    Holder.BackgroundColor3 = Color3.fromRGB(32,32,42)
    Holder.Active = false
    Instance.new("UICorner", Holder).CornerRadius = UDim.new(0,12)

    local Label = Instance.new("TextLabel", Holder)
    Label.Size = UDim2.new(0.7,0,1,0)
    Label.Position = UDim2.new(0,14,0,0)
    Label.Text = text
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextColor3 = Color3.new(1,1,1)
    Label.BackgroundTransparency = 1

    local Toggle = Instance.new("Frame", Holder)
    Toggle.Size = UDim2.new(0,48,0,24)
    Toggle.Position = UDim2.new(1,-60,0.5,-12)
    Toggle.BackgroundColor3 = Config[flag] and Color3.fromRGB(0,170,255) or Color3.fromRGB(70,70,70)
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(1,0)

    local Dot = Instance.new("Frame", Toggle)
    Dot.Size = UDim2.new(0,18,0,18)
    Dot.Position = Config[flag] and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,3,0.5,-9)
    Dot.BackgroundColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1,0)

    local function Update()
        TweenService:Create(Toggle,TweenInfo.new(0.25),{
            BackgroundColor3 = Config[flag] and Color3.fromRGB(0,170,255) or Color3.fromRGB(70,70,70)
        }):Play()
        TweenService:Create(Dot,TweenInfo.new(0.25),{
            Position = Config[flag] and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,3,0.5,-9)
        }):Play()
    end

    Holder.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            Config[flag] = not Config[flag]
            SaveConfig()
            Update()
        end
    end)
end

--==============================--
-- ELEMENTS
--==============================--
CreateToggle("Auto Reconnect", "AutoReconnect")
CreateToggle("Anti AFK", "AntiAFK")
CreateToggle("Webhook Enable", "WebhookEnabled")
CreateToggle("Auto Save Config", "AutoSave")
CreateToggle("Auto Execute After TP", "AutoExecute")

local WebhookBox = Instance.new("TextBox", Body)
WebhookBox.Size = UDim2.new(1,0,0,40)
WebhookBox.Text = Config.WebhookURL
WebhookBox.PlaceholderText = "Webhook URL"
WebhookBox.TextColor3 = Color3.new(1,1,1)
WebhookBox.BackgroundColor3 = Color3.fromRGB(28,28,38)
WebhookBox.ClearTextOnFocus = false
WebhookBox.Font = Enum.Font.Gotham
WebhookBox.TextSize = 13
Instance.new("UICorner", WebhookBox).CornerRadius = UDim.new(0,10)

WebhookBox.FocusLost:Connect(function()
    Config.WebhookURL = WebhookBox.Text
    SaveConfig()
end)

--==============================--
-- MINIMIZE
--==============================--
local minimized = false
Minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(Main,TweenInfo.new(0.3,Enum.EasingStyle.Quad),{
        Size = minimized and UDim2.fromScale(0.35,0.08) or UDim2.fromScale(0.35,0.45)
    }):Play()
end)

print("CornelloTeam UI Loaded | "..VERSION)