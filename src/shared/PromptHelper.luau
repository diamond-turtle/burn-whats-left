--!strict
local PromptHelper = {}

local function GetPos(prompt: ProximityPrompt): Vector3?
	local parent = prompt.Parent
	if parent and parent:IsA("Attachment") then
		return parent.WorldPosition
	end
	if parent and parent:IsA("BasePart") then
		return parent.Position
	end
	return nil
end

-- only runs callback if player is close enough
function PromptHelper.Connect(prompt: ProximityPrompt, maxDist: number, callback: (Player) -> ())
	prompt.Triggered:Connect(function(player: Player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local pos = GetPos(prompt)
		if not root or not pos then
			return
		end
		if (root.Position - pos).Magnitude > maxDist then
			return
		end
		callback(player)
	end)
end

return PromptHelper
