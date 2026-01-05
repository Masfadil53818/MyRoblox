-- FPS BOOST + UTILITY GUI
-- LocalScript (StarterPlayerScripts)

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- GUI
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "FPSBoostGui"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 300, 0, 260)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local uiCorner = Instance.new("UICorner", frame)

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 35)
title.Text = "FPS BOOST & UTILITY"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16

-- Button creator
local function createButton(text, posY)
	local btn = Instance.new("TextButton", frame)
	btn.Size = UDim2.new(0.9, 0, 0, 35)
	btn.Position = UDim2.new(0.05, 0, 0, posY)
	btn.Text = text
	btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 14
	Instance.new("UICorner", btn)
	return btn
end

-- Buttons
local fpsBtn = createButton("FPS BOOST : OFF", 45)
local wsBtn = createButton("WalkSpeed +", 90)
local jpBtn = createButton("JumpPower +", 135)
local resetBtn = createButton("Reset Utility", 180)

-- FPS BOOST FUNCTION
local fpsEnabled = false

local function fpsBoost(state)
	if state then
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 9e9
		Lighting.Brightness = 1

		for _,v in pairs(workspace:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Trail") then
				v.Enabled = false
			elseif v:IsA("BasePart") then
				v.Material = Enum.Material.Plastic
				v.Reflectance = 0
			end
		end
	else
		Lighting.GlobalShadows = true
	end
end

fpsBtn.MouseButton1Click:Connect(function()
	fpsEnabled = not fpsEnabled
	fpsBoost(fpsEnabled)
	fpsBtn.Text = fpsEnabled and "FPS BOOST : ON" or "FPS BOOST : OFF"
end)

-- Utility
wsBtn.MouseButton1Click:Connect(function()
	humanoid.WalkSpeed = humanoid.WalkSpeed + 5
end)

jpBtn.MouseButton1Click:Connect(function()
	humanoid.JumpPower = humanoid.JumpPower + 10
end)

resetBtn.MouseButton1Click:Connect(function()
	humanoid.WalkSpeed = 16
	humanoid.JumpPower = 50
end)

-- Toggle GUI (RightShift)
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.RightShift then
		frame.Visible = not frame.Visible
	end
end)
