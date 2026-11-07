--[[
	GuardService: simple NPC guards. Each stage has Config.GuardCountPerStage[stage] guards that
	patrol random points inside their own stage zone. A guard chases ONLY a player carrying an unsecured character taken from its stage
	(card attribute SourceStage); when it touches that carrier it knocks them back (the hit client applies the impulse) and makes
	them drop the card. Nobody else is ever chased or touched. No pathfinding: guards steer in a straight line, clamped to their zone.
	Guards ALWAYS patrol. Guards with a player within Config.GuardNearDistance are updated every frame
	(chase/hit logic); all others only re-evaluate their patrol Config.GuardFarUpdatesPerSecond times a second.
	Movement itself is physics (see MonsterFactory), so far guards still glide smoothly on clients.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local MonsterFactory = require(script.Parent.MonsterFactory)
local GuardService = {}

local CardService -- injected in Init
local guardsFolder = Workspace:WaitForChild("Greybox"):WaitForChild("Guards")
local rng = Random.new()
local zones = {}    -- [stage] = floor part
local guards = {}   -- { { model, view, stage, waypoint, margin, stunUntil, near, nextPatrol }, ... }
local hitUntil = {} -- [Player] = os.clock() until which the player is immune

local function pointIn(zone: Part, margin: number?): Vector3
	local reach = zone.Size / 2 - Vector3.one * (margin or Config.GuardZoneMargin)
	return Vector3.new(
		zone.Position.X + rng:NextNumber(-reach.X, reach.X),
		Config.GroundY + Config.GuardSize.Y / 2,
		zone.Position.Z + rng:NextNumber(-reach.Z, reach.Z)
	)
end

local function clampToZone(position: Vector3, zone: Part, margin: number?): Vector3
	local reach = zone.Size / 2 - Vector3.one * (margin or Config.GuardZoneMargin)
	return Vector3.new(
		math.clamp(position.X, zone.Position.X - reach.X, zone.Position.X + reach.X),
		position.Y,
		math.clamp(position.Z, zone.Position.Z - reach.Z, zone.Position.Z + reach.Z)
	)
end

local function createGuard(stage: number,index: number)
 local zone=zones[stage]
 local list=Config.MonsterGuards.Stages[stage]
 local model,view=MonsterFactory.Build(list[(index-1)%#list+1],pointIn(zone))
 local margin=Config.GuardZoneMargin+math.max(view.width,view.depth)/2
 model:PivotTo(CFrame.new(pointIn(zone,margin)))
 MonsterFactory.Hold(view)
 model.Name="Guard_Stage"..stage.."_"..index
 model:SetAttribute("Stage",stage)
 CollectionService:AddTag(model,"Guard")
 model.Parent=guardsFolder
 MonsterFactory.Activate(view)
 table.insert(guards,{model=model,view=view,stage=stage,waypoint=pointIn(zone,margin),margin=margin,stunUntil=0,near=false,nextPatrol=0,
  hitRadius=view.height*Config.GuardHit.PerHeight+Config.GuardHit.Margin})
end

local function livingTargets(): { { player: Player, root: BasePart } }
	local targets = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			table.insert(targets, { player = player, root = root })
		end
	end
	return targets
end

local function hit(guard, target, now: number)
	hitUntil[target.player] = now + Config.GuardHitCooldownSeconds
	guard.stunUntil = now + Config.GuardStunSeconds
	local away = target.root.Position - guard.model.PrimaryPart.Position
	local flat = Vector3.new(away.X, 0, away.Z)
	local direction = flat.Magnitude > 0 and flat.Unit or Vector3.zAxis
	if target.player.Character then target.player.Character:SetAttribute("HurtStart",workspace:GetServerTimeNow()) end
	Remotes.Knockback:FireClient(target.player, direction * Config.GuardKnockbackSpeed + Vector3.new(0, Config.GuardKnockbackUp, 0))
	CardService.DropCarried(target.player)
end

-- A guard only goes after a player carrying an unsecured character taken from ITS stage, and only while that player is inside the stage.
local function wantsToChase(guard, target): boolean
	local card = CardService.GetCarried(target.player)
	if not card or card:GetAttribute("Escaped") or card:GetAttribute("SourceStage") ~= guard.stage then return false end
	local localPoint = zones[guard.stage].CFrame:PointToObjectSpace(target.root.Position)
	return math.abs(localPoint.X) <= zones[guard.stage].Size.X / 2 and math.abs(localPoint.Z) <= zones[guard.stage].Size.Z / 2
end

local function flat(v: Vector3): Vector3 return Vector3.new(v.X, 0, v.Z) end

-- A touch: the carrier's body is within the guard's visible body radius of the path it just walked (so a fast guard cannot skip past a
-- player between two frames) and at a height the body reaches.
local function touches(guard, target, previous: Vector3, position: Vector3): boolean
	local root = target.root.Position
	if math.abs(root.Y - position.Y) > guard.view.height / 2 + Config.GuardHit.PlayerHalfHeight then return false end
	local a, b, p = flat(previous), flat(position), flat(root)
	local along = b - a
	local t = along.Magnitude > 1e-4 and math.clamp(along:Dot(p - a) / along:Dot(along), 0, 1) or 0
	return (p - (a + along * t)).Magnitude <= guard.hitRadius
end

-- `targets` is nil for far guards: they only patrol (no chase or hit checks).
local function updateGuard(guard, targets, now: number)
	local view, zone = guard.view, zones[guard.stage]
	local position = guard.model.PrimaryPart.Position
	local previous = guard.lastPosition or position
	guard.lastPosition = position
	if now < guard.stunUntil then MonsterFactory.Stop(view) return end

	local nearest, nearestDistance
	for _, target in ipairs(targets or {}) do
		if wantsToChase(guard, target) then
			if (hitUntil[target.player] or 0) <= now and touches(guard, target, previous, position) then
				hit(guard, target, now)
				MonsterFactory.Attack(view)
				MonsterFactory.Stop(view)
				return
			end
			local distance = (flat(target.root.Position) - flat(position)).Magnitude
			if not nearest or distance < nearestDistance then nearest, nearestDistance = target, distance end
		end
	end

	local destination, speed, running
	if nearest then
		destination, speed, running = nearest.root.Position, Config.GuardChaseSpeed[guard.stage], true
		guard.model:SetAttribute('ChasePlayerUserId',nearest.player.UserId)
	else
		guard.model:SetAttribute('ChasePlayerUserId',nil)
		if Vector3.new(guard.waypoint.X - position.X, 0, guard.waypoint.Z - position.Z).Magnitude <= Config.GuardWaypointReach then
			guard.waypoint = pointIn(zone,guard.margin)
		end
		destination, speed = guard.waypoint, Config.GuardChaseSpeed[guard.stage] * Config.GuardPatrolSpeedFactor
	end
	MonsterFactory.Drive(view, clampToZone(destination, zone, guard.margin), speed, running)
end

local function step()
	local now = os.clock()
	local targets
	for _, guard in ipairs(guards) do
		if guard.near then
			targets = targets or livingTargets()
			updateGuard(guard, targets, now)
		elseif now >= guard.nextPatrol then
			guard.nextPatrol = now + 1 / Config.GuardFarUpdatesPerSecond
			updateGuard(guard, nil, now)
		end
	end
end

--- Classify guards by their distance to the nearest living player: near guards run every frame, animations and
--- effects only run for guards a player can actually see.
local function refreshNear()
	local targets = livingTargets()
	for _, guard in ipairs(guards) do
		local nearest = math.huge
		local position = guard.model.PrimaryPart.Position
		for _, target in ipairs(targets) do nearest = math.min(nearest, (target.root.Position - position).Magnitude) end
		guard.near = nearest <= Config.GuardNearDistance
		if not guard.near then for _, target in ipairs(targets) do if wantsToChase(guard, target) then guard.near = true break end end end -- a carrier in the stage is always chased, however far
		MonsterFactory.SetEffects(guard.view, nearest <= Config.MonsterGuards.EffectsDistance)
		MonsterFactory.SetAnimated(guard.view, nearest <= Config.MonsterGuards.AnimationDistance)
		if not guard.near then guard.model:SetAttribute('ChasePlayerUserId',nil) end
	end
end

function GuardService.Init(cardService)
	CardService = cardService
	for _, floor in ipairs(CollectionService:GetTagged("StageZone")) do
		zones[floor:GetAttribute("Stage")] = floor
	end
	for stage in pairs(zones) do
		for index = 1, Config.GuardCountPerStage[stage] do
			createGuard(stage,index)
		end
	end
	Players.PlayerRemoving:Connect(function(player) hitUntil[player] = nil end)
	RunService.Heartbeat:Connect(step)
	task.spawn(function()
		while true do
			refreshNear()
			task.wait(Config.GuardNearCheckSeconds)
		end
	end)
end

return GuardService
