-- Tool ownership, purchase and equipping. Every player holds one mining Tool named Config.PickaxeName (equipping swaps it for a copy of
-- the chosen tool's template) and the free Mesh Bat behind it, so the pickaxe is hotbar slot 1 and the bat slot 2. Clients only send
-- requests; damage per hit comes from Shop.Power: a cash tool's own Power, or for a premium tool the best owned cash tool x Multiplier.
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Remotes=require(game.ReplicatedStorage.Shared.Remotes)
local Stats=require(script.Parent.PlayerStats)
local PlayerData=require(script.Parent.PlayerData)
local Purchases=require(script.Parent.Purchases)
local Shop={}
local cashById,premiumById={},{}
for _,def in Config.CashTools do cashById[def.Id]=def end
for _,def in Config.PremiumTools do premiumById[def.Id]=def end
local nextRequest={}
local function status(player,text) Remotes.ToolStatus:FireClient(player,text) end
local function bestCashPower(player)
 local best=0
 for id,def in cashById do if player:GetAttribute("ToolOwned_"..id) and def.Power>best then best=def.Power end end
 return best
end
function Shop.Power(player)
 local id=player:GetAttribute("ToolId")
 local premium=premiumById[id]
 if premium then return bestCashPower(player)*premium.Multiplier end
 return (cashById[id] or Config.CashTools[1]).Power
end
-- Robot Arm Drill: Right = normal grip. Left / Both put a welded copy of the tool in the left hand (LeftHand on R15, Left Arm on R6,
-- using the same grip offsets as the right hand); Left also hides the right-hand copy. The copy lives under the character.
local function armHooks(player,tool)
 local copy
 local function clear() if copy then copy:Destroy() copy=nil end end
 tool.Unequipped:Connect(clear)
 tool.Equipped:Connect(function()
  clear()
  local mode=player:GetAttribute("ArmMode")
  local char=tool.Parent
  local humanoid=char and char:FindFirstChildOfClass("Humanoid")
  if mode=="Right" or not humanoid then return end
  local r6=humanoid.RigType==Enum.HumanoidRigType.R6
  local hand,rightHand=char:FindFirstChild(r6 and "Left Arm" or "LeftHand"),char:FindFirstChild(r6 and "Right Arm" or "RightHand")
  local grip=rightHand and rightHand:WaitForChild("RightGrip",2)
  if not hand or not grip or tool.Parent~=char then return end
  copy=Instance.new("Model") copy.Name="LeftArmTool"
  for _,child in tool:Clone():GetChildren() do child.Parent=copy end
  for _,part in copy:GetDescendants() do
   if part:IsA("BasePart") then part.Anchored=false part.CanCollide=false part.CanTouch=false part.Massless=true end
  end
  local weld=Instance.new("Weld") weld.Name="LeftGrip" weld.Part0=hand weld.Part1=copy.Handle
  weld.C0=r6 and grip.C0 or hand.LeftGripAttachment.CFrame weld.C1=grip.C1 weld.Parent=copy
  copy.Parent=char
  if mode=="Left" then
   for _,part in tool:GetDescendants() do if part:IsA("BasePart") and part.Name~="Handle" then part.Transparency=1 end end
  end
 end)
end
local function give(player)
 local def=cashById[player:GetAttribute("ToolId")] or premiumById[player:GetAttribute("ToolId")]
 local char,backpack=player.Character,player:FindFirstChildOfClass("Backpack")
 local humanoid=char and char:FindFirstChildOfClass("Humanoid")
 if not def or not backpack or not humanoid then return end
 local held
 for _,name in {Config.PickaxeName,Config.Bat.Name} do
  for _,container in {backpack,char} do
   local old=container:FindFirstChild(name)
   if old then if container==char then held=name end old:Destroy() end
  end
 end
 local templates=game.ServerStorage.AxeTemplates
 local tool=templates[def.Template]:Clone()
 tool.Name=Config.PickaxeName tool.ToolTip=def.Name tool.Parent=backpack
 if def.Arms then armHooks(player,tool) end
 local bat=templates[Config.Bat.Template]:Clone()
 bat.Name=Config.Bat.Name bat.ToolTip=Config.Bat.ToolTip bat.Parent=backpack
 if held then humanoid:EquipTool(backpack:FindFirstChild(held)) end
end
local function equip(player,def)
 local profile=PlayerData.Get(player)
 profile.data.Tool=def.Id player:SetAttribute("ToolId",def.Id) give(player) status(player,def.Name.." equipped.")
end
local function request(player,action,id)
 local profile=PlayerData.Get(player)
 if not profile or player:GetAttribute("DataReady")~=true or type(action)~="string" or type(id)~="string" then return end
 if (nextRequest[player] or 0)>os.clock() then return end
 nextRequest[player]=os.clock()+Config.ToolShop.RequestGap
 local data=profile.data
 if action=="Arm" then
  if Purchases.Owns(player,"RobotArm") and table.find(Config.ArmModes,id) then
   data.ArmMode=id player:SetAttribute("ArmMode",id)
   if player:GetAttribute("ToolId")=="RobotArm" then give(player) end
   status(player,"Robot arm: "..id..".")
  end
  return
 end
 local cash,premium=cashById[id],premiumById[id]
 if action=="Premium" then
  if premium and not premium.ComingSoon then Purchases.RequestPrompt(player,id,function(text) status(player,text) end) end
 elseif action=="Buy" and cash then
  if data.Tools[id] then status(player,"You already own it.") return end
  if Stats.Get(player,"Cash")<cash.Cost then status(player,"Not enough cash.") return end
  Stats.Add(player,"Cash",-cash.Cost) data.Tools[id]=true player:SetAttribute("ToolOwned_"..id,true)
  PlayerData.RecordPurchase(player,id,cash.Cost,"Cash")
  equip(player,cash)
  task.spawn(PlayerData.RequestSave,player)
 elseif action=="Equip" and (cash and data.Tools[id] or premium and Purchases.Owns(player,id)) then
  equip(player,cash or premium)
 end
end
local function loaded(player)
 local profile=PlayerData.Get(player)
 if not profile then return end
 player:SetAttribute("ToolId",profile.data.Tool)
 player:SetAttribute("ArmMode",profile.data.ArmMode)
 for id in profile.data.Tools do player:SetAttribute("ToolOwned_"..id,true) end
 give(player)
end
-- A refunded premium tool in hand falls back to the best cash tool the player owns.
local function revoked(player,key)
 if player:GetAttribute("ToolId")~=key then return end
 local best=Config.CashTools[1]
 for _,def in Config.CashTools do if player:GetAttribute("ToolOwned_"..def.Id) and def.Power>best.Power then best=def end end
 equip(player,best)
end
function Shop.Init()
 Remotes.ToolRequest.OnServerEvent:Connect(request)
 Purchases.Granted.Event:Connect(function(player,key) if premiumById[key] then equip(player,premiumById[key]) end end)
 Purchases.Revoked.Event:Connect(function(player,key) if premiumById[key] then revoked(player,key) end end)
 local function added(player)
  player.CharacterAdded:Connect(function() if player:GetAttribute("DataReady") then task.defer(give,player) end end)
  player:GetAttributeChangedSignal("DataReady"):Connect(function() if player:GetAttribute("DataReady") then loaded(player) end end)
  if player:GetAttribute("DataReady") then loaded(player) end
 end
 Players.PlayerAdded:Connect(added)
 Players.PlayerRemoving:Connect(function(player) nextRequest[player]=nil end)
 for _,player in Players:GetPlayers() do added(player) end
end
return Shop
