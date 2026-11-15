local FireParticles = {}

type ClientController = { FireSignal: any, GetFirePercentage: any }
function FireParticles.Hook(ClientController: ClientController)
	local fireParticle = workspace:WaitForChild("Fireplace"):WaitForChild("Attachment"):WaitForChild("Fire") :: Fire

	local function update(percentage: number)
		fireParticle.Enabled = percentage > 0
		if percentage > 0 then
			fireParticle.Size = (percentage / 100) * 5
		end
	end

	update(ClientController.GetFirePercentage())
	ClientController.FireSignal:Connect(update)
end

return FireParticles
