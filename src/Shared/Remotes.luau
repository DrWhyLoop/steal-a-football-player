--[[
	Remotes: single place that defines RemoteEvents.
	Server creates them; client waits for them.
	Add a name to NAMES to add a new remote (e.g. future client->server requests).
	Note: pickaxe hits do NOT need a remote - Tool.Activated replicates to the server
	(works on mouse, touch and gamepad).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
 "EyeLook",
 "RebirthRequest", -- client -> server: rebirth (validated against the Speed Points requirement)
 "RebirthStatus",  -- server -> client: message text
 "QuestRequest",   -- client -> server: ("Sync") or ("Claim", "Daily"|"Weekly", index)
 "QuestSync",      -- server -> client: {Tokens, DayLeft, WeekLeft, Daily, Weekly} (seconds left until the UTC resets)
 "TwistEvent",    -- server -> clients in a stage: ("Warn", position, radius, seconds) or ("Strike", position); lightning only, everything else is drawn from the server clock
 "StageArrival",  -- server -> client: (stage, cash) on the first arrival in a stage (once per account)
 "UpgradeRequest", -- client -> server: ("Buy", upgrade id); levels reach the client as Player attributes Upgrade_<id>
 "UpgradeStatus",  -- server -> client: message text
 "FootballRequest",
 "FootballLobby",
 "DropPlayer",
 "TreadmillRequest",
 "TreadmillStatus",
 "ToolRequest", -- client -> server: ("Buy"|"Equip"|"Premium", tool id) or ("Arm", "Right"|"Left"|"Both")
 "TrailRequest",
 "TrailStatus",
 "ToolStatus",  -- server -> client: message text
 "FeedbackRequest",
 "FeedbackStatus",
 "EggReveal", -- server -> nearby clients: (cage, luck, duration, serverStart, revealId); cosmetic only
 "SafeReturn",
 "UpgradeResult", -- server -> clicking client: (reason key, see Config.PlotSlots.Messages)
 "CollectResult", -- server -> collecting client: (slot, amount) for the press effect and the floating +$X
 "IndexRequest",  -- client -> server: ask for the index and daily-reward state (rate limited)
 "IndexSync",     -- server -> client: (index {id=bitmask}, claimed {tier=true}); full on request/join, deltas afterwards
 "DailyClaim",    -- client -> server: claim today's reward (validated by day on the server)
 "DailyStatus",   -- server -> client: {Ready, Streak, Reward}
	"Announcement", -- server -> one/all clients: (text: string)
	"Knockback",    -- server -> hit client: (velocity: Vector3), client applies it locally
}

local folder
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in ipairs(NAMES) do
		if not folder:FindFirstChild(name) then
			local r = Instance.new("RemoteEvent")
			r.Name = name
			r.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes")
end

local Remotes = {}
for _, name in ipairs(NAMES) do
	Remotes[name] = folder:WaitForChild(name)
end

return Remotes
