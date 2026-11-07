--[[
	Purchases: every Robux interaction goes through here (server-authoritative).
	- Game pass items (the Celestial treadmill, the 2x Cash pass and the premium tools): explicit tap -> live-price check -> Roblox's own purchase prompt. Nothing prompts on join.
	- Ownership is stored in the profile (Entitlements). On join a pass the player owns but the profile lacks is re-granted; a refund
	  revokes it only after Config.Purchases.RevokeStrikes confirmed "not owned" results on separate joins at least
	  RevokeStrikeGapSeconds apart. An API error never counts and never resets anything.
	- Developer products (none yet): ProcessReceipt; the grant and the receipt ID are persisted by one profile save (see below).
	- Every event is written to PurchaseLog.
	Studio test mode (Config.Purchases.StudioTestMode, Studio only) swaps Marketplace for a simulation exposed as Purchases.Test.
]]
local Players=game:GetService("Players")
local Marketplace=game:GetService("MarketplaceService")
local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Shared.Config)
local Remotes=require(RS.Shared.Remotes)
local PlayerData=require(script.Parent.PlayerData)
local CashService=require(script.Parent.CashService)
local Log=require(script.Parent.PurchaseLog)
local cfg=Config.Purchases
local testMode=RunService:IsStudio() and cfg.StudioTestMode
local P={}
P.Granted=Instance.new("BindableEvent")  -- (player, key)
P.Revoked=Instance.new("BindableEvent")  -- (player, key)

local passes={} -- game pass items (treadmill catalog passes, Config.CashPass, Config.PremiumTools): [key] = {key, passId}
local byPassId={}
local cooldown={}
local checked={}
local onFinished

-- Simulation used in Studio test mode (never reaches Marketplace). Tests change these fields.
local sim={owned={},price=cfg.TestPrice,forSale=true,outcome="Success",ownsError=false,infoError=false}
P.Test=testMode and sim or nil
local adapter
if testMode then
 adapter={
  Owns=function(userId,passId) if sim.ownsError then error("simulated ownership error") end return sim.owned[userId..":"..passId]==true end,
  Info=function() if sim.infoError then error("simulated info error") end return {IsForSale=sim.forSale,PriceInRobux=sim.price} end,
  Prompt=function(player,passId)
   task.defer(function()
    local success=sim.outcome=="Success"
    if success then sim.owned[player.UserId..":"..passId]=true end
    onFinished(player,passId,success)
   end)
  end,
 }
else
 adapter={
  Owns=function(userId,passId) return Marketplace:UserOwnsGamePassAsync(userId,passId) end,
  Info=function(passId) return Marketplace:GetProductInfoAsync(passId,Enum.InfoType.GamePass) end,
  Prompt=function(player,passId) Marketplace:PromptGamePassPurchase(player,passId) end,
 }
end

local function status(player,text) Remotes.TreadmillStatus:FireClient(player,text) end
local function log(userId,event,pass,detail,price)
 Log.Add(userId,{Event=event,Key=pass and pass.key,PassId=pass and pass.passId,Price=price,Detail=detail})
end
local function data(player) local profile=PlayerData.Get(player) return profile and profile.data end
local function setOwned(player,pass) local d=data(player) player:SetAttribute("PassOwned_"..pass.key,d~=nil and d.Entitlements[pass.key]~=nil) end

-- Live price for display: a positive number, or -1 when the pass is off sale or Roblox cannot be reached (0 = not configured).
local function livePrice(pass)
 if pass.passId==0 then return 0 end
 local ok,info=pcall(adapter.Info,pass.passId)
 local price=ok and info and info.IsForSale and (info.PriceInRobux or 0)>0 and info.PriceInRobux or -1
 return price
end
local function publishPrice(pass) local price=livePrice(pass) RS:SetAttribute("PassPrice_"..pass.key,price) return price end

function P.Owns(player,key)
 local d=data(player)
 return d~=nil and d.Entitlements[key]~=nil
end

local function grant(player,pass,source)
 local d=data(player)
 if not d then log(player.UserId,"GrantFailed",pass,source..": profile not loaded") status(player,"Your purchase will appear when you rejoin.") return end
 d.Entitlements[pass.key]={At=os.time(),Source=source,Strikes=0}
 setOwned(player,pass)
 log(player.UserId,"Granted",pass,source)
 P.Granted:Fire(player,pass.key)
 if not PlayerData.RequestSave(player) then log(player.UserId,"GrantSaveFailed",pass,"the next autosave will retry") end
end

local function revoke(player,pass)
 local d=data(player)
 d.Entitlements[pass.key]=nil
 setOwned(player,pass)
 log(player.UserId,"Revoked",pass,"no longer owned (refund strikes reached)")
 P.Revoked:Fire(player,pass.key)
end

-- Explicit tap only. Every refusal is logged with its reason.
function P.RequestPrompt(player,key,notify)
 local pass=passes[key] if not pass or player:GetAttribute("DataReady")~=true or not data(player) then return end
 local function block(reason,message) log(player.UserId,"PromptBlocked",pass,reason) if notify then notify(message) else status(player,message) end end
 if (cooldown[player] or 0)>os.clock() then block("cooldown","Please wait a few seconds before trying again.") return end
 cooldown[player]=os.clock()+cfg.PromptCooldownSeconds
 if pass.passId==0 then block("notConfigured","This is not available yet.") return end
 if P.Owns(player,key) then block("alreadyOwned","You already own this.") return end
 local shown=RS:GetAttribute("PassPrice_"..key)
 local price=publishPrice(pass)
 if price<=0 then block("unavailable","Price unavailable right now.") return end
 if price~=shown then block("priceChanged","The price changed. Please check it and tap again.") return end
 log(player.UserId,"PromptShown",pass,nil,price)
 adapter.Prompt(player,pass.passId)
end

function onFinished(player,passId,purchased)
 local pass=byPassId[passId] if not pass then return end
 log(player.UserId,"PromptFinished",pass,purchased and "purchased" or "not purchased")
 if not purchased then return end
 local ok,owns=pcall(adapter.Owns,player.UserId,passId)
 log(player.UserId,"OwnershipCheck",pass,ok and ("purchase: owns="..tostring(owns)) or "purchase: error")
 if ok and owns then grant(player,pass,"Purchase")
 else
  log(player.UserId,"GrantFailed",pass,ok and "ownership not confirmed after purchase" or "ownership check failed after purchase")
  status(player,"Your purchase is still processing. It will appear when you rejoin.")
 end
end

-- On join: re-grant owned passes the profile lacks, and apply refund strikes.
local function checkOwnership(player)
 local d=data(player)
 for _,pass in passes do
  if pass.passId~=0 then
   local ok,owns=pcall(adapter.Owns,player.UserId,pass.passId)
   log(player.UserId,"OwnershipCheck",pass,ok and ("join: owns="..tostring(owns)) or "join: error (nothing changed)")
   local entitlement=d.Entitlements[pass.key]
   if ok and owns then
    if not entitlement then grant(player,pass,"Regrant")
    elseif entitlement.Strikes>0 then
     entitlement.Strikes=0 entitlement.LastStrikeAt=nil
     log(player.UserId,"StrikesCleared",pass,"ownership confirmed")
     PlayerData.RequestSave(player)
    end
   elseif ok and entitlement then
    local now=os.time()
    if entitlement.LastStrikeAt and now-entitlement.LastStrikeAt<cfg.RevokeStrikeGapSeconds then
     log(player.UserId,"StrikeSkipped",pass,"too soon after the previous strike")
    else
     entitlement.Strikes+=1 entitlement.LastStrikeAt=now
     log(player.UserId,"RefundStrike",pass,entitlement.Strikes.."/"..cfg.RevokeStrikes)
     if entitlement.Strikes>=cfg.RevokeStrikes then revoke(player,pass) end
     PlayerData.RequestSave(player)
    end
   end
   setOwned(player,pass)
  end
 end
end

-- Developer products. The grant and the receipt ID change together in memory (no yield between them) and are persisted by ONE
-- profile save; PurchaseGranted is returned only after that save succeeded. A crash can therefore only leave "neither saved"
-- (Roblox re-sends the receipt and it is granted) or "both saved" (the re-sent receipt is recognised and not granted again).
-- A receipt that is already being processed on this server is refused with NotProcessedYet.
local receiptsInFlight={}
local function settleReceipt(info,id,record)
 local decision=Enum.ProductPurchaseDecision
 local def=cfg.Products[info.ProductId]
 local player=Players:GetPlayerByUserId(info.PlayerId)
 local profile=player and PlayerData.Get(player)
 if not def then record("ReceiptRejected","unknown product") return decision.NotProcessedYet end
 if not profile or player:GetAttribute("DataReady")~=true then record("ReceiptRejected","player or profile not ready") return decision.NotProcessedYet end
 local receipts=profile.data.Receipts
 local duplicate=receipts[id]~=nil
 if not duplicate then
  CashService.AddCash(player,def.Cash)
  receipts[id]={At=os.time()}
  local count,oldest=0,nil
  for key,r in receipts do count+=1 if key~=id and (not oldest or r.At<receipts[oldest].At) then oldest=key end end
  if count>cfg.MaxReceipts and oldest then receipts[oldest]=nil end
 end
 if not PlayerData.RequestSave(player) then record("ReceiptRejected",(duplicate and "duplicate" or "grant").." could not be saved; Roblox will retry") return decision.NotProcessedYet end
 record(duplicate and "ReceiptDuplicate" or "ReceiptGranted",id)
 return decision.PurchaseGranted
end
function P.ProcessReceipt(info)
 local id=tostring(info.PurchaseId)
 local function record(event,detail) Log.Add(info.PlayerId,{Event=event,ProductId=info.ProductId,Price=info.CurrencySpent,Detail=detail}) end
 record("ReceiptReceived",id)
 if receiptsInFlight[id] then record("ReceiptRejected","this receipt is already being processed") return Enum.ProductPurchaseDecision.NotProcessedYet end
 receiptsInFlight[id]=true
 local ok,decision=pcall(settleReceipt,info,id,record)
 receiptsInFlight[id]=nil
 if not ok then record("ReceiptRejected","error: "..tostring(decision)) return Enum.ProductPurchaseDecision.NotProcessedYet end
 return decision
end

function P.Init()
 local nextTestId=cfg.TestPassId
 local function register(key,gamePassId)
  local passId=gamePassId
  if passId==0 and testMode then passId=nextTestId nextTestId+=1 end -- each unconfigured pass gets its own simulated id in Studio
  local pass={key=key,passId=passId}
  passes[key]=pass byPassId[passId]=pass
 end
 for _,tier in Config.Treadmills.Catalog do
  if tier.GamePassId then register(tier.Id,tier.GamePassId) end
 end
 register(Config.CashPass.Id,Config.CashPass.GamePassId)
 for _,tool in Config.PremiumTools do
  if tool.GamePassId then register(tool.Id,tool.GamePassId) end
 end
 Log.Init()
 Marketplace.ProcessReceipt=P.ProcessReceipt
 Marketplace.PromptGamePassPurchaseFinished:Connect(onFinished)
 task.spawn(function()
  while true do
   for _,pass in passes do publishPrice(pass) end
   task.wait(cfg.PriceRefreshSeconds)
  end
 end)
 local function added(player)
  local function ready()
   if player:GetAttribute("DataReady")~=true then checked[player]=nil return end -- PlayerData clears DataReady at the start of every load
   if checked[player] then return end
   checked[player]=true
   for _,pass in passes do setOwned(player,pass) end
   task.spawn(checkOwnership,player)
  end
  player:GetAttributeChangedSignal("DataReady"):Connect(ready)
  ready()
 end
 Players.PlayerAdded:Connect(added)
 Players.PlayerRemoving:Connect(function(player) cooldown[player]=nil checked[player]=nil end)
 for _,player in Players:GetPlayers() do added(player) end
end
return P
