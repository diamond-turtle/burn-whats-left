local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientController = require(script.Parent.ClientController)

local MenuController = {}
local HudFolder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Gui"):WaitForChild("Hud")
type HudModule = { Hook: (any) -> () }

function MenuController._Init()
	for _, mod in HudFolder:GetChildren() do
		if mod:IsA("ModuleScript") then
			local module = require(mod) :: HudModule
			task.spawn(module.Hook, ClientController)
		end
	end
end

return MenuController
