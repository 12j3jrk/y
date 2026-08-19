-- Put this LocalScript in: StarterPlayerScripts
-- It will create the whole GUI (TextBox + Play button + Status) automatically.
-- Local-only: plays a looped animation on the LOCAL character, using AnimationController -> Animator.

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LocalAnimLoopPlayerGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Size = UDim2.fromOffset(320, 140)
frame.Position = UDim2.new(0, 20, 0, 40)
frame.Parent = screenGui

local uipadding = Instance.new("UIPadding")
uipadding.PaddingTop = UDim.new(0, 10)
uipadding.PaddingLeft = UDim.new(0, 10)
uipadding.PaddingRight = UDim.new(0, 10)
uipadding.PaddingBottom = UDim.new(0, 10)
uipadding.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Size = UDim2.fromOffset(300, 18)
statusLabel.Position = UDim2.fromOffset(0, 0)
statusLabel.Text = "Enter animation id, press Play."
statusLabel.Parent = frame

local animBox = Instance.new("TextBox")
animBox.Name = "AnimIdBox"
animBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
animBox.BackgroundTransparency = 0.1
animBox.BorderSizePixel = 0
animBox.TextColor3 = Color3.fromRGB(255, 255, 255)
animBox.Font = Enum.Font.Gotham
animBox.TextSize = 16
animBox.PlaceholderText = "AnimationId (e.g. 123456 or rbxassetid://123456)"
animBox.ClearTextOnFocus = false
animBox.Size = UDim2.fromOffset(300, 38)
animBox.Position = UDim2.fromOffset(0, 22)
animBox.Parent = frame

local playButton = Instance.new("TextButton")
playButton.Name = "PlayButton"
playButton.BackgroundColor3 = Color3.fromRGB(70, 140, 255)
playButton.BackgroundTransparency = 0
playButton.BorderSizePixel = 0
playButton.AutoButtonColor = true
playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playButton.Font = Enum.Font.GothamBold
playButton.TextSize = 16
playButton.Text = "Play Loop"
playButton.Size = UDim2.fromOffset(300, 38)
playButton.Position = UDim2.fromOffset(0, 70)
playButton.Parent = frame

-- Logic
local currentTrack = nil

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

local function getAnimator(character)
	-- Prefer AnimationController -> Animator
	local animController = character:FindFirstChildWhichIsA("AnimationController", true)
	if animController then
		local animator = animController:FindFirstChildWhichIsA("Animator", true)
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = animController
		end
		return animator
	end

	-- Fallback: older rigs
	local humanoid = character:FindFirstChildWhichIsA("Humanoid", true)
	if humanoid then
		return humanoid:FindFirstChildWhichIsA("Animator", true)
	end

	return nil
end

local function stopCurrent()
	if currentTrack then
		currentTrack:Stop(0)
		currentTrack = nil
	end
end

local function playLoopedAnimation(animIdNumber)
	local character = player.Character
	if not character then
		setStatus("No character yet.")
		return
	end

	local animator = getAnimator(character)
	if not animator then
		setStatus("No Animator/AnimationController found on rig.")
		return
	end

	stopCurrent()

	local anim = Instance.new("Animation")
	anim.AnimationId = ("rbxassetid://%d"):format(animIdNumber)

	local track = animator:LoadAnimation(anim)
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Action
	track:Play(0.1)

	currentTrack = track
	setStatus(("Playing %d (loop)"):format(animIdNumber))
end

playButton.MouseButton1Click:Connect(function()
	local id = normalizeAnimId(animBox.Text)
	if not id then
		setStatus("Invalid animation id.")
		return
	end
	playLoopedAnimation(id)
end)

player.CharacterAdded:Connect(function()
	stopCurrent()
	setStatus("Respawned. Enter an id and press Play.")
end)
