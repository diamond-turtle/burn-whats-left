local Players = game:GetService("Players")
local GuiHelper = {}

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local gameGui = playerGui:WaitForChild("Game")

-- name has to be unique or shit blows up
function GuiHelper.GetInstance(name: string): Instance? | boolean
	if gameGui:FindFirstChild(name, true) then
		return gameGui:FindFirstChild(name, true)
	else
		print(`No instance named {name} found`)
		return false
	end
end

return GuiHelper
