-- StarterPlayerScripts > LocalScript

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Birds = ReplicatedStorage:WaitForChild("Birds")

local PelicanTemplate = Birds:WaitForChild("Pelican")

-- Try to match the beak part/attachment name inside the Pelican model
local BEAK_NAME = "Beak2"
local FALLBACK_TO_MODEL_PIVOT = true

-- Tuning
local PELICAN_SCALE = 20

local NECK_COUNT = 53
local NECK_LENGTH = 250

-- Cylinder settings
local CYLINDER_DIAMETER = 8
local CYLINDER_LENGTH = 12

local UPDATE_DT = 0.02

-- "Insane" motion tuning
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

			inst.CFrame =
				pivot
				* CFrame.new(relPos * scale)
				* (inst.CFrame - inst.CFrame.Position)
		end
	end
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


-- Creates a cylinder segment
local function createCylinder(name, parent)
	local cylinder = Instance.new("Part")

	cylinder.Name = name
	cylinder.Shape = Enum.PartType.Cylinder

	cylinder.Size = Vector3.new(
		CYLINDER_DIAMETER,
		CYLINDER_LENGTH,
		CYLINDER_DIAMETER
	)

	cylinder.Color = Color3.new(0, 0, 0)
	cylinder.Material = Enum.Material.SmoothPlastic

	cylinder.Anchored = true
	cylinder.CanCollide = false
	cylinder.CanTouch = false
	cylinder.CanQuery = false

	cylinder.Parent = parent

	return cylinder
end


local function buildNeck(pelican)

	local container = Instance.new("Folder")
	container.Name = "ClientCylinderNeckStack"
	container.Parent = pelican

	local beakCF = getBeakCFrame(pelican)
	local forward = beakCF.LookVector

	-- Spread the cylinders evenly across the desired neck length
	local step

	if NECK_COUNT > 1 then
		step = NECK_LENGTH / (NECK_COUNT - 1)
	else
		step = NECK_LENGTH
	end

	local cylinders = {}

	-- Create cylinders
	for i = 1, NECK_COUNT do

		local cylinder = createCylinder(
			("Cylinder_%02d"):format(i),
			container
		)

		local dist = step * (i - 1)

		local position =
			beakCF.Position
			- forward * dist

		-- Roblox cylinders point along their Y axis by default.
		-- Rotate them so their long axis follows the neck direction.
		local targetCF =
			CFrame.lookAt(position, position + forward)
			* CFrame.Angles(math.rad(90), 0, 0)

		cylinder.CFrame = targetCF

		table.insert(cylinders, cylinder)
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

			-- Fast jitter
			local baseYaw =
				math.sin(t * INSANE_BASE_SPEED * 1.1)
				* (0.6 + math.random() * 0.6)

			local basePitch =
				math.cos(t * INSANE_BASE_SPEED * 0.9)
				* (0.4 + math.random() * 0.6)


			for i, cylinder in ipairs(cylinders) do

				if not cylinder.Parent then
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


				local position =
					currentBeak.Position
					- fwd * dist
					+ jitterPos


				local target =
					CFrame.lookAt(
						position,
						position + fwd
					)
					* CFrame.Angles(
						math.rad(90) + pitch,
						yaw,
						jitterRotRoll
					)


				-- Fast smoothing
				cylinder.CFrame =
					cylinder.CFrame:Lerp(
						target,
						0.18
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
