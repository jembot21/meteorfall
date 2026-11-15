-- Meteorfall, bootstrap (client). Builds the HUD and the camera effects,
-- then routes the server's tagged messages: state snapshots to the HUD,
-- banners to the centre of the screen, hits to the shake and the red wash.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Hud = require(script.Parent.Hud)
local Effects = require(script.Parent.Effects)

local remotes = ReplicatedStorage:WaitForChild("MeteorfallRemotes")
local toClient = remotes:WaitForChild("ToClient")
local toServer = remotes:WaitForChild("ToServer")

Hud.build({
	onPlay = function()
		toServer:FireServer("Start")
	end,
})
Effects.attach()

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		Effects.dash()
	end
end)

toClient.OnClientEvent:Connect(function(kind, a, b)
	if kind == "State" then
		Hud.applyState(a)
	elseif kind == "Banner" then
		Hud.banner(a, b)
	elseif kind == "Hit" then
		if b then
			-- A shield ate the blast: a gold flash, a smaller shake, a word.
			Effects.shake(0.3)
			Hud.shieldFlash()
			Hud.toast("SHIELD DOWN — it ate that one")
		else
			Effects.shake(a and 1 or 0.55)
			Hud.damageFlash(a)
		end
	elseif kind == "Orb" then
		Hud.orbPop()
	elseif kind == "Shield" then
		Hud.toast("SHIELD UP")
	elseif kind == "GameOver" then
		Hud.showGameOver(a)
	end
end)
