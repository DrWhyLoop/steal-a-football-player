-- Shared adapter for imported monster looks; all gameplay stays in GuardService.
-- A guard is ONE unanchored, server-owned root part driven by AlignPosition/AlignOrientation. Every visual part is
-- massless, non-colliding and joined to it, so limbs can only move through their own joints (never separate).
-- Rigs with standard R6/R15 joint names are animated by a real Animator from an animation pack (Config.MonsterGuards.Packs); bone-driven
-- designs have no pack and are posed by the client from their bone clips.
local Config=require(game.ReplicatedStorage.Shared.Config)
local Pose=require(game.ReplicatedStorage.Shared.MonsterPose)
local G=Config.GuardAlign
local settings=Config.MonsterGuards
local M={}
local function bounds(model,includeInvisible)
 local lo,hi
 for _,p in model:GetDescendants() do if p:IsA("BasePart") and (includeInvisible or p.Transparency<1) then
  local cf=p.CFrame local half=p.Size/2
  for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
   local v=cf*Vector3.new(half.X*x,half.Y*y,half.Z*z)
   lo=lo and lo:Min(v) or v hi=hi and hi:Max(v) or v
  end end end
 end end
 assert(lo,"Monster has no visible geometry")
 return (lo+hi)/2,hi-lo
end
-- Joins one part of every jointed group to the root (parts already joined to it through Motor6D/Weld stay on their own joints).
local function weldGroups(visual,root)
 local adjacent={}
 for _,o in visual:GetDescendants() do
  if (o:IsA("JointInstance") or o:IsA("WeldConstraint")) and o.Part0 and o.Part1 then
   adjacent[o.Part0]=adjacent[o.Part0] or {} adjacent[o.Part1]=adjacent[o.Part1] or {}
   table.insert(adjacent[o.Part0],o.Part1) table.insert(adjacent[o.Part1],o.Part0)
  end
 end
 local seen={}
 local function weld(start)
  local queue,index={start},1
  seen[start]=true
  while queue[index] do for _,next in adjacent[queue[index]] or {} do if not seen[next] then seen[next]=true table.insert(queue,next) end end index+=1 end
  local w=Instance.new("WeldConstraint") w.Part0=root w.Part1=start w.Parent=start
 end
 local main=visual:FindFirstChild("HumanoidRootPart",true) or visual:FindFirstChild("Root",true)
 if not main then for _,p in visual:GetDescendants() do if p:IsA("BasePart") and (not main or p.Size.Magnitude>main.Size.Magnitude) then main=p end end end
 weld(main)
 for _,p in visual:GetDescendants() do if p:IsA("BasePart") and not seen[p] then weld(p) end end
end
local function multiply(a,b) return Color3.new(a.R*b.R,a.G*b.G,a.B*b.B) end
-- Animation clips assume the R15 skeleton: part names in the R15 hierarchy, joint frames aligned with the body, the body at rest with its
-- arms down and facing -Z. prepareJoints makes an imported rig match without changing how it looks at rest: a pack's Retarget renames the
-- parts and adds invisible stand-ins for the joints the rig lacks (R15Chain), every joint gets a world-aligned frame, and RestPoses
-- (degrees per R15 part name) rotates a limb that rests in another pose, e.g. T-posed arms, to the clip's rest pose.
local function prepareJoints(visual,spec,rest)
 local motors,byName={},{}
 for _,o in visual:GetDescendants() do
  if o:IsA("BasePart") then byName[o.Name]=o end
  if o:IsA("Motor6D") and o.Part0 and o.Part1 then table.insert(motors,o) end
 end
 if spec then
  for _,m in motors do
   local name=spec.Parts[m.Part1.Name]
   if name then byName[m.Part1.Name]=nil m.Part1.Name=name byName[name]=m.Part1 end
  end
  for _,link in Config.MonsterGuards.R15Chain do
   local parent=byName[link[2]]
   local part=Instance.new("Part") part.Name=link[1] part.Size=Vector3.one*0.1 part.Transparency=1 part.CFrame=parent.CFrame part.Parent=visual
   local motor=Instance.new("Motor6D") motor.Name=link[1] motor.Part0=parent motor.Part1=part motor.Parent=part
   byName[link[1]]=part table.insert(motors,motor)
  end
  for _,m in motors do
   local parent=spec.Parents[m.Part1.Name]
   if parent then m.Part0=byName[parent] end
  end
 end
 for _,m in motors do
  local p0,p1=m.Part0.CFrame,m.Part1.CFrame
  local c0=CFrame.new(p0:Inverse()*(p0*m.C0).Position)*p0.Rotation:Inverse()
  m.C0=c0 m.C1=p1:Inverse()*p0*c0
  local angles=rest and rest[m.Part1.Name]
  if angles then m.C1=m.C1*CFrame.Angles(math.rad(angles.X),math.rad(angles.Y),math.rad(angles.Z)):Inverse() end
 end
end
local function facing(visual,mode)
 if mode=="Sand" then return CFrame.Angles(0,math.pi/2,0) end
 if mode=="Walk" or mode=="WalkIdle" or mode=="Bramble" then
  local left=visual:FindFirstChild("LeftUpperArm",true) or visual:FindFirstChild("Left Arm",true)
  local right=visual:FindFirstChild("RightUpperArm",true) or visual:FindFirstChild("Right Arm",true)
  if left and right then
   local forward=Vector3.yAxis:Cross(right.Position-left.Position)
   if forward.Magnitude>0 then return CFrame.lookAt(Vector3.zero,forward) end
  end
 end
 local main=visual:FindFirstChild("HumanoidRootPart",true)
 return main and main.CFrame.Rotation or CFrame.identity
end

local function bindSand(visual,root)
 local sections={}
 local head=visual.HEAD:GetBoundingBox().Position
 for _,name in {"HEAD","Face","BODY","TAIL"} do
  local section=visual[name]
  local center=(name=="HEAD" or name=="Face") and head or section:GetBoundingBox().Position
  local distance=center.Z-head.Z
  local rest=CFrame.new(root.Position+Vector3.zAxis*distance):ToObjectSpace(section:GetPivot())
  table.insert(sections,{model=section,rest=rest,distance=distance})
 end
 return sections
end

local function moveSand(view)
 local root=view.root
 local position=root.Position
 local trail=view.trail
 local previous=trail[#trail]
 local distance=previous and (position-previous.position).Magnitude or 0
 if not previous then
  local length=view.depth
  trail[1]={position=position-root.CFrame.LookVector*length,distance=-length}
  previous={position=position,distance=0}
  trail[2]=previous
 elseif distance>0.05 then
  previous={position=position,distance=previous.distance+distance}
  table.insert(trail,previous)
  while #trail>2 and trail[2].distance<previous.distance-view.depth do table.remove(trail,1) end
 end
 local weight=math.clamp(root.AssemblyLinearVelocity.Magnitude/math.max(view.speed,1),0,1)
 for _,section in view.sections do
  local offset=previous.distance-section.distance
  local frame=root.CFrame
  if section.distance>0 then
   for i=#trail-1,1,-1 do
    local a,b=trail[i],trail[i+1]
    if offset>=a.distance or i==1 then
     local point=a.position:Lerp(b.position,math.clamp((offset-a.distance)/(b.distance-a.distance),0,1))
     local direction=(b.position-a.position)*Vector3.new(1,0,1)
     if direction.Magnitude>0 then frame=CFrame.lookAt(point,point+direction) end
     break
    end
   end
  end
  local lift=(1+math.sin(offset*settings.SandRippleFrequency))*settings.SandRippleHeight*weight
  section.model:PivotTo((frame+Vector3.yAxis*lift)*section.rest)
 end
end

function M.Build(entry,position)
 local name=entry.Design
 local eye=name=="Stage06Eye"
 local model=Instance.new("Model") model.Name=name
 local root=Instance.new("Part") root.Name="GuardRoot" root.Size=Config.GuardSize
 root.Transparency=1 root.CanCollide=false root.CanTouch=false root.CanQuery=false root.CastShadow=false
 root.CFrame=CFrame.new(position) root.Parent=model model.PrimaryPart=root
 local visual=game.ServerStorage.MonsterTemplates[name]:Clone() visual.Name="Visual" visual.PrimaryPart=nil visual.Parent=model
 -- Turn the rig so its HumanoidRootPart faces the way the guard walks (-Z).
 local pivot=visual:GetPivot()
 visual:PivotTo(CFrame.new(pivot.Position)*facing(visual,entry.Pose):Inverse()*pivot.Rotation)
 local center,size=bounds(visual,eye)
 -- Some supplied skinned runners were imported lying on their backs.
 if not entry.Pose and size.Y<size.Z/2 then visual:PivotTo(CFrame.new(center)*CFrame.Angles(math.pi/2,0,0)*CFrame.new(-center)*visual:GetPivot()) end
 center,size=bounds(visual,eye)
 visual:ScaleTo(visual:GetScale()*entry.Height/size.Y)
 center,size=bounds(visual,eye)
 visual.WorldPivot=CFrame.new(center)
 local y=Config.GroundY+size.Y/2
 visual:PivotTo(CFrame.new(position.X,y,position.Z))
 local pack=Config.MonsterGuards.Packs[entry.Pack]
 local rest=Config.MonsterGuards.RestPoses[name]
 if entry.Pose and entry.Pose~="Sand" and entry.Pose~="Still" then
  prepareJoints(visual,nil,nil)
 elseif pack and (pack.Retarget or rest) then prepareJoints(visual,pack.Retarget and Config.MonsterGuards.Retargets[pack.Retarget],rest) end
 center,size=bounds(visual,eye) -- a rest pose can move the feet: put the lowest point exactly on the floor
 visual:PivotTo(visual:GetPivot()+Vector3.new(0,Config.GroundY-(center.Y-size.Y/2),0))
 if eye then visual:PivotTo(visual:GetPivot()+Vector3.yAxis*settings.Eye.Hover) end
 y=Config.GroundY+size.Y/2+(eye and settings.Eye.Hover or 0)
 root.CFrame=CFrame.new(position.X,y,position.Z)
 local effects={} local light,eyeVisual
 for _,p in visual:GetDescendants() do
  if p:IsA("BasePart") then
   p.Anchored=entry.Pose=="Sand" p.Massless=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false
   if entry.Tint and p.Transparency<1 then p.Color=multiply(p.Color,entry.Tint) end
  elseif p:IsA("SurfaceAppearance") and entry.Tint then p.Color=multiply(p.Color,entry.Tint)
  elseif p:IsA("LuaSourceContainer") or p:IsA("Humanoid") or p:IsA("Animator") or p:IsA("AnimationController") or p:IsA("Animation") then p:Destroy() -- imported animations are owned by other creators and fail to load
  elseif p:IsA("ParticleEmitter") then
   p.Enabled=false
   if eye then
    eyeVisual=p
   else
    p.Rate=math.min(p.Rate,Config.MonsterGuards.ParticleRate)
    table.insert(effects,p)
   end
  elseif p:IsA("Trail") or p:IsA("Beam") then p.Enabled=false table.insert(effects,p)
  elseif p:IsA("Light") then
   if Config.MonsterGuards.BodyGlowDesigns[name] or light then p:Destroy()
   else
    light=p p.Enabled=false p.Shadows=false
    p.Brightness=math.min(p.Brightness,Config.MonsterGuards.LightBrightness)
    p.Range=math.min(p.Range,Config.MonsterGuards.LightRange)
    table.insert(effects,p)
   end
  end
 end
 if entry.Pose~="Sand" then weldGroups(visual,root) end
 if Config.MonsterGuards.BodyGlowDesigns[name] then
  local glow=Instance.new("Highlight") glow.Name="BodyGlow" glow.Adornee=visual
  glow.DepthMode=Enum.HighlightDepthMode.Occluded glow.FillColor=Config.MonsterGuards.BodyGlowColor
  glow.FillTransparency=Config.MonsterGuards.BodyGlowTransparency glow.OutlineTransparency=1
  glow.Enabled=false glow.Parent=model table.insert(effects,glow)
 end
 local attachment=Instance.new("Attachment") attachment.Parent=root
 local align=Instance.new("AlignPosition") align.Mode=Enum.PositionAlignmentMode.OneAttachment align.Attachment0=attachment
 align.MaxForce=G.MaxForce align.Responsiveness=G.Responsiveness align.MaxVelocity=G.HoldVelocity align.ApplyAtCenterOfMass=true align.Parent=root
 local orient=Instance.new("AlignOrientation") orient.Mode=Enum.OrientationAlignmentMode.OneAttachment orient.Attachment0=attachment
 orient.MaxTorque=G.MaxTorque orient.Responsiveness=G.Responsiveness orient.MaxAngularVelocity=G.TurnSpeed orient.Parent=root
 model:SetAttribute("MonsterDesign",name)
 model:SetAttribute("AnimationClip",Config.MonsterGuards.Animations[name] or "RunR6") -- bone clip for the client
 model:SetAttribute("AnimationScale",visual:GetScale()/game.ServerStorage.MonsterTemplates[name]:GetScale())
 model:SetAttribute("Moving",false)
 local ground={} -- the parts that touch the floor: feet and legs, or every visible part when the rig has none
 for _,p in visual:GetDescendants() do
  if p:IsA("BasePart") and p.Transparency<1 and (p.Name:lower():find("foot") or p.Name:lower():find("leg")) then table.insert(ground,p) end
 end
 if #ground==0 then for _,p in visual:GetDescendants() do if p:IsA("BasePart") and (eye or p.Transparency<1) then table.insert(ground,p) end end end
 local view={model=model,root=root,visual=visual,ground=ground,design=name,height=size.Y,width=size.X,depth=size.Z,y=y,align=align,orient=orient,effects=effects,pack=pack,moving=false,running=false,animated=false,speed=0,attackUntil=0}
 view.pose=entry.Pose
 view.eyeVisual=eyeVisual
 if view.pose=="Sand" then
  view.sections=bindSand(visual,root)
  view.trail={}
 elseif view.pose and view.pose~="Still" then
  view.motors={}
  for _,joint in visual:GetDescendants() do
   if joint:IsA("Motor6D") and joint.Part0 and joint.Part1 then
    table.insert(view.motors,{joint=joint,rest=joint.C0,name=joint.Part1.Name:lower()})
   end
  end
  view.phase=0
 end
 M.Hold(view)
 return model,view
end
-- Hold the guard where it currently is, upright.
-- Animation clips move the pose (the translation of a scaled rig is not scaled), so the root height is corrected continuously: the lowest foot
-- is brought back to the floor in small steps, whatever the guard's size (7-20 studs) or clip.
local function lowest(view)
 local bottom=math.huge
 for _,p in view.ground do
  local cf,s=p.CFrame,p.Size
  bottom=math.min(bottom,cf.Y-(math.abs(cf.RightVector.Y)*s.X+math.abs(cf.UpVector.Y)*s.Y+math.abs(cf.LookVector.Y)*s.Z)/2)
 end
 return bottom
end
local function settle(view)
 if view.sections then return end
 local floor=Config.GroundY+(view.eyeVisual and settings.Eye.Hover or 0)
 view.y-=math.clamp(lowest(view)-floor,-G.MaxSettle,G.MaxSettle)*G.SettleGain
end
function M.Hold(view)
 settle(view)
 local position=view.root.Position
 view.align.Position=Vector3.new(position.X,view.y,position.Z)
 view.orient.CFrame=view.root.CFrame.Rotation
end
-- Called once the guard is parented to the workspace: hand physics ownership to the server and load the Animator tracks.
local TRACKS={Idle={Enum.AnimationPriority.Idle,true},IdleLook={Enum.AnimationPriority.Idle,false},Walk={Enum.AnimationPriority.Movement,true},Run={Enum.AnimationPriority.Movement,true},Attack={Enum.AnimationPriority.Action,false}}
local refreshAnimation
function M.Activate(view)
 view.root:SetNetworkOwner(nil)
 if not view.pack then return end
 local animator=Instance.new("Animator") animator.Parent=Instance.new("AnimationController",view.visual)
 local tracks={} view.tracks=tracks
 for state,setting in TRACKS do
  local id=view.pack[state]
  if id then
   local animation=Instance.new("Animation") animation.AnimationId=id
   local track=animator:LoadAnimation(animation) track.Priority=setting[1] track.Looped=setting[2] tracks[state]=track
  end
 end
 if tracks.IdleLook then
  tracks.Idle.DidLoop:Connect(function() -- an occasional look-around between idle loops
   if view.playing=="Idle" and math.random()<Config.MonsterGuards.IdleLookChance then
    tracks.Idle:Stop(Config.MonsterGuards.AnimFadeSeconds) tracks.IdleLook:Play(Config.MonsterGuards.AnimFadeSeconds) view.playing="IdleLook"
   end
  end)
  tracks.IdleLook.Stopped:Connect(function() if view.playing=="IdleLook" then view.playing=nil refreshAnimation(view) end end)
 end
end
function M.SetEffects(view,enabled)
 for _,e in view.effects do e.Enabled=enabled end
end
-- Patrol = Walk, chase = Run, a hit = Attack (the guard is stunned meanwhile), otherwise Idle. Walk and Run play at the speed that makes
-- the feet match the ground speed for this guard's height.
function refreshAnimation(view)
 local tracks,c=view.tracks,Config.MonsterGuards
 if not tracks then return end
 local want
 if view.animated then
  if view.attackUntil>os.clock() and tracks.Attack then want="Attack"
  elseif view.moving then
   want=view.running and tracks.Run and "Run" or "Walk"
   if want=="Walk" and tracks.Run and view.speed>c.AnimSpeedMax*view.pack.Stride.Walk*view.height then want="Run" end -- a Walk that cannot keep up
  else want="Idle" end
 end
 if view.playing=="IdleLook" and want=="Idle" then want="IdleLook" end -- let the look-around finish
 if view.playing~=want then
  if view.playing then tracks[view.playing]:Stop(c.AnimFadeSeconds) end
  if want=="Attack" then tracks.Attack:Play(c.AnimFadeSeconds,1,tracks.Attack.Length/c.AttackSeconds)
  elseif want then tracks[want]:Play(c.AnimFadeSeconds) end
  view.playing=want view.trackSpeed=nil
 end
 if want=="Walk" or want=="Run" then
  local speed=math.min(c.AnimSpeedMax,view.speed/(view.pack.Stride[want]*view.height))
  if not view.trackSpeed or math.abs(speed-view.trackSpeed)>0.05*view.trackSpeed then tracks[want]:AdjustSpeed(speed) view.trackSpeed=speed end
 end
end
-- Animations only play while a player is close enough to see them.
function M.SetAnimated(view,enabled)
 view.animated=enabled
 if view.eyeVisual then view.eyeVisual.Enabled=enabled end
 refreshAnimation(view)
end
local function setMoving(view,moving,speed,running)
 view.speed=speed view.running=running
 if view.moving~=moving then view.moving=moving view.model:SetAttribute("Moving",moving) end
 refreshAnimation(view)
end
function M.Stop(view)
 M.Hold(view)
 setMoving(view,false,0,false)
end
-- Move towards a ground point at `speed`; the AlignPosition limits the speed so motion stays smooth between updates.
function M.Drive(view,destination,speed,running)
 settle(view)
 local position=view.root.Position
 local delta=Vector3.new(destination.X-position.X,0,destination.Z-position.Z)
 if delta.Magnitude<G.MinMove or speed<=0 then M.Stop(view) return end
 view.align.MaxVelocity=speed
 view.align.Position=Vector3.new(destination.X,view.y,destination.Z)
 view.orient.CFrame=CFrame.lookAt(Vector3.zero,delta)
 if view.sections then
  view.orient.MaxAngularVelocity=speed/settings.SandTurnRadius
  local forward=view.root.CFrame.LookVector
  local advance=math.clamp(forward:Dot(delta.Unit),0,1)*math.min(delta.Magnitude,settings.SandTurnRadius)
  view.align.Position=Vector3.new(position.X,view.y,position.Z)+forward*advance
 end
 setMoving(view,true,speed,running)
end
-- A hit: play the attack animation (the caller stuns the guard for as long).
function M.Attack(view)
 view.attackUntil=os.clock()+Config.MonsterGuards.AttackSeconds
 refreshAnimation(view)
end
function M.UpdatePose(view,dt)
 if view.sections then
  moveSand(view)
 elseif view.motors and (view.animated or view.wasAnimated) then
  local speed=(view.root.AssemblyLinearVelocity*Vector3.new(1,0,1)).Magnitude
  local stride=Config.MonsterGuards.StridePerHeight*view.height
  view.phase=(view.phase+speed*dt/stride*2*math.pi)%(2*math.pi)
  local weight=view.animated and view.moving and math.clamp(speed/stride,0,1) or 0
  for _,entry in view.motors do
   entry.joint.C0=entry.rest*Pose.Joint(entry.name,view.phase,view.pose,weight)
  end
  view.wasAnimated=view.animated
 end
end
return M
