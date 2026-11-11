-- Plots are Persistent but still arrive after the game has loaded. Each(fn) calls fn(plot) for every plot tagged "Plot"
-- once the plot and all of its slots (with their pad and button references) are present on this client.
local CS = game:GetService("CollectionService")
local Config = require(game.ReplicatedStorage.Shared.Config)

local PlotWatch = {}

local function ready(plot: Model): boolean
	local slots = plot:FindFirstChild("Slots")
	if not slots or #slots:GetChildren() < Config.SlotsPerPlot then return false end
	for _, slot in slots:GetChildren() do
		for _, name in {"UpgradePanel", "CollectPad"} do
			local ref = slot:FindFirstChild(name)
			if not (ref and ref.Value) then return false end
		end
	end
	return true
end

function PlotWatch.Each(fn: (Model) -> ())
	local function start(plot: Model)
		task.spawn(function()
			while not ready(plot) do task.wait(0.1) end
			fn(plot)
		end)
	end
	for _, plot in CS:GetTagged("Plot") do start(plot) end
	CS:GetInstanceAddedSignal("Plot"):Connect(start)
end

return PlotWatch
