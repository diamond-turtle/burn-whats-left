--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameState = require(script.Parent.GameState)
local LogController = require(script.Parent.LogController)
local PromptHelper = require(ReplicatedStorage.Shared.PromptHelper)
local ToolController = {}

local MaxDist = 12

-- Axe in the lodge, Rope at the wreck, BetterAxe in the village
local function Setup(tool: Instance)
	local name = tool.Name
	local part = if tool:IsA("Model") then tool.PrimaryPart or tool:FindFirstChildWhichIsA("BasePart") else tool
	if not part or not part:IsA("BasePart") then
		warn(`{name} has no part`)
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Take"
	prompt.ObjectText = (tool:GetAttribute("Label") :: string?) or name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	PromptHelper.Connect(prompt, MaxDist, function()
		if GameState.Tools[name] then
			return
		end
		GameState.Tools[name] = true
		tool:Destroy()
		LogController.Refresh()
	end)
end

function ToolController._Init()
	task.spawn(function()
		for _, tool in workspace:WaitForChild("Tools"):GetChildren() do
			Setup(tool)
		end
	end)
end

return ToolController
