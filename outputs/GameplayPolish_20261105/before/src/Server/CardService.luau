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

local Remotes=require(ReplicatedStorage.Shared.Remotes)
local Reward=require(script.Parent.PlayerReward)
local CardService = {}
local safeBoundary
local safePending = {}

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
 local visual=card:FindFirstChild("PlayerVisual")
 if visual then visual:SetAttribute("Moving",state=="Carried") end
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
 safePending[player]=false
	local root = getRoot(player)
	lastPos[player] = root and root.Position or head.Position
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
 safePending[player]=nil
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
	if player:GetAttribute("DataReady")==false or not root or not card.Parent or card:GetAttribute("State") ~= "World" then return end
	if (root.Position - card.Position).Magnitude > Config.PickupMaxDistance then return end
	CardService.Carry(player, card)
end

local function createCard(entry, tier: string, position: Vector3): Part
 local name=entry.Name
	local info = Config.Tiers[tier]
	local card = Instance.new("Part")
	card.Name = "Card_" .. name
	card.Size = Config.CardSize
 card.CFrame=CFrame.new(position.X,Config.GroundY+Config.CardSize.Y/2+Config.CardRestHeight,position.Z)
 card.Parent=cardsFolder
	card.Color = info.Color
 card.Transparency=1
 card.CanQuery=false
 card:SetAttribute("PlayerId",entry.Id)
	card.Material = Enum.Material.SmoothPlastic
	card.Anchored = true
	card.CanCollide = false
	card.CanTouch = false
	card:SetAttribute("CardName", name)
	card:SetAttribute("Tier", tier)
	card:SetAttribute("CashPerSecond", info.CashPerSecond)
	CollectionService:AddTag(card, "Card")
	makeLabel(card, name, tier)
 Reward.Attach(card,entry.Id)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickupPrompt"
	prompt.ActionText = "Pick up"
	prompt.ObjectText = name .. " (" .. tier .. ")"
	prompt.HoldDuration = Config.PickupHoldSeconds
	prompt.MaxActivationDistance = Config.PickupPromptDistance
	prompt.RequiresLineOfSight = true
	prompt.Parent = card
	prompt.Triggered:Connect(function(player) tryPickup(player, card) end)
	return card
end

--- Keep the carried/placed card label consistent with its upgraded income.
function CardService.SetIncome(card: Part, amount: number)
 card:SetAttribute("CashPerSecond",amount)
 local gui=card:FindFirstChild("CardLabel")
 if gui then for _,label in gui:GetChildren() do
  if label:IsA("TextLabel") and label.Text:sub(1,1)=="$" then label.Text=("$%.2f/s"):format(amount) end
 end end
end

--- Called when a cube breaks: drop a random card of `tier` on the floor below `position`.
function CardService.DropFromCube(tier: string, position: Vector3)
 local entry=Reward.Pick(tier)
 Remotes.EggReveal:FireAllClients(position,tier,entry.Id)
 task.delay(Config.Reveal.ShuffleSeconds,function()
  local card=createCard(entry,tier,position)
  card:SetAttribute("EarnedFromEgg",true)
  dropOnGround(card,position,Config.CubeDropLifetime)
 end)
end

-- Only validated server-saved roster records can be restored.
function CardService.RestoreRecord(record,position)
 if type(record)~="table" then return nil end
 local entry
 for _,candidate in Config.PlayerRoster do if candidate.Id==record.PlayerId then entry=candidate break end end
 if not entry then return nil end
 local card=createCard(entry,entry.Tier,position)
 local level=type(record.Level)=="number" and record.Level==record.Level and math.clamp(math.floor(record.Level),0,Config.PlotSlots.MaxLevel) or 0
 card:SetAttribute("UpgradeLevel",level)
 card:SetAttribute("BaseCashPerSecond",Config.Tiers[entry.Tier].CashPerSecond)
 CardService.SetIncome(card,Config.Tiers[entry.Tier].CashPerSecond*Config.PlotSlots.IncomeGrowth^level)
 return card
end

-- Death / leave handling -------------------------------------------------

--- Drop whatever `player` carries: back to its owner if stolen, otherwise onto the floor.
function CardService.DropCarried(player: Player, char: Model?)
	char = char or player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local position = root and root.Position or lastPos[player] or Config.FallbackDropPosition
	local card = CardService.Release(player)
	if not card or returnStolen(card) then return end
	dropOnGround(card, position, Config.DroppedCardLifetime)
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
 for _,zone in CollectionService:GetTagged("StageZone") do
  if zone:GetAttribute("Stage")==1 then safeBoundary=zone.Position.Z-zone.Size.Z/2 end
 end
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
				if root then
     lastPos[player] = root.Position
     local card=carried[player]
     if card:GetAttribute("EarnedFromEgg") and not card:GetAttribute("Escaped") then
      if safeBoundary and root.Position.Z>=safeBoundary then safePending[player]=true end
      if safePending[player] and root.Position.Z<safeBoundary-Config.Reveal.SafeMargin then
       card:SetAttribute("Escaped",true)
       safePending[player]=nil
       Remotes.SafeReturn:FireClient(player,card:GetAttribute("CardName"))
      end
     end
    end
			end
		end
	end)
end

return CardService
