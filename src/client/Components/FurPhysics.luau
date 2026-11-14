--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Math = require(ReplicatedStorage.Shared.Math)

local FurPhysics = {}

local TAG = "Monster"
local STIFF = 18 -- idk, low = floaty
local DAMP = 2.6
local WIND = 7
local MAX_ANGLE = math.rad(38)
local FAR = 150
local MID = 70

type Chain = {
	Parent: Bone,
	A: Bone,
	B: Bone,
	Q1: Vector3,
	V1: Vector3,
	Q2: Vector3,
	V2: Vector3,
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

local function FromTo(u: Vector3, v: Vector3): CFrame
	local ud = u.Unit
	local vd = v.Unit
	local axis = ud:Cross(vd)
	if axis.Magnitude < 1e-4 then
		return CFrame.identity
	end

	local raw = math.acos(Math.clamp(ud:Dot(vd), -1, 1))
	local ang = MAX_ANGLE * math.tanh(raw / MAX_ANGLE) -- soft
	return CFrame.fromAxisAngle(axis.Unit, ang)
end

local function Reset(fur: Fur)
	for _, c in fur.Chains do
		c.A.Transform = CFrame.identity
		c.B.Transform = CFrame.identity
		c.Ready = false
	end
end

local function Step(c: Chain, dt: number, t: number)
	local restA = c.Parent.TransformedWorldCFrame * c.A.CFrame
	local restB = restA * c.B.CFrame
	local a0 = restA.Position
	local m0 = restB.Position
	local t0 = m0 + (m0 - a0) * 0.9

	if not c.Ready or (c.Q1 - m0).Magnitude > 4 then
		c.Q1 = m0
		c.Q2 = t0
		c.V1 = Vector3.zero
		c.V2 = Vector3.zero
		c.Ready = true
	end

	local p = c.Phase
	local wind = Vector3.new(math.noise(t * 0.45, p, 0), math.noise(t * 0.45, p, 7) * 0.4, math.noise(t * 0.45, p, 14)) * WIND

	c.V1 += ((m0 - c.Q1) * STIFF - c.V1 * DAMP + wind) * dt
	c.Q1 += c.V1 * dt
	c.V2 += ((t0 - c.Q2) * STIFF * 0.7 - c.V2 * DAMP * 0.8 + wind * 1.4) * dt
	c.Q2 += c.V2 * dt

	-- lengths
	local d1 = c.Q1 - a0
	if d1.Magnitude < 1e-3 then
		d1 = m0 - a0
	end
	c.Q1 = a0 + d1.Unit * (m0 - a0).Magnitude
	local d2 = c.Q2 - c.Q1
	if d2.Magnitude < 1e-3 then
		d2 = t0 - m0
	end
	c.Q2 = c.Q1 + d2.Unit * (t0 - m0).Magnitude

	-- not +=
	local rw1 = FromTo(m0 - a0, c.Q1 - a0)
	local rA = restA.Rotation
	c.A.Transform = rA:Inverse() * rw1 * rA

	local m1 = a0 + rw1:VectorToWorldSpace(m0 - a0)
	local rw2 = FromTo(rw1:VectorToWorldSpace(t0 - m0), c.Q2 - m1)
	local rB = rw1 * restB.Rotation
	c.B.Transform = rB:Inverse() * rw2 * rB
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
		if d:IsA("Bone") and string.match(d.Name, "^Fur.+_1$") then
			local nm = string.gsub(d.Name, "_1$", "_2")
			local b = d:FindFirstChild(nm)
			local par = d.Parent
			if b and b:IsA("Bone") and par and par:IsA("Bone") then
				table.insert(chains, {
					Parent = par,
					A = d,
					B = b,
					Q1 = Vector3.zero,
					V1 = Vector3.zero,
					Q2 = Vector3.zero,
					V2 = Vector3.zero,
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
