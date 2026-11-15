--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Jolt = require(ReplicatedStorage.Packages.Jolt)
local FireController = require(script.Parent.FireController)
local GameState = require(script.Parent.GameState)
local GameController = {}

-- Jolt
local fireStateChannel = Jolt.Server("fireState")
local snapshotChannel = Jolt.Server("gameSnapshot")

local function getFire()
	return GameState.FirePercentage
end

-- Hooks
local function fireChanged()
	fireStateChannel:FireAll(getFire(), FireController.Tick)
end

-- sent to the client on join
local function getSnapshot(_player)
	return {
		FirePercentage = getFire(),
		FireTick = FireController.Tick,
		Matches = GameState.Matches,
		Logs = GameState.Logs,
		Stockpile = GameState.Stockpile,
		GamePhase = GameState.GamePhase,
	}
end

local function checkLose()
	if GameState.FirePercentage == 0 and GameState.Matches <= 0 then
		print("lose")
		-- make this actually do something when im not lazy
	end
end

function GameController._Init()
	snapshotChannel.OnInvoke = getSnapshot
	FireController.PercentageChanged:Connect(fireChanged)
	FireController.PercentageChanged:Connect(checkLose)
end

return GameController
