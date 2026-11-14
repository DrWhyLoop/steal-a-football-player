-- Client-only occupants, falling cage fragments and the white-character transformation.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local CS=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Config=require(RS.Shared.Config)
local UIKit=require(script.Parent.UIKit)
local Math=require(RS.Shared.RewardMath)
local Fit=require(RS.Shared.CageFit)
local Occupant=require(RS.Shared.CageOccupant)
local Remotes=require(RS.Shared.Remotes)
local Template=RS:WaitForChild("CageOccupantTemplate")
local R=Config.Reveal
local V=Config.EvolutionVFX
local Evolution=RS:WaitForChild("VFXLibrary"):WaitForChild("Evolution")
local activeBursts=0
local burstCards=setmetatable({},{__mode="k"})
local Effects={}
local active=0
local idle={}
local handled=setmetatable({},{__mode="k"})

-- One short, low-level puff/ring after the white character has transformed.
local function evolutionBurst(card)
 local root=Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if not card or not card.Parent or burstCards[card] or not root or activeBursts>=V.MaxConcurrent or (root.Position-card.Position).Magnitude>V.Distance then return end
 burstCards[card]=true activeBursts+=1
 local variant=card:GetAttribute("Variant") or "Normal"
 local size=Config.RewardSizeById[card:GetAttribute("SizeTier")] or Config.RewardSizeById.Normal
 local rare=variant~="Normal" or size.Scale>1
 local scale=rare and V.RareScale or 1
 local anchor=Instance.new("Part") anchor.Name="EvolutionBurst" anchor.Size=Vector3.one anchor.Transparency=1 anchor.Anchored=true
 anchor.CanCollide=false anchor.CanTouch=false anchor.CanQuery=false
 anchor.Position=Vector3.new(card.Position.X,card.Position.Y-card.Size.Y/2+V.Height,card.Position.Z)
 anchor:SetAttribute("CageRevealId",card:GetAttribute("CageRevealId"))
 local attachment=Instance.new("Attachment") attachment.Parent=anchor
 local smoke=Evolution.Smoke:Clone() smoke.Enabled=false smoke.Rate=0
 smoke.Lifetime=V.SmokeLifetime smoke.Speed=V.SmokeSpeed smoke.Rotation=V.SmokeRotation smoke.RotSpeed=V.SmokeSpin
 smoke.SpreadAngle=V.SmokeSpread smoke.EmissionDirection=Enum.NormalId.Top smoke.Acceleration=Vector3.new(0,V.SmokeLift,0) smoke.Drag=V.SmokeDrag
 smoke.Color=ColorSequence.new(V.SmokeColor) smoke.LightEmission=V.SmokeEmission smoke.LightInfluence=.5
 smoke.Orientation=Enum.ParticleOrientation.FacingCamera smoke.LockedToPart=false
 smoke.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,V.SmokeSize[1]*scale),NumberSequenceKeypoint.new(.4,V.SmokeSize[2]*scale),NumberSequenceKeypoint.new(1,V.SmokeSize[3]*scale)})
 smoke.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,V.SmokeTransparency[1]),NumberSequenceKeypoint.new(.25,V.SmokeTransparency[2]),NumberSequenceKeypoint.new(1,V.SmokeTransparency[3])})
 smoke.Parent=attachment
 local ring=Evolution.Ring:Clone() ring.Enabled=false ring.Rate=0 ring.Lifetime=V.RingLifetime
 ring.Speed=NumberRange.new(V.RingSpeed) ring.SpreadAngle=Vector2.zero ring.Acceleration=Vector3.zero ring.Drag=0
 ring.EmissionDirection=Enum.NormalId.Top ring.Orientation=Enum.ParticleOrientation.VelocityPerpendicular ring.LockedToPart=true
 local tint=Config.Variants[variant] and Config.Variants[variant].Tint or Color3.new(1,1,1)
 ring.Color=ColorSequence.new(V.RingColor:Lerp(tint,V.VariantBlend)) ring.LightEmission=V.RingEmission ring.LightInfluence=0
 ring.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,V.RingSize[1]*scale),NumberSequenceKeypoint.new(.25,V.RingSize[2]*scale),NumberSequenceKeypoint.new(1,V.RingSize[3]*scale)})
 ring.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,V.RingTransparency[1]),NumberSequenceKeypoint.new(.15,V.RingTransparency[2]),NumberSequenceKeypoint.new(1,V.RingTransparency[3])})
 ring.Parent=attachment
 local count=rare and V.RareSmokeCount or V.SmokeCount
 anchor:SetAttribute("SmokeCount",count) anchor:SetAttribute("RingCount",V.RingCount)
 anchor.Parent=workspace smoke:Emit(count) ring:Emit(V.RingCount)
 Debris:AddItem(anchor,V.Duration)
 task.delay(V.Duration,function() activeBursts-=1 end)
end

local function hide(cage)
 local visual=cage:FindFirstChild("CageVisual")
 if visual then for _,v in visual:GetDescendants() do if v:IsA("BasePart") then v.LocalTransparencyModifier=1 end end end
 for _,v in cage:GetDescendants() do
  if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail") or v:IsA("Highlight") then v.Enabled=false end
 end
end
local function removeIdle(cage)
 local actor=idle[cage]
 if actor then actor:RemoveTag(Config.Npc.Tag) actor:Destroy() idle[cage]=nil end
end
local function addIdle(cage)
 local visual=cage:FindFirstChild("CageVisual")
 if not visual or not visual:FindFirstChildWhichIsA("BasePart",true) then return end
 local actor=Occupant.Create(Template,visual,nil,cage:GetAttribute("CageGroundY") or cage.Position.Y-cage.Size.Y/2)
 actor:SetAttribute("LiveCage",true) actor.Parent=cage actor:AddTag(Config.Npc.Tag) idle[cage]=actor
end
local function debrisParts(visual,container,center,seed,budget)
 local rng=Random.new(seed)
 local pieces={}
 local function add(part,home)
  part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
  part.LocalTransparencyModifier=0 part.CFrame=home part.Parent=container
  local d=Vector3.new(home.X-center.X,0,home.Z-center.Z)
  if d.Magnitude<.01 then local a=rng:NextNumber(0,2*math.pi) d=Vector3.new(math.cos(a),0,math.sin(a)) end
  table.insert(pieces,{part=part,home=home,direction=d.Unit,distance=R.DebrisDistance*rng:NextNumber(.7,1.1),
   turn=Vector3.new(rng:NextNumber(-1,1),rng:NextNumber(-1,1),rng:NextNumber(-1,1))*R.DebrisTurns*math.pi,transparency=part.Transparency})
 end
 for _,v in visual:GetDescendants() do
  if #pieces>=budget then break end
  if v:IsA("BasePart") and v.Transparency<1 then
   if v:GetAttribute("FractureShell") then
    for _=1,math.min(R.ShellFragments,budget-#pieces) do
     local p=Instance.new("Part") p.Name="ShellFragment" p.Size=v.Size*R.FragmentScale
     p.Color=v.Color p.Material=v.Material p.Transparency=v.Transparency
     local offset=Vector3.new(rng:NextNumber(-.4,.4),rng:NextNumber(-.4,.4),rng:NextNumber(-.4,.4))*v.Size
     add(p,v.CFrame*CFrame.new(offset))
    end
   else
    local p=v:Clone()
    for _,child in p:GetChildren() do
     if not (child:IsA("Decal") or child:IsA("Texture") or child:IsA("SpecialMesh") or child:IsA("SurfaceAppearance")) then child:Destroy() end
    end
    add(p,v.CFrame)
   end
  end
 end
 return pieces
end
local function hatch(cage,luck,duration,started,revealId)
 local root=Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if not cage or not cage.Parent or handled[cage] or not root or (root.Position-cage.Position).Magnitude>R.MaxDistance then return end
 local original=cage:FindFirstChild("CageVisual")
 if not original then return end
 handled[cage]=true
 started=started or cage:GetAttribute("RevealStart")
 revealId=revealId or cage:GetAttribute("RevealId")
 local ground=cage:GetAttribute("CageGroundY") or cage.Position.Y-cage.Size.Y/2
 local actor=idle[cage] or Occupant.Create(Template,original,nil,ground)
 idle[cage]=nil actor:SetAttribute("RevealActive",true) actor:RemoveTag(Config.Npc.Tag)
 for _,joint in actor:GetDescendants() do if joint:IsA("Motor6D") then joint.Transform=CFrame.identity end end
 local floor=actor:GetAttribute("InteriorFloorY")
 Fit.ApplyPose(actor,floor+Config.Npc.CagePreview.FloorClearance)
 local effect=Instance.new("Model") effect.Name="CageCharacterReveal" effect:SetAttribute("RevealId",revealId)
 local fragments=Instance.new("Folder") fragments.Name="Fragments" fragments.Parent=effect
 actor.Name="WhiteRevealCharacter" actor.Parent=effect
 local heavy=active<R.MaxConcurrent
 if heavy then active+=1 end
 local pieces=debrisParts(original,fragments,cage.Position,cage:GetAttribute("RevealSeed") or 1,heavy and R.MaxDebrisParts or R.MaxLightDebrisParts)
 effect:SetAttribute("SourceCageDesign",cage:GetAttribute("CageDesign"))
 effect:SetAttribute("DebrisCount",#pieces)
 hide(cage) effect.Parent=workspace
 local anchor=Instance.new("Part") anchor.Name="LuckCounter" anchor.Size=Vector3.one anchor.Anchored=true anchor.Transparency=1
 anchor.CanCollide=false anchor.CanTouch=false anchor.CanQuery=false anchor.Parent=effect
 local gui=Instance.new("BillboardGui") gui.Size=UDim2.fromOffset(240,40) gui.AlwaysOnTop=true gui.Adornee=anchor gui.Parent=anchor
 local counter=Instance.new("TextLabel") counter.Size=UDim2.fromScale(1,1) counter.BackgroundTransparency=1 counter.TextScaled=true
 counter.Font=Enum.Font.GothamBlack counter.TextColor3=R.CounterColor counter.TextStrokeTransparency=.2 counter.Parent=gui
 local tick=Instance.new("Sound") tick.SoundId=R.TickSoundId tick.Volume=R.TickVolume tick.Parent=anchor
 local pop=Instance.new("Sound") pop.SoundId=R.PopSoundId pop.Volume=R.PopSoundVolume pop.Parent=anchor pop:Play()
 local initialScale=actor:GetScale()
 local _,growth,growthScale=Math.Reveal(luck)
 local began=started or workspace:GetServerTimeNow()
 local nextTick,glowing,swapAt=0,false,nil
 local rewardCard
 local originalTransparency={}
 for _,p in actor:GetDescendants() do if p:IsA("BasePart") then originalTransparency[p]=p.Transparency end end
 local connection
 local function finish()
  connection:Disconnect() effect:Destroy()
  if heavy then active-=1 end
 end
 connection=RunService.RenderStepped:Connect(function()
  local elapsed=workspace:GetServerTimeNow()-began
  effect:SetAttribute("Elapsed",elapsed)
  if elapsed>=duration+R.RevealGraceSeconds then finish() return end
  local breaking=math.clamp(elapsed/R.BreakSeconds,0,1)
  local alpha=math.clamp((elapsed-R.BreakSeconds)/growth,0,1)
  if breaking<1 then
   effect:SetAttribute("Phase","Break") counter.Text="Breaking..."
   for _,item in pieces do
    local p=breaking
    local offset=item.direction*item.distance*p+Vector3.yAxis*(R.DebrisLift*math.sin(p*math.pi)-R.DebrisFall*p*p)
    item.part.CFrame=(item.home+offset)*CFrame.Angles(item.turn.X*p,item.turn.Y*p,item.turn.Z*p)
    local fade=math.clamp((p-R.DebrisFadeStart)/(1-R.DebrisFadeStart),0,1)
    item.part.Transparency=item.transparency+(1-item.transparency)*fade
   end
  else
   if fragments.Parent then fragments:Destroy() pieces={} end
   effect:SetAttribute("Phase",alpha<1 and "Grow" or "Flash")
   actor:ScaleTo(initialScale*(1+(growthScale-1)*alpha))
   counter.Text=("x%.1f Luck"):format(1+(luck-1)*alpha)
   if alpha<1 and elapsed>=nextTick then tick.PlaybackSpeed=1+alpha*.8 tick:Play() nextTick=elapsed+1/(R.TickStart+(R.TickEnd-R.TickStart)*alpha) end
  end
  Fit.ApplyPose(actor,floor+(ground-floor)*breaking+Config.Npc.CagePreview.FloorClearance)
  local center,size=Fit.Bounds(actor)
  anchor.Position=center+Vector3.yAxis*(size.Y/2+R.CounterHeight)
  if alpha>=1 and not glowing then
   glowing=true
   for _,v in actor:GetDescendants() do
    if v:IsA("SurfaceAppearance") or v:IsA("Decal") or v:IsA("Texture") then v:Destroy()
    elseif v:IsA("SpecialMesh") then v.TextureId=""
    elseif v:IsA("BasePart") and v.Transparency<1 then
     if v:IsA("MeshPart") then v.TextureID="" end
     v.Material=Enum.Material.Neon v.Color=Color3.new(1,1,1)
    end
   end
  end
  if elapsed>=duration then
   gui.Enabled=false
   if not swapAt then for _,card in CS:GetTagged("Card") do if card:GetAttribute("CageRevealId")==revealId then rewardCard=card swapAt=workspace:GetServerTimeNow() break end end end
   if swapAt then
    local fade=math.clamp((workspace:GetServerTimeNow()-swapAt)/R.TransformFadeSeconds,0,1)
    for p,value in originalTransparency do if p.Parent then p.Transparency=value+(1-value)*fade end end
    if fade>=1 then evolutionBurst(rewardCard) finish() end
   end
  end
 end)
end
function Effects.Init()
 Remotes.EggReveal.OnClientEvent:Connect(hatch)
 task.spawn(function()
  while true do
   local root=Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
   local candidates={}
   if root then for _,cage in CS:GetTagged("Cube") do
    if cage:IsA("BasePart") and cage:IsDescendantOf(workspace) then
     if cage:GetAttribute("Dead") then hide(cage) removeIdle(cage)
     else local distance=(root.Position-cage.Position).Magnitude if distance<=R.OccupantDistance then table.insert(candidates,{cage=cage,distance=distance}) end end
    end
   end end
   table.sort(candidates,function(a,b) return a.distance<b.distance end)
   local keep={}
   for i=1,math.min(#candidates,R.MaxIdleOccupants) do keep[candidates[i].cage]=true end
   for cage in idle do if not keep[cage] or not cage.Parent then removeIdle(cage) end end
   for cage in keep do if not idle[cage] then addIdle(cage) end end
   task.wait(R.OccupantCheckSeconds)
  end
 end)

 Remotes.SafeReturn.OnClientEvent:Connect(function(name)
  local gui=Instance.new("ScreenGui") gui.Name="SafeReturn" gui.Parent=Players.LocalPlayer.PlayerGui
  UIKit.Screen(gui)
  local text=Instance.new("TextLabel") text.AnchorPoint=Vector2.new(0.5,0) text.Position=UDim2.new(0.5,0,0,Config.UIScreen.TopPopup)
  text.Size=UDim2.fromScale(0.6,0.07) text.TextScaled=true text.Text="SAFE! "..name text.Parent=gui
  Instance.new("UITextSizeConstraint",text).MaxTextSize=30
  UIKit.Text(text,"gold")
  TweenService:Create(text,TweenInfo.new(R.SafeCelebrationSeconds),{Position=UDim2.new(0.5,0,0,Config.UIScreen.TopPopup-12)}):Play()
  UIKit.Fade(text,R.SafeCelebrationSeconds,1)
  local char=Players.LocalPlayer.Character
  if char then
   local glow=Instance.new("Highlight") glow.FillColor=R.SafeColor glow.FillTransparency=0.6 glow.OutlineTransparency=1 glow.DepthMode=Enum.HighlightDepthMode.Occluded glow.Parent=char
   TweenService:Create(glow,TweenInfo.new(R.SafeCelebrationSeconds),{FillTransparency=1}):Play()
   Debris:AddItem(glow,R.SafeCelebrationSeconds)
  end
  Debris:AddItem(gui,R.SafeCelebrationSeconds)
 end)
end
return Effects
