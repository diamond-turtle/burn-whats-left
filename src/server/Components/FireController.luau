--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameState = require(script.Parent.GameState)
local LogController = require(script.Parent.LogController)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Math = require(ReplicatedStorage.Shared.Math)
local PromptHelper = require(ReplicatedStorage.Shared.PromptHelper)
local FireController = {}

local LogFire = 10 -- percent per log
local MaxDist = 12
local MatchFire = 100 -- percent per match

local logPrompt: ProximityPrompt
local lightPrompt: ProximityPrompt

FireController.FireChanged = Signal.new()
FireController.PercentageChanged = Signal.new() -- not fired on normal drain
FireController.Tick = math.floor(workspace:GetServerTimeNow()) -- last drain tick, client syncs to this

local function StartLoop()
	while true do
		task.wait(FireController.Tick + 1 - workspace:GetServerTimeNow())
		FireController.Tick += 1
		if GameState.FirePercentage > 0 then
			GameState.FirePercentage -= 1

			if GameState.FirePercentage == 0 then
				FireController.FireChanged:Fire(false)
				FireController.PercentageChanged:Fire()
			end
		end

		print(GameState.FirePercentage)
	end
end

local function UpdatePrompts()
	if not logPrompt then
		return
	end
	logPrompt.Enabled = GameState.FirePercentage > 0
	lightPrompt.Enabled = GameState.FirePercentage == 0 and GameState.Matches > 0
end

local function SetupPrompt()
	local fireplace = workspace:WaitForChild("Fireplace")
	local attachment = fireplace:WaitForChild("Attachment")

	logPrompt = attachment:WaitForChild("LogPrompt") :: ProximityPrompt
	lightPrompt = attachment:WaitForChild("LightPrompt") :: ProximityPrompt

	PromptHelper.Connect(logPrompt, MaxDist, function()
		if GameState.Logs <= 0 or GameState.FirePercentage <= 0 or GameState.FirePercentage >= 100 then
			return
		end
		GameState.Logs -= 1
		LogController.UpdatePrompts()
		FireController.AddPercentage(LogFire)
	end)

	PromptHelper.Connect(lightPrompt, MaxDist, function()
		if GameState.FirePercentage > 0 or GameState.Matches <= 0 then
			return
		end
		GameState.Matches -= 1
		FireController.AddPercentage(MatchFire)
	end)

	UpdatePrompts()
end

function FireController._Init()
	FireController.PercentageChanged:Connect(UpdatePrompts)
	task.spawn(SetupPrompt)
	task.spawn(function()
		StartLoop()
	end)
end

function FireController.AddPercentage(num: number)
	if GameState.FirePercentage == 0 and num > 0 then
		FireController.FireChanged:Fire(true)
	end

	local old = GameState.FirePercentage
	GameState.FirePercentage = Math.clamp(old + num, 0, 100)

	if GameState.FirePercentage ~= old then
		FireController.PercentageChanged:Fire()
	end
end

return FireController
