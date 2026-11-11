-- One sampler/retargeter for saved R6/R15 poses, custom bones and rigid claws.
local Clips=require(script.Parent.AnimationClips)
local Config=require(script.Parent.Config)
local HurtPose=require(script.Parent.HurtPose)
local Rig={}
local aliases={LeftUpperArm='Left Arm',RightUpperArm='Right Arm',LeftUpperLeg='Left Leg',RightUpperLeg='Right Leg',UpperTorso='Torso',LeftArm='Left Arm',RightArm='Right Arm',LeftUpLeg='Left Leg',RightUpLeg='Right Leg',Spine1='Torso'}
local knees={LeftLowerLeg=1,RightLowerLeg=-1,LeftLeg=1,RightLeg=-1,['shin.L']=1,['shin.R']=-1}
local elbows={LeftLowerArm=true,RightLowerArm=true,LeftForeArm=true,RightForeArm=true,['forearm.L']=true,['forearm.R']=true}
function Rig.Sample(clip,name,time)
    local track=clip.Tracks[name]
    if not track or #track==0 then return CFrame.identity end
    if time<=track[1][1] then return track[1][2] end
    for i=2,#track do
        local after=track[i]
        if time<=after[1] then local before=track[i-1] local span=after[1]-before[1] return span>0 and before[2]:Lerp(after[2],(time-before[1])/span) or after[2] end
    end
    return track[#track][2]
end
function Rig.Bind(model,design)
    local binding={model=model,joints={},bones={},aliases=Config.MonsterGuards.BoneAliases[design] or {}}
    for _,o in model:GetDescendants() do
        if (o:IsA('JointInstance') or o:IsA('AnimationConstraint')) and o.Part0 and o.Part1 then
            table.insert(binding.joints,{joint=o,part0=o.Part0,part1=o.Part1,c0=o.C0,c1=o.C1,animated=o:IsA('Motor6D') or o:IsA('AnimationConstraint'),name=o.Part1.Name,basis=o.C0.Rotation})
        elseif o:IsA('WeldConstraint') and o.Part0 and o.Part1 then
            table.insert(binding.joints,{part0=o.Part0,part1=o.Part1,c0=o.Part0.CFrame:ToObjectSpace(o.Part1.CFrame),c1=CFrame.identity,animated=false})
        elseif o:IsA('Bone') then
            local p=o.Parent while p and not p:IsA('BasePart') do p=p.Parent end
            if p then table.insert(binding.bones,{bone=o,name=o.Name,basis=p.CFrame:ToObjectSpace(o.WorldCFrame).Rotation}) end
        end
    end
    local children={} for _,j in binding.joints do children[j.part1]=true end
    local pending=table.clone(binding.joints) local ordered={} local done={}
    for _,j in pending do if not children[j.part0] then done[j.part0]=true end end
    for _=1,#pending do
        local progress=false
        for i=#pending,1,-1 do local j=pending[i] if done[j.part0] then table.insert(ordered,j) done[j.part1]=true table.remove(pending,i) progress=true end end
        if not progress then break end
    end
    binding.joints=ordered
    return binding
end
local function frame(binding,item,clip,time,scale)
    local name=item.name
    if clip.Tracks[name] then local f=Rig.Sample(clip,name,time) return CFrame.new(f.Position*scale)*f.Rotation end
    if clip==Clips.RunR6 and (knees[name] or elbows[name]) then
        local angle
        if knees[name] then angle=-math.max(0,math.sin(time/clip.Duration*math.pi*2)*knees[name])*Config.Axes.RunKneeBend
        else angle=Config.Axes.RunElbowBend end
        return item.basis:Inverse()*CFrame.Angles(angle,0,0)*item.basis
    end
    local source=binding.aliases[name] or aliases[name]
    if not source then return CFrame.identity end
    local pose=Rig.Sample(clip,source,time).Rotation
    local base=clip.Bases[source] or CFrame.identity
    local axis=item.basis:Inverse()*base.Rotation
    return axis*pose*axis:Inverse()
end
local upperArms={LeftArm=true,RightArm=true,LeftUpperArm=true,RightUpperArm=true}
local function carryArm(item)
 if not upperArms[item.name] then return CFrame.identity end
 local child=item.bone:FindFirstChildWhichIsA("Bone")
 if not child or child.Position.Magnitude<1e-4 then return CFrame.identity end
 local direction=item.basis:VectorToWorldSpace(child.Position.Unit)
 local down=-Vector3.yAxis
 local axis=direction:Cross(down)
 if axis.Magnitude<1e-4 then return CFrame.identity end
 local rotation=CFrame.fromAxisAngle(axis.Unit,math.acos(math.clamp(direction:Dot(down),-1,1)))
 return item.basis:Inverse()*rotation*item.basis
end

function Rig.PoseBones(binding,clipName,time,moving,scale,carrying)
    local clip=Clips[clipName] or Clips.RunR6
    local t=time%clip.Duration
    for _,item in binding.bones do
        if carrying and not item.carry then item.carry=carryArm(item) end
        item.bone.Transform=carrying and item.carry or moving and frame(binding,item,clip,t,scale or 1) or CFrame.identity
    end
end
function Rig.PoseAvatar(binding,runTime,running,swingTime)
    local run=Clips.RunR6 local strike=Clips.AxeStrikeR6 local a=Config.Axes
    for _,j in binding.joints do if j.animated then
        local f=running and frame(binding,j,run,runTime%run.Duration,1) or nil
        if swingTime and swingTime>=0 and swingTime<a.SwingDuration then
            local name=j.name local upper=name:find('Arm') or name:find('Torso') or name=='Head'
            if upper then
                local t=math.min(swingTime/a.StrikeEnd,1)*strike.Duration
                f=frame(binding,j,strike,t,1)
                if elbows[name] then f=CFrame.Angles(Config.Axes.StrikeElbowBend*math.sin(math.pi*t/strike.Duration),0,0) end
                if swingTime>a.StrikeEnd then f=f:Lerp(CFrame.identity,(swingTime-a.StrikeEnd)/(a.SwingDuration-a.StrikeEnd)) end
            end
        end
        if f then j.joint.Transform=f elseif j.owned then j.joint.Transform=CFrame.identity end
        j.owned=f~=nil
    end end
end
local r6Hurt={
 ["Left Arm"]=CFrame.Angles(.5,0,-.2),["Right Arm"]=CFrame.Angles(.8,0,.2),
 ["Left Leg"]=CFrame.Angles(-.65,0,0),["Right Leg"]=CFrame.Angles(-.3,0,0),
 Torso=CFrame.new(0,-.45,0)*CFrame.Angles(.25,0,0),Head=CFrame.Angles(.4,0,0),
}
function Rig.PoseHurt(binding,elapsed)
 local cfg=Config.Hurt
 local weight=elapsed and elapsed>=0 and elapsed<cfg.Duration and math.min(1,elapsed/cfg.BlendSeconds,(cfg.Duration-elapsed)/cfg.BlendSeconds) or 0
 for _,j in binding.joints do if j.animated then
  local pose=HurtPose[j.name] or r6Hurt[j.name]
  if pose and weight>0 then
   if not HurtPose[j.name] then pose=j.basis:Inverse()*pose*j.basis end
   j.joint.Transform=j.joint.Transform:Lerp(pose,weight) j.hurtOwned=true
  elseif j.hurtOwned then j.joint.Transform=CFrame.identity j.hurtOwned=false end
 end end
end
return Rig
