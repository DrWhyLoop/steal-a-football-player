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
Config.PlotAccess = {Version=3,Run=14,Width=4,SideOffset=19,BridgeLength=7,RungSpacing=1}
Config.GroundY = 1 -- top surface of all floors

-- Tiers ---------------------------------------------------------------
Config.BaseWalkSpeed = 16
Config.Hurt = {Duration=.85,BlendSeconds=.15}

Config.TierOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic", "GOAT" }

Config.Tiers = {
	Common    = { CashPerSecond = 1,    WalkSpeed = 16, Color = Color3.fromRGB(163, 162, 165) },
	Rare      = { CashPerSecond = 9.3,  WalkSpeed = 15, Color = Color3.fromRGB(60, 120, 255) },
	Epic      = { CashPerSecond = 82,   WalkSpeed = 14, Color = Color3.fromRGB(170, 60, 255) },
	Legendary = { CashPerSecond = 730,  WalkSpeed = 13, Color = Color3.fromRGB(255, 150, 30) },
	Mythic    = { CashPerSecond = 6500,  WalkSpeed = 12, Color = Color3.fromRGB(255, 50, 120) },
	GOAT      = { CashPerSecond = 57700, WalkSpeed = 11, Color = Color3.fromRGB(255, 215, 0) },
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
-- One cage falls apart; its white occupant grows and flashes into the locked server reward.
Config.Reveal = {
 BreakSeconds=.6, GrowthMinSeconds=1.5, GrowthMaxSeconds=2.9,
 GrowthMinScale=1.1, GrowthMaxScale=1.6, FlashSeconds=.25,
 TickStart=2, TickEnd=14,
 TickSoundId="rbxasset://sounds/electronicpingshort.wav", TickVolume=.25,
 CounterHeight=3, CounterColor=Color3.fromRGB(110,255,140),
 RiseSeconds=.35, PopSoundId="rbxasset://sounds/impact_explosion_03.mp3", PopSoundVolume=.5,
 BreakerPrioritySeconds=3, DisplayHeight=5, SafeCelebrationSeconds=1.4,
 SafeCheckSeconds=.2, SafeMargin=2, MaxDistance=100, MaxConcurrent=3,
 SafeColor=Color3.fromRGB(100,255,165),
 DebrisDistance=5,DebrisLift=2,DebrisFall=5,DebrisTurns=1.2,DebrisFadeStart=.45,
 ShellFraction=.65,ShellFragments=10,MaxDebrisParts=96,MaxLightDebrisParts=8,FragmentScale=Vector3.new(.13,.28,.13),
 OccupantDistance=105,MaxIdleOccupants=12,OccupantCheckSeconds=.4,RevealGraceSeconds=1,TransformFadeSeconds=.12,
}
Config.EvolutionVFX = {
 Distance=100,MaxConcurrent=3,Duration=1.05,Height=.25,
 SmokeCount=5,RareSmokeCount=8,RingCount=1,RareScale=1.15,
 SmokeLifetime=NumberRange.new(.45,.75),RingLifetime=NumberRange.new(.5,.65),
 SmokeSize={.35,1.4,2.2},RingSize={.4,3.2,5.6},
 SmokeTransparency={.5,.65,1},RingTransparency={.4,.2,1},
 SmokeSpeed=NumberRange.new(.8,1.6),SmokeRotation=NumberRange.new(0,360),SmokeSpin=NumberRange.new(-30,30),
 SmokeSpread=Vector2.new(150,150),SmokeLift=1,SmokeDrag=2,RingSpeed=.01,
 SmokeEmission=.08,RingEmission=.85,SmokeColor=Color3.fromRGB(225,230,235),RingColor=Color3.fromRGB(255,240,201),VariantBlend=.35,
}
Config.RewardSizes = {
 {Id="Tiny",Scale=.6,Income=.8,Weight=8},
 {Id="Small",Scale=.8,Income=.9,Weight=17},
 {Id="Normal",Scale=1,Income=1,Weight=60},
 {Id="Tall",Scale=1.2,Income=1.12,Weight=8},
 {Id="Large",Scale=1.4,Income=1.28,Weight=4},
 {Id="Huge",Scale=1.6,Income=1.5,Weight=1.6},
 {Id="Giant",Scale=1.9,Income=1.8,Weight=.8},
 {Id="Colossal",Scale=2.2,Income=2.2,Weight=.4},
 {Id="Mega",Scale=2.6,Income=2.7,Weight=.15},
 {Id="Monumental",Scale=3,Income=3.3,Weight=.05},
}
Config.RewardSizeById={}
for _,size in Config.RewardSizes do Config.RewardSizeById[size.Id]=size end
Config.RewardVariantOrder={"Normal","Gold","Diamond","Ruby","Shadow","Emerald","Fire","Lightning","Void","Rainbow"}
Config.Variants = {
 Normal={Income=1,Weight=89,Tint=Color3.new(1,1,1)},
 Gold={Income=1.5,Weight=6,Tint=Color3.fromRGB(255,215,110)},
 Diamond={Income=2,Weight=2,Tint=Color3.fromRGB(180,235,255)},
 Ruby={Income=2.4,Weight=.9,Tint=Color3.fromRGB(255,145,165)},
 Shadow={Income=2.8,Weight=.65,Tint=Color3.fromRGB(170,175,205)},
 Emerald={Income=3.2,Weight=.5,Tint=Color3.fromRGB(145,255,190)},
 Fire={Income=3.8,Weight=.35,Tint=Color3.fromRGB(255,185,115)},
 Lightning={Income=4.5,Weight=.25,Tint=Color3.fromRGB(170,210,255)},
 Void={Income=5.5,Weight=.2,Tint=Color3.fromRGB(210,165,255)},
 Rainbow={Income=7,Weight=.15,Tint=Color3.fromRGB(255,205,240)},
}
Config.RewardRoll={LuckExponent=.2,SoftStart=6,AbsoluteMax=20,TintBlend=.2}
Config.RewardDisplay={SpacingFraction=.85,MinimumRatio=.45,FloorGap=1,SameFloorTolerance=1}
Config.VariantEffects={Near=60,Far=80,MaxVisible=8,Rate=2,RefreshSeconds=.2,FootOffset=.2,RainbowSeconds=6}

-- Luck: every break rolls a luck value L (the counter on screen). A normal cage rolls Min + (Max - Min) * r^Power; a Lucky Cage rolls LuckyMin..LuckyMax.
-- The income roll is u = random()^(1/L) (L = 1 is uniform, more luck pushes towards 1) and the card's income factor is Min + (Max - Min) * u from its
-- IncomeRange (a roster entry may set its own IncomeRange = {Min=, Max=}; otherwise the tier's). Each tier range averages 1.0 at normal luck.
Config.Luck = { Min=1, Max=1.5, Power=2, LuckyMin=3, LuckyMax=4, Step=.1 } -- Step: the counter shows one decimal, so L is rounded to it
Config.IncomeRange = { Common={Min=.79,Max=1.19}, Rare={Min=.73,Max=1.23}, Epic={Min=.68,Max=1.28}, Legendary={Min=.62,Max=1.32}, Mythic={Min=.57,Max=1.37}, GOAT={Min=.46,Max=1.46} }
-- Lucky Egg: occasionally replaces a normal egg (never the GOAT or Golden egg) and boosts the variant odds.
Config.LuckyEgg = { Chance=0.03, Odds={ Gold=0.20, Diamond=0.03, Giant=0.08 }, Color=Color3.fromRGB(80,255,120), Label="LUCKY CAGE",
 OddsDistance=35, LookDot=0.97 }

-- Each numbered cage belongs to exactly one stage. Regular slots use three copies of each.
Config.Cages = {
 ByStage = {
  {8,14,19}, {4,5,26}, {9,13,17}, {3,12,15},
  {2,18,27}, {22,28,35}, {1,16,30}, {21,23,24},
  {6,7,25}, {10,11,34}, {20,32,33}, {29,31,36},
 },
 CopiesPerDesign = 3, MaxNormalWidth = 8,
 ParticleRate = 2, HitTint = Color3.fromRGB(255,190,190),
}

-- Cubes ---------------------------------------------------------------
Config.EggSpawning = { Attempts=40, EdgeMargin=12, Clearance=12, AvatarClearance=10, RetrySeconds=1, RayUp=10, RayDown=40 } -- RayUp/RayDown: the floor probe that stands each egg on the ground
Config.CubeSize = 6
-- Egg HP bars (Client/EggBars): sizes are studs, so a bar shrinks with distance like the egg. LabelWidth = bar-gui width as a multiple of the
-- egg width (room for the one-line text). Shown within MaxDistance, and only on a damaged egg or one within ShowDistance of the player.
-- Decorative lights tagged Tag flicker: their Range jumps to a random whole number between Min and Max every Step seconds (client only).
Config.LightFlicker = { Tag = "Flicker", Min = 5, Max = 10, Step = 0.1 }
-- Blinking fixture (tag Tag on the bulb part, which carries a PointLight): off Off1, on On, off Off2, then on for a random whole number of
-- seconds up to MaxPause; the bulb part's Transparency follows the light (the behaviour of the imported Flickering Light model).
Config.LightBlink = { Tag = "Blink", Off1 = 0.02, On = 0.15, Off2 = 0.02, MaxPause = 4 }

-- Plaza NPCs (Client/NpcMotion.luau): anchored, harmless, animated locally. Routes are offsets from each model's Home attribute, walked in a loop.
-- R15 uses NPC 1's own animations (idle 742637544, walk 742638842) plus Roblox's R15 wave; R6 uses Roblox's default R6 set.
Config.Npc = {
 CagePreview = {Animations={Walk=507777826,Idle=507766666},SpeedPerHeight=.18,MinAnimationSpeed=.45,Pause=.65,HeightFraction=.80,InnerFraction=.80,BodyRadiusFactor=.60,BodyWidthFraction=.95,FloorClearance=.025,PanelFraction=.22,SurfaceBand=.30,RoofInset=.02,RoundRouteFactor=.6},
	Tag = "Npc", ActiveDistance = 140, CheckSeconds = 0.5,
	WalkSpeed = 6, AnimRefSpeed = 16, TurnRate = 8, Fade = 0.2, -- studs/s, studs/s of the walk clip at playback 1, turn smoothing per second
	WaveDistance = 14, WaveSeconds = 2.5, WaveCooldown = 15, IdlePause = { 2, 5 },
	Animations = {
		R15 = { Idle = 742637544, Walk = 742638842, Wave = 507770239 },
		R6 = { Idle = 180435571, Walk = 180426354, Wave = 128777973 },
	},
	Priority = { Idle = Enum.AnimationPriority.Idle, Walk = Enum.AnimationPriority.Movement, Wave = Enum.AnimationPriority.Action },
	Routes = {
		["NPC 1"] = { Rig = "R15", Points = { Vector3.new(0, 0, 0), Vector3.new(12, 0, 0), Vector3.new(12, 0, -8), Vector3.new(0, 0, -8) } },
		["NPC 2"] = { Rig = "R6", Points = { Vector3.new(0, 0, 0), Vector3.new(-10, 0, 0), Vector3.new(-10, 0, 8), Vector3.new(0, 0, 8) } },
		["NPC 3"] = { Rig = "R6", Points = { Vector3.new(0, 0, 0), Vector3.new(14, 0, 0) } },
	},
}

Config.EggBars = { HitShowSeconds = 1.5, ShowDistance = 15, CheckSeconds = 0.1, LabelWidth = 1.7, TextHeight = 0.7, BarHeight = 0.35, Gap = 0.4 }
Config.CubeSpawnMarkerTransparency = 1
Config.CubeRespawnSeconds = 15
Config.CubeFlashSeconds = 0.08
Config.EggHP = { Base = 10, Growth = 3.7 } -- normal egg HP = Base * Growth^(stage-1), so each stage needs a better pickaxe
Config.CubeHP = {}                                        -- per stage, derived from EggHP
for stage = 1, 12 do Config.CubeHP[stage] = math.floor(Config.EggHP.Base * Config.EggHP.Growth ^ (stage - 1) + 0.5) end
Config.Onboarding = { Eggs = 5, Hits = 3 } -- a new player's first Eggs Stage 1 eggs break in Hits hits
Config.CubeCountPerStage = { 6, 6, 7, 7, 8, 8, 9, 10, 10, 11, 12, 4 }    -- per stage
-- Stage signs and the entry banner: name, difficulty word and the recommended Speed Points (the points at which the SpeedCurve gives the walking speed
-- that keeps a round trip to that stage's cages near 75 s; Stage 12 is the average arrival in the sim). Guard chase speeds are 80% of that walking speed.
Config.StageBanner = { Seconds = 3.5, CheckSeconds = 0.25 }
Config.DifficultyColor = { Easy = Color3.fromRGB(110, 230, 120), Medium = Color3.fromRGB(255, 225, 90), Hard = Color3.fromRGB(255, 160, 60), Insane = Color3.fromRGB(255, 80, 80), Impossible = Color3.fromRGB(190, 90, 255) }
-- Per stage: Name/Difficulty/Points (signs and banner), Look (floor, walls, kept plants, decor; built by tools/BuildStageLooks.luau at edit time) and Mood
-- (client-side lighting tween, Client/StageMood). Look.Walls: Material/Color = wall blocks, Top = hedge top, Vine = hanging vines (omit to hide). Decor entries:
-- {Layout, Count, Material, Colors, ...}: Stripes = alternating bands along the stage, Cross = thin lines across, Edge = lines along both edges (Width),
-- Long = lines along the stage (Width), Scatter = Shape (Disc/Block) with a size range. The sum of Count must stay within Config.StageLook.PartBudget.
Config.StageInfo = {
 { Name = "Training Grounds", Difficulty = "Easy", Points = 0,
  Look = { Floor = { Material = Enum.Material.Grass, Color = Color3.fromRGB(88,138,63) }, Walls = { Material = Enum.Material.Ground, Color = Color3.fromRGB(112,84,52), Top = Color3.fromRGB(70,150,50), Vine = Color3.fromRGB(40,90,40) }, Keep = { Tuft = true, Bush = true, Bamboo = true },
   Decor = {
    { Layout = "Stripes", Count = 12, Material = Enum.Material.Grass, Colors = {Color3.fromRGB(78,128,56), Color3.fromRGB(98,150,70)} },
    { Layout = "Cross", Count = 5, Material = Enum.Material.SmoothPlastic, Colors = {Color3.fromRGB(245,245,245)}, Width = 0.8 },
    { Layout = "Edge", Count = 2, Material = Enum.Material.SmoothPlastic, Colors = {Color3.fromRGB(245,245,245)}, Width = 0.8 },
   } },
  Mood = { Tint = Color3.fromRGB(255,255,255), Saturation = 0.05, Contrast = 0.02, Brightness = 0.02, Decay = Color3.fromRGB(106,112,125), Glare = 0, Offset = 0.25, DensityScale = 0.9, HazeScale = 1, Bloom = 1 } }, -- 1
 { Name = "Clover Park", Difficulty = "Easy", Points = 330,
  Look = { Floor = { Material = Enum.Material.LeafyGrass, Color = Color3.fromRGB(70,125,55) }, Walls = { Material = Enum.Material.Ground, Color = Color3.fromRGB(96,84,52), Top = Color3.fromRGB(80,170,60), Vine = Color3.fromRGB(50,110,45) }, Keep = { Grass = true, Tuft = true, Bush = true, Bamboo = true },
   Decor = {
    { Layout = "Scatter", Count = 24, Material = Enum.Material.SmoothPlastic, Colors = {Color3.fromRGB(240,130,170), Color3.fromRGB(250,220,90), Color3.fromRGB(245,245,245), Color3.fromRGB(190,140,230)}, Shape = "Disc", Size = {2.5, 5} },
   } },
  Mood = { Tint = Color3.fromRGB(255,240,215), Saturation = 0.15, Contrast = 0.02, Brightness = 0.02, Decay = Color3.fromRGB(140,120,90), Glare = 0, Offset = 0.25, DensityScale = 1, HazeScale = 1, Bloom = 1 } }, -- 2
 { Name = "Sandlot Yard", Difficulty = "Medium", Points = 2560,
  Look = { Floor = { Material = Enum.Material.Sand, Color = Color3.fromRGB(214,176,112) }, Walls = { Material = Enum.Material.Sandstone, Color = Color3.fromRGB(196,150,95), Top = Color3.fromRGB(200,170,90), Vine = Color3.fromRGB(120,90,50) }, Keep = { Tuft = true, Bush = true }, Plant = Color3.fromRGB(190,170,90),
   Decor = {
    { Layout = "Scatter", Count = 16, Material = Enum.Material.Ground, Colors = {Color3.fromRGB(140,100,60), Color3.fromRGB(160,118,70)}, Shape = "Block", Size = {12, 30} },
    { Layout = "Scatter", Count = 6, Material = Enum.Material.Slate, Colors = {Color3.fromRGB(120,110,100)}, Shape = "Disc", Size = {4, 8} },
   } },
  Mood = { Tint = Color3.fromRGB(255,214,170), Saturation = 0, Contrast = 0.05, Brightness = 0, Decay = Color3.fromRGB(170,120,70), Glare = 0.1, Offset = 0.3, DensityScale = 1.3, HazeScale = 1.4, Bloom = 1 } }, -- 3
 { Name = "Stone Quarry", Difficulty = "Medium", Points = 4210,
  Look = { Floor = { Material = Enum.Material.Slate, Color = Color3.fromRGB(100,106,116) }, Walls = { Material = Enum.Material.Slate, Color = Color3.fromRGB(95,100,110), Top = Color3.fromRGB(115,128,105), Vine = Color3.fromRGB(80,85,95) }, Keep = { Tuft = true, Bush = true }, Plant = Color3.fromRGB(110,125,100),
   Decor = {
    { Layout = "Scatter", Count = 14, Material = Enum.Material.Rock, Colors = {Color3.fromRGB(80,86,96), Color3.fromRGB(96,100,108)}, Shape = "Block", Size = {8, 20} },
   } },
  Mood = { Tint = Color3.fromRGB(200,212,228), Saturation = -0.25, Contrast = 0.08, Brightness = -0.02, Decay = Color3.fromRGB(100,110,125), Glare = 0, Offset = 0.25, DensityScale = 1.1, HazeScale = 1.1, Bloom = 0.8 } }, -- 4
 { Name = "Lantern Alley", Difficulty = "Medium", Points = 72200,
  Look = { Floor = { Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(116,100,96) }, Walls = { Material = Enum.Material.Brick, Color = Color3.fromRGB(120,78,66), Top = Color3.fromRGB(60,90,50), Vine = Color3.fromRGB(60,45,45) }, Keep = { Tuft = true, Bush = true }, Plant = Color3.fromRGB(60,90,55),
   Decor = {
    { Layout = "Stripes", Count = 8, Material = Enum.Material.Cobblestone, Colors = {Color3.fromRGB(96,80,78), Color3.fromRGB(130,115,108)} },
    { Layout = "Edge", Count = 2, Material = Enum.Material.Slate, Colors = {Color3.fromRGB(60,55,60)}, Width = 3 },
   } },
  Mood = { Tint = Color3.fromRGB(255,185,150), Saturation = 0.05, Contrast = 0.08, Brightness = -0.06, Decay = Color3.fromRGB(120,70,80), Glare = 0.2, Offset = 0.35, DensityScale = 1.3, HazeScale = 1.3, Bloom = 1.2 } }, -- 5
 { Name = "Mossy Ruins", Difficulty = "Hard", Points = 252000,
  Look = { Floor = { Material = Enum.Material.Slate, Color = Color3.fromRGB(84,104,82) }, Walls = { Material = Enum.Material.Rock, Color = Color3.fromRGB(80,100,80), Top = Color3.fromRGB(70,120,60), Vine = Color3.fromRGB(50,90,55) }, Keep = { Grass = true, Tuft = true, Bush = true, Bamboo = true }, Plant = Color3.fromRGB(70,110,80),
   Decor = {
    { Layout = "Scatter", Count = 20, Material = Enum.Material.Grass, Colors = {Color3.fromRGB(60,110,70), Color3.fromRGB(80,130,70)}, Shape = "Disc", Size = {4, 10} },
   } },
  Mood = { Tint = Color3.fromRGB(215,245,210), Saturation = -0.05, Contrast = 0, Brightness = -0.02, Decay = Color3.fromRGB(90,130,100), Glare = 0, Offset = 0.3, DensityScale = 1.3, HazeScale = 1.5, Bloom = 0.9 } }, -- 6
 { Name = "Rust Harbor", Difficulty = "Hard", Points = 1630000,
  Look = { Floor = { Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(104,84,64) }, Walls = { Material = Enum.Material.CorrodedMetal, Color = Color3.fromRGB(150,95,60), Top = Color3.fromRGB(150,80,40), Vine = Color3.fromRGB(90,60,40) }, Keep = {},
   Decor = {
    { Layout = "Scatter", Count = 10, Material = Enum.Material.DiamondPlate, Colors = {Color3.fromRGB(120,124,128)}, Shape = "Block", Size = {10, 22} },
    { Layout = "Cross", Count = 4, Material = Enum.Material.CorrodedMetal, Colors = {Color3.fromRGB(140,90,60)}, Width = 3 },
   } },
  Mood = { Tint = Color3.fromRGB(205,208,212), Saturation = -0.35, Contrast = 0.05, Brightness = -0.05, Decay = Color3.fromRGB(95,100,105), Glare = 0, Offset = 0.3, DensityScale = 1.5, HazeScale = 1.6, Bloom = 0.8 } }, -- 7
 { Name = "Ember Works", Difficulty = "Hard", Points = 68500000,
  Look = { Floor = { Material = Enum.Material.Basalt, Color = Color3.fromRGB(38,34,38) }, Walls = { Material = Enum.Material.Basalt, Color = Color3.fromRGB(45,40,45), Top = Color3.fromRGB(120,30,20), Vine = Color3.fromRGB(70,25,20) }, Keep = {},
   Decor = {
   } },
  Mood = { Tint = Color3.fromRGB(255,170,150), Saturation = 0.1, Contrast = 0.12, Brightness = -0.04, Decay = Color3.fromRGB(160,60,40), Glare = 0.3, Offset = 0.35, DensityScale = 1.4, HazeScale = 1.5, Bloom = 1.5 } }, -- 8
 { Name = "Frost Terrace", Difficulty = "Insane", Points = 828000000,
  Look = { Floor = { Material = Enum.Material.Snow, Color = Color3.fromRGB(236,244,252) }, Walls = { Material = Enum.Material.Glacier, Color = Color3.fromRGB(170,210,235), Top = Color3.fromRGB(245,250,255) }, Keep = {},
   Decor = {
    { Layout = "Scatter", Count = 8, Material = Enum.Material.Glacier, Colors = {Color3.fromRGB(190,225,245)}, Shape = "Block", Size = {6, 14} },
   } },
  Mood = { Tint = Color3.fromRGB(190,215,255), Saturation = -0.1, Contrast = 0.05, Brightness = 0.04, Decay = Color3.fromRGB(100,140,190), Glare = 0.1, Offset = 0.25, DensityScale = 1.2, HazeScale = 1.4, Bloom = 1.1 } }, -- 9
 { Name = "Neon Arcade", Difficulty = "Insane", Points = 6070000000,
  Look = { Floor = { Material = Enum.Material.Metal, Color = Color3.fromRGB(36,36,54) }, Walls = { Material = Enum.Material.Metal, Color = Color3.fromRGB(42,42,62), Top = Color3.fromRGB(0,230,255), Vine = Color3.fromRGB(200,40,220), TopNeon = true }, Keep = {},
   Decor = {
    { Layout = "Long", Count = 4, Material = Enum.Material.Neon, Colors = {Color3.fromRGB(0,230,255), Color3.fromRGB(255,40,200), Color3.fromRGB(255,230,40), Color3.fromRGB(80,255,120)}, Width = 1.2 },
    { Layout = "Cross", Count = 12, Material = Enum.Material.Neon, Colors = {Color3.fromRGB(0,230,255), Color3.fromRGB(255,40,200), Color3.fromRGB(255,230,40), Color3.fromRGB(80,255,120)}, Width = 0.8 },
   } },
  Mood = { Tint = Color3.fromRGB(170,170,255), Saturation = 0.25, Contrast = 0.15, Brightness = -0.06, Decay = Color3.fromRGB(70,40,110), Glare = 0, Offset = 0.4, DensityScale = 1.2, HazeScale = 1.2, Bloom = 1.8 } }, -- 10
 { Name = "Storm Dome", Difficulty = "Impossible", Points = 31900000000,
  Look = { Floor = { Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(78,86,102) }, Walls = { Material = Enum.Material.Metal, Color = Color3.fromRGB(72,80,96), Top = Color3.fromRGB(60,66,80), Vine = Color3.fromRGB(55,60,75) }, Keep = {},
   Decor = {
    { Layout = "Scatter", Count = 12, Material = Enum.Material.Metal, Colors = {Color3.fromRGB(96,104,122), Color3.fromRGB(84,92,110)}, Shape = "Block", Size = {8, 20} },
   } },
  Mood = { Tint = Color3.fromRGB(160,170,190), Saturation = -0.3, Contrast = 0.12, Brightness = -0.05, Decay = Color3.fromRGB(60,65,80), Glare = 0, Offset = 0.4, DensityScale = 1.4, HazeScale = 1.5, Bloom = 0.8, Rain = true, Lightning = { Min = 6, Max = 14, Flash = 0.45 } } }, -- 11
 { Name = "Golden Colosseum", Difficulty = "Impossible", Points = 50400000000,
  Look = { Floor = { Material = Enum.Material.Marble, Color = Color3.fromRGB(236,226,204) }, Walls = { Material = Enum.Material.Marble, Color = Color3.fromRGB(235,230,215), Top = Color3.fromRGB(230,185,60), TopMetal = true }, Keep = {},
   Decor = {
    { Layout = "Edge", Count = 2, Material = Enum.Material.Metal, Colors = {Color3.fromRGB(230,185,60)}, Width = 4 },
    { Layout = "Cross", Count = 6, Material = Enum.Material.Metal, Colors = {Color3.fromRGB(230,185,60)}, Width = 2 },
    { Layout = "Scatter", Count = 8, Material = Enum.Material.Metal, Colors = {Color3.fromRGB(230,185,60)}, Shape = "Disc", Size = {6, 12} },
   } },
  Mood = { Tint = Color3.fromRGB(255,245,215), Saturation = 0.1, Contrast = 0.05, Brightness = 0.06, Decay = Color3.fromRGB(180,150,90), Glare = 0.15, Offset = 0.25, DensityScale = 0.8, HazeScale = 0.8, Bloom = 1.3 } }, -- 12
}
-- Stage looks: PartBudget = new decor Parts per stage (non-colliding, CanQuery false). Organic props a stage does not Keep move to ServerStorage.StageLookBackup.
Config.StageLook = { PartBudget = 40, EndMargin = 20, DecorHeight = 0.06, DecorLift = 0.03, Seed = 20261113, BackupFolder = "StageLookBackup", FolderName = "StageLook" }
-- Stage mood (client): the lighting tween when a stage is entered. Lightning is a client-only brightness flash (Flash = ColorCorrection brightness added).
Config.StageMood = { TweenSeconds = 2.5, CheckSeconds = 0.25, FlashSeconds = 0.12, FlashDecay = 0.35,
 Neutral = { Tint = Color3.new(1, 1, 1), Saturation = 0, Contrast = 0, Brightness = 0, Glare = 0, Offset = 0, DensityScale = 1, HazeScale = 1, Bloom = 1 } } -- outside the stages
-- Stage props (tools/PlaceStageProps.luau): templates in ServerStorage.StageProps.StageN are placed along both stage edges (offsets from the centre line).
-- Props never collide, stay EndClear studs from each stage end and SpawnClear studs from any cage spawn marker, and stop at PartBudget Parts per stage.
Config.StageProps = { PartBudget = 40, BandInner = 12, BandOuter = 2, EndClear = 24, SpawnClear = 8, MinGap = 8, Seed = 20261114, Attempts = 40, FolderName = "StageProps" }

-- Stage twists (docs/Plans.md part 2, numbers from tools/economy/escape_twists.py). Everything is decided on the server (Server/StageTwists) from the shared
-- server clock and zone parts built by tools/BuildStageTwists.luau; the client only draws warnings and moving props (Client/StageTwistFX, Shared/StageTwistMath).
-- Speed effects multiply walking speed (Player attribute TwistSpeed), Detect shrinks a guard's detection radius for that player (TwistDetect).
-- Zones = {Count, Radius, Material, Color, Transparency?, Height?}: non-colliding discs placed at random inside the stage.
Config.StageTwists = {
 Tick = 0.1, EndMargin = 30, ZoneHeight = 0.08, WarnColor = Color3.fromRGB(255,60,60), IdleMarker = Color3.fromRGB(90,70,60),
 Stages = {
  { Kind = "Boost", Seconds = 2, Mult = 1.3, Zones = { Count = 8, Radius = 8, Material = Enum.Material.Neon, Color = Color3.fromRGB(120,255,140) } },
  { Kind = "Clover", Luck = 0.2, Cooldown = 60, Zones = { Count = 6, Radius = 5, Material = Enum.Material.Grass, Color = Color3.fromRGB(30,170,60) } },
  { Kind = "Gust", Period = 15, Duration = 1.5, Warn = 2, Slow = 0.5 },
  { Kind = "Cart", Lanes = 3, Period = 12, Crossing = 4, Warn = 2, Stun = 1, Cooldown = 2, Size = Vector3.new(8, 5, 6), Margin = 1.5, Color = Color3.fromRGB(120,90,60) },
  { Kind = "Blackout", Period = 20, Duration = 5, Warn = 2, Detect = 0.6, Lanterns = 12, LitColor = Color3.fromRGB(255,200,110), DarkColor = Color3.fromRGB(40,35,35) },
  { Kind = "Mist", Detect = 0.4, Zones = { Count = 8, Radius = 16, Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(190,235,205), Transparency = 0.65, Height = 12 } },
  { Kind = "Container", Count = 4, Period = 25, Move = 6, Warn = 2, Slow = 0.7, Size = Vector3.new(40, 12, 14), Edge = 28, Color = Color3.fromRGB(190,90,50) },
  { Kind = "Lava", Slow = 0.35, Zones = { Count = 14, Radius = 15, Material = Enum.Material.CrackedLava, Color = Color3.fromRGB(255,110,40) } },
  { Kind = "Ice", Slow = 0.15, Zones = { Count = 16, Radius = 18, Material = Enum.Material.Ice, Color = Color3.fromRGB(150,205,235) } },
  { Kind = "Pads", Period = 9, Lit = 3, Stagger = 1.1, Seconds = 2, Mult = 1.3, Zones = { Count = 8, Radius = 8, Material = Enum.Material.Neon, Color = Color3.fromRGB(0,230,255) }, DarkColor = Color3.fromRGB(20,50,70) },
  { Kind = "Lightning", Period = 8, Warn = 1.5, Radius = 6, Jitter = 12, Knock = 40 },
  { Kind = "GoldenHour", Period = 120, Duration = 20, Warn = 5, Luck = 0.2 },
 },
}
-- Collection sets: owning every roster footballer of a tier in Gold or better pays Gold[tier] extra plot income; a Diamond-or-better star pays
-- DiamondFactor of that. The total never exceeds Cap. Progress comes from the Index (Shared/SetBonus), nothing extra is saved.
Config.Sets = { Cap = 0.25, DiamondFactor = 0.5, GoldVariant = "Gold", DiamondVariant = "Diamond",
 Gold = { Common = 0.01, Rare = 0.015, Epic = 0.02, Legendary = 0.03, Mythic = 0.04, GOAT = 0.05 } }
-- Stage gates: an open arch (two pillars and a sign plate above the lanes) at every stage entrance, readable from far away.
Config.StageGate = { PillarWidth = 6, PillarHeight = 38, PlateHeight = 30, PlateThickness = 2, Inset = 6, Offset = 4, FolderName = "StageGates",
 PlateColor = Color3.fromRGB(24,34,46), PillarColor = Color3.fromRGB(60,66,76), Canvas = Vector2.new(1800, 300) }
-- First arrival in a stage (once per account, kept through rebirths): cash = Seconds of that stage's tier income per second.
Config.StageArrival = { Seconds = 90, BannerSeconds = 2.5, FadeSeconds = 0.5, SlideSeconds = 0.3, SlideOffset = 24, CheckSeconds = 0.5, SoundId = "rbxassetid://9083627113", SoundVolume = 0.7 }

Config.CubeColumnX = { -72, 72, -40, 40 } -- spawn columns (fill order); centre lane stays free

-- GOAT event cube: the only source of GOAT cards. One cube per interval + announcement.
Config.GoatStage = 12
Config.GoatSpawnIntervalSeconds = 120 -- TESTING VALUE. Set to 1200 (20 minutes) for live.
Config.GoatAnnouncement = "A GOAT EGG has appeared in STAGE 12!"
Config.GoatEvent = { MinVariant = "Gold" } -- timed event egg: always the Huge size and a Gold-or-better variant; Stage 12 also has regular GOAT cages

-- Golden Cage event: one at a random point of a random stage in [Min, Max]
Config.GoldenIntervalSeconds = 300
Config.GoldenInitialDelaySeconds = 300
Config.GoldenMinStage = 4
Config.GoldenMaxStage = 11
Config.GoldenHPMultiplier = 3

-- Egg sizes, rolled per egg by Weight. HP multiplies the egg's HP, Odds multiplies the variant odds, Scale sizes the egg and the
-- character inside. Secret is never rolled by weight (see SecretEgg); Huge is also the timed GOAT event egg.
Config.EggSizes = {
 { Id="Tiny",   Label="TINY",   Weight=15, HP=0.25, Odds=1,   Scale=0.7 },
 { Id="Small",  Label="SMALL",  Weight=25, HP=0.5, Odds=1,   Scale=0.85 },
 { Id="Normal",                 Weight=45, HP=1,   Odds=1,   Scale=1 },
 { Id="Big",    Label="BIG",    Weight=11, HP=2.5, Odds=1.5, Scale=1.25 },
 { Id="Huge",   Label="HUGE",   Weight=4,  HP=6,   Odds=3,   Scale=1.6 },
 { Id="Secret", Label="SECRET", Weight=0,  HP=20,  Odds=1,   Scale=1.4 },
 { Id="Titanic", Label="TITANIC", Weight=0, HP=100, Odds=5,  Scale=2.5, CharacterScale=2 }, -- only the global Titanic event (Config.Titanic)
}
Config.EggSizeById = {}
for _, size in Config.EggSizes do Config.EggSizeById[size.Id] = size end
-- Titanic event: one egg per server at the same moment everywhere. The schedule comes from os.time(): a slot starts every IntervalSeconds
-- and the egg lives LifetimeSeconds (a server that starts inside the window spawns it with the time that is left). Its stage is drawn from
-- the slot number, so every server picks the same one; stage s has weight 1 + StageBias * (s - 1), slightly favouring later stages. Its HP is
-- the egg size's HP (x100) times that stage's normal egg HP. It always drops the top tier, Gold or better, and is announced to everyone.
Config.Titanic = { IntervalSeconds = 5 * 3600, LifetimeSeconds = 20 * 60, StageBias = 0.15, Tier = "GOAT", MinVariant = "Gold", Color = Color3.fromRGB(255, 200, 40),
 Announcement = "A TITANIC EGG has appeared in STAGE %d! Every server - break it together!" }
Config.SecretEgg = { Chance = 0.001, MinVariant = "Gold", Color = Color3.fromRGB(190, 90, 255) } -- per egg spawn; drops one tier up (max GOAT)
Config.CardScaleCap = 2 -- Giant x egg size never makes a character larger than this multiple
Config.GoldenMaxTier = "Mythic" -- drops one tier above the stage, capped here
Config.GoldenColor = Color3.fromRGB(255, 200, 0)
Config.GoldenAnnouncement = "A GOLDEN EGG appeared in STAGE %d!"

Config.AnnouncementSeconds = 6

-- Pickaxe -------------------------------------------------------------
-- Tools: every player holds one mining Tool named PickaxeName (equipping swaps it for a copy of the chosen template, a Tool in
-- ServerStorage.AxeTemplates) plus the free Mesh Bat. Cash tools: Power = damage per hit, bought with cash in any order.
Config.PickaxeName = "Default Axe"
-- Rarity tags of tools and trails (the sim in tools/economy/sim4.py priced them).
Config.ToolRarity = { Common=Color3.fromRGB(190,190,195), Uncommon=Color3.fromRGB(90,220,110), Rare=Color3.fromRGB(70,140,255), Epic=Color3.fromRGB(175,80,255),
 Legendary=Color3.fromRGB(255,160,40), Mythic=Color3.fromRGB(255,70,130), Celestial=Color3.fromRGB(110,235,255) }
Config.CashTools = {
 { Id="Default",  Name="Default Axe",    Rarity="Common",    Power=1,        Cost=0,            Template="Default" },
 { Id="Hatchet",  Name="Sharp Hatchet",  Rarity="Common",    Power=3,        Cost=260,          Template="Good" },
 { Id="Copper",   Name="Copper Pick",    Rarity="Common",    Power=7,        Cost=700,          Template="Copper" },
 { Id="Miner",    Name="Miner's Pick",   Rarity="Common",    Power=18,       Cost=2100,         Template="Pickaxe" },
 { Id="Steel",    Name="Steel Pick",     Rarity="Uncommon",  Power=47,       Cost=6600,         Template="SteelPickaxe" },
 { Id="Quartz",   Name="Quartz Pick",    Rarity="Uncommon",  Power=120,      Cost=20000,        Template="Quartz" },
 { Id="Golden",   Name="Golden Pick",    Rarity="Uncommon",  Power=330,      Cost=66000,        Template="Golden" },
 { Id="Magma",    Name="Magma Axe",      Rarity="Uncommon",  Power=850,      Cost=200000,       Template="Volcanic" },
 { Id="Godly",    Name="Godly Pick",     Rarity="Rare",      Power=2200,     Cost=620000,       Template="Godly" },
 { Id="Sunstone", Name="Sunstone Axe",   Rarity="Rare",      Power=5900,     Cost=2000000,      Template="Sunstone" },
 { Id="Ember",    Name="Ember Pick",     Rarity="Rare",      Power=15000,    Cost=6000000,      Template="Ember" },
 { Id="Frost",    Name="Frost Pick",     Rarity="Rare",      Power=40000,    Cost=19000000,     Template="Frost" },
 { Id="Jade",     Name="Jade Hatchet",   Rarity="Epic",      Power=110000,   Cost=63000000,     Template="Jade" },
 { Id="Storm",    Name="Storm Pick",     Rarity="Epic",      Power=280000,   Cost=190000000,    Template="Storm" },
 { Id="Obsidian", Name="Obsidian Axe",   Rarity="Epic",      Power=730000,   Cost=580000000,    Template="Obsidian" },
 { Id="Tempest",  Name="Tempest Axe",    Rarity="Legendary", Power=1900000,  Cost=1800000000,   Template="Tempest" },
 { Id="Rose",     Name="Rose Gold Pick", Rarity="Legendary", Power=5000000,  Cost=5600000000,   Template="Rose" },
 { Id="Void",     Name="Void Pick",      Rarity="Mythic",    Power=13000000, Cost=17000000000,  Template="Void" },
 { Id="Aether",   Name="Aether Pick",    Rarity="Mythic",    Power=34000000, Cost=54000000000,  Template="Aether" },
 { Id="Prism",    Name="Prism Pick",     Rarity="Celestial", Power=90000000, Cost=170000000000, Template="Prism" },
}
-- Premium tools are Robux game passes (GamePassId 0 until the owner creates the pass). Their power is never an absolute number: it is the
-- player's best owned CASH tool times Multiplier (at most 1.5), so paying is a convenience and style boost, never a way past the economy.
-- ComingSoon rows show a picture only. Arms = the Robot Arm Drill, held in the Right hand, Left hand or Both (Config.ArmModes).
Config.PremiumTools = {
 { Id="Hammer",   Name="Hammer",          Multiplier=1.2,  GamePassId=0, Template="Hammer" },
 { Id="Reaper",   Name="Marrow Reaper",   Multiplier=1.25, GamePassId=0, Template="Reaper" },
 { Id="Drill",    Name="Drill",           Multiplier=1.3,  GamePassId=0, Template="Drill" },
 { Id="Drill2",   Name="Gilded Auger",    Multiplier=1.35, GamePassId=0, Template="Drill2" },
 { Id="RobotArm", Name="Robot Arm Drill", Multiplier=1.4,  GamePassId=0, Template="RobotArm", Arms=true },
 { Id="Laser",    Name="Laser Drill",     Multiplier=1.5,  ComingSoon=true, Template="Laser" },
}
Config.ArmModes = { "Right", "Left", "Both" }
Config.ToolShop = { RequestGap = 0.4, PremiumMinHits = 5 } -- seconds between a player's shop requests
-- Mesh Bat: free combat tool in hotbar slot 2. Same cooldown, range, facing and line-of-sight rules as the pickaxe on players
-- (only a player carrying a character can be hit); a hit makes the carrier drop it and knocks them back. It never damages.
Config.Bat = { Name="Mesh Bat", Template="MeshBat", KnockbackSpeed=70, KnockbackUp=28, ToolTip="Knock a carrier back so they drop their player" }
-- Auto Swing waits SwingCooldown + Margin between swings, turns to the nearest cage in range and swings; ButtonSize is the bottom-centre button (pixels).
Config.AutoSwing = { Margin = 0.05, ButtonSize = 92, ButtonRaise = 118 }
Config.SwingCooldown = 0.7          -- seconds between hits (server enforced)
Config.PickaxeRange = 12             -- max studs from player root to cube centre
Config.PickaxeCloseRange = 6         -- cubes this close always count, even if not facing
Config.PickaxeFacingDot = 0.3        -- min dot(look, toTarget) for "in front" (1 = dead ahead)
Config.PickaxeSounds = {             -- placeholder built-in clips
	Hit = "rbxasset://sounds/metal.mp3",
	Miss = "rbxasset://sounds/swordslash.wav",
}

Config.Axes = {
 SwingDuration = 0.7, StrikeEnd = 0.46, ImpactTime = 0.43,
 RunSpeedReference = 16, RunMinimumSpeed = 0.5, AnimationDistance = 120,
 RunKneeBend = 0.8, RunElbowBend = 0.7, StrikeElbowBend = 0.6,
}

-- Cards ---------------------------------------------------------------
Config.CardSize = Vector3.new(3, 5, 2)
Config.UITheme={
 Background=Color3.fromRGB(249,244,232),Card=Color3.fromRGB(255,253,247),
 Button=Color3.fromRGB(255,185,65),Accent=Color3.fromRGB(224,125,34),
 Selected=Color3.fromRGB(49,137,80),Border=Color3.fromRGB(211,193,162),Preview=Color3.fromRGB(237,227,207),
 Text=Color3.fromRGB(43,37,30),Muted=Color3.fromRGB(105,94,78),
 Disabled=Color3.fromRGB(222,216,203),HoverScale=1.025,PressScale=.96,
 -- Text on the screen has no box: white, gold for highlights, red for warnings, all with a dark outline so it reads on snow and on the Neon Arcade.
 TextMain=Color3.new(1,1,1),TextGold=Color3.fromRGB(255,214,80),TextWarn=Color3.fromRGB(255,84,72),Outline=Color3.fromRGB(12,14,20),OutlineThickness=2,
 MotionSeconds=.14,WindowSeconds=.22,WindowWidth=820,WindowHeight=650,
 Margin=16,CompactWidth=680,NavWidth=132,NavCompactWidth=100,NavHeight=44,NavGap=8,NavMoreOrder=99,
 PreviewFPS=24,PreviewTurnSpeed=.42,PreviewBob=.055,PreviewBobSpeed=1.8,
 Icons={close="rbxassetid://118819271276803",star="rbxassetid://71458718634620",
 energy="rbxassetid://109772672051925",medal="rbxassetid://97945893037460",
 mail="rbxassetid://71078899575319",key="rbxassetid://77808432154113",
 profile="rbxassetid://93837765787009",confirm="rbxassetid://82777339225926"},
}
-- Screen layout (Client/UIKit.Screen): every ScreenGui keeps out of Roblox's reserved areas and gets one UIScale = min(width/ReferenceX, height/ReferenceY)
-- clamped to Min..Max, updated live when the viewport changes. Top rows are the Y offsets (in UI units) of the stacked top-centre texts; EyeKey hides the UI.
Config.UIScreen={ReferenceX=800,ReferenceY=450,MinScale=.7,MaxScale=1.25,TopStage=6,TopPopup=50,TopAnnounce=122,TopWarning=164,MessageBottom=150,
 EyeSize=36,EyeMargin=8,CaptureReserve=116, -- pixels left free at the right edge for Roblox capture buttons (CoreUISafeInsets does not cover them)
 EyeKey=Enum.KeyCode.H,AutoSwingWidth=120,AutoSwingHeight=32,AutoSwingGap=8}
Config.FocusUI={Range=14,ScreenRadius=.16,RefreshSeconds=.1,PanelWidth=340,PanelHeight=94,Bottom=160,ShortBottom=135, -- above Auto Swing and the hotbar
 ActionWidth=144,ActionHeight=46,ActionBottom=200}
Config.HotbarUI={MinSlotWidth=54,SlotWidth=74,SlotHeight=72,Gap=7,Bottom=12,MaxSlots=10,RefreshSeconds=.15,Accent=Color3.fromRGB(224,125,34)}
Config.CardLabels = {Distance=60,HeadClearance=1.6,Width=230,Height=92,RefreshSeconds=0.25,StatusColor=Color3.fromRGB(255,190,90),IncomeColor=Color3.fromRGB(120,255,150)}
Config.DropPlayer = {Forward=4,RequestCooldown=.4,SafeCargoLimit=30}
Config.CardRestHeight = 0.6          -- gap between dropped card and floor
Config.CarryOffset = Vector3.new(0, 3.2, 0) -- above the Head
Config.PickupHoldSeconds = 0.3
Config.PickupPromptDistance = 8
Config.PickupMaxDistance = 20        -- server-side sanity check
Config.InteractMaxDistance = 25      -- server-side sanity check (slots)
Config.DroppedCardLifetime = 30      -- cards dropped by death/leave despawn after this
Config.CubeDropLifetime = 30          -- cards from broken cubes; 0 = never despawn
Config.CarryTrackSeconds = 0.1
Config.FallbackDropPosition = Vector3.new(0, 5, -60)

-- Stealing ------------------------------------------------------------
Config.ReservationLabelSize = Vector2.new(170, 36)
Config.ReservationLabelOffset = Vector3.new(0, 3, 0)
Config.ReservationLabelMaxDistance = 70
Config.StealHoldSeconds = 1.5
Config.StealAlert = "%s is stealing your %s!" -- (thief name, card name)

-- Guards (per stage, index = stage number) -------------------------------
Config.GuardCountPerStage = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 }
Config.GuardChaseSpeed    = { 12.8, 20.8, 33.6, 46.4, 60.8, 74.4, 87.2, 94.3, 112, 128.2, 144, 122.4 } -- 80% of the stage's recommended speed; Stages 8-12 trimmed (at most 10%) where the run clip cannot keep up at AnimSpeedMax; Stage 12 x0.85 so a carrier can get out (tools/economy/escape.py)
Config.GuardPatrolSpeedFactor = 0.7   -- patrol speed = chase speed * factor
Config.GuardSize = Vector3.new(3, 6, 2)
Config.GuardHeadSize = 2
Config.GuardColor = Color3.fromRGB(200, 40, 40)
Config.GuardMinimumHeight = 12
Config.GuardVisualScale = 1.65
Config.GuardPickupChaseMultiplier = 1.15
Config.GuardDetectRadius = 150         -- a guard starts chasing a carrier inside its stage only once the carrier is this close (flat studs); it then chases to the stage edge
Config.SecuredCarry = { GripSettleSeconds = 0.35, Grip = CFrame.new(0, -0.15, -1.5), VisualOffset = Vector3.new(0, .7, -1) }
Config.GuardHit = { PerHeight = 0.3, Margin = 1.5, PlayerHalfHeight = 3 } -- touch = the player's body within PerHeight x the guard's pre-scale height (+ Margin) of its axis, measured flat along the path it just walked
Config.GuardHitCooldownSeconds = 1.5  -- per-player immunity after a hit
Config.GuardStunSeconds = 1           -- guard pauses after hitting
Config.GuardFall = { Seconds = 1.5, Angle = math.pi/2 }
Config.KnockbackStunSeconds = 0.4     -- hit client is ragdolled this long so the impulse is not cancelled by the Humanoid
Config.GuardZoneMargin = 4            -- guards stay this far from the hallway walls
Config.GuardWaypointReach = 2
Config.GuardNearDistance = 60         -- guards with a player this close are driven every frame (chase/hit); all others patrol only
Config.GuardFarUpdatesPerSecond = 4   -- patrol re-evaluations per second for guards with no player near
Config.GuardNearCheckSeconds = 0.25   -- how often near/far and animation distance are re-evaluated
-- Guards are unanchored, server-owned and moved by an AlignPosition (speed-limited, so far guards glide between 4 Hz targets)
-- plus an upright AlignOrientation; they never collide with players.
Config.GuardAlign = { MaxForce=1e7, MaxTorque=1e7, Responsiveness=200, TurnSpeed=6, HoldVelocity=5, MinMove=0.3, SettleGain=0.5, MaxSettle=1.5 }

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
 StageSignSize = Vector3.new(0.25, 6, 24), StageSignHeight = 10,
 StageSignColor = Color3.fromRGB(30, 47, 30),
 PlotInset = 0.5, PlotSignSize = Vector3.new(0.2, 2, 29), PlotSignHeight = 6,
 SlotThickness = 0.18,
 WillowScale = 0.8, WillowStageInterval = 3, TreeOutsideOffset = 22,
 BambooScale = 0.42, BushScale = 0.27, BushLeafScale = 0.28,
 EdgeInset = 5, TuftsPerStage = 8, TuftScale = 0.6, PlazaTreeOutsideOffset = 60,
 MaxGrassPartsPerStage = 150, MaxPlotVisualParts = 550,
 VisibilityUpdateSeconds = 0.5,
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
  TorchLightRange = 18,
 TorchLightBrightness = .8, TorchFireRate = 1, TorchGlowRate = .5,
 TorchSmokeRate = .1,
}
Config.Weather = {
 DaySeconds = 1200, StartHour = 9, UpdateSeconds = 1, TransitionSeconds = 4,
 RainStartHour = 13, RainEndHour = 15, RainChance = 0.6, DayStartHour = 6, EveningHour = 16, NightHour = 18,
 RainRate = 1400, RainSpeed = 75, RainLifetime = 0.6, RainSize = 3, RainTransparency = 0.4,
 RainHeight = 32, RainArea = 140, RoofProbeHeight = 40, RoofProbeSteps = 4, RoofMinSize = 8, RoofMaxTransparency = 0.9, -- RainArea: studs covered around the camera
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
 SlotsPerFloor = 10, EmptyText = "Now a player",
 -- Per slot (templates in ServerStorage.SlotTemplates, scaled to these sizes): pedestal under the character, a collect pad in front
 -- of it (pending cash is paid when the owner steps on it) and an upgrade button stand beside it.
 PedestalDiameter = 3.4, CollectPadSize = 2.4, CollectPadOffset = 4.4, CollectCooldown = 0.5, CollectEffectSeconds = 0.35,
 StandHeight = 3.2, StandSideOffset = 2.6, StandForwardOffset = 1.2, UpgradeButtonColor = Color3.fromRGB(255, 200, 30),
 CollectSoundId = "rbxassetid://9083627113", CollectLightColor = Color3.fromRGB(40, 220, 70),
 LabelWidth = 200, LabelHeight = 32, LabelDistance = 45,
 PartBudgetPerSlot = 12, -- BaseParts per slot (pedestal, pad, stand, proxy); the builder asserts PartBudgetPerSlot x SlotsPerPlot per plot
 DisplayClearance = 0.02, PromptDistance = 5, InteractDistance = 8,
 UpgradeKey = Enum.KeyCode.R, UpgradeCooldown = 0.4, UpgradePromptDistance = 4.5,
 MessageGap = 0.3, MessageSeconds = 1.6, CantAffordColor = Color3.fromRGB(255, 80, 80),
 Messages = {Cash = "Not enough cash", Far = "Too far away", Cooldown = "Wait a moment", Max = "Max level", NotOwner = "Not your slot"},
 IncomeGrowth = 1.25, CostGrowth = 1.6, FirstCostSeconds = 60, MaxLevel = 20,
}
Config.MonsterGuards = {
 EffectsDistance = 80, ParticleRate = 2,
 AnimationDistance = 800, -- guards animate whenever a client can see them: the streaming target radius (Workspace.StreamingTargetRadius)
 LightBrightness = 1, LightRange = 6,
 BodyGlowDesigns = { Noob=true, BigGuy=true }, BodyGlowTransparency = 0.88,
 BodyGlowColor = Color3.fromRGB(255,235,170),
 -- Each stage lists its guards (guard i uses entry (i-1) mod #list + 1): Design = template in ServerStorage.MonsterTemplates, Height in
-- studs (one uniform scale, so proportions never stretch), Pack = key of Packs, optional Tint multiplies the colours. A design without a
-- Pack is bone-driven (client clips). Stages 4, 8 and 11 use animated designs; their original bone-driven ones are kept in OriginalStages:
-- copy them into Stages once they have a pack.
 Eye = { Hover = 4, Range = 65, StandOff = 18, Speed = 6, ReportInterval = 0.1, ReportTimeout = 0.5 },
 ProceduralHz = 24, StridePerHeight = 0.38, SandTurnRadius = 28,
 SandRippleHeight = 0.18, SandRippleFrequency = 0.45,
 Stages = {
  { { Design = "Stage01Noob", Height = 7, Pose = "Walk" } },
  { { Design = "Stage02Monster", Height = 8, Pose = "Walk" } },
  { { Design = "Stage03Bramble", Height = 9, Pose = "Bramble" } },
  { { Design = "Stage04Backrooms", Height = 10, Pose = "Walk" } },
  { { Design = "Stage05RiggedNew", Height = 10.5, Pack = "CustomR15" } },
  { { Design = "Stage06Eye", Height = 11.5, Pose = "Still" } },
  { { Design = "Stage07SCP096", Height = 12.5, Pose = "WalkIdle" } },
  { { Design = "Stage08MonsterR15", Height = 13, Pose = "Walk" } },
  { { Design = "Stage09Monster", Height = 14, Pose = "Walk" } },
  { { Design = "Stage10NoobVariant", Height = 14.5, Pose = "Walk" } },
  { { Design = "Stage11EarthWorm", Height = 15.5, Pose = "Earth" } },
  { { Design = "Stage12SandWorm", Height = 20, Pose = "Sand" } },
 },
 OriginalStages = { [4] = { { Design = "Realistic", Height = 10 } }, [8] = { { Design = "Paranormica", Height = 13 } }, [11] = { { Design = "White", Height = 15.5 } } },
 -- Bone-driven designs keep the client-side bone clips.
 Animations = { White="WhiteRun", Jessie="JessieRun" },
 -- Animation packs. ZombieR15 and WerewolfR15 are Roblox-made; the others were generated with Studio's animation generator ("zombie-style"
-- walk/run/idle and a 2 s lunge, saved to the owner's account) and drive an R6-style rig through its Retarget. Idle/Walk/Run loop, IdleLook plays
-- once now and then while idle, Attack plays once when the guard hits. Stride = studs per second the feet cover per stud of guard height at
-- playback speed 1 (Roblox packs use their 16 studs/s for a 5-stud avatar; generated clips come from their leg swing: leg length x
-- sin(half the swing range) x cycles / length). Playback = ground speed / (Stride * height), capped by AnimSpeedMax; a patrol whose Walk
-- would need more than the cap plays the Run clip instead.
 Packs = {
  CustomR15 = { Idle="rbxassetid://507766388", Walk="rbxassetid://507777826", Run="rbxassetid://507767714", Attack="rbxassetid://522635514", Stride={Walk=3.2,Run=3.2} },
  ZombieR15 = { Idle="rbxassetid://616158929", IdleLook="rbxassetid://616160636", Walk="rbxassetid://616168032", Run="rbxassetid://616163682", Attack="rbxassetid://522635514", Stride={Walk=3.2,Run=3.2} },
  WerewolfR15 = { Idle="rbxassetid://1083195517", IdleLook="rbxassetid://1083214717", Walk="rbxassetid://1083178339", Run="rbxassetid://1083216690", Attack="rbxassetid://522635514", Stride={Walk=3.2,Run=3.2} },
  TeddyZombie = { Retarget="Forearm", Idle="rbxassetid://120512474902742", Walk="rbxassetid://128874772131770", Run="rbxassetid://75198745894759", Attack="rbxassetid://100225665383596", Stride={Walk=1.16,Run=2.55} },
  LongArmZombie = { Retarget="Forearm", Idle="rbxassetid://107136854838348", Walk="rbxassetid://78505627347284", Run="rbxassetid://129748293211846", Attack="rbxassetid://98443400452270", Stride={Walk=0.65,Run=2.11} },
  DefaultR6 = { Idle="rbxassetid://180435571", Walk="rbxassetid://180426354", Run="rbxassetid://180426354", Attack="rbxassetid://129967390", Stride={Walk=3.2,Run=3.2} }, -- Roblox default R6 (the walk doubles as the run); Noob and Monster: generated zombie clips tumbled their rigs
 },
 -- Rigs with forearm chains lack the R15 part names and hierarchy: Parts renames them, Parents moves a joint under another part (stand-ins from R15Chain).
 Retargets = {
  Forearm = { -- Teddy, LongArm: torso, forearm > arm > hand chains
   Parts = { Torso="LowerTorso", ["Right Forearm"]="RightUpperArm", ["Right Arm"]="RightLowerArm", ["Right Hand"]="RightHand", ["Left Forearm"]="LeftUpperArm", ["Left Arm"]="LeftLowerArm", ["Left Hand"]="LeftHand", ["Right Leg"]="RightUpperLeg", ["Left Leg"]="LeftUpperLeg" },
   Parents = { Head="Chest", RightUpperArm="RightClavicle", LeftUpperArm="LeftClavicle" },
  },
 },
 RestPoses = { Backrooms = { RightUpperArm = Vector3.new(0, 0, -90), LeftUpperArm = Vector3.new(0, 0, 90) } }, -- imported T-posed arms rest at the clip's arms-down pose
 R15Chain = { -- {stand-in part, its parent}: the R15+ joints a retargeted design lacks
  { "UpperTorso", "LowerTorso" }, { "Spine", "UpperTorso" }, { "Chest", "Spine" }, { "RightClavicle", "Chest" }, { "LeftClavicle", "Chest" },
  { "RightLowerLeg", "RightUpperLeg" }, { "RightFoot", "RightLowerLeg" }, { "RightToeBase", "RightFoot" },
  { "LeftLowerLeg", "LeftUpperLeg" }, { "LeftFoot", "LeftLowerLeg" }, { "LeftToeBase", "LeftFoot" },
 },
 AnimSpeedMax = 2.5, AnimFadeSeconds = 0.2, AttackSeconds = 0.8, IdleLookChance = 0.35,
 BoneAliases = {
 Realistic = {["upper_arm.L"]="Left Arm",["upper_arm.R"]="Right Arm",["thigh.L"]="Left Leg",["thigh.R"]="Right Leg",["spine.002"]="Torso"},
 },
}
-- Training points are distinct from studs/second. All 15 levels share one owned pad.
Config.Treadmills = {
 BaseGain=5, TickSeconds=1, RequestCooldown=.5,
 RunAnimationR15="rbxassetid://507767714",RunAnimationR6="rbxassetid://180426354",
 -- Speed Points -> walking speed (studs/s), linear in log10(1 + points) between these points (fitted in tools/economy so the speed on arrival at each
 -- stage matches the stage's recommended Speed Points; 200 is reached at Stage 11). The walking speed is never shown, only the points.
 SpeedCurve={{0,16},{330,26},{2560,42},{4212,58},{72153,76},{251866,93},{1632903,109},{68517539,131},{827588229,149},{6071109646,178},{31944619545,200}},
 TemplateSize=Vector3.new(9,7,13), PlotOffset=24.5, EntrySideOffset=10, SensorSeconds=.1, BeltWidth=6, BeltLength=8, BeltCenter=2, BeltHeight=.8, EntryRun=4, GroundY=1.1,
 ParticleRate=2, EffectsDistance=65, LabelDistance=12, MaxLights=1,
 Catalog={
  {Id="Base",Name="Starter",Multiplier=1.5,Cost=0,Template="TreadmillBasic"},
  {Id="Circuit",Name="Circuit",Multiplier=2,Cost=24,Template="x1 Treadmill"},
  {Id="Alloy",Name="Alloy",Multiplier=4,Cost=56,Template="TreadmillPlaytime"},
  {Id="Flame",Name="Flame",Multiplier=6,Cost=133,Template="x3 Treadmill"},
  {Id="Diamond",Name="Diamond",Multiplier=9,Cost=313,Template="TreadmillDiamond"},
  {Id="Frost",Name="Frost",Multiplier=12,Cost=737,Template="x15 Treadmill"},
  {Id="Nova",Name="Nova",Multiplier=15,Cost=1740,Template="x50 Treadmill"},
  {Id="Solar",Name="Solar",Multiplier=20,Cost=4090,Template="x100 Treadmill"},
  {Id="Galaxy",Name="Galaxy",Multiplier=25,Cost=9630,Template="TreadmillGalaxy"},
  {Id="Aurora",Name="Aurora",Multiplier=35,Cost=22700,Template="x15 Treadmill"},
  {Id="Obsidian",Name="Obsidian",Multiplier=50,Cost=53400,Template="x50 Treadmill"},
  {Id="Titan",Name="Titan",Multiplier=75,Cost=126000,Template="x100 Treadmill"},
  {Id="Void",Name="Void",Multiplier=100,Cost=296000,Template="TreadmillVoid"},
  {Id="Infinity",Name="Infinity",Multiplier=250,Cost=697000,Template="TreadmillVoid"},
  {Id="ShadowScott",Name="Shadow Scott",Multiplier=500,Cost=1640000,Template="Shadow Scott"},
  {Id="Celestial",Name="Celestial",Multiplier=1500,GamePassId=0,Template="TreadmillCelestial"}, -- GamePassId: paste the owner-created pass ID here; the price shown is the live Roblox price
 },
}
Config.PlayerData={Store="FootballerProfiles_v1",ReportStore="FootballerReports_v1",AutosaveSeconds=60,
 SaveCoalesceSeconds=6,ItemIdMinLength=8,ItemIdMaxLength=40,
 LockSeconds=180,Retries=3,RetrySeconds=2,StudioMemoryOnly=true,ProfileVersion=2,MaxCash=1e60,MaxSpeedPoints=1e60,MaxCounter=1e15,
 MaxPurchaseHistory=60,ReportCooldown=60,MaxReportsPerDay=5,MaxInboxRecords=1000,
 FeedbackCategories={"Bug","Lost progress","Controls","Balance","Abuse","Exploiting"}}

-- Permanent income game pass: multiplies cash earned from the player's plot (Celestial is the other pass, in the treadmill catalog).
-- GamePassId: paste the owner-created pass ID (0 = not available); the shop shows the live Roblox price.
Config.CashPass = { Id="DoubleCash", Name="2x Cash", Multiplier=2, GamePassId=0 }

-- Robux purchases (see Purchases.luau). StudioTestMode only applies inside Studio: passes, prices and ownership are simulated and
-- Marketplace is never called, so no real purchase can happen. Live servers always use the real Marketplace.
Config.Purchases={LogStore="FootballerPurchaseLog_v1",LogKeyPrefix="U_",MaxLogEvents=200,LogFlushSeconds=30,LogWriteGapSeconds=6,
 PromptCooldownSeconds=10,PriceRefreshSeconds=300,MaxReceipts=200,
 RevokeStrikes=2,RevokeStrikeGapSeconds=3600, -- refund revoke: this many confirmed "not owned" results on separate joins this far apart
 StudioTestMode=true,TestPassId=1,TestPrice=4999,
 Products={}} -- developer products: [productId]={Cash=amount}; none exist yet and none may be random/paid-gamble items

-- Collection features (Phase 5). The roster entry fields Id/Name/Tier are required; PortraitImage (an "rbxassetid://..." string) is optional:
-- the Index uses it when present and falls back to a model preview. VariantOrder lists the paid-for-by-luck materials in a FIXED order
-- (only ever append): every character has two bits per material (normal and Giant), so saved bitmasks stay valid.
Config.Index={PerPage=8,VariantOrder={"Gold","Diamond","Ruby","Shadow","Emerald","Fire","Lightning","Void","Rainbow"},
 TierRewards={Common=500,Rare=2500,Epic=12500,Legendary=60000,Mythic=300000,GOAT=2000000}} -- provisional, one-time per tier
Config.Daily={BaseCash=500,StepCash=250,CapDays=7,ClaimCooldownSeconds=2,RefreshSeconds=60} -- reward = Base + Step*(min(streak,CapDays)-1)
-- Rebirth: filling the bar (log scale of Speed Points against the next requirement) unlocks it. A rebirth resets ONLY Speed Points; cash,
-- plot footballers, tools, trails, treadmills and upgrades are kept. Each rebirth adds IncomeStep to the income multiplier and GainStep to
-- the Speed Points gain multiplier. Requirement for rebirth number n = BaseRequirement * RequirementGrowth^(n-1) (tools/economy/rebirth.py).
Config.Rebirth={Max=10,Segments=10,BaseRequirement=8e10,RequirementGrowth=1.25,IncomeStep=.5,GainStep=.5,ConfirmSeconds=4,RequestGap=2}
-- Quests: 3 of the 5 kinds are drawn each UTC day (same for everyone), all 5 each UTC week (Monday start). They pay Quest Tokens.
-- RULE: Quest Tokens must NEVER be sold for Robux, directly or indirectly (no product, pass, bundle or offer may grant tokens or
-- token-priced upgrades). Tokens buy cage luck, so selling them would make luck a paid random item.
-- Target = a fixed number, or for Collect max(MinCollect, plot income per second at assignment * IncomeSeconds). A Steal only counts for a
-- victim whose account is older than MinAccountAgeDays and only once per victim per UTC day (blocks alt-account farming).
-- A Play minute counts only if the player moved MinMoveStuds since the last tick or is training on the treadmill.
Config.Quests={DailyCount=3,MinAccountAgeDays=3,MaxVictims=200,MaxTokens=1e9,SyncSeconds=1,PlayTickSeconds=60,MinMoveStuds=5,MinCollect=1000,RequestGap=.3,
 Kinds={
  {Id="Break",Text="Break %s cages",Daily={Target=30,Tokens=10},Weekly={Target=300,Tokens=40}},
  {Id="Place",Text="Place %s footballers",Daily={Target=5,Tokens=10},Weekly={Target=25,Tokens=25}},
  {Id="Play",Text="Play for %s minutes",Daily={Target=30,Tokens=15},Weekly={Target=240,Tokens=35}},
  {Id="Collect",Text="Collect $%s from your pads",Daily={IncomeSeconds=900,Tokens=10},Weekly={IncomeSeconds=7200,Tokens=30}},
  {Id="Steal",Text="Steal %s footballers",Daily={Target=1,Tokens=20},Weekly={Target=5,Tokens=40}},
 }}
Config.Quests.ById={}
for _,kind in Config.Quests.Kinds do Config.Quests.ById[kind.Id]=kind end
-- Upgrades shop (docs/Plans.md section 3): permanent, kept on rebirth, saved as profile.Upgrades = {id = level}. Bonus = Step * level.
-- Scale/Unit only format the value for the UI. RULE: Quest Tokens must NEVER be sold for Robux, directly or indirectly (see Config.Quests).
-- Luck adds to the rolled luck and the total is clamped at Config.Luck.LuckyMax, so it never lifts a Lucky Cage past that.
Config.Upgrades={RequestGap=.4,PadPollSeconds=.25,PadBaseReach=3.6, -- PadBaseReach: pad radius plus the character's root height above the pad
 Defs={
  {Id="Income",Name="Income",Hint="More cash from every placed footballer.",Step=.025,Scale=100,Unit="%",Currency="Tokens",Costs={20,30,45,65,90,120,160,210,270,350}},
  {Id="Speed",Name="Speed gain",Hint="More Speed Points from the treadmill.",Step=.05,Scale=100,Unit="%",Currency="Cash",Costs={1e6,4e6,1.5e7,5e7,1.5e8,4e8,1.2e9,4e9,1.2e10,4e10}},
  {Id="Pad",Name="Collect pad range",Hint="Collect cash from further away.",Step=1.5,Scale=1,Unit=" studs",Currency="Tokens",Costs={15,25,40,60,90}},
  {Id="Luck",Name="Cage luck",Hint="Added to the luck of every cage you break.",Step=.1,Scale=1,Unit=" luck",Currency="Tokens",Costs={30,50,80,120,180}},
 }}
Config.Upgrades.ById={}
for _,def in Config.Upgrades.Defs do Config.Upgrades.ById[def.Id]=def end
Config.Announce={Tiers={Mythic=true,GOAT=true},Variants={Diamond=true},Giant=true, -- what counts as a rare hatch
 GlobalGapSeconds=3,MaxPerMinute=6,PlayerGapSeconds=10}

-- The world outside the stages (see Server/WorldBuilder.luau, an edit-time tool). Positions are (X, Z) on the ground.
-- Jungle: Density is trees per square stud inside Bands, capped by PartBudget (BaseParts of all trees together, trunk colliders included).
Config.World = {
 GroundY = 0, Seed = 20261106, ClearMargin = 24, PathClear = 12,
 Jungle = {
  Density = 1 / 2000, PartBudget = 8000, Cell = 28, Scale = { 0.85, 1.25 },
  ZMin = -1000, ZMax = 5600,
  Bands = { { XMin = -600, XMax = -110 }, { XMin = 170, XMax = 700 } }, -- either side of the stage corridor (X -68..124)
  Types = { "Decid Tree 4", "Tree3" },
  -- Trunk collider per type: Diameter as a fraction of the Trunk part's X size, Offset (X, Z) of its centre as fractions of the part's size.
  Trunk = { Height = 10, ["Decid Tree 4"] = { Diameter = 0.19, Offset = Vector2.new(0.066, 0.096) }, Tree3 = { Diameter = 0.95, Offset = Vector2.zero } },
 },
 Lakes = {
  { Source = "ForestLake", Position = Vector2.new(-520, 1000), Yaw = 0, Scale = 2.2 },
  { Source = "Random Lake", Position = Vector2.new(-540, -250), Yaw = 0.5 },
  { Source = "Random Lake", Position = Vector2.new(-450, 2300), Yaw = 2 },
  { Source = "Random Lake", Position = Vector2.new(620, 1900), Yaw = 4 },
  { Source = "Lake", Position = Vector2.new(560, 800), Yaw = 0 },
 },
 ShoreLake = { Position = Vector2.new(560, 800) }, -- the normal Lake; the reptiles rest beside it
 Treehouses = {
  { Position = Vector2.new(-300, -560), Yaw = 0 }, { Position = Vector2.new(-400, 80), Yaw = 0.4 },
  { Position = Vector2.new(360, -560), Yaw = 0 }, { Position = Vector2.new(440, 100), Yaw = -0.4 },
 },
 Path = { Step = 3.5, Lane = 1.8, Jitter = 0.6, Lift = 0.1 }, -- a stone every Step studs on two lanes
 Paths = { -- from the plaza's open rear end around the plot rows to each treehouse
  { Name = "West1", Points = { Vector2.new(28, -880), Vector2.new(-30, -905), Vector2.new(-170, -905), Vector2.new(-200, -770), Vector2.new(-230, -650), Vector2.new(-225, -600) } },
  { Name = "West2", Points = { Vector2.new(-200, -770), Vector2.new(-185, -480), Vector2.new(-230, -300), Vector2.new(-300, -150), Vector2.new(-330, -20) } },
  { Name = "East1", Points = { Vector2.new(28, -880), Vector2.new(90, -905), Vector2.new(230, -905), Vector2.new(260, -770), Vector2.new(280, -650), Vector2.new(290, -600) } },
  { Name = "East2", Points = { Vector2.new(260, -770), Vector2.new(250, -480), Vector2.new(300, -300), Vector2.new(350, -120), Vector2.new(375, 40) } },
 },
 -- Animals are anchored decoration. Each client animates the ones near it from the server time (no replication, no server cost).
 AnimalArea = { NearShare = 0.5, NearZMax = 1500 }, -- half of the herd lives within the first 1500 studs
 Animals = {
  { Source = "Bison", Count = 3, Radius = 14, Speed = 1.2 }, { Source = "BisonB", Count = 3, Radius = 14, Speed = 1.2 },
  { Source = "Elk", Count = 3, Radius = 16, Speed = 1.8 }, { Source = "ElkB", Count = 3, Radius = 16, Speed = 1.8 },
  { Source = "CowMoose", Count = 4, Radius = 14, Speed = 1.5 }, { Source = "BullMoose", Count = 4, Radius = 14, Speed = 1.5 },
  { Source = "Deer", Count = 8, Radius = 18, Speed = 2, ForwardYaw = math.rad(90) },
  { Source = "Bear", Count = 3, Radius = 10, Speed = 1.2 }, { Source = "BlackBear", Count = 2, Radius = 10, Speed = 1.2 },
 },
 ShoreAnimals = {
  { Source = "Caiman", Offset = Vector2.new(-122, 40), Radius = 0, Speed = 0 },
  { Source = "SnappingTurtle", Offset = Vector2.new(-116, -35), Radius = 0, Speed = 0 },
 },
 AnimalMotion = { Distance = 90, CheckSeconds = 0.5, BobHeight = 0.08, BobSpeed = 1.6 }, -- client: animals within Distance move
}

-- Economy -------------------------------------------------------------
Config.CashTickSeconds = 1

-- Helpers -------------------------------------------------------------
function Config.GetStageLength(stage: number): number
	return Config.StageLengths[stage]
end

--- Tier of the card a Golden Cage drops for a stage.
function Config.GetTierAbove(stage: number, capTier: string): string
	local index = table.find(Config.TierOrder, Config.StageTier[stage]) :: number
	local cap = table.find(Config.TierOrder, capTier) :: number
	return Config.TierOrder[math.min(index + 1, cap)]
end
function Config.GetGoldenTier(stage: number): string
	return Config.GetTierAbove(stage, Config.GoldenMaxTier)
end

Config.Leaderboards = {
 RefreshSeconds=60, Top=10, ScorePrecision=1e9, StorePrefix="FootballerRank_v1_",
 BoardSize=Vector3.new(22,18,1), BoardSpacing=25, EdgeInset=3,
}

Config.Trails = {
 RequestGap=.4, Lifetime=.45, Height=.65, BackOffset=.55,
 -- Multiplier = Speed Points gained per second on the treadmill (times the treadmill's own); bought in order.
 Catalog={
  {Id="None", Name="No Trail", Cost=0, Multiplier=1},
  {Id="Spark", Name="Spark", Rarity="Common", Cost=2500, Multiplier=2, Color=Color3.fromRGB(255,236,150)},
  {Id="Ripple", Name="Ripple", Rarity="Common", Cost=4800, Multiplier=4, Color=Color3.fromRGB(120,200,255)},
  {Id="MintStreak", Name="Mint Streak", Rarity="Uncommon", Cost=9300, Multiplier=8, Color=Color3.fromRGB(117,255,199)},
  {Id="EmberTrail", Name="Ember Trail", Rarity="Uncommon", Cost=18000, Multiplier=16, Color=Color3.fromRGB(255,146,67)},
  {Id="Aurora", Name="Aurora", Rarity="Rare", Cost=43000, Multiplier=40, Color=Color3.fromRGB(140,157,255)},
  {Id="CometTail", Name="Comet Tail", Rarity="Rare", Cost=100000, Multiplier=100, Color=Color3.fromRGB(150,230,255)},
  {Id="PrismRibbon", Name="Prism Ribbon", Rarity="Epic", Cost=250000, Multiplier=250, Color=Color3.fromRGB(215,120,255)},
  {Id="VoidWake", Name="Void Wake", Rarity="Epic", Cost=560000, Multiplier=600, Color=Color3.fromRGB(120,70,200)},
  {Id="SolarFlare", Name="Solar Flare", Rarity="Legendary", Cost=2100000, Multiplier=4000, Color=Color3.fromRGB(255,190,60)},
  {Id="Nebula", Name="Nebula", Rarity="Mythic", Cost=4900000, Multiplier=10000, Color=Color3.fromRGB(255,90,170)},
  {Id="CelestialBlaze", Name="Celestial Blaze", Rarity="Celestial", Cost=12000000, Multiplier=25000, Color=Color3.fromRGB(120,240,255)},
 },
}


Config.Football = {
 KickRange = 9, KickSpeed = 58, KickLift = 4, KickCooldown = 0.4,
 ResetMargin = 25, ResetBelow = 12, ResetInterval = 0.5,
}

Config.FootballLobby = {
 Modes = {
  ["4v4"] = { Starters = 4, RewardMultiplier = 1, Rows = {1, 2, 1} },
  ["11v11"] = { Starters = 11, RewardMultiplier = 3, Rows = {1, 4, 3, 3} },
 },
 EntryRange = 12, LobbyRange = 35, InviteSeconds = 30, SelectionSeconds = 90,
 StagingSeconds = 180, RequestGap = 0.25, TeamDepth = 0.42, TeamWidth = 0.8,
}

return Config
