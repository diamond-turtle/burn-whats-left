--!strict
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local GameState = require(script.Parent.GameState)
local MonsterController = {}

local DaySpeed = 8
local NightSpeed = 14
local TurnSpeed = 4
local Up = Vector3.yAxis
local Sink = 1 -- path points float a stud over the ground

local monster: Model
local height = 0 -- pivot to feet
local tracks: { [string]: AnimationTrack } = {}
local playing: AnimationTrack?
local dayPoints: { BasePart } = {}
local nightPoints: { BasePart } = {}

local path = PathfindingService:CreatePath({
	AgentRadius = 6,
	AgentHeight = 14,
	AgentCanJump = false,
	WaypointSpacing = 4,
	Costs = { Water = math.huge, Lodge = math.huge },
})

local function IsNight(): boolean
	return GameState.Phase == "Night"
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
local function StepTo(target: Vector3)
	while true do
		local dt = RunService.Heartbeat:Wait()
		local cf = monster:GetPivot()
		local feet = cf.Position - Up * height
		local diff = target - feet
		local step = (if IsNight() then NightSpeed else DaySpeed) * dt
		local rot = cf.Rotation
		local flat = Vector3.new(diff.X, 0, diff.Z)
		if flat.Magnitude > 0.5 then
			rot = rot:Lerp(CFrame.lookAt(Vector3.zero, flat), math.min(dt * TurnSpeed, 1))
		end
		if diff.Magnitude <= step then
			monster:PivotTo(CFrame.new(target + Up * height) * rot)
			return
		end
		monster:PivotTo(CFrame.new(feet + diff.Unit * step + Up * height) * rot)
	end
end

local function GoTo(pos: Vector3): boolean
	local feet = monster:GetPivot().Position - Up * height
	if (pos - feet).Magnitude < 4 then
		return true -- already there, path errors on zero length
	end
	local ok = pcall(function()
		path:ComputeAsync(feet, pos)
	end)
	if not ok or path.Status ~= Enum.PathStatus.Success then
		warn(`monster cant path to {pos}`)
		return false
	end
	for _, point in path:GetWaypoints() do
		Play(if IsNight() then "Run" else "Walk")
		StepTo(point.Position - Up * Sink)
	end
	return true
end

local function Patrol()
	local i = 1
	while true do
		local target
		if IsNight() then
			target = nightPoints[math.random(#nightPoints)]
		else
			target = dayPoints[i]
			i = i % #dayPoints + 1
		end
		GoTo(target.Position)
		Play("Idle")
		task.wait(math.random(2, 5))
	end
end

function MonsterController._Init()
	monster = workspace:WaitForChild("Monster") :: Model

	-- so its own hitbox doesnt block the path
	local mod = Instance.new("PathfindingModifier")
	mod.PassThrough = true
	mod.Parent = monster:WaitForChild("Hitbox")

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
end

return MonsterController
