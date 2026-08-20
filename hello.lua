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

local PELICAN_SCALE = 20
local PENGUIN_SCALE = 10

local NECK_COUNT = 53
local NECK_LENGTH = 250

-- More separation between penguins
local PENGUIN_SPACING = 1.18

-- Overall movement speed
-- Smaller = slower
local WALK_SPEED = 0.12

-- How far the entire creature slowly moves
local WALK_DISTANCE = 2.5

-- Slow body bob
local BODY_BOB = 0.7

-- Neck joint movement
local NECK_SWAY = 0.9
local NECK_BEND = 0.16

-- How quickly penguins follow their targets
local NECK_SMOOTHING = 0.055

local UPDATE_DT = 0.03

--------------------------------------------------
-- BLACK
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
-- BEAK
--------------------------------------------------

local function getBeakCFrame(model)

	local found =
		model:FindFirstChild(
			BEAK_NAME,
			true
		)

	if found then

		if found:IsA("Attachment") then
			return found.WorldCFrame

		elseif found:IsA("BasePart") then
			return found.CFrame
		end
	end

	return model:GetPivot()
end

--------------------------------------------------
-- SCALE
--------------------------------------------------

local function scaleModel(model, scale)

	local pivot =
		model:GetPivot()

	for _, inst in ipairs(model:GetDescendants()) do

		if inst:IsA("BasePart") then

			local relative =
				pivot:PointToObjectSpace(
					inst.Position
				)

			inst.Size =
				inst.Size * scale

			inst.CFrame =
				pivot
				* CFrame.new(
					relative * scale
				)
				* (
					inst.CFrame
					- inst.CFrame.Position
				)
		end
	end
end

--------------------------------------------------
-- PENGUIN SIZE
--------------------------------------------------

local function getPenguinStep(model)

	local _, size =
		model:GetBoundingBox()

	return math.max(
		1,
		(size.Y + size.Z) * 0.5
	)
end

--------------------------------------------------
-- CREATE PELICAN
--------------------------------------------------

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

	setBlack(pelican)

	scaleModel(
		pelican,
		PELICAN_SCALE
	)

	-- Initial position only.
	-- From this point onward the pelican will
	-- translate without changing its rotation.
	pelican:PivotTo(
		hrp.CFrame
	)

	return pelican
end

--------------------------------------------------
-- BUILD NECK
--------------------------------------------------

local function buildNeck(pelican)

	local container =
		Instance.new("Folder")

	container.Name =
		"ClientPenguinNeckStack"

	container.Parent =
		pelican

	--------------------------------------------------
	-- INITIAL BEAK
	--------------------------------------------------

	local initialBeak =
		getBeakCFrame(pelican)

	local forward =
		initialBeak.LookVector

	--------------------------------------------------
	-- FIND PENGUIN SIZE
	--------------------------------------------------

	local temp =
		PenguinTemplate:Clone()

	setBlack(temp)

	scaleModel(
		temp,
		PENGUIN_SCALE
	)

	local baseStep =
		getPenguinStep(temp)

	temp:Destroy()

	--------------------------------------------------
	-- NECK LENGTH
	--------------------------------------------------

	local currentLength =
		baseStep *
		(NECK_COUNT - 1)

	local lengthScale =
		currentLength > 0
		and (
			NECK_LENGTH /
			currentLength
		)
		or 1

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

		local distance =
			step * (i - 1)

		--------------------------------------------------
		-- IMPORTANT:
		-- Initial orientation follows the neck,
		-- but each penguin remains its own object.
		--------------------------------------------------

		local target =
			initialBeak
			* CFrame.new(
				-forward * distance
			)

		penguin:PivotTo(target)

		table.insert(
			penguins,
			penguin
		)
	end

	--------------------------------------------------
	-- SAVE ORIGINAL PELICAN TRANSFORM
	--------------------------------------------------

	local originalPelican =
	
