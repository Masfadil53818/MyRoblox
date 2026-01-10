--// CornelloTeam Utility Hub
--// UI Purple Transparent | Auto Reconnect | Anti AFK | Webhook
--// Executor Friendly

if getgenv().CornelloLoaded then return end
getgenv().CornelloLoaded = true

-- SERVICES
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer

-- EXECUTOR CHECK
local queue = queue_on_teleport or syn and syn.queue_on_teleport
local request = http_request or request or syn and syn.request

-- CONFIG
getgenv().CornelloConfig = getgenv().CornelloConfig or {
	AntiAFK = false,
	AutoReconnect = true,
	Webhook = "",
	AutoExecute = true
}

-- SAVE CONFIG
local function SaveConfig()
	writefile("cornello_config.json", HttpService:JSONEncode(getgenv().CornelloConfig))
end

-- LOAD CONFIG
pcall(function()
	if isfile("cornello_config.json") then
		getgenv().CornelloConfig = HttpService:JSONDecode(readfile("cornello_config.json"))
	end
end)

-- LOAD UI LIB
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

-- UI WINDOW
local Window = OrionLib:MakeWindow({
	Name = "Cornello Utility Hub",
	HidePremium = true,
	SaveConfig = false,
	ConfigFolder = "Cornello",
	IntroEnabled = false
})

-- ICON BUTTON
OrionLib:MakeNotification({
	Name = "Loaded",
	Content = "Cornello Utility berhasil dimuat",
	Image = "rbxassetid://4483345998",
	Time = 4
})

-- TABS
local UtilityTab = Window:MakeTab({Name = "Utility", Icon = "rbxassetid://4483345998"})
local ServerTab = Window:MakeTab({Name = "Server", Icon = "rbxassetid://4483345998"})
local WebhookTab = Window:MakeTab({Name = "Webhook", Icon = "rbxassetid://4483345998"})

-- ======================
-- ANTI AFK
-- ======================
task.spawn(function()
	while task.wait(600) do -- 10 menit
		if getgenv().CornelloConfig.AntiAFK then
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end
	end
end)

UtilityTab:AddToggle({
	Name = "Anti AFK (10 Menit)",
	Default = getgenv().CornelloConfig.AntiAFK,
	Callback = function(v)
		getgenv().CornelloConfig.AntiAFK = v
		SaveConfig()
	end
})

-- ======================
-- AUTO EXECUTE
-- ======================
UtilityTab:AddToggle({
	Name = "Auto Execute After Rejoin",
	Default = getgenv().CornelloConfig.AutoExecute,
	Callback = function(v)
		getgenv().CornelloConfig.AutoExecute = v
		SaveConfig()
	end
})

-- ======================
-- AUTO RECONNECT
-- ======================
ServerTab:AddToggle({
	Name = "Auto Reconnect",
	Default = getgenv().CornelloConfig.AutoReconnect,
	Callback = function(v)
		getgenv().CornelloConfig.AutoReconnect = v
		SaveConfig()
	end
})

-- DISCONNECT DETECT
LP.OnTeleport:Connect(function(state)
	if state == Enum.TeleportState.Failed and getgenv().CornelloConfig.AutoReconnect then
		task.wait(3)
		TeleportService:Teleport(game.PlaceId, LP)
	end
end)

-- ======================
-- WEBHOOK
-- ======================
WebhookTab:AddTextbox({
	Name = "Discord Webhook URL",
	Default = getgenv().CornelloConfig.Webhook,
	TextDisappear = false,
	Callback = function(v)
		getgenv().CornelloConfig.Webhook = v
		SaveConfig()
	end
})

local function SendWebhook(title, desc)
	if getgenv().CornelloConfig.Webhook == "" or not request then return end

	request({
		Url = getgenv().CornelloConfig.Webhook,
		Method = "POST",
		Headers = {["Content-Type"] = "application/json"},
		Body = HttpService:JSONEncode({
			embeds = {{
				title = title,
				description = desc,
				color = 10494192 -- purple
			}}
		})
	})
end

WebhookTab:AddButton({
	Name = "Test Webhook",
	Callback = function()
		SendWebhook("Webhook Test", "Webhook Cornello Utility aktif.")
	end
})

-- ======================
-- QUEUE ON TELEPORT
-- ======================
if queue and getgenv().CornelloConfig.AutoExecute then
	queue([[
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Masfadil53818/MyRoblox/refs/heads/main/crnloader"))()
	]])
end

-- ======================
-- PLAYER LEAVE
-- ======================
game:GetService("Players").PlayerRemoving:Connect(function(p)
	if p == LP then
		SendWebhook("Disconnect", "Player terdisconnect dari server.")
	end
end)

-- FINAL
OrionLib:Init()
