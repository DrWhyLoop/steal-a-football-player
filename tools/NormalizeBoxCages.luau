-- Edit-time only. Rebuild box-cage templates from the preserved originals; no runtime scripts are inserted.
local SS=game:GetService("ServerStorage")
local templates=SS:WaitForChild("CageTemplates")
local backup=SS:FindFirstChild("CageTemplates_Backup_BoxFit_20261111")
if not backup then
 backup=Instance.new("Folder") backup.Name="CageTemplates_Backup_BoxFit_20261111" backup.Parent=SS
 for id=1,36 do templates["Cage "..id]:Clone().Parent=backup if id%6==0 then task.wait() end end
end
local cylinders={[4]=true,[6]=true,[13]=true,[19]=true,[36]=true}
local targets={
 [2]=Vector3.new(16.9,16.9,16.9),[3]=Vector3.new(6.45,6.45,6.45),
 [8]=Vector3.new(17,17,17),[10]=Vector3.new(12,12,12),[11]=Vector3.new(17,17,17),
 [15]=Vector3.new(12.1,12.1,12.1),[16]=Vector3.new(18.2,18.2,18.2),
 [18]=Vector3.new(9.1,10.5,9.1),[20]=Vector3.new(18.8,18.8,18.8),
 [21]=Vector3.new(10.1,10.1,10.1),[22]=Vector3.new(11.4,11.4,11.4),
 [27]=Vector3.new(5.1,5.9,5.1),[28]=Vector3.new(5.6,5.6,5.6),
 [33]=Vector3.new(24,24,24),[35]=Vector3.new(10.6,10.6,10.6),
}
local function bounds(model)
 local lo,hi
 for _,v in model:GetDescendants() do
  if v:IsA("BasePart") and v.Transparency<1 then
   for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
    local p=v.CFrame*Vector3.new(v.Size.X*x/2,v.Size.Y*y/2,v.Size.Z*z/2)
    lo=lo and lo:Min(p) or p hi=hi and hi:Max(p) or p
   end end end
  end
 end
 return (lo+hi)/2,hi-lo
end
local changed={}
for id=1,36 do
 if not cylinders[id] then
  local old=templates["Cage "..id]
  local model=backup[old.Name]:Clone()
  model.PrimaryPart=nil
  local center,size=bounds(model)
  local target=targets[id]
  if target then
   local factor=target/size
   local thin=math.min(size.X,size.Y,size.Z)*.065
   for _,part in model:GetDescendants() do
    if part:IsA("BasePart") then
     local cf=part.CFrame
     local function length(value,axis)
      -- Keep thin bar/panel thickness and small detail sizes; change their span instead.
      return value<thin and value or value*(axis*factor).Magnitude
     end
     local dimensions=part.Size
     part.Size=Vector3.new(length(dimensions.X,cf.RightVector),length(dimensions.Y,cf.UpVector),length(dimensions.Z,cf.LookVector))
     part.CFrame=CFrame.new(center+(cf.Position-center)*factor)*cf.Rotation
    end
   end
  end
  if id==33 then
   -- Four glass walls need a readable top/bottom perimeter, not another opaque box.
   local c,s=bounds(model)
   local sample=model:FindFirstChildWhichIsA("BasePart",true)
   local thickness=math.min(s.X,s.Z)*.025
   for _,y in {-1,1} do
    for _,x in {-1,1} do
     local p=Instance.new("Part") p.Name="BoxRim" p.Anchored=true
     p.Size=Vector3.new(thickness,thickness,s.Z) p.Position=c+Vector3.new(x*(s.X-thickness)/2,y*(s.Y-thickness)/2,0)
     p.Color=sample.Color:Lerp(Color3.new(),.45) p.Material=Enum.Material.Metal p.Parent=model
    end
    for _,z in {-1,1} do
     local p=Instance.new("Part") p.Name="BoxRim" p.Anchored=true
     p.Size=Vector3.new(s.X,thickness,thickness) p.Position=c+Vector3.new(0,y*(s.Y-thickness)/2,z*(s.Z-thickness)/2)
     p.Color=sample.Color:Lerp(Color3.new(),.45) p.Material=Enum.Material.Metal p.Parent=model
    end
   end
  end
  -- WorldPivot changes the authoring basis without moving geometry. Spawn PivotTo(identity) now keeps it upright.
  model.WorldPivot=CFrame.new((bounds(model)))
  model:SetAttribute("BoxShapeVersion",1)
  model.Parent=templates old:Destroy()
  table.insert(changed,id)
 end
 if id%6==0 then task.wait() end
end
return {updated=changed,reshaped=15,cylindersUnchanged={4,6,13,19,36},backup=backup:GetFullName()}

