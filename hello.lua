local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local pelican = RS.Birds.Pelican:Clone()
pelican.Parent = workspace

for _, obj in ipairs(pelican:GetDescendants()) do
	if obj:IsA("BasePart") then
		obj.BrickColor = BrickColor.new("Really black")
		obj.Material = Enum.Material.SmoothPlastic
	elseif obj:IsA("SpecialMesh") or obj:IsA("MeshPart") then
		obj.Color = Color3.new(0, 0, 0)
	end
end

local chickTemplate = RS.Birds.PenguinChick
local chicks = {}

local function blackenModel(model)
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Color = Color3.new(0, 0, 0)
			obj.Material = Enum.Material.SmoothPlastic
		elseif obj:IsA("MeshPart") then
			obj.Color = Color3.new(0, 0, 0)
		end
	end
end

local function getPrimaryPart(model)
	if model.PrimaryPart then return model.PrimaryPart end
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			model.PrimaryPart = obj
			return obj
		end
	end
end

local pelicanPart = getPrimaryPart(pelican)
if pelicanPart then
	pelican:PivotTo(CFrame.new(workspace.CurrentCamera.CFrame.Position + workspace.CurrentCamera.CFrame.LookVector * 20))
end

local lastAttach = pelicanPart and pelicanPart.CFrame or CFrame.new()

for i = 1, 10 do
	local chick = chickTemplate:Clone()
	chick.Parent = workspace
	blackenModel(chick)

	local chickPart = getPrimaryPart(chick)
	if chickPart then
		chickPart.Anchored = true
	end

	chicks[i] = chick
end

RunService.Heartbeat:Connect(function()
	local cam = workspace.CurrentCamera
	if not cam then return end

	local targetPos = cam.CFrame.Position + cam.CFrame.LookVector * 20
	local base = CFrame.new(targetPos, cam.CFrame.Position)

	if pelicanPart then
		pelican:PivotTo(base)
		lastAttach = pelicanPart.CFrame
	end

	local neckLength = 8
	local segmentGap = 4

	for i, chick in ipairs(chicks) do
		local offset = CFrame.new(0, 0, -neckLength * i)
		local wobble = CFrame.Angles(
			math.sin(tick() * 0.2 + i) * 0.01,
			math.sin(tick() * 0.15 + i) * 0.01,
			math.cos(tick() * 0.2 + i) * 0.01
		)
		chick:PivotTo(lastAttach * CFrame.new(0, 0, -segmentGap * i) * wobble)
	end
end)
