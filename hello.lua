-- StarterPlayerScripts > LocalScript

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Birds = ReplicatedStorage:WaitForChild("Birds")

local PelicanTemplate = Birds:WaitForChild("Pelican")
local PenguinTemplate = Birds:WaitForChild("PenguinChick")

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local BEAK_NAME = "Beak2"
local FALLBACK_TO_MODEL_PIVOT = true

local PELICAN_SCALE = 20
local PENGUIN_SCALE = 10

local NECK_COUNT = 53
local NECK_LENGTH = 250

-- Slightly more space between each penguin.
-- Increase this if you want them even more separated.
local PENGUIN_SPACING = 1.18

-- Very slow "giant snail / elephant" movement.
local SNAIL_SPEED = 0.12

-- How much the giant creature gently sways.
local SNAIL_SWAY = 0.35

-- How much the neck follows the slow movement.
local NECK_SWAY = 0.45

local UPDATE_DT = 0.03

--------------------------------------------------
-- BLACK MODEL
--------------------------------------------------

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

--------------------------------------------------
-- GET BEAK
--------------------------------------------------

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

--------------------------------------------------
-- SCALE MODEL
--------------------------------------------------

local function scaleModel(model, scale)
	local pivot = model:GetPivot()

	for _, inst in ipairs(model:GetDescendants()) do
		if inst:IsA("BasePart") then
			local relativePosition =
				pivot:PointToObjectSpace(inst.Position)

			inst.Size = inst.Size * scale

			inst.CFrame =
				pivot
				* CFrame.new(relativePosition * scale)
				* (inst.CFrame - inst.CFrame.Position)
		end
	end
end

--------------------------------------------------
-- ESTIMATE PENGUIN SIZE
--------------------------------------------------

local function estimatePenguinSegmentStep(model)
	local _, size = model:GetBoundingBox()

	local step = math.max(
		1,
		(size.Y + size.Z) * 0.5
	)

	return step
end

--------------------------------------------------
-- CREATE PELICAN
--------------------------------------------------

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

	pelican.Name =
		"ClientPelican_" .. player.Name

	pelican.Parent = workspace

	setBlack(pelican)
	scaleModel(pelican, PELICAN_SCALE)

	pelican:PivotTo(hrp.CFrame)

	return pelican
end

--------------------------------------------------
-- BUILD PENGUIN NECK
--------------------------------------------------

local function buildNeck(pelican)

	local container = Instance.new("Folder")

	container.Name =
		"ClientPenguinNeckStack"

	container.Parent = pelican

	--------------------------------------------------
	-- BEAK DIRECTION
	--------------------------------------------------

	local beakCF = getBeakCFrame(pelican)

	local forward = beakCF.LookVector

	--------------------------------------------------
	-- FIND BASE PENGUIN SPACING
	--------------------------------------------------

	local temp =
		PenguinTemplate:Clone()

	setBlack(temp)

	scaleModel(
		temp,
		PENGUIN_SCALE
	)

	local baseStep =
		estimatePenguinSegmentStep(temp)

	temp:Destroy()

	--------------------------------------------------
	-- CALCULATE LENGTH
	--------------------------------------------------

	local desiredTotal =
		NECK_LENGTH

	local currentTotal =
		baseStep * (NECK_COUNT - 1)

	local lengthScale =
		(currentTotal > 0)
		and (desiredTotal / currentTotal)
		or 1

	--------------------------------------------------
	-- EXTRA SPACING
	--------------------------------------------------

	local step =
		baseStep
		* lengthScale
		* PENGUIN_SPACING

	--------------------------------------------------
	-- CREATE PENGUINS
	--------------------------------------------------

	local penguins = {}

	for i = 1, NECK_COUNT do

		local penguin =
			PenguinTemplate:Clone()

		penguin.Name =
			("Penguin_%02d"):format(i)

		penguin.Parent =
			container

		setBlack(penguin)

		scaleModel(
			penguin,
			PENGUIN_SCALE
		)

		--------------------------------------------------
		-- EACH PENGUIN IS SLIGHTLY MORE SEPARATED
		--------------------------------------------------

		local distance =
			step * (i - 1)

		local targetCF =
			beakCF
			* CFrame.new(-forward * distance)

		penguin:PivotTo(targetCF)

		table.insert(
			penguins,
			penguin
		)
	end

	--------------------------------------------------
	-- SNAIL-LIKE MOVEMENT
	--------------------------------------------------

	task.spawn(function()

		local startTime =
			os.clock()

		while pelican.Parent do

			local elapsed =
				os.clock() - startTime

			--------------------------------------------------
			-- VERY SLOW TIME
			--------------------------------------------------

			local slowTime =
				elapsed * SNAIL_SPEED

			--------------------------------------------------
			-- CURRENT BEAK
			--------------------------------------------------

			local currentBeak =
				getBeakCFrame(pelican)

			local fwd =
				currentBeak.LookVector

			local right =
				currentBeak.RightVector

			local up =
				currentBeak.UpVector

			--------------------------------------------------
			-- GIANT SNAIL SWAY
			--------------------------------------------------

			local sideways =
				math.sin(slowTime)
				* SNAIL_SWAY

			local vertical =
				math.sin(slowTime * 0.7)
				* (SNAIL_SWAY * 0.25)

			--------------------------------------------------
			-- VERY SLOW BODY CREEP
			--------------------------------------------------

			local forwardCreep =
				(math.sin(slowTime * 0.45) * 0.5)

			--------------------------------------------------
			-- PELICAN MOVEMENT
			--------------------------------------------------

			local pelicanOffset =
				right * sideways
				+ up * vertical
				+ fwd * forwardCreep

			local pelicanTarget =
				currentBeak
				+ pelicanOffset

			--------------------------------------------------
			-- MOVE PELICAN SLOWLY
			--------------------------------------------------

			local currentPelican =
				pelican:GetPivot()

			local newPelican =
				currentPelican:Lerp(
					pelicanTarget,
					0.008
				)

			pelican:PivotTo(
				newPelican
			)

			--------------------------------------------------
			-- UPDATE BEAK AFTER BODY MOVEMENT
			--------------------------------------------------

			local animatedBeak =
				getBeakCFrame(pelican)

			local animatedForward =
				animatedBeak.LookVector

			local animatedRight =
				animatedBeak.RightVector

			local animatedUp =
				animatedBeak.UpVector

			--------------------------------------------------
			-- MOVE EACH PENGUIN
			--------------------------------------------------

			for i, penguin in ipairs(penguins) do

				if not penguin.Parent then
					break
				end

				local alpha =
					(i - 1)
					/ math.max(
						1,
						NECK_COUNT - 1
					)

				local distance =
					step * (i - 1)

				--------------------------------------------------
				-- SNAIL-LIKE WAVE THROUGH THE NECK
				--------------------------------------------------

				local wave =
					math.sin(
						slowTime
						- alpha * 2.5
					)

				local waveSide =
					wave
					* NECK_SWAY
					* alpha

				local waveUp =
					math.sin(
						slowTime * 0.8
						- alpha * 2
					)
					* NECK_SWAY
					* 0.25
					* alpha

				--------------------------------------------------
				-- SLIGHTLY CURVE THE NECK
				--------------------------------------------------

				local curveOffset =
					animatedRight
					* waveSide
					+
					animatedUp
					* waveUp

				--------------------------------------------------
				-- KEEP PENGUINS SPACED
				--------------------------------------------------

				local target =
					animatedBeak
					* CFrame.new(
						-animatedForward
						* distance
					)
					* CFrame.new(
						curveOffset
					)

				--------------------------------------------------
				-- VERY SLOW FOLLOWING
				--------------------------------------------------

				local current =
					penguin:GetPivot()

				penguin:PivotTo(
					current:Lerp(
						target,
						0.035
					)
				)
			end

			task.wait(UPDATE_DT)
		end
	end)
end

--------------------------------------------------
-- CLEAR OLD VERSION
--------------------------------------------------

local function clearOld()

	for _, inst in ipairs(
		workspace:GetChildren()
	) do

		if
			inst:IsA("Model")
			and
			inst.Name ==
			("ClientPelican_" .. player.Name)
		then
			inst:Destroy()
		end
	end
end

--------------------------------------------------
-- START
--------------------------------------------------

local function start()

	clearOld()

	local pelican =
		clonePelican()

	if not pelican then
		return
	end

	buildNeck(pelican)
end

--------------------------------------------------
-- INITIAL SPAWN
--------------------------------------------------

if player.Character then
	start()
end

--------------------------------------------------
-- RESPAWN
--------------------------------------------------

player.CharacterAdded:Connect(function()

	task.wait(0.2)

	start()
end)
