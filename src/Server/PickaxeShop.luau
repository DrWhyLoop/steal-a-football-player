-- Pickaxe ownership, purchase and equipping. Every player holds one Tool named Config.PickaxeName; equipping swaps it for a copy
-- of the chosen pickaxe's template. Clients only send Buy/Equip requests; damage per hit comes from Shop.Power.
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Remotes=require(game.ReplicatedStorage.Shared.Remotes)
local Stats=require(script.Parent.PlayerStats)
local PlayerData=require(script.Parent.PlayerData)
local Shop={}
local byId={}
for _,def in Config.Pickaxes do byId[def.Id]=def end
local nextRequest={}
local function status(player,text) Remotes.PickaxeStatus:FireClient(player,text) end
function Shop.Power(player) return (byId[player:GetAttribute("PickaxeId")] or Config.Pickaxes[1]).Power end
local function give(player)
 local def=byId[player:GetAttribute("PickaxeId")]
 local char,backpack=player.Character,player:FindFirstChildOfClass("Backpack")
 local humanoid=char and char:FindFirstChildOfClass("Humanoid")
 if not def or not backpack or not humanoid then return end
 local held=false
 for _,container in {backpack,char} do
  local old=container:FindFirstChild(Config.PickaxeName)
  if old then held=held or container==char old:Destroy() end
 end
 local tool=game.ServerStorage.AxeTemplates[def.Template]:Clone()
 tool.Name=Config.PickaxeName tool.ToolTip=def.Name tool.Parent=backpack
 if held then humanoid:EquipTool(tool) end
end
local function request(player,action,id)
 local profile=PlayerData.Get(player)
 if not profile or player:GetAttribute("DataReady")~=true or type(action)~="string" or type(id)~="string" then return end
 if (nextRequest[player] or 0)>os.clock() then return end
 nextRequest[player]=os.clock()+Config.PickaxeShop.RequestGap
 local def,data=byId[id],profile.data
 if not def then return end
 if action=="Buy" then
  if data.Pickaxes[id] then status(player,"You already own it.") return end
  if Stats.Get(player,"Cash")<def.Cost then status(player,"Not enough cash.") return end
  Stats.Add(player,"Cash",-def.Cost) data.Pickaxes[id]=true player:SetAttribute("PickaxeOwned_"..id,true)
  PlayerData.RecordPurchase(player,id,def.Cost,"Cash")
 elseif action~="Equip" or not data.Pickaxes[id] then return end
 data.Pickaxe=id player:SetAttribute("PickaxeId",id) give(player) status(player,def.Name.." equipped.")
 if action=="Buy" then task.spawn(PlayerData.RequestSave,player) end
end
local function loaded(player)
 local profile=PlayerData.Get(player)
 if not profile then return end
 player:SetAttribute("PickaxeId",profile.data.Pickaxe)
 for id in profile.data.Pickaxes do player:SetAttribute("PickaxeOwned_"..id,true) end
 give(player)
end
function Shop.Init()
 Remotes.PickaxeRequest.OnServerEvent:Connect(request)
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
