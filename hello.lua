-- Server Script (place in ServerScriptService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = ReplicatedStorage:WaitForChild("CustomServerModeration")
local kickedFolder = root:WaitForChild("KickedPlayers")

local function cleanup()
	for _, child in ipairs(kickedFolder:GetChildren()) do
		-- Assume the folder contains instances named like the player's UserId
		local ok = false
		for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
			if tostring(child.Name) == tostring(plr.UserId) then
				ok = true
				break
			end
		end

		if ok then
			child:Destroy()
		end
	end
end

while true do
	cleanup()
	task.wait(1)
end
