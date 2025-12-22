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
	AutoReconnect = true,
	ReconnectCooldown = 10 -- seconds
}

local _lastReconnect = 0

-- FILE SYSTEM
local function SaveConfig()
	if type(writefile) == "function" then
		local ok,err = pcall(function()
			writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
		end)
		if not ok then
			warn("Cornello: SaveConfig failed: "..tostring(err))
		end
	end
end

local function LoadConfig()
	if type(readfile) == "function" and type(isfile) == "function" then
		local ok, exists = pcall(isfile, CONFIG_FILE)
		if ok and exists then
			local ok2, data = pcall(readfile, CONFIG_FILE)
			if ok2 and data then
				local ok3, decoded = pcall(HttpService.JSONDecode, HttpService, data)
				if ok3 and type(decoded) == "table" then
					for k,v in pairs(decoded) do
						Config[k] = v
					end
				end
			end
		end
	end
end

LoadConfig()

-- WEBHOOK SEND
-- Safe HTTP requester that attempts common executor request APIs
local function safeRequest(params)
	local wrappers = {
		function(p) if type(request) == "function" then return request(p) end end,
		function(p) if syn and type(syn.request) == "function" then return syn.request(p) end end,
		function(p) if http and type(http.request) == "function" then return http.request(p) end end,
		function(p) if type(http_request) == "function" then return http_request(p) end end
	}
	for _,fn in ipairs(wrappers) do
		local ok, res = pcall(fn, params)
		if ok and res then
			return true, res
		end
	end
	return false, "no http request available"
end

local function SendWebhook(title, desc)
	local embed = {
		title = title,
		description = desc,
		color = 0x8A2BE2,
		footer = { text = "CornelloTeam" },
		timestamp = DateTime.now():ToIsoDate()
	}
	local payload = { embeds = { embed } }
	for _,url in pairs(Config.Webhooks) do
		pcall(function()
			local ok, res = safeRequest({
				Url = url,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode(payload)
			})
			if not ok then
				warn("Cornello: webhook send failed: "..tostring(res))
			end
		end)
	end
end

-- DISCONNECT DETECT
do
	local overlay = nil
	pcall(function()
		overlay = game:GetService("CoreGui").RobloxPromptGui.promptOverlay
	end)
	if overlay then
		overlay.DescendantAdded:Connect(function(obj)
			if not Config.Enabled then return end
			if obj.Name == "ErrorPrompt" then
				local t = os.date("*t")
				-- try to find the error message text to decide if kicked
				local message = ""
				pcall(function()
					for _,d in pairs(obj:GetDescendants()) do
						if d:IsA("TextLabel") and d.Text and #d.Text > #message then
							message = d.Text
						end
					end
				end)

				SendWebhook(
					"Info Disconnect",
					"Halo <@"..(Config.DiscordID or "")..">\n"
					.."Player: ```"..(LocalPlayer.Name or "Unknown").."```\n"
					.."Time: ```"..string.format("%02d:%02d:%02d",t.hour,t.min,t.sec).."```\n"
					.."Day: ```"..t.day.."/"..t.month.."/"..t.year.."```\n\n"
					.."Pesan: ```"..(message or "-").."```\n\n"
					.."Akun anda telah disconnect"
				)

				if Config.AutoReconnect then
					local now = os.time()
					if now - _lastReconnect < (Config.ReconnectCooldown or 10) then
						return
					end
					-- if message indicates a kick, do not reconnect
					local lower = (message or ""):lower()
					if lower:find("kick") or lower:find("kicked") or lower:find("you have been kicked") then
						return
					end

					_lastReconnect = now
					task.spawn(function()
						task.wait(5)
						pcall(function()
							TeleportService:Teleport(game.PlaceId, LocalPlayer)
						end)
					end)
				end
			end
		end)
	end
end

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CornelloTeam"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- FLOAT ICON
local Icon = Instance.new("ImageButton")
Icon.Size = UDim2.fromOffset(56,56)
Icon.Position = UDim2.fromScale(0.06,0.5)
Icon.AnchorPoint = Vector2.new(0.5,0.5)
Icon.Image = "rbxassetid://7072719338"
Icon.BackgroundTransparency = 1
Icon.Active = true
Icon.Selectable = true
Icon.Draggable = true
Icon.Parent = ScreenGui

-- MAIN FRAME
local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(420,280)
Main.Position = UDim2.fromScale(0.5,0.5)
Main.AnchorPoint = Vector2.new(0.5,0.5)
Main.BackgroundColor3 = Color3.fromRGB(18,12,28)
Main.BackgroundTransparency = 0.05
Main.Visible = false
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner", Main)
Corner.CornerRadius = UDim.new(0,16)

-- TITLE
local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1,0,0,44)
Title.Text = "CornelloTeam | Disconnect Notify"
Title.TextColor3 = Color3.fromRGB(220,180,255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.BackgroundTransparency = 1
Title.TextWrapped = true
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextYAlignment = Enum.TextYAlignment.Center
Title.Position = UDim2.fromOffset(16,0)
Title.Parent = Main

-- TOGGLE BUTTON
-- Left sidebar (compact)
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0,110,1, -20)
Sidebar.Position = UDim2.fromOffset(8,46)
Sidebar.BackgroundTransparency = 0.12
Sidebar.BackgroundColor3 = Color3.fromRGB(30,18,45)
local sidebarCorner = Instance.new("UICorner", Sidebar)
sidebarCorner.CornerRadius = UDim.new(0,12)

local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.fromOffset(88,36)
Toggle.Position = UDim2.fromOffset(12,16)
Toggle.Text = "Notify : ON"
Toggle.Font = Enum.Font.Gotham
Toggle.TextSize = 14
Toggle.TextWrapped = true
Toggle.BackgroundColor3 = Color3.fromRGB(90,46,140)
Toggle.TextColor3 = Color3.new(1,1,1)
Toggle.Parent = Sidebar
Instance.new("UICorner", Toggle)

Toggle.MouseButton1Click:Connect(function()
	Config.Enabled = not Config.Enabled
	Toggle.Text = "Notify : "..(Config.Enabled and "ON" or "OFF")
	SaveConfig()
end)

-- TEST WEBHOOK
-- Test button on sidebar
local Test = Toggle:Clone()
Test.Position = UDim2.fromOffset(12,64)
Test.Text = "Test Webhook"
Test.Parent = Sidebar

Test.MouseButton1Click:Connect(function()
	SendWebhook("Test Webhook","Webhook berhasil di test ✅")
end)

-- Discord ID input and webhook manager on right panel
local RightPanel = Instance.new("Frame", Main)
RightPanel.Size = UDim2.new(1, -136, 1, -70)
RightPanel.Position = UDim2.fromOffset(124,46)
RightPanel.BackgroundTransparency = 1

local Scroll = Instance.new("ScrollingFrame", RightPanel)
Scroll.Size = UDim2.new(1,0,1,0)
Scroll.BackgroundTransparency = 1
Scroll.CanvasSize = UDim2.new(0,0)
Scroll.ScrollBarThickness = 6
local layout = Instance.new("UIListLayout", Scroll)
layout.Padding = UDim.new(0,6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
local padding = Instance.new("UIPadding", Scroll)
padding.PaddingLeft = UDim.new(0,8)
padding.PaddingRight = UDim.new(0,8)
padding.PaddingTop = UDim.new(0,8)

-- Discord ID label + box
local discordLabel = Instance.new("TextLabel", Scroll)
discordLabel.Size = UDim2.new(1,0,0,20)
discordLabel.Text = "Discord ID (optional)"
discordLabel.TextColor3 = Color3.fromRGB(210,200,255)
discordLabel.BackgroundTransparency = 1
discordLabel.Font = Enum.Font.Gotham
discordLabel.TextSize = 13

local discordBox = Instance.new("TextBox", Scroll)
discordBox.Size = UDim2.new(1,0,0,36)
discordBox.Text = (Config.DiscordID or "")
discordBox.PlaceholderText = "123456789012345678"
discordBox.Font = Enum.Font.Gotham
discordBox.TextSize = 14
discordBox.TextWrapped = true
discordBox.ClearTextOnFocus = false
discordBox.BackgroundColor3 = Color3.fromRGB(34,20,46)
discordBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", discordBox)

discordBox.FocusLost:Connect(function(enter)
	if enter then
		Config.DiscordID = discordBox.Text or ""
		SaveConfig()
	end
end)

-- Webhook input + add button
local hookBox = Instance.new("TextBox", Scroll)
hookBox.Size = UDim2.new(1,0,0,36)
hookBox.PlaceholderText = "Webhook URL"
hookBox.Font = Enum.Font.Gotham
hookBox.TextSize = 14
hookBox.ClearTextOnFocus = false
hookBox.BackgroundColor3 = Color3.fromRGB(34,20,46)
hookBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", hookBox)

local addBtn = Instance.new("TextButton", Scroll)
addBtn.Size = UDim2.new(1,0,0,32)
addBtn.Text = "Add Webhook"
addBtn.Font = Enum.Font.Gotham
addBtn.TextSize = 14
addBtn.BackgroundColor3 = Color3.fromRGB(95,50,160)
addBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", addBtn)

local hooksInfo = Instance.new("TextLabel", Scroll)
hooksInfo.Size = UDim2.new(1,0,0,18)
hooksInfo.Text = "Webhooks: "..tostring(#Config.Webhooks)
hooksInfo.TextColor3 = Color3.fromRGB(200,190,255)
hooksInfo.BackgroundTransparency = 1
hooksInfo.Font = Enum.Font.Gotham
hooksInfo.TextSize = 12

addBtn.MouseButton1Click:Connect(function()
	local url = hookBox.Text and hookBox.Text:match("https?://%S+") or hookBox.Text
	if url and #url > 10 then
		table.insert(Config.Webhooks, url)
		hookBox.Text = ""
		hooksInfo.Text = "Webhooks: "..tostring(#Config.Webhooks)
		SaveConfig()
	end
end)

-- ICON CLICK
Icon.MouseButton1Click:Connect(function()
	Main.Visible = not Main.Visible
end)

-- Minimize button
local MinBtn = Instance.new("TextButton", Main)
MinBtn.Size = UDim2.fromOffset(28,20)
MinBtn.Position = UDim2.fromOffset(Main.Size.X.Offset - 40,8)
MinBtn.AnchorPoint = Vector2.new(0,0)
MinBtn.Text = "—"
MinBtn.Font = Enum.Font.Gotham
MinBtn.TextSize = 18
MinBtn.BackgroundTransparency = 0.2
MinBtn.BackgroundColor3 = Color3.fromRGB(50,24,80)
MinBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", MinBtn)

MinBtn.MouseButton1Click:Connect(function()
	Main.Visible = false
end)

-- LOAD NOTIF
-- Load config and update UI state
LoadConfig()
Toggle.Text = "Notify : "..(Config.Enabled and "ON" or "OFF")
hooksInfo.Text = "Webhooks: "..tostring(#Config.Webhooks)
discordBox.Text = Config.DiscordID or ""

-- Notify script loaded (safe)
pcall(function()
	SendWebhook("Script Loaded","CornelloTeam berhasil dijalankan di Roblox ✅")
end)

SaveConfig()

-- Best-effort: queue a loader for teleport if executor supports queue_on_teleport
pcall(function()
	local qf = queue_on_teleport or (syn and syn.queue_on_teleport)
	if qf and type(qf) == "function" and type(readfile) == "function" then
		-- try to queue a loader that reads a saved script file (user's executor must have written it)
		local loader = [[
			pcall(function()
				local names = {"Cornello.lua","CornelloTeam.lua","CornelloTeam_Auto.lua"}
				for _,n in ipairs(names) do
					local ok, content = pcall(readfile, n)
					if ok and content and #content > 40 then
						loadstring(content)()
						return
					end
				end
			end)
		]]
		qf(loader)
	end
end)