--!strict
local FireController = require(script.Parent.Parent.Components.FireController)
local GameState = require(script.Parent.Parent.Components.GameState)

return function(_context: any, set: number): string
	FireController.AddPercentage(set - GameState.FirePercentage)
	return `Fire set to {GameState.FirePercentage}%`
end
