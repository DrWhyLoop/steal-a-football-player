--[[
	PromptFilter: hides the slot / lock prompts that do not apply to the local player.
	Purely cosmetic - the server re-checks every rule. Event-driven: prompts are only
	recomputed when a relevant attribute changes (plot OwnerUserId / LockState,
	slot CardName, or the player's CarriedCard). The server never touches these prompts' Enabled.
	  Owner:     SlotPrompt for (empty slot while carrying) or (filled slot with free hands); LockPrompt when Ready.
	  Non-owner: StealPrompt on a filled slot of an owned, unlocked plot, with free hands.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local PromptFilter = {}

local player = Players.LocalPlayer

local function refreshSlot(slot: BasePart)
	local plot = slot:FindFirstAncestorOfClass("Model") :: Model
	local ownerId = plot:GetAttribute("OwnerUserId")
	local isOwner = ownerId == player.UserId
	local filled = slot:GetAttribute("CardName") ~= nil
	local carrying = player:GetAttribute("CarriedCard") ~= nil
	slot.SlotPrompt.Enabled = isOwner and filled ~= carrying
	slot.StealPrompt.Enabled = ownerId ~= 0 and not isOwner and filled and not carrying
		and plot:GetAttribute("LockState") ~= "Locked"
end

local function refreshPlot(plot: Model)
	for _, slot in ipairs(plot.Slots:GetChildren()) do
		refreshSlot(slot)
	end
	plot.LockButton.LockPrompt.Enabled = plot:GetAttribute("OwnerUserId") == player.UserId
		and plot:GetAttribute("LockState") == "Ready"
end

function PromptFilter.Init()
	local plots = CollectionService:GetTagged("Plot")
	for _, plot in ipairs(plots) do
		for _, attribute in ipairs({ "OwnerUserId", "LockState" }) do
			plot:GetAttributeChangedSignal(attribute):Connect(function() refreshPlot(plot) end)
		end
		for _, slot in ipairs(plot.Slots:GetChildren()) do
			slot:GetAttributeChangedSignal("CardName"):Connect(function() refreshSlot(slot) end)
		end
		refreshPlot(plot)
	end
	player:GetAttributeChangedSignal("CarriedCard"):Connect(function()
		for _, plot in ipairs(plots) do refreshPlot(plot) end
	end)
end

return PromptFilter
