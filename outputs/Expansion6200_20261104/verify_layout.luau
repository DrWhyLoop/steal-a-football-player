local g=workspace.Greybox local stages=g.Hallway.Stages local e=g.Environment
local baseline=game.HttpService:JSONDecode(game.ServerStorage._Expansion6200Rollback_20261104.BaselineJSON.Value)
local r={Stages={},Markers=0,MarkersOutside=0,JoinErrors=0,WidthErrors=0,PlotsUnchanged=true,PreviewUnchanged=true,PlotTorchesUnchanged=true,HallwayRays={Hits=0,Total=0},BorderRays={Hits=0,Total=0},BackingRays={Hits=0,Total=0},GroundSamples={},RearWallHits=0}
local start=stages.Stage_1.Position.Z-stages.Stage_1.Size.Z/2
local lastEnd=start local length=0
for n=1,12 do
    local s=stages['Stage_'..n] local begin=s.Position.Z-s.Size.Z/2
    if math.abs(begin-lastEnd)>.001 then r.JoinErrors+=1 end
    if math.abs(s.Size.X-192)>.001 then r.WidthErrors+=1 end
    lastEnd=s.Position.Z+s.Size.Z/2 length+=s.Size.Z
    table.insert(r.Stages,{Stage=n,Length=s.Size.Z,Width=s.Size.X,Start=begin,Finish=lastEnd})
    for _,m in g.CubeSpawns['Stage_'..n]:GetChildren() do if m:IsA('BasePart') then
        r.Markers+=1 local p=s.CFrame:PointToObjectSpace(m.Position)
        if math.abs(p.X)>s.Size.X/2 or math.abs(p.Z)>s.Size.Z/2 then r.MarkersOutside+=1 end
    end end
end
r.TotalLength=length r.Start=start r.Finish=lastEnd r.FarBoundaryClearance=5672-8-lastEnd
for _,p in g.Plots:GetChildren() do local b=baseline.Plots[p.Name] if not b or tostring(p.Base.CFrame)~=b.Base or tostring(p.Base.Size)~=b.Size then r.PlotsUnchanged=false end end
for _,m in workspace.PlayerPreview_20261104:GetChildren() do if m:IsA('Model') and tostring(m:GetPivot())~=baseline.Preview[m.Name] then r.PreviewUnchanged=false end end
local torches={} for _,m in e.Torches:GetChildren() do if m.Name:match('^Plot_') then table.insert(torches,tostring(m:GetPivot())) end end table.sort(torches)
r.PlotTorchesUnchanged=game.HttpService:JSONEncode(torches)==game.HttpService:JSONEncode(baseline.PlotTorches)
local function countParts(root) local n=0 for _,p in root:GetDescendants() do if p:IsA('BasePart') then n+=1 end end return n end
r.GrassParts={} for n=1,12 do table.insert(r.GrassParts,countParts(e.Stages['Stage_'..n].Grass)) end
r.Vines=#e.WallVines:GetChildren() r.Torches=#e.Torches:GetChildren() r.TreeModels=#e.Trees:GetChildren()
local function ray(group,origin,direction,result)
    local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={group}
    result.Total+=1 if workspace:Raycast(origin,direction,params) then result.Hits+=1 end
end
for n=1,12 do local s=stages['Stage_'..n] for _,f in {-.49,.49} do for _,side in {-1,1} do for _,y in {4,20} do
    ray(g.Hallway.Walls,Vector3.new(s.Position.X,y,s.Position.Z+s.Size.Z*f),Vector3.new(side*140,0,0),r.HallwayRays)
end end end end
local backing={}
for side=1,4 do table.insert(backing,e.Perimeter['Side_'..side].SolidBacking) end
for _,f in {.002,.1,.25,.5,.75,.9,.998} do
    for _,side in {-1,1} do for _,y in {4,20} do
        local origin=Vector3.new(side*990,y,-1024+6696*f) local direction=Vector3.new(side*80,0,0)
        ray(e.Perimeter,origin,direction,r.BorderRays)
        local p=RaycastParams.new() p.FilterType=Enum.RaycastFilterType.Include p.FilterDescendantsInstances=backing
        r.BackingRays.Total+=1 if workspace:Raycast(origin,direction,p) then r.BackingRays.Hits+=1 end
    end end
end
for _,z in {-1024,5672} do for _,x in {-990,-500,0,500,990} do for _,y in {4,20} do
    local side=z<0 and -1 or 1
    ray(e.Perimeter,Vector3.new(x,y,z-side*30),Vector3.new(0,0,side*80),r.BorderRays)
end end end
for _,z in {3071.9,3072,3072.1,4000,5119.9,5120,5120.1,5465,5660} do
    local p=RaycastParams.new() p.FilterType=Enum.RaycastFilterType.Include p.FilterDescendantsInstances={workspace.Terrain}
    local hit=workspace:Raycast(Vector3.new(400,20,z),Vector3.new(0,-50,0),p)
    table.insert(r.GroundSamples,{Z=z,Y=hit and hit.Position.Y or -999,Material=hit and hit.Material.Name or 'None'})
end
for _,m in workspace:GetChildren() do if m.Name=='MainWall' and math.abs(m:GetPivot().Z-lastEnd)<20 then
    for _,x in {-85,-40,0,40,85} do local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={m}
        if workspace:Raycast(Vector3.new(stages.Stage_12.Position.X+x,6,lastEnd-12),Vector3.new(0,0,40),params) then r.RearWallHits+=1 end
    end
end end
return game.HttpService:JSONEncode(r)
