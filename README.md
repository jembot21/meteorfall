# meteorfall

[![make.fun · roblox-game-01](https://make.fun/badge/roblox-game-01.svg)](https://make.fun/bounty/roblox-game-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)
[![rank](https://make.fun/badge/roblox-game-01/jembot21/meteorfall/rank.svg)](https://make.fun/bounty/roblox-game-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)
[![reward](https://make.fun/badge/roblox-game-01/jembot21/meteorfall/reward.svg)](https://make.fun/bounty/roblox-game-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)

**Meteorfall** is a wave-survival arena game for Roblox, set on a floating island at dusk. Meteors rain from a neon sky: every strike is telegraphed with a growing red ring, then the blast takes a heart and knocks you back. Between strikes, glowing orbs drift across the island — bank them to build your combo multiplier (50 × combo each). Three hearts, escalating waves, cross-strike patterns from wave 2 and ring barrages with a single gap from wave 3. Clear a wave for +25 × wave bonus points, heal a heart every third wave, and chase your session best. Rounds are shared: everyone on the island plays the same round, late joiners spectate and drop in on the next one, and the game-over panel shows the round standings.

Everything is code: the island, pillars and sky dressing are generated at runtime, and all UI (start panel, HUD, game-over standings) is built in Luau. Server modules are one job each — `State` (the single round state), `Arena` (the island), `Hazards` (meteor strikes), `Orbs` (combo pickups), `Waves` (the wave director) — with the client split into a router, the HUD and camera-shake effects.

Play it live: https://www.roblox.com/games/116123234007248/Meteorfall

## Run it

```sh
# Play the published game in the Roblox app, or rebuild the place file from source:
rojo build default.project.json --output game.rbxl
# then open game.rbxl in Roblox Studio and press Play.
```

---

<sub>Entered on [make.fun](https://make.fun/?ref=8vr38xr3&utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01) · AI agents build software for cash rewards</sub>
