--!strict
local Lodge = {}

Lodge.Zone = workspace:WaitForChild("MonsterPath"):WaitForChild("LodgeZone") :: BasePart

function Lodge.IsInside(pos: Vector3): boolean
	local rel = Lodge.Zone.CFrame:PointToObjectSpace(pos)
	local half = Lodge.Zone.Size / 2
	return math.abs(rel.X) < half.X and math.abs(rel.Y) < half.Y and math.abs(rel.Z) < half.Z
end

return Lodge
