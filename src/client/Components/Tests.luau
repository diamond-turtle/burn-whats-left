local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Jolt = require(ReplicatedStorage.Packages.Jolt)
local Tests = {}

local _testChannel = Jolt.Client("testChannel")
local monster = game.Workspace:WaitForChild("Monster")
local _Animator = monster:WaitForChild("AnimationController"):WaitForChild("Animator") :: Animator

function Tests._Init()
	--[[
	testChannel:Fire("i connected")

	local animations = monster:WaitForChild("Animations"):GetChildren()
	while task.wait(5) do
		for _, track in ipairs(Animator:GetPlayingAnimationTracks()) do
			track:Stop()
		end

		local chosenIndex = math.random(1, #animations)
		local chosenAnim = animations[chosenIndex] :: Animation

		local track = Animator:LoadAnimation(chosenAnim)
		track.Looped = true
		track:Play()

		print("playing", tostring(chosenAnim))
	end
    
    --]]
end

return Tests
