-- Meteorfall, bootstrap (server). Wires the modules together: builds the
-- arena, makes the two remotes the client talks on, runs the round state
-- machine (lobby -> playing -> game over -> lobby) and keeps every player's
-- HUD in step with State.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local State = require(script.State)
local Arena = require(script.Arena)
local Hazards = require(script.Hazards)
local Orbs = require(script.Orbs)
local Waves = require(script.Waves)

-- The wire: one event each way, tagged messages.
local remotes = Instance.new("Folder")
remotes.Name = "MeteorfallRemotes"
remotes.Parent = ReplicatedStorage

local toClient = Instance.new("RemoteEvent")
toClient.Name = "ToClient"
toClient.Parent = remotes

local toServer = Instance.new("RemoteEvent")
toServer.Name = "ToServer"
toServer.Parent = remotes

Arena.build()
Arena.startAmbient()

local function pushState(player)
	if player and player.Parent then
		toClient:FireClient(player, "State", State.snapshot(player))
	end
end

local function pushAll()
	for _, player in Players:GetPlayers() do
		pushState(player)
	end
end

local function finishRound()
	if State.phase ~= "Playing" then
		return
	end
	State.endRound()
	Waves.stop()
	Orbs.stop()
	toClient:FireAllClients("GameOver", State.standings())
	pushAll()
end

Hazards.onHit = function(player, died)
	toClient:FireClient(player, "Hit", died)
	pushState(player)
	if died and #State.alivePlayers() == 0 then
		task.delay(1.2, finishRound)
	end
end

Orbs.onCollect = function(player)
	toClient:FireClient(player, "Orb")
	pushState(player)
end

Waves.onBanner = function(headline, subline)
	toClient:FireAllClients("Banner", headline, subline)
end

Waves.onSync = pushAll

local function placeAtPad(player, slot)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local angle = (slot % 8) / 8 * math.pi * 2
		hrp.CFrame = CFrame.new(math.cos(angle) * 4, 2.5, math.sin(angle) * 4)
		hrp.AssemblyLinearVelocity = Vector3.zero
	end
end

local function startRound()
	if State.phase == "Playing" then
		return
	end
	local roster = Players:GetPlayers()
	if #roster == 0 then
		return
	end
	State.beginRound(roster)
	for i, player in roster do
		placeAtPad(player, i)
	end
	toClient:FireAllClients("RoundStart")
	pushAll()
	Orbs.start()
	Waves.start()
end

toServer.OnServerEvent:Connect(function(player, action)
	if action == "Start" then
		startRound()
	end
end)

Players.PlayerAdded:Connect(function(player)
	State.record(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.WalkSpeed = 20
		local rec = State.record(player)
		if rec.inRound and rec.alive then
			task.wait(0.2)
			placeAtPad(player, player.UserId)
		end
		pushState(player)
	end)
	pushState(player)
end)

Players.PlayerRemoving:Connect(function(player)
	State.forget(player)
	if State.phase == "Playing" and #State.alivePlayers() == 0 then
		task.delay(0.5, finishRound)
	end
end)

-- Nobody leaves the island: a character that somehow slips past the rim is
-- set back on the pad instead of falling forever.
task.spawn(function()
	while true do
		task.wait(0.25)
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if hrp and hrp.Position.Y < -25 then
				placeAtPad(player, player.UserId)
			end
		end
	end
end)
