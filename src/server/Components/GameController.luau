--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Jolt = require(ReplicatedStorage.Packages.Jolt)
local FireController = require(script.Parent.FireController)
local GameState = require(script.Parent.GameState)
local TimeController = require(script.Parent.TimeController)
local MonsterController = require(script.Parent.MonsterController)
local ColdController = require(script.Parent.ColdController)
local LogController = require(script.Parent.LogController)
local TreeController = require(script.Parent.TreeController)
local FinaleController = require(script.Parent.FinaleController)
local GameController = {}

-- Jolt
local fireStateChannel = Jolt.Server("fireState")
local timeStateChannel = Jolt.Server("timeState")
local coldStateChannel = Jolt.Server("coldState")
local itemsStateChannel = Jolt.Server("itemsState")
local snapshotChannel = Jolt.Server("gameSnapshot")

local function getFire()
	return GameState.FirePercentage
end

-- Hooks
local function fireChanged()
	fireStateChannel:FireAll(getFire(), FireController.Tick)
end

local function timeChanged()
	timeStateChannel:FireAll(GameState.Time, TimeController.Tick, GameState.Day)
end

local function getItems()
	return {
		Matches = GameState.Matches,
		Logs = GameState.Logs,
		Stockpile = GameState.Stockpile,
		TreesLeft = TreeController.TreesLeft(),
		Tools = GameState.Tools,
	}
end

local function itemsChanged()
	itemsStateChannel:FireAll(getItems())
end

local function coldChanged()
	coldStateChannel:FireAll(GameState.Cold)
end

-- sent to the client on join
local function getSnapshot(_player)
	return {
		FirePercentage = getFire(),
		FireTick = FireController.Tick,
		Items = getItems(),
		Finale = GameState.Finale,
		Objective = FinaleController.Objective,
		GamePhase = GameState.GamePhase,
		Time = GameState.Time,
		TimeTick = TimeController.Tick,
		Phase = GameState.Phase,
		Day = GameState.Day,
		Cold = GameState.Cold,
	}
end

local function checkLose()
	if GameState.FirePercentage == 0 and GameState.Matches <= 0 and GameState.Finale == 0 then
		print("lose")
		-- make this actually do something when im not lazy
	end
end

-- stub, snapshots later
local function kill(player: Player, why: string)
	print(`{player.Name} died: {why}`)
	local character = player.Character
	local spawn = workspace:FindFirstChild("SpawnLocation")
	if character and spawn and spawn:IsA("BasePart") then
		character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
	end
	ColdController.Reset()
end

function GameController._Init()
	snapshotChannel.OnInvoke = getSnapshot
	FireController.PercentageChanged:Connect(fireChanged)
	FireController.PercentageChanged:Connect(checkLose)
	TimeController.PhaseChanged:Connect(timeChanged)
	TimeController.TimeSet:Connect(timeChanged)
	ColdController.ColdChanged:Connect(coldChanged)
	ColdController.Frozen:Connect(function(player: Player)
		kill(player, "cold")
	end)
	MonsterController.Caught:Connect(function(player: Player)
		kill(player, "monster")
	end)
	FinaleController.Caught:Connect(function(player: Player)
		kill(player, "finale")
	end)
	LogController.Changed:Connect(itemsChanged)
end

return GameController
