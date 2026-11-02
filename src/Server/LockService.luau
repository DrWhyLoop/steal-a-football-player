--[[
	LockService: the base lock. The owner presses the LockButton prompt on their plot:
	  Ready -> Locked (Config.LockDurationSeconds) -> Cooldown (Config.LockCooldownSeconds) -> Ready.
	While Locked, translucent barrier walls block everyone except the owner (collision groups
	Barrier_n / Owner_n) and a countdown shows above the plot. Non-owners already inside are moved out.
	The plot attribute LockState ("Ready" | "Locked" | "Cooldown") is what clients and SlotService read.
]]

local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local LockService = {}

local PlotService -- injected in Init
local lockEnds, lockReady = {}, {} -- [plot] = server time

local function barrierGroup(plot: Model): string
	return "Barrier_" .. plot:GetAttribute("PlotIndex")
end

local function ownerGroup(plot: Model): string
	return "Owner_" .. plot:GetAttribute("PlotIndex")
end

local function registerGroup(name: string)
	if not PhysicsService:IsCollisionGroupRegistered(name) then
		PhysicsService:RegisterCollisionGroup(name)
	end
end

function LockService.IsLocked(plot: Model): boolean
	return plot:GetAttribute("LockState") == "Locked"
end

local function setBarrier(plot: Model, active: boolean)
	for _, wall in ipairs(plot.Barrier:GetChildren()) do
		wall.CanCollide = active
		wall.Transparency = active and Config.LockBarrierTransparency or 1
	end
	plot.LockStatus.StatusGui.Enabled = active
end

local function reset(plot: Model)
	lockEnds[plot], lockReady[plot] = nil, nil
	setBarrier(plot, false)
	plot:SetAttribute("LockState", "Ready")
end

--- Move every non-owner standing on the plot out to the forecourt.
local function expelTrespassers(plot: Model, owner: Player)
	local base = plot.Base
	local half = base.Size / 2
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and player ~= owner then
			local offset = root.Position - base.Position
			if math.abs(offset.X) <= half.X and math.abs(offset.Z) <= half.Z then
				local x = math.sign(base.Position.X) * (Config.HallwayWidth / 2 - Config.LockExpelInset)
				char:PivotTo(CFrame.new(x, root.Position.Y, base.Position.Z))
			end
		end
	end
end

local function activate(plot: Model, owner: Player)
	local now = Workspace:GetServerTimeNow()
	lockEnds[plot] = now + Config.LockDurationSeconds
	lockReady[plot] = lockEnds[plot] + Config.LockCooldownSeconds
	setBarrier(plot, true)
	plot:SetAttribute("LockState", "Locked")
	expelTrespassers(plot, owner)
end

local function onTriggered(player: Player, button: BasePart)
	local plot = PlotService.GetPlotOfInstance(button)
	if not plot or PlotService.GetOwner(plot) ~= player or plot:GetAttribute("LockState") ~= "Ready" then return end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or (root.Position - button.Position).Magnitude > Config.InteractMaxDistance then return end
	activate(plot, player)
end

local function updateLocks()
	local now = Workspace:GetServerTimeNow()
	for plot, endsAt in pairs(lockEnds) do
		local state = plot:GetAttribute("LockState")
		if state == "Locked" then
			if now >= endsAt then
				setBarrier(plot, false)
				plot:SetAttribute("LockState", "Cooldown")
			else
				plot.LockStatus.StatusGui.Label.Text = ("LOCKED %ds"):format(math.ceil(endsAt - now))
			end
		elseif now >= lockReady[plot] then
			reset(plot)
		end
	end
end

-- Owner collision group ------------------------------------------------

local function applyOwnerGroup(player: Player)
	local plot = PlotService.GetPlot(player)
	local group = plot and ownerGroup(plot) or "Default"
	local char = player.Character
	if char then
		for _, descendant in ipairs(char:GetDescendants()) do
			if descendant:IsA("BasePart") then descendant.CollisionGroup = group end
		end
	end
end

local function onCharacterAdded(player: Player, char: Model)
	applyOwnerGroup(player)
	char.DescendantAdded:Connect(function(descendant) -- tools, accessories
		if descendant:IsA("BasePart") then
			local plot = PlotService.GetPlot(player)
			descendant.CollisionGroup = plot and ownerGroup(plot) or "Default"
		end
	end)
end

local function watchPlayer(player: Player)
	player.CharacterAdded:Connect(function(char) onCharacterAdded(player, char) end)
	if player.Character then onCharacterAdded(player, player.Character) end
end

function LockService.Init(plotService)
	PlotService = plotService

	for _, plot in ipairs(CollectionService:GetTagged("Plot")) do
		registerGroup(barrierGroup(plot))
		registerGroup(ownerGroup(plot))
		PhysicsService:CollisionGroupSetCollidable(barrierGroup(plot), ownerGroup(plot), false)
		for _, wall in ipairs(plot.Barrier:GetChildren()) do
			wall.CollisionGroup = barrierGroup(plot)
		end
		reset(plot)
	end

	for _, button in ipairs(CollectionService:GetTagged("LockButton")) do
		button.LockPrompt.Triggered:Connect(function(player) onTriggered(player, button) end)
	end

	PlotService.PlotAssigned.Event:Connect(function(_, player) applyOwnerGroup(player) end)
	PlotService.PlotFreed.Event:Connect(reset)
	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		watchPlayer(player)
	end

	task.spawn(function()
		while true do
			task.wait(Config.LockTickSeconds)
			updateLocks()
		end
	end)
end

return LockService
