local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiHelper = require(ReplicatedStorage.Shared.GuiHelper)
local FirePercentageHud = {}

type ClientController = { FireSignal: any, GetFirePercentage: () -> number }
function FirePercentageHud.Hook(ClientController: ClientController)
	local FireBar = GuiHelper.GetInstance("FireBar") :: Frame
	local Fill = FireBar:WaitForChild("Fill") :: Frame
	local Text = FireBar:WaitForChild("Text") :: TextLabel

	local function update(percentage: number)
		Text.Text = `{percentage}%`
		Fill.Size = UDim2.fromScale(percentage / 100, 1)
	end

	update(ClientController.GetFirePercentage())
	ClientController.FireSignal:Connect(update)
end

return FirePercentageHud
