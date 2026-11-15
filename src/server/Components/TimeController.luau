--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameState = require(script.Parent.GameState)
local Signal = require(ReplicatedStorage.Packages.Signal)
local DayNight = require(ReplicatedStorage.Shared.DayNight)
local TimeController = {}

TimeController.PhaseChanged = Signal.new()
TimeController.TimeSet = Signal.new() -- jumps, not normal ticks
TimeController.Tick = math.floor(workspace:GetServerTimeNow())

local function CheckPhase()
	local phase = DayNight.GetPhase(GameState.Time)
	if phase ~= GameState.Phase then
		GameState.Phase = phase
		print(`{phase} {GameState.Day}`)
		TimeController.PhaseChanged:Fire(phase)
	end
end

local function StartLoop()
	while true do
		task.wait(TimeController.Tick + 1 - workspace:GetServerTimeNow())
		TimeController.Tick += 1
		GameState.Time += 1
		if GameState.Time >= DayNight.CycleLength then
			GameState.Time = 0
			GameState.Day += 1
		end
		CheckPhase()
	end
end

function TimeController.SetTime(t: number)
	GameState.Time = math.floor(t) % DayNight.CycleLength
	CheckPhase()
	TimeController.TimeSet:Fire()
end

function TimeController._Init()
	task.spawn(StartLoop)
end

return TimeController
