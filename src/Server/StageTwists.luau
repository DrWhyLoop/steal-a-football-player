-- Stage twists (Config.StageTwists), server side: speed changes, stuns, guard detection, luck and lightning. Everything is decided here from the shared
-- server clock (Shared/StageTwistMath) and the zone parts built by tools/BuildStageTwists.luau; clients only draw warnings and moving props.
-- Walking speed is multiplied through the Player attribute TwistSpeed (TreadmillService), guard detection through TwistDetect (GuardService).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local Config = require(RS.Shared.Config)
local Remotes = require(RS.Shared.Remotes)
local Timeline = require(RS.Shared.StageTwistMath)
local StageZone = require(RS.Shared.StageZone)
local T = Config.StageTwists
local S = {}
local CardService
local zones = {}  -- [stage] = { {Kind, Position, Radius, Index} }
local states = {} -- [player] = per-player timers

local function flat(v: Vector3): Vector2 return Vector2.new(v.X, v.Z) end
local function inZone(stage, position, accept)
	for _, zone in zones[stage] or {} do
		if (not accept or accept(zone)) and (flat(position) - flat(zone.Position)).Magnitude <= zone.Radius then return zone end
	end
end
local function broadcast(stage, ...)
	for _, other in Players:GetPlayers() do
		local root = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		if root and StageZone.At(root.Position) == stage then Remotes.TwistEvent:FireClient(other, ...) end
	end
end

-- Lightning: a carrier of an unsecured card gets a marked spot (where they would be if they keep running, plus a sideways jitter); the circle is
-- shown for Warn seconds, and anyone still inside when it strikes loses the card.
local function lightning(player, root, floor, state, cfg, now, stage)
	local card = CardService.GetCarried(player)
	if state.strike then
		if now < state.strike.At then return end
		local target = state.strike.Position
		state.strike, state.nextStrike = nil, now + cfg.Period
		broadcast(stage, "Strike", target)
		if (flat(root.Position) - flat(target)).Magnitude <= cfg.Radius and CardService.GetCarried(player) then
			CardService.DropCarried(player)
			Remotes.Knockback:FireClient(player, Vector3.new(0, cfg.Knock, 0))
		end
	elseif not card or card:GetAttribute("Escaped") then
		state.nextStrike = nil
	else
		state.nextStrike = state.nextStrike or now + cfg.Period * (0.5 + 0.5 * math.random())
		if now < state.nextStrike then return end
		local velocity = root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
		local side = velocity.Magnitude > 1 and Vector3.new(-velocity.Z, 0, velocity.X).Unit or Vector3.xAxis
		local ahead = root.Position + velocity * cfg.Warn + side * (math.random() * 2 - 1) * cfg.Jitter
		local target = Vector3.new(ahead.X, floor.Position.Y + floor.Size.Y / 2, ahead.Z)
		state.strike = {Position = target, At = now + cfg.Warn}
		broadcast(stage, "Warn", target, cfg.Radius, cfg.Warn)
	end
end

local function evaluate(player: Player, root: BasePart, now: number)
	local state = states[player] or {}
	states[player] = state
	local position, last = root.Position, state.last or root.Position
	state.last = position
	local stage, floor = StageZone.At(position)
	local cfg = stage and T.Stages[stage]
	local speed, detect = 1, 1
	if cfg then
		local kind = cfg.Kind
		if kind == "Boost" or kind == "Pads" then
			if inZone(stage, position, function(zone) return kind == "Boost" or Timeline.PadLit(cfg, zone.Index, now) end) then
				state.boostUntil, state.boostMult = now + cfg.Seconds, cfg.Mult
			end
		elseif kind == "Clover" then
			if now >= (state.cloverReadyAt or 0) and inZone(stage, position) then
				state.cloverReadyAt, state.clover = now + cfg.Cooldown, true
				Remotes.Announcement:FireClient(player, ("Lucky clover! +%s luck on your next cage"):format(cfg.Luck))
			end
		elseif kind == "Gust" then
			if Timeline.State(now, cfg.Period, cfg.Duration, cfg.Warn, 0) == "active" then speed *= 1 - cfg.Slow end
		elseif kind == "Cart" then
			local half = floor.Size.X / 2
			for lane = 1, cfg.Lanes do
				local x = Timeline.CartX(cfg, lane, now, half)
				if x and now >= (state.cartReadyAt or 0) then
					local laneZ = Timeline.LaneZ(floor, lane, cfg.Lanes)
					local reachX, reachZ = cfg.Size.X / 2 + cfg.Margin, cfg.Size.Z / 2 + cfg.Margin
					if math.abs(position.X - (floor.Position.X + x)) <= reachX and math.max(last.Z, position.Z) >= laneZ - reachZ and math.min(last.Z, position.Z) <= laneZ + reachZ then
						state.stunUntil, state.cartReadyAt = now + cfg.Stun, now + cfg.Stun + cfg.Cooldown
					end
				end
			end
		elseif kind == "Blackout" then
			if Timeline.State(now, cfg.Period, cfg.Duration, cfg.Warn, 0) == "active" then detect = cfg.Detect end
		elseif kind == "Mist" then
			if inZone(stage, position) then detect = cfg.Detect end
		elseif kind == "Container" then
			for index = 1, cfg.Count do
				local x = Timeline.ContainerX(cfg, index, now, floor.Size.X / 2)
				local z = Timeline.LaneZ(floor, index, cfg.Count)
				if math.abs(position.X - (floor.Position.X + x)) <= cfg.Size.X / 2 and math.abs(position.Z - z) <= cfg.Size.Z / 2 then speed *= 1 - cfg.Slow break end
			end
		elseif kind == "Lava" or kind == "Ice" then
			if inZone(stage, position) then speed *= 1 - cfg.Slow end
		elseif kind == "Lightning" then
			lightning(player, root, floor, state, cfg, now, stage)
		end
	end
	if now < (state.boostUntil or 0) then speed *= state.boostMult end
	if now < (state.stunUntil or 0) then speed = 0 end
	if player:GetAttribute("TwistSpeed") ~= speed then player:SetAttribute("TwistSpeed", speed) end
	if player:GetAttribute("TwistDetect") ~= detect then player:SetAttribute("TwistDetect", detect) end
end

--- Extra luck for a cage break in `stage`: a lucky clover waiting for this player (used up) plus the Golden Hour of Stage 12.
function S.TakeLuck(player: Player?, stage: number?): number
	local bonus, state = 0, player and states[player]
	if state and state.clover then
		state.clover = nil
		bonus += T.Stages[2].Luck
	end
	local hour = T.Stages[12]
	if stage == 12 and Timeline.State(workspace:GetServerTimeNow(), hour.Period, hour.Duration, hour.Warn, 0) == "active" then bonus += hour.Luck end
	return bonus
end

function S.Init(cardService)
	CardService = cardService
	for _, part in CS:GetTagged("TwistZone") do
		local stage = part:GetAttribute("Stage")
		zones[stage] = zones[stage] or {}
		table.insert(zones[stage], {Kind = part:GetAttribute("Kind"), Position = part.Position, Radius = part:GetAttribute("Radius"), Index = part:GetAttribute("Index")})
	end
	Players.PlayerRemoving:Connect(function(player) states[player] = nil end)
	task.spawn(function()
		while true do
			task.wait(T.Tick)
			local now = workspace:GetServerTimeNow()
			for _, player in Players:GetPlayers() do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if root and humanoid and humanoid.Health > 0 and player:GetAttribute("DataReady") == true then evaluate(player, root, now) end
			end
		end
	end)
end

return S
