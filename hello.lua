-- Roblox Script (ServerScriptService or inside a tool)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BirdsFolder = ReplicatedStorage:WaitForChild("Birds")

local PelicanTemplate = BirdsFolder:WaitForChild("Pelican")
local PenguinTemplate = BirdsFolder:WaitForChild("PenguinChick")

local function setAllBlack(model)
	for _, inst in ipairs(model:GetDescendants()) do
		if inst:IsA("BasePart") then
			inst.Color = Color3.new(0, 0, 0)
			inst.Material = Enum.Material.SmoothPlastic
		elseif inst:IsA("MeshPart") then
			-- MeshPart is also BasePart, but kept for clarity
			inst.Color = Color3.new(0, 0, 0)
		elseif inst:IsA("Decal") then
			-- Decals can't always be recolored; remove for a clean black look
			inst.Transparency = 1
		end
	end
end

local function findBeakCFrame(pelicanModel)
	-- Try common naming patterns
	local candidates = {
		"Beak", "beak", "Mouth", "mouth", "Head", "head",
		"PelicanBeak", "PelicanMouth", "BeakAttachment", "MouthAttachment"
	}

	for _, name in ipairs(candidates) do
		local inst = pelicanModel:FindFirstChild(name, true)
		if inst then
			if inst:IsA("Attachment") then
				return inst.WorldCFrame
			elseif inst:IsA("BasePart") then
				return inst.CFrame
			end
		end
	end

	-- Fallbacks
	if pelicanModel.PrimaryPart then
		return pelicanModel.PrimaryPart.CFrame
	end

	local anyPart = pelicanModel:FindFirstChildWhichIsA("BasePart", true)
	if anyPart then
		return anyPart.CFrame
	end

	return pelicanModel:GetPivot()
end

local function cloneAndSizePelicanToPlayer(pelicanModel, player, veryLargeScale)
	local clone = pelicanModel:Clone()
	clone.Parent = workspace

	setAllBlack(clone)

	-- Make super large
	clone:PivotTo(player.Character.HumanoidRootPart.CFrame)

	-- Scale model via Pivot and applying scale to each BasePart (no native model scaling in all cases)
	-- We'll scale by adjusting each BasePart size/position relative to pivot.
	local pivot = clone:GetPivot()
	for _, inst in ipairs(clone:GetDescendants()) do
		if inst:IsA("BasePart") then
			-- scale size
			inst.Size = inst.Size * veryLargeScale

			-- move position relative to pivot
			local rel = pivot:ToObjectSpace(inst.CFrame)
			-- scale translation component
			local newRel = CFrame.new(rel.Position * veryLargeScale) * CFrame.fromMatrix(rel.Position * 0, rel.Rotation.XVector, rel.Rotation.YVector, rel.Rotation.ZVector)
			-- preserve orientation using original rotation:
			local rot = CFrame.fromMatrix(Vector3.zero, rel.Rotation.XVector, rel.Rotation.YVector, rel.Rotation.ZVector)
			inst.CFrame = pivot * CFrame.new(rel.Position * veryLargeScale) * rot
		end
	end

	return clone
end

local function placePenguinNeckStack({
	pelicanClone,
	player,
	penguinCount,
	beakCFrame,
	neckLength,
	spreadAngle,
	moveSpeed
})
	-- Create a folder for organization
	local folder = Instance.new("Folder")
	folder.Name = "PenguinNeckStack"
	folder.Parent = workspace

	-- We'll build a “chain”: each penguin follows the previous one,
	-- and the whole chain subtly oscillates/rotates very slowly.
	local base = beakCFrame

	-- Decide forward direction (pelican look direction)
	-- Use pelican's pivot orientation
	local pelicanLook = pelicanClone:GetPivot().LookVector
	local forward = pelicanLook.Unit
	local up = base.UpVector

	-- Start with a “target” direction that slowly rotates
	local timeStart = os.clock()

	local lastCFrame = base

	-- Keep a small offset so penguins appear like stacked on beaks position
	local step = neckLength / math.max(1, penguinCount - 1)

	local penguins = {}

	for i = 1, penguinCount do
		local p = PenguinTemplate:Clone()
		p.Name = "Penguin_" .. i
		p.Parent = folder

		-- Ensure we can move it: pick a PrimaryPart or any BasePart
		local part = p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart", true)
		if not part then
			p:Destroy()
			continue
		end

		-- Make penguins long/large like the pelican? If you want even bigger,
		-- increase this. Otherwise keep at default.
		-- We'll scale moderately; you can change it.
		local penguinScale = 10 -- adjust if you want them huge
		local pivot = p:GetPivot()

		for _, inst in ipairs(p:GetDescendants()) do
			if inst:IsA("BasePart") then
				inst.Size = inst.Size * penguinScale
			end
		end

		-- Initial placement: along forward direction from beak
		local offset = forward * (-step * (i - 1))
		local cf = base * CFrame.new(offset)

		p:PivotTo(cf)
		table.insert(penguins, p)

		lastCFrame = cf
	end

	-- Animation loop: very slow move + rotate, still connected
	task.spawn(function()
		while pelicanClone.Parent do
			local t = (os.clock() - timeStart)

			-- Very slow oscillation
			local rotWave = math.sin(t * moveSpeed) * spreadAngle
			local rotWave2 = math.cos(t * (moveSpeed * 0.7)) * (spreadAngle * 0.5)

			-- Build a target rotation around the beak base
			-- Use local axes so it looks like a neck twisting
			local twistRot = CFrame.Angles(rotWave, rotWave2, 0)

			local currentBase = base * twistRot

			-- Move/rotate each segment so it stays connected
			for i, p in ipairs(penguins) do
				if not p.Parent then break end
				local stepOffset = step * (i - 1)
				-- Add slight curvature so it looks like a neck stacking
				local bend = math.sin(t * moveSpeed + i * 0.35) * (0.15 + i * 0.01)

				local segForward = (forward * (-stepOffset))
				local bendRot = CFrame.Angles(0, bend * rotWave * 0.4, bend * 0.25)

				-- Each segment attaches to the previous with a tiny smoothing
				local targetCF = currentBase * bendRot * CFrame.new(segForward)

				-- Lerp for smooth super-slow motion
				local currentCF = p:GetPivot()
				p:PivotTo(currentCF:Lerp(targetCF, 0.03))
			end

			task.wait(0.03)
		end
	end)

	return folder
end

-- MAIN
-- Example: spawn when a player joins (or you can call this from a remote event)
game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local veryLargeScale = 20 -- super large pelican (adjust)
		local pelicanClone = cloneAndSizePelicanToPlayer(PelicanTemplate, player, veryLargeScale)

		-- Make sure it "goes to player position"
		pelicanClone:PivotTo(hrp.CFrame)

		-- Find beak position
		local beakCF = findBeakCFrame(pelicanClone)

		-- Penguin neck settings
		placePenguinNeckStack({
			pelicanClone = pelicanClone,
			player = player,
			penguinCount = 10,
			beakCFrame = beakCF,
			neckLength = 200,      -- how long the neck extends
			spreadAngle = 1.2,     -- rotation intensity (keep small for subtle)
			moveSpeed = 0.08        -- very slow
		})
	end)
end)

