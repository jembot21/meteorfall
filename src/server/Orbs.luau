-- Orbs: the light worth running for. Glowing orbs drift over the arena while
-- a round runs; touching one banks points, and each one in a row raises the
-- combo it pays at — until a meteor resets it. One orb in four is gold: a
-- shield orb, and touching it wraps the player in a bubble that eats the
-- next blast instead of a heart.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local State = require(script.Parent.State)
local Arena = require(script.Parent.Arena)

local Orbs = {}

-- Set by the bootstrap: function(player) — refresh that player's HUD.
Orbs.onCollect = nil
Orbs.onShield = nil

local CYAN = Color3.fromRGB(64, 224, 255)
local GOLD = Color3.fromRGB(255, 196, 64)
local SHIELD_CHANCE = 0.25
local MAX_ALIVE = 3
local SPAWN_EVERY = 2.2

local running = false
local alive = 0
local storm = false

-- The visible half of a shield: a glass bubble riding on the character.
-- Called whenever a shield is gained, spent or a round resets.
function Orbs.syncShield(player)
	local character = player.Character
	if not character then
		return
	end
	local bubble = character:FindFirstChild("ShieldBubble")
	local shielded = State.record(player).shield
	if shielded and not bubble then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end
		bubble = Instance.new("Part")
		bubble.Name = "ShieldBubble"
		bubble.Shape = Enum.PartType.Ball
		bubble.Size = Vector3.new(6.4, 6.4, 6.4)
		bubble.Color = GOLD
		bubble.Material = Enum.Material.Neon
		bubble.Transparency = 0.72
		bubble.CanCollide = false
		bubble.CanQuery = false
		bubble.CanTouch = false
		bubble.Massless = true
		bubble.CFrame = hrp.CFrame
		bubble.Parent = character
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hrp
		weld.Part1 = bubble
		weld.Parent = bubble
	elseif bubble and not shielded then
		bubble:Destroy()
	end
end

function Orbs.setStorm(on)
	storm = on
end

local function spawnOrb()
	local shieldOrb = math.random() < SHIELD_CHANCE
	local orb = Instance.new("Part")
	orb.Name = shieldOrb and "ShieldOrb" or "Orb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = shieldOrb and Vector3.new(2.7, 2.7, 2.7) or Vector3.new(2.2, 2.2, 2.2)
	orb.Color = shieldOrb and GOLD or CYAN
	orb.Material = Enum.Material.Neon
	orb.Anchored = true
	orb.CanCollide = false
	orb.CanQuery = false
	orb:SetAttribute("Shield", shieldOrb)
	local pos = Arena.randomFloorPoint(10)
	orb.CFrame = CFrame.new(pos + Vector3.new(0, 2.4, 0))
	orb.Parent = Arena.fx

	local light = Instance.new("PointLight")
	light.Color = shieldOrb and GOLD or CYAN
	light.Range = 13
	light.Brightness = 1.6
	light.Parent = orb

	local sparks = Instance.new("ParticleEmitter")
	sparks.Color = ColorSequence.new(shieldOrb and GOLD or CYAN)
	sparks.Size = NumberSequence.new(0.55)
	sparks.Transparency = NumberSequence.new(0.35)
	sparks.Rate = 9
	sparks.Lifetime = NumberRange.new(0.5, 0.9)
	sparks.Speed = NumberRange.new(1.2, 2.6)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Parent = orb

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
		alive -= 1
		bob:Cancel()
		orb:Destroy()
		if orb:GetAttribute("Shield") then
			State.giveShield(player)
			Orbs.syncShield(player)
			if Orbs.onShield then
				Orbs.onShield(player)
			end
		else
			State.collectOrb(player)
			if Orbs.onCollect then
				Orbs.onCollect(player)
			end
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
			if alive < (storm and MAX_ALIVE + 1 or MAX_ALIVE) then
				spawnOrb()
			end
			task.wait(storm and SPAWN_EVERY * 0.55 or SPAWN_EVERY)
		end
		running = false
	end)
end

function Orbs.stop()
	running = false
	storm = false
	for _, child in Arena.fx:GetChildren() do
		if child.Name == "Orb" or child.Name == "ShieldOrb" then
			child:Destroy()
		end
	end
	alive = 0
end

return Orbs
