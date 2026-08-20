-- StarterPlayerScripts > LocalScript
-- GIANT SLOW ELEPHANT PELICAN
-- Vertical cylinder trunk + slow movement

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

-- Giant size
local PELICAN_SCALE = 20

-- Trunk
local NECK_COUNT = 55
local NECK_LENGTH = 260
local CYLINDER_RADIUS = 5

-- Trunk movement
local WAVE_SPEED = 0.45
local SIDE_SWAY = 18
local FORWARD_SWAY = 12
local VERTICAL_SWAY = 8

-- Whole giant movement
local GIANT_SPEED = 2.0
local TURN_AMOUNT = 0.15

-- Smoothness
local SMOOTHNESS = 3

------------------------------------------------------------
-- BLACK PELICAN
------------------------------------------------------------

local function blacken(model)

	for _, obj in ipairs(model:GetDescendants()) do

		if obj:IsA("BasePart") then
			obj.Color = Color3.new(0, 0, 0)
			obj.Material = Enum.Material.SmoothPlastic

		elseif obj:IsA("Decal") then
			obj.Transparency = 1
		end

	end

end

------------------------------------------------------------
-- SCALE
------------------------------------------------------------

local function scaleModel(model, scale)

	local pivot = model:GetPivot()

	for _, obj in ipairs(model:GetDescendants()) do

		if obj:IsA("BasePart") then

			local relative =
				pivot:PointToObjectSpace(
					obj.Position
				)

			local rotation =
				obj.CFrame
				- obj.CFrame.Position

			obj.Size =
				obj.Size * scale

			obj.CFrame =
				pivot
				* CFrame.new(
					relative * scale
				)
				* rotation

		end

	end

end

------------------------------------------------------------
-- BEAK
------------------------------------------------------------

local function getBeak(model)

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
-- PELICAN
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
-- CYLINDER
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
-- MAIN TRUNK
------------------------------------------------------------

local function createTrunk(pelican)

	local folder =
		Instance.new("Folder")

	folder.Name =
		"CylinderTrunk"

	folder.Parent =
		pelican

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

		local time = 0

		while pelican.Parent do

			local dt =
				RunService.Heartbeat:Wait()

			time += dt

			------------------------------------------------
			-- BEAK
			------------------------------------------------

			local beak =
				getBeak(pelican)

			local origin =
				beak.Position

			local forward =
				beak.LookVector

			local right =
				beak.RightVector

			------------------------------------------------
			-- JOINT POSITIONS
			------------------------------------------------

			local joints = {}

			joints[1] =
				origin

			------------------------------------------------
			-- CREATE CONNECTED TRUNK
			------------------------------------------------

			for i = 2, NECK_COUNT + 1 do

				local alpha =
					(i - 2)
					/ NECK_COUNT

				------------------------------------------------
				-- SNAKE-LIKE WAVE
				------------------------------------------------

				local phase =
					time
					* WAVE_SPEED
					+ alpha * 3.5

				local side =
					math.sin(phase)
					* SIDE_SWAY
					* alpha

				local forwardWave =
					math.cos(
						phase * 0.7
					)
					* FORWARD_SWAY
					* alpha

				local vertical =
					math.sin(
						phase * 0.55
						+ 1
					)
					* VERTICAL_SWAY
					* alpha

				------------------------------------------------
				-- IMPORTANT:
				-- THE TRUNK GROWS UPWARD.
				------------------------------------------------

				local basePosition =
					origin
					+ Vector3.new(
						0,
						(i - 1)
						* (
							NECK_LENGTH
							/ NECK_COUNT
						),
						0
					)

				local target =
					basePosition
					+ right * side
					+ forward * forwardWave
					+ Vector3.new(
						0,
						vertical,
						0
					)

				------------------------------------------------
				-- CONNECT TO PREVIOUS JOINT
				------------------------------------------------

				local previous =
					joints[i - 1]

				local difference =
					target - previous

				if difference.Magnitude > 0 then

					target =
						previous
						+ difference.Unit
						* (
							NECK_LENGTH
							/ NECK_COUNT
						)

				end

				joints[i] =
					target

			end

			------------------------------------------------
			-- DRAW CYLINDERS
			------------------------------------------------

			for i = 1, NECK_COUNT do

				local a =
					joints[i]

				local b =
					joints[i + 1]

				local center =
					(a + b) / 2

				local length =
					(b - a).Magnitude

				local cylinder =
					cylinders[i]

				------------------------------------------------
				-- VERTICAL CYLINDER
				--
				-- Y AXIS ALWAYS POINTS UP.
				------------------------------------------------

				local targetCFrame =
					CFrame.new(center)

				local targetSize =
					Vector3.new(
						CYLINDER_RADIUS * 2,
						length,
						CYLINDER_RADIUS * 2
					)

				local smooth =
					math.clamp(
						dt * SMOOTHNESS,
						0,
						1
					)

				cylinder.CFrame =
					cylinder.CFrame:Lerp(
						targetCFrame,
						smooth
					)

				cylinder.Size =
					cylinder.Size:Lerp(
						targetSize,
						smooth
					)

			end

		end

	end)

end

------------------------------------------------------------
-- GIANT ELEPHANT MOVEMENT
------------------------------------------------------------

local function createMovement(pelican)

	task.spawn(function()

		local elapsed = 0

		while pelican.Parent do

			local dt =
				RunService.Heartbeat:Wait()

			elapsed += dt

			------------------------------------------------
			-- VERY SLOW GIANT MOVEMENT
			------------------------------------------------

			local forward =
				pelican:GetPivot().LookVector

			------------------------------------------------
			-- Slow forward walk
			------------------------------------------------

			local movement =
				forward
				* GIANT_SPEED
				* dt

			------------------------------------------------
			-- VERY GENTLE BODY SWAY
			------------------------------------------------

			local sway =
				math.sin(
					elapsed * 0.45
				)
				* TURN_AMOUNT

			local current =
				pelican:GetPivot()

			local newCFrame =
				current
				+ movement

			newCFrame =
				newCFrame
				* CFrame.Angles(
					0,
					sway * dt,
					0
				)

			pelican:PivotTo(
				newCFrame
			)

		end

	end)

end

------------------------------------------------------------
-- CLEAN OLD
------------------------------------------------------------

local function clearOld()

	local name =
		"ClientPelican_" .. player.Name

	for _, obj in ipairs(
		workspace:GetChildren()
	) do

		if obj:IsA("Model")
			and obj.Name == name then

			obj:Destroy()

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

	createTrunk(
		pelican
	)

	createMovement(
		pelican
	)

end

------------------------------------------------------------
-- CHARACTER
------------------------------------------------------------

if player.Character then

	task.wait(0.5)

	start()

end

player.CharacterAdded:Connect(function()

	task.wait(0.5)

	start()

end)
