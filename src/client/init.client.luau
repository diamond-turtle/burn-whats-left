local ComponentsFolder = script:WaitForChild("Components"):GetChildren()

type Component = { _Init: (() -> ())? }

for _, component in ComponentsFolder do
	if component:IsA("ModuleScript") then
		local module = require(component) :: Component
		if module._Init then
			module._Init()
		end
	end
end
