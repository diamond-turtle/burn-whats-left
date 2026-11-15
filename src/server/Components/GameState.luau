--!strict
-- Needed for snapshotting the game whenever we need to
local GameState = {
	FirePercentage = 0,
	Matches = 2,
	Logs = 2,
	Stockpile = 0,
	Piles = {} :: { [string]: number }, -- logs in each lodge pile
	SourceLogs = 20, -- placeholder until trees
	GamePhase = 0,
	Time = 0,
}

return GameState
