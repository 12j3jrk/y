-- StarterPlayerScripts > LocalScript

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Birds = ReplicatedStorage:WaitForChild("Birds")

local PelicanTemplate = Birds:WaitForChild("Ostrich")
local PenguinTemplate = Birds:WaitForChild("PenguinChick")

-- =========================================================
-- SETTINGS
-- =========================================================

local PELICAN_SCALE = 20
local PENGUIN_SCALE = 10

local NECK_COUNT = 240

-- Tight penguin stack
local NECK_LENGTH = 220

local UPDATE_DT = 0.02

-- Movement
local INSANE_BASE_SPEED = 4.0
local JITTER_STRENGTH = 3.5
local ROT_INSANE_STRENGTH = 3.5
local SWAY_STRENGTH = 1.18

-- Last 10 penguins fade
local FADE_COUNT = 10

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

		elseif inst:IsA("Texture") then

			inst.Transparency = 1
		end
	end
end

-- =========================================================
-- HIDE ANYTHING WITH "BEAK" IN ITS NAME
-- =========================================================

local function hideBeakObjects(model)

	for _, inst in ipairs(model:GetDescendants()) do

		local nameLower =
			string.lower(inst.Name)

		if string.find(
			nameLower,
			"beak",
			1,
			true
		) then

			-- Parts
			if inst:IsA("BasePart") then

				inst.Transparency = 1

			-- Decals
			elseif inst:IsA("Decal") then

				inst.Transparency = 1

			-- Textures
			elseif inst:IsA("Texture") then

				inst.Transparency = 1

			-- Particle emitters
			elseif inst:IsA("ParticleEmitter") then

				inst.Enabled = false

			-- Trails
			elseif inst:IsA("Trail") then

				inst.Enabled = false

			-- Beams
			elseif inst:IsA("Beam") then

				inst.Enabled = false
			end
		end
	end
end

-- =========================================================
-- TRANSPARENCY
-- =========================================================

local function setModelTransparency(
	model,
	transparency
)

	transparency =
		math.clamp(
			transparency,
			0,
			1
		)

	for _, inst in ipairs(
		model:GetDescendants()
	) do

		if inst:IsA("BasePart") then

			inst.Transparency =
				transparency

		elseif inst:IsA("Decal") then

			inst.Transparency =
				transparency

		elseif inst:IsA("Texture") then

			inst.Transparency =
				transparency
		end
	end
end

-- =========================================================
-- CORRECT MODEL SCALING
-- =========================================================

local function scaleModel(
	model,
	scale
)

	-- Roblox's built-in Model scaling
	-- preserves the model's proportions,
	-- joints, offsets, and internal layout.
	--
	-- This replaces the old manual part-by-part
	-- CFrame scaling that could distort the pelican.

	if model:IsA("Model") then

		model:ScaleTo(scale)

	end
end

-- =========================================================
-- FIND BEAK POSITION
-- =========================================================

local function getBeakCFrame(model)

	-- Prefer the old Beak2 reference if it exists.
	local found =
		model:FindFirstChild(
			"Beak2",
			true
		)

	if found then

		if found:IsA("Attachment") then

			return found.WorldCFrame

		elseif found:IsA("BasePart") then

			return found.CFrame
		end
	end

	-- If Beak2 was hidden but still exists,
	-- its CFrame is still usable.

	return model:GetPivot()
end

-- =========================================================
-- PENGUIN SIZE
-- =========================================================

local function estimatePenguinSegmentStep(
	model
)

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

	local char =
		player.Character

	if not char then
		return nil
	end

	local hrp =
		char:FindFirstChild(
			"HumanoidRootPart"
		)

	if not hrp then
		return nil
	end

	local pelican =
		PelicanTemplate:Clone()

	pelican.Name =
		"ClientPelican_"
		.. player.Name

	pelican.Parent =
		workspace

	-- =====================================================
	-- SCALE FIRST
	-- =====================================================

	scaleModel(
		pelican,
		PELICAN_SCALE
	)

	-- =====================================================
	-- APPEARANCE
	-- =====================================================

	setBlack(
		pelican
	)

	-- Hide EVERY object containing
	-- "beak" in its name.
	hideBeakObjects(
		pelican
	)

	-- =====================================================
	-- POSITION
	-- =====================================================

	pelican:PivotTo(
		hrp.CFrame
	)

	return pelican
end

-- =========================================================
-- BUILD PENGUIN STACK
-- =========================================================

local function buildNeck(
	pelican
)

	local container =
		Instance.new("Folder")

	container.Name =
		"ClientPenguinNeckStack"

	container.Parent =
		pelican

	local beakCF =
		getBeakCFrame(
			pelican
		)

	local forward =
		beakCF.LookVector

	-- =====================================================
	-- TEMPORARY PENGUIN
	-- =====================================================

	local temp =
		PenguinTemplate:Clone()

	temp.Parent =
		workspace

	scaleModel(
		temp,
		PENGUIN_SCALE
	)

	setBlack(
		temp
	)

	local segStep =
		estimatePenguinSegmentStep(
			temp
		)

	temp:Destroy()

	-- =====================================================
	-- COMPACT SPACING
	-- =====================================================

	local desiredTotal =
		NECK_LENGTH

	local currentTotal =
		segStep
		*
		(NECK_COUNT - 1)

	local lengthScale =

		(currentTotal > 0)
		and
		(
			desiredTotal
			/
			currentTotal
		)
		or
		1

	local step =
		segStep
		*
		lengthScale

	-- =====================================================
	-- CREATE PENGUINS
	-- =====================================================

	local penguins = {}

	for i = 1, NECK_COUNT do

		local p =
			PenguinTemplate:Clone()

		p.Name =
			("Penguin_%02d")
			:format(i)

		p.Parent =
			container

		-- Correct proportional scaling
		scaleModel(
			p,
			PENGUIN_SCALE
		)

		setBlack(
			p
		)

		-- Hide beak-named objects
		hideBeakObjects(
			p
		)

		-- =================================================
		-- POSITION
		-- =================================================

		local dist =
			step
			*
			(i - 1)

		local targetCF =

			beakCF

			*
			CFrame.new(
				-forward * dist
			)

		p:PivotTo(
			targetCF
		)

		-- =================================================
		-- FADE
		-- =================================================

		local fadeStart =
			NECK_COUNT
			-
			FADE_COUNT

		if i >= fadeStart then

			local fadeAlpha =

				(i - fadeStart)
				/
				math.max(
					1,
					FADE_COUNT - 1
				)

			setModelTransparency(
				p,
				math.clamp(
					fadeAlpha,
					0,
					1
				)
			)
		end

		table.insert(
			penguins,
			p
		)
	end

	-- =====================================================
	-- CONNECTED ANIMATION
	-- =====================================================

	task.spawn(function()

		local t0 =
			os.clock()

		while pelican.Parent do

			local t =
				os.clock()
				-
				t0

			local currentBeak =
				getBeakCFrame(
					pelican
				)

			local fwd =
				currentBeak.LookVector

			local right =
				currentBeak.RightVector

			local up =
				currentBeak.UpVector

			-- =================================================
			-- BASE MOTION
			-- =================================================

			local baseYaw =

				math.sin(
					t
					*
					INSANE_BASE_SPEED
					*
					1.1
				)
				*
				(
					0.6
					+
					math.random()
					*
					0.6
				)

			local basePitch =

				math.cos(
					t
					*
					INSANE_BASE_SPEED
					*
					0.9
				)
				*
				(
					0.4
					+
					math.random()
					*
					0.6
				)

			-- =================================================
			-- PENGUINS
			-- =================================================

			for i, p in ipairs(
				penguins
			) do

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

				local dist =

					step
					*
					(i - 1)

				-- =================================================
				-- RANDOM SHAKE
				-- =================================================

				local randX =
					(math.random() - 0.5)
					*
					2

				local randY =
					(math.random() - 0.5)
					*
					2

				local randZ =
					(math.random() - 0.5)
					*
					2

				local jitterPos =

					(
						right
						*
						randX
						+
						up
						*
						randY
					)
					*
					(
						JITTER_STRENGTH
						*
						(
							0.1
							+
							alpha
						)
					)

				local jitterRotYaw =

					(
						math.sin(
							t
							*
							INSANE_BASE_SPEED
							+
							i
							*
							0.25
						)
						+
						randZ
					)
					*
					(
						ROT_INSANE_STRENGTH
						*
						0.02
						*
						(
							0.2
							+
							alpha
						)
					)

				local jitterRotRoll =

					(
						math.cos(
							t
							*
							INSANE_BASE_SPEED
							*
							1.2
							+
							i
							*
							0.18
						)
						+
						randY
					)
					*
					(
						ROT_INSANE_STRENGTH
						*
						0.02
						*
						(
							0.2
							+
							alpha
						)
					)

				-- =================================================
				-- CURVE
				-- =================================================

				local sway =

					math.sin(
						t
						*
						(
							INSANE_BASE_SPEED
							*
							0.8
						)
						+
						i
						*
						0.35
					)
					*
					SWAY_STRENGTH
					*
					(
						0.05
						+
						alpha
					)

				local pitch =

					(
						basePitch
						*
						(
							0.2
							+
							alpha
						)
					)
					+
					sway
					*
					0.2

				local yaw =

					(
						baseYaw
						*
						(
							0.2
							+
							alpha
						)
					)
					+
					jitterRotYaw

				-- =================================================
				-- TARGET
				-- =================================================

				local target =

					currentBeak

					*
					CFrame.Angles(
						pitch,
						yaw,
						jitterRotRoll
					)

					*
					CFrame.new(
						-fwd
						*
						dist
					)

					*
					CFrame.new(
						jitterPos
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
-- CLEAR OLD PELICAN
-- =========================================================

local function clearOld()

	for _, inst in ipairs(
		workspace:GetChildren()
	) do

		if
			inst:IsA("Model")
			and
			inst.Name ==
			(
				"ClientPelican_"
				..
				player.Name
			)
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

player.CharacterAdded:Connect(
	function()

		task.wait(
			0.2
		)

		start()
	end
)
