-- LocalScript
-- Clones a target model/penguins and stacks them on top of each other instead of spreading out
-- Replace "Penguin" with your model name

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local sourceModel = Workspace:WaitForChild("Penguin") -- change this
local clonesFolder = Workspace:FindFirstChild("Clones") or Instance.new("Folder")
clonesFolder.Name = "Clones"
clonesFolder.Parent = Workspace

local clones = {}
local spacing = 2 -- smaller = closer together
local count = 10

local function makeClone(index)
	local clone = sourceModel:Clone()
	clone.Parent = clonesFolder

	local baseCFrame = sourceModel:GetPivot()
	local offset = CFrame.new(0, spacing * index, 0) -- stacked upward

	clone:PivotTo(baseCFrame * offset)
	table.insert(clones, clone)
end

for i = 1, count do
	makeClone(i)
end

-- If you want them to stay stacked and not move apart, don't update their positions every frame.
-- If they're moving because of scripts inside the clone, disable those scripts:
for _, clone in ipairs(clones) do
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") then
			d.Disabled = true
		end
	end
end
