-- Draws the stage twists. The server decides every effect (Server/StageTwists); this only shows warnings and props from the same server clock
-- (Shared/StageTwistMath): a warning line, minecarts, sliding containers, lanterns, neon pads, cart-lane markers and the lightning circles.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Config = require(RS.Shared.Config)
local Remotes = require(RS.Shared.Remotes)
local Timeline = require(RS.Shared.StageTwistMath)
local StageZone = require(RS.Shared.StageZone)
local UIKit = require(script.Parent.UIKit)
local T = Config.StageTwists
local FX = {}
local PARKED = CFrame.new(0, -500, 0)

local function prop(name, size, color, material, parent)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Color, p.Material = name, size, color, material
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
	p.Parent = parent
	return p
end
local function glow(part, lit, onColor, offColor)
	part.Color = lit and onColor or offColor
	part.Material = lit and Enum.Material.Neon or Enum.Material.SmoothPlastic
end

-- The one-line warning for the stage the player is in (and "gold" when it is good news), or nil.
local function warning(stage, now)
	local cfg = stage and T.Stages[stage]
	if not cfg then return end
	local kind = cfg.Kind
	if kind == "Gust" then
		local state, left = Timeline.State(now, cfg.Period, cfg.Duration, cfg.Warn, 0)
		if state == "warn" then return ("Dust gust in %d!"):format(math.ceil(left)) end
		if state == "active" then return "Dust gust! You are slowed" end
	elseif kind == "Cart" then
		for lane = 1, cfg.Lanes do if Timeline.CartState(cfg, lane, now) ~= "idle" then return "Minecart crossing!" end end
	elseif kind == "Blackout" then
		local state = Timeline.State(now, cfg.Period, cfg.Duration, cfg.Warn, 0)
		if state == "warn" then return "Lanterns flickering..." end
		if state == "active" then return "Lanterns out: guards see less" end
	elseif kind == "Container" then
		for index = 1, cfg.Count do if Timeline.ContainerState(cfg, index, now) ~= "idle" then return "Containers sliding!" end end
	elseif kind == "GoldenHour" then
		local state, left = Timeline.State(now, cfg.Period, cfg.Duration, cfg.Warn, 0)
		if state == "warn" then return ("Golden Hour in %d s"):format(math.ceil(left)), "gold" end
		if state == "active" then return ("GOLDEN HOUR: +%s luck (%d s)"):format(cfg.Luck, math.ceil(left)), "gold" end
	end
end

function FX.Init()
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn = "StageTwistWarning", false
	gui.Parent = player:WaitForChild("PlayerGui")
	UIKit.Screen(gui)
	local label = Instance.new("TextLabel")
	label.AnchorPoint, label.Position, label.Size = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, Config.UIScreen.TopWarning), UDim2.fromScale(0.6, 0.06)
	label.TextScaled, label.Visible, label.Parent = true, false, gui
	Instance.new("UITextSizeConstraint", label).MaxTextSize = 24
	UIKit.Text(label, "warn")

	local props = Instance.new("Folder")
	props.Name, props.Parent = "StageTwistProps", workspace
	local cartCfg, boxCfg = T.Stages[4], T.Stages[7]
	local carts, boxes = {}, {}
	for lane = 1, cartCfg.Lanes do carts[lane] = prop("Cart" .. lane, cartCfg.Size, cartCfg.Color, Enum.Material.Metal, props) carts[lane].CFrame = PARKED end
	for index = 1, boxCfg.Count do boxes[index] = prop("Container" .. index, boxCfg.Size, boxCfg.Color, Enum.Material.CorrodedMetal, props) boxes[index].CFrame = PARKED end

	local stage, floor, lightningUntil, nextCheck, nextColor = nil, nil, 0, 0, 0 -- the floor streams in with the player, so it is read from the stage lookup, not cached at start
	local function place(parts, count, cfg, positionX)
		for index, part in parts do
			local x = floor and positionX(index)
			part.CFrame = x and CFrame.new(floor.Position.X + x, floor.Position.Y + floor.Size.Y / 2 + cfg.Size.Y / 2, Timeline.LaneZ(floor, index, count)) or PARKED
		end
	end
	local function recolor(now)
		local cfg = stage and T.Stages[stage]
		if not cfg then return end
		if cfg.Kind == "Blackout" then
			local state = Timeline.State(now, cfg.Period, cfg.Duration, cfg.Warn, 0)
			local lit = state == "idle" or (state == "warn" and math.floor(now * 6) % 2 == 0)
			for _, bulb in CS:GetTagged("TwistLantern") do glow(bulb, lit, cfg.LitColor, cfg.DarkColor) end
		elseif cfg.Kind == "Pads" then
			for _, pad in CS:GetTagged("TwistZone") do
				if pad:GetAttribute("Kind") == "Pads" then glow(pad, Timeline.PadLit(cfg, pad:GetAttribute("Index"), now), cfg.Zones.Color, cfg.DarkColor) end
			end
		elseif cfg.Kind == "Cart" then
			for _, marker in CS:GetTagged("TwistMarker") do
				glow(marker, Timeline.CartState(cfg, marker:GetAttribute("Lane"), now) ~= "idle", T.WarnColor, T.IdleMarker)
			end
		end
	end

	RunService.Heartbeat:Connect(function()
		local now, clock = workspace:GetServerTimeNow(), os.clock()
		if clock >= nextCheck then
			nextCheck = clock + T.Tick
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			stage, floor = nil, nil
			if root then stage, floor = StageZone.At(root.Position) end
			local text, kind
			if clock < lightningUntil then text = "LIGHTNING! Move!" else text, kind = warning(stage, now) end
			label.Visible, label.Text = text ~= nil, text or ""
			label.TextColor3 = kind == "gold" and Config.UITheme.TextGold or Config.UITheme.TextWarn
		end
		if clock >= nextColor then nextColor = clock + 0.15 recolor(now) end
		local half = floor and floor.Size.X / 2
		place(carts, cartCfg.Lanes, cartCfg, function(lane) return stage == 4 and Timeline.CartX(cartCfg, lane, now, half) end)
		place(boxes, boxCfg.Count, boxCfg, function(index) return stage == 7 and Timeline.ContainerX(boxCfg, index, now, half) end)
	end)

	Remotes.TwistEvent.OnClientEvent:Connect(function(kind, position, radius, seconds)
		if kind == "Warn" then
			local disc = prop("LightningWarning", Vector3.new(0.2, radius * 2, radius * 2), T.WarnColor, Enum.Material.Neon, props)
			disc.Shape, disc.Transparency = Enum.PartType.Cylinder, 0.6
			disc.CFrame = CFrame.new(position + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
			TweenService:Create(disc, TweenInfo.new(seconds), {Transparency = 0.1}):Play()
			Debris:AddItem(disc, seconds + 0.1)
			lightningUntil = os.clock() + seconds
		elseif kind == "Strike" then
			local bolt = prop("LightningBolt", Vector3.new(2, 90, 2), Color3.new(1, 1, 1), Enum.Material.Neon, props)
			bolt.CFrame = CFrame.new(position + Vector3.new(0, 45, 0))
			Debris:AddItem(bolt, 0.2)
			lightningUntil = 0
		end
	end)
end

return FX
