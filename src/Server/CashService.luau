--[[
	CashService: adds income to the player's Cash balance (PlayerStats) and runs the per-second income tick.
	Each tick the plot's placed cards add their CashPerSecond to their own slot's pending cash (SlotService.Accrue);
	the owner collects it from the slot's pad.
	AddCash() is the entry point for shops/rewards.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Rebirth = require(ReplicatedStorage.Shared.Rebirth)
local Stats = require(script.Parent.PlayerStats)
local UpgradeShop = require(script.Parent.UpgradeShop)

local CashService = {}

local PlotService, SlotService -- injected in Init

-- Income multiplier: the 2x Cash pass (attribute set by Purchases) times the permanent rebirth multiplier and the Income upgrade.
function CashService.Boost(player: Player?): number
	if not player then return 1 end
	local pass = player:GetAttribute("PassOwned_" .. Config.CashPass.Id) and Config.CashPass.Multiplier or 1
	return pass * Rebirth.Income(player:GetAttribute("Rebirths") or 0) * (1 + UpgradeShop.Bonus(player, "Income"))
end

function CashService.AddCash(player: Player, amount: number)
	Stats.Add(player,"Cash",amount)
end

function CashService.Init(plotService, slotService)
	PlotService = plotService
	SlotService = slotService

	Players.PlayerAdded:Connect(Stats.Setup)
	for _, p in ipairs(Players:GetPlayers()) do
		Stats.Setup(p)
	end

	task.spawn(function()
		while true do
			task.wait(Config.CashTickSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				local plot = PlotService.GetPlot(player)
				if plot and player:GetAttribute("DataReady")~=false then
					SlotService.Accrue(plot, Config.CashTickSeconds, CashService.Boost(player))
				end
			end
		end
	end)
end

return CashService
