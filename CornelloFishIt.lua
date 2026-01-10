--// Auto Reconnect & Anti AFK Script
--// Made to survive Roblox being Roblox

if not writefile then
    warn("Executor kamu cupu, ga support writefile.")
end

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- CONFIG FILE
local CONFIG_FILE = "AutoReconnectConfig.json"
local reconnectCount = 0
local disconnectCount = 0

-- DEFAULT CONFIG
local Config = {
    AutoReconnect = true,
    AntiAFK = true,
    WebhookEnabled = true,
    WebhookURL = "",
    AutoSave = true
}

-- LOAD CONFIG
pcall(function()
    if isfile(CONFIG_FILE) then
        Config = HttpService:JSONDecode(readfile(CONFIG_FILE))
    end
end)

local function SaveConfig()
    if Config.AutoSave then
        writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
    end
end

-- TIME FORMAT
local function GetTime()
    local t = os.date("*t")
    return os.date("%d-%m-%Y"), os.date("%H:%M:%S")
end

-- WEBHOOK SEND
local function SendWebhook(title, fields)
    if not Config.WebhookEnabled or Config.WebhookURL == "" then return end

    local date, time = GetTime()

    local embed = {
        title = title,
        color = 65280,
        fields = fields,
        footer = {
            text = date.." | "..time
        }
    }

    local data = {
        embeds = {embed}
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

-- ANTI AFK
if Config.AntiAFK then
    LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

-- DISCONNECT DETECT
game:GetService("GuiService").ErrorMessageChanged:Connect(function(msg)
    disconnectCount += 1
    local date, time = GetTime()

    SendWebhook("Disconnect Alert", {
        {name="Date", value="```"..date.."```", inline=false},
        {name="Time", value="```"..time.."```", inline=false},
        {name="Reason", value="```"..msg.."```", inline=false},
        {name="Leaved", value="```"..disconnectCount.."```", inline=false}
    })

    if Config.AutoReconnect then
        task.wait(5)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end)

-- REJOIN SUCCESS
Players.PlayerAdded:Connect(function(plr)
    if plr == LocalPlayer then
        reconnectCount += 1
        local date, time = GetTime()

        SendWebhook("Reconnect Successfully", {
            {name="Date", value="```"..date.."```", inline=false},
            {name="Time", value="```"..time.."```", inline=false},
            {name="Connect", value="```"..reconnectCount.."```", inline=false}
        })
    end
end)

-- AUTO EXECUTE AFTER TELEPORT
queue_on_teleport([[
    loadstring(game:HttpGet("PASTE_YOUR_RAW_SCRIPT_URL_HERE"))()
]])

-- UI
local ScreenGui = Instance.new("ScreenGui", CoreGui)
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0,300,0,320)
Frame.Position = UDim2.new(0.5,-150,0.5,-160)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.Active = true
Frame.Draggable = true

local UIList = Instance.new("UIListLayout", Frame)
UIList.Padding = UDim.new(0,8)

local function Toggle(text, callback)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(1,-10,0,40)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.new(1,1,1)

    btn.MouseButton1Click:Connect(function()
        callback()
        SaveConfig()
    end)
end

Toggle("Auto Reconnect: "..tostring(Config.AutoReconnect), function()
    Config.AutoReconnect = not Config.AutoReconnect
end)

Toggle("Anti AFK: "..tostring(Config.AntiAFK), function()
    Config.AntiAFK = not Config.AntiAFK
end)

Toggle("Webhook: "..tostring(Config.WebhookEnabled), function()
    Config.WebhookEnabled = not Config.WebhookEnabled
end)

Toggle("Test Webhook", function()
    SendWebhook("Webhook Test", {
        {name="Status", value="```Webhook Aktif```", inline=false}
    })
end)

print("Auto Reconnect Script Loaded. Tinggal main, biar script yang stress.")