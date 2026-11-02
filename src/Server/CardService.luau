--[[
	CardService: creates cards, handles pickup, carrying, walk-speed penalty and dropping.
	Card part attributes: CardName, Tier, CashPerSecond, State ("World" | "Carried" | "Placed").
	One card carried per player. Server authoritative.
	Carry/Release are the only places carrying state changes. DropCarried is the single drop path
	(death, leave, pickaxe hit, guard hit); a stolen card is returned to its owner first.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local CardService = {}

local cardsFolder = Workspace:WaitForChild("Greybox"):WaitForChild("Cards")
local carried = {} -- [Player] = card part
local lastPos = {} -- [Player] = Vector3 (last known position while carrying)
local returnStolen -- fn(card): boolean, injected in Init; true if the card went back to its owner

local function getRoot(player: Player): BasePart?
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function getHumanoid(player: Player): Humanoid?
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function addLine(gui: BillboardGui, text: string, y: number, height: number, color: Color3)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0, y)
	label.Size = UDim2.fromScale(1, height)
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
end

local function makeLabel(card: Part, name: string, tier: string)
	local info = Config.Tiers[tier]
	local gui = Instance.new("BillboardGui")
	gui.Name = "CardLabel"
	gui.Size = UDim2.fromOffset(170, 66)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.MaxDistance = 70
	gui.Parent = card
	addLine(gui, name, 0, 0.45, Color3.new(1, 1, 1))
	addLine(gui, tier, 0.45, 0.28, info.Color)
	addLine(gui, ("$%d/s"):format(info.CashPerSecond), 0.73, 0.27, Color3.fromRGB(120, 255, 120))
end

--- Set card state; only World cards can be picked up.
function CardService.SetState(card: Part, state: string)
	card:SetAttribute("State", state)
	card.PickupPrompt.Enabled = (state == "World")
end

local function scheduleDespawn(card: Part, seconds: number)
	if seconds <= 0 then return end
	local token = (card:GetAttribute("DropToken") or 0) + 1
	card:SetAttribute("DropToken", token)
	task.delay(seconds, function()
		if card.Parent and card:GetAttribute("State") == "World" and card:GetAttribute("DropToken") == token then
			card:Destroy()
		end
	end)
end

local function setCarryAttributes(player: Player, card: Part?)
	player:SetAttribute("CarriedCard", card and card:GetAttribute("CardName"))
	player:SetAttribute("CarriedTier", card and card:GetAttribute("Tier"))
end

function CardService.GetCarried(player: Player): Part?
	return carried[player]
end

--- Attach a card above the player's head. Returns true on success.
function CardService.Carry(player: Player, card: Part): boolean
	local head = player.Character and player.Character:FindFirstChild("Head") :: BasePart?
	local humanoid = getHumanoid(player)
	if carried[player] or not head or not humanoid or humanoid.Health <= 0 then return false end

	carried[player] = card
	CardService.SetState(card, "Carried")
	card.Anchored = false
	card.Massless = true
	card.CFrame = head.CFrame * CFrame.new(Config.CarryOffset)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = head
	weld.Part1 = card
	weld.Parent = card

	humanoid.WalkSpeed = Config.Tiers[card:GetAttribute("Tier")].WalkSpeed
	setCarryAttributes(player, card)
	return true
end

--- Detach the carried card (no drop). Returns the card, or nil. Caller decides what happens to it.
function CardService.Release(player: Player): Part?
	local card = carried[player]
	if not card then return nil end
	carried[player] = nil
	lastPos[player] = nil
	card.CarryWeld:Destroy()
	card.Anchored = true
	card.Massless = false
	local humanoid = getHumanoid(player)
	if humanoid then humanoid.WalkSpeed = Config.BaseWalkSpeed end
	setCarryAttributes(player, nil)
	return card
end

local function dropOnGround(card: Part, position: Vector3, lifetime: number)
	card.CFrame = CFrame.new(position.X, Config.GroundY + card.Size.Y / 2 + Config.CardRestHeight, position.Z)
	card.Parent = cardsFolder
	CardService.SetState(card, "World")
	scheduleDespawn(card, lifetime)
end

local function tryPickup(player: Player, card: Part)
	local root = getRoot(player)
	if not root or not card.Parent or card:GetAttribute("State") ~= "World" then return end
	if (root.Position - card.Position).Magnitude > Config.PickupMaxDistance then return end
	if CardService.Carry(player, card) then
		lastPos[player] = root.Position
	end
end

local function createCard(name: string, tier: string): Part
	local info = Config.Tiers[tier]
	local card = Instance.new("Part")
	card.Name = "Card_" .. name
	card.Size = Config.CardSize
	card.Color = info.Color
	card.Material = Enum.Material.SmoothPlastic
	card.Anchored = true
	card.CanCollide = false
	card.CanTouch = false
	card:SetAttribute("CardName", name)
	card:SetAttribute("Tier", tier)
	card:SetAttribute("CashPerSecond", info.CashPerSecond)
	CollectionService:AddTag(card, "Card")
	makeLabel(card, name, tier)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickupPrompt"
	prompt.ActionText = "Pick up"
	prompt.ObjectText = name .. " (" .. tier .. ")"
	prompt.HoldDuration = Config.PickupHoldSeconds
	prompt.MaxActivationDistance = Config.PickupPromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = card
	prompt.Triggered:Connect(function(player) tryPickup(player, card) end)
	return card
end

--- Called when a cube breaks: drop a random card of `tier` on the floor below `position`.
function CardService.DropFromCube(tier: string, position: Vector3)
	dropOnGround(createCard(Config.PickCardName(tier), tier), position, Config.CubeDropLifetime)
end

-- Death / leave handling -------------------------------------------------

--- Drop whatever `player` carries: back to its owner if stolen, otherwise onto the floor.
function CardService.DropCarried(player: Player, char: Model?)
	local card = CardService.Release(player)
	if not card or returnStolen(card) then return end
	char = char or player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	dropOnGround(card, root and root.Position or lastPos[player] or Config.FallbackDropPosition, Config.DroppedCardLifetime)
end

local function onCharacterAdded(player: Player, char: Model)
	local humanoid = char:WaitForChild("Humanoid") :: Humanoid
	humanoid.WalkSpeed = Config.BaseWalkSpeed
	humanoid.Died:Connect(function() CardService.DropCarried(player, char) end)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(char) onCharacterAdded(player, char) end)
	player.CharacterRemoving:Connect(function(char) CardService.DropCarried(player, char) end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end

function CardService.Init(returnStolenFn)
	returnStolen = returnStolenFn
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		CardService.DropCarried(player)
		lastPos[player] = nil
	end)

	-- Track last known position of carriers (fallback if the character is already gone)
	task.spawn(function()
		while true do
			task.wait(Config.CarryTrackSeconds)
			for player in pairs(carried) do
				local root = getRoot(player)
				if root then lastPos[player] = root.Position end
			end
		end
	end)
end

return CardService
