-- Hud: every pixel of Meteorfall's interface, built in code — the start and
-- game-over panels, the in-round readouts (wave, score, hearts, combo) and
-- the centre banners. Nothing sits in the top-left corner, where Roblox
-- draws its own menu buttons over the view.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Hud = {}

local INK = Color3.fromRGB(16, 14, 40)
local PANEL = Color3.fromRGB(26, 23, 58)
local PAPER = Color3.fromRGB(235, 240, 255)
local DIM_TEXT = Color3.fromRGB(168, 172, 214)
local CYAN = Color3.fromRGB(64, 224, 255)
local MAGENTA = Color3.fromRGB(255, 84, 168)
local AMBER = Color3.fromRGB(255, 176, 66)
local HEART = Color3.fromRGB(255, 92, 132)
local HEART_GONE = Color3.fromRGB(52, 48, 88)
local DANGER = Color3.fromRGB(255, 70, 60)
local GOLD = Color3.fromRGB(255, 196, 64)

local refs = {}
local bannerToken = 0
local toastToken = 0
local heartPulse = nil
local lastStandings = nil
local lastSnapshot = nil

local function commas(n)
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

local function label(parent, name, text, size, color, font)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size
	l.TextColor3 = color
	l.Font = font or Enum.Font.Gotham
	l.Parent = parent
	return l
end

local function panel(parent, name, size)
	local p = Instance.new("Frame")
	p.Name = name
	p.AnchorPoint = Vector2.new(0.5, 0.5)
	p.Position = UDim2.fromScale(0.5, 0.5)
	p.Size = size
	p.BackgroundColor3 = PANEL
	p.BorderSizePixel = 0
	p.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = p
	local stroke = Instance.new("UIStroke")
	stroke.Color = CYAN
	stroke.Thickness = 2
	stroke.Transparency = 0.35
	stroke.Parent = p
	return p
end

local function playButton(parent, name, text, y)
	local b = Instance.new("TextButton")
	b.Name = name
	b.AnchorPoint = Vector2.new(0.5, 0)
	b.Position = UDim2.new(0.5, 0, 0, y)
	b.Size = UDim2.fromOffset(220, 58)
	b.BackgroundColor3 = MAGENTA
	b.Text = text
	b.TextSize = 26
	b.TextColor3 = PAPER
	b.Font = Enum.Font.GothamBlack
	b.AutoButtonColor = true
	b.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = b
	return b
end

function Hud.build(callbacks)
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "MeteorfallGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 5

	local dim = Instance.new("Frame")
	dim.Name = "Dim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = INK
	dim.BackgroundTransparency = 0.45
	dim.BorderSizePixel = 0
	dim.Parent = gui
	refs.dim = dim

	-- Start panel.
	local start = panel(gui, "StartPanel", UDim2.fromOffset(500, 400))
	local title = label(start, "Title", "METEORFALL", 58, CYAN, Enum.Font.GothamBlack)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.new(0.5, 0, 0, 34)
	title.Size = UDim2.new(1, 0, 0, 70)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(CYAN, MAGENTA)
	gradient.Parent = title
	local tag = label(start, "Tagline", "Dodge the falling sky. Grab the light.", 20, PAPER)
	tag.AnchorPoint = Vector2.new(0.5, 0)
	tag.Position = UDim2.new(0.5, 0, 0, 116)
	tag.Size = UDim2.new(1, -40, 0, 28)
	local best = label(start, "Best", "", 17, DIM_TEXT)
	best.AnchorPoint = Vector2.new(0.5, 0)
	best.Position = UDim2.new(0.5, 0, 0, 152)
	best.Size = UDim2.new(1, -40, 0, 24)
	refs.startBest = best
	local play = playButton(start, "PlayButton", "PLAY", 196)
	play.MouseButton1Click:Connect(callbacks.onPlay)
	local hint = label(start, "Hint", "Move: WASD or joystick · Jump: Space · Dash: Shift\nRed ring on the floor? Run. Cyan orb? Combo. Gold orb? A shield.", 16, DIM_TEXT)
	hint.AnchorPoint = Vector2.new(0.5, 0)
	hint.Position = UDim2.new(0.5, 0, 0, 282)
	hint.Size = UDim2.new(1, -56, 0, 60)
	refs.startPanel = start

	-- Game-over panel.
	local over = panel(gui, "OverPanel", UDim2.fromOffset(500, 430))
	local overTitle = label(over, "Title", "GAME OVER", 46, MAGENTA, Enum.Font.GothamBlack)
	overTitle.AnchorPoint = Vector2.new(0.5, 0)
	overTitle.Position = UDim2.new(0.5, 0, 0, 28)
	overTitle.Size = UDim2.new(1, 0, 0, 58)
	local rows = label(over, "Standings", "", 20, PAPER, Enum.Font.GothamBold)
	rows.AnchorPoint = Vector2.new(0.5, 0)
	rows.Position = UDim2.new(0.5, 0, 0, 104)
	rows.Size = UDim2.new(1, -70, 0, 150)
	rows.TextYAlignment = Enum.TextYAlignment.Top
	refs.standings = rows
	local yours = label(over, "Yours", "", 18, AMBER, Enum.Font.GothamBold)
	yours.AnchorPoint = Vector2.new(0.5, 0)
	yours.Position = UDim2.new(0.5, 0, 0, 262)
	yours.Size = UDim2.new(1, -40, 0, 26)
	refs.yours = yours
	local again = playButton(over, "AgainButton", "PLAY AGAIN", 306)
	again.MouseButton1Click:Connect(callbacks.onPlay)
	over.Visible = false
	refs.overPanel = over

	-- In-round readouts, top centre: wave over score.
	local top = Instance.new("Frame")
	top.Name = "TopReadout"
	top.AnchorPoint = Vector2.new(0.5, 0)
	top.Position = UDim2.new(0.5, 0, 0, 10)
	top.Size = UDim2.fromOffset(320, 74)
	top.BackgroundTransparency = 1
	top.Parent = gui
	local wave = label(top, "Wave", "WAVE 1", 19, CYAN, Enum.Font.GothamBold)
	wave.Size = UDim2.new(1, 0, 0, 24)
	local score = label(top, "Score", "0", 40, PAPER, Enum.Font.GothamBlack)
	score.Position = UDim2.fromOffset(0, 24)
	score.Size = UDim2.new(1, 0, 0, 48)
	refs.wave = wave
	refs.score = score
	refs.top = top

	-- Hearts, top right: one tile per heart, lit or dark.
	local hearts = Instance.new("Frame")
	hearts.Name = "Hearts"
	hearts.AnchorPoint = Vector2.new(1, 0)
	hearts.Position = UDim2.new(1, -16, 0, 16)
	hearts.Size = UDim2.fromOffset(3 * 30 + 16, 30)
	hearts.BackgroundTransparency = 1
	hearts.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Parent = hearts
	refs.heartTiles = {}
	for i = 1, 3 do
		local tile = Instance.new("Frame")
		tile.Name = "Heart" .. i
		tile.Size = UDim2.fromOffset(30, 30)
		tile.BackgroundColor3 = HEART
		tile.BorderSizePixel = 0
		tile.Parent = hearts
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 9)
		corner.Parent = tile
		refs.heartTiles[i] = tile
	end
	refs.hearts = hearts

	-- The shield tile, under the hearts: gold while a shield is held.
	local shieldTile = Instance.new("Frame")
	shieldTile.Name = "ShieldTile"
	shieldTile.AnchorPoint = Vector2.new(1, 0)
	shieldTile.Position = UDim2.new(1, -16, 0, 56)
	shieldTile.Size = UDim2.fromOffset(30, 30)
	shieldTile.BackgroundColor3 = GOLD
	shieldTile.BorderSizePixel = 0
	shieldTile.Visible = false
	shieldTile.Parent = gui
	local shieldCorner = Instance.new("UICorner")
	shieldCorner.CornerRadius = UDim.new(0, 15)
	shieldCorner.Parent = shieldTile
	local shieldCore = Instance.new("Frame")
	shieldCore.Name = "Core"
	shieldCore.AnchorPoint = Vector2.new(0.5, 0.5)
	shieldCore.Position = UDim2.fromScale(0.5, 0.5)
	shieldCore.Size = UDim2.fromOffset(14, 14)
	shieldCore.BackgroundColor3 = PAPER
	shieldCore.BorderSizePixel = 0
	shieldCore.Parent = shieldTile
	local coreCorner = Instance.new("UICorner")
	coreCorner.CornerRadius = UDim.new(0, 7)
	coreCorner.Parent = shieldCore
	refs.shieldTile = shieldTile

	-- Combo, bottom centre.
	local combo = label(gui, "Combo", "", 27, AMBER, Enum.Font.GothamBlack)
	combo.AnchorPoint = Vector2.new(0.5, 1)
	combo.Position = UDim2.new(0.5, 0, 1, -24)
	combo.Size = UDim2.new(1, 0, 0, 34)
	combo.Visible = false
	refs.combo = combo

	-- Spectator note, under the top readout.
	local note = label(gui, "Note", "", 17, DIM_TEXT, Enum.Font.GothamBold)
	note.AnchorPoint = Vector2.new(0.5, 0)
	note.Position = UDim2.new(0.5, 0, 0, 92)
	note.Size = UDim2.new(1, 0, 0, 24)
	note.Visible = false
	refs.note = note

	-- Centre banner: wave calls and clear bonuses.
	local banner = label(gui, "Banner", "", 48, PAPER, Enum.Font.GothamBlack)
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.new(0.5, 0, 0.3, 0)
	banner.Size = UDim2.new(1, 0, 0, 60)
	banner.TextTransparency = 1
	refs.banner = banner
	local bannerSub = label(gui, "BannerSub", "", 21, CYAN, Enum.Font.GothamBold)
	bannerSub.AnchorPoint = Vector2.new(0.5, 0.5)
	bannerSub.Position = UDim2.new(0.5, 0, 0.3, 52)
	bannerSub.Size = UDim2.new(1, 0, 0, 28)
	bannerSub.TextTransparency = 1
	refs.bannerSub = bannerSub

	-- A small gold word for shield news, under the banner.
	local toast = label(gui, "Toast", "", 26, GOLD, Enum.Font.GothamBlack)
	toast.AnchorPoint = Vector2.new(0.5, 0.5)
	toast.Position = UDim2.new(0.5, 0, 0.42, 0)
	toast.Size = UDim2.new(1, 0, 0, 34)
	toast.TextTransparency = 1
	refs.toast = toast

	-- The red wash of a hit, above everything.
	local flash = Instance.new("Frame")
	flash.Name = "DamageFlash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = DANGER
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 50
	flash.Parent = gui
	refs.flash = flash

	gui.Parent = player:WaitForChild("PlayerGui")
	return gui
end

local function setInRoundChrome(snap)
	local playing = snap.phase == "Playing"
	refs.top.Visible = playing
	refs.hearts.Visible = playing
	refs.shieldTile.Visible = playing and snap.shield == true
	refs.wave.Text = "WAVE " .. math.max(snap.wave, 1)
	refs.score.Text = commas(snap.score)
	for i, tile in refs.heartTiles do
		tile.BackgroundColor3 = (i <= snap.hearts) and HEART or HEART_GONE
		tile.Visible = i <= snap.maxHearts
	end
	-- One heart left: the last tile throbs until it is spent or healed.
	if snap.hearts == 1 and snap.alive then
		if not heartPulse then
			heartPulse = TweenService:Create(refs.heartTiles[1], TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				Size = UDim2.fromOffset(36, 36),
			})
			heartPulse:Play()
		end
	elseif heartPulse then
		heartPulse:Cancel()
		heartPulse = nil
		refs.heartTiles[1].Size = UDim2.fromOffset(30, 30)
	end
	if snap.combo >= 2 and snap.alive then
		refs.combo.Text = "COMBO x" .. snap.combo
		refs.combo.Visible = true
	else
		refs.combo.Visible = false
	end
	if playing and not snap.inRound then
		refs.note.Text = "Round in progress — you're in the next one"
		refs.note.Visible = true
	elseif playing and not snap.alive then
		refs.note.Text = "You're out — watching the sky fall"
		refs.note.Visible = true
	else
		refs.note.Visible = false
	end
end

function Hud.applyState(snap)
	lastSnapshot = snap
	if snap.phase == "Lobby" then
		refs.dim.Visible = true
		refs.startPanel.Visible = true
		refs.overPanel.Visible = false
		refs.top.Visible = false
		refs.hearts.Visible = false
		refs.shieldTile.Visible = false
		refs.combo.Visible = false
		refs.note.Visible = false
		refs.startBest.Text = (snap.best > 0) and ("Your best: " .. commas(snap.best)) or "Survive the waves. Bank the orbs. Beat your best."
	elseif snap.phase == "Playing" then
		refs.dim.Visible = false
		refs.startPanel.Visible = false
		refs.overPanel.Visible = false
		setInRoundChrome(snap)
	elseif snap.phase == "Over" then
		refs.dim.Visible = true
		refs.startPanel.Visible = false
		refs.top.Visible = false
		refs.hearts.Visible = false
		refs.shieldTile.Visible = false
		refs.combo.Visible = false
		refs.note.Visible = false
		if lastStandings then
			refs.overPanel.Visible = true
		end
	end
end

function Hud.showGameOver(standings)
	lastStandings = standings
	local lines = {}
	for i, row in standings do
		if i > 5 then
			break
		end
		lines[#lines + 1] = i .. ".  " .. row.name .. "  —  " .. commas(row.score)
	end
	refs.standings.Text = table.concat(lines, "\n")
	if lastSnapshot then
		refs.yours.Text = "You: " .. commas(lastSnapshot.score) .. "   ·   Best: " .. commas(math.max(lastSnapshot.best, lastSnapshot.score))
	end
	refs.overPanel.Visible = true
	refs.dim.Visible = true
end

function Hud.banner(headline, subline)
	bannerToken += 1
	local token = bannerToken
	refs.banner.Text = headline
	refs.bannerSub.Text = subline or ""
	refs.banner.TextTransparency = 0
	refs.bannerSub.TextTransparency = 0
	task.delay(1.7, function()
		if token ~= bannerToken then
			return
		end
		TweenService:Create(refs.banner, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		TweenService:Create(refs.bannerSub, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
	end)
end

local function flashWith(color, alpha)
	refs.flash.BackgroundColor3 = color
	refs.flash.BackgroundTransparency = alpha
	TweenService:Create(refs.flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
end

function Hud.damageFlash(died)
	flashWith(DANGER, died and 0.35 or 0.55)
end

-- The gold wash of a blast the shield swallowed.
function Hud.shieldFlash()
	flashWith(GOLD, 0.62)
end

-- A short gold headline for shield news.
function Hud.toast(text)
	toastToken += 1
	local token = toastToken
	refs.toast.Text = text
	refs.toast.TextTransparency = 0
	task.delay(1.4, function()
		if token ~= toastToken then
			return
		end
		TweenService:Create(refs.toast, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
	end)
end

-- A little pop on the combo readout when an orb lands.
function Hud.orbPop()
	if not refs.combo.Visible then
		return
	end
	refs.combo.TextSize = 33
	TweenService:Create(refs.combo, TweenInfo.new(0.22), { TextSize = 27 }):Play()
end

return Hud
