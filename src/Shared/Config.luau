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
-- Cage break: the server rolls the result at once and destroys the cage. Nearby clients show a glowing blob in its place for GlowSeconds (it swells
-- to GlowScale, pulses and jitters harder towards the end) with a luck counter ticking up to the rolled luck, then a burst; the character
-- appears when the glow ends. Everything here is cosmetic and runs on the client.
Config.Reveal = { GlowSeconds=4.5, GlowScale=1.6, PulseStart=2, PulseEnd=9, JitterStart=.02, JitterEnd=.14, SparkRateStart=8, SparkRateEnd=60,
 TickStart=2, TickEnd=14, TickSoundId="rbxasset://sounds/electronicpingshort.wav", TickVolume=.35, CounterHeight=3, CounterColor=Color3.fromRGB(110,255,140),
 PopSeconds=.3, PopSize=16, LuckyPopSize=26, ConfettiCount=45, RayCount=12, LuckyRayCount=22, RayLength=26, RayColorLucky=Color3.fromRGB(255,215,0),
 RiseSeconds=.35, StartScale=.9, LuckyScale=1.25, PopTextSeconds=1.4, PopTextHeight=7,
 BeamSeconds=.9, BeamHeight=60, BeamWidth=3, PopSoundId="rbxasset://sounds/impact_explosion_03.mp3", PopSoundVolume=.9, BreakerPrioritySeconds=3,
 ShakeSeconds=.35, ShakeDistance=90, ShakeStrength={Rare=.15,Epic=.25,Legendary=.4,Mythic=.55,GOAT=.8},
 DisplayHeight=5, SafeCelebrationSeconds=1.4, SafeCheckSeconds=0.2, SafeMargin=2,
 MaxDistance=100, MaxConcurrent=3, SafeColor=Color3.fromRGB(100,255,165) }

-- Card variants. Gold/Diamond are exclusive (Diamond checked first); Giant is an independent roll. Income multipliers stack.
Config.Variants = { Gold={Income=2,Tint=Color3.fromRGB(255,200,60)}, Diamond={Income=5,Tint=Color3.fromRGB(235,250,255),Glow=Color3.fromRGB(120,220,255),GlowFill=0.5}, SparkleRate=2 }
Config.GiantVariant = { Income=3, Size=1.5 }
Config.VariantOdds = { Gold=0.05, Diamond=0.005, Giant=0.02 }
-- Luck: every break rolls a luck value L (the counter on screen). A normal cage rolls Min + (Max - Min) * r^Power; a Lucky Cage rolls LuckyMin..LuckyMax.
-- The income roll is u = random()^(1/L) (L = 1 is uniform, more luck pushes towards 1) and the card's income factor is Min + (Max - Min) * u from its
-- IncomeRange (a roster entry may set its own IncomeRange = {Min=, Max=}; otherwise the tier's). Each tier range averages 1.0 at normal luck.
Config.Luck = { Min=1, Max=1.5, Power=2, LuckyMin=3, LuckyMax=4, Step=.1 } -- Step: the counter shows one decimal, so L is rounded to it
Config.IncomeRange = { Common={Min=.79,Max=1.19}, Rare={Min=.73,Max=1.23}, Epic={Min=.68,Max=1.28}, Legendary={Min=.62,Max=1.32}, Mythic={Min=.57,Max=1.37}, GOAT={Min=.46,Max=1.46} }
-- Pop text in the burst: LUCKY! only for a Lucky Cage; the variants have their own.
Config.PopText = { Lucky={Text="LUCKY!",Color=Color3.fromRGB(255,215,0)}, Gold={Text="GOLD!",Color=Config.Variants.Gold.Tint},
 Diamond={Text="DIAMOND!",Color=Config.Variants.Diamond.Glow}, Giant={Text="GIANT!",Color=Color3.fromRGB(255,140,40)} }
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

-- Plaza NPCs (Client/NpcMotion.luau): anchored, harmless, animated locally. Routes are offsets from each model's Home attribute, walked in a loop.
-- R15 uses NPC 1's own animations (idle 742637544, walk 742638842) plus Roblox's R15 wave; R6 uses Roblox's default R6 set.
Config.Npc = {
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
Config.StageInfo = {
 { Name = "Training Grounds", Difficulty = "Easy", Points = 0 }, { Name = "Clover Park", Difficulty = "Easy", Points = 330 },
 { Name = "Sandlot Yard", Difficulty = "Medium", Points = 2560 }, { Name = "Stone Quarry", Difficulty = "Medium", Points = 4210 },
 { Name = "Lantern Alley", Difficulty = "Medium", Points = 72200 }, { Name = "Mossy Ruins", Difficulty = "Hard", Points = 252000 },
 { Name = "Rust Harbor", Difficulty = "Hard", Points = 1630000 }, { Name = "Ember Works", Difficulty = "Hard", Points = 68500000 },
 { Name = "Frost Terrace", Difficulty = "Insane", Points = 828000000 }, { Name = "Neon Arcade", Difficulty = "Insane", Points = 6070000000 },
 { Name = "Storm Dome", Difficulty = "Impossible", Points = 31900000000 }, { Name = "Golden Colosseum", Difficulty = "Impossible", Points = 50400000000 },
}
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
Config.CardLabels = {Distance=60,HeadClearance=1.6,Width=230,Height=92,RefreshSeconds=0.25,StatusColor=Color3.fromRGB(255,190,90),IncomeColor=Color3.fromRGB(120,255,150)}
Config.DropPlayer = {Forward=4,RequestCooldown=.4,SafeCargoLimit=30}
Config.CardRestHeight = 0.6          -- gap between dropped card and floor
Config.CarryOffset = Vector3.new(0, 3.2, 0) -- above the Head
Config.PickupHoldSeconds = 0.3
Config.PickupPromptDistance = 8
Config.PickupMaxDistance = 20        -- server-side sanity check
Config.InteractMaxDistance = 25      -- server-side sanity check (slots, lock button)
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

-- Base lock -----------------------------------------------------------
Config.LockDurationSeconds = 60
Config.LockCooldownSeconds = 30      -- starts when the lock expires
Config.LockTickSeconds = 1
Config.LockBarrierHeight = 36
Config.LockBarrierTransparency = 0.5
Config.LockBarrierColor = Color3.fromRGB(80, 170, 255)
Config.LockExpelInset = 10            -- trespassers are moved this far inside the forecourt

-- Guards (per stage, index = stage number) -------------------------------
Config.GuardCountPerStage = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 }
Config.GuardChaseSpeed    = { 12.8, 20.8, 33.6, 46.4, 60.8, 74.4, 87.2, 94.3, 112, 128.2, 144, 144 } -- 80% of the stage's recommended speed; Stages 8-12 trimmed (at most 10%) where the run clip cannot keep up at AnimSpeedMax
Config.GuardPatrolSpeedFactor = 0.7   -- patrol speed = chase speed * factor
Config.GuardSize = Vector3.new(3, 6, 2)
Config.GuardHeadSize = 2
Config.GuardColor = Color3.fromRGB(200, 40, 40)
Config.GuardMinimumHeight = 12
Config.GuardVisualScale = 1.65
Config.GuardPickupChaseMultiplier = 1.15
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
 PlotLockOffset = 13, SlotThickness = 0.18,
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
 StandHeight = 3.2, StandSideOffset = 2.5, StandForwardOffset = 1.2, UpgradeButtonColor = Color3.fromRGB(255, 200, 30),
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
Config.Index={PerPage=8,VariantOrder={"Gold","Diamond"},
 TierRewards={Common=500,Rare=2500,Epic=12500,Legendary=60000,Mythic=300000,GOAT=2000000}} -- provisional, one-time per tier
Config.Daily={BaseCash=500,StepCash=250,CapDays=7,ClaimCooldownSeconds=2,RefreshSeconds=60} -- reward = Base + Step*(min(streak,CapDays)-1)
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
