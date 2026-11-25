local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local SprintController = {}

local WalkSpeed = 16
local SprintSpeed = 24

local function Sprint(_name: string, state: Enum.UserInputState)
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = if state == Enum.UserInputState.Begin then SprintSpeed else WalkSpeed
	end
	return Enum.ContextActionResult.Pass
end

function SprintController._Init()
	-- true = touch button on phones
	ContextActionService:BindAction("Sprint", Sprint, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
	ContextActionService:SetTitle("Sprint", "Run")
end

return SprintController
