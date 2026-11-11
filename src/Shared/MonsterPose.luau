local Pose={}

function Pose.Joint(name, phase, mode, stride)
 local worm,walkIdle=mode=="Earth",mode=="WalkIdle"
 local bramble=mode=="Bramble"
 local side=name:find("left",1,true) and 1 or name:find("right",1,true) and -1 or 0
 if worm then
  local segment=tonumber(name:match("%d+$")) or 0
  if side~=0 and name:find("leg",1,true) then
   return CFrame.Angles(0,math.sin(phase+segment*.62)*.22*side,math.sin(phase+segment*.62)*.15)
  end
  if name:find("tail",1,true) or name:find("body",1,true) or name=="head" then
   return CFrame.Angles(math.sin(phase-segment)*.09,math.cos(phase-segment)*.19,0)
  end
 elseif side~=0 then
  local swing=math.sin(phase)*side*stride
  if name:find("upperleg",1,true) or name=="left leg" or name=="right leg" then return CFrame.Angles(swing*(bramble and .18 or .42),0,0) end
  if name:find("lowerleg",1,true) or (walkIdle and (name=="left foot" or name=="right foot")) then return CFrame.Angles(math.max(0,swing)*(bramble and .12 or .31),0,0) end
  if name:find("upperarm",1,true) or name=="left arm" or name=="right arm" then return CFrame.Angles(-swing*(bramble and .13 or .32),0,0)*CFrame.Angles(0,0,walkIdle and side*.40 or 0) end
 end
 return CFrame.identity
end

return Pose
