local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Jolt = require(ReplicatedStorage.Packages.Jolt)
local Signal = require(ReplicatedStorage.Packages.Signal)
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
}
local fireBase = 100
local fireBaseTick = 0
ClientController.FireSignal = Signal.new()

-- Jolt
local fireChannel = Jolt.Client("fireState")
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

function ClientController.GetFirePercentage(): number
	return ClientController.State.FirePercentage
end

-- Will be responsible for listening to gamestate changes, such as fire state, game phase, etc
function ClientController._Init()
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

	fireChannel:Connect(fireStateChanged)
	local snapshot = snapshotChannel:Invoke()

	for key, value in snapshot do
		ClientController.State[key] = value
	end
	fireBase = snapshot.FirePercentage
	fireBaseTick = snapshot.FireTick
	refreshFire()

	startFireLoop()
end

return ClientController
