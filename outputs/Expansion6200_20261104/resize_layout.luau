-- Edit-time only. Lengthen the existing layout and retain its asset budgets.
local copy=game.ReplicatedStorage.Shared.Config:Clone() copy.Parent=game.ServerStorage
local Config=require(copy) copy:Destroy()
local g=workspace.Greybox local env=g.Environment local stages=g.Hallway.Stages
assert(not g:GetAttribute('Expanded6200'),'Layout already expanded')
local first,last=stages.Stage_1,stages.Stage_12
local start=first.Position.Z-first.Size.Z/2
local oldEnd=last.Position.Z+last.Size.Z/2
local total=0 for _,length in Config.StageLengths do total+=length end
assert(math.abs(total-6200)<.001)
local finish=start+total local factor=total/(oldEnd-start)
local oldGroundStart=-1024 local oldGroundEnd=3072
local newGroundStart=Config.Landscape.GroundCenter.Z-Config.Landscape.GroundSize.Z/2
local newGroundEnd=Config.Landscape.GroundCenter.Z+Config.Landscape.GroundSize.Z/2
assert(math.abs(newGroundStart-oldGroundStart)<.001)
assert(newGroundEnd-finish>100,'Insufficient boundary clearance')
local function mapZ(z) return start+(z-start)*factor end
local function moveModel(model)
    local cf=model:GetPivot()
    model:PivotTo(CFrame.new(cf.X,cf.Y,mapZ(cf.Z))*cf.Rotation)
end
local function affine(part,origin,scale)
    local transform=Vector3.new(1,1,scale)
    local function abs(v) return Vector3.new(math.abs(v.X),math.abs(v.Y),math.abs(v.Z)) end
    local localScale=Vector3.new(abs(part.CFrame.RightVector):Dot(transform),abs(part.CFrame.UpVector):Dot(transform),abs(part.CFrame.LookVector):Dot(transform))
    local newSize=part.Size*localScale
    assert(math.max(newSize.X,newSize.Y,newSize.Z)<=2048,'Part would exceed Studio size limit')
    part.Size=newSize
    part.CFrame=CFrame.new(part.Position.X,part.Position.Y,origin+(part.Position.Z-origin)*scale)*part.CFrame.Rotation
    for _,mesh in part:GetChildren() do if mesh:IsA('SpecialMesh') and mesh.MeshType==Enum.MeshType.FileMesh then mesh.Scale*=localScale mesh.Offset*=localScale end end
end
local cursor=start
for n=1,12 do
    local floor=stages['Stage_'..n] local oldCenter=floor.Position.Z local oldLength=floor.Size.Z
    local length=Config.GetStageLength(n)
    floor.Size=Vector3.new(floor.Size.X,floor.Size.Y,length)
    floor.Position=Vector3.new(floor.Position.X,floor.Position.Y,cursor+length/2)
    cursor+=length
    local divider=stages:FindFirstChild('Divider_'..n)
    if divider then divider.Position=Vector3.new(divider.Position.X,divider.Position.Y,cursor) end
    for _,marker in g.CubeSpawns['Stage_'..n]:GetChildren() do if marker:IsA('BasePart') then
        marker.Position=Vector3.new(marker.Position.X,marker.Position.Y,floor.Position.Z+(marker.Position.Z-oldCenter)*length/oldLength)
    end end
    for _,item in env.Stages['Stage_'..n]:GetChildren() do
        if item.Name=='Grass' then
            for _,part in item:GetDescendants() do if part:IsA('BasePart') then affine(part,start,factor) end end
        elseif item:IsA('Model') then moveModel(item)
        elseif item:IsA('BasePart') and item.Name:match('^StageSign_') then
            item.Position=Vector3.new(item.Position.X,item.Position.Y,floor.Position.Z-length/2+18)
        elseif item:IsA('BasePart') then
            item.Position=Vector3.new(item.Position.X,item.Position.Y,mapZ(item.Position.Z))
        end
    end
    task.wait()
end
-- Split invisible collision walls; a Roblox Part cannot be 6,200 studs long.
local wallTemplates={Left=g.Hallway.Walls.Wall_Left:Clone(),Right=g.Hallway.Walls.Wall_Right:Clone()}
g.Hallway.Walls:ClearAllChildren()
local sections=math.ceil(total/2048)
for side,template in wallTemplates do
    for i=1,sections do
        local wall=template:Clone()
        wall.Name='Wall_'..side..(i==1 and '' or '_'..i)
        wall.Size=Vector3.new(template.Size.X,template.Size.Y,total/sections+.02)
        wall.CFrame=CFrame.new(template.Position.X,template.Position.Y,start+(i-.5)*total/sections)*template.CFrame.Rotation
        wall.Parent=g.Hallway.Walls
    end
    template:Destroy()
end
local budget=0
for _,root in {env.Walls,env.WallVines} do
    for _,part in root:GetDescendants() do if part:IsA('BasePart') then
        affine(part,start,factor) budget+=1
        if budget>=600 then budget=0 task.wait() end
    end end
end
for _,tree in env.Trees:GetChildren() do
    local cf=tree:GetPivot()
    if cf.Z>=start and cf.Z<=oldEnd then moveModel(tree) end
end
for _,torch in env.Torches:GetChildren() do if torch.Name:match('^Stage_%d+_') then moveModel(torch) end end
for _,wall in workspace:GetChildren() do
    if wall.Name=='MainWall' and math.abs(wall:GetPivot().Z-oldEnd)<20 then
        wall:PivotTo(wall:GetPivot()+Vector3.new(0,0,finish-oldEnd))
    end
end
-- Ground extension only on the far side. Original two support parts stay fixed.
local extra=newGroundEnd-oldGroundEnd local count=math.ceil(extra/2048)
local cursorGround=oldGroundEnd
for i=1,count do
    local length=math.min(2048,newGroundEnd-cursorGround)
    local support=workspace.GroundExtension:Clone()
    support.Name='GroundExtension_'..(i+1)
    support.Size=Vector3.new(Config.Landscape.GroundSize.X,16,length)
    support.Position=Vector3.new(0,-8,cursorGround+length/2)
    support.Parent=workspace cursorGround+=length
end
local groundFactor=Config.Landscape.GroundSize.Z/(oldGroundEnd-oldGroundStart)
for _,part in env.Perimeter.Side_2:GetDescendants() do if part:IsA('BasePart') then part.CFrame+=Vector3.new(0,0,extra) end end
for side=3,4 do
    local group=env.Perimeter['Side_'..side]
    local template=group.BorderCollision:Clone()
    for _,part in group:GetDescendants() do
        if part:IsA('BasePart') and not part.Name:match('^BorderCollision') then affine(part,oldGroundStart,groundFactor) end
    end
    for _,part in group:GetChildren() do if part:IsA('BasePart') and part.Name:match('^BorderCollision') then part:Destroy() end end
    local sections=math.ceil(Config.Landscape.GroundSize.Z/2048)
    for i=1,sections do
        local part=template:Clone()
        part.Name=i==1 and 'BorderCollision' or 'BorderCollision_'..i
        part.Size=Vector3.new(template.Size.X,template.Size.Y,Config.Landscape.GroundSize.Z/sections+.02)
        part.CFrame=CFrame.new(template.Position.X,template.Position.Y,newGroundStart+(i-.5)*Config.Landscape.GroundSize.Z/sections)*template.CFrame.Rotation
        part.Parent=group
    end
    template:Destroy() task.wait()
end
g:SetAttribute('Expanded6200',true)
return game.HttpService:JSONEncode({Start=start,Finish=finish,Length=total,Factor=factor,GroundStart=newGroundStart,GroundEnd=newGroundEnd,GroundLength=Config.Landscape.GroundSize.Z})
