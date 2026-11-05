--[[
	GuardService: simple NPC guards. Each stage has Config.GuardCountPerStage[stage] guards that
	patrol random points inside their own stage zone and chase the nearest player in range.
	A guard that touches a player knocks them back (the hit client applies the impulse) and makes
	them drop their card. No pathfinding: guards move in a straight line, clamped to their zone.
	Guards only update while a player is within Config.GuardActivationDistance of their stage;
	otherwise they stand still and the Heartbeat connection is disconnected entirely.
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
local guards = {}   -- [stage] = { { model, stage, waypoint, stunUntil }, ... }
local active = {}   -- [stage] = true while a player is near
local hitUntil = {} -- [Player] = os.clock() until which the player is immune
local heartbeat: RBXScriptConnection?

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
 local margin=Config.GuardZoneMargin+math.max(view.width,view.depth)/2
 model:PivotTo(CFrame.new(pointIn(zone,margin)))
 MonsterFactory.Pose(view,model.PrimaryPart,false,0)
 model.Name="Guard_Stage"..stage.."_"..index
 model:SetAttribute("Stage",stage)
 CollectionService:AddTag(model,"Guard")
 model.Parent=guardsFolder
 table.insert(guards[stage],{model=model,view=view,stage=stage,waypoint=pointIn(zone,margin),margin=margin,stunUntil=0})
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

local function updateGuard(guard, targets, dt: number, now: number)
	if now < guard.stunUntil then MonsterFactory.Pose(guard.view,guard.model.PrimaryPart,false,now) return end
	local stage, zone = guard.stage, zones[guard.stage]
	local position = guard.model.PrimaryPart.Position

	local nearest, nearestDistance, bestPriority
	for _, target in ipairs(targets) do
		local offset = target.root.Position - position
		if offset.Magnitude <= Config.GuardHitRadius and (hitUntil[target.player] or 0) <= now then
			hit(guard, target, now)
			return
		end
		local flat = Vector3.new(offset.X, 0, offset.Z).Magnitude
		local card=CardService.GetCarried(target.player)
		local localPoint=zone.CFrame:PointToObjectSpace(target.root.Position)
		local carrierInside=card and math.abs(localPoint.X)<=zone.Size.X/2 and math.abs(localPoint.Z)<=zone.Size.Z/2
		local priority=card and (card:GetAttribute('OriginalOwnerUserId') and 2 or 1) or 0
		if (carrierInside or flat<=Config.GuardChaseRange[stage]) and (not nearest or priority>bestPriority or priority==bestPriority and flat<nearestDistance) then
			nearest,nearestDistance,bestPriority=target,flat,priority
		end
	end

	local destination, speed
	if nearest then
		destination, speed = nearest.root.Position, Config.GuardChaseSpeed[stage]
		guard.model:SetAttribute('ChasePlayerUserId',nearest.player.UserId)
	else
		guard.model:SetAttribute('ChasePlayerUserId',nil)
		if Vector3.new(guard.waypoint.X - position.X, 0, guard.waypoint.Z - position.Z).Magnitude <= Config.GuardWaypointReach then
			guard.waypoint = pointIn(zone,guard.margin)
		end
		destination, speed = guard.waypoint, Config.GuardChaseSpeed[stage] * Config.GuardPatrolSpeedFactor
	end

	local delta = Vector3.new(destination.X - position.X, 0, destination.Z - position.Z)
	if delta.Magnitude < 0.01 then MonsterFactory.Pose(guard.view,guard.model.PrimaryPart,false,now) return end
	local nextPosition = clampToZone(position + delta.Unit * math.min(speed * dt, delta.Magnitude), zone,guard.margin)
	guard.model:PivotTo(CFrame.lookAt(nextPosition, nextPosition + delta.Unit))
 MonsterFactory.Pose(guard.view,guard.model.PrimaryPart,true,now)
end

local function step(dt: number)
	local now = os.clock()
	local targets = livingTargets()
	for stage in pairs(active) do
		for _, guard in ipairs(guards[stage]) do
			updateGuard(guard, targets, dt, now)
		end
	end
end

local function distanceToZone(position: Vector3, zone: Part): number
	local offset = position - zone.Position
	local dx = math.max(math.abs(offset.X) - zone.Size.X / 2, 0)
	local dz = math.max(math.abs(offset.Z) - zone.Size.Z / 2, 0)
	return math.sqrt(dx * dx + dz * dz)
end

--- Work out which stages have a player nearby; only those are simulated.
local function refreshActive()
	table.clear(active)
	local targets=livingTargets()
	for _, target in ipairs(targets) do
		for stage, zone in pairs(zones) do
			if distanceToZone(target.root.Position, zone) <= Config.GuardActivationDistance then
				active[stage] = true
			end
		end
	end
	for _,list in guards do for _,guard in list do
  local near=false
  for _,target in targets do if (target.root.Position-guard.model.PrimaryPart.Position).Magnitude<=Config.MonsterGuards.EffectsDistance then near=true break end end
  MonsterFactory.SetEffects(guard.view,near)
  local enabled=active[guard.stage]==true
  if guard.model:GetAttribute('Active')~=enabled then
   if not enabled then MonsterFactory.Pose(guard.view,guard.model.PrimaryPart,false,os.clock()) end
   guard.model:SetAttribute('Active',enabled)
  end
  if not enabled then guard.model:SetAttribute('ChasePlayerUserId',nil) end
 end end
 local anyActive = next(active) ~= nil
	if anyActive and not heartbeat then
		heartbeat = RunService.Heartbeat:Connect(step)
	elseif not anyActive and heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
end

function GuardService.Init(cardService)
	CardService = cardService
	for _, floor in ipairs(CollectionService:GetTagged("StageZone")) do
		zones[floor:GetAttribute("Stage")] = floor
	end
	for stage in pairs(zones) do
		guards[stage] = {}
		for index = 1, Config.GuardCountPerStage[stage] do
			createGuard(stage,index)
		end
	end
	Players.PlayerRemoving:Connect(function(player) hitUntil[player] = nil end)
	task.spawn(function()
		while true do
			refreshActive()
			task.wait(Config.GuardActivationCheckSeconds)
		end
	end)
end

return GuardService
