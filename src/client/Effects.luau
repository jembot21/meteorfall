-- Effects: the client's feel — the camera and the dash. A hit lands as a
-- shake whose size and length scale with how bad it was; it decays on its
-- own. The dash is the player's one verb of their own: a burst of speed on
-- Shift, on a short cooldown, with a kick of field-of-view for the rush.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Effects = {}

local shakeTime = 0
local shakeSpan = 0.4
local shakePower = 0

local DASH_COOLDOWN = 1.6
local dashReadyAt = 0

function Effects.shake(power)
	shakeSpan = 0.4
	shakeTime = shakeSpan
	shakePower = math.max(shakePower, power)
end

-- A burst in the direction the player is already steering (or facing):
-- enough to clear a telegraph ring, not enough to leave the island.
function Effects.dash()
	local now = os.clock()
	if now < dashReadyAt then
		return
	end
	local character = Players.LocalPlayer and Players.LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid or humanoid.Health <= 0 then
		return
	end
	dashReadyAt = now + DASH_COOLDOWN
	local dir = humanoid.MoveDirection
	if dir.Magnitude < 0.1 then
		local look = hrp.CFrame.LookVector
		dir = Vector3.new(look.X, 0, look.Z)
	end
	if dir.Magnitude < 0.1 then
		return
	end
	hrp.AssemblyLinearVelocity = dir.Unit * 66 + Vector3.new(0, 9, 0)
	local camera = Workspace.CurrentCamera
	if camera then
		TweenService:Create(camera, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = 77 }):Play()
		task.delay(0.16, function()
			if Workspace.CurrentCamera then
				TweenService:Create(Workspace.CurrentCamera, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = 70 }):Play()
			end
		end)
	end
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
