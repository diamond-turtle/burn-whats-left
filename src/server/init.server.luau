local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Jolt = require(ReplicatedStorage.Packages.Jolt)
print("Hello world, from server")

local testChannel = Jolt.Server("testChannel")
testChannel:Connect(function(player, args)
	print(player, args)
end)
