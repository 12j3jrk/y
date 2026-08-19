local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Get the animation controller from the model in the character
-- Adjust the path based on your model structure
local animationControllerModel = character:WaitForChild("AnimationControllerModel") -- Change name as needed
local animationController = animationControllerModel:WaitForChild("AnimationController")

-- Create the GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AnimationPlayerGui"
screenGui.ResetOnSpawn = false
screenGui.SafeAreaCompatible = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 280, 0, 400)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Add corner radius
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Add stroke
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(100, 100, 100)
stroke.Thickness = 2
stroke.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Text = "Animation Player"
title.BorderSizePixel = 0
title.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

-- Padding container
local paddingFrame = Instance.new("Frame")
paddingFrame.Name = "PaddingFrame"
paddingFrame.Size = UDim2.new(1, -20, 1, -60)
paddingFrame.Position = UDim2.new(0, 10, 0, 50)
paddingFrame.BackgroundTransparency = 1
paddingFrame.Parent = mainFrame

-- UIListLayout
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = paddingFrame

-- Animation ID TextBox
local animationIdLabel = Instance.new("TextLabel")
animationIdLabel.Name = "AnimationIdLabel"
animationIdLabel.Size = UDim2.new(1, 0, 0, 20)
animationIdLabel.BackgroundTransparency = 1
animationIdLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
animationIdLabel.TextSize = 12
animationIdLabel.Font = Enum.Font.Gotham
animationIdLabel.Text = "Animation ID:"
animationIdLabel.TextXAlignment = Enum.TextXAlignment.Left
animationIdLabel.LayoutOrder = 1
animationIdLabel.Parent = paddingFrame

local animationIdBox = Instance.new("TextBox")
animationIdBox.Name = "AnimationIdBox"
animationIdBox.Size = UDim2.new(1, 0, 0, 32)
animationIdBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
animationIdBox.TextColor3 = Color3.fromRGB(255, 255, 255)
animationIdBox.TextSize = 14
animationIdBox.Font = Enum.Font.Gotham
animationIdBox.PlaceholderText = "rbxassetid://..."
animationIdBox.BorderSizePixel = 0
animationIdBox.LayoutOrder = 2
animationIdBox.Parent = paddingFrame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 6)
boxCorner.Parent = animationIdBox

-- Animation Speed Label and Input
local speedLabel = Instance.new("TextLabel")
speedLabel.Name = "SpeedLabel"
speedLabel.Size = UDim2.new(1, 0, 0, 20)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.TextSize = 12
speedLabel.Font = Enum.Font.Gotham
speedLabel.Text = "Speed: 1.00"
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.LayoutOrder = 3
speedLabel.Parent = paddingFrame

local speedBox = Instance.new("TextBox")
speedBox.Name = "SpeedBox"
speedBox.Size = UDim2.new(1, 0, 0, 32)
speedBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.TextSize = 14
speedBox.Font = Enum.Font.Gotham
speedBox.Text = "1"
speedBox.PlaceholderText = "1.0"
speedBox.BorderSizePixel = 0
speedBox.LayoutOrder = 4
speedBox.Parent = paddingFrame

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 6)
speedCorner.Parent = speedBox

-- Buttons Container
local buttonsContainer = Instance.new("Frame")
buttonsContainer.Name = "ButtonsContainer"
buttonsContainer.Size = UDim2.new(1, 0, 0, 150)
buttonsContainer.BackgroundTransparency = 1
buttonsContainer.LayoutOrder = 5
buttonsContainer.Parent = paddingFrame

local buttonLayout = Instance.new("UIGridLayout")
buttonLayout.CellSize = UDim2.new(0.5, -4, 0, 30)
buttonLayout.CellPadding = UDim2.new(0, 8, 0, 8)
buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
buttonLayout.Parent = buttonsContainer

-- Helper function to create buttons
local function createButton(name, text, parent, layoutOrder)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0, 100, 0, 30)
	button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 12
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.BorderSizePixel = 0
	button.LayoutOrder = layoutOrder
	button.Parent = parent
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = button
	
	return button
end

-- Create buttons
local playBtn = createButton("PlayBtn", "Play", buttonsContainer, 1)
local stopBtn = createButton("StopBtn", "Stop", buttonsContainer, 2)
local loopBtn = createButton("LoopBtn", "Loop: OFF", buttonsContainer, 3)
local overrideBtn = createButton("OverrideBtn", "Override: OFF", buttonsContainer, 4)

-- Animation state
local currentAnimation = nil
local isLooping = false
local isOverride = false
local animationSpeed = 1

-- Helper function to set button color
local function setButtonColor(button, isActive)
	button.BackgroundColor3 = isActive and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(70, 70, 70)
end

-- Play animation
local function playAnimation()
	local animId = animationIdBox.Text:match("rbxassetid://(%d+)") or animationIdBox.Text
	
	if not animId or animId == "" then
		print("Invalid animation ID")
		return
	end
	
	-- Stop current animation if playing
	if currentAnimation then
		currentAnimation:Stop()
	end
	
	-- Create new animation
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://" .. animId
	
	-- Load animation on the controller
	currentAnimation = animationController:LoadAnimation(animation)
	currentAnimation.Looped = isLooping
	currentAnimation.Speed = animationSpeed
	currentAnimation:Play()
end

-- Stop animation
local function stopAnimation()
	if currentAnimation then
		currentAnimation:Stop()
		currentAnimation = nil
	end
end

-- Toggle loop
local function toggleLoop()
	isLooping = not isLooping
	loopBtn.Text = isLooping and "Loop: ON" or "Loop: OFF"
	setButtonColor(loopBtn, isLooping)
	
	if currentAnimation then
		currentAnimation.Looped = isLooping
	end
end

-- Toggle override
local function toggleOverride()
	isOverride = not isOverride
	overrideBtn.Text = isOverride and "Override: ON" or "Override: OFF"
	setButtonColor(overrideBtn, isOverride)
end

-- Update speed
local function updateSpeed()
	local speedValue = tonumber(speedBox.Text) or 1
	speedValue = math.max(0.1, math.min(speedValue, 5)) -- Clamp between 0.1 and 5
	animationSpeed = speedValue
	speedBox.Text = tostring(speedValue)
	speedLabel.Text = string.format("Speed: %.2f", speedValue)
	
	if currentAnimation then
		currentAnimation.Speed = animationSpeed
	end
end

-- Button connections
playBtn.Activated:Connect(playAnimation)
stopBtn.Activated:Connect(stopAnimation)
loopBtn.Activated:Connect(toggleLoop)
overrideBtn.Activated:Connect(toggleOverride)
speedBox.FocusLost:Connect(updateSpeed)
speedBox:GetPropertyChangedSignal("Text"):Connect(updateSpeed)

-- Mobile detection
local function isMobile()
    local userInputService = game:GetService("UserInputService")
    return userInputService.TouchEnabled
end

-- Only show on touch-enabled devices
if not isMobile() then
    screenGui:Destroy()
    return
end


if not isMobile() then
	screenGui:Destroy()
	return
end
