-- One owned treadmill per assigned plot. Training and cash purchases are server-authoritative.
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Remotes=require(game.ReplicatedStorage.Shared.Remotes)
local Format=require(game.ReplicatedStorage.Shared.NumberFormat)
local Rebirth=require(game.ReplicatedStorage.Shared.Rebirth)
local PlayerData=require(script.Parent.PlayerData)
local Stats=require(script.Parent.PlayerStats)
local Purchases=require(script.Parent.Purchases)
local TrailShop=require(script.Parent.TrailShop)
local UpgradeShop=require(script.Parent.UpgradeShop)
local Service={}
local cfg=Config.Treadmills
local pads={} local training={} local cooldown={} local nextGain={}
local PlotService,CardService
local byId={}
for i,tier in cfg.Catalog do byId[tier.Id]={tier=tier,index=i} end
local function status(player,text) Remotes.TreadmillStatus:FireClient(player,text) end
-- Walking speed from Speed Points: linear in log10(1 + points) between the SpeedCurve points (the last speed is the cap).
local function speed(player)
 local x,curve=math.log10(1+Stats.Get(player,"Speed")),cfg.SpeedCurve
 local previous=curve[1]
 for i=2,#curve do
  local point=curve[i]
  local x0,x1=math.log10(1+previous[1]),math.log10(1+point[1])
  if x<=x1 then return previous[2]+(point[2]-previous[2])*(x-x0)/(x1-x0) end
  previous=point
 end
 return previous[2]
end
function Service.UpdateSpeed(player)
 local char=player.Character local h=char and char:FindFirstChildOfClass("Humanoid")
 if h then
  local card=CardService.GetCarried(player)
  h.WalkSpeed=speed(player)*(card and Config.Tiers[card:GetAttribute("Tier")].WalkSpeed/Config.BaseWalkSpeed or 1)
 end
end
local function stop(player)
 training[player]=nil nextGain[player]=nil player:SetAttribute("Training",false)
end
local function footing(pad,height)
 local old=pad:FindFirstChild("BeltFooting") if old then old:Destroy() end
 local folder=Instance.new("Folder") folder.Name="BeltFooting" folder.Parent=pad
 local belt=Instance.new("Part") belt.Name="WalkableBelt" belt.Size=Vector3.new(cfg.BeltWidth,.2,cfg.BeltLength)
 belt.CFrame=pad.CFrame*CFrame.new(0,height-.1,cfg.BeltCenter) belt.Transparency=1 belt.Anchored=true belt.CanCollide=true belt.CanTouch=false belt.CanQuery=false belt.Parent=folder
 local front=pad.CFrame*Vector3.new(0,height,cfg.BeltCenter+cfg.BeltLength/2)
 local back=pad.CFrame*Vector3.new(0,.1,cfg.BeltCenter+cfg.BeltLength/2+cfg.EntryRun)
 local ramp=Instance.new("Part") ramp.Name="WalkOnRamp" ramp.Size=Vector3.new(cfg.BeltWidth,.15,(front-back).Magnitude)
 ramp.CFrame=CFrame.lookAt((front+back)/2,front) ramp.Anchored=true ramp.Material=Enum.Material.Metal ramp.Color=Color3.fromRGB(40,49,59)
 ramp.CanTouch=false ramp.CanQuery=false ramp.Parent=folder
 pad:SetAttribute("BeltHeight",height)
end
local function onBelt(player,pad)
 local char=player.Character local root=char and char:FindFirstChild("HumanoidRootPart") local h=char and char:FindFirstChildOfClass("Humanoid")
 if not root or not h or h.Health<=0 or CardService.GetCarried(player) or h:GetState()==Enum.HumanoidStateType.Jumping then return false end
 local feet=root.Position-Vector3.new(0,h.HipHeight+root.Size.Y/2,0)
 local p=pad.CFrame:PointToObjectSpace(feet) local height=pad:GetAttribute("BeltHeight") or cfg.BeltHeight
 return math.abs(p.X)<=cfg.BeltWidth/2 and math.abs(p.Z-cfg.BeltCenter)<=cfg.BeltLength/2 and math.abs(p.Y-height)<=.7
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
 pad:SetAttribute("OwnerUserId",player.UserId)
 footing(pad,visual:GetAttribute("BeltHeight") or cfg.BeltHeight)
 pad.Label.Enabled=true
end
local function request(player,action,id)
 if player:GetAttribute("DataReady")~=true or type(action)~="string" or (cooldown[player] or 0)>os.clock() then return end
 cooldown[player]=os.clock()+cfg.RequestCooldown
 if action=="Premium" and id==Config.CashPass.Id then Purchases.RequestPrompt(player,id) return end
 if type(id)~="string" or not byId[id] then return end
 local entry=byId[id] local tier=entry.tier
 if action=="Buy" and tier.Cost then
  local owned=player:GetAttribute("CashTreadmillTier") or 1
  if entry.index~=owned+1 then status(player,"Buy the next cash upgrade in order.") return end
  if Stats.Get(player,"Cash")<tier.Cost then status(player,"Not enough cash.") return end
  Stats.Add(player,"Cash",-tier.Cost)
  player:SetAttribute("CashTreadmillTier",entry.index) player:SetAttribute("TreadmillId",id)
  PlayerData.RecordPurchase(player,id,tier.Cost,"Cash")
 elseif action=="Equip" then
  if tier.GamePassId then if not Purchases.Owns(player,id) then status(player,"You do not own this treadmill.") return end
  elseif entry.index>(player:GetAttribute("CashTreadmillTier") or 1) then return end
  player:SetAttribute("TreadmillId",id)
 elseif action=="Premium" then Purchases.RequestPrompt(player,id) return
 else return end
 stop(player) rebuild(player) status(player,"Treadmill ready.") task.spawn(PlayerData.RequestSave,player)
end
local function added(player)
 local function ready()
  if player:GetAttribute("DataReady")~=true then return end
  rebuild(player) Service.UpdateSpeed(player)
 end
 player:GetAttributeChangedSignal("DataReady"):Connect(ready)
 for _,key in {"CarriedCard","Speed"} do player:GetAttributeChangedSignal(key):Connect(function() Service.UpdateSpeed(player) end) end
 player.CharacterAdded:Connect(function(char)
  char:WaitForChild("Humanoid") char:WaitForChild("HumanoidRootPart") stop(player) Service.UpdateSpeed(player)
 end)
 ready()
end
function Service.Init(plotService,cardService)
 PlotService=plotService CardService=cardService
 local old=workspace.Greybox:FindFirstChild("OwnedTreadmills") if old then old:Destroy() end
 local folder=Instance.new("Folder") folder.Name="OwnedTreadmills" folder.Parent=workspace.Greybox
 for _,plot in PlotService.GetPlots() do
  local base=plot.Base local sign
  -- Determine the outside row relative to the midpoint between the six plots.
  local center=0 for _,p in PlotService.GetPlots() do center+=p.Base.Position.X end center/=#PlotService.GetPlots()
  sign=base.Position.X>center and 1 or -1
  local pad=Instance.new("Part") pad.Name=plot.Name.."_Treadmill" pad.Size=Vector3.new(cfg.TemplateSize.X,.25,cfg.TemplateSize.Z)
  pad.CFrame=CFrame.new(base.Position.X-sign*cfg.PlotOffset,cfg.GroundY,base.Position.Z+sign*cfg.EntrySideOffset)*CFrame.Angles(0,-sign*math.pi/2,0)
  pad.Anchored=true pad.Material=Enum.Material.Slate pad.Color=Color3.fromRGB(37,45,55) pad.Parent=folder
  local gui=Instance.new("BillboardGui") gui.Name="Label" gui.Size=UDim2.fromOffset(210,40) gui.StudsOffset=Vector3.new(0,8,0) gui.MaxDistance=25 gui.Enabled=false gui.Parent=pad
  local text=Instance.new("TextLabel") text.Name="Info" text.BackgroundTransparency=1 text.Size=UDim2.fromScale(1,1) text.TextScaled=true text.Font=Enum.Font.GothamBold text.TextColor3=Color3.new(1,1,1) text.Text="Unowned treadmill" text.Parent=gui
  pads[plot]=pad
 end
 PlotService.PlotAssigned.Event:Connect(function(_,player) if player:GetAttribute("DataReady") then rebuild(player) end end)
 PlotService.PlotFreed.Event:Connect(function(plot,player) stop(player) local pad=pads[plot] local v=pad:FindFirstChild("Visual") if v then v:Destroy() end local f=pad:FindFirstChild("BeltFooting") if f then f:Destroy() end pad:SetAttribute("OwnerUserId",0) pad.Label.Info.Text="" pad.Label.Enabled=false end)
 Remotes.TreadmillRequest.OnServerEvent:Connect(request)
 Purchases.Granted.Event:Connect(function(player,key) if not byId[key] then return end player:SetAttribute("TreadmillId",key) stop(player) rebuild(player) status(player,"Treadmill ready.") end)
 Purchases.Revoked.Event:Connect(function(player,key)
  if not byId[key] or player:GetAttribute("TreadmillId")~=key then return end
  player:SetAttribute("TreadmillId",cfg.Catalog[player:GetAttribute("CashTreadmillTier") or 1].Id) stop(player) rebuild(player) status(player,"Treadmill updated.")
 end)
 Players.PlayerAdded:Connect(added)
 Players.PlayerRemoving:Connect(function(player) stop(player) cooldown[player]=nil end)
 for _,player in Players:GetPlayers() do added(player) end
 task.spawn(function() while true do task.wait(cfg.SensorSeconds)
  for _,player in Players:GetPlayers() do
   local plot=PlotService.GetPlot(player) local pad=plot and pads[plot]
   local valid=player:GetAttribute("DataReady")==true and pad and pad:FindFirstChild("Visual") and onBelt(player,pad)
   if valid then
    if not training[player] then training[player]=pad player:SetAttribute("Training",true) nextGain[player]=os.clock()+cfg.TickSeconds end
    if os.clock()>=(nextGain[player] or math.huge) then
     nextGain[player]=os.clock()+cfg.TickSeconds
     local tier=byId[player:GetAttribute("TreadmillId")].tier
     Stats.Add(player,"Speed",cfg.BaseGain*tier.Multiplier*TrailShop.Multiplier(player)*Rebirth.Gain(player:GetAttribute("Rebirths") or 0)*(1+UpgradeShop.Bonus(player,"Speed")))
    end
   elseif training[player] then stop(player) end
  end
 end end)
end
return Service
