-- StarterPlayerScripts > LocalScript

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Birds = ReplicatedStorage:WaitForChild("Birds")

local PelicanTemplate = Birds:WaitForChild("Pelican")
local PenguinTemplate = Birds:WaitForChild("PenguinChick")

-- ===== YOU MAY NEED TO EDIT THIS =====
-- Either:
--   1) set to the exact beak part name (searched recursively), e.g. "Beak"
--   2) or set to a full path relative to Pelican model, e.g. "Head/Beak"
local BEAK_NAME = "Beak2" -- try "Beak", "Mouth", "BeakPart", "PelicanBeak", etc.

-- If you can't find the beak name, set this to true and it will use a fallback.
local FALLBACK_TO_MODEL_PIVOT = true
-- =====================================

-- Size tuning
local PELICAN_SCALE = 20
local PENGUIN_SCALE = 10
local NECK_COUNT = 10
local NECK_LENGTH = 200

-- Motion tuning (super slow)
local YAW_AMT = 0.35
local PITCH_AMT = 0.25
local SWAY_AMT = 0.15
local MOVE_SPEED = 0.06       -- smaller = slower
local BEND_SPEED = 0.03       -- smaller = slower
local UPDATE_DT = 0.03

local function setBlack(model)
	for _, inst in ipairs(model:GetDescendants()) do
		if inst:IsA("BasePart") then
			inst.Color = Color3.new(0, 0, 0)
			-- Keep it readable
			if inst.Material ~= Enum.Material.Neon then
				inst.Material = Enum.Material.SmoothPlastic
			end
		elseif inst:IsA("Decal") then
			-- Make decals effectively disappear (since they often can't be recolored)
			inst.Transparency = 1
		end
	end
end

local function getBeakCFrame(model)
	-- Try by name (recursive)
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

	-- final fallback
	return model:GetPivot()
end

local function scaleModel(model, scale)
	-- Scale each BasePart around model pivot (works for most rigs/models)
	local pivot = model:GetPivot()
	for _, inst in ipairs(model:GetDescendants()) do
		if inst:IsA("BasePart") then
			local rel = pivot:PointToObjectSpace(inst.Position)
			inst.Size = inst.Size * scale
			inst.CFrame = pivot
				* CFrame.new(rel * scale)
				* (inst.CFrame - inst.CFrame.Position)
		end
	end
end

local function clonePelicanToPlayer()
	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Clone and parent
	local pelican = PelicanTemplate:Clone()
	pelican.Name = "ClientPelican_" .. player.Name
	pelican.Parent = workspace

	-- Make black and scale
	setBlack(pelican)
	scaleModel(pelican, PELICAN_SCALE)

	-- Teleport to player immediately (use Pivot)
	pelican:PivotTo(hrp.CFrame)

	return pelican
end

local function buildPenguinsNeck(pelican, hrp)
	-- container so we can clean/identify
	local folder = Instance.new("Folder")
	folder.Name = "ClientPenguinNeckStack"
	folder.Parent = pelican

	-- anchor
	local beakCF = getBeakCFrame(pelican)

	-- we will place penguins along pelican forward direction
	local forward = beakCF.LookVector
	local step = NECK_LENGTH / math.max(1, (NECK_COUNT - 1))

	local penguins = {}

	for i = 1, NECK_COUNT do
		local p = PenguinTemplate:Clone()
		p.Name = ("Penguin_%02d"):format(i)
		p.Parent = folder

		-- scale penguin
		for _, inst in ipairs(p:GetDescendants()) do
			if inst:IsA("BasePart") then
				inst.Size = inst.Size * PENGUIN_SCALE
			end
		end

		-- place along a line starting at beak (extend outward)
		local dist = step * (i - 1)
		local targetCF = beakCF * CFrame.new(-forward * dist)

		p:PivotTo(targetCF)
		table.insert(penguins, p)
	end

	-- animate very slowly, staying connected to the beak
	task.spawn(function()
		local t0 = os.clock()

		while pelican.Parent do
			local t = os.clock() - t0

			-- recompute beak each frame so it stays attached even if pelican moves
			local currentBeak = getBeakCFrame(pelican)
			local fwd = currentBeak.LookVector

			local yaw = math.sin(t * MOVE_SPEED) * YAW_AMT
			local pitch = math.cos(t * MOVE_SPEED * 0.7) * PITCH_AMT
			local sway = math.sin(t * MOVE_SPEED * 0.5) * SWAY_AMT

			for i, p in ipairs(penguins) do
				local alpha = (i - 1) / math.max(1, (NECK_COUNT - 1))
				local dist = step * (i - 1)

				-- bend increases along the stack
				local bend = math.sin(t * BEND_SPEED + i * 0.45) * (0.12 + 0.05 * alpha) * alpha

				-- Each segment rotates a bit differently, but still connected via same base + offset
				local rot = CFrame.Angles(
					pitch * alpha,
					yaw * alpha,
					sway * alpha + bend
				)

				local cf = currentBeak * rot * CFrame.new(-fwd * dist)

				local cur = p:GetPivot()
				p:PivotTo(cur:Lerp(cf, 0.03)) -- smoothing for slow connected motion
			end

			task.wait(UPDATE_DT)
		end
	end)
end

local function clearOldPelican()
	-- Remove any previous client pelican for this player (optional cleanup)
	for _, inst in ipairs(workspace:GetChildren()) do
		if inst:IsA("Model") and inst.Name == ("ClientPelican_" .. player.Name) then
			inst:Destroy()
		end
	end
end

local function startForCharacter()
	clearOldPelican()

	local pelican = clonePelicanToPlayer()
	if not pelican then return end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	buildPenguinsNeck(pelican, hrp)
end

-- run
if player.Character then
	startForCharacter()
end

player.CharacterAdded:Connect(function()
	task.wait(0.2)
	startForCharacter()
end)
