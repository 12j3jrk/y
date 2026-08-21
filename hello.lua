-- LocalScript
-- Place in StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

local Birds = ReplicatedStorage:WaitForChild("Birds")
local PelicanTemplate = Birds:WaitForChild("Pelican")

-- =========================================================
-- SETTINGS
-- =========================================================

-- MASSIVE
local PELICAN_SCALE = 90

-- How high above the player/map the Pelican stays.
local SKY_HEIGHT = 700

-- =========================================================
-- SWARM
-- =========================================================

-- Extremely fast initial swarm.
local SWARM_DURATION = 8
local SWARM_SPEED = 420

-- How far around the player the swarm travels.
local SWARM_RADIUS = 850

-- Vertical movement during swarm.
local SWARM_VERTICAL = 260

-- =========================================================
-- ROAM
-- =========================================================

local ROAM_SPEED = 170

local ROAM_RADIUS = 1800
local ROAM_MIN_HEIGHT = 650
local ROAM_MAX_HEIGHT = 1100

-- =========================================================
-- PROXIMITY
-- =========================================================

-- How close the player needs to physically get.
local WARNING_DISTANCE = 100

-- Don't spam the notification.
local WARNING_COOLDOWN = 4

-- =========================================================
-- BLACK MODEL
-- =========================================================

local function makeBlack(model)

	for _, object in ipairs(model:GetDescendants()) do

		if object:IsA("BasePart") then

			object.Color =
				Color3.new(
					0,
					0,
					0
				)

			object.Material =
				Enum.Material.SmoothPlastic

		elseif object:IsA("Decal") then

			object.Transparency = 1

		elseif object:IsA("Texture") then

			object.Transparency = 1
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
-- FIND ANIMATION
-- =========================================================

local function findFlyAnimation(model)

	local animation =
		model:FindFirstChild(
			"Fly",
			true
		)

	if animation
		and animation:IsA("Animation")
	then

		return animation
	end

	return nil
end

-- =========================================================
-- GET / CREATE ANIMATION CONTROLLER
-- =========================================================

local function getAnimationController(model)

	local controller =
		model:FindFirstChildOfClass(
			"AnimationController"
		)

	if not controller then

		controller =
			Instance.new(
				"AnimationController"
			)

		controller.Name =
			"AnimationController"

		controller.Parent =
			model
	end

	local animator =
		controller:FindFirstChildOfClass(
			"Animator"
		)

	if not animator then

		animator =
			Instance.new(
				"Animator"
			)

		animator.Parent =
			controller
	end

	return controller, animator
end

-- =========================================================
-- PLAY FLY
-- =========================================================

local function playFlyAnimation(model)

	local animation =
		findFlyAnimation(
			model
		)

	if not animation then

		warn(
			"[Sky Pelican] Could not find Animation named 'Fly'."
		)

		return nil
	end

	local controller, animator =
		getAnimationController(
			model
		)

	local success, track =
		pcall(function()

			return animator:LoadAnimation(
				animation
			)

		end)

	if not success or not track then

		warn(
			"[Sky Pelican] Failed to load Fly animation."
		)

		return nil
	end

	track.Looped = true
	track.Priority = Enum.AnimationPriority.Action
	track:Play(
		0.2,
		1,
		1
	)

	return track
end

-- =========================================================
-- CREATE GIANT PELICAN
-- =========================================================

local function createGiantPelican()

	local pelican =
		PelicanTemplate:Clone()

	pelican.Name =
		"MassiveSkyPelican"

	pelican.Parent =
		workspace

	-- =====================================================
	-- MAKE SURE IT IS A MODEL
	-- =====================================================

	if not pelican:IsA("Model") then

		warn(
			"[Sky Pelican] Pelican isn't a Model."
		)

		pelican:Destroy()

		return nil
	end

	-- =====================================================
	-- HUMANOID
	-- =====================================================

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

	-- =====================================================
	-- SCALE
	-- =====================================================

	local success =
		pcall(function()

			pelican:ScaleTo(
				PELICAN_SCALE
			)

		end)

	if not success then

		warn(
			"[Sky Pelican] Failed to scale Pelican."
		)
	end

	-- =====================================================
	-- BLACK
	-- =====================================================

	makeBlack(
		pelican
	)

	hideHeadAndBeak(
		pelican
	)

	-- =====================================================
	-- ANIMATION
	-- =====================================================

	playFlyAnimation(
		pelican
	)

	return pelican
end

-- =========================================================
-- RANDOM SKY POSITION
-- =========================================================

local function getSkyPosition(
	center,
	radius
)

	local angle =
		math.random()
		*
		math.pi
		*
		2

	local distance =
		math.sqrt(
			math.random()
		)
		*
		radius

	local x =
		math.cos(angle)
		*
		distance

	local z =
		math.sin(angle)
		*
		distance

	local y =
		math.random(
			ROAM_MIN_HEIGHT,
			ROAM_MAX_HEIGHT
		)

	return center
		+
		Vector3.new(
			x,
			y,
			z
		)
end

-- =========================================================
-- SWARM MOVEMENT
-- =========================================================

local function swarmPelican(
	pelican,
	startPosition
)

	local start =
		os.clock()

	local lastPosition =
		startPosition

	pelican:PivotTo(
		CFrame.lookAt(
			startPosition,
			startPosition
			+
			Vector3.new(
				1,
				0,
				0
			)
		)
	)

	while
		pelican.Parent
		and
		os.clock() - start
		<
		SWARM_DURATION
	do

		local elapsed =
			os.clock()
			-
			start

		local angle =
			elapsed
			*
			(
				SWARM_SPEED
				/
				SWARM_RADIUS
			)

		-- Rapid looping path around the sky.
		local x =
			math.cos(
				angle
			)
			*
			SWARM_RADIUS

		local z =
			math.sin(
				angle
			)
			*
			SWARM_RADIUS

		-- Rapid vertical swooping.
		local y =
			SKY_HEIGHT
			+
			math.sin(
				angle
				*
				2.7
			)
			*
			SWARM_VERTICAL

		local target =
			startPosition
			+
			Vector3.new(
				x,
				y - SKY_HEIGHT,
				z
			)

		local current =
			pelican:GetPivot()

		local currentPosition =
			current.Position

		local direction =
			target
			-
			currentPosition

		if direction.Magnitude > 0.01 then

			local velocity =
				direction.Unit
				*
				SWARM_SPEED

			local nextPosition =
				currentPosition
				+
				velocity
				*
				(1 / 60)

			local facing =
				CFrame.lookAt(
					nextPosition,
					nextPosition
					+
					direction.Unit
				)

			pelican:PivotTo(
				facing
			)

			lastPosition =
				nextPosition
		end

		RunService.Heartbeat:Wait()
	end

	return lastPosition
end

-- =========================================================
-- ROAM
-- =========================================================

local function roamPelican(
	pelican,
	center
)

	local target =
		getSkyPosition(
			center,
			ROAM_RADIUS
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

		if distance < 100 then

			target =
				getSkyPosition(
					center,
					ROAM_RADIUS
				)

			continue
		end

		local movement =
			math.min(
				ROAM_SPEED
				*
				(1 / 60),
				distance
			)

		local directionUnit =
			direction.Unit

		local nextPosition =
			position
			+
			directionUnit
			*
			movement

		-- Slight natural flying motion.
		local time =
			os.clock()

		local bob =
			math.sin(
				time
				*
				0.7
			)
			*
			8

		nextPosition +=
			Vector3.new(
				0,
				bob
				*
				(1 / 60),
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
				0.12
			)
		)

		RunService.Heartbeat:Wait()
	end
end

-- =========================================================
-- PROXIMITY CHECK
-- =========================================================

local lastWarning = 0

local function checkProximity(
	pelican
)

	local character =
		Player.Character

	if not character then
		return
	end

	local root =
		character:FindFirstChild(
			"HumanoidRootPart"
		)

	if not root then
		return
	end

	local pelicanPosition =
		pelican:GetPivot().Position

	local distance =
		(
			root.Position
			-
			pelicanPosition
		).Magnitude

	if
		distance
		<=
		WARNING_DISTANCE
	then

		local now =
			os.clock()

		if
			now - lastWarning
			>=
			WARNING_COOLDOWN
		then

			lastWarning =
				now

			-- Standard Roblox RemoteEvent route.
			--
			-- This intentionally does NOT use firesignal(),
			-- because firesignal is an executor-only API.

			local notification =
				ReplicatedStorage
				:FindFirstChild(
					"GUI"
				)

			if notification then

				notification =
					notification:FindFirstChild(
						"ServerNotification"
					)

				if notification
					and notification:IsA(
						"RemoteEvent"
					)
				then

					-- If the game's server accepts
					-- this request, it can handle it.
					pcall(function()

						notification:FireServer(
							"An error has encountered."
						)

					end)
				end
			end
		end
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

	local pelican =
		createGiantPelican()

	if not pelican then
		return
	end

	local character =
		Player.Character

	if not character then
		pelican:Destroy()
		return
	end

	local root =
		character:FindFirstChild(
			"HumanoidRootPart"
		)

	if not root then
		pelican:Destroy()
		return
	end

	-- =====================================================
	-- START HIGH ABOVE PLAYER
	-- =====================================================

	local startPosition =
		root.Position
		+
		Vector3.new(
			0,
			SKY_HEIGHT,
			0
		)

	pelican:PivotTo(
		CFrame.lookAt(
			startPosition,
			root.Position
		)
	)

	-- =====================================================
	-- SWARM
	-- =====================================================

	task.spawn(function()

		local finalPosition =
			swarmPelican(
				pelican,
				startPosition
			)

		if
			pelican.Parent
		then

			-- =================================================
			-- ROAM AFTER SWARM
			-- =================================================

			roamPelican(
				pelican,
				root.Position
			)
		end
	end)

	-- =====================================================
	-- PROXIMITY
	-- =====================================================

	task.spawn(function()

		while pelican.Parent do

			checkProximity(
				pelican
			)

			RunService.Heartbeat:Wait()
		end
	end)
end

-- =========================================================
-- START
-- =========================================================

if Player.Character then

	task.wait(
		0.5
	)

	start()
end

-- =========================================================
-- RESPAWN
-- =========================================================

Player.CharacterAdded:Connect(
	function()

		task.wait(
			1
		)

		start()
	end
)
