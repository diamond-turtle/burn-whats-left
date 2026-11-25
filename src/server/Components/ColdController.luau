--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameState = require(script.Parent.GameState)
local Lodge = require(script.Parent.Lodge)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Math = require(ReplicatedStorage.Shared.Math)
local ColdController = {}

local Drain = 100 / 150 -- 2.5 min outside
local Refill = 100 / 30

ColdController.ColdChanged = Signal.new()
ColdController.Frozen = Signal.new()

local function Tick()
	if GameState.Finale > 0 then
		return -- cold holds still in the finale
	end
	local player = Players:GetPlayers()[1] -- solo game
	local character = player and player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end

	local old = GameState.Cold
	local rate = if Lodge.IsInside(root.Position) then Refill else -Drain
	GameState.Cold = Math.clamp(old + rate, 0, 100)
	if GameState.Cold ~= old then
		ColdController.ColdChanged:Fire()
	end
	if GameState.Cold == 0 then
		ColdController.Frozen:Fire(player)
	end
end

function ColdController.Reset()
	GameState.Cold = 100
	ColdController.ColdChanged:Fire()
end

function ColdController._Init()
	task.spawn(function()
		while true do
			task.wait(1)
			Tick()
		end
	end)
end

return ColdController
