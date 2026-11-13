-- Permanent upgrades (Config.Upgrades). Levels live in profile.Upgrades and are mirrored to the player as attributes Upgrade_<id>, which the
-- income, speed, pad and luck code read through Shop.Bonus. Every purchase is validated here; Quest Tokens are never sold for Robux.
local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.Config)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local Data = require(script.Parent.PlayerData)
local Stats = require(script.Parent.PlayerStats)
local Quests = require(script.Parent.QuestService)
local U = Config.Upgrades
local Shop = {}
local nextRequest = {}

function Shop.Level(player: Player, id: string): number
	return player:GetAttribute("Upgrade_" .. id) or 0
end

--- Total bonus of an upgrade (Step x level); 0 without a player or before the profile is loaded.
function Shop.Bonus(player: Player?, id: string): number
	return player and Shop.Level(player, id) * U.ById[id].Step or 0
end

local function publish(player: Player, levels)
	for _, def in U.Defs do player:SetAttribute("Upgrade_" .. def.Id, levels[def.Id] or 0) end
end

local function buy(player: Player, id)
	local profile = Data.Get(player)
	local def = type(id) == "string" and U.ById[id]
	if not profile or not def or player:GetAttribute("DataReady") ~= true then return end
	local levels = profile.data.Upgrades
	local level = levels[id] or 0
	local cost = def.Costs[level + 1]
	if not cost then Remotes.UpgradeStatus:FireClient(player, "Max level") return end
	if def.Currency == "Tokens" then
		if not Quests.AddTokens(player, -cost) then Remotes.UpgradeStatus:FireClient(player, "Not enough tokens") return end
	elseif Stats.Get(player, "Cash") < cost then
		Remotes.UpgradeStatus:FireClient(player, "Not enough cash")
		return
	else
		Stats.Add(player, "Cash", -cost)
	end
	levels[id] = level + 1 -- no yield between the payment and the level
	Data.RecordPurchase(player, "Upgrade_" .. id .. "_" .. (level + 1), cost, def.Currency)
	publish(player, levels)
	Remotes.UpgradeStatus:FireClient(player, "")
	task.spawn(Data.RequestSave, player)
end

function Shop.Init()
	Remotes.UpgradeRequest.OnServerEvent:Connect(function(player, action, id)
		if action ~= "Buy" or (nextRequest[player] or 0) > os.clock() then return end
		nextRequest[player] = os.clock() + U.RequestGap
		buy(player, id)
	end)
	local function added(player: Player)
		player:GetAttributeChangedSignal("DataReady"):Connect(function()
			local profile = player:GetAttribute("DataReady") == true and Data.Get(player)
			if profile then publish(player, profile.data.Upgrades) end
		end)
	end
	Players.PlayerAdded:Connect(added)
	for _, player in Players:GetPlayers() do added(player) end
	Players.PlayerRemoving:Connect(function(player) nextRequest[player] = nil end)
end

return Shop
