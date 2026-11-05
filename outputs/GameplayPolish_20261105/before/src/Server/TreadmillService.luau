-- One owned treadmill per assigned plot. Training and cash purchases are server-authoritative.
local Players=game:GetService("Players")
local Marketplace=game:GetService("MarketplaceService")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Remotes=require(game.ReplicatedStorage.Shared.Remotes)
local Format=require(game.ReplicatedStorage.Shared.NumberFormat)
local PlayerData=require(script.Parent.PlayerData)
local Service={}
local cfg=Config.Treadmills
local pads={} local training={} local cooldown={} local passOwned={}
local PlotService,CardService
local byId={}
for i,tier in cfg.Catalog do byId[tier.Id]={tier=tier,index=i} end
local function status(player,text) Remotes.TreadmillStatus:FireClient(player,text) end
local function speed(player)
 local stats=player:FindFirstChild("leaderstats")
 local points=stats and stats:FindFirstChild("Speed")
 return math.min(cfg.MaxWalkSpeed,cfg.MovementBase+cfg.MovementPerLog*math.log10(1+(points and points.Value or 0)/cfg.PointsPerScale))
end
function Service.UpdateSpeed(player)
 local char=player.Character local h=char and char:FindFirstChildOfClass("Humanoid")
 if h then
  local card=CardService.GetCarried(player)
  h.WalkSpeed=speed(player)*(card and Config.Tiers[card:GetAttribute("Tier")].WalkSpeed/Config.BaseWalkSpeed or 1)
 end
 player:SetAttribute("MovementSpeed",speed(player))
end
local function stop(player)
 training[player]=nil player:SetAttribute("Training",false)
 local char=player.Character local root=char and char:FindFirstChild("HumanoidRootPart")
 if root then root.Anchored=false end
end
local function rebuild(player)
 local plot=PlotService.GetPlot(player) local pad=plot and pads[plot]
 if not pad then return end
 local old=pad:FindFirstChild("Visual") if old then old:Destroy() end
 local tier=byId[player:GetAttribute("TreadmillId")] or byId.Base
 local visual=game.ServerStorage.TreadmillTemplates[tier.tier.Id]:Clone() visual.Name="Visual"
 visual:PivotTo(pad.CFrame*CFrame.new(0,visual:GetAttribute("Height")/2+pad.Size.Y/2,0))
 visual.Parent=pad
 pad.Label.Info.Text=tier.tier.Name.." | "..Format.Exact(tier.tier.Multiplier).."x Training"
 pad.UsePrompt.Enabled=true
end
local function start(player,plot)
 if player:GetAttribute("DataReady")~=true or PlotService.GetOwner(plot)~=player then return end
 if training[player] then stop(player) return end
 local char=player.Character local root=char and char:FindFirstChild("HumanoidRootPart") local h=char and char:FindFirstChildOfClass("Humanoid")
 local pad=pads[plot]
 if not root or not h or h.Health<=0 or CardService.GetCarried(player) or (root.Position-pad.Position).Magnitude>cfg.InteractionDistance then return end
 training[player]=pad player:SetAttribute("Training",true)
 -- Stationary training preserves standard avatar walking; jumping leaves the treadmill.
 root.CFrame=pad.CFrame*CFrame.new(0,cfg.TrainingStandHeight,0)
 root.Anchored=true
end
local function request(player,action,id)
 if player:GetAttribute("DataReady")~=true or type(action)~="string" or (cooldown[player] or 0)>os.clock() then return end
 cooldown[player]=os.clock()+cfg.RequestCooldown
 if action=="Stop" then stop(player) return end
 if action=="Train" then local plot=PlotService.GetPlot(player) if plot then start(player,plot) end return end
 if type(id)~="string" or not byId[id] then return end
 local entry=byId[id] local tier=entry.tier
 if action=="Buy" and tier.Cost then
  local owned=player:GetAttribute("CashTreadmillTier") or 1
  if entry.index~=owned+1 then status(player,"Buy the next cash upgrade in order.") return end
  local cash=player.leaderstats.Cash
  if cash.Value<tier.Cost then status(player,"Not enough cash.") return end
  cash.Value-=tier.Cost
  player:SetAttribute("CashTreadmillTier",entry.index) player:SetAttribute("TreadmillId",id)
  PlayerData.RecordPurchase(player,id,tier.Cost,"Cash")
 elseif action=="Equip" then
  if tier.GamePassId then if not passOwned[player] then status(player,"Premium is not configured.") return end
  elseif entry.index>(player:GetAttribute("CashTreadmillTier") or 1) then return end
  player:SetAttribute("TreadmillId",id)
 elseif action=="Premium" then
  if not tier.GamePassId or tier.GamePassId<=0 then status(player,"Premium purchasing is not available yet.") return end
  local ok,info=pcall(Marketplace.GetProductInfoAsync,Marketplace,tier.GamePassId,Enum.InfoType.GamePass)
  if not ok or not info.IsForSale or info.PriceInRobux~=tier.ExpectedRobux then status(player,"Premium price is awaiting setup.") return end
  Marketplace:PromptGamePassPurchase(player,tier.GamePassId) return
 else return end
 stop(player) rebuild(player) status(player,"Treadmill ready.") task.spawn(PlayerData.Save,player,false)
end
local function added(player)
 local function ready()
  if player:GetAttribute("DataReady")~=true then return end
  rebuild(player) Service.UpdateSpeed(player)
  local premium=cfg.Catalog[#cfg.Catalog]
  if premium.GamePassId>0 then
   local ok,owns=pcall(Marketplace.UserOwnsGamePassAsync,Marketplace,player.UserId,premium.GamePassId)
   if ok and owns then passOwned[player]=true player:SetAttribute("PremiumTreadmillOwned",true) end
  end
 end
 player:GetAttributeChangedSignal("DataReady"):Connect(ready)
 player:GetAttributeChangedSignal("CarriedCard"):Connect(function() Service.UpdateSpeed(player) end)
 player.CharacterAdded:Connect(function(char)
  char:WaitForChild("Humanoid") char:WaitForChild("HumanoidRootPart") stop(player) Service.UpdateSpeed(player)
 end)
 ready()
end
function Service.Init(plotService,cardService)
 PlotService=plotService CardService=cardService
 local folder=Instance.new("Folder") folder.Name="OwnedTreadmills" folder.Parent=workspace.Greybox
 for _,plot in game:GetService("CollectionService"):GetTagged("Plot") do
  local base=plot.Base local sign
  -- Determine the outside row relative to the midpoint between the six plots.
  local center=0 for _,p in game:GetService("CollectionService"):GetTagged("Plot") do center+=p.Base.Position.X end center/=6
  sign=base.Position.X>center and 1 or -1
  local pad=Instance.new("Part") pad.Name=plot.Name.."_Treadmill" pad.Size=Vector3.new(cfg.TemplateSize.X,.25,cfg.TemplateSize.Z)
  pad.CFrame=CFrame.new(base.Position.X-sign*cfg.PlotOffset,cfg.GroundY,base.Position.Z)
  pad.Anchored=true pad.Material=Enum.Material.Slate pad.Color=Color3.fromRGB(37,45,55) pad.Parent=folder
  local gui=Instance.new("BillboardGui") gui.Name="Label" gui.Size=UDim2.fromOffset(210,40) gui.StudsOffset=Vector3.new(0,8,0) gui.MaxDistance=60 gui.Parent=pad
  local text=Instance.new("TextLabel") text.Name="Info" text.BackgroundTransparency=1 text.Size=UDim2.fromScale(1,1) text.TextScaled=true text.Font=Enum.Font.GothamBold text.TextColor3=Color3.new(1,1,1) text.Text="Unowned treadmill" text.Parent=gui
  local prompt=Instance.new("ProximityPrompt") prompt.Name="UsePrompt" prompt.ActionText="Train / stop" prompt.ObjectText="Your treadmill" prompt.MaxActivationDistance=cfg.InteractionDistance prompt.HoldDuration=.2 prompt.Enabled=false prompt.Parent=pad
  prompt.Triggered:Connect(function(player) start(player,plot) end) pads[plot]=pad
 end
 PlotService.PlotAssigned.Event:Connect(function(_,player) if player:GetAttribute("DataReady") then rebuild(player) end end)
 PlotService.PlotFreed.Event:Connect(function(plot,player) stop(player) local pad=pads[plot] local v=pad:FindFirstChild("Visual") if v then v:Destroy() end pad.UsePrompt.Enabled=false pad.Label.Info.Text="Unowned treadmill" end)
 Remotes.TreadmillRequest.OnServerEvent:Connect(request)
 Marketplace.PromptGamePassPurchaseFinished:Connect(function(player,id,purchased)
  local premium=cfg.Catalog[#cfg.Catalog]
  if not purchased or id~=premium.GamePassId or premium.GamePassId<=0 then return end
  local ok,owns=pcall(Marketplace.UserOwnsGamePassAsync,Marketplace,player.UserId,id)
  if ok and owns then
   passOwned[player]=true player:SetAttribute("PremiumTreadmillOwned",true)
   PlayerData.RecordPurchase(player,premium.Id,nil,"GamePass entitlement")
   request(player,"Equip",premium.Id)
  end
 end)
 Players.PlayerAdded:Connect(added)
 Players.PlayerRemoving:Connect(function(player) stop(player) cooldown[player]=nil passOwned[player]=nil end)
 for _,player in Players:GetPlayers() do added(player) end
 task.spawn(function() while true do task.wait(cfg.TickSeconds)
  for player,pad in training do
   local char=player.Character local root=char and char:FindFirstChild("HumanoidRootPart") local h=char and char:FindFirstChildOfClass("Humanoid")
   if not root or not h or h.Health<=0 or h.Jump or (root.Position-pad.Position).Magnitude>cfg.TrainingRadius or CardService.GetCarried(player) then stop(player)
   else
    local tier=byId[player:GetAttribute("TreadmillId")].tier
    local gain=cfg.BaseGain*tier.Multiplier -- trail/global factors remain 1 until those systems exist
    player.leaderstats.Speed.Value=math.min(Config.PlayerData.MaxSpeedPoints,player.leaderstats.Speed.Value+gain)
    Service.UpdateSpeed(player)
   end
  end
 end end)
end
return Service
