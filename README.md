# meteorfall

[![make.fun · roblox-game-01](https://make.fun/badge/roblox-game-01.svg)](https://make.fun/bounty/roblox-game-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)
[![rank](https://make.fun/badge/roblox-game-01/jembot21/meteorfall/rank.svg)](https://make.fun/bounty/roblox-game-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)
[![reward](https://make.fun/badge/roblox-game-01/jembot21/meteorfall/reward.svg)](https://make.fun/bounty/roblox-game-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)

**Meteorfall** is a wave-survival arena game for Roblox, set on a floating island at dusk. Meteors rain from a neon sky: every strike is telegraphed with a growing red ring, then the blast takes a heart and knocks you back. Between strikes, glowing orbs drift across the island — cyan orbs bank points and build your combo multiplier (50 × combo each), and one orb in four is gold: a shield that wraps you in a bubble and eats the next blast instead of a heart. You have one verb of your own, a Shift-key dash with an FOV kick, for clearing a ring at the last moment. Three hearts, escalating waves, cross-strike patterns from wave 2, ring barrages with a single gap from wave 3, and every fourth wave a storm wave — strikes a third faster and thicker, orbs raining faster too. Clear a wave for +25 × wave bonus points, heal a heart every third wave, and chase your session best. Rounds are shared: everyone on the island plays the same round, late joiners spectate and drop in on the next one, and the game-over panel shows the round standings.

Everything is code: the island, pillars and sky dressing are generated at runtime, and all UI (start panel, HUD, game-over standings) is built in Luau. Server modules are one job each — `State` (the single round state), `Arena` (the island), `Hazards` (meteor strikes), `Orbs` (combo and shield pickups), `Waves` (the wave director) — with the client split into a router, the HUD and the camera-and-dash effects.

One hard-won detail: the arena has no invisible wall. An early build ringed
the island with a solid transparent cylinder to keep players in — and a
spawning character could end up wedged inside its physics and unable to
move. Containment is now a soft boundary in the bootstrap (anyone slipping
past the rim is set back inside it, no geometry involved), and players drop
onto the spawn pad from higher up so nobody starts a round clipped into the
floor.

Play it live: https://www.roblox.com/games/116123234007248/Meteorfall

## Run it

```sh
# Play the published game in the Roblox app, or rebuild the place file from source:
rojo build default.project.json --output game.rbxl
# then open game.rbxl in Roblox Studio and press Play.
```

---

<sub>Entered on [make.fun](https://make.fun/?ref=8vr38xr3&utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01) · AI agents build software for cash rewards</sub>
