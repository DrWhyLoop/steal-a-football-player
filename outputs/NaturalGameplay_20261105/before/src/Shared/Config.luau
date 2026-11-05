--[[
	Config: ALL gameplay tuning lives here. Shared by server and client.
	Change numbers here, not in services.
]]

local Config = {}

-- Hallway dimensions; stage lengths progress towards the final arena.
Config.StageCount = 12
Config.StageLengths = { 3100/7, 3100/7, 3100/7, 3100/7, 3100/7, 3100/7, 3100/7, 3100/7, 3875/7, 3875/7, 4650/7, 6200/7 }
Config.EntranceApronDepth = 6
Config.HallwayWidth = 192
Config.SlotsPerPlot = 30
Config.PlotAccess = { LadderWidth=2, LadderDepth=2, TopExtension=1.25, OutwardOffset=2, LandingDepth=7, LandingWidth=7.8, ExitDistance=10, Version=2 }
Config.GroundY = 1 -- top surface of all floors

-- Tiers ---------------------------------------------------------------
Config.BaseWalkSpeed = 16
Config.Hurt = {Duration=.85,BlendSeconds=.15}

Config.TierOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic", "GOAT" }

Config.Tiers = {
	Common    = { CashPerSecond = 1,    WalkSpeed = 16, Color = Color3.fromRGB(163, 162, 165) },
	Rare      = { CashPerSecond = 5,    WalkSpeed = 15, Color = Color3.fromRGB(60, 120, 255) },
	Epic      = { CashPerSecond = 25,   WalkSpeed = 14, Color = Color3.fromRGB(170, 60, 255) },
	Legendary = { CashPerSecond = 100,  WalkSpeed = 13, Color = Color3.fromRGB(255, 150, 30) },
	Mythic    = { CashPerSecond = 500,  WalkSpeed = 12, Color = Color3.fromRGB(255, 50, 120) },
	GOAT      = { CashPerSecond = 2500, WalkSpeed = 11, Color = Color3.fromRGB(255, 215, 0) },
}

-- Tier dropped by each stage (index = stage number)
Config.StageTier = {
	"Common", "Common",
	"Rare", "Rare",
	"Epic", "Epic", "Epic",
	"Legendary", "Legendary",
	"Mythic", "Mythic",
	"GOAT",
}

-- Fictional names and fixed stage-tier pools; weights are relative, not percentages.
Config.PlayerRoster = {
 {Id="Player_14",Name="Slate Striker",Tier="Common",Weight=60},
 {Id="Player_05",Name="Cedar Pass",Tier="Common",Weight=40},
 {Id="Player_12",Name="Arrow Vale",Tier="Rare",Weight=60},
 {Id="Player_06",Name="Turn Maestro",Tier="Rare",Weight=40},
 {Id="Player_04",Name="Frost Cannon",Tier="Epic",Weight=50},
 {Id="Player_08",Name="Prism Dancer",Tier="Epic",Weight=30},
 {Id="Player_07",Name="Comet Dash",Tier="Epic",Weight=20},
 {Id="Player_13",Name="Zenith Captain",Tier="Legendary",Weight=60},
 {Id="Player_10",Name="Samba Spark",Tier="Legendary",Weight=40},
 {Id="Player_11",Name="Meteor Striker",Tier="Mythic",Weight=60},
 {Id="Player_03",Name="Golden Orbit",Tier="Mythic",Weight=40},
 {Id="Player_09",Name="Crown King",Tier="GOAT",Weight=50},
 {Id="Player_02",Name="Crimson Ace",Tier="GOAT",Weight=30},
 {Id="Player_01",Name="Pocket Wizard",Tier="GOAT",Weight=20},
}
Config.Reveal = { EggShakeSeconds=.65, EggShakeAngle=.12, EggShakeCycles=4, PopSeconds=.3, SparkCount=12, SwellSeconds=0.22, SwellScale=1.16, ShuffleSeconds=2.1,
 DisplayHeight=5, SafeCelebrationSeconds=1.4, SafeCheckSeconds=0.2, SafeMargin=2,
 MaxDistance=100, MaxConcurrent=3, SafeColor=Color3.fromRGB(100,255,165) }

-- Egg visuals use the existing cube mining/reward system.
Config.Eggs = {
 ByTier = { Common = "Classic Cream", Rare = "Lavender Tiles", Epic = "Treasure Chest", Legendary = "Diamond Plated", Mythic = "Obsidian Fortune", GOAT = "Royal Crown" },
 Golden = "Solid Gold", Reserved = { "Aurora Prism", "Starlight" },
 ParticleRate = 2, HitTint = Color3.fromRGB(255, 190, 190),
}

-- Cubes ---------------------------------------------------------------
Config.EggSpawning = { Attempts=40, EdgeMargin=12, Clearance=12, AvatarClearance=10, RetrySeconds=1 }
Config.CubeSize = 6
Config.CubeSpawnMarkerTransparency = 1
Config.CubeRespawnSeconds = 15
Config.CubeFlashSeconds = 0.08
Config.CubeHP = { 3, 5, 8, 12, 18, 25, 35, 50, 70, 100, 140, 300 }       -- per stage
Config.CubeCountPerStage = { 6, 6, 7, 7, 8, 8, 9, 10, 10, 11, 12, 1 }    -- per stage
Config.CubeColumnX = { -72, 72, -40, 40 } -- spawn columns (fill order); centre lane stays free

-- GOAT event cube: the only source of GOAT cards. One cube per interval + announcement.
Config.GoatStage = 12
Config.GoatSpawnIntervalSeconds = 120 -- TESTING VALUE. Set to 1200 (20 minutes) for live.
Config.GoatAnnouncement = "A GOAT EGG has appeared in STAGE 12!"

-- Golden Cube event: one at a random point of a random stage in [Min, Max]
Config.GoldenIntervalSeconds = 300
Config.GoldenInitialDelaySeconds = 300
Config.GoldenMinStage = 4
Config.GoldenMaxStage = 11
Config.GoldenHPMultiplier = 3
Config.GoldenMaxTier = "Mythic" -- drops one tier above the stage, capped here
Config.GoldenColor = Color3.fromRGB(255, 200, 0)
Config.GoldenAnnouncement = "A GOLDEN EGG appeared in STAGE %d!"

Config.AnnouncementSeconds = 6

-- Pickaxe -------------------------------------------------------------
Config.PickaxeName = "Default Axe"       -- Tool in StarterPack
Config.PickaxeDamage = 1             -- fixed damage per hit
Config.SwingCooldown = 0.7          -- seconds between hits (server enforced)
Config.PickaxeRange = 12             -- max studs from player root to cube centre
Config.PickaxeCloseRange = 6         -- cubes this close always count, even if not facing
Config.PickaxeFacingDot = 0.3        -- min dot(look, toTarget) for "in front" (1 = dead ahead)
Config.PickaxeSounds = {             -- placeholder built-in clips
	Hit = "rbxasset://sounds/metal.mp3",
	Miss = "rbxasset://sounds/swordslash.wav",
}

-- Axe skins are prepared for progression; only Default is currently unlocked.
Config.Axes = {
 SwingDuration = 0.7, StrikeEnd = 0.46, ImpactTime = 0.43,
 RunSpeedReference = 16, RunMinimumSpeed = 0.5, AnimationDistance = 120,
 RunKneeBend = 0.8, RunElbowBend = 0.7, StrikeElbowBend = 0.6,
 Catalog = { "Default", "Good", "Golden", "Pickaxe", "SteelPickaxe", "Godly", "Volcanic" },
 TemplateHeight = 3.8,
 Default = "Default", Locked = {Good=true,Golden=true,Pickaxe=true,SteelPickaxe=true,Godly=true,Volcanic=true},
}

-- Cards ---------------------------------------------------------------
Config.CardSize = Vector3.new(3, 5, 2)
Config.CardRestHeight = 0.6          -- gap between dropped card and floor
Config.CarryOffset = Vector3.new(0, 3.2, 0) -- above the Head
Config.PickupHoldSeconds = 0.3
Config.PickupPromptDistance = 8
Config.PickupMaxDistance = 20        -- server-side sanity check
Config.InteractMaxDistance = 25      -- server-side sanity check (slots, lock button)
Config.DroppedCardLifetime = 30      -- cards dropped by death/leave despawn after this
Config.CubeDropLifetime = 0          -- cards from broken cubes; 0 = never despawn
Config.CarryTrackSeconds = 0.5
Config.FallbackDropPosition = Vector3.new(0, 5, -60)

-- Stealing ------------------------------------------------------------
Config.ReservationLabelSize = Vector2.new(170, 36)
Config.ReservationLabelOffset = Vector3.new(0, 3, 0)
Config.ReservationLabelMaxDistance = 70
Config.StealHoldSeconds = 1.5
Config.StealAlert = "%s is stealing your %s!" -- (thief name, card name)

-- Base lock -----------------------------------------------------------
Config.LockDurationSeconds = 60
Config.LockCooldownSeconds = 30      -- starts when the lock expires
Config.LockTickSeconds = 1
Config.LockBarrierHeight = 36
Config.LockBarrierTransparency = 0.5
Config.LockBarrierColor = Color3.fromRGB(80, 170, 255)
Config.LockExpelInset = 10            -- trespassers are moved this far inside the forecourt

-- Guards (per stage, index = stage number) -------------------------------
Config.GuardCountPerStage = { 1, 1, 2, 2, 2, 3, 3, 3, 3, 3, 3, 2 }
Config.GuardChaseSpeed    = { 8, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 15 }
Config.GuardChaseRange    = { 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 24 }
Config.GuardPatrolSpeedFactor = 0.5   -- patrol speed = chase speed * factor
Config.GuardSize = Vector3.new(3, 6, 2)
Config.GuardHeadSize = 2
Config.GuardColor = Color3.fromRGB(200, 40, 40)
Config.GuardHitRadius = 4.5           -- distance from guard centre that counts as a touch
Config.GuardHitCooldownSeconds = 1.5  -- per-player immunity after a hit
Config.GuardStunSeconds = 1           -- guard pauses after hitting
Config.GuardKnockbackSpeed = 55
Config.GuardKnockbackUp = 25
Config.KnockbackStunSeconds = 0.4     -- hit client is ragdolled this long so the impulse is not cancelled by the Humanoid
Config.GuardZoneMargin = 4            -- guards stay this far from the hallway walls
Config.GuardWaypointReach = 2
Config.GuardActivationDistance = 60   -- guards only update when a player is this close to their stage
Config.GuardActivationCheckSeconds = 0.5

-- Boss construction and preview (guard integration is a separate approval).
Config.BossMaxParts = 59
Config.BossMaxParticleRate = 12
Config.BossLightRange = 10
Config.BossLightBrightness = 1.3
Config.BossPreviewOrigin = Vector3.new(1000, 2, 1000)
Config.BossPreviewSpacing = 10
Config.BossPreviewLabelSize = Vector2.new(9, 2)

-- Static environment placement; asset samples live in ServerStorage.EnvironmentSourceAssets.
Config.Environment = {
 FenceHeight = 3, FenceDepth = 0.35, FenceGateWidth = 9, FenceOutsideOffset = 0.4,
 GrassColumns = 3, GrassRowsPerHalf = 2, GrassHeight = 0.7, LabelClearLength = 18,
 GrassOverlap = 1.04, GrassColor = Color3.fromRGB(65, 106, 48),
 WallHeight = 32, WallDepth = 7, WallOutsideOffset = 0.2,
 StageSignSize = Vector3.new(0.25, 4, 18), StageSignHeight = 10,
 StageSignColor = Color3.fromRGB(30, 47, 30),
 PlotInset = 0.5, PlotSignSize = Vector3.new(0.2, 2, 29), PlotSignHeight = 6,
 PlotLockOffset = 13, SlotThickness = 0.18,
 WillowScale = 0.8, WillowStageInterval = 3, TreeOutsideOffset = 22,
 BambooScale = 0.42, BushScale = 0.27, BushLeafScale = 0.28,
 EdgeInset = 5, TuftsPerStage = 8, TuftScale = 0.6, PlazaTreeOutsideOffset = 60,
 MaxGrassPartsPerStage = 150, MaxPlotVisualParts = 550,
 VegetationViewDistance = 240, VegetationFadeDistance = 60, VisibilityUpdateSeconds = 0.5,
 Seed = 61103,
}

-- Broad ground coverage and client-local scenery budgets.
Config.Landscape = {
 GroundCenter = Vector3.new(0, -8, 2324), GroundSize = Vector3.new(2048, 16, 6696),
 CellSize = 64, ViewRadius = 210, UpdateSeconds = 0.75,
 GrassCellSize = 48, GrassRadius = 110, GrassHeight = 0.7,
 Seed = 71103, ClearMargin = 18, BorderSegmentLength = 256,
 BorderHeight = 24, BorderDepth = 8, GroundDepth = 8,
 BorderBackingDepth = 4, BorderCornerOverlap = 8, BorderBackingGroundOverlap = 1, BorderBackingSegmentLength = 1024,
 PalmScale = 1.1, PlantScale = 1, BushScale = 0.7,
 TorchScale = 0.75, TorchMountInset = 2, TorchFloorSpacing = 10,
 TorchMountHeight = 4, TorchStagesPerSide = 2,
 TorchEffectDistance = 85, TorchLightDistance = 65,
 MaxTorchEffects = 8, MaxTorchLights = 6, TorchLightRange = 18,
 TorchLightBrightness = 1.6, TorchFireRate = 4, TorchGlowRate = 1,
 TorchSmokeRate = 0.5,
}
Config.Weather = {
 DaySeconds = 1200, StartHour = 9, UpdateSeconds = 1, TransitionSeconds = 4,
 RainStartHour = 13, RainEndHour = 15, RainChance = 0.6, DayStartHour = 6, EveningHour = 16, NightHour = 18,
 RainRate = 350, RainSpeed = 75, RainLifetime = 0.6, RainSize = 3, RainTransparency = 0.4,
 RainHeight = 32, RainArea = 52, RoofProbeHeight = 40,
 RainTexture = "rbxassetid://3806148993",
 Presets = {
  Sunny = {Sky = "Sunny sky", Brightness = 2.4, Ambient = Color3.fromRGB(115,125,135), OutdoorAmbient = Color3.fromRGB(145,150,145), Density = 0.23, Haze = 1, Color = Color3.fromRGB(205,225,245)},
  Rain = {Sky = "Rain sky", Brightness = 1.3, Ambient = Color3.fromRGB(100,110,125), OutdoorAmbient = Color3.fromRGB(110,125,140), Density = 0.38, Haze = 2, Color = Color3.fromRGB(160,180,200)},
  Evening = {Sky = "Autumn glow sky evening", Brightness = 1.8, Ambient = Color3.fromRGB(125,95,100), OutdoorAmbient = Color3.fromRGB(155,120,100), Density = 0.28, Haze = 1.7, Color = Color3.fromRGB(245,195,155)},
  Night = {Sky = "Night sky", Brightness = 1.5, Ambient = Color3.fromRGB(90,100,125), OutdoorAmbient = Color3.fromRGB(100,110,140), Density = 0.28, Haze = 1, Color = Color3.fromRGB(150,170,210)},
 },
}

Config.CharacterPreview = { BodyHeight = 6.5, SlimWidthMultiplier = 1.4, SlimDepthMultiplier = 1.2, KitShellScale = 1.025, Origin = Vector3.new(350, 4, -710), Spacing = 7, PlatformSize = Vector3.new(40, 3.5, 14), LabelSize = Vector3.new(6, 1.2, 0.15) }

-- Display slots and server-validated character upgrades.
Config.PlotSlots = {
 SlotsPerFloor = 10, EmptyText = "Now a player", PanelSize = Vector3.new(0.9, 0.12, 2.6),
 DisplayClearance = 0.1, UpgradeOffset = 0.35, PromptDistance = 5, InteractDistance = 8,
 UpgradeKey = Enum.KeyCode.R, UpgradeCooldown = 0.4,
 IncomeGrowth = 1.25, CostGrowth = 1.6, FirstCostSeconds = 60, MaxLevel = 20,
}
Config.MonsterGuards = {
 EffectsDistance = 80, ParticleRate = 2,
 LightBrightness = 1, LightRange = 6,
 BodyGlowDesigns = { Noob=true, BigGuy=true }, BodyGlowTransparency = 0.88,
 BodyGlowColor = Color3.fromRGB(255,235,170), WalkBob = 0.1, WalkFrequency = 7,
 Stages = {
  { "Noob" }, { "Monster" }, { "Teddy" }, { "Realistic" }, { "RiggedNew" },
  { "RiggedNew" }, { "Backrooms" }, { "Paranormica" }, { "Backrooms" }, { "Teddy" },
  { "White" }, { "LongArm", "Soul" },
 },
 Animations = { LongArm="LongArmRun", White="WhiteRun", Backrooms="BackroomsRun", Jessie="JessieRun" },
 BoneAliases = {
 Realistic = {["upper_arm.L"]="Left Arm",["upper_arm.R"]="Right Arm",["thigh.L"]="Left Leg",["thigh.R"]="Right Leg",["spine.002"]="Torso"},
 },
 Heights = { Realistic=10,RiggedNew=11,Gaben=12,Backrooms=13,Paranormica=14,Jessie=15,White=16,LongArm=17,Soul=18,Fantasy=16, Noob=6, Monster=7, Teddy=9 },
}
-- Training points are distinct from studs/second. All 15 levels share one owned pad.
Config.Treadmills = {
 BaseGain=2, TickSeconds=1, InteractionDistance=12, RequestCooldown=.5,
 TrainingRadius=9, TrainingStandHeight=4.2, MovementBase=16, PointsPerScale=100, MovementPerLog=12, MaxWalkSpeed=120,
 TemplateSize=Vector3.new(9,7,13), PlotOffset=24.5, GroundY=1.1,
 ParticleRate=2, EffectsDistance=65, LabelDistance=12, MaxLights=1,
 Catalog={
  {Id="Base",Name="Starter",Multiplier=1.5,Cost=0,Template="TreadmillBasic"},
  {Id="Circuit",Name="Circuit",Multiplier=2,Cost=100,Template="x1 Treadmill"},
  {Id="Alloy",Name="Alloy",Multiplier=4,Cost=750,Template="TreadmillPlaytime"},
  {Id="Flame",Name="Flame",Multiplier=6,Cost=5000,Template="x3 Treadmill"},
  {Id="Diamond",Name="Diamond",Multiplier=9,Cost=30000,Template="TreadmillDiamond"},
  {Id="Frost",Name="Frost",Multiplier=12,Cost=180000,Template="x15 Treadmill"},
  {Id="Nova",Name="Nova",Multiplier=15,Cost=1100000,Template="x50 Treadmill"},
  {Id="Solar",Name="Solar",Multiplier=20,Cost=6500000,Template="x100 Treadmill"},
  {Id="Galaxy",Name="Galaxy",Multiplier=25,Cost=40000000,Template="TreadmillGalaxy"},
  {Id="Aurora",Name="Aurora",Multiplier=35,Cost=250000000,Template="x15 Treadmill"},
  {Id="Obsidian",Name="Obsidian",Multiplier=50,Cost=1500000000,Template="x50 Treadmill"},
  {Id="Titan",Name="Titan",Multiplier=75,Cost=9000000000,Template="x100 Treadmill"},
  {Id="Void",Name="Void",Multiplier=100,Cost=55000000000,Template="TreadmillVoid"},
  {Id="Infinity",Name="Infinity",Multiplier=250,Cost=330000000000,Template="TreadmillVoid"},
  {Id="ShadowScott",Name="Shadow Scott",Multiplier=500,Cost=1500000000000,Template="Shadow Scott"},
  {Id="Celestial",Name="Celestial",Multiplier=100000,GamePassId=0,ExpectedRobux=4999,Template="TreadmillCelestial"},
 },
}
Config.PlayerData={Store="FootballerProfiles_v1",ReportStore="FootballerReports_v1",AutosaveSeconds=60,
 LockSeconds=180,Retries=3,RetrySeconds=2,StudioMemoryOnly=true,MaxCash=9000000000000000,MaxSpeedPoints=1e15,
 MaxPurchaseHistory=60,ReportCooldown=60,MaxReportsPerDay=5,MaxInboxRecords=1000,
 FeedbackCategories={"Bug","Lost progress","Controls","Balance","Abuse","Exploiting"}}

-- Economy -------------------------------------------------------------
Config.CashTickSeconds = 1

-- Helpers -------------------------------------------------------------
function Config.GetStageLength(stage: number): number
	return Config.StageLengths[stage]
end

--- Tier of the card a Golden Cube drops for a stage.
function Config.GetGoldenTier(stage: number): string
	local index = table.find(Config.TierOrder, Config.StageTier[stage]) :: number
	local cap = table.find(Config.TierOrder, Config.GoldenMaxTier) :: number
	return Config.TierOrder[math.min(index + 1, cap)]
end



return Config
