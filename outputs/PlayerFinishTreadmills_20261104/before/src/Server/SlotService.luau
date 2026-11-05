--[[
	SlotService: placing, picking up and stealing cards on plot slots (parts tagged "Slot").
	- Owner + empty slot + carrying      -> place (SlotPrompt).
	- Owner + filled slot + hands free   -> pick back up (SlotPrompt).
	- Non-owner + filled slot + hands free + plot not locked -> steal (StealPrompt, hold).
	  The thief carries the card; placing it in their own slot transfers ownership.
	- A stolen card that gets dropped goes back to its owner (ReturnStolen).
	The client hides prompts that do not apply (PromptFilter), but every rule is enforced here.
	Slot attribute CardName mirrors the slot content for the client.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local LineOfSight = require(script.Parent.LineOfSight)

local SlotService = {}

local PlotService, CardService, LockService -- injected in Init
local slotCards = {} -- [slotPart] = card part
local homeSlot = {} -- [stolen card] = reserved original slot
local reserved = {} -- [slot] = stolen card
local upgradeUntil = {} -- [slot] = next purchase time

local function upgradeCost(card)
 local level=card:GetAttribute("UpgradeLevel") or 0
 return math.ceil(card:GetAttribute("BaseCashPerSecond")*Config.PlotSlots.FirstCostSeconds*Config.PlotSlots.CostGrowth^level)
end

local function refreshSlot(slot: BasePart, card: Part?)
	local name = card and card:GetAttribute("CardName")
	local beingStolen = reserved[slot] ~= nil
	slot:SetAttribute("Reserved", beingStolen)
	slot.ReservationGui.Enabled = beingStolen
	slot:SetAttribute("CardName", name)
	slot.SlotPrompt.ActionText = card and "Pick up" or "Place player"
	slot.SlotPrompt.ObjectText = beingStolen and "BEING STOLEN" or name or Config.PlotSlots.EmptyText
	slot.StealPrompt.ObjectText = name or Config.PlotSlots.EmptyText
 local panel=slot.EarningsPanel.Value
 panel.InfoGui.Label.Text=beingStolen and "BEING STOLEN" or card and ("$%.2f/sec"):format(card:GetAttribute("CashPerSecond")) or Config.PlotSlots.EmptyText
 local upgrade=slot.UpgradePanel.Value
 local level=card and card:GetAttribute("UpgradeLevel") or 0
 slot:SetAttribute("UpgradeLevel",level)
 upgrade.InfoGui.Label.Text=card and (level>=Config.PlotSlots.MaxLevel and "MAX LEVEL" or ("Lv %d | $%d\nNext: $%.2f/sec"):format(level,upgradeCost(card),card:GetAttribute("CashPerSecond")*Config.PlotSlots.IncomeGrowth)) or "Place a player"
 upgrade.UpgradePrompt.ObjectText=card and ("Level %d"):format(level) or Config.PlotSlots.EmptyText
 upgrade.UpgradePrompt.ActionText=card and ("Upgrade ($%d)"):format(upgradeCost(card)) or "Upgrade"
end

local function clearStolen(card: Part)
	local home = homeSlot[card]
	homeSlot[card] = nil
	card:SetAttribute("OriginalOwnerUserId", nil)
	if home and reserved[home] == card then
		reserved[home] = nil
		refreshSlot(home, slotCards[home])
	end
end

local function occupy(slot: BasePart, card: Part)
 if card:GetAttribute("UpgradeLevel")==nil then card:SetAttribute("UpgradeLevel",0) card:SetAttribute("BaseCashPerSecond",card:GetAttribute("CashPerSecond")) end
	card.CFrame = slot.CFrame * CFrame.new(0, (slot.Size.Y + card.Size.Y) / 2 + Config.PlotSlots.DisplayClearance, 0)
	CardService.SetState(card, "Placed")
	slotCards[slot] = card
	clearStolen(card)
	refreshSlot(slot, card)
end

local function isAliveAndNear(player: Player, slot: BasePart): boolean
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	return root ~= nil and humanoid ~= nil and humanoid.Health > 0
		and (root.Position - slot.Position).Magnitude <= Config.PlotSlots.InteractDistance
end

local function onUpgrade(player: Player,slot: BasePart)
 local plot=PlotService.GetPlotOfInstance(slot)
 local card=slotCards[slot]
 if not plot or PlotService.GetOwner(plot)~=player or reserved[slot] or not card or not isAliveAndNear(player,slot) then return end
 local level=card:GetAttribute("UpgradeLevel") or 0
 if level>=Config.PlotSlots.MaxLevel or os.clock()<(upgradeUntil[slot] or 0) then return end
 local stats=player:FindFirstChild("leaderstats")
 local cash=stats and stats:FindFirstChild("Cash")
 local cost=upgradeCost(card)
 if not cash or cash.Value<cost then return end
 upgradeUntil[slot]=os.clock()+Config.PlotSlots.UpgradeCooldown
 cash.Value-=cost
 card:SetAttribute("UpgradeLevel",level+1)
 CardService.SetIncome(card,card:GetAttribute("BaseCashPerSecond")*Config.PlotSlots.IncomeGrowth^(level+1))
 refreshSlot(slot,card)
end

local function onOwnerTriggered(player: Player, slot: BasePart)
	local plot = PlotService.GetPlotOfInstance(slot)
	if not plot or PlotService.GetOwner(plot) ~= player or reserved[slot] or not isAliveAndNear(player, slot) then return end

	local placed = slotCards[slot]
	if placed then
		if CardService.Carry(player, placed) then
			slotCards[slot] = nil
			refreshSlot(slot, nil)
		end
		return
	end

	local card = CardService.Release(player)
	if card then occupy(slot, card) end
end

local function onStealTriggered(thief: Player, slot: BasePart)
	local plot = PlotService.GetPlotOfInstance(slot)
	local owner = plot and PlotService.GetOwner(plot)
	local card = slotCards[slot]
	if not owner or owner == thief or not card or LockService.IsLocked(plot) or not isAliveAndNear(thief, slot) then return end
	if not LineOfSight.IsClear(thief.Character, slot, slot.Position) then return end
	if not CardService.Carry(thief, card) then return end

	slotCards[slot] = nil
	homeSlot[card] = slot
	reserved[slot] = card
	card:SetAttribute("OriginalOwnerUserId", owner.UserId)
	refreshSlot(slot, nil)
	Remotes.Announcement:FireClient(owner, Config.StealAlert:format(thief.DisplayName, card:GetAttribute("CardName")))
end

--- Recover only to the reserved slot while the original owner still owns the plot.
function SlotService.ReturnStolen(card: Part): boolean
	local home = homeSlot[card]
	local userId = card:GetAttribute("OriginalOwnerUserId")
	local owner = userId and Players:GetPlayerByUserId(userId)
	local plot = home and PlotService.GetPlotOfInstance(home)
	local canReturn = owner and plot and PlotService.GetOwner(plot) == owner
		and reserved[home] == card and not slotCards[home]
	clearStolen(card)
	if not canReturn then return false end
	occupy(home, card)
	return true
end

--- Total cash/sec of all cards placed on a plot.
function SlotService.GetPlotIncome(plot: Model): number
	local total = 0
	for _, slot in ipairs(plot.Slots:GetChildren()) do
		local card = slotCards[slot]
		if card then total += card:GetAttribute("CashPerSecond") end
	end
	return total
end

--- Remove all placed cards from a plot (used when the owner leaves).
local function clearPlot(plot: Model)
	for _, slot in ipairs(plot.Slots:GetChildren()) do
		if reserved[slot] then clearStolen(reserved[slot]) end
		local card = slotCards[slot]
		if card then
			slotCards[slot] = nil
			card:Destroy()
			refreshSlot(slot, nil)
		end
	end
end

function SlotService.Init(plotService, cardService, lockService)
	PlotService = plotService
	CardService = cardService
	LockService = lockService

	for _, slot in ipairs(CollectionService:GetTagged("Slot")) do
		local gui = Instance.new("BillboardGui")
		gui.Name = "ReservationGui"
		gui.Size = UDim2.fromOffset(Config.ReservationLabelSize.X, Config.ReservationLabelSize.Y)
		gui.StudsOffset = Config.ReservationLabelOffset
		gui.MaxDistance = Config.ReservationLabelMaxDistance
		gui.Enabled = false
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "BEING STOLEN"
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = Config.Tiers.GOAT.Color
		label.Parent = gui
		gui.Parent = slot
		refreshSlot(slot, slotCards[slot])
		slot.StealPrompt.RequiresLineOfSight = true
		slot.SlotPrompt.Triggered:Connect(function(player) onOwnerTriggered(player, slot) end)
  slot.UpgradePanel.Value.UpgradePrompt.Triggered:Connect(function(player) onUpgrade(player,slot) end)
		slot.StealPrompt.HoldDuration = Config.StealHoldSeconds
		slot.StealPrompt.Triggered:Connect(function(player) onStealTriggered(player, slot) end)
	end
	PlotService.PlotFreed.Event:Connect(clearPlot)
end

return SlotService
