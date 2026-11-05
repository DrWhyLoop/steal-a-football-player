--[[
	Owner-only purchase support tool for the Studio command bar. Game scripts never require it and no remote exposes it.
	Place it as ServerStorage.PurchaseSupport, then in the command bar:
	  local S = require(game.ServerStorage.PurchaseSupport)
	  S.History(userId)                       -- every logged Robux event for the player, oldest first
	  S.Regrant(userId, "Celestial", "reason") -- re-grants a paid item the player owns but lacks; the reason is logged
	It reads/writes the published data stores, so Game Settings > Security > "Enable Studio Access to API Services" must be on.
	Refunds are handled by Roblox support; this tool only inspects the log and restores an item a verified buyer is missing.
]]
local DSS=game:GetService("DataStoreService")
local Config=require(game.ReplicatedStorage.Shared.Config)
local cfg=Config.Purchases
local S={}
local stores={profile=DSS:GetDataStore(Config.PlayerData.Store),log=DSS:GetDataStore(cfg.LogStore)}
-- Swap in other store objects (same GetAsync/UpdateAsync API), e.g. for a dry run.
function S.UseStores(profile,log) stores={profile=profile,log=log} end
local function logKey(userId) return cfg.LogKeyPrefix..userId end

function S.History(userId)
 local list=stores.log:GetAsync(logKey(userId)) or {}
 table.sort(list,function(a,b) return a.At<b.At end)
 return list
end

-- Returns ok, message. Refuses an empty reason, an unknown item, a missing profile and a player with an active session.
function S.Regrant(userId,key,reason)
 assert(type(userId)=="number" and userId>0,"userId must be a positive number")
 assert(type(reason)=="string" and #reason>=5,"give a reason of at least 5 characters; it is written to the purchase log")
 local known=false
 for _,tier in Config.Treadmills.Catalog do if tier.GamePassId and tier.Id==key then known=true end end
 if not known then return false,"unknown paid item: "..tostring(key) end
 local operator=select(2,pcall(function() return game:GetService("StudioService"):GetUserId() end))
 local outcome
 stores.profile:UpdateAsync(tostring(userId),function(old)
  if type(old)~="table" or type(old.Data)~="table" then outcome="no profile found" return nil end
  if old.Session and old.Session.Expires>os.time() then outcome="the player has an active session; try again after they leave" return nil end
  old.Data.Entitlements=type(old.Data.Entitlements)=="table" and old.Data.Entitlements or {}
  if old.Data.Entitlements[key] then outcome="the player already has this item" return nil end
  old.Data.Entitlements[key]={At=os.time(),Source="Support",Strikes=0}
  outcome="ok"
  return old
 end)
 if outcome~="ok" then return false,outcome end
 stores.log:UpdateAsync(logKey(userId),function(old)
  old=type(old)=="table" and old or {}
  table.insert(old,{Event="SupportRegrant",Key=key,Detail=reason,Operator=type(operator)=="number" and operator or 0,At=os.time(),JobId="support",UserId=userId})
  while #old>cfg.MaxLogEvents do table.remove(old,1) end
  return old
 end)
 return true,"re-granted "..key.." to "..userId
end
return S
