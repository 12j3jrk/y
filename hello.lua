-- StarterPlayerScripts > LocalScript
-- FULL REMAKE
-- Pelican + procedural connected cylinder trunk/neck

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

-- Pelican size
local PELICAN_SCALE = 20

-- Neck
local NECK_COUNT = 55
local NECK_LENGTH = 250

-- Cylinder thickness
local CYLINDER_RADIUS = 5

-- Movement
local MOTION_SPEED = 1.8

-- How much the neck can bend sideways
local SIDE_BEND = 35

-- How much the neck can bend forward/backward
local FORWARD_BEND = 25

-- How much the tip can swing
local TIP_SWING = 45

-- How much vertical movement occurs
local VERTICAL_BEND = 20

-- Smoothness
local FOLLOW_SPEED = 14

------------------------------------------------------------
-- BLACK MODEL
------------------------------------------------------------

local function setBlack(model)

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
-- SCALE MODEL
------------------------------------------------------------

local function scaleModel(model, scale)

	local pivot = model:GetPivot()

	for _, object in ipairs(model:GetDescendants()) do

		if object:IsA("BasePart") then

			local relativePosition =
				pivot:PointToObjectSpace(object.Position)

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
-- GET BEAK POSITION
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

	setBlack(pelican)

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
	index
)

	local cylinder =
		Instance.new("Part")

	cylinder.Name =
		"Cylinder_" .. index

	cylinder.Shape =
		Enum.PartType.Cylinder

	cylinder.Size =
		Vector3.new(
			CYLINDER_RADIUS * 2,
			1,
			CYLINDER_RADIUS * 2
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
-- CREATE ORIENTATION WHERE Y AXIS = DIRECTION
------------------------------------------------------------

local function makeCylinderCFrame(
	position,
	direction,
	upReference
)

	direction =
		direction.Unit

	-- Pick a reference vector that isn't parallel
	-- to the cylinder direction.
	local reference =
		upReference

	if math.abs(
		direction:Dot(reference)
	) > 0.95 then

		reference =
			Vector3.new(1, 0, 0)

	end

	-- X axis
	local xAxis =
		reference:Cross(direction).Unit

	-- Z axis
	local zAxis =
		xAxis:Cross(direction).Unit

	-- Cylinder's Y axis points along direction.
	return CFrame.fromMatrix(
		position,
		xAxis,
		direction,
		zAxis
	)

end

------------------------------------------------------------
-- BUILD THE NECK
------------------------------------------------------------

local function buildNeck(pelican)

	local folder =
		Instance.new("Folder")

	folder.Name =
		"CylinderNeck"

	folder.Parent =
		pelican

	--------------------------------------------------------
	-- JOINT COUNT
	--
	-- There is one more joint than cylinders.
	--------------------------------------------------------

	local joints = {}

	local targetJoints = {}

	--------------------------------------------------------
	-- CYLINDERS
	--------------------------------------------------------

	local cylinders = {}

	for i = 1, NECK_COUNT do

		cylinders[i] =
			createCylinder(
				folder,
				i
			)

	end

	--------------------------------------------------------
	-- ANIMATION
	--------------------------------------------------------

	task.spawn(function()

		local startTime =
			os.clock()

		while pelican.Parent do

			local deltaTime =
				RunService.Heartbeat:Wait()

			local time =
				os.clock() - startTime

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
			-- IMPORTANT:
			--
			-- These are the actual coordinate axes
			-- used to grow the chain.
			------------------------------------------------

			local up =
				beak.UpVector

			local right =
				beak.RightVector

			local forward =
				beak.LookVector

			------------------------------------------------
			-- DISTANCE BETWEEN JOINTS
			------------------------------------------------

			local segmentLength =
				NECK_LENGTH
				/ NECK_COUNT

			------------------------------------------------
			-- FIRST JOINT IS LITERALLY THE BEAK
			------------------------------------------------

			targetJoints[1] =
				origin

			------------------------------------------------
			-- BUILD THE CHAIN
			--
			-- THIS IS THE IMPORTANT PART.
			--
			-- Joint 2 comes from Joint 1.
			-- Joint 3 comes from Joint 2.
			-- Joint 4 comes from Joint 3.
			--
			-- Therefore the neck is actually connected.
			------------------------------------------------

			local previous =
				origin

			local previousDirection =
				up

			for i = 2, NECK_COUNT + 1 do

				local alpha =
					(i - 2)
					/ NECK_COUNT

				------------------------------------------------
				-- WAVE PHASE
				--
				-- The wave gets stronger toward the tip.
				------------------------------------------------

				local phase =
					time
					* MOTION_SPEED
					+ alpha * 6

				local waveSide =
					math.sin(phase)

				local waveForward =
					math.sin(
						phase * 0.73
						+ 1.7
					)

				local waveVertical =
					math.cos(
						phase * 0.61
						+ 2.4
					)

				------------------------------------------------
				-- BEND STRENGTH
				------------------------------------------------

				local strength =
					alpha ^ 1.35

				------------------------------------------------
				-- DESIRED DIRECTION
				------------------------------------------------

				local desiredDirection =
					up

				desiredDirection +=
					right
					* (
						waveSide
						* SIDE_BEND
						* strength
					)

				desiredDirection +=
					forward
					* (
						waveForward
						* FORWARD_BEND
						* strength
					)

				desiredDirection +=
					up
					* (
						waveVertical
						* VERTICAL_BEND
						* strength
					)

				------------------------------------------------
				-- TIP SWING
				------------------------------------------------

				local tipStrength =
					strength ^ 2

				desiredDirection +=
					right
					* (
						math.sin(
							time * MOTION_SPEED * 1.4
							+ alpha * 10
						)
						* TIP_SWING
						* tipStrength
					)

				------------------------------------------------
				-- NORMALIZE
				------------------------------------------------

				desiredDirection =
					desiredDirection.Unit

				------------------------------------------------
				-- SMOOTH DIRECTION
				--
				-- This prevents sharp 90-degree joints.
				------------------------------------------------

				local direction =
					previousDirection:Lerp(
						desiredDirection,
						0.22
					).Unit

				------------------------------------------------
				-- THE NEW JOINT IS EXACTLY ONE
				-- SEGMENT LENGTH FROM THE PREVIOUS JOINT.
				--
				-- NO INDEPENDENT OFFSET.
				-- NO RANDOM GAP.
				------------------------------------------------

				local newPosition =
					previous
					+ direction
					* segmentLength

				targetJoints[i] =
					newPosition

				previous =
					newPosition

				previousDirection =
					direction

			end

			------------------------------------------------
			-- SMOOTH THE ACTUAL JOINTS
			------------------------------------------------

			local smoothing =
				1 - math.exp(
					-FOLLOW_SPEED
					* deltaTime
				)

			for i = 1, NECK_COUNT + 1 do

				if not joints[i] then

					joints[i] =
						targetJoints[i]

				else

					joints[i] =
						joints[i]:Lerp(
							targetJoints[i],
							smoothing
						)

				end

			end

			------------------------------------------------
			-- PUT CYLINDERS BETWEEN JOINTS
			------------------------------------------------

			for i = 1, NECK_COUNT do

				local a =
					joints[i]

				local b =
					joints[i + 1]

				local difference =
					b - a

				local length =
					difference.Magnitude

				if length > 0.01 then

					local direction =
						difference.Unit

					------------------------------------------------
					-- CENTER THE CYLINDER BETWEEN THE TWO JOINTS
					------------------------------------------------

					local center =
						(a + b) * 0.5

					------------------------------------------------
					-- Y AXIS OF CYLINDER = NECK DIRECTION
					------------------------------------------------

					local target =
						makeCylinderCFrame(
							center,
							direction,
							up
						)

					------------------------------------------------
					-- THE CYLINDER LENGTH IS EXACTLY THE
					-- DISTANCE BETWEEN THE TWO JOINTS.
					------------------------------------------------

					local targetSize =
						Vector3.new(
							CYLINDER_RADIUS * 2,
							length + 0.15,
							CYLINDER_RADIUS * 2
						)

					cylinders[i].Size =
						cylinders[i].Size:Lerp(
							targetSize,
							smoothing
						)

					cylinders[i].CFrame =
						cylinders[i].CFrame:Lerp(
							target,
							smoothing
						)

				end

			end

		end

	end)

end

------------------------------------------------------------
-- REMOVE OLD VERSION
------------------------------------------------------------

local function clearOld()

	local name =
		"ClientPelican_" .. player.Name

	for _, object in ipairs(
		workspace:GetChildren()
	) do

		if object:IsA("Model")
			and object.Name == name then

			object:Destroy()

		end

	end

end

------------------------------------------------------------
-- START
------------------------------------------------------------

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

------------------------------------------------------------
-- CHARACTER
------------------------------------------------------------

if player.Character then

	task.wait(0.2)

	start()

end

player.CharacterAdded:Connect(function()

	task.wait(0.3)

	start()

end)
