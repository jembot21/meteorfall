-- Hazards: the meteors. A strike is telegraphed by a red ring that grows to
-- the blast size, then a meteor falls on it and bursts — anyone caught inside
-- loses a heart and is thrown clear. Two patterns join in later waves: a
-- cross of strikes around a player, and a ring barrage with one gap.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local State = require(script.Parent.State)
local Arena = require(script.Parent.Arena)

local Hazards = {}

-- Set by the bootstrap: function(player, died) — the client feedback for a hit.
Hazards.onHit = nil

local DANGER = Color3.fromRGB(255, 70, 60)
local EMBER = Color3.fromRGB(255, 122, 40)
local SCORCH = Color3.fromRGB(12, 10, 22)

local function rootPart(player)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	return hrp
end

local function flatCylinder(name, radius, height, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(height, radius * 2, radius * 2)
	p.Color = color
	p.Material = material or Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Parent = Arena.fx
	return p
end

local function telegraph(pos, radius, seconds)
	local ring = flatCylinder("Telegraph", 1.2, 0.22, DANGER)
	ring.CFrame = CFrame.new(pos + Vector3.new(0, 0.32, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0.35
	local started = os.clock()
	while os.clock() - started < seconds do
		if State.phase ~= "Playing" then
			ring:Destroy()
			return false
		end
		local k = (os.clock() - started) / seconds
		local r = 1.2 + (radius - 1.2) * k
		ring.Size = Vector3.new(0.22, r * 2, r * 2)
		ring.Transparency = 0.35 - 0.25 * math.abs(math.sin(os.clock() * 10))
		RunService.Heartbeat:Wait()
	end
	ring.Size = Vector3.new(0.22, radius * 2, radius * 2)
	ring.Transparency = 0.1
	task.delay(0.12, function()
		if ring.Parent then
			ring:Destroy()
		end
	end)
	return true
end

local function blast(pos, radius)
	-- The flash: a sphere that swells and thins out.
	local shell = Instance.new("Part")
	shell.Name = "Blast"
	shell.Shape = Enum.PartType.Ball
	shell.Size = Vector3.new(1, 1, 1)
	shell.CFrame = CFrame.new(pos + Vector3.new(0, 1, 0))
	shell.Color = EMBER
	shell.Material = Enum.Material.Neon
	shell.Transparency = 0.25
	shell.Anchored = true
	shell.CanCollide = false
	shell.CanQuery = false
	shell.CanTouch = false
	shell.Parent = Arena.fx
	local light = Instance.new("PointLight")
	light.Color = EMBER
	light.Range = 26
	light.Brightness = 3
	light.Parent = shell
	local grow = TweenService:Create(shell, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(radius * 2.1, radius * 2.1, radius * 2.1),
		Transparency = 1,
	})
	grow:Play()
	grow.Completed:Connect(function()
		shell:Destroy()
	end)

	-- The scorch mark it leaves behind.
	local mark = flatCylinder("Scorch", radius * 0.8, 0.14, SCORCH, Enum.Material.SmoothPlastic)
	mark.CFrame = CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	mark.Transparency = 0.3
	local fade = TweenService:Create(mark, TweenInfo.new(6, Enum.EasingStyle.Linear), { Transparency = 1 })
	fade:Play()
	fade.Completed:Connect(function()
		mark:Destroy()
	end)

	-- Whoever is standing in it pays a heart and gets thrown out of it.
	for _, player in State.alivePlayers() do
		local hrp = rootPart(player)
		if hrp then
			local away = hrp.Position - (pos + Vector3.new(0, 1, 0))
			if away.Magnitude <= radius + 1.5 then
				local died = State.hurt(player)
				local flat = Vector3.new(away.X, 0, away.Z)
				if flat.Magnitude < 0.5 then
					flat = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
				end
				hrp.AssemblyLinearVelocity = flat.Unit * 50 + Vector3.new(0, 36, 0)
				if Hazards.onHit then
					Hazards.onHit(player, died)
				end
			end
		end
	end
end

local function meteorFall(pos, radius)
	local meteor = Instance.new("Part")
	meteor.Name = "Meteor"
	meteor.Shape = Enum.PartType.Ball
	meteor.Size = Vector3.new(3.1, 3.1, 3.1)
	meteor.Color = EMBER
	meteor.Material = Enum.Material.Neon
	meteor.Anchored = true
	meteor.CanCollide = false
	meteor.CanQuery = false
	meteor.CanTouch = false
	meteor.CFrame = CFrame.new(pos + Vector3.new(0, 88, 0))
	meteor.Parent = Arena.fx
	local fire = Instance.new("Fire")
	fire.Size = 7
	fire.Heat = 12
	fire.Color = EMBER
	fire.SecondaryColor = Color3.fromRGB(255, 200, 90)
	fire.Parent = meteor
	local fall = TweenService:Create(meteor, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		CFrame = CFrame.new(pos + Vector3.new(0, 1.2, 0)),
	})
	fall:Play()
	fall.Completed:Wait()
	meteor:Destroy()
	blast(pos, radius)
end

-- One strike on a point of the floor: ring first, then the rock.
function Hazards.strikeAt(pos, radius, telegraphSeconds, delay)
	task.spawn(function()
		if delay and delay > 0 then
			task.wait(delay)
		end
		if State.phase ~= "Playing" then
			return
		end
		if telegraph(pos, radius, telegraphSeconds) then
			meteorFall(pos, radius)
		end
	end)
end

-- A strike aimed at a player, jittered so a moving player can escape it.
function Hazards.strikePlayer(player, radius, telegraphSeconds)
	local hrp = rootPart(player)
	if not hrp then
		return
	end
	local jitter = Vector3.new((math.random() - 0.5) * 11, 0, (math.random() - 0.5) * 11)
	local pos = hrp.Position + jitter
	local dist = Vector3.new(pos.X, 0, pos.Z).Magnitude
	if dist > Arena.RADIUS - 5 then
		pos = Vector3.new(pos.X, 0, pos.Z).Unit * (Arena.RADIUS - 5)
	end
	Hazards.strikeAt(Vector3.new(pos.X, 0, pos.Z), radius, telegraphSeconds, 0)
end

-- Five strikes in a cross around the player; the centre one lands last.
function Hazards.crossStrike(player, radius, telegraphSeconds)
	local hrp = rootPart(player)
	if not hrp then
		return
	end
	local c = hrp.Position
	for _, off in { Vector3.new(10, 0, 0), Vector3.new(-10, 0, 0), Vector3.new(0, 0, 10), Vector3.new(0, 0, -10) } do
		Hazards.strikeAt(Vector3.new(c.X + off.X, 0, c.Z + off.Z), radius, telegraphSeconds, 0)
	end
	Hazards.strikeAt(Vector3.new(c.X, 0, c.Z), radius, telegraphSeconds, 0.3)
end

-- Eight strikes in a ring around the player, with one gap to run for.
function Hazards.ringBarrage(player, radius, telegraphSeconds)
	local hrp = rootPart(player)
	if not hrp then
		return
	end
	local c = hrp.Position
	local gap = math.random(1, 8)
	for i = 1, 8 do
		if i ~= gap then
			local a = (i / 8) * math.pi * 2
			Hazards.strikeAt(Vector3.new(c.X + math.cos(a) * 11, 0, c.Z + math.sin(a) * 11), radius, telegraphSeconds, 0)
		end
	end
end

return Hazards
