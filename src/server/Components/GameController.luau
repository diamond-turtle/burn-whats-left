--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Jolt = require(ReplicatedStorage.Packages.Jolt)
local FireController = require(script.Parent.FireController)
local GameController = {}

-- Variables

-- Jolt
local fireStateChannel = Jolt.Server("fireState")

-- Hooks
local function fireStateChanged(bool)
	fireStateChannel:FireAll(bool)
end

function GameController._Init()
	FireController.FireChanged:Connect(fireStateChanged)
end

return GameController
