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
local Format = require(ReplicatedStorage.Shared.NumberFormat)
local PlayerData = require(script.Parent.PlayerData)

local CubeService = {}

local cubesFolder = Workspace:WaitForChild("Greybox"):WaitForChild("Cubes")
local rng = Random.new()
local brokenCallbacks = {}
local cubeMarker = {}  -- [cube] = spawn marker (regular cubes; Golden and event eggs have none)
local stageFloors = {} -- [stage] = floor part
local goatCube, goldenCube
local revealReservations = {}

function CubeService.OnBroken(callback)
	table.insert(brokenCallbacks, callback)
end

local function announce(text: string)
	Remotes.Announcement:FireAllClients(text)
end

local function updateLabel(cube: BasePart)
	local hp, maxHp = cube:GetAttribute("HP"), cube:GetAttribute("MaxHP")
	local size = Config.EggSizeById[cube:GetAttribute("Size")]
	local tags = (cube:GetAttribute("Lucky") and Config.LuckyEgg.Label .. "  " or "") .. (size.Label and size.Label .. "  " or "")
	local gui = cube.HpGui
	gui.HpLabel.Text = ("%sHP %s / %s"):format(tags, Format.Compact(hp), Format.Compact(maxHp))
	local fraction = math.clamp(hp / maxHp, 0, 1)
	gui.Bar.Fill.Size = UDim2.fromScale(fraction, 1)
	gui.Bar.Fill.BackgroundColor3 = Color3.fromHSV(fraction * 0.33, 0.85, 1) -- green at full health, red when nearly broken
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

-- Egg kinds: normal (size rolled, small chance of Secret), Golden (one tier up), the timed GOAT event egg (always Huge) and Secret
-- (one tier up). The event and Secret eggs promise a Gold-or-better variant (MinVariant).
local function makeCube(stage: number, position: Vector3, golden: boolean, event: boolean?): BasePart
	local tier = Config.StageTier[stage]
	local secret = not golden and not event and rng:NextNumber() < Config.SecretEgg.Chance
	local size = golden and Config.EggSizeById.Normal or event and Config.EggSizeById.Huge or secret and Config.EggSizeById.Secret or rollSize()
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
	cube.CFrame = CFrame.new(position)
	cube:SetAttribute("Stage", stage)
	cube:SetAttribute("Event", event)
	cube:SetAttribute("Size", size.Id)
	cube:SetAttribute("MinVariant", event and Config.GoatEvent.MinVariant or secret and Config.SecretEgg.MinVariant or nil)
	cube:SetAttribute("MaxHP", hp)
	cube:SetAttribute("HP", hp)
	cube:SetAttribute("BaseColor", color)
	cube:SetAttribute("DropTier", golden and Config.GetGoldenTier(stage) or secret and Config.GetTierAbove(stage, "GOAT") or tier)
 local lucky = not golden and not secret and stage ~= Config.GoatStage and rng:NextNumber() < Config.LuckyEgg.Chance
 if lucky then
  cube:SetAttribute("Lucky", true)
  addGlow(cube, Config.LuckyEgg.Color)
 elseif secret then
  addGlow(cube, Config.SecretEgg.Color)
 end
	CollectionService:AddTag(cube, "Cube")

	local gui = Instance.new("BillboardGui")
	gui.Name = "HpGui"
	gui.Size = UDim2.fromOffset(170, 54)
	gui.StudsOffset = Vector3.new(0, Config.CubeSize * size.Scale / 2 + 1.8, 0)
	gui.MaxDistance = 90
	gui.Parent = cube
	local text = Instance.new("TextLabel")
	text.Name = "HpLabel"
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 0.55)
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.TextColor3 = golden and Config.GoldenColor or lucky and Config.LuckyEgg.Color or secret and Config.SecretEgg.Color or Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.2
	text.Parent = gui
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Position = UDim2.fromScale(0, 0.62)
	bar.Size = UDim2.fromScale(1, 0.3)
	bar.BackgroundColor3 = Color3.new(0, 0, 0)
	bar.BackgroundTransparency = 0.35
	bar.Parent = gui
	local barCorner = Instance.new("UICorner") barCorner.CornerRadius = UDim.new(0.5, 0) barCorner.Parent = bar
	local barEdge = Instance.new("UIStroke") barEdge.Color = Color3.new(1, 1, 1) barEdge.Thickness = 1.5 barEdge.Parent = bar
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BorderSizePixel = 0
	fill.Parent = bar
	local fillCorner = Instance.new("UICorner") fillCorner.CornerRadius = UDim.new(0.5, 0) fillCorner.Parent = fill

	updateLabel(cube)
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
 cube.HpGui.Enabled=false
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
		updateLabel(cube)
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
	for _, floor in ipairs(CollectionService:GetTagged("StageZone")) do
		stageFloors[floor:GetAttribute("Stage")] = floor
	end
	for _, marker in ipairs(CollectionService:GetTagged("CubeSpawn")) do
		task.spawn(spawnWhenClear,marker)
	end
	task.spawn(goatLoop)
	task.spawn(goldenLoop)
end

return CubeService
