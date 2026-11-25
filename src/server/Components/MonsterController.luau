--!strict
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GameState = require(script.Parent.GameState)
local Lodge = require(script.Parent.Lodge)
local Signal = require(ReplicatedStorage.Packages.Signal)
local MonsterController = {}

local DaySpeed = 8
local NightSpeed = 14
local ChaseSpeed = 22 -- sprint is 24
local TurnSpeed = 4
local SightRange = 90
local GiveUp = 9
local CatchDist = 9
local Calm = 6 -- leaves you alone after a catch
local Up = Vector3.yAxis
local Sink = 1 -- path points float a stud over the ground

MonsterController.Caught = Signal.new()
MonsterController.Scripted = false -- finale, ai off

local scriptThread: thread? = nil

local monster: Model
local eyes: BasePart
local height = 0 -- pivot to feet
local tracks: { [string]: AnimationTrack } = {}
local playing: AnimationTrack?
local dayPoints: { BasePart } = {}
local nightPoints: { BasePart } = {}
local sight = RaycastParams.new()

local chasing: Player? = nil
local lastPos = Vector3.zero
local lastSeen = 0
local calmUntil = 0

local function NewPath(radius: number, lodgeCost: number): Path
	return PathfindingService:CreatePath({
		AgentRadius = radius,
		AgentHeight = 14,
		AgentCanJump = false,
		WaypointSpacing = 4,
		Costs = { Water = math.huge, Lodge = lodgeCost },
	})
end

local outPath = NewPath(6, math.huge)
local inPath = NewPath(2, 1) -- squeezes thru the small doors

local function IsNight(): boolean
	return GameState.Phase == "Night"
end

local function Feet(): Vector3
	return monster:GetPivot().Position - Up * height
end

local function Play(name: string)
	local track = tracks[name]
	if playing == track then
		return
	end
	if playing then
		playing:Stop(0.3)
	end
	playing = track
	track:Play(0.3)
end

-- server moves it so it might stutter on clients, move it client side if it looks bad
local function StepTo(target: Vector3, chase: boolean): boolean
	while true do
		local dt = RunService.Heartbeat:Wait()
		if (chasing ~= nil) ~= chase then
			return false
		end
		if MonsterController.Scripted and coroutine.running() ~= scriptThread then
			return false
		end
		local cf = monster:GetPivot()
		local feet = cf.Position - Up * height
		local diff = target - feet
		local speed = if chase then ChaseSpeed elseif IsNight() then NightSpeed else DaySpeed
		local step = speed * dt
		local rot = cf.Rotation
		local flat = Vector3.new(diff.X, 0, diff.Z)
		if flat.Magnitude > 0.5 then
			rot = rot:Lerp(CFrame.lookAt(Vector3.zero, flat), math.min(dt * TurnSpeed, 1))
		end
		if diff.Magnitude <= step then
			monster:PivotTo(CFrame.new(target + Up * height) * rot)
			return true
		end
		monster:PivotTo(CFrame.new(feet + diff.Unit * step + Up * height) * rot)
	end
end

local function GoTo(pos: Vector3, chase: boolean, steps: number?): boolean
	local feet = Feet()
	if (pos - feet).Magnitude < 4 then
		return true -- already there, path errors on zero length
	end
	local path = if GameState.FirePercentage == 0 or Lodge.IsInside(feet) then inPath else outPath
	local ok = pcall(function()
		path:ComputeAsync(feet, pos)
	end)
	if not ok or path.Status ~= Enum.PathStatus.Success then
		if not chase and not MonsterController.Scripted then
			warn(`monster cant path to {pos}`)
		end
		return false
	end
	for i, point in path:GetWaypoints() do
		if steps and i > steps then
			break
		end
		Play(if chase or IsNight() then "Run" else "Walk")
		if not StepTo(point.Position - Up * Sink, chase) then
			return false
		end
	end
	return true
end

local function Chase()
	while chasing do
		if os.clock() - lastSeen > GiveUp then
			chasing = nil
			break
		end
		-- 8 steps per repath, less and it jitters on corners
		if not GoTo(lastPos, true, 8) or (lastPos - Feet()).Magnitude < 4 then
			Play("Idle")
			task.wait(0.3)
		end
	end
end

local function Rest(t: number)
	Play("Idle")
	local stop = os.clock() + t
	while os.clock() < stop and not chasing do
		task.wait(0.2)
	end
end

local function Patrol()
	local i = 1
	while true do
		if MonsterController.Scripted then
			task.wait(0.5)
			continue
		end
		if chasing then
			Chase()
			Rest(2)
			continue
		end
		if IsNight() then
			GoTo(nightPoints[math.random(#nightPoints)].Position, false)
		elseif GoTo(dayPoints[i].Position, false) then
			i = i % #dayPoints + 1
		end
		Rest(math.random(2, 5))
	end
end

local function Look()
	local lit = false -- no smelling before the first match
	while true do
		task.wait(0.2)
		if GameState.FirePercentage > 0 then
			lit = true
		end
		if os.clock() < calmUntil or MonsterController.Scripted then
			continue
		end
		local pivot = monster:GetPivot().Position
		for _, player in Players:GetPlayers() do
			local character = player.Character
			if not character then
				continue
			end
			local root = character:FindFirstChild("HumanoidRootPart")
			if not root or not root:IsA("BasePart") then
				continue
			end
			local inside = Lodge.IsInside(root.Position)
			if inside and GameState.FirePercentage > 0 then
				continue -- safe by the fire
			end

			local seen = inside and lit -- fire died, it smells you
			if not seen and (root.Position - eyes.Position).Magnitude < SightRange then
				local hit = workspace:Raycast(eyes.Position, root.Position - eyes.Position, sight)
				seen = hit ~= nil and hit.Instance:IsDescendantOf(character)
			end
			if seen and (chasing == nil or chasing == player) then
				chasing = player
				lastPos = root.Position
				lastSeen = os.clock()
			end

			local d = root.Position - pivot
			if chasing == player and Vector3.new(d.X, 0, d.Z).Magnitude < CatchDist then
				chasing = nil
				calmUntil = os.clock() + Calm
				MonsterController.Caught:Fire(player)
			end
		end
	end
end

-- walks the points in order, ai stays off until Release
function MonsterController.RunScripted(points: { Vector3 })
	MonsterController.Scripted = true
	chasing = nil
	scriptThread = coroutine.running()
	for _, pos in points do
		if scriptThread ~= coroutine.running() then
			return -- another run took over
		end
		if not GoTo(pos, false) then
			Play("Walk")
			StepTo(pos, false) -- no path, just walk straight
		end
	end
	Play("Idle")
end

function MonsterController.Release()
	MonsterController.Scripted = false
	scriptThread = nil
end

function MonsterController._Init()
	monster = workspace:WaitForChild("Monster") :: Model
	eyes = monster:WaitForChild("Eyes") :: BasePart

	-- so its own hitbox doesnt block the path
	local mod = Instance.new("PathfindingModifier")
	mod.PassThrough = true
	mod.Parent = monster:WaitForChild("Hitbox")

	sight.FilterType = Enum.RaycastFilterType.Exclude
	sight.FilterDescendantsInstances = { monster, Lodge.Zone }

	local cf, size = monster:GetBoundingBox()
	height = monster:GetPivot().Y - (cf.Y - size.Y / 2)

	local animator = monster:WaitForChild("AnimationController"):WaitForChild("Animator") :: Animator
	local anims = monster:WaitForChild("Animations")
	for _, name in { "Walk", "Run", "Idle" } do
		local track = animator:LoadAnimation(anims:WaitForChild(name) :: Animation)
		track.Looped = true
		tracks[name] = track
	end

	local folder = workspace:WaitForChild("MonsterPath")
	for _, point in folder:WaitForChild("Day"):GetChildren() do
		dayPoints[tonumber(point.Name) :: number] = point :: BasePart
		table.insert(nightPoints, point :: BasePart)
	end
	for _, point in folder:WaitForChild("Night"):GetChildren() do
		table.insert(nightPoints, point :: BasePart)
	end

	monster:PivotTo(CFrame.new(dayPoints[1].Position + Up * height))
	task.spawn(Patrol)
	task.spawn(Look)
end

return MonsterController
