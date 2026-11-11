local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.Config)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local Data = require(script.Parent.PlayerData)
local Stats = require(script.Parent.PlayerStats)
local T = Config.Trails
local Shop = {}
local nextRequest = {}

function Shop.Multiplier(player)
 local profile = Data.Get(player)
 local def = profile and T.Catalog[profile.data.TrailIndex]
 return def and def.Multiplier or 1
end

local function apply(player, character)
 local root = character and character:WaitForChild("HumanoidRootPart",5)
 if not root or character~=player.Character then return end
 for _,name in {"OwnedTrail","TrailUpper","TrailLower"} do
  local old = root:FindFirstChild(name)
  if old then old:Destroy() end
 end
 local def = T.Catalog[player:GetAttribute("TrailIndex") or 1]
 if not def or not def.Color then return end
 local upper = Instance.new("Attachment")
 upper.Name = "TrailUpper"
 upper.Position = Vector3.new(0,T.Height,T.BackOffset)
 upper.Parent = root
 local lower = Instance.new("Attachment")
 lower.Name = "TrailLower"
 lower.Position = Vector3.new(0,-T.Height,T.BackOffset)
 lower.Parent = root
 local trail = Instance.new("Trail")
 trail.Name = "OwnedTrail"
 trail.Attachment0 = upper
 trail.Attachment1 = lower
 trail.Lifetime = T.Lifetime
 trail.Color = ColorSequence.new(def.Color)
 trail.Transparency = NumberSequence.new(.2,1)
 trail.LightEmission = .5
 trail.FaceCamera = true
 trail.Parent = root
end

local function publish(player, data)
 player:SetAttribute("TrailTier",data.TrailTier)
 player:SetAttribute("TrailIndex",data.TrailIndex)
 task.spawn(apply,player,player.Character)
end

local function request(player, action, index)
 local profile = Data.Get(player)
 if not profile or not player:GetAttribute("DataReady") then return end
 if type(index)~="number" or index%1~=0 or not T.Catalog[index] then return end
 if (nextRequest[player] or 0)>os.clock() then return end
 nextRequest[player] = os.clock()+T.RequestGap
 local data,def = profile.data,T.Catalog[index]
 if action=="Buy" then
  if index~=data.TrailTier+1 then return end
  if Stats.Get(player,"Cash")<def.Cost then
   Remotes.TrailStatus:FireClient(player,"Not enough cash.")
   return
  end
  Stats.Add(player,"Cash",-def.Cost)
  data.TrailTier = index
  Data.RecordPurchase(player,def.Id,def.Cost,"Cash")
 elseif action~="Equip" or index>data.TrailTier then
  return
 end
 data.TrailIndex = index
 publish(player,data)
 Remotes.TrailStatus:FireClient(player,def.Name.." equipped.")
 task.spawn(Data.RequestSave,player)
end

function Shop.Init()
 Remotes.TrailRequest.OnServerEvent:Connect(request)
 local function added(player)
  local function ready()
   local profile = Data.Get(player)
   if profile and player:GetAttribute("DataReady") then publish(player,profile.data) end
  end
  player:GetAttributeChangedSignal("DataReady"):Connect(ready)
  player.CharacterAdded:Connect(function(character) task.spawn(apply,player,character) end)
  ready()
 end
 Players.PlayerAdded:Connect(added)
 Players.PlayerRemoving:Connect(function(player) nextRequest[player]=nil end)
 for _,player in Players:GetPlayers() do added(player) end
end

return Shop
