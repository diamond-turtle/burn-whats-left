local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Jolt = require(ReplicatedStorage.Packages.Jolt)
local Signal = require(ReplicatedStorage.Packages.Signal)
local DayNight = require(ReplicatedStorage.Shared.DayNight)
local ClientController = {}

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

ClientController.State = {
	FirePercentage = 100,
	Matches = 0,
	Logs = 0,
	Stockpile = 0,
	GamePhase = 0,
	Phase = "Day",
	Time = 0,
	Day = 1,
}
local fireBase = 100
local fireBaseTick = 0
local timeBase = 0
local timeBaseTick = 0
local dayBase = 1
ClientController.FireSignal = Signal.new()
ClientController.TimeSignal = Signal.new() -- every frame, (t, hours)
ClientController.PhaseSignal = Signal.new()

-- Jolt
local fireChannel = Jolt.Client("fireState")
local timeChannel = Jolt.Client("timeState")
local snapshotChannel = Jolt.Client("gameSnapshot")

-- Hooks
local function nowTick()
	return math.floor(workspace:GetServerTimeNow())
end

local function refreshFire()
	local percentage = math.max(fireBase - (nowTick() - fireBaseTick), 0)
	ClientController.State.FirePercentage = percentage
	ClientController.FireSignal:Fire(percentage)
end

local function fireStateChanged(percentage, tick)
	fireBase = percentage
	fireBaseTick = tick
	refreshFire()
end

local function startFireLoop()
	local last = nowTick()
	while true do
		task.wait(last + 1 - workspace:GetServerTimeNow())
		last += 1
		if ClientController.State.FirePercentage > 0 then
			refreshFire()
		end
	end
end

local function timeStateChanged(t, tick, day)
	timeBase = t
	timeBaseTick = tick
	dayBase = day
end

local function refreshTime()
	local state = ClientController.State
	local raw = timeBase + (workspace:GetServerTimeNow() - timeBaseTick)
	local t = raw % DayNight.CycleLength
	state.Time = t
	state.Day = dayBase + math.floor(raw / DayNight.CycleLength)

	local phase = DayNight.GetPhase(t)
	if phase ~= state.Phase then
		state.Phase = phase
		ClientController.PhaseSignal:Fire(phase)
	end
	ClientController.TimeSignal:Fire(t, DayNight.GetHours(t))
end

function ClientController.GetFirePercentage(): number
	return ClientController.State.FirePercentage
end

function ClientController.GetTime(): number
	return ClientController.State.Time
end

function ClientController.GetPhase(): string
	return ClientController.State.Phase
end

-- Will be responsible for listening to gamestate changes, such as fire state, game phase, etc
function ClientController._Init()
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

	fireChannel:Connect(fireStateChanged)
	timeChannel:Connect(timeStateChanged)
	local snapshot = snapshotChannel:Invoke()

	for key, value in snapshot do
		ClientController.State[key] = value
	end
	fireBase = snapshot.FirePercentage
	fireBaseTick = snapshot.FireTick
	refreshFire()

	timeStateChanged(snapshot.Time, snapshot.TimeTick, snapshot.Day)
	RunService.Heartbeat:Connect(refreshTime)

	startFireLoop()
end

return ClientController
