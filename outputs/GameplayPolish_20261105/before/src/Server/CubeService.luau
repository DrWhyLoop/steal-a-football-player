--[[
	CubeService: spawns, damages and respawns cubes.
	- Spawn points are parts tagged "CubeSpawn" with attribute Stage (edit them in Studio).
	- Normal stages respawn a broken cube after Config.CubeRespawnSeconds.
	- GOAT stage: one cube per Config.GoatSpawnIntervalSeconds, with an announcement.
	- Golden Cube: one at a random point of a random stage every Config.GoldenIntervalSeconds.
	- OnBroken(callback(dropTier, position, breaker)) lets other systems react (drops, quests, guards...).
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local CubeService = {}

local cubesFolder = Workspace:WaitForChild("Greybox"):WaitForChild("Cubes")
local rng = Random.new()
local brokenCallbacks = {}
local cubeMarker = {}  -- [cube] = spawn marker (regular and GOAT-stage cubes)
local stageFloors = {} -- [stage] = floor part
local goatCube, goldenCube

function CubeService.OnBroken(callback)
	table.insert(brokenCallbacks, callback)
end

local function announce(text: string)
	Remotes.Announcement:FireAllClients(text)
end

local function updateLabel(cube: BasePart)
	local label = cube.HpGui.HpLabel :: TextLabel
	label.Text = ("HP %d / %d"):format(cube:GetAttribute("HP"), cube:GetAttribute("MaxHP"))
end

local function makeCube(stage: number, position: Vector3, golden: boolean): BasePart
	local tier = Config.StageTier[stage]
	local hp = Config.CubeHP[stage] * (golden and Config.GoldenHPMultiplier or 1)

	local eggName = golden and Config.Eggs.Golden or Config.Eggs.ByTier[tier]
 local template = game:GetService("ServerStorage").EggTemplates:FindFirstChild(eggName)
 assert(template and template:IsA("MeshPart"), "Missing egg template: " .. eggName)
 local cube = template:Clone()
	cube.Name = (golden and "GoldenCube_Stage" or "Cube_Stage") .. stage
	local scale = Config.CubeSize / cube.Size.Y
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
	cube:SetAttribute("MaxHP", hp)
	cube:SetAttribute("HP", hp)
	cube:SetAttribute("BaseColor", color)
	cube:SetAttribute("DropTier", golden and Config.GetGoldenTier(stage) or tier)
	CollectionService:AddTag(cube, "Cube")

	local gui = Instance.new("BillboardGui")
	gui.Name = "HpGui"
	gui.Size = UDim2.fromOffset(150, 44)
	gui.StudsOffset = Vector3.new(0, Config.CubeSize / 2 + 1.5, 0)
	gui.MaxDistance = 90
	gui.Parent = cube
	local text = Instance.new("TextLabel")
	text.Name = "HpLabel"
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.TextColor3 = golden and Config.GoldenColor or Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.2
	text.Parent = gui

	updateLabel(cube)
	cube.Parent = cubesFolder
	return cube
end

local function spawnAt(marker: BasePart): BasePart
	local offset = Vector3.new(0, (marker.Size.Y + Config.CubeSize) / 2, 0)
	local cube = makeCube(marker:GetAttribute("Stage"), marker.Position + offset, false)
	cubeMarker[cube] = marker
	return cube
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
	cube.CanCollide=false
 cube.CanQuery=false
 cube.HpGui.Enabled=false
 TweenService:Create(cube,TweenInfo.new(Config.Reveal.SwellSeconds),{Size=cube.Size*Config.Reveal.SwellScale}):Play()
 task.wait(Config.Reveal.SwellSeconds)
 cube:Destroy()

	for _, callback in ipairs(brokenCallbacks) do
		task.spawn(callback, dropTier, position, breaker)
	end
	if marker and marker:GetAttribute("Stage") ~= Config.GoatStage then
		task.delay(Config.CubeRespawnSeconds, function()
			if marker.Parent then spawnAt(marker) end
		end)
	end
end

--- Apply server-validated damage to a cube.
function CubeService.Damage(cube: BasePart, amount: number, breaker: Player?)
	if not cube.Parent or cube:GetAttribute("Dead") then return end
	local hp = cube:GetAttribute("HP") - amount
	if hp <= 0 then
		cube:SetAttribute("Dead", true)
		onBroken(cube, breaker)
	else
		cube:SetAttribute("HP", hp)
		updateLabel(cube)
		flash(cube)
	end
end

local function goatLoop(marker: BasePart)
	while marker.Parent do
		if not (goatCube and goatCube.Parent) then
			goatCube = spawnAt(marker)
			announce(Config.GoatAnnouncement)
		end
		task.wait(Config.GoatSpawnIntervalSeconds)
	end
end

local function isClearOfCubes(position: Vector3): boolean
	for _, other in ipairs(CollectionService:GetTagged("Cube")) do
		if ((other :: Part).Position - position).Magnitude < Config.GoldenMinSpacing then
			return false
		end
	end
	return true
end

local function randomPointOn(floor: Part): Vector3
	local reach = floor.Size / 2 - Vector3.one * Config.GoldenEdgeMargin
	local y = floor.Position.Y + (floor.Size.Y + Config.CubeSize) / 2
	local point
	for _ = 1, Config.GoldenSpawnAttempts do
		point = Vector3.new(
			floor.Position.X + rng:NextNumber(-reach.X, reach.X),
			y,
			floor.Position.Z + rng:NextNumber(-reach.Z, reach.Z)
		)
		if isClearOfCubes(point) then break end
	end
	return point
end

local function goldenLoop()
	task.wait(Config.GoldenInitialDelaySeconds)
	while true do
		if not (goldenCube and goldenCube.Parent) then
			local stage = rng:NextInteger(Config.GoldenMinStage, Config.GoldenMaxStage)
			goldenCube = makeCube(stage, randomPointOn(stageFloors[stage]), true)
			announce(Config.GoldenAnnouncement:format(stage))
		end
		task.wait(Config.GoldenIntervalSeconds)
	end
end

function CubeService.Init()
	for _, floor in ipairs(CollectionService:GetTagged("StageZone")) do
		stageFloors[floor:GetAttribute("Stage")] = floor
	end
	for _, marker in ipairs(CollectionService:GetTagged("CubeSpawn")) do
		if marker:GetAttribute("Stage") == Config.GoatStage then
			task.spawn(goatLoop, marker)
		else
			spawnAt(marker)
		end
	end
	task.spawn(goldenLoop)
end

return CubeService
