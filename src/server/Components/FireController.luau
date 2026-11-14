--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameState = require(script.Parent.GameState)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Math = require(ReplicatedStorage.Shared.Math)
local FireController = {}

FireController.TickDuration = 1 -- in seconds
FireController.FireChanged = Signal.new()

local function StartLoop()
	while task.wait(FireController.TickDuration) do
		if GameState.FirePercentage > 0 then
			GameState.FirePercentage -= 1

			if GameState.FirePercentage == 0 then
				FireController.FireChanged:Fire(false)
			end
		end
	end
end

function FireController._Init()
	task.spawn(function()
		StartLoop()
	end)
end

function FireController.AddPercentage(num: number)
	if GameState.FirePercentage == 0 and num > 0 then
		FireController.FireChanged:Fire(true)
	end

	GameState.FirePercentage = Math.clamp(GameState.FirePercentage + num, 0, 100)
end

return FireController
