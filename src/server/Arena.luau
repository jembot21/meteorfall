-- Arena: builds the floating island the round is played on — the floor, the
-- neon rim that keeps players in, six lit pillars, the spawn pad and a ring of
-- drifting shards — and dresses the sky: dusk light, atmosphere and bloom so
-- the neon reads as neon.

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Arena = {}

Arena.RADIUS = 46
Arena.root = nil -- Folder "Meteorfall" in Workspace
Arena.fx = nil -- Folder for short-lived effect parts (strikes, blasts, orbs)

local INK = Color3.fromRGB(22, 19, 52)
local SLATE = Color3.fromRGB(43, 38, 84)
local CYAN = Color3.fromRGB(64, 224, 255)
local MAGENTA = Color3.fromRGB(255, 84, 168)
local VIOLET = Color3.fromRGB(130, 90, 255)

local shards = {} -- { part, baseY, phase, spin }

local function makePart(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function dressSky()
	Lighting.ClockTime = 18.6
	Lighting.Ambient = Color3.fromRGB(38, 33, 79)
	Lighting.OutdoorAmbient = Color3.fromRGB(72, 60, 120)
	Lighting.Brightness = 2
	Lighting.GlobalShadows = true

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "DuskAir"
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(168, 156, 255)
	atmosphere.Decay = Color3.fromRGB(52, 38, 106)
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "NeonBloom"
	bloom.Intensity = 0.55
	bloom.Size = 28
	bloom.Threshold = 0.85
	bloom.Parent = Lighting

	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "DuskGrade"
	grade.Saturation = 0.12
	grade.Contrast = 0.06
	grade.Parent = Lighting
end

local function buildIsland(root)
	-- The island: a squat cylinder whose top face is the floor at y = 0.
	local island = makePart(root, "Island", Vector3.new(6, Arena.RADIUS * 2, Arena.RADIUS * 2), CFrame.new(0, -3.2, 0) * CFrame.Angles(0, 0, math.rad(90)), SLATE)
	island.Shape = Enum.PartType.Cylinder

	local plate = makePart(root, "FloorPlate", Vector3.new(0.5, (Arena.RADIUS - 1.5) * 2, (Arena.RADIUS - 1.5) * 2), CFrame.new(0, -0.05, 0) * CFrame.Angles(0, 0, math.rad(90)), INK)
	plate.Shape = Enum.PartType.Cylinder
	plate.CanCollide = true

	-- Glowing rings inlaid in the floor mark the play circle and give the
	-- dark stone some geometry to catch the light.
	local inlay = makePart(root, "PlayRing", Vector3.new(0.18, 64, 64), CFrame.new(0, 0.24, 0) * CFrame.Angles(0, 0, math.rad(90)), VIOLET, Enum.Material.Neon)
	inlay.Shape = Enum.PartType.Cylinder
	inlay.CanCollide = false
	for _, ring in { { 34, CYAN }, { 86, MAGENTA } } do
		local r = makePart(root, "FloorRing", Vector3.new(0.14, ring[1], ring[1]), CFrame.new(0, 0.22, 0) * CFrame.Angles(0, 0, math.rad(90)), ring[2], Enum.Material.Neon)
		r.Shape = Enum.PartType.Cylinder
		r.CanCollide = false
	end

	-- Rim: alternating neon segments, high enough to read as a wall of light.
	local segments = 28
	for i = 1, segments do
		local angle = (i / segments) * math.pi * 2
		local pos = Vector3.new(math.cos(angle) * (Arena.RADIUS - 0.6), 1.5, math.sin(angle) * (Arena.RADIUS - 0.6))
		local color = (i % 2 == 0) and CYAN or MAGENTA
		local seg = makePart(root, "Rim", Vector3.new(10.6, 3, 1.1), CFrame.new(pos) * CFrame.Angles(0, -angle + math.pi / 2, 0), color, Enum.Material.Neon)
		seg.CanCollide = true
	end

	-- Nobody leaves the island: there is deliberately no solid wall part
	-- around the arena — the bootstrap runs a soft boundary that sets back
	-- anyone who slips past the rim, so no invisible geometry can ever
	-- interfere with a character standing inside the arena.

	-- Spawn pad at the centre.
	local pad = makePart(root, "SpawnPad", Vector3.new(0.4, 13, 13), CFrame.new(0, 0.35, 0) * CFrame.Angles(0, 0, math.rad(90)), CYAN, Enum.Material.Neon)
	pad.Shape = Enum.PartType.Cylinder
	pad.CanCollide = false
end

local function buildPillars(root)
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2 + math.pi / 6
		local pos = Vector3.new(math.cos(angle) * 37, 0, math.sin(angle) * 37)
		local color = (i % 2 == 0) and CYAN or MAGENTA
		makePart(root, "Pillar", Vector3.new(3, 13, 3), CFrame.new(pos + Vector3.new(0, 6.5, 0)), SLATE)
		local cap = makePart(root, "PillarCap", Vector3.new(3.8, 1.1, 3.8), CFrame.new(pos + Vector3.new(0, 13.4, 0)), color, Enum.Material.Neon)
		cap.CanCollide = false
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 30
		light.Brightness = 1.4
		light.Parent = cap
	end
end

local function buildShards(root)
	local folder = Instance.new("Folder")
	folder.Name = "Shards"
	folder.Parent = root
	for i = 1, 14 do
		local angle = (i / 14) * math.pi * 2 + i * 0.7
		local dist = 58 + (i % 4) * 9
		local y = 7 + (i % 5) * 4.5
		local size = 2 + (i % 3)
		local color = (i % 3 == 0) and MAGENTA or ((i % 3 == 1) and CYAN or VIOLET)
		local shard = makePart(folder, "Shard", Vector3.new(size, size * 1.7, size), CFrame.new(math.cos(angle) * dist, y, math.sin(angle) * dist) * CFrame.Angles(i, i * 2.1, 0), color, Enum.Material.Neon)
		shard.CanCollide = false
		shards[#shards + 1] = { part = shard, baseY = y, phase = i * 1.37, spin = 0.15 + (i % 4) * 0.06 }
	end
end

-- The night above the island: a dome of small neon stars and one low,
-- pale moon, so the sky the meteors fall from is worth looking at.
local function buildSkyDressing(root)
	local folder = Instance.new("Folder")
	folder.Name = "Sky"
	folder.Parent = root
	for i = 1, 44 do
		local a = (i / 44) * math.pi * 2 + i * 1.7
		local dist = 95 + (i % 5) * 16
		local y = 34 + (i % 7) * 11
		local size = 0.7 + (i % 3) * 0.5
		local color = (i % 4 == 0) and MAGENTA or ((i % 4 == 1) and CYAN or Color3.fromRGB(226, 228, 255))
		local star = makePart(folder, "Star", Vector3.new(size, size, size), CFrame.new(math.cos(a) * dist, y, math.sin(a) * dist), color, Enum.Material.Neon)
		star.Shape = Enum.PartType.Ball
		star.CanCollide = false
	end
	local moon = makePart(folder, "Moon", Vector3.new(16, 16, 1), CFrame.new(-70, 52, -95) * CFrame.Angles(0, math.rad(36), 0), Color3.fromRGB(238, 240, 255), Enum.Material.Neon)
	moon.Shape = Enum.PartType.Cylinder
	moon.CanCollide = false
end

function Arena.build()
	dressSky()

	local root = Instance.new("Folder")
	root.Name = "Meteorfall"
	root.Parent = Workspace

	local fx = Instance.new("Folder")
	fx.Name = "Fx"
	fx.Parent = root

	Arena.root = root
	Arena.fx = fx

	buildIsland(root)
	buildPillars(root)
	buildShards(root)
	buildSkyDressing(root)

	local glow = Instance.new("PointLight")
	glow.Name = "IslandGlow"
	glow.Color = VIOLET
	glow.Range = 70
	glow.Brightness = 1.6
	local glowPart = makePart(root, "GlowAnchor", Vector3.new(1, 1, 1), CFrame.new(0, -9, 0), INK)
	glowPart.Transparency = 1
	glowPart.CanCollide = false
	glow.Parent = glowPart

	return root
end

-- A point on the floor inside the play circle, kept off the very rim.
function Arena.randomFloorPoint(margin)
	local r = math.sqrt(math.random()) * (Arena.RADIUS - (margin or 8))
	local a = math.random() * math.pi * 2
	return Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
end

-- Slow life for the set dressing: the shards turn and breathe while you play.
function Arena.startAmbient()
	task.spawn(function()
		while Arena.root and Arena.root.Parent do
			local t = os.clock()
			for _, s in shards do
				if s.part.Parent then
					local pos = s.part.Position
					s.part.CFrame = CFrame.new(pos.X, s.baseY + math.sin(t * 0.6 + s.phase) * 1.2, pos.Z)
						* CFrame.Angles(t * s.spin + s.phase, s.phase, 0)
				end
			end
			RunService.Heartbeat:Wait()
		end
	end)
end

return Arena
