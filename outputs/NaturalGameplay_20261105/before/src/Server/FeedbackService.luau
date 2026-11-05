-- Structured private feedback only; no player-to-player messages or public free text.
local Players=game:GetService("Players")
local DSS=game:GetService("DataStoreService")
local Http=game:GetService("HttpService")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Remotes=require(game.ReplicatedStorage.Shared.Remotes)
local F={}
local limits={}
function F.Init()
 local memoryOnly=game:GetService("RunService"):IsStudio() and Config.PlayerData.StudioMemoryOnly
 local store=not memoryOnly and DSS:GetDataStore(Config.PlayerData.ReportStore)
 Remotes.FeedbackRequest.OnServerEvent:Connect(function(player,category,target)
  if player:GetAttribute("DataReady")~=true or type(category)~="string" or not table.find(Config.PlayerData.FeedbackCategories,category) then return end
  if type(target)~="number" or target~=target or target%1~=0 or target<0 then return end
  local day=math.floor(os.time()/86400)
  local state=limits[player] or {day=day,count=0,next=0}
  if state.day~=day then state={day=day,count=0,next=0} end
  limits[player]=state
  if os.clock()<state.next or state.count>=Config.PlayerData.MaxReportsPerDay then Remotes.FeedbackStatus:FireClient(player,"Please wait before sending another report.") return end
  if target~=0 and (target==player.UserId or not Players:GetPlayerByUserId(target)) then return end
  if (category=="Abuse" or category=="Exploiting") and target==0 then Remotes.FeedbackStatus:FireClient(player,"Choose the player you are reporting.") return end
  state.next=os.clock()+Config.PlayerData.ReportCooldown state.count+=1
  local id=Http:GenerateGUID(false)
  local report={Id=id,FromUserId=player.UserId,TargetUserId=target,Category=category,At=os.time(),PlaceId=game.PlaceId,JobId=game.JobId,Status="New"}
  if memoryOnly then
   local f=game.ServerStorage:FindFirstChild("StudioFeedback") or Instance.new("Folder") f.Name="StudioFeedback" f.Parent=game.ServerStorage
   local value=Instance.new("StringValue") value.Name=id value.Value=Http:JSONEncode(report) value.Parent=f
  else
   local ok,result=pcall(function()
    -- One bounded daily inbox; no unfiltered user text is accepted or exposed.
    return store:UpdateAsync("Inbox_"..os.date("!%Y%m%d"),function(old)
     old=type(old)=="table" and old or {}
     local sent=0 for _,v in old do if v.FromUserId==player.UserId then sent+=1 end end
     if #old>=Config.PlayerData.MaxInboxRecords or sent>=Config.PlayerData.MaxReportsPerDay then return nil end
     table.insert(old,report) return old
    end)
   end)
   if not ok or not result then Remotes.FeedbackStatus:FireClient(player,"Could not save your report. Please try later.") return end
  end
  Remotes.FeedbackStatus:FireClient(player,memoryOnly and "Test report recorded for this Studio session." or "Report saved for review. Also use Roblox Report Abuse for safety concerns.")
 end)
 Players.PlayerRemoving:Connect(function(player) limits[player]=nil end)
end
return F
