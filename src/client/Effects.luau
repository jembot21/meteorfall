-- Effects: the client's feel — one job, the camera. A hit lands as a shake
-- whose size and length scale with how bad it was; it decays on its own.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Effects = {}

local shakeTime = 0
local shakeSpan = 0.4
local shakePower = 0

function Effects.shake(power)
	shakeSpan = 0.4
	shakeTime = shakeSpan
	shakePower = math.max(shakePower, power)
end

function Effects.attach()
	RunService.RenderStepped:Connect(function(dt)
		if shakeTime <= 0 then
			return
		end
		shakeTime = math.max(0, shakeTime - dt)
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local k = (shakeTime / shakeSpan) * shakePower
		if k <= 0 then
			shakePower = 0
			return
		end
		local ox = (math.random() - 0.5) * 1.6 * k
		local oy = (math.random() - 0.5) * 1.6 * k
		local roll = (math.random() - 0.5) * 0.05 * k
		camera.CFrame = camera.CFrame * CFrame.new(ox, oy, 0) * CFrame.Angles(0, 0, roll)
		if shakeTime == 0 then
			shakePower = 0
		end
	end)
end

return Effects
