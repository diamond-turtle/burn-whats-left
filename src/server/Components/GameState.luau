--!strict
-- Needed for snapshotting the game whenever we need to
local GameState = {
	FirePercentage = 100,
	Matches = 6,
	Logs = 0,
	Stockpile = 0,
	GamePhase = 0,
	Time = 0,
}

return GameState
