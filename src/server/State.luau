-- State: the one place that holds the round. Every other server module reads
-- or changes the game through here, so phase, wave, score and hearts can never
-- disagree with each other.

local State = {}

State.phase = "Lobby" -- "Lobby" | "Playing" | "Over"
State.wave = 0
State.players = {} -- [Player] = { hearts, score, combo, best, alive, inRound }

local MAX_HEARTS = 3
local ORB_BASE = 50
local COMBO_CAP = 8

function State.maxHearts()
	return MAX_HEARTS
end

function State.record(player)
	local rec = State.players[player]
	if not rec then
		rec = { hearts = MAX_HEARTS, score = 0, combo = 0, best = 0, alive = false, inRound = false, shield = false }
		State.players[player] = rec
	end
	return rec
end

function State.forget(player)
	State.players[player] = nil
end

-- Starts a round for everyone in the roster: fresh hearts, score and combo.
function State.beginRound(roster)
	State.phase = "Playing"
	State.wave = 0
	for _, player in roster do
		local rec = State.record(player)
		rec.hearts = MAX_HEARTS
		rec.score = 0
		rec.combo = 0
		rec.shield = false
		rec.alive = true
		rec.inRound = true
	end
end

-- Closes the round and banks each player's best score.
function State.endRound()
	State.phase = "Over"
	for _, rec in State.players do
		if rec.score > rec.best then
			rec.best = rec.score
		end
		rec.inRound = false
		rec.alive = false
	end
end

function State.alivePlayers()
	local out = {}
	for player, rec in State.players do
		if rec.inRound and rec.alive and player.Parent ~= nil then
			out[#out + 1] = player
		end
	end
	return out
end

function State.addScore(player, points)
	local rec = State.record(player)
	rec.score += points
	return rec.score
end

-- An orb pays ORB_BASE times the running combo; the combo grows per orb.
function State.collectOrb(player)
	local rec = State.record(player)
	rec.combo = math.min(rec.combo + 1, COMBO_CAP)
	return State.addScore(player, ORB_BASE * rec.combo)
end

-- A shield orb's gift: the next blast breaks the shield instead of a heart.
function State.giveShield(player)
	local rec = State.record(player)
	rec.shield = true
end

-- A hit costs a heart and the combo — unless a shield eats it, which costs
-- only the shield and half the combo. Returns (blocked, died).
function State.hurt(player)
	local rec = State.record(player)
	if rec.shield then
		rec.shield = false
		rec.combo = math.floor(rec.combo / 2)
		return true, false
	end
	rec.hearts -= 1
	rec.combo = 0
	if rec.hearts <= 0 then
		rec.alive = false
		if rec.score > rec.best then
			rec.best = rec.score
		end
		return false, true
	end
	return false, false
end

function State.heal(player)
	local rec = State.record(player)
	rec.hearts = math.min(rec.hearts + 1, MAX_HEARTS)
end

-- The per-player view the client HUD renders from.
function State.snapshot(player)
	local rec = State.record(player)
	return {
		phase = State.phase,
		wave = State.wave,
		hearts = rec.hearts,
		maxHearts = MAX_HEARTS,
		score = rec.score,
		combo = rec.combo,
		best = rec.best,
		alive = rec.alive,
		inRound = rec.inRound,
		shield = rec.shield,
	}
end

-- Score rows for the game-over screen, best first.
function State.standings()
	local rows = {}
	for player, rec in State.players do
		if rec.score > 0 or rec.inRound then
			rows[#rows + 1] = { name = player.DisplayName, score = rec.score, best = rec.best }
		end
	end
	table.sort(rows, function(a, b)
		return a.score > b.score
	end)
	return rows
end

return State
