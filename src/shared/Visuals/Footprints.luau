local RunService = game:GetService("RunService")
local Footprints = {}

local Step = 6
local Side = 3
local Fade = 90 -- back to grass after this

function Footprints.Hook(_ClientController: any)
	local monster = workspace:WaitForChild("Monster") :: Model
	local terrain = workspace.Terrain
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { terrain }

	local last = monster:GetPivot().Position
	local left = true

	-- client only, flattens the grass where it stepped
	local function Print(pos: Vector3)
		local hit = workspace:Raycast(pos + Vector3.yAxis * 10, Vector3.yAxis * -40, params)
		if not hit or hit.Material ~= Enum.Material.Grass then
			return
		end
		local p = hit.Position
		local min = Vector3.new(math.floor(p.X / 4) * 4, math.floor(p.Y / 4) * 4 - 4, math.floor(p.Z / 4) * 4)
		local region = Region3.new(min, min + Vector3.new(4, 8, 4))
		terrain:ReplaceMaterial(region, 4, Enum.Material.Grass, Enum.Material.Snow)
		task.delay(Fade, function()
			terrain:ReplaceMaterial(region, 4, Enum.Material.Snow, Enum.Material.Grass)
		end)
	end

	RunService.Heartbeat:Connect(function()
		local cf = monster:GetPivot()
		local moved = Vector3.new(cf.X - last.X, 0, cf.Z - last.Z).Magnitude
		if moved > 30 then
			last = cf.Position -- teleported
		elseif moved >= Step then
			last = cf.Position
			left = not left
			Print(cf.Position + cf.RightVector * (if left then -Side else Side))
		end
	end)
end

return Footprints
