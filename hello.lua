-- StarterPlayerScripts (LocalScript) - LOCAL ONLY
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LocalAnimLoopPlayerGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Size = UDim2.fromOffset(360, 150)
frame.Position = UDim2.new(0, 20, 0, 60)
frame.Parent = screenGui

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Size = UDim2.fromOffset(330, 18)
statusLabel.Position = UDim2.fromOffset(10, 10)
statusLabel.Text = "Enter AnimationId and press Play."
statusLabel.Parent = frame

local animBox = Instance.new("TextBox")
animBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
animBox.BackgroundTransparency = 0.1
animBox.BorderSizePixel = 0
animBox.TextColor3 = Color3.fromRGB(255, 255, 255)
animBox.Font = Enum.Font.Gotham
animBox.TextSize = 16
animBox.PlaceholderText = "AnimationId (e.g. 123456 or rbxassetid://123456)"
animBox.ClearTextOnFocus = false
animBox.Size = UDim2.fromOffset(330, 38)
animBox.Position = UDim2.fromOffset(10, 30)
animBox.Parent = frame

local playButton = Instance.new("TextButton")
playButton.BackgroundColor3 = Color3.fromRGB(70, 140, 255)
playButton.BorderSizePixel = 0
playButton.AutoButtonColor = true
playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playButton.Font = Enum.Font.GothamBold
playButton.TextSize = 16
playButton.Text = "Play Loop (Override)"
playButton.Size = UDim2.fromOffset(330, 40)
playButton.Position = UDim2.fromOffset(10, 75)
playButton.Parent = frame

-- Logic
local currentTrack = nil
local stopToken = 0

local function setStatus(msg)
	statusLabel.Text = msg
end

local function normalizeAnimId(input)
	local s = tostring(input or ""):gsub("%s+", "")
	if s == "" then return nil end
	local id = s:match("rbxassetid://(%d+)")
	if not id then id = s:match("asset/%?id=(%d+)") end
	if not id then id = s:match("(%d+)") end
	return id and tonumber(id) or nil
end

local function findAnimatorAnywhere(character)
	-- This is the important part:
	-- It finds the Animator wherever it is (including inside your nested Model).
	local animator = character:FindFirstChildWhichIsA("Animator", true)
	if animator then return animator end
	return nil
end

local function stopCurrent()
	if currentTrack then
		currentTrack:Stop(0)
		currentTrack = nil
	end
end

local function playLoop(animIdNumber)
	local character = player.Character
	if not character then
		setStatus("No character.")
		return
	end

	local animator = findAnimatorAnywhere(character)
	if not animator then
		setStatus("No Animator found anywhere under character.")
		return
	end

	stopToken += 1
	local myToken = stopToken

	stopCurrent()

	local anim = Instance.new("Animation")
	anim.AnimationId = ("rbxassetid://%d"):format(animIdNumber)

	local track = animator:LoadAnimation(anim)
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Action2
	track:Play(0.05)

	-- If a new play happens, stop the old one
	if myToken ~= stopToken then
		track:Stop(0)
		return
	end

	currentTrack = track
	setStatus(("Playing %d (loop)"):format(animIdNumber))
end

playButton.MouseButton1Click:Connect(function()
	local id = normalizeAnimId(animBox.Text)
	if not id then
		setStatus("Invalid animation id.")
		return
	end
	playLoop(id)
end)

player.CharacterAdded:Connect(function()
	stopToken += 1
	stopCurrent()
	setStatus("Respawned. Enter id and press Play.")
end)
