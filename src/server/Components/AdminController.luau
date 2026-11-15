local ServerScriptService = game:GetService("ServerScriptService")
local cmdr = require(ServerScriptService.ServerPackages.cmdr)
local AdminController = {}

local Admins = { 4566415505 }

function AdminController._Init()
	local registry = cmdr.Registry :: any
	registry:RegisterDefaultCommands()
	registry:RegisterCommandsIn(script.Parent.Parent:WaitForChild("Admin"))

	-- admins only
	registry:RegisterHook("BeforeRun", function(context): string?
		if not table.find(Admins, context.Executor.UserId) then
			return "No permission"
		end
		return nil
	end)
end

return AdminController
