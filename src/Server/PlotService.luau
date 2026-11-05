--[[
	PlotService: assigns one plot (Workspace/Greybox/Plots/Plot_n) per player.
	- Sets the owner's name on the sign and OwnerUserId attribute on the plot.
	- Sets player.RespawnLocation to the plot's PlotSpawn.
	- Fires PlotFreed(plot, player) BEFORE the plot is released so other services can clean up.
	Future hook: stealing/guards read GetOwner(plot) from here.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local PlotService = {}

PlotService.PlotAssigned = Instance.new("BindableEvent") -- (plot, player)
PlotService.PlotFreed = Instance.new("BindableEvent")    -- (plot, player)

local plots = {}       -- sorted list of plot Models
local ownerOfPlot = {} -- [plot] = Player
local plotOfPlayer = {} -- [Player] = plot

local function setSign(plot, text)
	local sign = plot:FindFirstChild("Sign")
	local label = sign and sign:FindFirstChild("SurfaceGui") and sign.SurfaceGui:FindFirstChild("Label")
	if label then
		label.Text = text
	end
end

function PlotService.GetPlots()
 return table.clone(plots)
end

function PlotService.GetPlot(player: Player): Model?
	return plotOfPlayer[player]
end

function PlotService.GetOwner(plot: Model): Player?
	return ownerOfPlot[plot]
end

function PlotService.GetPlotOfInstance(inst: Instance): Model?
	local cur = inst
	while cur do
		if CollectionService:HasTag(cur, "Plot") then
			return cur :: Model
		end
		cur = cur.Parent
	end
	return nil
end

local function assign(player: Player)
	if plotOfPlayer[player] then return end
	for _, plot in ipairs(plots) do
		if not ownerOfPlot[plot] then
			ownerOfPlot[plot] = player
			plotOfPlayer[player] = plot
			plot:SetAttribute("OwnerUserId", player.UserId)
			setSign(plot, player.DisplayName .. "'s Base")

			local spawn = plot:FindFirstChild("PlotSpawn")
			if spawn then
				player.RespawnLocation = spawn
				-- If character already exists (script started late), move it
				local char = player.Character
				if char and char.PrimaryPart then
					char:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
				end
			end
			PlotService.PlotAssigned:Fire(plot, player)
			return
		end
	end
	warn(("[PlotService] No free plot for %s"):format(player.Name))
end

local function release(player: Player)
	local plot = plotOfPlayer[player]
	if not plot then return end
	if PlotService.BeforeRelease then PlotService.BeforeRelease(player) end
	PlotService.PlotFreed:Fire(plot, player) -- listeners clear placed cards
	ownerOfPlot[plot] = nil
	plotOfPlayer[player] = nil
	plot:SetAttribute("OwnerUserId", 0)
	setSign(plot, "Free Plot")
end

function PlotService.Init()
	for _, plot in ipairs(CollectionService:GetTagged("Plot")) do
		if plot:IsDescendantOf(workspace.Greybox.Plots) then table.insert(plots, plot) end
	end
	table.sort(plots, function(a, b)
		return (a:GetAttribute("PlotIndex") or 0) < (b:GetAttribute("PlotIndex") or 0)
	end)
	if #plots == 0 then
		warn("[PlotService] No plots tagged 'Plot' found in Workspace/Greybox")
	end
	for _, plot in ipairs(plots) do
		plot:SetAttribute("OwnerUserId", 0)
		setSign(plot, "Free Plot")
	end

	Players.PlayerAdded:Connect(assign)
	Players.PlayerRemoving:Connect(release)
	for _, p in ipairs(Players:GetPlayers()) do
		assign(p)
	end
end

return PlotService
