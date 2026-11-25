--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameState = require(script.Parent.GameState)
local FireController = require(script.Parent.FireController)
local MonsterController = require(script.Parent.MonsterController)
local LogController = require(script.Parent.LogController)
local Jolt = require(ReplicatedStorage.Packages.Jolt)
local Signal = require(ReplicatedStorage.Packages.Signal)
local PromptHelper = require(ReplicatedStorage.Shared.PromptHelper)
local FinaleController = {}

-- placeholders, all of it gets hooked to puzzle 4 in week 3
local DieFrom = 30 -- fire % when you hide, so ~30 s
local NowTime = 9
local MaxDist = 12

local Steps = {
	"Pour the kerosene. Hide. Let the fire die.",
	"Hide by the back door.",
	"Let the fire die.",
	"It's inside.",
	"NOW!",
	"It burns.",
}

FinaleController.Caught = Signal.new()
FinaleController.Objective = ""

local channel = Jolt.Server("finaleState")
local folder: Instance
local pourPrompt: ProximityPrompt
local hidePrompt: ProximityPrompt
local dropPrompt: ProximityPrompt
local hider: Player? = nil
local attempt = 0

local function Points(name: string): { Vector3 }
	local list = {}
	for _, point in folder:WaitForChild(name):GetChildren() do
		if point:IsA("BasePart") then
			list[tonumber(point.Name) :: number] = point.Position
		end
	end
	return list
end

local function SetStep(step: number)
	GameState.Finale = step
	FinaleController.Objective = Steps[step] or ""
	pourPrompt.Enabled = step == 1
	hidePrompt.Enabled = step == 2
	dropPrompt.Enabled = step == 5
	channel:FireAll(step, FinaleController.Objective)
	FireController.PercentageChanged:Fire() -- so the hearth prompts update
end

local function SetTrail(lit: boolean, shown: boolean)
	for _, part in folder:WaitForChild("Trail"):GetChildren() do
		if part:IsA("BasePart") then
			part.Transparency = if shown then 0.4 else 1
			local fire = part:FindFirstChildOfClass("Fire")
			if lit and not fire then
				local new = Instance.new("Fire")
				new.Size = 8
				new.Parent = part
			elseif not lit and fire then
				fire:Destroy()
			end
		end
	end
end

local function SetFire(to: number)
	FireController.AddPercentage(to - GameState.FirePercentage)
end

local function Burn(player: Player)
	local escape = GameState.Matches > 0
	if escape then
		GameState.Matches -= 1 -- the match only goes when you drop it
		LogController.Refresh()
	end
	SetStep(6)
	SetTrail(true, true)
	SetFire(100)
	print(`finale done, {if escape then "escape" else "sacrifice"} ({player.Name})`)
	MonsterController.RunScripted(Points("Collapse"))
	-- souls, helicopter, title go here
end

local function ItCameIn()
	SetStep(4)
	local this = attempt
	MonsterController.RunScripted(Points("Inside"))
	if attempt ~= this or GameState.Finale ~= 4 then
		return
	end
	SetStep(5)
	task.wait(NowTime)
	if attempt == this and GameState.Finale == 5 then
		-- missed it, it comes out the back
		attempt += 1
		local player = hider
		if player then
			FinaleController.Caught:Fire(player)
			local hide = folder:WaitForChild("Hide") :: BasePart
			if player.Character then
				player.Character:PivotTo(hide.CFrame + Vector3.new(0, 4, 0))
			end
		end
		SetStep(2)
	end
end

function FinaleController.Start()
	if GameState.Finale > 0 and GameState.Finale < 6 then
		return
	end
	attempt += 1
	SetTrail(false, false)
	if GameState.FirePercentage == 0 then
		SetFire(100) -- debug skip from a dead fire
	end
	SetStep(1)
	task.spawn(MonsterController.RunScripted, Points("Wait"))
end

local function Setup()
	folder = workspace:WaitForChild("Finale")
	local function MakePrompt(name: string, action: string, hold: number): ProximityPrompt
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = action
		prompt.ObjectText = ""
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = hold
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Enabled = false
		prompt.Parent = folder:WaitForChild(name)
		return prompt
	end
	pourPrompt = MakePrompt("Kerosene", "Pour kerosene", 2)
	hidePrompt = MakePrompt("Hide", "Hide", 0.5)
	dropPrompt = MakePrompt("Drop", "Drop the flame", 0)
	SetTrail(false, false)

	PromptHelper.Connect(pourPrompt, MaxDist, function()
		if GameState.Finale ~= 1 then
			return
		end
		SetTrail(false, true) -- snaps to the path, cant waste it
		SetStep(2)
	end)

	PromptHelper.Connect(hidePrompt, MaxDist, function(player: Player)
		if GameState.Finale ~= 2 then
			return
		end
		hider = player
		SetStep(3)
		if GameState.FirePercentage > DieFrom or GameState.FirePercentage == 0 then
			SetFire(DieFrom)
		end
		task.spawn(MonsterController.RunScripted, Points("Outside"))
	end)

	PromptHelper.Connect(dropPrompt, MaxDist, function(player: Player)
		if GameState.Finale ~= 5 then
			return
		end
		task.spawn(Burn, player)
	end)

	FireController.FireChanged:Connect(function(lit: boolean)
		if not lit and GameState.Finale == 3 then
			task.spawn(ItCameIn)
		end
	end)
end

function FinaleController._Init()
	task.spawn(Setup)
end

return FinaleController
