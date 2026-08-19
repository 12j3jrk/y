-- LocalScript only (LOCAL ONLY)
-- Put this in: StarterPlayerScripts
-- It creates the GUI and plays a LOOPED animation chosen by TextBox.
-- It loads the Animation onto the Animator found anywhere under your character
-- (including if it's inside a nested Model).

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== GUI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LocalAnimLoopPlayerGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Frame"
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Size = UDim2.fromOffset(360, 150)
frame.Position = UDim2.new(0, 20, 0, 60)
frame.Parent = screenGui

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
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
animBox.Name = "AnimIdBox"
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
playButton.Name = "PlayButton"
playButton.BackgroundColor3 = Color3.fromRGB(70, 140, 255)
playButton.BorderSizePixel = 0
playButton.AutoButtonColor = true
playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playButton.Font = Enum.Font.GothamBold
playButton.TextSize = 16
playButton.Text = "Play Loop"
playButton.Size = UDim2.fromOffset(330, 40)
playButton.Position = UDim2.fromOffset(10, 75)
playButton.Parent = frame

-- ===== Animation Logic (LOCAL ONLY) =====
local currentTrack : AnimationTrack? = nil
local currentAnimator : Animator? = nil
local currentAnimId : number? = nil

local function setStatus(msg)
	statusLabel.Text = msg
end

local function normalizeAnimId(input)
	local s = tostring(input or ""):gsub("%s+", "")
	if s == "" then return nil end

	local id = s:match("rbxassetid://(%d+)")
	if not id then id = s:match("asset/%?id=(%d+)") end
	if not id then id = s:match("(%d+)") end

	if not id then return nil end
	return tonumber(id)
end

local function getAnimator(character)
	-- Finds ANY Animator anywhere under your character (including nested Models).
	if not character then return nil end
	return character:FindFirstChildWhichIsA("Animator", true)
end

local function stopCurrent()
	if currentTrack then
		pcall(function() currentTrack:Stop(0) end)
	end
	currentTrack = nil
	currentAnimator = nil
end

local function ensureCharacterAndAnimatorAndPlay(animIdNumber)
	currentAnimId = animIdNumber
	local character = player.Character
	if not character then
		setStatus("No character yet.")
		return
	end

	setStatus("Finding Animator...")
	stopCurrent()

	-- Animator can appear a moment later due to rig loading / nested model placement.
	local animator = nil
	for _ = 1, 30 do
		animator = getAnimator(character)
		if animator then break end
		task.wait(0.1)
	end

	if not animator then
		setStatus("Animator not found under character.")
		return
	end

	currentAnimator = animator

	local anim = Instance.new("Animation")
	anim.AnimationId = ("rbxassetid://%d"):format(animIdNumber)

	local ok, trackOrErr = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if not ok or not trackOrErr then
		setStatus("LoadAnimation failed.")
		return
	end

	currentTrack = trackOrErr
	currentTrack.Looped = true
	-- Action2 tends to win against default idle/walk on many rigs.
	currentTrack.Priority = Enum.AnimationPriority.Action2
	currentTrack:Play(0.05)

	setStatus(("Playing %d (loop)"):format(animIdNumber))
end

playButton.MouseButton1Click:Connect(function()
	local id = normalizeAnimId(animBox.Text)
	if not id then
		setStatus("Invalid AnimationId.")
		return
	end
	ensureCharacterAndAnimatorAndPlay(id)
end)

player.CharacterAdded:Connect(function()
	-- Keep the UI; stop old track; re-play last animation if any.
	stopCurrent()
	setStatus("Respawned. Re-loading...")
	if currentAnimId then
		task.wait(0.2)
		ensureCharacterAndAnimatorAndPlay(currentAnimId)
	else
		setStatus("Enter an id and press Play.")
	end
end)
