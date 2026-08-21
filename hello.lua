-- LocalScript
-- StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

local Birds = ReplicatedStorage:WaitForChild("Birds")
local PelicanTemplate = Birds:WaitForChild("Pelican")

--========================================================--
-- SETTINGS
--========================================================--

-- Large, but not absurdly huge.
local PELICAN_SCALE = 30

-- ALWAYS above the player.
local SKY_HEIGHT = 900

-- Distance in front/behind of the player for the zoom.
local START_DISTANCE = 1800

-- How far it flies across the sky.
local ZOOM_DISTANCE = 10000

-- VERY fast.
local ZOOM_SPEED = 2600

-- Small amount of sideways variation.
local SIDE_OFFSET = 700

-- After zooming away, roaming speed.
local ROAM_SPEED = 180

local ROAM_RADIUS = 3000

local ROAM_MIN_HEIGHT = 800
local ROAM_MAX_HEIGHT = 1500

-- Actual physical proximity.
local WARNING_DISTANCE = 100

local WARNING_COOLDOWN = 3

--========================================================--
-- FIND FLY ANIMATION
--========================================================--

local function findFly(model)

	for _, object in ipairs(
		model:GetDescendants()
	) do

		if
			object:IsA("Animation")
			and
			string.lower(object.Name) == "fly"
		then

			return object
		end
	end

	return nil
end

--========================================================--
-- HUMANOID ANIMATION
--========================================================--

local function setupFlyAnimation(pelican)

	-- Remove AnimationControllers completely.
	for _, object in ipairs(
		pelican:GetDescendants()
	) do

		if object:IsA("AnimationController") then
			object:Destroy()
		end
	end

	-- Find/create Humanoid.
	local humanoid =
		pelican:FindFirstChildOfClass(
			"Humanoid"
		)

	if not humanoid then

		humanoid =
			Instance.new("Humanoid")

		humanoid.Name = "Humanoid"

		humanoid.Parent =
			pelican
	end

	-- Find the original Fly animation.
	local fly =
		findFly(pelican)

	if not fly then

		warn(
			"[Pelican] No Animation named Fly was found."
		)

		return
	end

	-- Remove any old Fly copies inside Humanoid.
	for _, object in ipairs(
		humanoid:GetChildren()
	) do

		if
			object:IsA("Animation")
			and
			string.lower(object.Name) == "fly"
		then

			object:Destroy()
		end
	end

	-- Put Fly DIRECTLY inside Humanoid.
	local humanoidFly =
		fly:Clone()

	humanoidFly.Name = "Fly"
	humanoidFly.Parent = humanoid

	-- Animator.
	local animator =
		humanoid:FindFirstChildOfClass(
			"Animator"
		)

	if not animator then

		animator =
			Instance.new("Animator")

		animator.Parent =
			humanoid
	end

	-- Load animation.
	local success, track =
		pcall(function()

			return animator:LoadAnimation(
				humanoidFly
			)

		end)

	if not success or not track then

		warn(
			"[Pelican] Failed to load Fly."
		)

		return
	end

	track.Looped = true
	track.Priority =
		Enum.AnimationPriority.Action

	track:Play(
		0,
		1,
		1
	)

	-- Make absolutely sure it starts.
	task.defer(function()

		if track then
			track:Play(
				0,
				1,
				1
			)
		end
	end)

	return track
end

--========================================================--
-- UNANCHOR
--========================================================--

local function unanchorPelican(pelican)

	for _, object in ipairs(
		pelican:GetDescendants()
	) do

		if object:IsA("BasePart") then

			object.Anchored = false

			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = false

			object.Massless = true
		end
	end
end

--========================================================--
-- BLACK PELICAN
--========================================================--

local function makeBlack(pelican)

	for _, object in ipairs(
		pelican:GetDescendants()
	) do

		if object:IsA("BasePart") then

			object.Color =
				Color3.new(0, 0, 0)

			object.Material =
				Enum.Material.SmoothPlastic

		end
	end
end

--========================================================--
-- HIDE HEAD / BEAK
--========================================================--

local function hideHeadAndBeak(pelican)

	for _, object in ipairs(
		pelican:GetDescendants()
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

--========================================================--
-- CREATE PELICAN
--========================================================--

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

	-- Scale it.
	pcall(function()

		pelican:ScaleTo(
			PELICAN_SCALE
		)

	end)

	makeBlack(
		pelican
	)

	hideHeadAndBeak(
		pelican
	)

	-- IMPORTANT:
	-- Do this before animation setup.
	unanchorPelican(
		pelican
	)

	-- Humanoid + Fly.
	setupFlyAnimation(
		pelican
	)

	return pelican
end

--========================================================--
-- GET PLAYER
--========================================================--

local function getRoot()

	local character =
		Player.Character

	if not character then
		return nil
	end

	return character:FindFirstChild(
		"HumanoidRootPart"
	)
end

--========================================================--
-- PROXIMITY
--========================================================--

local lastNotification = 0

local function getClosestPartDistance(
	pelican,
	position
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
					position
				).Magnitude

			if distance < closest then
				closest = distance
			end
		end
	end

	return closest
end

local function proximityLoop(
	pelican
)

	while pelican.Parent do

		local root =
			getRoot()

		if root then

			local distance =
				getClosestPartDistance(
					pelican,
					root.Position
				)

			if
				distance
				<=
				WARNING_DISTANCE
			then

				local now =
					os.clock()

				if
					now - lastNotification
					>=
					WARNING_COOLDOWN
				then

					lastNotification =
						now

					-- Normal RemoteEvent attempt.
					local gui =
						ReplicatedStorage:FindFirstChild(
							"GUI"
						)

					if gui then

						local event =
							gui:FindFirstChild(
								"ServerNotification"
							)

						if
							event
							and
							event:IsA(
								"RemoteEvent"
							)
						then

							pcall(function()

								event:FireServer(
									"An error has encountered."
								)

							end)
						end
					end
				end
			end
		end

		RunService.Heartbeat:Wait()
	end
end

--========================================================--
-- SKY ZOOM
--========================================================--

local function skyZoom(
	pelican,
	root
)

	-- Direction is HORIZONTAL.
	-- It does NOT point toward the player.

	local camera =
		workspace.CurrentCamera

	local horizontalDirection

	if camera then

		horizontalDirection =
			Vector3.new(
				camera.CFrame.LookVector.X,
				0,
				camera.CFrame.LookVector.Z
			)

		if horizontalDirection.Magnitude
			<
			0.01
		then

			horizontalDirection =
				Vector3.new(
					0,
					0,
					-1
				)

		else

			horizontalDirection =
				horizontalDirection.Unit
		end

	else

		horizontalDirection =
			Vector3.new(
				0,
				0,
				-1
			)
	end

	-- Start ABOVE and slightly behind the player.
	local sideDirection =
		Vector3.new(
			-horizontalDirection.Z,
			0,
			horizontalDirection.X
		)

	local startPosition =

		root.Position

		+
		Vector3.new(
			0,
			SKY_HEIGHT,
			0
		)

		-
		horizontalDirection
		*
		START_DISTANCE

		+
		sideDirection
		*
		SIDE_OFFSET

	-- Face horizontally.
	pelican:PivotTo(
		CFrame.lookAt(
			startPosition,
			startPosition
			+
			horizontalDirection
		)
	)

	local distance =
		0

	local last =
		os.clock()

	--====================================================--
	-- BLAST ACROSS THE SKY
	--====================================================--

	while
		pelican.Parent
		and
		distance < ZOOM_DISTANCE
	do

		local now =
			os.clock()

		local dt =
			now - last

		last =
			now

		-- Keep speed INSANELY fast.
		local movement =
			ZOOM_SPEED * dt

		distance +=
			movement

		local current =
			pelican:GetPivot()

		local nextPosition =

			current.Position

			+
			horizontalDirection
			*
			movement

		-- Tiny vertical wave so it doesn't
		-- look like a perfectly straight line.
		nextPosition +=
			Vector3.new(
				0,
				math.sin(
					now * 3
				)
				*
				0.8,
				0
			)

		pelican:PivotTo(

			CFrame.lookAt(
				nextPosition,
				nextPosition
				+
				horizontalDirection
			)
		)

		RunService.Heartbeat:Wait()
	end
end

--========================================================--
-- ROAM
--========================================================--

local function randomRoamTarget(
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
			1200,
			3000
		)

	return center +

		Vector3.new(
			math.cos(angle)
			*
			radius,

			math.random(
				ROAM_MIN_HEIGHT,
				ROAM_MAX_HEIGHT
			),

			math.sin(angle)
			*
			radius
		)
end

local function roam(
	pelican,
	center
)

	local target =
		randomRoamTarget(
			center
		)

	while pelican.Parent do

		local current =
			pelican:GetPivot()

		local position =
			current.Position

		local difference =
			target
			-
			position

		local distance =
			difference.Magnitude

		if distance < 150 then

			target =
				randomRoamTarget(
					center
				)

			continue
		end

		local direction =
			difference.Unit

		local dt =
			RunService.Heartbeat:Wait()

		local movement =
			math.min(
				ROAM_SPEED * dt,
				distance
			)

		local nextPosition =
			position
			+
			direction
			*
			movement

		pelican:PivotTo(

			CFrame.lookAt(
				nextPosition,
				nextPosition
				+
				direction
			)
		)
	end
end

--========================================================--
-- START
--========================================================--

local function start()

	local old =
		workspace:FindFirstChild(
			"MassiveSkyPelican"
		)

	if old then
		old:Destroy()
	end

	local root =
		getRoot()

	if not root then
		return
	end

	local pelican =
		createPelican()

	if not pelican then
		return
	end

	-- Proximity detection always runs.
	task.spawn(
		proximityLoop,
		pelican
	)

	--====================================================--
	-- FLY ABOVE PLAYER
	--====================================================--

	task.spawn(function()

		-- Give the animation a moment to start.
		task.wait(0.25)

		-- FAST HORIZONTAL ZOOM.
		skyZoom(
			pelican,
			root
		)

		if not pelican.Parent then
			return
		end

		--================================================--
		-- NOW ROAM FAR AWAY
		--================================================--

		roam(
			pelican,
			root.Position
		)
	end)
end

--========================================================--
-- INITIAL
--========================================================--

if Player.Character then

	task.wait(1)

	start()
end

--========================================================--
-- RESPAWN
--========================================================--

Player.CharacterAdded:Connect(
	function()

		task.wait(1)

		start()
	end
)
