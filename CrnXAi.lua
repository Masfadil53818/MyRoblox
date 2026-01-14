--// CornelloTeam Auto Reconnect & Anti AFK
--// Cyberpunk UI Edition + Tab System
--// v0.0.3 [BETA]

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

--==============================--
-- UI ROOT
--==============================--
local GUI = Instance.new("ScreenGui", CoreGui)
GUI.Name = "CornelloTeamCyberUI"
GUI.ResetOnSpawn = false

local Main = Instance.new("Frame", GUI)
Main.Size = UDim2.fromScale(0.36,0.46)
Main.Position = UDim2.fromScale(0.5,0.5)
Main.AnchorPoint = Vector2.new(0.5,0.5)
Main.BackgroundColor3 = Color3.fromRGB(14,14,20)
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,18)

-- Stroke
local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(0,255,255)
Stroke.Thickness = 2
Stroke.Transparency = 0.25

--==============================--
-- HEADER
--==============================--
local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1,0,0,54)
Header.BackgroundTransparency = 1

-- LOGO
local Logo = Instance.new("TextLabel", Header)
Logo.Size = UDim2.new(0,40,0,40)
Logo.Position = UDim2.new(0,14,0.5,-20)
Logo.Text = "CT"
Logo.Font = Enum.Font.GothamBlack
Logo.TextSize = 16
Logo.TextColor3 = Color3.fromRGB(0,255,255)
Logo.BackgroundColor3 = Color3.fromRGB(22,22,32)
Logo.TextXAlignment = Enum.TextXAlignment.Center
Instance.new("UICorner", Logo).CornerRadius = UDim.new(1,0)

-- TITLE
local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1,-160,1,0)
Title.Position = UDim2.new(0,70,0,0)
Title.Text = "CornelloTeam  "..VERSION
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextColor3 = Color3.fromRGB(220,220,255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1

-- iOS BUTTON
local function IOS(color, x)
    local b = Instance.new("TextButton", Header)
    b.Size = UDim2.new(0,14,0,14)
    b.Position = UDim2.new(1,x,0.5,-7)
    b.BackgroundColor3 = color
    b.Text = ""
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(1,0)
    return b
end

local Close = IOS(Color3.fromRGB(255,90,90), -22)
local Minimize = IOS(Color3.fromRGB(255,200,60), -44)

--==============================--
-- TAB BAR
--==============================--
local TabBar = Instance.new("Frame", Main)
TabBar.Position = UDim2.new(0,0,0,54)
TabBar.Size = UDim2.new(1,0,0,38)
TabBar.BackgroundTransparency = 1

local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0,8)
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

--==============================--
-- CONTENT HOLDER
--==============================--
local Pages = {}

local function CreatePage(name)
    local page = Instance.new("ScrollingFrame", Main)
    page.Position = UDim2.new(0,0,0,92)
    page.Size = UDim2.new(1,0,1,-92)
    page.CanvasSize = UDim2.new(0,0,0,0)
    page.ScrollBarThickness = 4
    page.Visible = false
    page.BackgroundTransparency = 1

    local pad = Instance.new("UIPadding", page)
    pad.PaddingTop = UDim.new(0,10)
    pad.PaddingLeft = UDim.new(0,14)
    pad.PaddingRight = UDim.new(0,14)

    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0,12)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 20)
    end)

    Pages[name] = page
    return page
end

local function SwitchTab(name)
    for n,p in pairs(Pages) do
        p.Visible = (n == name)
    end
end

local function CreateTab(name)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0,90,0,28)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(0,255,255)
    btn.BackgroundColor3 = Color3.fromRGB(22,22,32)
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,12)

    btn.MouseButton1Click:Connect(function()
        SwitchTab(name)
    end)
end

--==============================--
-- CREATE TABS & PAGES
--==============================--
CreateTab("Main")
CreateTab("Reconnect")
CreateTab("Config")

local MainPage = CreatePage("Main")
local ReconnectPage = CreatePage("Reconnect")
local ConfigPage = CreatePage("Config")

-- DEFAULT TAB
SwitchTab("Main")

--==============================--
-- TOGGLE FUNCTION
--==============================--
local function CreateToggle(parent,text,flag)
    local Holder = Instance.new("Frame", parent)
    Holder.Size = UDim2.new(1,0,0,46)
    Holder.BackgroundColor3 = Color3.fromRGB(22,22,32)
    Instance.new("UICorner", Holder).CornerRadius = UDim.new(0,14)

    local Label = Instance.new("TextLabel", Holder)
    Label.Size = UDim2.new(0.7,0,1,0)
    Label.Position = UDim2.new(0,16,0,0)
    Label.Text = text
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextColor3 = Color3.new(1,1,1)
    Label.BackgroundTransparency = 1

    local Toggle = Instance.new("Frame", Holder)
    Toggle.Size = UDim2.new(0,48,0,22)
    Toggle.Position = UDim2.new(1,-62,0.5,-11)
    Toggle.BackgroundColor3 = Config[flag] and Color3.fromRGB(0,255,255) or Color3.fromRGB(80,80,80)
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(1,0)

    local Dot = Instance.new("Frame", Toggle)
    Dot.Size = UDim2.new(0,18,0,18)
    Dot.Position = Config[flag] and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,3,0.5,-9)
    Dot.BackgroundColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1,0)

    Holder.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            Config[flag] = not Config[flag]
            SaveConfig()
            TweenService:Create(Toggle,TweenInfo.new(0.25),{
                BackgroundColor3 = Config[flag] and Color3.fromRGB(0,255,255) or Color3.fromRGB(80,80,80)
            }):Play()
            TweenService:Create(Dot,TweenInfo.new(0.25),{
                Position = Config[flag] and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,3,0.5,-9)
            }):Play()
        end
    end)
end

--==============================--
-- CONTENT
--==============================--
CreateToggle(MainPage,"Anti AFK","AntiAFK")
CreateToggle(ReconnectPage,"Auto Reconnect","AutoReconnect")
CreateToggle(ConfigPage,"Auto Save Config","AutoSave")
CreateToggle(ConfigPage,"Auto Execute After TP","AutoExecute")

--==============================--
-- BUTTON ACTION
--==============================--
local minimized = false
Minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(Main,TweenInfo.new(0.3),{
        Size = minimized and UDim2.fromScale(0.36,0.1) or UDim2.fromScale(0.36,0.46)
    }):Play()
end)

Close.MouseButton1Click:Connect(function()
    GUI:Destroy()
end)

print("CornelloTeam Cyberpunk UI Loaded | "..VERSION)
