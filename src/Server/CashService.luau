--[[
	CashService: adds income to the player's Cash balance (PlayerStats) and runs the per-second income tick.
	Income each tick = sum of CashPerSecond of cards placed on the player's plot.
	AddCash() is the entry point for shops/rewards.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Stats = require(script.Parent.PlayerStats)

local CashService = {}
local remainder = {}

local PlotService, SlotService -- injected in Init

-- Income multiplier from the 2x Cash pass (the attribute is set by Purchases).
function CashService.Boost(player: Player?): number
	return player and player:GetAttribute("PassOwned_" .. Config.CashPass.Id) and Config.CashPass.Multiplier or 1
end

function CashService.AddCash(player: Player, amount: number)
	Stats.Add(player,"Cash",amount)
end

function CashService.Init(plotService, slotService)
	PlotService = plotService
	SlotService = slotService

	Players.PlayerAdded:Connect(Stats.Setup)
 Players.PlayerRemoving:Connect(function(player) remainder[player]=nil end)
	for _, p in ipairs(Players:GetPlayers()) do
		Stats.Setup(p)
	end

	task.spawn(function()
		while true do
			task.wait(Config.CashTickSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				local plot = PlotService.GetPlot(player)
				if plot and player:GetAttribute("DataReady")~=false then
					local income = SlotService.GetPlotIncome(plot) * Config.CashTickSeconds * CashService.Boost(player)
					if income > 0 then
						local pending=(remainder[player] or 0)+income
      local whole=math.floor(pending)
      remainder[player]=pending-whole
      CashService.AddCash(player, whole)
					end
				end
			end
		end
	end)
end

return CashService
