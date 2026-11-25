--!strict
local FinaleController = require(script.Parent.Parent.Components.FinaleController)
local LogController = require(script.Parent.Parent.Components.LogController)
local GameState = require(script.Parent.Parent.Components.GameState)

return function(_context: any, matches: number?): string
	if matches then
		GameState.Matches = matches
		LogController.Refresh()
	end
	FinaleController.Start()
	return `Finale started, {GameState.Matches} matches`
end
