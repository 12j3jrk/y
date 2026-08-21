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

-- =========================================================
-- TUNING
-- =========================================================

local PELICAN_SCALE = 20
local PENGUIN_SCALE = 10

local NECK_COUNT = 53
local NECK_LENGTH = 250

local UPDATE_DT = 0.02

-- Motion
local INSANE_BASE_SPEED = 4.0
local ROT_INSANE_STRENGTH = 3.5
local SWAY_STRENGTH = 1.18

-- =========================================================
-- FADE SETTINGS
-- =========================================================

-- Last 10 penguins are used for the fade.
-- Penguin #44 = 0 transparency
-- Penguin #53 = 1 transparency
local FADE_COUNT = 10

-- =========================================================
-- SPACING SETTINGS
-- =========================================================

-- Keeps the penguins from bunching together toward the end.
-- 1 = normal spacing
-- Higher = more separation toward the tail
local TAIL_SPACING_BOOST = 1.35

-- Small overall spacing multiplier.
local BASE_SPACING_MULTIPLIER = 1.05

-- =========================================================
-- BLACK MODEL
-- =========================================================

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

-- =========================================================
-- TRANSPARENCY
-- =========================================================

local function setModelTransparency(model, transparency)
	transparency = math.clamp(transparency, 0, 1)

	for _, inst in ipairs(model:GetDescendants()) do
		if inst:IsA("BasePart") then
			inst.Transparency = transparency
		elseif inst:IsA("Decal") then
			inst.Transparency = 1
		end
	end
end

-- =========================================================
-- BEAK POSITION
-- =========================================================

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

-- =========================================================
-- MODEL SCALING
-- =========================================================

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

-- =========================================================
-- PENGUIN SIZE ESTIMATION
-- =========================================================

local function estimatePenguinSegmentStep(penguinTemplateClone)
	local _, size = penguinTemplateClone:GetBoundingBox()

	local step = math.max(
		1,
		(size.Y + size.Z) * 0.5
	)

	return step
end

-- =========================================================
-- CREATE PELICAN
-- =========================================================

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

	pelican:PivotTo(hrp.CFrame)

	return pelican
end

-- =========================================================
-- BUILD PENGUIN NECK
-- =========================================================

local function buildNeck(pelican)

	local container = Instance.new("Folder")
	container.Name = "ClientPenguinNeckStack"
	container.Parent = pelican

	local beakCF = getBeakCFrame(pelican)

	-- =====================================================
	-- CALCULATE PENGUIN SIZE
	-- =====================================================

	local temp = PenguinTemplate:Clone()

	setBlack(temp)
	scaleModel(temp, PENGUIN_SCALE)

	local segStep = estimatePenguinSegmentStep(temp)

	temp:Destroy()

	-- =====================================================
	-- BASE SPACING
	-- =====================================================

	local desiredTotal = NECK_LENGTH

	local currentTotal =
		segStep * (NECK_COUNT - 1)

	local lengthScale =
		(currentTotal > 0)
		and (desiredTotal / currentTotal)
		or 1

	local step =
		segStep
		* lengthScale
		* BASE_SPACING_MULTIPLIER

	-- =====================================================
	-- CREATE PENGUINS
	-- =====================================================

	local penguins = {}

	for i = 1, NECK_COUNT do

		local p = PenguinTemplate:Clone()

		p.Name = ("Penguin_%02d"):format(i)
		p.Parent = container

		setBlack(p)
		scaleModel(p, PENGUIN_SCALE)

		-- =============================================
		-- PROGRESS ALONG THE NECK
		-- =============================================

		local alpha =
			(i - 1)
			/ math.max(1, NECK_COUNT - 1)

		-- =============================================
		-- EXTRA TAIL SPACING
		--
		-- The farther toward the end we go,
		-- the more separation is added.
		-- This prevents the final bunch from
		-- collapsing into each other.
		-- =============================================

		local spacingMultiplier =
			1 + (alpha * TAIL_SPACING_BOOST)

		-- Use cumulative-style spacing.
		-- This makes the tail progressively spread out.
		local dist =
			step
			* (i - 1)
			* (
				1
				+ (
					(alpha * alpha)
					* TAIL_SPACING_BOOST
				)
			)

		-- =============================================
		-- FADE
		--
		-- Last 10:
		-- 44 = 0
		-- 45 = ~0.11
		-- 46 = ~0.22
		-- ...
		-- 52 = ~0.89
		-- 53 = 1
		-- =============================================

		local transparency = 0

		local fadeStart =
			NECK_COUNT - FADE_COUNT

		if i >= fadeStart then

			local fadeAlpha =
				(i - fadeStart)
				/ math.max(1, FADE_COUNT - 1)

			transparency =
				math.clamp(fadeAlpha, 0, 1)
		end

		setModelTransparency(p, transparency)

		-- =============================================
		-- INITIAL POSITION
		-- =============================================

		local forward = beakCF.LookVector

		local targetCF =
			beakCF
			* CFrame.new(-forward * dist)

		p:PivotTo(targetCF)

		table.insert(penguins, p)
	end

	-- =====================================================
	-- CONNECTED ANIMATION
	-- =====================================================

	task.spawn(function()

		local t0 = os.clock()

		while pelican.Parent do

			local t = os.clock() - t0

			local currentBeak =
				getBeakCFrame(pelican)

			local fwd =
				currentBeak.LookVector

			local right =
				currentBeak.RightVector

			local up =
				currentBeak.UpVector

			-- =============================================
			-- BASE MOTION
			-- =============================================

			local baseYaw =
				math.sin(
					t
					* INSANE_BASE_SPEED
					* 1.1
				)
				* 0.7

			local basePitch =
				math.cos(
					t
					* INSANE_BASE_SPEED
					* 0.9
				)
				* 0.5

			-- =============================================
			-- MOVE EACH PENGUIN
			-- =============================================

			for i, p in ipairs(penguins) do

				if not p.Parent then
					break
				end

				local alpha =
					(i - 1)
					/ math.max(1, NECK_COUNT - 1)

				-- Same spacing formula used during creation.
				local dist =
					step
					* (i - 1)
					* (
						1
						+ (
							(alpha * alpha)
							* TAIL_SPACING_BOOST
						)
					)

				-- =========================================
				-- GENTLE SIDE MOVEMENT
				--
				-- No random positional jitter here.
				-- That was what caused the penguins
				-- to visually jumble together.
				-- =========================================

				local sway =
					math.sin(
						t
						* (
							INSANE_BASE_SPEED
							* 0.8
						)
						+ i * 0.35
					)
					* SWAY_STRENGTH
					* (0.05 + alpha)

				-- =========================================
				-- ROTATION
				-- =========================================

				local pitch =
					(
						basePitch
						* (0.2 + alpha)
					)
					+ sway * 0.2

				local yaw =
					(
						baseYaw
						* (0.2 + alpha)
					)

				local roll =
					math.cos(
						t
						* INSANE_BASE_SPEED
						* 1.2
						+ i * 0.18
					)
					* (
						ROT_INSANE_STRENGTH
						* 0.02
						* (0.2 + alpha)
					)

				-- =========================================
				-- VERY SMALL CONTROLLED SIDE SWAY
				-- =========================================

				local sideSway =
					right
					* math.sin(
						t * 1.6
						+ i * 0.25
					)
					* (
						0.15
						* alpha
					)

				-- =========================================
				-- TARGET
				-- =========================================

				local target =
					currentBeak
					* CFrame.Angles(
						pitch,
						yaw,
						roll
					)
					* CFrame.new(
						-fwd * dist
					)
					* CFrame.new(
						sideSway
					)

				-- =========================================
				-- SMOOTH MOVEMENT
				-- =========================================

				local current =
					p:GetPivot()

				p:PivotTo(
					current:Lerp(
						target,
						0.18
					)
				)
			end

			task.wait(UPDATE_DT)
		end
	end)
end

-- =========================================================
-- CLEAR OLD PELICAN
-- =========================================================

local function clearOld()

	for _, inst in ipairs(workspace:GetChildren()) do

		if inst:IsA("Model")
			and inst.Name == ("ClientPelican_" .. player.Name) then

			inst:Destroy()
		end
	end
end

-- =========================================================
-- START
-- =========================================================

local function start()

	clearOld()

	local pelican =
		clonePelican()

	if not pelican then
		return
	end

	buildNeck(pelican)
end

-- =========================================================
-- INITIAL SPAWN
-- =========================================================

if player.Character then
	start()
end

-- =========================================================
-- RESPAWN
-- =========================================================

player.CharacterAdded:Connect(function()

	task.wait(0.2)

	start()
end)
