local AdminClient = {}

type Cmdr = { SetActivationKeys: any }

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient")) :: Cmdr

function AdminClient._Init()
	Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })
end

return AdminClient
