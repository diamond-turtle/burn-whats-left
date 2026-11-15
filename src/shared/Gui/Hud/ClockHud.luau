local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiHelper = require(ReplicatedStorage.Shared.GuiHelper)
local DayNight = require(ReplicatedStorage.Shared.DayNight)
local ClockHud = {}

type ClientController = { TimeSignal: any }
function ClockHud.Hook(ClientController: ClientController)
	local Clock = GuiHelper.GetInstance("Clock") :: TextLabel

	ClientController.TimeSignal:Connect(function(_t: number, hours: number)
		local text = DayNight.Format(hours)
		if Clock.Text ~= text then
			Clock.Text = text
		end
	end)
end

return ClockHud
