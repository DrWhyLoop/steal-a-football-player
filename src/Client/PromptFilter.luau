--[[
	PromptFilter: hides the slot prompts that do not apply to the local player.
	Purely cosmetic - the server re-checks every rule. Event-driven: prompts are only
	recomputed when a relevant attribute changes (plot OwnerUserId,
	slot CardName, or the player's CarriedCard). The server never touches these prompts' Enabled.
	  Owner:     SlotPrompt for (empty slot while carrying) or (filled slot with free hands).
	  Non-owner: StealPrompt on a filled slot of an owned plot, with free hands.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local PlotWatch = require(script.Parent.PlotWatch)
local PromptFilter = {}

local player = Players.LocalPlayer

local function refreshSlot(slot: BasePart)
	local plot = slot:FindFirstAncestorOfClass("Model") :: Model
	local ownerId = plot:GetAttribute("OwnerUserId")
	local isOwner = ownerId == player.UserId
	local filled = slot:GetAttribute("CardName") ~= nil
	local carrying = player:GetAttribute("CarriedCard") ~= nil
	local reserved = slot:GetAttribute("Reserved") == true
	slot.UpgradePanel.Value.UpgradePrompt.Enabled = isOwner and filled and not reserved and (slot:GetAttribute("UpgradeLevel") or 0)<Config.PlotSlots.MaxLevel
 slot.SlotPrompt.Enabled = isOwner and not reserved and filled ~= carrying
	slot.StealPrompt.Enabled = ownerId ~= 0 and not isOwner and filled and not carrying and not reserved
end

local function refreshPlot(plot: Model)
	for _, slot in ipairs(plot.Slots:GetChildren()) do
		refreshSlot(slot)
	end
end

function PromptFilter.Init()
	PlotWatch.Each(function(plot)
		plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function() refreshPlot(plot) end)
		for _, slot in ipairs(plot.Slots:GetChildren()) do
			for _, attribute in ipairs({ "CardName", "Reserved", "UpgradeLevel" }) do
				slot:GetAttributeChangedSignal(attribute):Connect(function() refreshSlot(slot) end)
			end
		end
		refreshPlot(plot)
	end)
	player:GetAttributeChangedSignal("CarriedCard"):Connect(function()
		for _, plot in ipairs(CollectionService:GetTagged("Plot")) do refreshPlot(plot) end
	end)
end

return PromptFilter
