-- Orbs: the light worth running for. Glowing orbs drift over the arena while
-- a round runs; touching one banks points, and each one in a row raises the
-- combo it pays at — until a meteor resets it.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local State = require(script.Parent.State)
local Arena = require(script.Parent.Arena)

local Orbs = {}

-- Set by the bootstrap: function(player) — refresh that player's HUD.
Orbs.onCollect = nil

local CYAN = Color3.fromRGB(64, 224, 255)
local MAX_ALIVE = 3
local SPAWN_EVERY = 2.2

local running = false
local alive = 0

local function spawnOrb()
	local orb = Instance.new("Part")
	orb.Name = "Orb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(2.2, 2.2, 2.2)
	orb.Color = CYAN
	orb.Material = Enum.Material.Neon
	orb.Anchored = true
	orb.CanCollide = false
	orb.CanQuery = false
	local pos = Arena.randomFloorPoint(10)
	orb.CFrame = CFrame.new(pos + Vector3.new(0, 2.4, 0))
	orb.Parent = Arena.fx

	local light = Instance.new("PointLight")
	light.Color = CYAN
	light.Range = 13
	light.Brightness = 1.6
	light.Parent = orb

	local bob = TweenService:Create(orb, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		CFrame = CFrame.new(pos + Vector3.new(0, 3.3, 0)),
	})
	bob:Play()

	alive += 1
	orb.Touched:Connect(function(hit)
		if orb:GetAttribute("Taken") then
			return
		end
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		local rec = State.record(player)
		if not (rec.inRound and rec.alive) then
			return
		end
		orb:SetAttribute("Taken", true)
		State.collectOrb(player)
		alive -= 1
		bob:Cancel()
		orb:Destroy()
		if Orbs.onCollect then
			Orbs.onCollect(player)
		end
	end)
	orb.Destroying:Connect(function()
		bob:Cancel()
	end)
end

function Orbs.start()
	if running then
		return
	end
	running = true
	task.spawn(function()
		while running and State.phase == "Playing" do
			if alive < MAX_ALIVE then
				spawnOrb()
			end
			task.wait(SPAWN_EVERY)
		end
		running = false
	end)
end

function Orbs.stop()
	running = false
	for _, child in Arena.fx:GetChildren() do
		if child.Name == "Orb" then
			child:Destroy()
		end
	end
	alive = 0
end

return Orbs
