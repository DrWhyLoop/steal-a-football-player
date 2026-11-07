--[[
	CubeService: spawns, damages and respawns cubes.
	- CubeSpawn markers define each stage's quota; positions are randomized safely inside StageZone.
	- Normal stages respawn a broken cube after Config.CubeRespawnSeconds.
	- GOAT event: one extra Stage 12 egg (guaranteed Gold-or-better, tougher) per Config.GoatSpawnIntervalSeconds, with an announcement.
	- Golden Cube: one at a random point of a random stage every Config.GoldenIntervalSeconds.
	- OnBroken(callback(dropTier, position, breaker, lucky, egg)) - runs when the egg breaks; the egg is destroyed Reveal.SwellSeconds later lets other systems react (drops, quests, guards...).
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerData = require(script.Parent.PlayerData)

local CubeService = {}

local cubesFolder = Workspace:WaitForChild("Greybox"):WaitForChild("Cubes")
local rng = Random.new()
local brokenCallbacks = {}
local cubeMarker = {}  -- [cube] = spawn marker (regular cubes; Golden and event eggs have none)
local stageFloors = {} -- [stage] = floor part
local goatCube, goldenCube
local floorParams = RaycastParams.new() floorParams.FilterType = Enum.RaycastFilterType.Include
local revealReservations = {}

function CubeService.OnBroken(callback)
	table.insert(brokenCallbacks, callback)
end

local function announce(text: string)
	Remotes.Announcement:FireAllClients(text)
end

local totalWeight = 0
for _, size in Config.EggSizes do totalWeight += size.Weight end
local function rollSize()
	local roll = rng:NextNumber() * totalWeight
	for _, size in Config.EggSizes do
		roll -= size.Weight
		if roll < 0 then return size end
	end
	return Config.EggSizeById.Normal
end

local function addGlow(cube: BasePart, color: Color3)
	local glow = Instance.new("Highlight") glow.FillColor = color glow.OutlineColor = color
	glow.FillTransparency = 0.6 glow.DepthMode = Enum.HighlightDepthMode.Occluded glow.Parent = cube
	local sparkle = Instance.new("ParticleEmitter") sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds" sparkle.Rate = Config.Eggs.ParticleRate
	sparkle.Lifetime = NumberRange.new(.8, 1.4) sparkle.Speed = NumberRange.new(1, 3) sparkle.SpreadAngle = Vector2.new(180, 180) sparkle.LightEmission = 1
	sparkle.Color = ColorSequence.new(color) sparkle.Parent = cube
end

-- Egg kinds: normal (size rolled, small chance of Secret), Golden (one tier up), the timed GOAT event egg (always Huge), Secret
-- (one tier up) and the global Titanic. The event, Secret and Titanic eggs promise a Gold-or-better variant (MinVariant).
local function makeCube(stage: number, position: Vector3, golden: boolean, event: boolean?, titanic: boolean?): BasePart
	local tier = Config.StageTier[stage]
	local secret = not golden and not event and rng:NextNumber() < Config.SecretEgg.Chance
	local size = titanic and Config.EggSizeById.Titanic or golden and Config.EggSizeById.Normal or event and Config.EggSizeById.Huge or secret and Config.EggSizeById.Secret or rollSize()
	local hp = Config.CubeHP[stage] * size.HP * (golden and Config.GoldenHPMultiplier or 1)

	local eggName = golden and Config.Eggs.Golden or Config.Eggs.ByTier[tier]
 local template = game:GetService("ServerStorage").EggTemplates:FindFirstChild(eggName)
 assert(template and template:IsA("MeshPart"), "Missing egg template: " .. eggName)
 local cube = template:Clone()
	cube.Name = (golden and "GoldenCube_Stage" or "Cube_Stage") .. stage
	local scale = Config.CubeSize / cube.Size.Y * size.Scale
	cube.Size *= scale
	cube.Anchored = true
	cube.CanCollide, cube.CanTouch, cube.CanQuery = true, false, true
 cube.CastShadow = false
 local color = cube.Color
 cube:SetAttribute("EggDesign", eggName)
 for _,effect in cube:GetDescendants() do
  if effect:IsA("Attachment") then
   effect.Position *= scale
  elseif effect:IsA("ParticleEmitter") then
   effect.Enabled = golden or tier == "GOAT"
   effect.Rate = math.min(effect.Rate, Config.Eggs.ParticleRate)
  end
 end
	-- stand the egg on the real floor below the point, by its actual (scaled) size
	local floor = stageFloors[stage]
	local hit = workspace:Raycast(position + Vector3.new(0, Config.EggSpawning.RayUp, 0), Vector3.new(0, -Config.EggSpawning.RayDown, 0), floorParams)
	local ground = hit and hit.Position.Y or floor.Position.Y + floor.Size.Y / 2
	cube.CFrame = CFrame.new(position.X, ground + cube.Size.Y / 2, position.Z)
	cube:SetAttribute("Stage", stage)
	cube:SetAttribute("Event", event)
	cube:SetAttribute("Size", size.Id)
	cube:SetAttribute("Golden", golden or nil)
	cube:SetAttribute("MinVariant", event and Config.GoatEvent.MinVariant or titanic and Config.Titanic.MinVariant or secret and Config.SecretEgg.MinVariant or nil)
	cube:SetAttribute("MaxHP", hp)
	cube:SetAttribute("HP", hp)
	cube:SetAttribute("BaseColor", color)
	cube:SetAttribute("DropTier", titanic and Config.Titanic.Tier or golden and Config.GetGoldenTier(stage) or secret and Config.GetTierAbove(stage, "GOAT") or tier)
 local lucky = not golden and not secret and not titanic and stage ~= Config.GoatStage and rng:NextNumber() < Config.LuckyEgg.Chance
 if titanic then
  addGlow(cube, Config.Titanic.Color)
 elseif lucky then
  cube:SetAttribute("Lucky", true)
  addGlow(cube, Config.LuckyEgg.Color)
 elseif secret then
  addGlow(cube, Config.SecretEgg.Color)
 end
	CollectionService:AddTag(cube, "Cube")

	cube.Parent = cubesFolder
	return cube
end

local function isClear(position: Vector3): boolean
 local cfg=Config.EggSpawning
 local function near(other,radius)
  local d=other-position
  return Vector2.new(d.X,d.Z).Magnitude<radius
 end
 for _,egg in CollectionService:GetTagged("Cube") do
  if egg.Parent and near(egg.Position,cfg.Clearance) then return false end
 end
 for _,card in CollectionService:GetTagged("Card") do
  if card.Parent and card:GetAttribute("State")=="World" and near(card.Position,cfg.Clearance) then return false end
 end
 for _,player in game.Players:GetPlayers() do
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if root and near(root.Position,cfg.AvatarClearance) then return false end
 end
 for i=#revealReservations,1,-1 do
  local reservation=revealReservations[i]
  if os.clock()>reservation.untilTime then table.remove(revealReservations,i)
  elseif near(reservation.position,cfg.Clearance) then return false end
 end
 return true
end
local function randomPointOn(floor: BasePart): Vector3?
 local reach=floor.Size/2-Vector3.new(Config.EggSpawning.EdgeMargin,0,Config.EggSpawning.EdgeMargin)
 for _=1,Config.EggSpawning.Attempts do
  local localPoint=Vector3.new(rng:NextNumber(-reach.X,reach.X),(floor.Size.Y+Config.CubeSize)/2,rng:NextNumber(-reach.Z,reach.Z))
  local point=floor.CFrame*localPoint
  if isClear(point) then return point end
 end
 return nil
end
local function spawnAt(marker: BasePart): BasePart?
 local stage=marker:GetAttribute("Stage")
 local point=randomPointOn(stageFloors[stage])
 if not point then return nil end
 local cube=makeCube(stage,point,false)
 cubeMarker[cube]=marker
 return cube
end
local function spawnWhenClear(marker)
 while marker.Parent do
  local cube=spawnAt(marker)
  if cube then return cube end
  task.wait(Config.EggSpawning.RetrySeconds)
 end
 return nil
end

local function flash(cube: BasePart)
	cube.Color = Config.Eggs.HitTint
	task.delay(Config.CubeFlashSeconds, function()
		if cube.Parent then
			TweenService:Create(cube, TweenInfo.new(Config.CubeFlashSeconds), { Color = cube:GetAttribute("BaseColor") }):Play()
		end
	end)
end

local function onBroken(cube: BasePart, breaker: Player?)
	local marker = cubeMarker[cube]
	local dropTier, position = cube:GetAttribute("DropTier"), cube.Position
	cubeMarker[cube] = nil
 table.insert(revealReservations,{position=position,untilTime=os.clock()+Config.Reveal.SwellSeconds+Config.Reveal.RiseSeconds+Config.EggSpawning.RetrySeconds})
		cube.CanCollide=false
 cube.CanQuery=false
 -- The egg stays still: DropFromCube tells nearby clients to animate it locally. Result and card spawn happen with the destroy.
 for _, callback in ipairs(brokenCallbacks) do
  task.spawn(callback, dropTier, position, breaker, cube:GetAttribute("Lucky"), cube)
 end
 task.wait(Config.Reveal.SwellSeconds)
 cube:Destroy()
	if marker then
		task.delay(Config.CubeRespawnSeconds, function()
			if marker.Parent then spawnWhenClear(marker) end
		end)
	end
end

--- Apply server-validated damage to a cube.
function CubeService.Damage(cube: BasePart, amount: number, breaker: Player?)
	if not cube.Parent or cube:GetAttribute("Dead") then return end
	local profile = breaker and PlayerData.Get(breaker)
	if profile and cube:GetAttribute("Stage") == 1 and profile.data.Hatched < Config.Onboarding.Eggs then
		amount = math.max(amount, math.ceil(cube:GetAttribute("MaxHP") / Config.Onboarding.Hits)) -- onboarding: the first eggs break fast
	end
	local hp = cube:GetAttribute("HP") - amount
	if hp <= 0 then
		cube:SetAttribute("Dead", true)
		if profile then profile.data.Hatched = math.min(Config.PlayerData.MaxCounter, profile.data.Hatched + 1) end
		onBroken(cube, breaker)
	else
		cube:SetAttribute("HP", hp)
		flash(cube)
	end
end

local function goatLoop()
	while true do
		if not (goatCube and goatCube.Parent) then
			local point = randomPointOn(stageFloors[Config.GoatStage])
			if point then goatCube = makeCube(Config.GoatStage, point, false, true) announce(Config.GoatAnnouncement) end
		end
		task.wait(Config.GoatSpawnIntervalSeconds)
	end
end

-- Global Titanic: the slot number comes from os.time(), so every server spawns it at the same moment, in the same stage.
local function titanicStage(slot: number): number
	local T = Config.Titanic
	local total = 0
	for stage = 1, #Config.CubeHP do total += 1 + T.StageBias * (stage - 1) end
	local roll = Random.new(slot):NextNumber() * total
	for stage = 1, #Config.CubeHP do
		roll -= 1 + T.StageBias * (stage - 1)
		if roll < 0 then return stage end
	end
	return #Config.CubeHP
end
local function titanicLoop()
	local T = Config.Titanic
	local lastSlot
	while true do
		local now = os.time()
		local slot = now // T.IntervalSeconds
		local into = now - slot * T.IntervalSeconds
		if slot ~= lastSlot and into < T.LifetimeSeconds then
			local stage = titanicStage(slot)
			local point = randomPointOn(stageFloors[stage])
			if point then
				lastSlot = slot
				local egg = makeCube(stage, point, false, false, true)
				announce(T.Announcement:format(stage))
				task.delay(T.LifetimeSeconds - into, function() if egg.Parent and not egg:GetAttribute("Dead") then egg:Destroy() end end)
			end
		end
		task.wait(1)
	end
end

local function goldenLoop()
	task.wait(Config.GoldenInitialDelaySeconds)
	while true do
		if not (goldenCube and goldenCube.Parent) then
			local stage = rng:NextInteger(Config.GoldenMinStage, Config.GoldenMaxStage)
			local point=randomPointOn(stageFloors[stage])
   if point then goldenCube=makeCube(stage,point,true) announce(Config.GoldenAnnouncement:format(stage)) end
		end
		task.wait(Config.GoldenIntervalSeconds)
	end
end

function CubeService.Init()
	local floors = {}
	for _, floor in ipairs(CollectionService:GetTagged("StageZone")) do
		stageFloors[floor:GetAttribute("Stage")] = floor
		table.insert(floors, floor)
	end
	floorParams.FilterDescendantsInstances = floors
	for _, marker in ipairs(CollectionService:GetTagged("CubeSpawn")) do
		task.spawn(spawnWhenClear,marker)
	end
	task.spawn(goatLoop)
	task.spawn(titanicLoop)
	task.spawn(goldenLoop)
end

return CubeService
