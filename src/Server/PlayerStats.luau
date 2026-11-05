-- Real balances live in player attributes (Cash, Speed). The leaderstats folder only holds formatted text for the leaderboard, so
-- nothing may read it back. All balance reads/writes go through here.
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Format=require(game.ReplicatedStorage.Shared.NumberFormat)
local Stats={}
local caps={Cash=Config.PlayerData.MaxCash,Speed=Config.PlayerData.MaxSpeedPoints}
function Stats.Get(player,key) return player:GetAttribute(key) or 0 end
function Stats.Set(player,key,value)
 value=math.clamp(value,0,caps[key])
 player:SetAttribute(key,value)
 local text=player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild(key)
 if text then text.Value=Format.Compact(value) end
end
function Stats.Add(player,key,delta) Stats.Set(player,key,Stats.Get(player,key)+delta) end
function Stats.Setup(player)
 if player:FindFirstChild("leaderstats") then return end
 local folder=Instance.new("Folder") folder.Name="leaderstats"
 for key in caps do Instance.new("StringValue",folder).Name=key end
 folder.Parent=player
 for key in caps do Stats.Set(player,key,0) end
end
return Stats
