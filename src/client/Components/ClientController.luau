local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Jolt = require(ReplicatedStorage.Packages.Jolt)
local ClientController = {}

-- Variables

-- Jolt
local fireChannel = Jolt.Client("fireState")

-- Hooks
local function fireStateChanged(args)
	print("Fire state changed:", args)
end

function ClientController._Init()
	fireChannel:Connect(fireStateChanged)
end

return ClientController
