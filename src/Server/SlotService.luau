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

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SlotService = {}

local PlotService, CardService, LockService -- injected in Init
local slotCards = {} -- [slotPart] = card part
local homeSlot = setmetatable({}, { __mode = "k" }) -- [card] = slot it was stolen from

local function refreshSlot(slot: BasePart, card: Part?)
	local name = card and card:GetAttribute("CardName")
	slot:SetAttribute("CardName", name)
	slot.SlotPrompt.ActionText = card and "Pick up" or "Place card"
	slot.SlotPrompt.ObjectText = name or "Slot " .. slot:GetAttribute("SlotIndex")
	slot.StealPrompt.ObjectText = name or "Slot " .. slot:GetAttribute("SlotIndex")
end

local function occupy(slot: BasePart, card: Part)
	card.CFrame = slot.CFrame * CFrame.new(0, (slot.Size.Y + card.Size.Y) / 2 + 0.1, 0)
	CardService.SetState(card, "Placed")
	slotCards[slot] = card
	homeSlot[card] = nil
	refreshSlot(slot, card)
end

local function isAliveAndNear(player: Player, slot: BasePart): boolean
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	return root ~= nil and humanoid ~= nil and humanoid.Health > 0
		and (root.Position - slot.Position).Magnitude <= Config.InteractMaxDistance
end

local function onOwnerTriggered(player: Player, slot: BasePart)
	local plot = PlotService.GetPlotOfInstance(slot)
	if not plot or PlotService.GetOwner(plot) ~= player or not isAliveAndNear(player, slot) then return end

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
	if not CardService.Carry(thief, card) then return end

	slotCards[slot] = nil
	homeSlot[card] = slot
	refreshSlot(slot, nil)
	Remotes.Announcement:FireClient(owner, Config.StealAlert:format(thief.DisplayName, card:GetAttribute("CardName")))
end

local function firstEmptySlot(plot: Model): BasePart?
	for _, slot in ipairs(plot.Slots:GetChildren()) do
		if not slotCards[slot] then return slot end
	end
	return nil
end

--- Put a dropped stolen card back into its owner's plot. Returns false if it should stay on the floor.
function SlotService.ReturnStolen(card: Part): boolean
	local home = homeSlot[card]
	homeSlot[card] = nil
	local plot = home and PlotService.GetPlotOfInstance(home)
	if not plot or not PlotService.GetOwner(plot) then return false end
	local target = slotCards[home] and firstEmptySlot(plot) or home
	if not target then return false end
	occupy(target, card)
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
		slot.SlotPrompt.Triggered:Connect(function(player) onOwnerTriggered(player, slot) end)
		slot.StealPrompt.HoldDuration = Config.StealHoldSeconds
		slot.StealPrompt.Triggered:Connect(function(player) onStealTriggered(player, slot) end)
	end
	PlotService.PlotFreed.Event:Connect(clearPlot)
end

return SlotService
