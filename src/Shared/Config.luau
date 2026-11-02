--[[
	Config: ALL gameplay tuning lives here. Shared by server and client.
	Change numbers here, not in services.
]]

local Config = {}

-- Hallway layout (read by the world builder; stage n is StageBaseLength + StageLengthStep*(n-1) long)
Config.StageCount = 12
Config.StageBaseLength = 40
Config.StageLengthStep = 10
Config.HallwayWidth = 80
Config.SlotsPerPlot = 10
Config.GroundY = 1 -- top surface of all floors

-- Tiers ---------------------------------------------------------------
Config.BaseWalkSpeed = 16

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

Config.CardPools = {
	Common    = { "Robot Tower", "Party Sprinter", "Long-Throw Launcher", "Everywhere Man" },
	Rare      = { "Calm Tower", "Reflex Wall", "Lion Mane", "Wing Spark" },
	Epic      = { "Bicycle Bulldog", "Final Header", "Cut-Inside", "Dance Dribbler" },
	Legendary = { "Red Glide", "Banana Cannon", "Viking Engine", "Star Prodigy" },
	Mythic    = { "Meteor Nine", "Samba Grin", "Rainbow Fox", "Turbo Prince" },
	GOAT      = { "Crimson Demon", "Pocket Storm" },
}

-- Cubes ---------------------------------------------------------------
Config.CubeSize = 6
Config.CubeRespawnSeconds = 15
Config.CubeFlashSeconds = 0.08
Config.CubeHP = { 3, 5, 8, 12, 18, 25, 35, 50, 70, 100, 140, 300 }       -- per stage
Config.CubeCountPerStage = { 6, 6, 7, 7, 8, 8, 9, 10, 10, 11, 12, 1 }    -- per stage
Config.CubeColumnX = { -30, 30, -16, 16 } -- spawn columns (fill order); centre lane stays free

-- GOAT event cube: the only source of GOAT cards. One cube per interval + announcement.
Config.GoatStage = 12
Config.GoatSpawnIntervalSeconds = 120 -- TESTING VALUE. Set to 1200 (20 minutes) for live.
Config.GoatAnnouncement = "A GOAT CUBE has appeared in STAGE 12!"

-- Golden Cube event: one at a random point of a random stage in [Min, Max]
Config.GoldenIntervalSeconds = 300
Config.GoldenInitialDelaySeconds = 300
Config.GoldenMinStage = 4
Config.GoldenMaxStage = 11
Config.GoldenHPMultiplier = 3
Config.GoldenMaxTier = "Mythic" -- drops one tier above the stage, capped here
Config.GoldenColor = Color3.fromRGB(255, 200, 0)
Config.GoldenEdgeMargin = 6
Config.GoldenMinSpacing = 8       -- min distance to other cubes
Config.GoldenSpawnAttempts = 10
Config.GoldenAnnouncement = "A GOLDEN CUBE appeared in STAGE %d!"

Config.AnnouncementSeconds = 6

-- Pickaxe -------------------------------------------------------------
Config.PickaxeName = "Pickaxe"       -- Tool in StarterPack
Config.PickaxeDamage = 1             -- fixed damage per hit
Config.SwingCooldown = 0.45          -- seconds between hits (server enforced)
Config.PickaxeRange = 12             -- max studs from player root to cube centre
Config.PickaxeCloseRange = 6         -- cubes this close always count, even if not facing
Config.PickaxeFacingDot = 0.3        -- min dot(look, toTarget) for "in front" (1 = dead ahead)
Config.PickaxeSounds = {             -- placeholder built-in clips
	Hit = "rbxasset://sounds/metal.mp3",
	Miss = "rbxasset://sounds/swordslash.wav",
}

-- Cards ---------------------------------------------------------------
Config.CardSize = Vector3.new(2.5, 3.5, 0.4)
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
Config.StealHoldSeconds = 1.5
Config.StealAlert = "%s is stealing your %s!" -- (thief name, card name)

-- Base lock -----------------------------------------------------------
Config.LockDurationSeconds = 60
Config.LockCooldownSeconds = 30      -- starts when the lock expires
Config.LockTickSeconds = 1
Config.LockBarrierHeight = 24
Config.LockBarrierTransparency = 0.5
Config.LockBarrierColor = Color3.fromRGB(80, 170, 255)
Config.LockExpelInset = 10            -- trespassers are moved this far inside the forecourt

-- Guards (per stage, index = stage number) -------------------------------
Config.GuardCountPerStage = { 1, 1, 2, 2, 2, 3, 3, 4, 4, 4, 5, 5 }
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

-- Economy -------------------------------------------------------------
Config.CashTickSeconds = 1

-- Helpers -------------------------------------------------------------
function Config.GetStageLength(stage: number): number
	return Config.StageBaseLength + Config.StageLengthStep * (stage - 1)
end

--- Tier of the card a Golden Cube drops for a stage.
function Config.GetGoldenTier(stage: number): string
	local index = table.find(Config.TierOrder, Config.StageTier[stage]) :: number
	local cap = table.find(Config.TierOrder, Config.GoldenMaxTier) :: number
	return Config.TierOrder[math.min(index + 1, cap)]
end

function Config.PickCardName(tier: string): string
	local pool = Config.CardPools[tier]
	return pool[math.random(1, #pool)]
end

return Config
