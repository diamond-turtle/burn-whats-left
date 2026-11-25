local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiHelper = require(ReplicatedStorage.Shared.GuiHelper)
local ColdHud = {}

type ClientController = { ColdSignal: any, GetCold: () -> number }
function ColdHud.Hook(ClientController: ClientController)
	local ColdBar = GuiHelper.GetInstance("ColdBar") :: Frame
	local Fill = ColdBar:WaitForChild("Fill") :: Frame
	local Text = ColdBar:WaitForChild("Text") :: TextLabel

	local function update(cold: number)
		Text.Text = `{math.floor(cold)}%`
		Fill.Size = UDim2.fromScale(cold / 100, 1)
	end

	update(ClientController.GetCold())
	ClientController.ColdSignal:Connect(update)
end

return ColdHud
