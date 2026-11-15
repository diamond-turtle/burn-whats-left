local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local DayNightLighting = {}

local TweenTime = 8

-- night is dark so the fire actually matters
local Night = {
	Brightness = 0.3,
	Ambient = Color3.fromRGB(8, 10, 18),
	OutdoorAmbient = Color3.fromRGB(20, 26, 45),
	ExposureCompensation = -0.6,
}

type ClientController = { TimeSignal: any, PhaseSignal: any, GetPhase: () -> string }
function DayNightLighting.Hook(ClientController: ClientController)
	-- day = whatever is set in studio
	local Day = {
		Brightness = Lighting.Brightness,
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		ExposureCompensation = Lighting.ExposureCompensation,
	}
	Night.ExposureCompensation += Day.ExposureCompensation

	local tween: Tween?
	local snapped = false

	local function apply(phase: string, instant: boolean)
		local goal: { [string]: any } = if phase == "Night" then Night else Day
		if tween then
			tween:Cancel()
		end
		if instant then
			for key, value in goal do
				(Lighting :: any)[key] = value
			end
			return
		end
		local new = TweenService:Create(Lighting, TweenInfo.new(TweenTime, Enum.EasingStyle.Sine), goal)
		new:Play()
		tween = new
	end

	ClientController.TimeSignal:Connect(function(_t: number, hours: number)
		Lighting.ClockTime = hours
		if not snapped then
			snapped = true
			apply(ClientController.GetPhase(), true)
		end
	end)

	ClientController.PhaseSignal:Connect(function(phase: string)
		apply(phase, false)
	end)
end

return DayNightLighting
