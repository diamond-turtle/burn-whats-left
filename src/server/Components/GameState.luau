--!strict
-- Needed for snapshotting the game whenever we need to
local GameState = {
	FirePercentage = 0,
	Matches = 6, -- 1 first fire, 5 relights
	Logs = 0,
	Stockpile = 0,
	Piles = {} :: { [string]: number }, -- logs in each lodge pile
	Trees = {} :: { [string]: number }, -- logs left in each tree
	Tools = {} :: { [string]: boolean }, -- kept thru death
	Burned = {} :: { [string]: boolean }, -- furniture names
	GamePhase = 0,
	Finale = 0, -- finale step, 0 = not started
	Phase = "Day" :: string, -- day or night
	Time = 0, -- seconds into the day/night cycle
	Day = 1,
	Cold = 100, -- drains outside
}

return GameState
