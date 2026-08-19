-- StarterPlayerScripts/AnimationOverrideClient.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ========= CONFIG =========
-- Set this to the animation id you want (example: "rbxassetid://123456789")
local ANIMATION_ID = "rbxassetid://INSERT_ANIMATION_ID_HERE"
-- ==========================

local function getAnimationTrack(controller)
	-- Create Animation instance and load it on the controller
	local anim = Instance.new("Animation")
	anim.AnimationId = ANIMATION_ID
	return controller:LoadAnimation(anim)
end

local function stopAllTracks(controller)
	-- On AnimationController, tracks are created via controller:LoadAnimation(...)
	-- We'll track the one we create and stop it, and also stop any others we find.
	-- (This is best-effort; if something else uses a different controller, it won't be affected.)
	for _, track in ipairs(controller:GetPlayingAnimationTracks()) do
		track:Stop(0)
	end
end

local function setupForCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	-- Humanoid.AnimationController is where the tracks will live
	local controller = humanoid:FindFirstChildOfClass("AnimationController")
	if not controller then
		controller = Instance.new("AnimationController")
		controller.Name = "AnimationController"
		controller.Parent = humanoid
	end

	local track = getAnimationTrack(controller)
	track.Looped = true

	-- Override behavior: stop other controller tracks, then play ours
	stopAllTracks(controller)

	-- Ensure the animation is playing
	track:Play(0.1)

	-- Keep re-enforcing if something else tries to start tracks on this controller
	-- (lightweight loop, not per-frame heavy)
	task.spawn(function()
		while character.Parent do
			-- If our track isn’t playing, force it back
			if not track.IsPlaying then
				stopAllTracks(controller)
				track:Play(0.1)
			end

			-- Also keep it synced to be safe
			RunService.Heartbeat:Wait()
		end
	end)
end

player.CharacterAdded:Connect(function(character)
	-- small delay so everything exists
	task.wait(0.2)
	setupForCharacter(character)
end)

if player.Character then
	task.wait(0.2)
	setupForCharacter(player.Character)
end
