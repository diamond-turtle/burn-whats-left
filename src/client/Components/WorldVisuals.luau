local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientController = require(script.Parent.ClientController)
local WorldVisuals = {}

local VisualsFolder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Visuals")
type VisualModule = { Hook: (any) -> () }

function WorldVisuals._Init()
	for _, mod in VisualsFolder:GetChildren() do
		if mod:IsA("ModuleScript") then
			local module = require(mod) :: VisualModule
			task.spawn(module.Hook, ClientController)
		end
	end
end

return WorldVisuals
