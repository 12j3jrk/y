-- StarterPlayerScripts > LocalScript
-- GIANT PELICAN / ELEPHANT TRUNK
-- VERTICAL CYLINDER VERSION

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Birds = ReplicatedStorage:WaitForChild("Birds")
local PelicanTemplate = Birds:WaitForChild("Pelican")

------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------

local BEAK_NAME = "Beak2"

-- Giant pelican
local PELICAN_SCALE = 20

------------------------------------------------------------
-- NECK
------------------------------------------------------------

-- Total height of the neck
local NECK_LENGTH = 300

-- Number of vertical cylinders
local NECK_COUNT = 30

-- Thickness of every cylinder
local CYLINDER_DIAMETER = 12

-- Slight overlap so there are NO visible gaps
local CYLINDER_OVERLAP = 0.8

------------------------------------------------------------
-- TRUNK MOVEMENT
------------------------------------------------------------

local SWAY_SPEED = 0.45

-- Side-to-side movement of the trunk
local SIDE_SWAY = 30

-- Forward/backward movement
local FORWARD_SWAY = 18

-- Up/down wave
local VERTICAL_SWAY = 8

------------------------------------------------------------
-- GIANT MOVEMENT
------------------------------------------------------------

-- Very slow movement, like an enormous animal
local GIANT_SPEED = 1.2

-- Gentle body turning
local TURN_SPEED = 0.08

------------------------------------------------------------
-- SMOOTHNESS
------------------------------------------------------------

local FOLLOW_SPEED = 3

------------------------------------------------------------
-- BLACKEN PELICAN
------------------------------------------------------------

local function blacken(model)

	for _, object in ipairs(model:GetDescendants()) do

		if object:IsA("BasePart") then

			object.Color = Color3.new(0, 0, 0)
			object.Material = Enum.Material.SmoothPlastic

		elseif object:IsA("Decal") then

			object.Transparency = 1

		end

	end

end

------------------------------------------------------------
-- SCALE PELICAN
------------------------------------------------------------

local function scaleModel(model, scale)

	local pivot = model:GetPivot()

	for _, object in ipairs(model:GetDescendants()) do

		if object:IsA("BasePart") then

			local relativePosition =
				pivot:PointToObjectSpace(
					object.Position
				)

			local rotation =
				object.CFrame
				- object.CFrame.Position

			object.Size =
				object.Size * scale

			object.CFrame =
				pivot
				* CFrame.new(
					relativePosition * scale
				)
				* rotation

		end

	end

end

------------------------------------------------------------
-- FIND BEAK
------------------------------------------------------------

local function getBeakCFrame(model)

	local beak =
		model:FindFirstChild(
			BEAK_NAME,
			true
		)

	if beak then

		if beak:IsA("Attachment") then
			return beak.WorldCFrame
		end

		if beak:IsA("BasePart") then
			return beak.CFrame
		end

	end

	return model:GetPivot()

end

------------------------------------------------------------
-- CREATE PELICAN
------------------------------------------------------------

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
		"ClientPelican_" .. player.Name

	pelican.Parent =
		workspace

	blacken(pelican)

	scaleModel(
		pelican,
		PELICAN_SCALE
	)

	pelican:PivotTo(
		root.CFrame
	)

	return pelican

end

------------------------------------------------------------
-- CREATE CYLINDER
------------------------------------------------------------

local function createCylinder(
	parent,
	index,
	height
)

	local cylinder =
		Instance.new("Part")

	cylinder.Name =
		"Cylinder_" .. index

	cylinder.Shape =
		Enum.PartType.Cylinder

	--------------------------------------------------------
	-- IMPORTANT:
	--
	-- Roblox Cylinder length is along the X axis.
	--
	-- So:
	--
	-- X = HEIGHT
	-- Y = DIAMETER
	-- Z = DIAMETER
	--------------------------------------------------------

	cylinder.Size =
		Vector3.new(
			height,
			CYLINDER_DIAMETER,
			CYLINDER_DIAMETER
		)

	--------------------------------------------------------
	-- ROTATE THE CYLINDER 90 DEGREES AROUND Z.
	--
	-- This changes the cylinder's long X axis
	-- into the WORLD Y axis.
	--
	-- Result:
	--        |
	--        |
	--        |
	--        |
	--        |
	--
	-- NOT:
	--  --------
	--------------------------------------------------------

	cylinder.CFrame =
		CFrame.Angles(
			0,
			0,
			math.rad(90)
		)

	cylinder.Color =
		Color3.new(0, 0, 0)

	cylinder.Material =
		Enum.Material.SmoothPlastic

	cylinder.Anchored =
		true

	cylinder.CanCollide =
		false

	cylinder.CanTouch =
		false

	cylinder.CanQuery =
		false

	cylinder.CastShadow =
		false

	cylinder.Parent =
		parent

	return cylinder

end

------------------------------------------------------------
-- CREATE TRUNK
------------------------------------------------------------

local function createTrunk(pelican)

	local folder =
		Instance.new("Folder")

	folder.Name =
		"VerticalCylinderTrunk"

	folder.Parent =
		pelican

	--------------------------------------------------------
	-- EACH SEGMENT IS THIS TALL
	--------------------------------------------------------

	local segmentHeight =
		NECK_LENGTH
		/ NECK_COUNT

	local actualHeight =
		segmentHeight
		+ CYLINDER_OVERLAP

	--------------------------------------------------------
	-- CREATE CYLINDERS
	--------------------------------------------------------

	local cylinders = {}

	for i = 1, NECK_COUNT do

		cylinders[i] =
			createCylinder(
				folder,
				i,
				actualHeight
			)

	end

	--------------------------------------------------------
	-- ANIMATION
	--------------------------------------------------------

	task.spawn(function()

		local elapsed = 0

		----------------------------------------------------
		-- Current positions for smoothing
		----------------------------------------------------

		local currentPositions = {}

		while pelican.Parent do

			local dt =
				RunService.Heartbeat:Wait()

			elapsed += dt

			------------------------------------------------
			-- BEAK
			------------------------------------------------

			local beak =
				getBeakCFrame(
					pelican
				)

			local origin =
				beak.Position

			------------------------------------------------
			-- USE THE WORLD'S UP DIRECTION.
			--
			-- This guarantees the cylinders themselves
			-- remain VERTICAL.
			------------------------------------------------

			local WORLD_UP =
				Vector3.new(
					0,
					1,
					0
				)

			local forward =
				beak.LookVector

			------------------------------------------------
		
