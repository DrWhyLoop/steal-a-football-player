-- Bounded per-player log of every Robux event (UserId, pass/product, price, time, server JobId). Buffered writes keep to the
-- per-key DataStore limit; Studio test sessions keep the log in memory only.
local Players=game:GetService("Players")
local DSS=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local Config=require(game.ReplicatedStorage.Shared.Config)
local cfg=Config.Purchases
local L={}
local memoryOnly=RunService:IsStudio() and Config.PlayerData.StudioMemoryOnly
local store=not memoryOnly and DSS:GetDataStore(cfg.LogStore)
local memory={}   -- [userId]=events (Studio only)
local buffers={}  -- [userId]=events not yet written
local flushing={} -- [userId]=true while a write is in flight
local nextWrite={}
local function key(userId) return cfg.LogKeyPrefix..userId end
local function append(list,events)
 for _,e in events do table.insert(list,e) end
 while #list>cfg.MaxLogEvents do table.remove(list,1) end
 return list
end
function L.Add(userId,event)
 event.At=os.time() event.JobId=game.JobId event.UserId=userId
 buffers[userId]=buffers[userId] or {}
 table.insert(buffers[userId],event)
end
-- Writes everything buffered for one player; returns true when nothing is left unwritten.
function L.Flush(userId)
 while flushing[userId] do task.wait(0.1) end
 flushing[userId]=true
 local ok=true
 while buffers[userId] and #buffers[userId]>0 do
  local wait=(nextWrite[userId] or 0)-os.clock()
  if wait>0 then task.wait(wait) end
  local events=buffers[userId] buffers[userId]=nil
  if memoryOnly then memory[userId]=append(memory[userId] or {},events)
  else
   local written=false
   for attempt=1,Config.PlayerData.Retries do
    local success=pcall(function() store:UpdateAsync(key(userId),function(old) return append(type(old)=="table" and old or {},events) end) end)
    if success then written=true break end
    task.wait(Config.PlayerData.RetrySeconds)
   end
   if not written then buffers[userId]=append(events,buffers[userId] or {}) ok=false warn("[PurchaseLog] Could not write the log for "..userId) break end
  end
  nextWrite[userId]=os.clock()+cfg.LogWriteGapSeconds
 end
 flushing[userId]=nil
 return ok
end
-- Everything recorded for a player, including events not yet flushed.
function L.Read(userId)
 local list={}
 if memoryOnly then list=table.clone(memory[userId] or {})
 else
  local ok,stored=pcall(function() return store:GetAsync(key(userId)) end)
  if ok and type(stored)=="table" then list=stored end
 end
 for _,e in buffers[userId] or {} do table.insert(list,e) end
 return list
end
function L.Init()
 Players.PlayerRemoving:Connect(function(player) task.spawn(L.Flush,player.UserId) end)
 task.spawn(function()
  while true do
   task.wait(cfg.LogFlushSeconds)
   for userId in buffers do task.spawn(L.Flush,userId) end
  end
 end)
 game:BindToClose(function()
  local pending=0
  for userId in buffers do pending+=1 task.spawn(function() L.Flush(userId) pending-=1 end) end
  while pending>0 do task.wait() end
 end)
end
return L
