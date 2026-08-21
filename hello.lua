-- StarterPlayerScripts > LocalScript

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Birds = ReplicatedStorage:WaitForChild("Birds")

local PelicanTemplate = Birds:WaitForChild("Pelican")

-- =========================================================
-- SETTINGS
-- =========================================================

local PELICAN_SCALE = 20
local NECK_SCALE = 10

-- Make the chain extremely long.
-- Increase this if you literally want more segments.
local NECK_SEGMENTS = 180

-- How slowly the neck moves.
local NECK_SPEED = 0.42

-- How much the neck bends.
local BEND_X = 0.055
local BEND_Y = 0.075
local BEND_Z = 0.035

-- How much movement travels down the neck.
local WAVE_LENGTH = 18

-- Smoothness.
local FOLLOW_SPEED = 4

-- =========================================================
-- NAME HIDING
-- =========================================================

local function shouldHide(inst)

	local name = string.lower(inst.Name)

	return
		string.find(name, "head", 1, true) ~= nil
		or
		string.find(name, "beak", 1, true) ~= nil
end

local function hideHeadAndBeak(model)

	for _, inst in ipairs(model:GetDescendants()) do

		if shouldHide(inst) then

			if inst:IsA("BasePart") then
				inst.Transparency = 1

			elseif inst:IsA("Decal") then
				inst.Transparency = 1

			elseif inst:IsA("Texture") then
				inst.Transparency = 1

			elseif inst:IsA("ParticleEmitter") then
				inst.Enabled = false

			elseif inst:IsA("Trail") then
				inst.Enabled = false

			elseif inst:IsA("Beam") then
				inst.Enabled = false
			end
		end
	end
end

-- =========================================================
-- BLACK
-- =========================================================

local function makeBlack(model)

	for _, inst in ipairs(model:GetDescendants()) do

		if inst:IsA("BasePart") then

			inst.Color = Color3.new(0, 0, 0)

			if inst.Material ~= Enum.Material.Neon then
				inst.Material = Enum.Material.SmoothPlastic
			end
		end
	end
end

-- =========================================================
-- SAFE MODEL SCALING
-- =========================================================

local function scaleModel(model, scale)

	if not model:IsA("Model") then
		return
	end

	-- Use Roblox's native model scaling.
	-- This avoids the old manual CFrame distortion.
	pcall(function()
		model:ScaleTo(scale)
	end)
end

-- =========================================================
-- FIND NECK3 / NECK4
-- =========================================================

local function findNamedObject(root, wantedName)

	local exact = root:FindFirstChild(wantedName, true)

	if exact then
		return exact
	end

	for _, inst in ipairs(root:GetDescendants()) do

		if string.lower(inst.Name) == string.lower(wantedName) then
			return inst
		end
	end

	return nil
end

-- =========================================================
-- GET WORLD CFRAME
-- =========================================================

local function getObjectCFrame(object)

	if object:IsA("Model") then
		return object:GetPivot()

	elseif object:IsA("BasePart") then
		return object.CFrame

	elseif object:IsA("Attachment") then
		return object.WorldCFrame
	end

	return nil
end

-- =========================================================
-- SET WORLD CFRAME
-- =========================================================

local function setObjectCFrame(object, cf)

	if object:IsA("Model") then

		object:PivotTo(cf)

	elseif object:IsA("BasePart") then

		object.CFrame = cf

	elseif object:IsA("Attachment") then

		object.WorldCFrame = cf
	end
end

-- =========================================================
-- GET BOUNDING BOX
-- =========================================================

local function getSize(object)

	if object:IsA("Model") then

		local _, size =
			object:GetBoundingBox()

		return size

	elseif object:IsA("BasePart") then

		return object.Size
	end

	return Vector3.one
end

-- =========================================================
-- FIND TOP/BOTTOM AXIS
-- =========================================================

local function getStackDistance(object)

	local size =
		getSize(object)

	-- The neck is expected to extend vertically.
	--
	-- Use Y first, but make sure the value isn't tiny.
	local height =
		math.max(
			math.abs(size.Y),
			math.abs(size.Z),
			0.01
		)

	-- Slight overlap makes the repeated pieces
	-- visually merge instead of showing gaps.
	return height * 0.92
end

-- =========================================================
-- CREATE PELICAN
-- =========================================================

local function createPelican()

	local character =
		player.Character

	if not character then
		return nil
	end

	local hrp =
		character:FindFirstChild(
			"HumanoidRootPart"
		)

	if not hrp then
		return nil
	end

	local pelican =
		PelicanTemplate:Clone()

	pelican.Name =
		"ClientPelican_" ..
		player.Name

	pelican.Parent =
		workspace

	-- Correct proportional scaling.
	scaleModel(
		pelican,
		PELICAN_SCALE
	)

	makeBlack(
		pelican
	)

	hideHeadAndBeak(
		pelican
	)

	pelican:PivotTo(
		hrp.CFrame
	)

	return pelican
end

-- =========================================================
-- BUILD NECK
-- =========================================================

local function buildInfiniteNeck(pelican)

	local neck3 =
		findNamedObject(
			pelican,
			"Neck3"
		)

	local neck4 =
		findNamedObject(
			pelican,
			"Neck4"
		)

	if not neck3 then

		warn(
			"Could not find Neck3 inside Pelican."
		)

		return
	end

	if not neck4 then

		warn(
			"Could not find Neck4 inside Pelican."
		)

		return
	end

	-- =====================================================
	-- CONTAINER
	-- =====================================================

	local container =
		Instance.new("Folder")

	container.Name =
		"ClientInfiniteNeck"

	container.Parent =
		pelican

	-- =====================================================
	-- ORIGINAL NECK4
	-- =====================================================

	hideHeadAndBeak(
		neck4
	)

	-- =====================================================
	-- TEMPLATE NECK3
	-- =====================================================

	local template =
		neck3:Clone()

	template.Name =
		"Neck3_TEMPLATE"

	template.Parent =
		container

	scaleModel(
		template,
		NECK_SCALE
	)

	makeBlack(
		template
	)

	hideHeadAndBeak(
		template
	)

	-- We don't want the template itself
	-- visible in the chain.
	local templateTransparency = {}

	for _, inst in ipairs(
		template:GetDescendants()
	) do

		if inst:IsA("BasePart") then

			templateTransparency[inst] =
				inst.Transparency

			inst.Transparency = 1
		end
	end

	-- =====================================================
	-- START POSITION
	-- =====================================================

	local neck4CF =
		getObjectCFrame(
			neck4
		)

	if not neck4CF then
		return
	end

	-- =====================================================
	-- SEGMENT DISTANCE
	-- =====================================================

	local segmentDistance =
		getStackDistance(
			template
		)

	-- =====================================================
	-- CREATE CHAIN
	-- =====================================================

	local segments = {}

	for i = 1, NECK_SEGMENTS do

		local segment =
			neck3:Clone()

		segment.Name =
			"Neck3_Infinite_" ..
			string.format(
				"%03d",
				i
			)

		segment.Parent =
			container

		-- Correct scale.
		scaleModel(
			segment,
			NECK_SCALE
		)

		makeBlack(
			segment
		)

		hideHeadAndBeak(
			segment
		)

		-- =================================================
		-- STACK
		-- =================================================

		local distance =
			segmentDistance
			*
			(i - 1)

		local target =
			neck4CF
			*
			CFrame.new(
				0,
				distance,
				0
			)

		setObjectCFrame(
			segment,
			target
		)

		table.insert(
			segments,
			{
				model = segment,
				index = i,
				base = target
			}
		)
	end

	template:Destroy()

	-- =====================================================
	-- JOINT-LIKE MOTION
	-- =====================================================

	task.spawn(function()

		local startTime =
			os.clock()

		while
			pelican.Parent
			and
			container.Parent
		do

			local now =
				os.clock()

			local elapsed =
				now - startTime

			-- Current Neck4 position is the anchor.
			local currentNeck4 =
				getObjectCFrame(
					neck4
				)

			if not currentNeck4 then
				break
			end

			for _, data in ipairs(
				segments
			) do

				local segment =
					data.model

				if not segment.Parent then
					continue
				end

				local i =
					data.index

				-- =============================================
				-- WAVE DELAY
				-- =============================================

				local waveOffset =
					(i - 1)
					/
					WAVE_LENGTH

				-- =============================================
				-- SLOW JOINT MOTION
				-- =============================================

				local waveTime =
					elapsed
					*
					NECK_SPEED
					-
					waveOffset

				-- Several overlapping waves make it
				-- look like individual joints following
				-- the one above them.
				local x =
					math.sin(
						waveTime
					)
					*
					BEND_X
					*
					(0.35 + i / NECK_SEGMENTS)

				local y =
					math.sin(
						waveTime
						* 0.73
						+ 1.7
					)
					*
					BEND_Y
					*
					(0.35 + i / NECK_SEGMENTS)

				local z =
					math.cos(
						waveTime
						* 0.58
						+ 0.8
					)
					*
					BEND_Z
					*
					(0.35 + i / NECK_SEGMENTS)

				-- =============================================
				-- POSITION ALONG NECK4'S AXIS
				-- =============================================

				local distance =
					segmentDistance
					*
					(i - 1)

				local target =

					currentNeck4

					*
					CFrame.new(
						0,
						distance,
						0
					)

					*
					CFrame.Angles(
						x,
						y,
						z
					)

				-- =============================================
				-- FOLLOWING MOTION
				-- =============================================

				local current =
					getObjectCFrame(
						segment
					)

				if current then

					local alpha =
						math.clamp(
							FOLLOW_SPEED
							*
							0.02,
							0,
							1
						)

					local smooth =
						current:Lerp(
							target,
							alpha
						)

					setObjectCFrame(
						segment,
						smooth
					)
				end
			end

			RunService.Heartbeat:Wait()
		end
	end)
end

-- =========================================================
-- CLEAR OLD
-- =========================================================

local function clearOld()

	local oldName =
		"ClientPelican_" ..
		player.Name

	for _, inst in ipairs(
		workspace:GetChildren()
	) do

		if
			inst:IsA("Model")
			and
			inst.Name == oldName
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
		createPelican()

	if not pelican then
		return
	end

	buildInfiniteNeck(
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

		task.wait(0.25)

		start()
	end
)
