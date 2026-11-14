--!strict
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local FurPhysics = {}

local TAG = "Monster"
local STIFF = 25 -- idk, low = floaty
local DAMP = 3
local CARRY = 0.55 -- how much of the body move the fur just follows
local WIND = 0.25
local FAR = 150
local MID = 70

type Chain = {
	Parent: Bone,
	Bone: Bone,
	N: Vector3,
	T: Vector3,
	Tan: number,
	R: number,
	Q: Vector3,
	V: Vector3,
	Last: Vector3,
	Phase: number,
	Ready: boolean,
}

type Fur = {
	Chains: { Chain },
	Frame: number,
	On: boolean,
	Conn: RBXScriptConnection,
}

local Active: { [Model]: Fur } = {}

local function Reset(fur: Fur)
	for _, c in fur.Chains do
		c.Bone.Transform = CFrame.identity
		c.Ready = false
	end
end

local function Step(c: Chain, dt: number, t: number)
	local rest = c.Parent.TransformedWorldCFrame * c.Bone.CFrame
	local m0 = rest.Position

	if not c.Ready or (c.Q - m0).Magnitude > 4 then
		c.Q = m0
		c.V = Vector3.zero
		c.Last = m0
		c.Ready = true
	end

	-- ride along
	c.Q += (m0 - c.Last) * CARRY
	c.Last = m0

	local n = rest:VectorToWorldSpace(c.N)
	local a = rest:VectorToWorldSpace(c.T)
	local b = n:Cross(a)

	local p = c.Phase
	local wind = (a * math.noise(t * 0.5, p, 0) + b * math.noise(t * 0.5, p, 9) + n * 0.3) * c.R * WIND
	c.V += ((m0 + wind - c.Q) * STIFF - c.V * DAMP) * dt
	c.Q += c.V * dt

	-- going sideways lifts it off the body, never into it
	local d = c.Q - m0
	local dn = d:Dot(n)
	local side = d - n * dn
	local need = side.Magnitude / c.Tan
	if dn < need then
		c.Q += n * (need - dn)
		local vn = c.V:Dot(n)
		if vn < 0 then
			c.V -= n * vn
		end
		dn = need
	end

	d = side + n * dn
	local m = d.Magnitude
	if m > 1e-4 then
		d *= math.tanh(m / c.R) * c.R / m -- soft
	end
	c.Bone.Transform = CFrame.new(rest:VectorToObjectSpace(d))
end

local function Update(dt: number)
	local cam = Workspace.CurrentCamera
	if not cam then
		return
	end

	local t = os.clock()
	for model, fur in Active do
		if model:GetAttribute("FurPhysics") == false then
			if fur.On then
				fur.On = false
				Reset(fur)
			end
			continue
		end

		local dist = (cam.CFrame.Position - model:GetPivot().Position).Magnitude
		if dist > FAR then
			if fur.On then
				fur.On = false
				Reset(fur)
			end
			continue
		end
		fur.On = true

		local step = math.min(dt, 1 / 30)
		if dist > MID then
			fur.Frame += 1
			if fur.Frame % 2 == 1 then
				continue
			end
			step = math.min(dt * 2, 1 / 30)
		end

		for _, c in fur.Chains do
			Step(c, step, t)
		end
	end
end

function FurPhysics.Detach(model: Model)
	local fur = Active[model]
	if not fur then
		return
	end

	fur.Conn:Disconnect()
	Reset(fur)
	Active[model] = nil
end

function FurPhysics.Attach(model: Model)
	if Active[model] then
		return
	end

	local chains: { Chain } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Bone") and string.sub(d.Name, 1, 3) == "Fur" then
			local par = d.Parent
			local n = d:GetAttribute("FurN")
			local cone = d:GetAttribute("FurCone")
			local r = d:GetAttribute("FurR")
			if
				par
				and par:IsA("Bone")
				and typeof(n) == "Vector3"
				and typeof(cone) == "number"
				and typeof(r) == "number"
				and r > 0
			then
				local nn = n.Unit
				local up = if math.abs(nn.Y) > 0.9 then Vector3.xAxis else Vector3.yAxis
				table.insert(chains, {
					Parent = par,
					Bone = d,
					N = nn,
					T = nn:Cross(up).Unit,
					Tan = math.tan(math.rad(math.clamp(cone, 5, 80))),
					R = r,
					Q = Vector3.zero,
					V = Vector3.zero,
					Last = Vector3.zero,
					Phase = math.random() * 100,
					Ready = false,
				})
			end
		end
	end

	if #chains == 0 then
		return
	end

	local conn = model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(game) then
			FurPhysics.Detach(model)
		end
	end)
	Active[model] = { Chains = chains, Frame = 0, On = true, Conn = conn }
end

function FurPhysics._Init()
	for _, m in CollectionService:GetTagged(TAG) do
		if m:IsA("Model") then
			FurPhysics.Attach(m)
		end
	end

	CollectionService:GetInstanceAddedSignal(TAG):Connect(function(m)
		if m:IsA("Model") then
			FurPhysics.Attach(m)
		end
	end)

	RunService.PreSimulation:Connect(Update)
end

return FurPhysics
