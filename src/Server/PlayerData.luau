-- Server-owned profile snapshots with expiring session locks. Studio tests are memory-only.
local Players=game:GetService("Players")
local DSS=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local Config=require(game.ReplicatedStorage.Shared.Config)
local P={}
local settings=Config.PlayerData
local profiles={}
local memory={}
local store
local session=game.JobId~="" and game.JobId or HttpService:GenerateGUID(false)
local PlotService,SlotService,CardService
local function defaults()
 return {Cash=0,SpeedPoints=0,CashTier=1,TreadmillId="Base",Slots={},SafeCargo={},PlaySeconds=0,Visits=0,FirstSeen=os.time(),PurchaseHistory={}}
end
local function finite(n,maximum)
 return type(n)=="number" and n==n and n>=0 and n<=maximum
end
local function sanitize(d)
 local clean=defaults()
 if type(d)~="table" then return clean end
 for key,max in {Cash=settings.MaxCash,SpeedPoints=settings.MaxSpeedPoints,PlaySeconds=settings.MaxSpeedPoints,Visits=settings.MaxSpeedPoints,FirstSeen=os.time()} do
  if finite(d[key],max) then clean[key]=d[key] end
 end
 if finite(d.CashTier,#Config.Treadmills.Catalog-1) and d.CashTier>=1 then clean.CashTier=math.floor(d.CashTier) end
 if type(d.TreadmillId)=="string" then clean.TreadmillId=d.TreadmillId end
 if type(d.Slots)=="table" then clean.Slots=d.Slots end
 if type(d.SafeCargo)=="table" then clean.SafeCargo=d.SafeCargo end
 if type(d.PurchaseHistory)=="table" then
  for i=math.max(1,#d.PurchaseHistory-settings.MaxPurchaseHistory+1),#d.PurchaseHistory do table.insert(clean.PurchaseHistory,d.PurchaseHistory[i]) end
 end
 return clean
end
function P.Get(player) return profiles[player] end
function P.RecordPurchase(player,id,cost,currency)
 local p=profiles[player] if not p then return end
 table.insert(p.data.PurchaseHistory,{Id=id,Cost=cost,Currency=currency,At=os.time()})
 if #p.data.PurchaseHistory>settings.MaxPurchaseHistory then table.remove(p.data.PurchaseHistory,1) end
end
local function snapshot(player)
 local p=profiles[player] if not p then return end
 local d=p.data local stats=player:FindFirstChild("leaderstats")
 if stats then d.Cash=stats.Cash.Value d.SpeedPoints=stats.Speed.Value end
 d.CashTier=player:GetAttribute("CashTreadmillTier") or 1
 d.TreadmillId=player:GetAttribute("TreadmillId") or "Base"
 local plot=PlotService.GetPlot(player)
 if plot and not p.released then d.Slots=SlotService.Export(plot,p.leaving) d.SafeCargo=CardService.ExportSecured(player) end
 d.PlaySeconds=p.initialPlay+math.floor(os.clock()-p.started)
 d.LastSeen=os.time()
 return d
end
function P.Save(player,releasing)
 local p=profiles[player] if not p then return false end
 while p.saving do task.wait() end
 if p.closed then return true end
 p.saving=true p.lastStart=os.clock()
 local d=snapshot(player)
 if not store then memory[player.UserId]=table.clone(d) p.saving=false p.closed=releasing return true end
 local success=false
 for attempt=1,settings.Retries do
  local ok,result=pcall(function()
   return store:UpdateAsync(tostring(player.UserId),function(old)
    if not old or not old.Session or old.Session.Id~=session then return nil end
    local record={Version=1,Data=d}
    if not releasing then record.Session={Id=session,Expires=os.time()+settings.LockSeconds} end
    return record
   end)
  end)
  if ok and result then success=true break end
  if attempt<settings.Retries then task.wait(settings.RetrySeconds) end
 end
 p.saving=false p.closed=releasing and success
 player:SetAttribute("LastSaveOK",success)
 if not success then
  warn("[PlayerData] Could not save profile for "..player.UserId)
  if os.clock()-p.lastSaved>settings.LockSeconds-settings.AutosaveSeconds and player.Parent then
   player:SetAttribute("DataReady",false) player:Kick("Your progress could not be saved. Please rejoin.")
  end
 else p.lastSaved=os.clock() end
 return success
end
-- Forced saves (treadmill purchase, steal transfer) merge into one pending save and respect the per-key write limit.
-- Yields until the save covering this request has finished and returns whether it succeeded.
function P.RequestSave(player)
 local p=profiles[player] if not p then return false end
 if not p.pending then
  p.pending=true
  task.delay(math.max(0,settings.SaveCoalesceSeconds-(os.clock()-p.lastStart)),function() p.pendingOk=P.Save(player,false) p.pending=false end)
 end
 while p.pending do task.wait() end
 return p.pendingOk
end
local function load(player)
 player:SetAttribute("DataReady",false)
 local data
 if not store then data=sanitize(memory[player.UserId])
 else
  for attempt=1,settings.Retries do
   local ok,result=pcall(function()
    return store:UpdateAsync(tostring(player.UserId),function(old)
     if old and old.Session and old.Session.Id~=session and old.Session.Expires>os.time() then return nil end
     return {Version=1,Data=sanitize(old and old.Data),Session={Id=session,Expires=os.time()+settings.LockSeconds}}
    end)
   end)
   if ok and result then data=result.Data break end
   if attempt<settings.Retries then task.wait(settings.RetrySeconds) end
  end
 end
 if not data then if player.Parent then player:Kick("Progress is unavailable or open in another server. Please rejoin shortly.") end return end
 profiles[player]={data=data,started=os.clock(),initialPlay=data.PlaySeconds,lastSaved=os.clock(),lastStart=os.clock()}
 if not player.Parent then P.Save(player,true) profiles[player]=nil return end
 local stats=player:WaitForChild("leaderstats")
 local speed=Instance.new("NumberValue") speed.Name="Speed" speed.Value=data.SpeedPoints speed.Parent=stats
 stats.Cash.Value=data.Cash
 player:SetAttribute("CashTreadmillTier",data.CashTier)
 local selected=Config.Treadmills.Catalog[data.CashTier]
 player:SetAttribute("TreadmillId",selected.Id)
 data.Visits+=1
 local plot=PlotService.GetPlot(player)
 if plot then SlotService.Restore(plot,data.Slots) CardService.RestoreSecured(player,data.SafeCargo) end
 player:SetAttribute("PersistenceMode",store and "Saved" or "Studio session only")
 player:SetAttribute("DataReady",true)
end
function P.Init(plotService,slotService,cardService)
 PlotService=plotService SlotService=slotService CardService=cardService
 if not (RunService:IsStudio() and settings.StudioMemoryOnly) then store=DSS:GetDataStore(settings.Store) end
 PlotService.BeforeRelease=function(player) local p=profiles[player] if p then p.leaving=true end snapshot(player) if p then p.released=true end end
 Players.PlayerAdded:Connect(function(player) task.spawn(load,player) end)
 Players.PlayerRemoving:Connect(function(player) local p=profiles[player] if p then p.leaving=true end P.Save(player,true) profiles[player]=nil end)
 for _,player in Players:GetPlayers() do task.spawn(load,player) end
 task.spawn(function() while true do task.wait(settings.AutosaveSeconds)
  for player in profiles do task.spawn(P.Save,player,false) end
 end end)
 game:BindToClose(function()
  local pending=0
  for player in profiles do pending+=1 task.spawn(function() P.Save(player,true) pending-=1 end) end
  while pending>0 do task.wait() end
 end)
end
return P
