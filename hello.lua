-- LocalScript inside a ScreenGui
-- Mobile-only, self-only animation player GUI
-- Requires: AnimationController inside a Model inside the player's Character
-- Example path: Character > SomeModel > AnimationController

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local gui = script.Parent

if not UserInputService.TouchEnabled then
	gui:Destroy()
	return
end

local character = player.Character or player.CharacterAdded:Wait()

local function getAnimationController()
	character = player.Character or player.CharacterAdded:Wait()

	for _, desc in ipairs(character:GetDescendants()) do
		if desc:IsA("AnimationController") then
			return desc
		end
	end
	return nil
end

local controller = getAnimationController()
local currentTrack
local looped = false
local overrideOn = false
local animSpeed = 1
local playing = false

local function stopCurrent()
	if currentTrack then
		currentTrack:Stop()
		currentTrack:Destroy()
		currentTrack = nil
	end
	playing = false
end

local function playAnimation(animId)
	if not controller then
		controller = getAnimationController()
		if not controller then return end
	end

	if overrideOn then
		for _, track in ipairs(controller:GetPlayingAnimationTracks()) do
			track:Stop(0)
		end
	end

	stopCurrent()

	local anim = Instance.new("Animation")
	anim.AnimationId = animId

	currentTrack = controller:LoadAnimation(anim)
	currentTrack.Looped = looped
	currentTrack:Play()
	currentTrack:AdjustSpeed(animSpeed)
	playing = true
end

-- GUI
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 230)
frame.Position = UDim2.new(0.5, -140, 0.5, -115)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Animation Player"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Parent = frame

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -20, 0, 35)
box.Position = UDim2.new(0, 10, 0, 40)
box.PlaceholderText = "Animation ID (rbxassetid://...)"
box.Text = ""
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
box.Parent = frame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 6)
boxCorner.Parent = box

local function makeButton(text, x, y, w, h)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, w, 0, h)
	b.Position = UDim2.new(0, x, 0, y)
	b.Text = text
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	b.Parent = frame
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = b
	return b
end

local playBtn = makeButton("Play", 10, 85, 80, 35)
local stopBtn = makeButton("Stop", 100, 85, 80, 35)
local loopBtn = makeButton("Loop: Off", 190, 85, 80, 35)

local overrideBtn = makeButton("Override: Off", 10, 130, 125, 35)
local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0, 125, 0, 35)
speedBox.Position = UDim2.new(0, 145, 0, 130)
speedBox.Text = "1"
speedBox.PlaceholderText = "Speed"
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
speedBox.Parent = frame
local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 6)
speedCorner.Parent = speedBox

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 40)
status.Position = UDim2.new(0, 10, 0, 175)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextWrapped = true
status.Text = "Enter animation ID, then press Play."
status.Parent = frame

playBtn.Activated:Connect(function()
	local id = box.Text:match("%d+")
	if not id then
		status.Text = "Invalid animation ID."
		return
	end

	local spd = tonumber(speedBox.Text)
	if spd then
		animSpeed = spd
	else
		animSpeed = 1
	end

	playAnimation("rbxassetid://" .. id)
	status.Text = "Playing animation."
end)

stopBtn.Activated:Connect(function()
	stopCurrent()
	status.Text = "Stopped."
end)

loopBtn.Activated:Connect(function()
	looped = not looped
	loopBtn.Text = "Loop: " .. (looped and "On" or "Off")
	if currentTrack then
		currentTrack.Looped = looped
	end
end)

overrideBtn.Activated:Connect(function()
	overrideOn = not overrideOn
	overrideBtn.Text = "Override: " .. (overrideOn and "On" or "Off")
end)

speedBox.FocusLost:Connect(function()
	local spd = tonumber(speedBox.Text)
	if spd then
		animSpeed = spd
	else
		speedBox.Text = "1"
		animSpeed = 1
	end
	if currentTrack then
		currentTrack:AdjustSpeed(animSpeed)
	end
end)

player.CharacterAdded:Connect(function(char)
	character = char
	controller = getAnimationController()
	stopCurrent()
end)
