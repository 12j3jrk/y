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

-- How many Neck3 copies are created.
-- Very high so it visually appears infinite.
local NECK_COUNT = 300

-- Very slow movement.
local NECK_SPEED = 0.22

-- Joint-like bending.
local BEND_X = math.rad(1.8)
local BEND_Y = math.rad(2.5)
local BEND_Z = math.rad(1.2)

-- Distance between repeated neck pieces.
-- 1 = exactly their measured height.
-- Lower = slight overlap.
local NECK_OVERLAP = 0.94

-- How far the bending wave travels down the neck.
local WAVE_LENGTH = 24

-- Smoothness.
local SMOOTHNESS = 0.055

-- =========================================================
-- NAME HIDING
-- =========================================================

local function nameShouldBeInvisible(name)

	name = string.lower(name)

	return
		string.find(name, "head", 1, true) ~= nil
		or
		string.find(name, "beak", 1, true) ~= nil
end

local function hideHeadAndBeak(model)

	for _, object in ipairs(model:GetDescendants()) do

		if nameShouldBeInvisible(object.Name) then

			if object:IsA("BasePart") then
				object.Transparency = 1

			elseif object:IsA("Decal") then
				object.Transparency = 1

			elseif object:IsA("Texture") then
				object.Transparency = 1

			elseif object:IsA("ParticleEmitter") then
				object.Enabled = false

			elseif object:IsA("Trail") then
				object.Enabled = false

			elseif object:IsA("Beam") then
				object.Enabled = false
			end
		end
	end
end

-- =========================================================
-- BLACK MODEL
-- =========================================================

local function makeBlack(model)

	for _, object in ipairs(model:GetDescendants()) do

		if object:IsA("BasePart") then

			object.Color = Color3.new(0, 0, 0)

			if object.Material ~= Enum.Material.Neon then
				object.Material = Enum.Material.SmoothPlastic
			end
		end
	end
end

-- =========================================================
-- MODEL SCALE
-- =========================================================

local function scaleModel(model, scale)

	if not model:IsA("Model") then
		return
	end

	-- Native Roblox scaling.
	-- Does not manually distort individual parts.
	pcall(function()
		model:ScaleTo(scale)
	end)
end

-- =========================================================
-- FIND OBJECT
-- =========================================================

local function findObject(root, objectName)

	-- Exact recursive search first.
	local object =
		root:FindFirstChild(
			objectName,
			true
		)

	if object then
		return object
	end

	-- Case-insensitive fallback.
	local wanted =
		string.lower(objectName)

	for _, descendant in ipairs(
		root:GetDescendants()
	) do

		if string.lower(
			descendant.Name
		) == wanted then

			return descendant
		end
	end

	return nil
end

-- =========================================================
-- GET PIVOT
-- =========================================================

local function getPivot(object)

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
-- SET PIVOT
-- =========================================================

local function setPivot(object, cframe)

	if object:IsA("Model") then

		object:PivotTo(cframe)

	elseif object:IsA("BasePart") then

		object.CFrame = cframe

	elseif object:IsA("Attachment") then

		object.WorldCFrame = cframe
	end
end

-- =========================================================
-- GET MODEL SIZE
-- =========================================================

local function getObjectSize(object)

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
-- GET NECK LENGTH
-- =========================================================

local function getNeckLength(neck)

	local size =
		getObjectSize(neck)

	-- Neck pieces are stacked vertically.
	--
	-- We use Y as the primary axis.
	-- If Y is unusably small, use the largest axis.
	local y =
		math.abs(size.Y)

	if y > 0.01 then
		return y * NECK_OVERLAP
	end

	return math.max(
		math.abs(size.X),
		math.abs(size.Z),
		0.01
	) * NECK_OVERLAP
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

	local root =
		character:FindFirstChild(
			"HumanoidRootPart"
		)

	if not root then
		return nil
	end

	local pelican =
		PelicanTemplate:Clone()

	pelican.Name =
		"ClientPelican_"
		.. player.Name

	pelican.Parent =
		workspace

	-- Scale the COMPLETE pelican correctly.
	scaleModel(
		pelican,
		PELICAN_SCALE
	)

	makeBlack(
		pelican
	)

	-- Hide absolutely anything whose
	-- name contains "head" or "beak".
	hideHeadAndBeak(
		pelican
	)

	pelican:PivotTo(
		root.CFrame
	)

	return pelican
end

-- =========================================================
-- BUILD INFINITE NECK
-- =========================================================

local function buildNeck(pelican)

	-- =====================================================
	-- FIND NECK3 AND NECK4
	-- =====================================================

	local neck3 =
		findObject(
			pelican,
			"Neck3"
		)

	local neck4 =
		findObject(
			pelican,
			"Neck4"
		)

	if not neck3 then

		warn(
			"[Infinite Neck] Neck3 was not found."
		)

		return
	end

	if not neck4 then

		warn(
			"[Infinite Neck] Neck4 was not found."
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
	-- HIDE ORIGINAL HEAD/BEAK OBJECTS
	-- =====================================================

	hideHeadAndBeak(
		neck3
	)

	hideHeadAndBeak(
		neck4
	)

	-- =====================================================
	-- ORIGINAL NECK4 POSITION
	-- =====================================================

	local neck4CFrame =
		getPivot(
			neck4
		)

	if not neck4CFrame then

		warn(
			"[Infinite Neck] Could not get Neck4 pivot."
		)

		return
	end

	-- =====================================================
	-- NECK3 SIZE
	-- =====================================================

	local spacing =
		getNeckLength(
			neck3
		)

	-- =====================================================
	-- CREATE REPEATING NECK3
	-- =====================================================

	local segments = {}

	for i = 1, NECK_COUNT do

		local clone =
			neck3:Clone()

		clone.Name =
			"Neck3_Infinite_"
			.. string.format(
				"%03d",
				i
			)

		clone.Parent =
			container

		-- Keep the same size as the original Neck3.
		-- No additional scaling here.

		makeBlack(
			clone
		)

		hideHeadAndBeak(
			clone
		)

		-- =================================================
		-- STACK DIRECTLY ON NECK4
		-- =================================================

		local distance =
			spacing
			*
			(i - 1)

		local target =
			neck4CFrame
			*
			CFrame.new(
				0,
				distance,
				0
			)

		setPivot(
			clone,
			target
		)

		table.insert(
			segments,
			{
				object = clone,
				index = i
			}
		)
	end

	-- =====================================================
	-- HIDE ORIGINAL NECK3
	-- =====================================================

	-- The original Neck3 is replaced by the generated chain.
	if neck3:IsA("BasePart") then
		neck3.Transparency = 1

	elseif neck3:IsA("Model") then

		for _, object in ipairs(
			neck3:GetDescendants()
		) do

			if object:IsA("BasePart") then
				object.Transparency = 1
			end
		end
	end

	-- =====================================================
	-- JOINT-LIKE MOVEMENT
	-- =====================================================

	task.spawn(function()

		local startTime =
			os.clock()

		while
			pelican.Parent
			and
			container.Parent
		do

			local elapsed =
				os.clock()
				-
				startTime

			-- Always follow Neck4.
			local anchor =
				getPivot(
					neck4
				)

			if not anchor then
				break
			end

			-- =============================================
			-- MOVE EACH JOINT
			-- =============================================

			for _, data in ipairs(
				segments
			) do

				local segment =
					data.object

				local i =
					data.index

				if not segment.Parent then
					continue
				end

				-- =========================================
				-- DELAYED WAVE
				-- =========================================

				local delay =
					(i - 1)
					/
					WAVE_LENGTH

				local wave =
					elapsed
					*
					NECK_SPEED
					-
					delay

				-- =========================================
				-- JOINT ROTATION
				-- =========================================

				local pitch =

					math.sin(
						wave
					)
					*
					BEND_X

				local yaw =

					math.sin(
						wave
						*
						0.78
						+
						1.1
					)
					*
					BEND_Y

				local roll =

					math.cos(
						wave
						*
						0.63
						+
						0.6
					)
					*
					BEND_Z

				-- =========================================
				-- POSITION
				-- =========================================

				local distance =
					spacing
					*
					(i - 1)

				local target =

					anchor

					*
					CFrame.new(
						0,
						distance,
						0
					)

					*
					CFrame.Angles(
						pitch,
						yaw,
						roll
					)

				-- =========================================
				-- SMOOTH JOINT MOTION
				-- =========================================

				local current =
					getPivot(
						segment
					)

				if current then

					local smooth =
						current:Lerp(
							target,
							SMOOTHNESS
						)

					setPivot(
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
-- REMOVE OLD
-- =========================================================

local function clearOld()

	local name =
		"ClientPelican_"
		.. player.Name

	for _, object in ipairs(
		workspace:GetChildren()
	) do

		if
			object:IsA("Model")
			and
			object.Name == name
		then

			object:Destroy()
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

		task.wait(0.25)

		start()
	end
)
