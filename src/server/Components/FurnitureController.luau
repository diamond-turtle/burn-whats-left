--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameState = require(script.Parent.GameState)
local FireController = require(script.Parent.FireController)
local PromptHelper = require(ReplicatedStorage.Shared.PromptHelper)
local FurnitureController = {}

local MaxDist = 12
local DefaultFire = 20

local prompts: { ProximityPrompt } = {}

local function UpdatePrompts()
	for _, prompt in prompts do
		prompt.Enabled = GameState.FirePercentage > 0
	end
end

local function Setup(piece: Instance)
	local part = if piece:IsA("Model") then piece.PrimaryPart else piece
	if not part or not part:IsA("BasePart") then
		warn(`{piece.Name} has no part`)
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Burn"
	prompt.ObjectText = piece.Name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 1 -- no burning stuff by accident
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	table.insert(prompts, prompt)

	PromptHelper.Connect(prompt, MaxDist, function()
		if GameState.Burned[piece.Name] or GameState.FirePercentage <= 0 or GameState.FirePercentage >= 100 then
			return
		end
		local fire = (piece:GetAttribute("Fire") :: number?) or DefaultFire
		GameState.Burned[piece.Name] = true
		if piece:GetAttribute("Puzzle") then
			print(`burned puzzle item {piece.Name}`)
		end
		piece:Destroy()
		FireController.AddPercentage(fire)
	end)
end

function FurnitureController._Init()
	FireController.PercentageChanged:Connect(UpdatePrompts)
	task.spawn(function()
		for _, piece in workspace:WaitForChild("Furniture"):GetChildren() do
			Setup(piece)
		end
		UpdatePrompts()
	end)
end

return FurnitureController
