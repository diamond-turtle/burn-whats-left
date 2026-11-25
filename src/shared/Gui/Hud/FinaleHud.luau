local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiHelper = require(ReplicatedStorage.Shared.GuiHelper)
local FinaleHud = {}

type ClientController = { FinaleSignal: any, State: any }
function FinaleHud.Hook(ClientController: ClientController)
	local Objective = GuiHelper.GetInstance("Objective") :: TextLabel
	local Now = GuiHelper.GetInstance("Now") :: TextLabel

	local function update(step: number, objective: string)
		Objective.Text = objective
		Objective.Visible = step > 0 and step ~= 5
		Now.Visible = step == 5
	end

	update(ClientController.State.Finale, ClientController.State.Objective)
	ClientController.FinaleSignal:Connect(update)
end

return FinaleHud
