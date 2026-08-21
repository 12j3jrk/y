-- LocalScript
-- StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local Birds =
	ReplicatedStorage:WaitForChild("Birds")

local PelicanTemplate =
	Birds:WaitForChild("Pelican")

-- =========================================================
-- SETTINGS
-- =========================================================

-- Smaller than before.
local PELICAN_SCALE = 35

-- Starts VERY high.
local START_HEIGHT = 1400

-- Starts this far horizontally from the player.
local START_DISTANCE = 1800

-- =========================================================
-- FLASH-LIKE ZOOM
-- =========================================================

-- Extremely fast.
local ZOOM_SPEED = 2200

-- How long the initial zoom lasts.
local ZOOM_TIME = 5

-- How far it must travel before disappearing.
local ZOOM_DISTANCE = 9000

-- =========================================================
-- ROAM
-- =========================================================

local ROAM_SPEED = 190

local ROAM_RADIUS = 3000

local ROAM_MIN_HEIGHT = 1000
local ROAM_MAX_HEIGHT = 1700

-- =========================================================
-- PROXIMITY
-- =========================================================

-- Physical distance from the Pelican's actual parts.
local WARNING_DISTANCE = 100

local WARNING_COOLDOWN = 3

local lastWarning = 0

-- =========================================================
-- BLACK
-- =========================================================

local function makeBlack(model)

	for _, object in ipairs(
		model:GetDescendants()
	) do

		if object:IsA("BasePart") then

			object.Color =
				Color3.new(
					0,
					0,
					0
				)

			object.Material =
				Enum.Material.SmoothPlastic
		end
	end
end

-- =========================================================
-- HIDE HEAD / BEAK
-- =========================================================

local function hideHeadAndBeak(model)

	for _, object in ipairs(
		model:GetDescendants()
	) do

		local name =
			string.lower(
				object.Name
			)

		if
			string.find(
				name,
				"head",
				1,
				true
			)
			or
			string.find(
				name,
				"beak",
				1,
				true
			)
		then

			if object:IsA("BasePart") then

				object.Transparency = 1

			elseif object:IsA("Decal") then

				object.Transparency = 1

			elseif object:IsA("Texture") then

				object.Transparency = 1
			end
		end
	end
end

-- =========================================================
-- HUMANOID ANIMATION SETUP
-- =========================================================

local function setupHumanoidAnimation(
	pelican
)

	-- -----------------------------------------------------
	-- DELETE EVERY ANIMATIONCONTROLLER
	-- -----------------------------------------------------

	for _, object in ipairs(
		pelican:GetDescendants()
	) do

		if object:IsA(
			"AnimationController"
		) then

			object:Destroy()
		end
	end

	-- -----------------------------------------------------
	-- GET HUMANOID
	-- -----------------------------------------------------

	local humanoid =
		pelican:FindFirstChildOfClass(
			"Humanoid"
		)

	if not humanoid then

		humanoid =
			Instance.new(
				"Humanoid"
			)

		humanoid.Name =
			"Humanoid"

		humanoid.DisplayDistanceType =
			Enum.HumanoidDisplayDistanceType.None

		humanoid.HealthDisplayType =
			Enum.HumanoidHealthDisplayType.AlwaysOff

		humanoid.Parent =
			pelican
	end

	-- -----------------------------------------------------
	-- FIND FLY ANYWHERE
	-- -----------------------------------------------------

	local fly =
		pelican:FindFirstChild(
			"Fly",
			true
		)

	if not fly
		or
		not fly:IsA("Animation")
	then

		warn(
			"[Pelican] Fly animation was not found."
		)

		return
	end

	-- -----------------------------------------------------
	-- PUT FLY INSIDE HUMANOID
	-- -----------------------------------------------------

	if fly.Parent ~= humanoid then

		local flyCopy =
			fly:Clone()

		flyCopy.Name =
			"Fly"

		flyCopy.Parent =
			humanoid

		fly =
			flyCopy
	end

	-- -----------------------------------------------------
	-- FIND ANIMATOR
	-- -----------------------------------------------------

	local animator =
		humanoid:FindFirstChildOfClass(
			"Animator"
		)

	if not animator then

		animator =
			Instance.new(
				"Animator"
			)

		animator.Parent =
			humanoid
	end

	-- -----------------------------------------------------
	-- PLAY
	-- -----------------------------------------------------

	local success, track =
		pcall(function()

			return animator:LoadAnimation(
				fly
			)

		end)

	if not success or not track then

		warn(
			"[Pelican] Could not load Fly animation."
		)

		return
	end

	track.Looped = true

	track.Priority =
		Enum.AnimationPriority.Action

	track:Play(
		0.05,
		1,
		1
	)

	return track
end

-- =========================================================
-- CREATE PELICAN
-- =========================================================

local function createPelican()

	local pelican =
		PelicanTemplate:Clone()

	pelican.Name =
		"MassiveSkyPelican"

	pelican.Parent =
		workspace

	if not pelican:IsA("Model") then

		pelican:Destroy()

		return nil
	end

	-- -----------------------------------------------------
	-- SCALE
	-- -----------------------------------------------------

	pcall(function()

		pelican:ScaleTo(
			PELICAN_SCALE
		)

	end)

	-- -----------------------------------------------------
	-- APPEARANCE
	-- -----------------------------------------------------

	makeBlack(
		pelican
	)

	hideHeadAndBeak(
		pelican
	)

	-- -----------------------------------------------------
	-- HUMANOID + FLY
	-- -----------------------------------------------------

	setupHumanoidAnimation(
		pelican
	)

	return pelican
end

-- =========================================================
-- GET PLAYER ROOT
-- =========================================================

local function getPlayerRoot()

	local character =
		player.Character

	if not character then
		return nil
	end

	return character:FindFirstChild(
		"HumanoidRootPart"
	)
end

-- =========================================================
-- FIND CLOSEST ACTUAL PELICAN PART
-- =========================================================

local function getClosestDistance(
	pelican,
	playerPosition
)

	local closest =
		math.huge

	for _, object in ipairs(
		pelican:GetDescendants()
	) do

		if object:IsA("BasePart") then

			local distance =
				(
					object.Position
					-
					playerPosition
				).Magnitude

			if distance < closest then
				closest = distance
			end
		end
	end

	return closest
end

-- =========================================================
-- NOTIFICATION
-- =========================================================

local function notifyPlayer()

	local now =
		os.clock()

	if
		now - lastWarning
		<
		WARNING_COOLDOWN
	then
		return
	end

	lastWarning =
		now

	local gui =
		ReplicatedStorage:FindFirstChild(
			"GUI"
		)

	if not gui then
		return
	end

	local event =
		gui:FindFirstChild(
			"ServerNotification"
		)

	if not event then
		return
	end

	if not event:IsA("RemoteEvent") then
		return
	end

	-- Normal Roblox RemoteEvent call.
	pcall(function()

		event:FireServer(
			"An error has encountered."
		)

	end)
end

-- =========================================================
-- PROXIMITY LOOP
-- =========================================================

local function proximityLoop(
	pelican
)

	while
		pelican.Parent
	do

		local root =
			getPlayerRoot()

		if root then

			local distance =
				getClosestDistance(
					pelican,
					root.Position
				)

			if
				distance
				<=
				WARNING_DISTANCE
			then

				notifyPlayer()
			end
		end

		RunService.Heartbeat:Wait()
	end
end

-- =========================================================
-- INITIAL POSITION
-- =========================================================

local function getStartPosition(
	root
)

	-- Random horizontal direction.
	local angle =
		math.random()
		*
		math.pi
		*
		2

	local direction =
		Vector3.new(
			math.cos(angle),
			0,
			math.sin(angle)
		)

	return
		root.Position
		+
		direction
		*
		START_DISTANCE
		+
		Vector3.new(
			0,
			START_HEIGHT,
			0
		)
end

-- =========================================================
-- FAST FLASH-LIKE ZOOM
-- =========================================================

local function flashZoom(
	pelican,
	root
)

	local startPosition =
		getStartPosition(
			root
		)

	-- Fly toward a point FAR beyond the player.
	local direction =
		(
			root.Position
			-
			startPosition
		).Unit

	local distanceTravelled =
		0

	local startTime =
		os.clock()

	local lastTime =
		startTime

	local targetDistance =
		ZOOM_DISTANCE

	-- Face toward the direction of travel.
	pelican:PivotTo(
		CFrame.lookAt(
			startPosition,
			startPosition
			+
			direction
		)
	)

	while
		pelican.Parent
	do

		local now =
			os.clock()

		local dt =
			now - lastTime

		lastTime =
			now

		if
			now - startTime
			>=
			ZOOM_TIME
			or
			distanceTravelled
			>=
			targetDistance
		then

			break
		end

		-- HUGE speed.
		local movement =
			ZOOM_SPEED
			*
			dt

		distanceTravelled +=
			movement

		local current =
			pelican:GetPivot()

		local position =
			current.Position

		local nextPosition =
			position
			+
			direction
			*
			movement

		-- Keep the Pelican pointed exactly
		-- along the flight direction.
		local target =
			CFrame.lookAt(
				nextPosition,
				nextPosition
				+
				direction
			)

		pelican:PivotTo(
			target
		)

		RunService.Heartbeat:Wait()
	end

	return true
end

-- =========================================================
-- ROAM TARGET
-- =========================================================

local function getRoamTarget(
	center
)

	local angle =
		math.random()
		*
		math.pi
		*
		2

	local radius =
		math.random(
			1000,
			ROAM_RADIUS
		)

	local x =
		math.cos(angle)
		*
		radius

	local z =
		math.sin(angle)
		*
		radius

	local y =
		math.random(
			ROAM_MIN_HEIGHT,
			ROAM_MAX_HEIGHT
		)

	return
		center
		+
		Vector3.new(
			x,
			y,
			z
		)
end

-- =========================================================
-- HIGH SKY ROAM
-- =========================================================

local function roam(
	pelican,
	center
)

	local target =
		getRoamTarget(
			center
		)

	while
		pelican.Parent
	do

		local current =
			pelican:GetPivot()

		local position =
			current.Position

		local direction =
			target
			-
			position

		local distance =
			direction.Magnitude

		if distance < 120 then

			target =
				getRoamTarget(
					center
				)

			continue
		end

		local directionUnit =
			direction.Unit

		local dt =
			RunService.Heartbeat:Wait()

		local movement =
			math.min(
				ROAM_SPEED
				*
				dt,
				distance
			)

		local nextPosition =
			position
			+
			directionUnit
			*
			movement

		-- Gentle wandering/bobbing.
		local t =
			os.clock()

		nextPosition +=
			Vector3.new(
				0,
				math.sin(
					t * 0.45
				)
				*
				2,
				0
			)

		local targetCF =
			CFrame.lookAt(
				nextPosition,
				nextPosition
				+
				directionUnit
			)

		pelican:PivotTo(
			current:Lerp(
				targetCF,
				0.08
			)
		)
	end
end

-- =========================================================
-- MAIN
-- =========================================================

local function start()

	local old =
		workspace:FindFirstChild(
			"MassiveSkyPelican"
		)

	if old then
		old:Destroy()
	end

	local root =
		getPlayerRoot()

	if not root then
		return
	end

	local pelican =
		createPelican()

	if not pelican then
		return
	end

	-- Start far away and high.
	local startPosition =
		getStartPosition(
			root
		)

	pelican:PivotTo(
		CFrame.lookAt(
			startPosition,
			root.Position
		)
	)

	-- Proximity detection runs independently.
	task.spawn(
		proximityLoop,
		pelican
	)

	-- Initial incredibly fast zoom,
	-- then permanent high-altitude roaming.
	task.spawn(function()

		flashZoom(
			pelican,
			root
		)

		if
			not pelican.Parent
		then
			return
		end

		-- Once the zoom has gone out of sight,
		-- switch to wandering.
		roam(
			pelican,
			root.Position
		)
	end)
end

-- =========================================================
-- START
-- =========================================================

if player.Character then

	task.wait(
		1
	)

	start()
end

-- =========================================================
-- RESPAWN
-- =========================================================

player.CharacterAdded:Connect(
	function()

		task.wait(
			1
		)

		start()
	end
)
