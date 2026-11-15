-- Waves: the round's director. Each wave aims a budget of meteors at the
-- players still standing, faster and meaner than the last; between waves it
-- pays a clear bonus, and every third wave hands a heart back. Survival also
-- pays a slow tick, so even a cautious run climbs the board.

local State = require(script.Parent.State)
local Hazards = require(script.Parent.Hazards)

local Waves = {}

-- Set by the bootstrap: function(headline, subline) shown to every player,
-- and function() to push fresh state to every HUD.
Waves.onBanner = nil
Waves.onSync = nil

local running = false

local WAVE_SUBLINES = {
	[1] = "Dodge the falling sky",
	[2] = "Crosses join the rain",
	[3] = "Barrages incoming",
	[4] = "The sky is angry now",
	[5] = "Hold the island",
}

local function banner(headline, subline)
	if Waves.onBanner then
		Waves.onBanner(headline, subline)
	end
	if Waves.onSync then
		Waves.onSync()
	end
end

local function survivalTick()
	task.spawn(function()
		while running and State.phase == "Playing" do
			task.wait(1)
			if State.phase ~= "Playing" then
				break
			end
			for _, player in State.alivePlayers() do
				State.addScore(player, 5)
			end
			if Waves.onSync then
				Waves.onSync()
			end
		end
	end)
end

local function directWave(wave)
	local budget = 5 + wave * 3
	local interval = math.max(0.55, 1.45 - wave * 0.08)
	local radius = (wave >= 5) and 7.6 or 7
	local telegraph = math.max(0.85, 1.12 - wave * 0.015)

	for _ = 1, budget do
		if State.phase ~= "Playing" then
			return
		end
		local alive = State.alivePlayers()
		if #alive == 0 then
			return
		end
		local target = alive[math.random(1, #alive)]
		local roll = math.random()
		if wave >= 3 and roll < 0.16 then
			Hazards.ringBarrage(target, radius, telegraph)
		elseif wave >= 2 and roll < 0.38 then
			Hazards.crossStrike(target, radius, telegraph)
		else
			Hazards.strikePlayer(target, radius, telegraph)
		end
		task.wait(interval * (0.7 + math.random() * 0.6))
	end
end

function Waves.start()
	if running then
		return
	end
	running = true
	survivalTick()
	task.spawn(function()
		while running and State.phase == "Playing" do
			State.wave += 1
			local wave = State.wave
			banner("WAVE " .. wave, WAVE_SUBLINES[wave] or "Faster. Meaner.")
			task.wait(1.6)
			directWave(wave)

			if State.phase ~= "Playing" or #State.alivePlayers() == 0 then
				break
			end

			-- Wave clear: a bonus for everyone still standing, a heart every
			-- third wave, and a breath before the next one.
			local bonus = 25 * wave
			for _, player in State.alivePlayers() do
				State.addScore(player, bonus)
				if wave % 3 == 0 then
					State.heal(player)
				end
			end
			banner("WAVE " .. wave .. " CLEAR", "+" .. bonus .. " for everyone standing")
			task.wait(3.5)
		end
		running = false
	end)
end

function Waves.stop()
	running = false
end

return Waves
