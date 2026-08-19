local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Get animation controller
local animationController = character:WaitForChild("AnimationControllerModel"):WaitForChild("AnimationController")

-- Mobile detection
if not UserInputService.TouchEnabled then
    return
end

-- Create ScreenGui optimized for mobile
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AnimationPlayerGui"
screenGui.ResetOnSpawn = false
screenGui.SafeAreaCompatible = true
screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Main frame (full screen, bottom sheet style)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(1, 0, 0, 500)
mainFrame.Position = UDim2.new(0, 0, 1, -500)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Top handle bar
local handleBar = Instance.new("Frame")
handleBar.Name = "HandleBar"
handleBar.Size = UDim2.new(0, 50, 0, 4)
handleBar.Position = UDim2.new(0.5, -25, 0, 8)
handleBar.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
handleBar.BorderSizePixel = 0
handleBar.Parent = mainFrame

local handleCorner = Instance.new("UICorner")
handleCorner.CornerRadius = UDim.new(0, 2)
handleCorner.Parent = handleBar

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 16)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.Text = "Animation Player"
title.Parent = mainFrame

-- Scroll frame for content
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ScrollFrame"
scrollFrame.Size = UDim2.new(1, -20, 1, -80)
scrollFrame.Position = UDim2.new(0, 10, 0, 66)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
scrollFrame.CanUseMouseWheel = true
scrollFrame.Parent = mainFrame

-- List layout for scrolling content
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 12)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingLeft = UDim.new(0, 0)
listPadding.PaddingRight = UDim.new(0, 0)
listPadding.PaddingTop = UDim.new(0, 8)
listPadding.PaddingBottom = UDim.new(0, 8)
listPadding.Parent = scrollFrame

-- Helper: Create label
local function createLabel(text, layoutOrder)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 24)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(180, 180, 180)
    label.TextSize = 13
    label.Font = Enum.Font.GothamSemibold
    label.Text = text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = layoutOrder
    label.Parent = scrollFrame
    return label
end

-- Helper: Create input box
local function createInputBox(placeholder, layoutOrder)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 44)
    box.BackgroundColor3 = Color3.fromRGB(55, 55, 58)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.TextSize = 14
    box.Font = Enum.Font.Gotham
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    box.LayoutOrder = layoutOrder
    box.Parent = scrollFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = box
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = box
    
    return box
end

-- Helper: Create button (thumb-friendly)
local function createButton(text, layoutOrder)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 48)
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 15
    button.Font = Enum.Font.GothamBold
    button.Text = text
    button.BorderSizePixel = 0
    button.LayoutOrder = layoutOrder
    button.Parent = scrollFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Hover effect
    local originalColor = button.BackgroundColor3
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(85, 85, 90)
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = originalColor
    end)
    
    return button
end

-- UI Elements
createLabel("Animation ID", 1)
local animationIdBox = createInputBox("rbxassetid://123456789", 2)

createLabel("Playback Speed", 3)
local speedBox = createInputBox("1.0", 4)
local speedDisplay = createLabel("Speed: 1.00", 5)

createLabel("Controls", 6)
local playBtn = createButton("▶ PLAY", 7)
local stopBtn = createButton("⏹ STOP", 8)

createLabel("Options", 9)
local loopBtn = createButton("🔁 Loop: OFF", 10)
local overrideBtn = createButton("🛡️ Override: OFF", 11)

-- State variables
local currentAnimation = nil
local isLooping = false
local isOverride = false
local animationSpeed = 1

-- Helper: Update button appearance
local function updateButtonColor(button, isActive)
    button.BackgroundColor3 = isActive 
        and Color3.fromRGB(52, 168, 83) 
        or Color3.fromRGB(70, 70, 75)
end

-- Play animation
local function playAnimation()
    local animId = animationIdBox.Text
    
    -- Extract numeric ID
    if animId:match("rbxassetid://") then
        animId = animId:gsub("rbxassetid://", "")
    end
    
    if not animId or animId == "" then
        print("Invalid animation ID")
        return
    end
    
    -- Stop existing animation
    if currentAnimation then
        currentAnimation:Stop()
    end
    
    -- Create and play new animation
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://" .. animId
    
    currentAnimation = animationController:LoadAnimation(animation)
    currentAnimation.Looped = isLooping
    currentAnimation.Speed = animationSpeed
    currentAnimation:Play()
    
    print("Playing animation: " .. animId)
end

-- Stop animation
local function stopAnimation()
    if currentAnimation then
        currentAnimation:Stop()
        currentAnimation = nil
        print("Animation stopped")
    end
end

-- Toggle loop
local function toggleLoop()
    isLooping = not isLooping
    loopBtn.Text = isLooping and "🔁 Loop: ON" or "🔁 Loop: OFF"
    updateButtonColor(loopBtn, isLooping)
    
    if currentAnimation then
        currentAnimation.Looped = isLooping
    end
end

-- Toggle override
local function toggleOverride()
    isOverride = not isOverride
    overrideBtn.Text = isOverride and "🛡️ Override: ON" or "🛡️ Override: OFF"
    updateButtonColor(overrideBtn, isOverride)
end

-- Update speed
local function updateSpeed()
    local speedValue = tonumber(speedBox.Text) or 1
    speedValue = math.max(0.1, math.min(speedValue, 5))
    
    animationSpeed = speedValue
    speedBox.Text = tostring(speedValue)
    speedDisplay.Text = string.format("Speed: %.2f", speedValue)
    
    if currentAnimation then
        currentAnimation.Speed = animationSpeed
    end
end

-- Connect button events
playBtn.Activated:Connect(playAnimation)
stopBtn.Activated:Connect(stopAnimation)
loopBtn.Activated:Connect(toggleLoop)
overrideBtn.Activated:Connect(toggleOverride)
speedBox.FocusLost:Connect(updateSpeed)

-- Update scrolling frame content size
local function updateScrollSize()
    listLayout:ApplyLayout()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 16)
end

listLayout.Changed:Connect(updateScrollSize)
RunService.RenderStepped:Connect(updateScrollSize)
