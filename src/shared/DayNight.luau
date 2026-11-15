--!strict
local DayNight = {}

DayNight.DayLength = 240 -- seconds
DayNight.NightLength = 180
DayNight.CycleLength = DayNight.DayLength + DayNight.NightLength
DayNight.DayStart = 7 -- 07:00
DayNight.NightStart = 19 -- 19:00

-- t = seconds into the cycle
function DayNight.GetPhase(t: number): string
	if t < DayNight.DayLength then
		return "Day"
	end
	return "Night"
end

function DayNight.GetHours(t: number): number
	local dayHours = DayNight.NightStart - DayNight.DayStart
	if t < DayNight.DayLength then
		return DayNight.DayStart + t / DayNight.DayLength * dayHours
	end
	local nightHours = 24 - dayHours
	return (DayNight.NightStart + (t - DayNight.DayLength) / DayNight.NightLength * nightHours) % 24
end

function DayNight.TimeFromHours(hours: number): number
	hours %= 24
	local dayHours = DayNight.NightStart - DayNight.DayStart
	if hours >= DayNight.DayStart and hours < DayNight.NightStart then
		return (hours - DayNight.DayStart) / dayHours * DayNight.DayLength
	end
	local into = (hours - DayNight.NightStart) % 24
	return DayNight.DayLength + into / (24 - dayHours) * DayNight.NightLength
end

function DayNight.Format(hours: number): string
	local h = math.floor(hours) % 24
	local m = math.floor((hours % 1) * 60)
	return string.format("%02d:%02d", h, m)
end

return DayNight
