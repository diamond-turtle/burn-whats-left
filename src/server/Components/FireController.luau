--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameState = require(script.Parent.GameState)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Math = require(ReplicatedStorage.Shared.Math)
local FireController = {}

FireController.FireChanged = Signal.new()
FireController.PercentageChanged = Signal.new() -- not fired on normal drain

local function StartLoop()
	while task.wait(1) do
		if GameState.FirePercentage > 0 then
			GameState.FirePercentage -= 1

			if GameState.FirePercentage == 0 then
				FireController.FireChanged:Fire(false)
				FireController.PercentageChanged:Fire()
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

	local old = GameState.FirePercentage
	GameState.FirePercentage = Math.clamp(old + num, 0, 100)

	if GameState.FirePercentage ~= old then
		FireController.PercentageChanged:Fire()
	end
end

return FireController
