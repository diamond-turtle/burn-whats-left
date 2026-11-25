--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameState = require(script.Parent.GameState)
local PromptHelper = require(ReplicatedStorage.Shared.PromptHelper)
local Signal = require(ReplicatedStorage.Packages.Signal)
local LogController = {}

local MaxCarry = 3
LogController.MaxCarry = MaxCarry
LogController.Changed = Signal.new() -- carry, piles, trees, tools
local MaxDist = 12
local PileNames = { "LogPile1", "LogPile2", "LogPile3" }

local pileModels: { [string]: Instance } = {}
local pileCaps: { [string]: number } = {}
local dropPrompts: { [string]: ProximityPrompt } = {}
local takePrompts: { [string]: ProximityPrompt } = {}

local function MakePrompt(parent: Instance, action: string, key: Enum.KeyCode): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = "Logs"
	prompt.KeyboardKeyCode = key
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

-- show only as many logs as the pile has
local function ShowLogs(name: string)
	local count = GameState.Piles[name] or 0
	for i = 1, pileCaps[name] do
		local log = pileModels[name]:FindFirstChild("Log" .. i)
		if log and log:IsA("BasePart") then
			log.Transparency = if i <= count then 0 else 1
			log.CanCollide = i <= count
		end
	end
end

function LogController.UpdatePrompts()
	local hasRoom = GameState.Logs < MaxCarry
	for name, prompt in dropPrompts do
		prompt.Enabled = GameState.Logs > 0 and GameState.Piles[name] < pileCaps[name]
	end
	for name, prompt in takePrompts do
		prompt.Enabled = hasRoom and GameState.Piles[name] > 0
	end
end

-- call after touching carry or tools
function LogController.Refresh()
	LogController.UpdatePrompts()
	LogController.Changed:Fire()
end

local function SetupPile(name: string)
	local pile = workspace:WaitForChild(name)
	local cap = 0
	for _, child in pile:GetChildren() do
		if child:IsA("BasePart") then
			child.Anchored = true -- or they fall thru the floor
			cap += 1
		end
	end
	pileModels[name] = pile
	pileCaps[name] = cap
	GameState.Piles[name] = 0
	ShowLogs(name)

	local parent = pile:WaitForChild("Log1")
	local drop = MakePrompt(parent, "Drop logs", Enum.KeyCode.E)
	local take = MakePrompt(parent, "Take log", Enum.KeyCode.F)
	take.UIOffset = Vector2.new(0, 80) -- so they dont overlap
	dropPrompts[name] = drop
	takePrompts[name] = take

	PromptHelper.Connect(drop, MaxDist, function()
		local amount = math.min(GameState.Logs, cap - GameState.Piles[name])
		if amount <= 0 then
			return
		end
		GameState.Logs -= amount
		GameState.Piles[name] += amount
		GameState.Stockpile += amount
		ShowLogs(name)
		LogController.Refresh()
	end)

	PromptHelper.Connect(take, MaxDist, function()
		if GameState.Piles[name] <= 0 or GameState.Logs >= MaxCarry then
			return
		end
		GameState.Logs += 1
		GameState.Piles[name] -= 1
		GameState.Stockpile -= 1
		ShowLogs(name)
		LogController.Refresh()
	end)

	LogController.UpdatePrompts()
end

function LogController._Init()
	for _, name in PileNames do
		task.spawn(SetupPile, name)
	end
end

return LogController
