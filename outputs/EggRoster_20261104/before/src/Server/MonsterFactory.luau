-- Shared adapter for imported monster looks; all gameplay stays in GuardService.
local Config=require(game.ReplicatedStorage.Shared.Config)
local RigAnimation=require(game.ReplicatedStorage.Shared.RigAnimation)
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
function M.Build(name,position)
 local model=Instance.new("Model") model.Name=name
 local root=Instance.new("Part") root.Name="GuardRoot" root.Size=Config.GuardSize
 root.Transparency=1 root.Anchored=true root.CanCollide=false root.CanTouch=false root.CanQuery=false
 root.CFrame=CFrame.new(position) root.Parent=model model.PrimaryPart=root
 local visual=game.ServerStorage.MonsterTemplates[name]:Clone() visual.Name="Visual" visual.PrimaryPart=nil visual.Parent=model
 local center,size=bounds(visual)
 -- Some supplied skinned runners were imported lying on their backs.
 if size.Y<size.Z/2 then visual:PivotTo(CFrame.new(center)*CFrame.Angles(math.pi/2,0,0)*CFrame.new(-center)*visual:GetPivot()) end
 center,size=bounds(visual)
 visual:ScaleTo(visual:GetScale()*Config.MonsterGuards.Heights[name]/size.Y)
 center,size=bounds(visual)
 visual.WorldPivot=CFrame.new(center)
 visual:PivotTo(CFrame.new(position.X,Config.GroundY+size.Y/2,position.Z))
 local effects={} local light
 for _,p in visual:GetDescendants() do
  if p:IsA("BasePart") then p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false
  elseif p:IsA("Humanoid") then p.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None p.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff p.EvaluateStateMachine=false
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
 if Config.MonsterGuards.BodyGlowDesigns[name] then
  local glow=Instance.new("Highlight") glow.Name="BodyGlow" glow.Adornee=visual
  glow.DepthMode=Enum.HighlightDepthMode.Occluded glow.FillColor=Config.MonsterGuards.BodyGlowColor
  glow.FillTransparency=Config.MonsterGuards.BodyGlowTransparency glow.OutlineTransparency=1
  glow.Enabled=false glow.Parent=model table.insert(effects,glow)
 end
 model:SetAttribute("MonsterDesign",name)
 local clip=Config.MonsterGuards.Animations[name] or 'RunR6'
 model:SetAttribute('AnimationClip',clip)
 model:SetAttribute('Moving',false)
 local view={visual=visual,height=size.Y,width=size.X,depth=size.Z,rig=RigAnimation.Bind(visual,name),clip=clip,scale=visual:GetScale()/game.ServerStorage.MonsterTemplates[name]:GetScale(),effects=effects}
 model:SetAttribute('AnimationScale',view.scale)
 M.Pose(view,root,false,0)
 return model,view
end
function M.SetEffects(view,enabled)
 for _,e in view.effects do e.Enabled=enabled end
end
function M.Pose(view,root,moving,now)
 local c=Config.MonsterGuards
 local wave=moving and math.sin(now*c.WalkFrequency) or 0
 view.visual:PivotTo(CFrame.new(root.Position.X,Config.GroundY+view.height/2+math.abs(wave)*c.WalkBob,root.Position.Z)*root.CFrame.Rotation)
 RigAnimation.PoseParts(view.rig,view.clip,now,view.scale,moving)
 if root.Parent:GetAttribute('Moving')~=moving then root.Parent:SetAttribute('Moving',moving) end
end
return M
