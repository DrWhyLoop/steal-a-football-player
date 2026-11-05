--[[
	GuardService: simple NPC guards. Each stage has Config.GuardCountPerStage[stage] guards that
	patrol random points inside their own stage zone and chase the nearest player in range.
	A guard that touches a player knocks them back (the hit client applies the impulse) and makes
	them drop their card. No pathfinding: guards steer in a straight line, clamped to their zone.
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
 local design=list[(index-1)%#list+1]
 local model,view=MonsterFactory.Build(design,pointIn(zone))
 view.patrolSpeed=Config.GuardChaseSpeed[stage]*Config.GuardPatrolSpeedFactor
 local margin=Config.GuardZoneMargin+math.max(view.width,view.depth)/2
 model:PivotTo(CFrame.new(pointIn(zone,margin)))
 MonsterFactory.Hold(view)
 model.Name="Guard_Stage"..stage.."_"..index
 model:SetAttribute("Stage",stage)
 CollectionService:AddTag(model,"Guard")
 model.Parent=guardsFolder
 MonsterFactory.Activate(view)
 table.insert(guards,{model=model,view=view,stage=stage,waypoint=pointIn(zone,margin),margin=margin,stunUntil=0,near=false,nextPatrol=0})
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

-- `targets` is nil for far guards: they only patrol (no chase or hit checks).
local function updateGuard(guard, targets, now: number)
	local view, zone = guard.view, zones[guard.stage]
	if now < guard.stunUntil then MonsterFactory.Stop(view) return end
	local position = guard.model.PrimaryPart.Position

	local nearest, nearestDistance, bestPriority
	for _, target in ipairs(targets or {}) do
		local offset = target.root.Position - position
		if offset.Magnitude <= Config.GuardHitRadius and (hitUntil[target.player] or 0) <= now then
			hit(guard, target, now)
			MonsterFactory.Stop(view)
			return
		end
		local flat = Vector3.new(offset.X, 0, offset.Z).Magnitude
		local card=CardService.GetCarried(target.player)
		local localPoint=zone.CFrame:PointToObjectSpace(target.root.Position)
		local carrierInside=card and math.abs(localPoint.X)<=zone.Size.X/2 and math.abs(localPoint.Z)<=zone.Size.Z/2
		local priority=card and (card:GetAttribute('OriginalOwnerUserId') and 2 or 1) or 0
		if (card or not target.player:GetAttribute("DropDisengaged")) and (carrierInside or flat<=Config.GuardChaseRange[guard.stage]) and (not nearest or priority>bestPriority or priority==bestPriority and flat<nearestDistance) then
			nearest,nearestDistance,bestPriority=target,flat,priority
		end
	end

	local destination, speed
	if nearest then
		destination, speed = nearest.root.Position, Config.GuardChaseSpeed[guard.stage]
		guard.model:SetAttribute('ChasePlayerUserId',nearest.player.UserId)
	else
		guard.model:SetAttribute('ChasePlayerUserId',nil)
		if Vector3.new(guard.waypoint.X - position.X, 0, guard.waypoint.Z - position.Z).Magnitude <= Config.GuardWaypointReach then
			guard.waypoint = pointIn(zone,guard.margin)
		end
		destination, speed = guard.waypoint, Config.GuardChaseSpeed[guard.stage] * Config.GuardPatrolSpeedFactor
	end
	MonsterFactory.Drive(view, clampToZone(destination, zone, guard.margin), speed)
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
		local visible = nearest <= Config.MonsterGuards.EffectsDistance
		MonsterFactory.SetEffects(guard.view, visible)
		MonsterFactory.SetAnimated(guard.view, visible)
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
