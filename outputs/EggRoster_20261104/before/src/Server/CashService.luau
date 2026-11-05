--[[
	CashService: owns the "Cash" leaderstat and the per-second income tick.
	Income each tick = sum of CashPerSecond of cards placed on the player's plot.
	Future hooks: AddCash() for shops/rewards; replace the leaderstat with saved data later.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local CashService = {}
local remainder = {}

local PlotService, SlotService -- injected in Init

local function setup(player: Player)
	if player:FindFirstChild("leaderstats") then return end
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = 0
	cash.Parent = stats
	stats.Parent = player
end

function CashService.AddCash(player: Player, amount: number)
	local stats = player:FindFirstChild("leaderstats")
	local cash = stats and stats:FindFirstChild("Cash") :: IntValue?
	if cash then
		cash.Value += amount
	end
end

function CashService.Init(plotService, slotService)
	PlotService = plotService
	SlotService = slotService

	Players.PlayerAdded:Connect(setup)
 Players.PlayerRemoving:Connect(function(player) remainder[player]=nil end)
	for _, p in ipairs(Players:GetPlayers()) do
		setup(p)
	end

	task.spawn(function()
		while true do
			task.wait(Config.CashTickSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				local plot = PlotService.GetPlot(player)
				if plot then
					local income = SlotService.GetPlotIncome(plot) * Config.CashTickSeconds
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
