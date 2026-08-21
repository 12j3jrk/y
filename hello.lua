-- StarterPlayerScripts > LocalScript

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Birds = ReplicatedStorage:WaitForChild("Birds")

local PelicanTemplate = Birds:WaitForChild("Pelican")
local PenguinTemplate = Birds:WaitForChild("PenguinChick")

-- =========================================================
-- SETTINGS
-- =========================================================

local BEAK_NAME = "Beak2"
local FALLBACK_TO_MODEL_PIVOT = true

local PELICAN_SCALE = 20
local PENGUIN_SCALE = 10

local NECK_COUNT = 200

-- MUCH SHORTER STACK
-- Lower = penguins sit much closer together.
local NECK_LENGTH = 125

local UPDATE_DT = 0.02

-- Movement
local INSANE_BASE_SPEED = 4.0
local ROT_INSANE_STRENGTH = 3.5
local SWAY_STRENGTH = 1.18

-- =========================================================
-- FADE
-- =========================================================

-- Last 10 penguins fade from:
-- 0 transparency -> 1 transparency
--
-- 51 = 0
-- 52 = ~0.11
-- 53 = ~0.22
-- ...
-- 59 = ~0.89
-- 60 = 1
local FADE_COUNT = 10

-- =========================================================
-- STACK TIGHTNESS
-- =========================================================

-- Additional multiplier after calculating the compact
-- total length. This makes the actual penguin-to-penguin
-- gap even smaller.
local STACK_TIGHTNESS = 0.72

-- Keep the very end from collapsing into one another.
-- This is intentionally small because the stack is supposed
-- to look extremely tight.
local TAIL_SPACING_BOOST = 0.10

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

	local found =
		model:FindFirstChild(BEAK_NAME, true)

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
-- SCALE MODEL
-- =========================================================

local function scaleModel(model, scale)

	local pivot = model:GetPivot()

	for _, inst in ipairs(model:GetDescendants()) do

		if inst:IsA("BasePart") then

			local relPos =
				pivot:PointToObjectSpace(
					inst.Position
				)

			inst.Size =
				inst.Size * scale

			inst.CFrame =
				pivot
				* CFrame.new(relPos * scale)
				* (inst.CFrame - inst.CFrame.Position)
		end
	end
end

-- =========================================================
-- PENGUIN SIZE
-- =========================================================

local function estimatePenguinSegmentStep(model)

	local _, size =
		model:GetBoundingBox()

	local step =
		math.max(
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

	local hrp =
		char:FindFirstChild("HumanoidRootPart")

	if not hrp then
		return nil
	end

	local pelican =
		PelicanTemplate:Clone()

	pelican.Name =
		"ClientPelican_" .. player.Name

	pelican.Parent = workspace

	setBlack(pelican)

	scaleModel(
		pelican,
		PELICAN_SCALE
	)

	pelican:PivotTo(
		hrp.CFrame
	)

	return pelican
end

-- =========================================================
-- BUILD PENGUIN STACK
-- =========================================================

local function buildNeck(pelican)

	local container =
		Instance.new("Folder")

	container.Name =
		"ClientPenguinNeckStack"

	container.Parent =
		pelican

	local beakCF =
		getBeakCFrame(pelican)

	local forward =
		beakCF.LookVector

	-- =====================================================
	-- ESTIMATE PENGUIN SIZE
	-- =====================================================

	local temp =
		PenguinTemplate:Clone()

	setBlack(temp)

	scaleModel(
		temp,
		PENGUIN_SCALE
	)

	local segStep =
		estimatePenguinSegmentStep(temp)

	temp:Destroy()

	-- =====================================================
	-- COMPACT BASE STEP
	-- =====================================================

	local desiredTotal =
		NECK_LENGTH

	local currentTotal =
		segStep * (NECK_COUNT - 1)

	local lengthScale =

		(currentTotal > 0)
		and
		(desiredTotal / currentTotal)
		or
		1

	-- This is the important part:
	-- stack is intentionally compressed further.
	local step =
		segStep
		* lengthScale
		* STACK_TIGHTNESS

	-- =====================================================
	-- CREATE PENGUINS
	-- =====================================================

	local penguins = {}

	for i = 1, NECK_COUNT do

		local p =
			PenguinTemplate:Clone()

		p.Name =
			("Penguin_%02d"):format(i)

		p.Parent =
			container

		setBlack(p)

		scaleModel(
			p,
			PENGUIN_SCALE
		)

		-- =============================================
		-- STACK POSITION
		-- =============================================

		local alpha =
			(i - 1)
			/
			math.max(
				1,
				NECK_COUNT - 1
			)

		-- Tiny amount of extra separation toward
		-- the very end so the last few don't occupy
		-- the exact same space.
		local tailMultiplier =
			1
			+
			(
				alpha
				* alpha
				* TAIL_SPACING_BOOST
			)

		local dist =
			step
			* (i - 1)
			* tailMultiplier

		-- =============================================
		-- FADE LAST 10
		-- =============================================

		local transparency = 0

		local fadeStart =
			NECK_COUNT
			- FADE_COUNT

		if i >= fadeStart then

			local fadeAlpha =
				(i - fadeStart)
				/
				math.max(
					1,
					FADE_COUNT - 1
				)

			transparency =
				math.clamp(
					fadeAlpha,
					0,
					1
				)
		end

		setModelTransparency(
			p,
			transparency
		)

		-- =============================================
		-- INITIAL POSITION
		-- =============================================

		local targetCF =
			beakCF
			* CFrame.new(
				-forward * dist
			)

		p:PivotTo(
			targetCF
		)

		table.insert(
			penguins,
			p
		)
	end

	-- =====================================================
	-- ANIMATION
	-- =====================================================

	task.spawn(function()

		local t0 =
			os.clock()

		while pelican.Parent do

			local t =
				os.clock() - t0

			local currentBeak =
				getBeakCFrame(pelican)

			local fwd =
				currentBeak.LookVector

			-- =================================================
			-- BASE MOTION
			-- =================================================

			local baseYaw =
				math.sin(
					t
					* INSANE_BASE_SPEED
					* 1.1
				)
				* 0.6

			local basePitch =
				math.cos(
					t
					* INSANE_BASE_SPEED
					* 0.9
				)
				* 0.4

			-- =================================================
			-- EACH PENGUIN
			-- =================================================

			for i, p in ipairs(penguins) do

				if not p.Parent then
					break
				end

				local alpha =
					(i - 1)
					/
					math.max(
						1,
						NECK_COUNT - 1
					)

				-- Same compact spacing used when created.
				local tailMultiplier =
					1
					+
					(
						alpha
						* alpha
						* TAIL_SPACING_BOOST
					)

				local dist =
					step
					* (i - 1)
					* tailMultiplier

				-- =================================================
				-- CONTROLLED CURVE
				--
				-- No random positional movement.
				-- This keeps the super-short stack clean.
				-- =================================================

				local sway =
					math.sin(
						t
						*
						(
							INSANE_BASE_SPEED
							* 0.8
						)
						+
						i * 0.35
					)
					*
					SWAY_STRENGTH
					*
					(
						0.03
						+
						alpha * 0.08
					)

				local pitch =
					(
						basePitch
						*
						(0.2 + alpha)
					)
					+
					sway * 0.2

				local yaw =
					baseYaw
					*
					(0.2 + alpha)

				local roll =
					math.cos(
						t
						*
						INSANE_BASE_SPEED
						*
						1.2
						+
						i * 0.18
					)
					*
					(
						ROT_INSANE_STRENGTH
						*
						0.02
						*
						(0.2 + alpha)
					)

				-- =================================================
				-- TARGET
				-- =================================================

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

				-- =================================================
				-- SMOOTH MOVEMENT
				-- =================================================

				local current =
					p:GetPivot()

				p:PivotTo(
					current:Lerp(
						target,
						0.18
					)
				)
			end

			task.wait(
				UPDATE_DT
			)
		end
	end)
end

-- =========================================================
-- CLEAR OLD
-- =========================================================

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

	buildNeck(
		pelican
	)
end

-- =========================================================
-- INITIAL
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
