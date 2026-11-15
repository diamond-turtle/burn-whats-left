local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Jolt = require(ReplicatedStorage.Packages.Jolt)
local ClientController = {}

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

-- Jolt
local fireChannel = Jolt.Client("fireState")

-- Hooks
local function fireStateChanged(args)
	print("Fire state changed:", args)
end

function ClientController._Init()
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

	fireChannel:Connect(fireStateChanged)
end

return ClientController
