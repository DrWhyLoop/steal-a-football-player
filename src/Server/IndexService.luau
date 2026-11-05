-- Character index: records which characters (and variant combinations) a player has made their own and grants each tier's
-- one-time cash reward. A character counts once it is placed on the player's display or secured at home (Record is called from
-- SlotService.occupy and the CardService secure paths). Everything is derived from the roster; the client only displays.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Shared.Config)
local Remotes=require(RS.Shared.Remotes)
local Keys=require(RS.Shared.IndexKeys)
local Format=require(RS.Shared.NumberFormat)
local PlayerData=require(script.Parent.PlayerData)
local CashService=require(script.Parent.CashService)
local I={}
local requestAt={}

local function checkTier(player,data,tier)
 if data.IndexClaimed[tier] then return end
 for _,entry in Keys.ByTier[tier] do if (data.Index[entry.Id] or 0)==0 then return end end
 data.IndexClaimed[tier]=true
 local reward=Config.Index.TierRewards[tier] or 0
 CashService.AddCash(player,reward)
 Remotes.IndexSync:FireClient(player,nil,{[tier]=true})
 Remotes.Announcement:FireClient(player,("Index: %s tier complete! +$%s"):format(tier,Format.Compact(reward)))
end

function I.Record(player,card)
 local profile=PlayerData.Get(player)
 local entry=profile and Keys.ById[card:GetAttribute("PlayerId")]
 local bit=entry and Keys.Bit(card:GetAttribute("Variant"),card:GetAttribute("Giant"))
 if not bit then return end
 local data=profile.data
 local old=data.Index[entry.Id] or 0
 local new=bit32.bor(old,bit32.lshift(1,bit))
 if new==old then return end
 data.Index[entry.Id]=new
 Remotes.IndexSync:FireClient(player,{[entry.Id]=new})
 checkTier(player,data,entry.Tier)
 task.spawn(PlayerData.RequestSave,player)
end

function I.Sync(player)
 local profile=PlayerData.Get(player)
 if profile then Remotes.IndexSync:FireClient(player,profile.data.Index,profile.data.IndexClaimed) end
end

function I.Init()
 Remotes.IndexRequest.OnServerEvent:Connect(function(player)
  if (requestAt[player] or 0)>os.clock() then return end
  requestAt[player]=os.clock()+1
  I.Sync(player)
 end)
 local function added(player)
  player:GetAttributeChangedSignal("DataReady"):Connect(function() if player:GetAttribute("DataReady")==true then I.Sync(player) end end)
 end
 Players.PlayerAdded:Connect(added)
 Players.PlayerRemoving:Connect(function(player) requestAt[player]=nil end)
 for _,player in Players:GetPlayers() do added(player) end
end
return I
