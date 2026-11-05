local ss=game:GetService('ServerStorage')
local rollback=ss:FindFirstChild('_Expansion6200Rollback_20261104') or Instance.new('Folder') rollback.Name='_Expansion6200Rollback_20261104' rollback.Parent=ss
local CS=game:GetService('CollectionService')
local budget=0
local function attach(node,parent)
    local children
    local count=#node:GetDescendants()
    if count>800 then
        children=node:GetChildren()
        for _,child in children do child.Parent=nil end
    end
    node.Parent=parent
    budget+=children and 1 or count+1
    if budget>700 then budget=0 task.wait() end
    if children then for _,child in children do attach(child,node) end end
end
local function save(obj,name)
    if rollback:FindFirstChild(name or obj.Name) then return end
    local copy=obj:Clone() copy.Name=name or obj.Name
    local function clean(v)
        local tags=CS:GetTags(v)
        if #tags>0 then v:SetAttribute('OriginalTagsJSON',game.HttpService:JSONEncode(tags)) end
        for _,tag in tags do CS:RemoveTag(v,tag) end
        if v:IsA('BaseScript') then v.Disabled=true end
    end
    clean(copy)
    for _,v in copy:GetDescendants() do clean(v) end
    attach(copy,rollback)
end
local g=workspace.Greybox
save(g.Hallway.Stages) save(g.Hallway.Walls,'HallwayWalls') save(g.CubeSpawns) save(g.Environment)
save(game.ReplicatedStorage.Shared.Config)
local i=0
for _,m in workspace:GetChildren() do if m.Name=='MainWall' then i+=1 save(m,'MainWall_'..i) end end
local baseline={Plots={},Preview={},PlotTorches={},Start=g.Hallway.Stages.Stage_1.Position.Z-g.Hallway.Stages.Stage_1.Size.Z/2}
for _,p in g.Plots:GetChildren() do baseline.Plots[p.Name]={Base=tostring(p.Base.CFrame),Size=tostring(p.Base.Size)} end
for _,m in workspace.PlayerPreview_20261104:GetChildren() do if m:IsA('Model') then baseline.Preview[m.Name]=tostring(m:GetPivot()) end end
for _,m in g.Environment.Torches:GetChildren() do if m.Name:match('^Plot_') then table.insert(baseline.PlotTorches,tostring(m:GetPivot())) end end
table.sort(baseline.PlotTorches)
local text=Instance.new('StringValue') text.Name='BaselineJSON' text.Value=game.HttpService:JSONEncode(baseline) text.Parent=rollback
return text.Value
