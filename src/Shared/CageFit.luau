-- Geometry measurements also work for decorative parts with CanQuery=false.
local Fit={}
function Fit.Bounds(model)
 local low,high
 for _,part in model:GetDescendants() do
  if part:IsA("BasePart") and part.Transparency<1 then
   for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
    local p=part.CFrame*Vector3.new(part.Size.X*x/2,part.Size.Y*y/2,part.Size.Z*z/2)
    low=low and low:Min(p) or p high=high and high:Max(p) or p
   end end end
  end
 end
 assert(low,"No visible geometry")
 return (low+high)/2,high-low,low
end

-- Intersection with an oriented panel, independent of collision/query settings.
local function verticalSpan(part,x,z)
 local origin=part.CFrame:PointToObjectSpace(Vector3.new(x,part.Position.Y,z))
 local direction=part.CFrame:VectorToObjectSpace(Vector3.yAxis)
 local half=part.Size/2 local first,last=-math.huge,math.huge
 for _,axis in {"X","Y","Z"} do
  local o,d,h=origin[axis],direction[axis],half[axis]
  if math.abs(d)<1e-6 then if math.abs(o)>h then return end
  else
   local a,b=(-h-o)/d,(h-o)/d
   first=math.max(first,math.min(a,b)) last=math.min(last,math.max(a,b))
   if first>last then return end
  end
 end
 return part.Position.Y+first,part.Position.Y+last
end

function Fit.FloorAt(surfaces,x,z,fallback)
 local height
 for _,part in surfaces do
  if part.Parent then
   local _,top=verticalSpan(part,x,z)
   if top then height=height and math.max(height,top) or top end
  end
 end
 return height or fallback
end

function Fit.Interior(cage,pedestal,settings,baseY)
 local center,size,low=Fit.Bounds(cage)
 local floors,roofs={},{}
 for _,part in cage:GetDescendants() do
  if part:IsA("BasePart") and part.Transparency<1 then
   local cf,s=part.CFrame,part.Size
   local vertical=math.abs(cf.RightVector.Y)*s.X+math.abs(cf.UpVector.Y)*s.Y+math.abs(cf.LookVector.Y)*s.Z
   if vertical<=size.Y*settings.PanelFraction then
    if part.Position.Y<=low.Y+size.Y*settings.SurfaceBand then table.insert(floors,part) end
    if part.Position.Y>=low.Y+size.Y*(1-settings.SurfaceBand) then table.insert(roofs,part) end
   end
  end
 end
 local fallback=baseY or (pedestal and pedestal.Position.Y+pedestal.Size.Y/2 or low.Y)
 local floor=Fit.FloorAt(floors,center.X,center.Z,fallback)
 local roof=low.Y+size.Y-size.Y*settings.RoofInset
 for _,part in roofs do
  local bottom=verticalSpan(part,center.X,center.Z)
  if bottom and bottom>floor then roof=math.min(roof,bottom) end
 end
 return {center=center,size=size,floor=floor,roof=roof,surfaces=floors}
end

local function sole(cf,size)
 return cf.Position.Y-(math.abs(cf.RightVector.Y)*size.X+math.abs(cf.UpVector.Y)*size.Y+math.abs(cf.LookVector.Y)*size.Z)/2
end

function Fit.FeetLow(model)
 local lowest=math.huge
 for _,name in {"LeftFoot","RightFoot"} do
  local foot=model:FindFirstChild(name)
  if foot then lowest=math.min(lowest,sole(foot.CFrame,foot.Size)) end
 end
 return lowest
end

-- Preview-only anchored rigs: evaluate the animated joint chain without physics/interpolation.
function Fit.ApplyPose(model,floor)
 local poses,links={},{}
 local root=model.PrimaryPart
 if not root then return end
 poses[root]=root.CFrame
 for _,joint in model:GetDescendants() do
  if joint:IsA("Motor6D") and joint.Part0 and joint.Part1 then links[joint.Part1]=joint end
 end
 local function pose(part)
  if poses[part] then return poses[part] end
  local joint=links[part]
  local cf=joint and pose(joint.Part0)*joint.C0*joint.Transform*joint.C1:Inverse() or part.CFrame
  poses[part]=cf return cf
 end
 for part in links do pose(part) end
 local lowest=math.huge
 for _,name in {"LeftFoot","RightFoot"} do
  local foot=model:FindFirstChild(name)
  if foot then lowest=math.min(lowest,sole(pose(foot),foot.Size)) end
 end
 local lift=floor and lowest<math.huge and floor-lowest or 0
 local offset=Vector3.new(0,lift,0)
 for part,cf in poses do part.CFrame=cf+offset end
end
return Fit
