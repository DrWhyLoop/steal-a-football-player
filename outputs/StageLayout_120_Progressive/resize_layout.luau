local c=game.ReplicatedStorage.Shared.Config:Clone() c.Parent=game.ServerStorage local Config=require(c) c:Destroy()
local g=workspace.Greybox local stages=g.Hallway.Stages
local original={} local start=stages.Stage_1.Position.Z-stages.Stage_1.Size.Z/2
local center=stages.Stage_1.Position.X local total=0
for n=1,Config.StageCount do local s=stages["Stage_"..n] original[n]={Position=s.Position,Size=s.Size} total+=Config.GetStageLength(n) end
local oldEnd=original[12].Position.Z+original[12].Size.Z/2 local finish=start+total
local perimeter=g.Environment.Perimeter
local innerEnd=perimeter.Side_2.BorderCollision.Position.Z-perimeter.Side_2.BorderCollision.Size.X/2
assert(finish+Config.Environment.WallDepth<innerEnd,"New layout crosses outer boundary")
local oldWidth=original[1].Size.X
local cursor=start
for n=1,Config.StageCount do
 local s=stages["Stage_"..n] local length=Config.GetStageLength(n)
 s.Size=Vector3.new(Config.HallwayWidth,s.Size.Y,length) s.Position=Vector3.new(center,s.Position.Y,cursor+length/2)
 cursor+=length
 local divider=stages:FindFirstChild("Divider_"..n) if divider then divider.Size=Vector3.new(Config.HallwayWidth,divider.Size.Y,divider.Size.Z) divider.Position=Vector3.new(center,divider.Position.Y,cursor) end
 local folder=g.CubeSpawns["Stage_"..n]
 local markers=folder:GetChildren() table.sort(markers,function(a,b) return tonumber(a.Name:match("%d+$"))<tonumber(b.Name:match("%d+$")) end)
 local rows=math.ceil(#markers/#Config.CubeColumnX)
 for i,m in markers do
  local x=Config.CubeColumnX[(i-1)%#Config.CubeColumnX+1]
  local row=math.floor((i-1)/#Config.CubeColumnX)+1
  local z=-length/2+(row-0.5)*length/rows
  if n==Config.GoatStage and #markers==1 then x=0 z=length/4 end
  m.Position=Vector3.new(center+x,m.Position.Y,s.Position.Z+z) m.Transparency=Config.CubeSpawnMarkerTransparency m.CanCollide=false
 end
end
for _,side in {-1,1} do
 local wall=g.Hallway.Walls[side==1 and "Wall_Right" or "Wall_Left"]
 wall.Size=Vector3.new(wall.Size.X,wall.Size.Y,total)
 wall.Position=Vector3.new(center+side*(Config.HallwayWidth/2+wall.Size.X/2),wall.Position.Y,(start+finish)/2)
end
local function abs(v) return Vector3.new(math.abs(v.X),math.abs(v.Y),math.abs(v.Z)) end
for _,m in workspace:GetChildren() do
 if m.Name=="MainWall" then
  local p=m:GetPivot().Position
  if math.abs(p.Z-oldEnd)<20 then
   local scale=Vector3.new(Config.HallwayWidth/oldWidth,1,1)
   for _,v in m:GetDescendants() do if v:IsA("BasePart") then
    local ls=Vector3.new(abs(v.CFrame.RightVector):Dot(scale),abs(v.CFrame.UpVector):Dot(scale),abs(v.CFrame.LookVector):Dot(scale))
    v.Size*=ls v.CFrame=CFrame.new(p+(v.Position-p)*scale)*v.CFrame.Rotation
   end end
   m:PivotTo(m:GetPivot()+Vector3.new(0,0,finish-oldEnd))
  elseif math.abs(p.Z-start)<10 then
   local side=p.X>center and 1 or -1
   m:PivotTo(m:GetPivot()+Vector3.new(side*(Config.HallwayWidth-oldWidth)/2,0,0))
  end
 end
end
-- Reposition stage fixtures without rebuilding the user's plot fixtures.
for _,m in g.Environment.Torches:GetChildren() do
 local n=tonumber(m.Name:match("^Stage_(%d+)_"))
 if n then local old=original[n] local new=stages["Stage_"..n] local cf=m:GetPivot() local offset=cf.Position-old.Position
  m:PivotTo(CFrame.new(new.Position+Vector3.new(offset.X*new.Size.X/old.Size.X,offset.Y,offset.Z*new.Size.Z/old.Size.Z))*cf.Rotation)
 end
end
local apron=g.Hallway:FindFirstChild("EntranceApron") or Instance.new("Part")
apron.Name="EntranceApron" apron.Size=Vector3.new(Config.HallwayWidth,stages.Stage_1.Size.Y,Config.EntranceApronDepth)
apron.Position=Vector3.new(center,stages.Stage_1.Position.Y,start-Config.EntranceApronDepth/2)
apron.Anchored=true apron.Material=Enum.Material.Grass apron.Color=Config.Environment.GrassColor apron.Parent=g.Hallway
return {Start=start,Finish=finish,Total=total,OuterWallClearance=innerEnd-finish}
