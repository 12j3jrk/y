-- StarterPlayerScripts > LocalScript
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Birds = ReplicatedStorage:WaitForChild("Birds")

local PelicanTemplate = Birds:WaitForChild("Pelican")
local PenguinTemplate = Birds:WaitForChild("PenguinChick")

-- ====== EDIT THESE ======
local BEAK_NAME = "Beak" -- change to the exact part/attachment name in your Pelican model
local PELICAN_SCALE = 20 -- "super large"
local NECK_SCALE = 10 -- scale penguins to look big/long like pelican
local PENGUINS = 10

-- how far neck stretches (studs)
local NECK_LENGTH = 200

-- very slow motion amount
local ROT_SPEED = 0.08
local SWAY_SPEED = 0.05
-- =======================

local function setBlackDeep(model)
	for _, inst in ipairs(model:GetDescendants()) do
		if inst:IsA("BasePart") then
			inst.Color = Color3.new(0, 0, 0)
			-- optional: make it solid-looking
			if inst.Material ~= Enum.Material.Neon then
				inst.Material = Enum.Material.SmoothPlastic
			end
		elseif inst:IsA("MeshPart") then
			inst.Color = Color3.new(0, 0, 0)
			inst.Material = Enum.Material.SmoothPlastic
		end
	end
end

local function findBeakPivot(model)
	-- Try: named part first
	local byName = model:FindFirstChild(BEAK_NAME, true)
	if byName then
		if byName:IsA("BasePart") then
			return byName.CFrame
		elseif byName:IsA("Attachment") then
			return byName.WorldCFrame
		end
	end

	-- Fallback: model pivot
	return model:GetPivot()
end

local function scaleModelParts(model, scale)
	-- robust scaling for most static models: scale each BasePart about model pivot
	local pivot = model:GetPivot()
	for _, inst in ipairs(model:GetDescendants()) do
		if inst:IsA("BasePart") then
			-- scale size
			inst.Size = inst.Size * scale

			-- scale position offset from pivot
			local rel = pivot:PointToObjectSpace(inst.Position)
			inst.CFrame = pivot * CFrame.new(rel * scale) * (inst.CFrame - inst.CFrame.Position)
		end
	end
end

local function makePelicanForPlayer()
	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local clone = PelicanTemplate:Clone()
	clone.Parent = workspace

	-- make black
	setBlackDeep(clone)

	-- scale pelican
	scaleModelParts(clone, PELICAN_SCALE)

	-- place on player
	clone:PivotTo(hrp.CFrame)

	return clone
end

local function animatePenguinNeck(pelicanModel)
	local beakCF = findBeakPivot(pelicanModel)

	-- use pelican forward direction
	local forward = beakCF.LookVector
	local up = beakCF.UpVector

	local container = Instance.new("Folder")
	container.Name = "ClientNeckStack"
	container.Parent = workspace

	local penguins = {}
	local step = NECK_LENGTH / math.max(1, (PENGUINS - 1))

	for i = 1, PENGUINS do
		local p = PenguinTemplate:Clone()
		p.Name = ("Penguin_%d"):format(i)
		p.Parent = container

		-- scale penguin bigger so it looks like it matches big pelican
		for _, inst in ipairs(p:GetDescendants()) do
			if inst:IsA("BasePart") then
				inst.Size = inst.Size * NECK_SCALE
			end
		end

		-- place along a line extending from beak
		local dist = step * (i - 1)
		local offsetCF = beakCF * CFrame.new(-forward * dist)

		p:PivotTo(offsetCF)
		table.insert(penguins, p)
	end

	-- slow connected neck motion:
	task.spawn(function()
		local t0 = os.clock()
		while pelicanModel.Parent do
			local t = os.clock() - t0

			-- tiny overall rotate and slow sway
			local globalYaw = math.sin(t * ROT_SPEED) * 0.35
			local globalPitch = math.cos(t * ROT_SPEED * 0.7) * 0.25
			local sway = math.sin(t * SWAY_SPEED) * 0.15

			for i, p in ipairs(penguins) do
				local alpha = (i - 1) / math.max(1, (PENGUINS - 1)) -- 0..1 along neck
				local dist = step * (i - 1)

				-- make farther segments move slightly more (still connected)
				local segYaw = globalYaw * alpha
				local segPitch = globalPitch * alpha
				local segRoll = sway * alpha

				-- curve: segments bend subtly as they extend
				local bend = math.sin(t * (ROT_SPEED + 0.01) + i * 0.4) * 0.1 * alpha

				local target = beakCF
					* CFrame.Angles(segPitch, segYaw, segRoll + bend)
					* CFrame.new(-forward * dist)

				-- smoothing so it looks super slow and connected
				local current = p:GetPivot()
				p:PivotTo(current:Lerp(target, 0.03))
			end

			task.wait(0.03)
		end
	end)
end

-- run
local function start()
	local pelican = makePelicanForPlayer()
	if pelican then
		animatePenguinNeck(pelican)
	end
end

start()

player.CharacterAdded:Connect(function()
	task.wait(0.2)
	start()
end)
