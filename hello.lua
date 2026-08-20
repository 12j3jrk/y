-- StarterPlayerScripts > LocalScript

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Birds = ReplicatedStorage:WaitForChild("Birds")

local PelicanTemplate = Birds:WaitForChild("Pelican")

--// Main settings
local PELICAN_SCALE = 20

-- Cylinder settings
local CYLINDER_RADIUS = 5
local CYLINDER_HEIGHT = 10
local CYLINDER_GAP = 0
local CYLINDER_ADD_DELAY = 0.08

-- Set this to nil for a truly unlimited number of cylinders.
-- Keeping a limit prevents the client from eventually creating too many Parts.
local MAX_CYLINDERS = 350

--// Fade settings
local FADE_START_DELAY = 1.5
local FADE_TIME = 2.5

--// Extremely slow movement
local SNAIL_MOVE_SPEED = 0.006
local SNAIL_SWAY_AMOUNT = 0.08
local SNAIL_ROTATION_AMOUNT = 0.002

local BEAK_NAME = "Beak2"
local FALLBACK_TO_MODEL_PIVOT = true

local function setBlack(model)
	for _, inst in ipairs(model:GetDescendants()) do
		if inst:IsA("BasePart") then
			inst.Color = Color3.new(0, 0, 0)
			inst.Material = Enum.Material.SmoothPlastic
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
			local relativePosition = pivot:PointToObjectSpace(inst.Position)
			local relativeRotation = inst.CFrame - inst.CFrame.Position

			inst.Size *= scale
			inst.CFrame =
				pivot
				* CFrame.new(relativePosition * scale)
				* relativeRotation
		end
	end
end

local function createCylinder()
	local cylinder = Instance.new("Part")

	cylinder.Name = "BlackCylinder"
	cylinder.Shape = Enum.PartType.Cylinder

	-- Roblox cylinders use their X axis as their length axis.
	cylinder.Size = Vector3.new(
		CYLINDER_HEIGHT,
		CYLINDER_RADIUS * 2,
		CYLINDER_RADIUS * 2
	)

	cylinder.Color = Color3.new(0, 0, 0)
	cylinder.Material = Enum.Material.SmoothPlastic
	cylinder.Transparency = 0

	cylinder.Anchored = true
	cylinder.CanCollide = false
	cylinder.CanTouch = false
	cylinder.CanQuery = false

	return cylinder
end

local function fadeAndDestroyCylinder(cylinder)
	task.delay(FADE_START_DELAY, function()
		if not cylinder or not cylinder.Parent then
			return
		end

		local tween = TweenService:Create(
			cylinder,
			TweenInfo.new(
				FADE_TIME,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut
			),
			{
				Transparency = 1
			}
		)

		tween:Play()
		tween.Completed:Wait()

		if cylinder and cylinder.Parent then
			cylinder:Destroy()
		end
	end)
end

local function clonePelican()
	local character = player.Character
	if not character then
		return nil
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil
	end

	local pelican = PelicanTemplate:Clone()
	pelican.Name = "ClientPelican_" .. player.Name
	pelican.Parent = workspace

	setBlack(pelican)
	scaleModel(pelican, PELICAN_SCALE)
	pelican:PivotTo(hrp.CFrame)

	return pelican
end

local function buildInfiniteCylinderNeck(pelican)
	local neckFolder = Instance.new("Folder")
	neckFolder.Name = "InfiniteBlackCylinderNeck"
	neckFolder.Parent = pelican

	local cylinders = {}
	local totalDistance = 0
	local running = true

	-- Adds one cylinder at a time forever.
	task.spawn(function()
		while running and pelican.Parent do
			local cylinder = createCylinder()
			cylinder.Parent = neckFolder

			table.insert(cylinders, cylinder)

			totalDistance += CYLINDER_HEIGHT + CYLINDER_GAP

			fadeAndDestroyCylinder(cylinder)

			-- Remove the oldest reference after it has faded.
			if MAX_CYLINDERS and #cylinders > MAX_CYLINDERS then
				local oldest = table.remove(cylinders, 1)

				if oldest and oldest.Parent then
					oldest:Destroy()
				end
			end

			task.wait(CYLINDER_ADD_DELAY)
		end
	end)

	-- Slowly animate the pelican and every cylinder together.
	task.spawn(function()
		local startTime = os.clock()

		while running and pelican.Parent do
			local elapsed = os.clock() - startTime
			local beakCFrame = getBeakCFrame(pelican)

			local forward = beakCFrame.LookVector
			local right = beakCFrame.RightVector
			local up = beakCFrame.UpVector

			-- Almost unnoticeably slow motion.
			local sway =
				math.sin(elapsed * SNAIL_MOVE_SPEED)
				* SNAIL_SWAY_AMOUNT

			local verticalSway =
				math.cos(elapsed * SNAIL_MOVE_SPEED * 0.7)
				* SNAIL_SWAY_AMOUNT

			local tinyRotation =
				math.sin(elapsed * SNAIL_MOVE_SPEED)
				* SNAIL_ROTATION_AMOUNT

			-- Move the entire pelican very slowly.
			local pelicanPivot = pelican:GetPivot()

			pelican:PivotTo(
				pelicanPivot
				* CFrame.new(
					right * (sway * 0.01)
					+ up * (verticalSway * 0.01)
				)
				* CFrame.Angles(0, tinyRotation, 0)
			)

			-- Re-read the beak after moving the pelican so the neck follows it.
			beakCFrame = getBeakCFrame(pelican)
			forward = beakCFrame.LookVector
			right = beakCFrame.RightVector
			up = beakCFrame.UpVector

			local distanceFromBeak = 0

			for index, cylinder in ipairs(cylinders) do
				if cylinder and cylinder.Parent then
					-- The cylinders are placed directly behind one another.
					-- No random offsets means they do not swarm toward one point.
					local cylinderPosition =
						beakCFrame.Position
						- forward * (distanceFromBeak + CYLINDER_HEIGHT / 2)

					local targetCFrame =
						CFrame.lookAt(
							cylinderPosition,
							cylinderPosition - forward,
							up
						)
						* CFrame.Angles(0, math.rad(90), 0)

					-- Slightly bend the entire neck, but extremely slowly.
					local bend =
						math.sin(
							elapsed * SNAIL_MOVE_SPEED
							+ index * 0.025
						)
						* 0.001

					targetCFrame *= CFrame.Angles(0, bend, 0)

					-- Soft movement so every cylinder follows the pelican.
					cylinder.CFrame = cylinder.CFrame:Lerp(
						targetCFrame,
						0.035
					)

					distanceFromBeak += CYLINDER_HEIGHT + CYLINDER_GAP
				end
			end

			RunService.RenderStepped:Wait()
		end
	end)

	pelican.AncestryChanged:Connect(function(_, parent)
		if not parent then
			running = false
		end
	end)
end

local function clearOldPelican()
	local oldName = "ClientPelican_" .. player.Name

	for _, inst in ipairs(workspace:GetChildren()) do
		if inst:IsA("Model") and inst.Name == oldName then
			inst:Destroy()
		end
	end
end

local function start()
	clearOldPelican()

	local pelican = clonePelican()
	if not pelican then
		return
	end

	buildInfiniteCylinderNeck(pelican)
end

if player.Character then
	start()
end

player.CharacterAdded:Connect(function()
	task.wait(0.2)
	start()
end)
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
			-- Reposition translation; keep orientation
			inst.CFrame = pivot * CFrame.new(relPos * scale) * (inst.CFrame - inst.CFrame.Position)
		end
	end
end

local function estimatePenguinSegmentStep(penguinTemplateClone)
	-- Use bounding box depth along forward-ish axis approximation.
	-- We'll just use its overall bounding box size magnitude to get a step.
	local cf, size = penguinTemplateClone:GetBoundingBox()
	-- A single scalar step that tends to prevent gaps.
	-- Since we don't know exact neck direction, we use size.Z as a heuristic.
	local step = math.max(1, (size.Y + size.Z) * 0.5)
	return step
end

local function clonePelican()
	local char = player.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

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

	-- Clone a temp penguin to estimate step so the stack doesn't leave gaps
	local temp = PenguinTemplate:Clone()
	setBlack(temp)
	scaleModel(temp, PENGUIN_SCALE)
	local segStep = estimatePenguinSegmentStep(temp)
	temp:Destroy()

	-- Decide overall length step distribution:
	-- If NECK_LENGTH is shorter/longer than segStep*(count-1), we adjust.
	local desiredTotal = NECK_LENGTH
	local currentTotal = segStep * (NECK_COUNT - 1)
	local lengthScale = (currentTotal > 0) and (desiredTotal / currentTotal) or 1
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
		local targetCF = beakCF * CFrame.new(-forward * dist)
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

			-- fast jitter seed-ish changes
			local baseYaw = math.sin(t * INSANE_BASE_SPEED * 1.1) * (0.6 + math.random() * 0.6)
			local basePitch = math.cos(t * INSANE_BASE_SPEED * 0.9) * (0.4 + math.random() * 0.6)

			-- For each segment, keep it anchored and still connected (no gaps)
			for i, p in ipairs(penguins) do
				if not p.Parent then break end

				local alpha = (i - 1) / math.max(1, NECK_COUNT - 1)
				local dist = step * (i - 1)

				-- random shake (stronger for far segments)
				local randX = (math.random() - 0.5) * 2
				local randY = (math.random() - 0.5) * 2
				local randZ = (math.random() - 0.5) * 2

				local jitterPos = (right * randX + up * randY) * (JITTER_STRENGTH * (0.1 + alpha))
				local jitterRotYaw = (math.sin(t * INSANE_BASE_SPEED + i * 0.25) + randZ) * (ROT_INSANE_STRENGTH * 0.02 * (0.2 + alpha))
				local jitterRotRoll = (math.cos(t * INSANE_BASE_SPEED * 1.2 + i * 0.18) + randY) * (ROT_INSANE_STRENGTH * 0.02 * (0.2 + alpha))

				-- curved/twisting neck
				local sway = math.sin(t * (INSANE_BASE_SPEED * 0.8) + i * 0.35) * SWAY_STRENGTH * (0.05 + alpha)
				local pitch = (basePitch * (0.2 + alpha)) + sway * 0.2
				local yaw = (baseYaw * (0.2 + alpha)) + jitterRotYaw

				-- keep spacing exact -> no gaps by using step-driven placement only
				local target = currentBeak
					* CFrame.Angles(pitch, yaw, jitterRotRoll)
					* CFrame.new(-fwd * dist)
					* CFrame.new(jitterPos)

				-- fast smoothing so it looks chaotic but attached
				local current = p:GetPivot()
				p:PivotTo(current:Lerp(target, 0.18))
			end

			task.wait(UPDATE_DT)
		end
	end)
end

local function clearOld()
	for _, inst in ipairs(workspace:GetChildren()) do
		if inst:IsA("Model") and inst.Name == ("ClientPelican_" .. player.Name) then
			inst:Destroy()
		end
	end
end

local function start()
	clearOld()
	local pelican = clonePelican()
	if not pelican then return end
	buildNeck(pelican)
end

if player.Character then
	start()
end

player.CharacterAdded:Connect(function()
	task.wait(0.2)
	start()
end)
