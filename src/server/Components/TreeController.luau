--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameState = require(script.Parent.GameState)
local LogController = require(script.Parent.LogController)
local PromptHelper = require(ReplicatedStorage.Shared.PromptHelper)
local TreeController = {}

local MaxDist = 12
local DefaultLogs = 4

local prompts: { [string]: ProximityPrompt } = {}
local far: { [string]: boolean } = {}

function TreeController.TreesLeft(): number
	local n = 0
	for _, logs in GameState.Trees do
		if logs > 0 then
			n += 1
		end
	end
	return n
end

local function UpdatePrompts()
	for name, prompt in prompts do
		local axe = if far[name] then GameState.Tools.BetterAxe else GameState.Tools.Axe
		prompt.Enabled = GameState.Trees[name] > 0 and axe == true and GameState.Logs < LogController.MaxCarry
		prompt.ObjectText = if axe then `Tree ({GameState.Trees[name]})` else "Tree"
	end
end

local function Setup(tree: Instance)
	local name = tree.Name
	if prompts[name] then
		warn(`two trees named {name}`)
		return
	end
	local part = if tree:IsA("Model") then tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart") else tree
	if not part or not part:IsA("BasePart") then
		warn(`{name} has no part`)
		return
	end

	-- prompt at the foot of the trunk, not in the middle
	local cf, size = if tree:IsA("Model") then tree:GetBoundingBox() else part.CFrame, part.Size
	local attachment = Instance.new("Attachment")
	attachment.Parent = part
	attachment.WorldPosition = cf.Position - Vector3.new(0, size.Y / 2 - 3, 0)

	GameState.Trees[name] = (tree:GetAttribute("Logs") :: number?) or DefaultLogs
	far[name] = tree:GetAttribute("Far") == true

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Chop"
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.HoldDuration = 1.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = attachment
	prompts[name] = prompt

	PromptHelper.Connect(prompt, MaxDist, function()
		local axe = if far[name] then GameState.Tools.BetterAxe else GameState.Tools.Axe
		if not axe or GameState.Trees[name] <= 0 or GameState.Logs >= LogController.MaxCarry then
			return
		end
		GameState.Trees[name] -= 1
		GameState.Logs += 1
		if GameState.Trees[name] == 0 then
			tree:Destroy()
			prompts[name] = nil
		end
		LogController.Refresh()
	end)
end

function TreeController._Init()
	LogController.Changed:Connect(UpdatePrompts)
	task.spawn(function()
		for _, tree in workspace:WaitForChild("Trees"):GetChildren() do
			Setup(tree)
		end
		UpdatePrompts()
		LogController.Changed:Fire() -- hud gets the tree count
	end)
end

return TreeController
