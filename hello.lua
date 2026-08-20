-- StarterPlayerScripts > LocalScript
-- Pelican with a fully procedural cylinder neck
-- No Penguin models are used.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Birds = ReplicatedStorage:WaitForChild("Birds")

local PelicanTemplate = Birds:WaitForChild("Pelican")

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local BEAK_NAME = "Beak2"

local PELICAN_SCALE = 20

-- Number of cylinders in the neck
local NECK_COUNT = 45

-- Distance from the beak to the end of the neck
local NECK_LENGTH = 250

-- Cylinder dimensions
local CYLINDER_RADIUS = 5
local CYLINDER_LENGTH = 7

-- How much the neck can bend
local BEND_AMOUNT = 2.0

-- Side-to-side movement
local SIDE_SWAY = 1.8

-- Up/down movement
local VERTICAL_SWAY = 1.4

-- Speed of the trunk/snake motion
local MOTION_SPEED = 1.7

-- How quickly cylinders follow their targets
local FOLLOW_SPEED = 12

--------------------------------------------------
-- BLACKEN MODEL
--------------------------------------------------

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

--------------------------------------------------
-- SCALE MODEL
--------------------------------------------------

local function scaleModel(model, scale)

	local pivot = model:GetPivot()

	for _, object in ipairs(model:GetDescendants()) do

		if object:IsA("BasePart") then

			local relativePosition =
				pivot:PointToObjectSpace(object.Position)

			object.Size = object.Size * scale

			object.CFrame =
				pivot
				* CFrame.new(relativePosition * scale)
				* (object.CFrame - object.CFrame.Position)

		end

	end

end

--------------------------------------------------
-- GET BEAK
--------------------------------------------------

local function getBeakCFrame(model)

	local beak = model:FindFirstChild(BEAK_NAME, true)

	if beak then

		if beak:IsA("Attachment") then
			return beak.WorldCFrame
		end

		if beak:IsA("BasePart") then
			return beak.CFrame
		end

	end

	-- Fallback
	return model:GetPivot()

end

--------------------------------------------------
-- CREATE PELICAN
--------------------------------------------------

local function createPelican()

	local character = player.Character

	if not character then
		return nil
	end

	local humanoidRootPart =
		character:FindFirstChild("HumanoidRootPart")

	if not humanoidRootPart then
		return nil
	end

	local pelican = PelicanTemplate:Clone()

	pelican.Name =
		"ClientPelican_" .. player.Name

	pelican.Parent = workspace

	setBlack(pelican)

	scaleModel(
		pelican,
		PELICAN_SCALE
	)

	pelican:PivotTo(
		humanoidRootPart.CFrame
	)

	return pelican

end

--------------------------------------------------
-- CREATE CYLINDER
--------------------------------------------------

local function createCylinder(parent, number)

	local cylinder = Instance.new("Part")

	cylinder.Name =
		"Cylinder_" .. number

	cylinder.Shape =
		Enum.PartType.Cylinder

	-- Roblox cylinders are normally aligned
	-- along their Y axis.
	cylinder.Size = Vector3.new(
		CYLINDER_RADIUS * 2,
		CYLINDER_LENGTH,
		CYLINDER_RADIUS * 2
	)

	cylinder.Color =
		Color3.new(0, 0, 0)

	cylinder.Material =
		Enum.Material.SmoothPlastic

	cylinder.Anchored = true

	cylinder.CanCollide = false
	cylinder.CanTouch = false
	cylinder.CanQuery = false

	cylinder.CastShadow = false

	cylinder.Parent = parent

	return cylinder

end

--------------------------------------------------
-- BUILD NECK
--------------------------------------------------

local function buildNeck(pelican)

	local neckFolder =
		Instance.new("Folder")

	neckFolder.Name =
		"CylinderNeck"

	neckFolder.Parent =
		pelican

	--------------------------------------------------
	-- CREATE ALL CYLINDERS
	--------------------------------------------------

	local cylinders = {}

	for i = 1, NECK_COUNT do

		local cylinder =
			createCylinder(
				neckFolder,
				i
			)

		table.insert(
			cylinders,
			cylinder
		)

	end

	--------------------------------------------------
	-- STARTING POSITIONS
	--------------------------------------------------

	local beakStart =
		getBeakCFrame(pelican)

	local startPosition =
		beakStart.Position

	local startDirection =
		beakStart.UpVector

	-- Put the cylinders initially
	-- in a straight vertical chain.

	for i, cylinder in ipairs(cylinders) do

		local distance =
			(i - 1) * CYLINDER_LENGTH

		local position =
			startPosition
			+ startDirection * distance

		cylinder.CFrame =
			CFrame.lookAt(
				position,
				position + startDirection
			)
			* CFrame.Angles(
				math.rad(90),
				0,
				0
			)

	end

	--------------------------------------------------
	-- ANIMATION
	--------------------------------------------------

	task.spawn(function()

		local startTime =
			os.clock()

		while pelican.Parent do

			local deltaTime =
				RunService.Heartbeat:Wait()

			local time =
				os.clock() - startTime

			--------------------------------------------------
			-- CURRENT BEAK
			--------------------------------------------------

			local beak =
				getBeakCFrame(pelican)

			local origin =
				beak.Position

			-- The neck initially points upward.
			local baseDirection =
				beak.UpVector

			local baseRight =
				beak.RightVector

			local baseLook =
				beak.LookVector

			--------------------------------------------------
			-- BUILD A CURVED "SPINE"
			--------------------------------------------------

			local positions = {}

			local directions = {}

			local previousPosition =
				origin

			local previousDirection =
				baseDirection

			for i = 1, NECK_COUNT do

				local alpha =
					(i - 1)
					/ math.max(
						1,
						NECK_COUNT - 1
					)

				--------------------------------------------------
				-- TRUNK/SNAKE WAVE
				--------------------------------------------------

				local wave1 =
					math.sin(
						time * MOTION_SPEED
						+ alpha * 5
					)

				local wave2 =
					math.sin(
						time * MOTION_SPEED * 0.63
						+ alpha * 8
					)

				local wave3 =
					math.cos(
						time * MOTION_SPEED * 0.47
						+ alpha * 11
					)

				--------------------------------------------------
				-- MAKE BENDING STRONGER TOWARD THE TIP
				--------------------------------------------------

				local bendStrength =
					alpha ^ 1.25

				local sideOffset =
					wave1
					* SIDE_SWAY
					* bendStrength

				local verticalOffset =
					wave2
					* VERTICAL_SWAY
					* bendStrength

				local forwardOffset =
					wave3
					* BEND_AMOUNT
					* bendStrength

				--------------------------------------------------
				-- TARGET POSITION
				--------------------------------------------------

				local targetPosition =
					origin
					+ baseDirection
						* (
							(i - 1)
							* CYLINDER_LENGTH
						)

					+ baseRight
						* sideOffset

					+ baseLook
						* forwardOffset

					+ baseDirection
						* verticalOffset

				--------------------------------------------------
				-- CONNECT TO PREVIOUS SEGMENT
				--------------------------------------------------

				if i > 1 then

					local previous =
						positions[i - 1]

					-- Prevent sudden disconnected jumps.
					local connection =
						targetPosition
						- previous

					local distance =
						connection.Magnitude

					if distance > 0 then

						targetPosition =
							previous
							+ connection.Unit
								* CYLINDER_LENGTH

					end

				end

				positions[i] =
					targetPosition

			end

			--------------------------------------------------
			-- CALCULATE DIRECTIONS
			--------------------------------------------------

			for i = 1, NECK_COUNT do

				local direction

				if i < NECK_COUNT then

					direction =
						positions[i + 1]
						- positions[i]

				elseif i > 1 then

					direction =
						positions[i]
						- positions[i - 1]

				else

					direction =
						baseDirection

				end

				if direction.Magnitude > 0.001 then

					directions[i] =
						direction.Unit

				else

					directions[i] =
						baseDirection

				end

			end

			--------------------------------------------------
			-- MOVE CYLINDERS
			--------------------------------------------------

			local smoothing =
				1 - math.exp(
					-FOLLOW_SPEED
					* deltaTime
				)

			for i, cylinder in ipairs(cylinders) do

				if not cylinder.Parent then
					break
				end

				local position =
					positions[i]

				local direction =
					directions[i]

				--------------------------------------------------
				-- MAKE CYLINDER FOLLOW THE NECK
				--------------------------------------------------

				local targetCFrame =
					CFrame.lookAt(
						position,
						position + direction,
						baseRight
					)
					* CFrame.Angles(
						math.rad(90),
						0,
						0
					)

				cylinder.CFrame =
					cylinder.CFrame:Lerp(
						targetCFrame,
						smoothing
					)

			end

		end

	end)

end

------------------------------------------------
