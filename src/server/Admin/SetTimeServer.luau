--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TimeController = require(script.Parent.Parent.Components.TimeController)
local GameState = require(script.Parent.Parent.Components.GameState)
local DayNight = require(ReplicatedStorage.Shared.DayNight)

return function(_context: any, hours: number): string
	TimeController.SetTime(DayNight.TimeFromHours(hours))
	return `Time set to {DayNight.Format(DayNight.GetHours(GameState.Time))} ({GameState.Phase})`
end
