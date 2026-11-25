local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiHelper = require(ReplicatedStorage.Shared.GuiHelper)
local ItemsHud = {}

local MaxCarry = 3 -- same as LogController

type ClientController = { ItemsSignal: any, State: any }
function ItemsHud.Hook(ClientController: ClientController)
	local Matches = GuiHelper.GetInstance("Matches") :: TextLabel
	local Carry = GuiHelper.GetInstance("Carry") :: TextLabel
	local TreesLeft = GuiHelper.GetInstance("TreesLeft") :: TextLabel

	local function update(state)
		Matches.Text = `Matches {state.Matches}`
		Carry.Text = `Logs {state.Logs}/{MaxCarry}`
		TreesLeft.Text = `Trees {state.TreesLeft}`
	end

	update(ClientController.State)
	ClientController.ItemsSignal:Connect(update)
end

return ItemsHud
