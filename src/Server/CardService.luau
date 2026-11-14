--[[
	CardService: creates cards, handles pickup, carrying, walk-speed penalty and dropping.
	Card part attributes: CardName, Tier, CashPerSecond, State ("World" | "Carried" | "Placed").
	One card carried per player. Server authoritative.
	Carry/Release are the only places carrying state changes. DropCarried is the single drop path
	(death, leave, pickaxe hit, guard hit); a stolen card is returned to its owner first.
]]

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local Remotes=require(ReplicatedStorage.Shared.Remotes)
local Reward=require(script.Parent.PlayerReward)
local RewardMath=require(ReplicatedStorage.Shared.RewardMath)
local IndexService=require(script.Parent.IndexService)
local UpgradeShop=require(script.Parent.UpgradeShop)
local StageTwists=require(script.Parent.StageTwists)
local Announcer=require(script.Parent.Announcer)
local CardService = {}
local safeBoundary
local safePending = {}
local dropCooldown={}
local SlotService
local function clock() return Workspace:GetServerTimeNow() end

local cardsFolder = Workspace:WaitForChild("Greybox"):WaitForChild("Cards")
local pockets = {} -- one secured footballer and its hotbar tool per player
local storage = Instance.new("Folder")
storage.Name = "SecuredFootballers"
storage.Parent = game.ServerStorage
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

--- Set card state; only World cards can be picked up.
function CardService.SetState(card: Part,state: string)
 local deadline=card:GetAttribute("WorldExpiresAt")
 if deadline then card:SetAttribute("RemainingLifetime",math.max(0,deadline-clock())) end
 card:SetAttribute("WorldExpiresAt",nil)
 card:SetAttribute("State",state)
 local remaining=card:GetAttribute("RemainingLifetime")
 if state=="World" and not card:GetAttribute("Escaped") and remaining then
  card:SetAttribute("WorldExpiresAt",clock()+remaining)
 end
 local visual=card:FindFirstChild("PlayerVisual")
 if visual then
  if state~="Placed" then Reward.Resize(card) end
  visual:SetAttribute("Moving",false)
  visual:SetAttribute("CarryPose",state=="Carried")
 end
 local prompt=card:FindFirstChild("PickupPrompt") if prompt then prompt.Enabled=state=="World" or state=="Safe" end
end

local function setCarryAttributes(player: Player, card: Part?)
	player:SetAttribute("CarriedCard", card and card:GetAttribute("CardName"))
	player:SetAttribute("CarriedTier", card and card:GetAttribute("Tier"))
 player:SetAttribute("CanDropPlayer",card~=nil and not card:GetAttribute("Escaped"))
end

function CardService.GetCarried(player: Player): Part?
	local pocket=pockets[player]
 if pocket and pocket.tool and pocket.tool.Parent~=player.Character then return nil end
 return carried[player]
end

--- Attach a card above the player's head. Returns true on success.
function CardService.Carry(player: Player, card: Part): boolean
	local head = player.Character and player.Character:FindFirstChild("Head") :: BasePart?
	local humanoid = getHumanoid(player)
	if not card:GetAttribute("Escaped") and #CardService.ExportSecured(player)>=Config.DropPlayer.SafeCargoLimit then return false end
 local deadline=card:GetAttribute("WorldExpiresAt")
 if deadline and deadline<=clock() then card:Destroy() return false end
 if card:GetAttribute("PickupOwnerUserId") and card:GetAttribute("PickupOwnerUserId")~=player.UserId then return false end
 if pockets[player] or carried[player] or not head or not humanoid or humanoid.Health <= 0 then return false end

	carried[player] = card
 card:SetAttribute("PickupOwnerUserId",nil)
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
	local card = CardService.GetCarried(player)
	if not card then return nil end
 local pocket=pockets[player]
 if pocket then pockets[player]=nil end
	carried[player] = nil
	lastPos[player] = nil
 safePending[player]=nil
	local weld=card:FindFirstChild("CarryWeld")
 if weld then weld:Destroy() end
 if pocket and pocket.tool then pocket.tool:Destroy() end
	card.Anchored = true
	card.Massless = false
	local humanoid = getHumanoid(player)
	if humanoid then humanoid.WalkSpeed = Config.BaseWalkSpeed end
	setCarryAttributes(player, nil)
	return card
end

local function stow(player, pocket)
 local card=pocket.card
 if carried[player]==card then
  carried[player]=nil
  lastPos[player]=nil
  setCarryAttributes(player,nil)
 end
 local weld=card:FindFirstChild("CarryWeld")
 if weld then weld:Destroy() end
 card.Anchored=true
 CardService.SetState(card,"Stored")
 card.Parent=storage
end

local function givePocketTool(player, pocket, equip)
 local backpack=player:FindFirstChildOfClass("Backpack")
 local humanoid=getHumanoid(player)
 if not backpack or not humanoid or humanoid.Health<=0 or pockets[player]~=pocket then return end
 if pocket.tool and pocket.tool.Parent then
  if equip then humanoid:EquipTool(pocket.tool) end
  return
 end
 local tool=Instance.new("Tool")
 tool.Name=pocket.card:GetAttribute("CardName")
 tool.ToolTip="Secured footballer"
 tool.CanBeDropped=false
 tool.Grip=Config.SecuredCarry.Grip
 local handle=Instance.new("Part")
 handle.Name="Handle"
 handle.Size=Vector3.one
 handle.Transparency=1
 handle.CanCollide=false
 handle.CanTouch=false
 handle.CanQuery=false
 handle.Massless=true
 handle.Parent=tool
 pocket.tool=tool
 tool.Equipped:Connect(function()
  task.wait(Config.SecuredCarry.GripSettleSeconds)
  if pockets[player]~=pocket or tool.Parent~=player.Character or humanoid.Health<=0 then return end
  local character=player.Character
  local hand=character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
  local root=getRoot(player)
  if not hand or not root then return end
  local card=pocket.card
  local offset=root.CFrame:VectorToWorldSpace(Config.SecuredCarry.VisualOffset)
  card.CFrame=CFrame.new(hand.Position+offset)*root.CFrame.Rotation
  card.Anchored=false
  card.Massless=true
  local old=card:FindFirstChild("CarryWeld")
  if old then old:Destroy() end
  local weld=Instance.new("Weld")
  weld.Name="CarryWeld"
  -- Keep the held visual upright as the avatar's tool animation rotates its wrist.
  weld.C0=root.CFrame:ToObjectSpace(card.CFrame)
  weld.Part0=root
  weld.Part1=card
  weld.Parent=card
  carried[player]=card
  CardService.SetState(card,"Carried")
  card.Parent=cardsFolder
  setCarryAttributes(player,card)
 end)
 tool.Unequipped:Connect(function()
  if pockets[player]==pocket and pocket.tool==tool then stow(player,pocket) end
 end)
 tool.Parent=backpack
 if equip then humanoid:EquipTool(tool) end
end

local function pocketCard(player,card,equip)
 local pocket={card=card}
 pockets[player]=pocket
 stow(player,pocket)
 if equip then givePocketTool(player,pocket,true) end
end

function CardService.RefreshPocketTool(player)
 local pocket=pockets[player]
 if pocket then givePocketTool(player,pocket,false) end
end

local function dropOnGround(card: Part, position: Vector3, lifetime: number)
 if not card:GetAttribute("RemainingLifetime") then card:SetAttribute("RemainingLifetime",lifetime) end
	card.CFrame = CFrame.new(position.X, Config.GroundY + card.Size.Y / 2 + Config.CardRestHeight, position.Z)
	card.Parent = cardsFolder
	CardService.SetState(card, "World")

end

local function tryPickup(player: Player, card: Part)
	local root = getRoot(player)
	if player:GetAttribute("DataReady")==false or not root or not card.Parent or (card:GetAttribute("State") ~= "World" and card:GetAttribute("State") ~= "Safe") then return end
	if (root.Position - card.Position).Magnitude > Config.PickupMaxDistance then return end
 if card:GetAttribute("BreakerUserId")~=player.UserId and clock()<(card:GetAttribute("PriorityUntil") or 0) then return end -- the breaker gets first pick
	CardService.Carry(player, card)
end

-- Every attribute (including Variant/Giant) is set before the card is parented, so clients see them from the first frame.
local function createCard(entry, tier: string, position: Vector3, variant: string?, giant: boolean?, eggSize: string?, roll: number?, luckyBreak: boolean?, sizeTier: string?, revealId: string?, groundY: number?): Part
 local name=entry.Name
	local info = Config.Tiers[tier]
	local card = Instance.new("Part")
	card.Name = "Card_" .. name
	card.Size = Config.CardSize
 card.CFrame=CFrame.new(position.X,(groundY or Config.GroundY+Config.CardRestHeight)+Config.CardSize.Y/2,position.Z)
 card:SetAttribute("CageRevealId",revealId)
	card.Color = info.Color
 card.Transparency=1
 card.CanQuery=false
 card:SetAttribute("PlayerId",entry.Id)
 card:SetAttribute("ItemId",HttpService:GenerateGUID(false))
	card.Material = Enum.Material.SmoothPlastic
	card.Anchored = true
	card.CanCollide = false
	card.CanTouch = false
	card:SetAttribute("CardName", name)
	card:SetAttribute("Tier", tier)
	card:SetAttribute("CashPerSecond", info.CashPerSecond*Reward.IncomeMultiplier(sizeTier or "Normal",variant or "Normal",roll or 1))
 card:SetAttribute("IncomeRoll",roll or 1)
 card:SetAttribute("LuckyBreak",luckyBreak) -- cosmetic: the burst that revealed it (clients only)
 card:SetAttribute("SizeTier",sizeTier or "Normal")
 card:SetAttribute("RewardVersion",2)
 card:SetAttribute("Variant",variant or "Normal")
 card:SetAttribute("Giant",giant or nil)
 card:SetAttribute("EggSize",eggSize)
	CollectionService:AddTag(card, "Card")
 Reward.Attach(card,entry.Id,variant or "Normal")

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickupPrompt"
	prompt.ActionText = "Pick up"
	prompt.ObjectText = name .. " (" .. tier .. ")"
	prompt.HoldDuration = Config.PickupHoldSeconds
	prompt.MaxActivationDistance = Config.PickupPromptDistance
	prompt.RequiresLineOfSight = true
	prompt.Parent = card
	prompt.Triggered:Connect(function(player) tryPickup(player, card) end)
 card.Parent=cardsFolder
	return card
end

function CardService.SetIncome(card: Part, amount: number)
 card:SetAttribute("CashPerSecond",amount)
end

-- Lock the reward before the reveal, then start its pickup window and ground timer after the character flashes into its footballer.
function CardService.DropFromCube(tier: string,position: Vector3,breaker: Player?,lucky: boolean?,egg: BasePart)
 local entry=Reward.Pick(tier)
 local eggSize=egg:GetAttribute("Size")
 local stage=egg:GetAttribute("Stage")
 local luck=Reward.Luck(lucky,UpgradeShop.Bonus(breaker,"Luck")+StageTwists.TakeLuck(breaker,stage))
 local variant,sizeTier=Reward.Roll(luck,egg:GetAttribute("MinVariant"))
 local roll=Reward.IncomeRoll(entry,luck)
 local duration=RewardMath.Reveal(luck)
 local ground=egg:GetAttribute("CageGroundY") or position.Y-egg.Size.Y/2
 egg:SetAttribute("RevealDuration",duration)
 local revealId=HttpService:GenerateGUID(false)
 local started=Workspace:GetServerTimeNow()
 egg:SetAttribute("RevealId",revealId)
 egg:SetAttribute("RevealStart",started)
 egg:SetAttribute("RevealSeed",Random.new():NextInteger(1,1000000000))
 for _,player in Players:GetPlayers() do
  local root=getRoot(player)
  if root and (root.Position-position).Magnitude<=Config.Reveal.MaxDistance then
   Remotes.EggReveal:FireClient(player,egg,luck,duration,started,revealId)
  end
 end
 task.wait(duration)
 local card=createCard(entry,tier,position,variant,nil,eggSize,roll,lucky,sizeTier,revealId,ground)
 card:SetAttribute("EarnedFromEgg",true)
 card:SetAttribute("SourceStage",stage) -- guards only chase a carrier of a character taken from their own stage
 card:SetAttribute("RemainingLifetime",Config.CubeDropLifetime)
 if breaker then
  card:SetAttribute("BreakerUserId",breaker.UserId)
  card:SetAttribute("PriorityUntil",clock()+Config.Reveal.BreakerPrioritySeconds)
  Announcer.Hatched(breaker,entry,tier,variant,sizeTier=="Giant" or sizeTier=="Colossal" or sizeTier=="Mega" or sizeTier=="Monumental")
 end
 CardService.SetState(card,"Revealing")
 task.delay(Config.Reveal.RiseSeconds,function() if card.Parent and card:GetAttribute("State")=="Revealing" then CardService.SetState(card,"World") end end)
end

local function itemExists(id)
 for _,card in CollectionService:GetTagged("Card") do if card:GetAttribute("ItemId")==id then return true end end
 return false
end
function CardService.Record(card)
 return {PlayerId=card:GetAttribute("PlayerId"),Level=card:GetAttribute("UpgradeLevel") or 0,ItemId=card:GetAttribute("ItemId"),
  Pocket=card:GetAttribute("SecuredHotbar")==true or nil,Variant=card:GetAttribute("Variant"),Giant=card:GetAttribute("Giant"),EggSize=card:GetAttribute("EggSize"),
 IncomeRoll=card:GetAttribute("IncomeRoll"),SizeTier=card:GetAttribute("SizeTier"),RewardVersion=2,
 LegacyBaseIncome=card:GetAttribute("LegacyBaseIncome")}
end
-- Only validated server-saved roster records can be restored. A saved ItemId that already exists live is a duplicate and is refused.
function CardService.RestoreRecord(record,position)
 if type(record)~="table" then return nil end
 local entry
 for _,candidate in Config.PlayerRoster do if candidate.Id==record.PlayerId then entry=candidate break end end
 if not entry then return nil end
 local id=record.ItemId
 local validId=type(id)=="string" and #id>=Config.PlayerData.ItemIdMinLength and #id<=Config.PlayerData.ItemIdMaxLength
 if validId and itemExists(id) then return nil end
 local variant=type(record.Variant)=="string" and Config.Variants[record.Variant] and record.Variant or nil
 local giant=record.Giant==true or nil
 local eggSize=type(record.EggSize)=="string" and Config.EggSizeById[record.EggSize] and record.EggSize or nil
 local range=entry.IncomeRange or Config.IncomeRange[entry.Tier]
 local roll=type(record.IncomeRoll)=="number" and record.IncomeRoll==record.IncomeRoll and math.clamp(record.IncomeRoll,range.Min,range.Max) or nil
 local sizeTier=type(record.SizeTier)=="string" and Config.RewardSizeById[record.SizeTier] and record.SizeTier or "Normal"
 local card=createCard(entry,entry.Tier,position,variant,giant,eggSize,roll,nil,sizeTier)
 local legacy=record.LegacyBaseIncome
 if record.RewardVersion~=2 then
  local oldVariant=variant=="Gold" and 2 or variant=="Diamond" and 5 or 1
  legacy=Config.Tiers[entry.Tier].CashPerSecond*oldVariant*(giant and 3 or 1)*(roll or 1)
 end
 if type(legacy)=="number" and legacy==legacy and legacy>0 and legacy<math.huge then
  card:SetAttribute("LegacyBaseIncome",legacy)
  card:SetAttribute("CashPerSecond",legacy)
 end
 if validId then card:SetAttribute("ItemId",id) end
 local level=type(record.Level)=="number" and record.Level==record.Level and math.clamp(math.floor(record.Level),0,Config.PlotSlots.MaxLevel) or 0
 local base=card:GetAttribute("CashPerSecond")
 card:SetAttribute("UpgradeLevel",level)
 card:SetAttribute("BaseCashPerSecond",base)
 CardService.SetIncome(card,base*Config.PlotSlots.IncomeGrowth^level)
 return card
end

-- Death / leave handling -------------------------------------------------

local function secureAtHome(player,card)
 card:SetAttribute("Escaped",true) card:SetAttribute("SecuredOwnerUserId",player.UserId)
 card:SetAttribute("WorldExpiresAt",nil) card:SetAttribute("RemainingLifetime",nil)
 IndexService.Record(player,card)
 if SlotService and SlotService.PlaceSecured(player,card) then return end
 local spawn=player.RespawnLocation
 card.CFrame=CFrame.new(spawn and spawn.Position+Vector3.new(0,Config.CardSize.Y/2,0) or Config.FallbackDropPosition)
 card:SetAttribute("PickupOwnerUserId",player.UserId)
 CardService.SetState(card,"Safe")
end
function CardService.DropCarried(player: Player,char: Model?)
 char=char or player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 local pocket=pockets[player]
 if pocket then
  stow(player,pocket)
  local tool=pocket.tool
  local backpack=player:FindFirstChildOfClass("Backpack")
  if tool and backpack and tool.Parent==char then tool.Parent=backpack end
  return
 end
 local position=root and root.Position or lastPos[player] or Config.FallbackDropPosition
 local card=CardService.Release(player)
 if not card then return end
 local stolen=card:GetAttribute("OriginalOwnerUserId")~=nil
 if returnStolen(card) then return end
 if card:GetAttribute("Escaped") and not stolen then secureAtHome(player,card) return end
 if stolen then card:SetAttribute("Escaped",nil) card:SetAttribute("RemainingLifetime",Config.DroppedCardLifetime) end
 dropOnGround(card,position,Config.DroppedCardLifetime)
end
function CardService.ExportSecured(player)
 local records={}
 local pocket=pockets[player]
 if pocket and pocket.card.Parent then table.insert(records,CardService.Record(pocket.card)) end
 for _,card in CollectionService:GetTagged("Card") do
  if card.Parent and (not pocket or pocket.card~=card) and not card:GetAttribute("OriginalOwnerUserId") and card:GetAttribute("Escaped") and (carried[player]==card or card:GetAttribute("PickupOwnerUserId")==player.UserId) then
   table.insert(records,CardService.Record(card))
  end
 end
 return records
end
function CardService.RestoreSecured(player,records)
 for index,record in records do
  if index>Config.DropPlayer.SafeCargoLimit then break end
  local card=CardService.RestoreRecord(record,Config.FallbackDropPosition)
  if card then
   if record.Pocket==true and not pockets[player] then
    card:SetAttribute("Escaped",true)
    card:SetAttribute("SecuredOwnerUserId",player.UserId)
    card:SetAttribute("SecuredHotbar",true)
    pocketCard(player,card,false)
   else
    secureAtHome(player,card)
   end
  end
 end
end
local function currentStage(position)
 for _,zone in CollectionService:GetTagged("StageZone") do
  local p=zone.CFrame:PointToObjectSpace(position)
  if math.abs(p.X)<=zone.Size.X/2 and math.abs(p.Z)<=zone.Size.Z/2 then return zone end
 end
end
local function manualDrop(player)
 if (dropCooldown[player] or 0)>clock() then return end
 dropCooldown[player]=clock()+Config.DropPlayer.RequestCooldown
 local card=carried[player] local root=getRoot(player) local h=getHumanoid(player)
 if not card or not root or not h or h.Health<=0 or card:GetAttribute("Escaped") then return end
 local zone=currentStage(root.Position) if not zone then return end
 local point=zone.CFrame:PointToObjectSpace(root.Position+root.CFrame.LookVector*Config.DropPlayer.Forward)
 point=Vector3.new(math.clamp(point.X,-zone.Size.X/2+3,zone.Size.X/2-3),point.Y,math.clamp(point.Z,-zone.Size.Z/2+3,zone.Size.Z/2-3))
 lastPos[player]=zone.CFrame*point
 local position=lastPos[player] or root.Position
 local released=CardService.Release(player)
 if released then dropOnGround(released,position,Config.DroppedCardLifetime) end
end

local function onCharacterAdded(player: Player, char: Model)
	local humanoid = char:WaitForChild("Humanoid") :: Humanoid
	humanoid.WalkSpeed = Config.BaseWalkSpeed
	humanoid.Died:Connect(function() CardService.DropCarried(player, char) end)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(char) onCharacterAdded(player, char) end)
	player.CharacterRemoving:Connect(function(char)
  CardService.DropCarried(player,char)
  local pocket=pockets[player]
  if pocket and pocket.tool then pocket.tool:Destroy() pocket.tool=nil end
 end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end

function CardService.Init(returnStolenFn,slotService)
 SlotService=slotService
 Remotes.DropPlayer.OnServerEvent:Connect(manualDrop)
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
		task.defer(function()
   local pocket=pockets[player]
   if pocket then
    pockets[player]=nil
    if pocket.tool then pocket.tool:Destroy() end
    pocket.card:Destroy()
   end
  end)
  lastPos[player] = nil
  dropCooldown[player]=nil
  for _,card in CollectionService:GetTagged("Card") do if card:GetAttribute("PickupOwnerUserId")==player.UserId then card:Destroy() end end
	end)

	-- Track last known position of carriers (fallback if the character is already gone)
	task.spawn(function()
		while true do
			task.wait(Config.CarryTrackSeconds)
   for _,card in CollectionService:GetTagged("Card") do local deadline=card:GetAttribute("WorldExpiresAt") if deadline and deadline<=clock() and (card:GetAttribute("State")=="World" or card:GetAttribute("State")=="Revealing") then card:Destroy() end end
   for player in pairs(carried) do
				local root = getRoot(player)
				if root then
     lastPos[player] = root.Position
     local card=carried[player]
     if card:GetAttribute("EarnedFromEgg") and not card:GetAttribute("Escaped") then
      if safeBoundary and root.Position.Z>=safeBoundary then safePending[player]=true end
      if safePending[player] and root.Position.Z<safeBoundary-Config.Reveal.SafeMargin then
       card:SetAttribute("Escaped",true)
       card:SetAttribute("SecuredOwnerUserId",player.UserId)
       IndexService.Record(player,card)
       card:SetAttribute("RemainingLifetime",nil) card:SetAttribute("WorldExpiresAt",nil)
       player:SetAttribute("CanDropPlayer",false)
       safePending[player]=nil
       local released=CardService.Release(player)
       if released then
        released:SetAttribute("SecuredHotbar",true)
        pocketCard(player,released,true)
       end
       Remotes.SafeReturn:FireClient(player,card:GetAttribute("CardName"))
      end
     end
    end
			end
		end
	end)
end

return CardService
