-- StarterPlayerScripts > LocalScript

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Birds = ReplicatedStorage:WaitForChild("Birds")

local PelicanTemplate = Birds:WaitForChild("Pelican")
local PenguinTemplate = Birds:WaitForChild("PenguinChick")

-- Try to match the beak part/attachment name inside the Pelican model
local BEAK_NAME = "Beak2"
local FALLBACK_TO_MODEL_PIVOT = true

-- Tuning
local PELICAN_SCALE = 20
local PENGUIN_SCALE = 10
local NECK_COUNT = 60

-- Reduced from 250 so the penguins sit closer together/inward
-- instead of stretching into an obvious oval.
local NECK_LENGTH = 220

local UPDATE_DT = 0.02

-- "insane" motion tuning
local INSANE_BASE_SPEED = 4.0
local JITTER_STRENGTH = 3.5
local ROT_INSANE_STRENGTH = 3.5
local SWAY_STRENGTH = 1.18

local function setBlack(model)
	for _, inst in ipairs(model:GetDescendants()) do
		if inst:IsA("BasePart") then
			inst.Color = Color3.new(0, 0, 0)

			if inst.Material ~= Enum.Material.Neon then
				inst.Material = Enum.Material.SmoothPlastic
			end
		elseif inst:IsA("Decal") then
			inst.Transparency = 1
		end
	end
end

local function getBeakCFrame(model)
	local found = model:FindFirstChild(BEAK_NAME, true)

	if found then
		if found:IsA("Attachment") then
			return found.WorldCFrame
		elseif found:IsA("BasePart") then
			return found.CFrame
		end
	end

	if FALLBACK_TO_MODEL_PIVOT then
		return model:GetPivot()
	end

	return model:GetPivot()
end

local function scaleModel(model, scale)
	local pivot = model:GetPivot()

	for _, inst in ipairs(model:GetDescendants()) do
		if inst:IsA("BasePart") then
			local relPos = pivot:PointToObjectSpace(inst.Position)

			inst.Size = inst.Size * scale

			-- Reposition translation while keeping orientation
			inst.CFrame =
				pivot
				* CFrame.new(relPos * scale)
				* (inst.CFrame - inst.CFrame.Position)
		end
	end
end

local function estimatePenguinSegmentStep(penguinTemplateClone)
	local cf, size = penguinTemplateClone:GetBoundingBox()

	-- Slightly tighter base spacing
	local step = math.max(1, (size.Y + size.Z) * 0.5)

	return step
end

local function clonePelican()
	local char = player.Character
	if not char then
		return nil
	end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil
	end

	local pelican = PelicanTemplate:Clone()

	pelican.Name = "ClientPelican_" .. player.Name
	pelican.Parent = workspace

	setBlack(pelican)
	scaleModel(pelican, PELICAN_SCALE)

	-- Teleport immediately to player
	pelican:PivotTo(hrp.CFrame)

	return pelican
end

local function buildNeck(pelican)
	local container = Instance.new("Folder")
	container.Name = "ClientPenguinNeckStack"
	container.Parent = pelican

	local beakCF = getBeakCFrame(pelican)
	local forward = beakCF.LookVector

	-- Clone a temporary penguin to estimate spacing
	local temp = PenguinTemplate:Clone()

	setBlack(temp)
	scaleModel(temp, PENGUIN_SCALE)

	local segStep = estimatePenguinSegmentStep(temp)

	temp:Destroy()

	-- Use the reduced total length so the chain stays more compact
	-- and doesn't form such an obvious stretched oval.
	local desiredTotal = NECK_LENGTH
	local currentTotal = segStep * (NECK_COUNT - 1)

	local lengthScale =
		(currentTotal > 0)
		and (desiredTotal / currentTotal)
		or 1

	local step = segStep * lengthScale

	-- Create penguins
	local penguins = {}

	for i = 1, NECK_COUNT do
		local p = PenguinTemplate:Clone()

		p.Name = ("Penguin_%02d"):format(i)
		p.Parent = container

		setBlack(p)
		scaleModel(p, PENGUIN_SCALE)

		local dist = step * (i - 1)

		local targetCF =
			beakCF
			* CFrame.new(-forward * dist)

		p:PivotTo(targetCF)

		table.insert(penguins, p)
	end

	-- Insane connected animation
	task.spawn(function()
		local t0 = os.clock()

		while pelican.Parent do
			local t = os.clock() - t0

			local currentBeak = getBeakCFrame(pelican)

			local fwd = currentBeak.LookVector
			local right = currentBeak.RightVector
			local up = currentBeak.UpVector

			-- Fast jitter seed-ish changes
			local baseYaw =
				math.sin(t * INSANE_BASE_SPEED * 1.1)
				* (0.6 + math.random() * 0.6)

			local basePitch =
				math.cos(t * INSANE_BASE_SPEED * 0.9)
				* (0.4 + math.random() * 0.6)

			-- Keep each segment anchored and connected
			for i, p in ipairs(penguins) do
				if not p.Parent then
					break
				end

				local alpha =
					(i - 1)
					/ math.max(1, NECK_COUNT - 1)

				local dist = step * (i - 1)

				-- Random shake
				local randX = (math.random() - 0.5) * 2
				local randY = (math.random() - 0.5) * 2
				local randZ = (math.random() - 0.5) * 2

				local jitterPos =
					(right * randX + up * randY)
					* (JITTER_STRENGTH * (0.1 + alpha))

				local jitterRotYaw =
					(
						math.sin(
							t * INSANE_BASE_SPEED
							+ i * 0.25
						)
						+ randZ
					)
					* (
						ROT_INSANE_STRENGTH
						* 0.02
						* (0.2 + alpha)
					)

				local jitterRotRoll =
					(
						math.cos(
							t * INSANE_BASE_SPEED * 1.2
							+ i * 0.18
						)
						+ randY
					)
					* (
						ROT_INSANE_STRENGTH
						* 0.02
						* (0.2 + alpha)
					)

				-- Curved/twisting neck
				local sway =
					math.sin(
						t * (INSANE_BASE_SPEED * 0.8)
						+ i * 0.35
					)
					* SWAY_STRENGTH
					* (0.05 + alpha)

				local pitch =
					(basePitch * (0.2 + alpha))
					+ sway * 0.2

				local yaw =
					(baseYaw * (0.2 + alpha))
					+ jitterRotYaw

				-- Compact spacing remains driven by the new step
				local target =
					currentBeak
					* CFrame.Angles(
						pitch,
						yaw,
						jitterRotRoll
					)
					* CFrame.new(-fwd * dist)
					* CFrame.new(jitterPos)

				-- Smooth connected movement
				local current = p:GetPivot()

				p:PivotTo(
					current:Lerp(target, 0.18)
				)
			end

			task.wait(UPDATE_DT)
		end
	end)
end

local function clearOld()
	for _, inst in ipairs(workspace:GetChildren()) do
		if inst:IsA("Model")
			and inst.Name == ("ClientPelican_" .. player.Name) then

			inst:Destroy()
		end
	end
end

local function start()
	clearOld()

	local pelican = clonePelican()

	if not pelican then
		return
	end

	buildNeck(pelican)
end

if player.Character then
	start()
end

player.CharacterAdded:Connect(function()
	task.wait(0.2)
	start()
end)
