--// CornelloTeam - Disconnect Notify v1.0
--// Mobile Friendly | AutoReconnect | AutoExecute | Multi Webhook

if getgenv().CornelloLoaded then return end
getgenv().CornelloLoaded = true

-- SERVICES
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- FILE
local CONFIG_FILE = "CornelloTeam_Disconnect.json"

-- DEFAULT CONFIG
local Config = {
	Enabled = true,
	DiscordID = "",
	Webhooks = {},
	AutoReconnect = true
}

-- FILE SYSTEM
local function SaveConfig()
	if writefile then
		writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
	end
end

local function LoadConfig()
	if readfile and isfile and isfile(CONFIG_FILE) then
		local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
		for k,v in pairs(data) do
			Config[k] = v
		end
	end
end

LoadConfig()

-- WEBHOOK SEND
local function SendWebhook(title, desc)
	for _,url in pairs(Config.Webhooks) do
		pcall(function()
			local data = {
				embeds = {{
					title = title,
					description = desc,
					color = 0x8A2BE2,
					footer = { text = "CornelloTeam" },
					timestamp = DateTime.now():ToIsoDate()
				}}
			}
			request({
				Url = url,
				Method = "POST",
				Headers = {["Content-Type"] = "application/json"},
				Body = HttpService:JSONEncode(data)
			})
		end)
	end
end

-- DISCONNECT DETECT
game:GetService("CoreGui").RobloxPromptGui.promptOverlay.DescendantAdded:Connect(function(obj)
	if not Config.Enabled then return end
	if obj.Name == "ErrorPrompt" then
		local t = os.date("*t")
		SendWebhook(
			"Info Disconnect",
			"Halo <@"..Config.DiscordID..">\n"
			.."Player: ```"..LocalPlayer.Name.."```\n"
			.."Time: ```"..string.format("%02d:%02d:%02d",t.hour,t.min,t.sec).."```\n"
			.."Day: ```"..t.day.."/"..t.month.."/"..t.year.."```\n\n"
			.."Akun anda telah disconnect"
		)

		if Config.AutoReconnect then
			task.wait(5)
			TeleportService:Teleport(game.PlaceId, LocalPlayer)
		end
	end
end)

-- UI
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "CornelloUI"
ScreenGui.ResetOnSpawn = false

-- FLOAT ICON
local Icon = Instance.new("ImageButton", ScreenGui)
Icon.Size = UDim2.fromOffset(50,50)
Icon.Position = UDim2.fromScale(0.05,0.5)
Icon.Image = "rbxassetid://7072719338"
Icon.BackgroundTransparency = 1
Icon.Active = true
Icon.Draggable = true

-- MAIN FRAME
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.fromOffset(420,260)
Main.Position = UDim2.fromScale(0.5,0.5)
Main.AnchorPoint = Vector2.new(0.5,0.5)
Main.BackgroundColor3 = Color3.fromRGB(20,20,30)
Main.Visible = false
Main.Active = true
Main.Draggable = true

local Corner = Instance.new("UICorner", Main)
Corner.CornerRadius = UDim.new(0,16)

-- TITLE
local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1,0,0,40)
Title.Text = "CornelloTeam | Disconnect Notify"
Title.TextColor3 = Color3.fromRGB(200,160,255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.BackgroundTransparency = 1
Title.TextWrapped = true
Title.TextXAlignment = Enum.TextXAlignment.Center
Title.TextYAlignment = Enum.TextYAlignment.Center

-- TOGGLE BUTTON
local Toggle = Instance.new("TextButton", Main)
Toggle.Size = UDim2.fromOffset(160,36)
Toggle.Position = UDim2.fromOffset(20,60)
Toggle.Text = "Notify : ON"
Toggle.Font = Enum.Font.Gotham
Toggle.TextSize = 14
Toggle.TextWrapped = true
Toggle.BackgroundColor3 = Color3.fromRGB(80,40,120)
Toggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", Toggle)

Toggle.MouseButton1Click:Connect(function()
	Config.Enabled = not Config.Enabled
	Toggle.Text = "Notify : "..(Config.Enabled and "ON" or "OFF")
	SaveConfig()
end)

-- TEST WEBHOOK
local Test = Toggle:Clone()
Test.Position = UDim2.fromOffset(20,110)
Test.Text = "Test Webhook"
Test.Parent = Main

Test.MouseButton1Click:Connect(function()
	SendWebhook("Test Webhook","Webhook berhasil di test ✅")
end)

-- ICON CLICK
Icon.MouseButton1Click:Connect(function()
	Main.Visible = not Main.Visible
end)

-- LOAD NOTIF
SendWebhook("Script Loaded","CornelloTeam berhasil dijalankan di Roblox")

SaveConfig()