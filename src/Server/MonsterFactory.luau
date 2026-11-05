-- Shared adapter for imported monster looks; all gameplay stays in GuardService.
-- A guard is ONE unanchored, server-owned root part driven by AlignPosition/AlignOrientation. Every visual part is
-- massless, non-colliding and joined to it, so limbs can only move through their own joints (never separate).
-- Rigs with standard R6/R15 joint names are animated by a real Animator (Roblox-made animations); bone-driven or
-- custom-named designs have no usable animation and are posed by the client from their bone clips.
local Config=require(game.ReplicatedStorage.Shared.Config)
local G=Config.GuardAlign
local M={}
local function bounds(model)
 local lo,hi
 for _,p in model:GetDescendants() do if p:IsA("BasePart") and p.Transparency<1 then
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
 local main=visual:FindFirstChild("HumanoidRootPart",true)
 if not main then for _,p in visual:GetDescendants() do if p:IsA("BasePart") and (not main or p.Size.Magnitude>main.Size.Magnitude) then main=p end end end
 weld(main)
 for _,p in visual:GetDescendants() do if p:IsA("BasePart") and not seen[p] then weld(p) end end
end
function M.Build(name,position)
 local model=Instance.new("Model") model.Name=name
 local root=Instance.new("Part") root.Name="GuardRoot" root.Size=Config.GuardSize
 root.Transparency=1 root.CanCollide=false root.CanTouch=false root.CanQuery=false root.CastShadow=false
 root.CFrame=CFrame.new(position) root.Parent=model model.PrimaryPart=root
 local visual=game.ServerStorage.MonsterTemplates[name]:Clone() visual.Name="Visual" visual.PrimaryPart=nil visual.Parent=model
 local center,size=bounds(visual)
 -- Some supplied skinned runners were imported lying on their backs.
 if size.Y<size.Z/2 then visual:PivotTo(CFrame.new(center)*CFrame.Angles(math.pi/2,0,0)*CFrame.new(-center)*visual:GetPivot()) end
 center,size=bounds(visual)
 visual:ScaleTo(visual:GetScale()*Config.MonsterGuards.Heights[name]/size.Y)
 center,size=bounds(visual)
 visual.WorldPivot=CFrame.new(center)
 local y=Config.GroundY+size.Y/2
 visual:PivotTo(CFrame.new(position.X,y,position.Z))
 root.CFrame=CFrame.new(position.X,y,position.Z)
 local effects={} local light
 for _,p in visual:GetDescendants() do
  if p:IsA("BasePart") then p.Anchored=false p.Massless=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false
  elseif p:IsA("Humanoid") or p:IsA("Animator") or p:IsA("AnimationController") or p:IsA("Animation") then p:Destroy() -- imported animations are owned by other creators and fail to load
  elseif p:IsA("ParticleEmitter") then p.Enabled=false p.Rate=math.min(p.Rate,Config.MonsterGuards.ParticleRate) table.insert(effects,p)
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
 weldGroups(visual,root)
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
 local view={model=model,root=root,visual=visual,design=name,height=size.Y,width=size.X,depth=size.Z,y=y,align=align,orient=orient,effects=effects,moving=false,animated=false,speed=0}
 M.Hold(view)
 return model,view
end
-- Hold the guard where it currently is, upright.
function M.Hold(view)
 local position=view.root.Position
 view.align.Position=Vector3.new(position.X,view.y,position.Z)
 view.orient.CFrame=view.root.CFrame.Rotation
end
-- Called once the guard is parented to the workspace: hand physics ownership to the server and load the Animator tracks.
function M.Activate(view)
 view.root:SetNetworkOwner(nil)
 local set=Config.MonsterGuards.AnimationSets[Config.MonsterGuards.AnimationDesigns[view.design]]
 if not set then return end
 local animator=Instance.new("Animator") animator.Parent=Instance.new("AnimationController",view.visual)
 view.tracks={}
 for state,id in set do
  local animation=Instance.new("Animation") animation.AnimationId=id
  local track=animator:LoadAnimation(animation) track.Looped=true view.tracks[state]=track
 end
end
function M.SetEffects(view,enabled)
 for _,e in view.effects do e.Enabled=enabled end
end
local function refreshAnimation(view)
 local tracks=view.tracks if not tracks then return end
 local want=view.animated and (view.moving and "Walk" or "Idle") or nil
 if view.playing~=want then
  if view.playing then tracks[view.playing]:Stop(Config.MonsterGuards.AnimFadeSeconds) end
  if want then tracks[want]:Play(Config.MonsterGuards.AnimFadeSeconds) end
  view.playing=want view.trackSpeed=nil
 end
 if want=="Walk" then -- scale the walk cycle to the ground speed of this (scaled) body
  local c=Config.MonsterGuards
 -- the floor scales with how much faster than its patrol pace the guard is moving, so a chase always looks faster than a patrol
 local speed=math.max(view.speed/(c.AnimWalkRefSpeed*view.height/c.AnimRefHeight),c.AnimSpeedMin*view.speed/view.patrolSpeed)
  if not view.trackSpeed or math.abs(speed-view.trackSpeed)>0.05*view.trackSpeed then tracks.Walk:AdjustSpeed(speed) view.trackSpeed=speed end
 end
end
-- Animations only play while a player is close enough to see them.
function M.SetAnimated(view,enabled)
 view.animated=enabled
 refreshAnimation(view)
end
local function setMoving(view,moving,speed)
 view.speed=speed
 if view.moving~=moving then view.moving=moving view.model:SetAttribute("Moving",moving) end
 refreshAnimation(view)
end
function M.Stop(view)
 M.Hold(view)
 setMoving(view,false,0)
end
-- Move towards a ground point at `speed`; the AlignPosition limits the speed so motion stays smooth between updates.
function M.Drive(view,destination,speed)
 local position=view.root.Position
 local delta=Vector3.new(destination.X-position.X,0,destination.Z-position.Z)
 if delta.Magnitude<G.MinMove or speed<=0 then M.Stop(view) return end
 view.align.MaxVelocity=speed
 view.align.Position=Vector3.new(destination.X,view.y,destination.Z)
 view.orient.CFrame=CFrame.lookAt(Vector3.zero,delta)
 setMoving(view,true,speed)
end
return M
