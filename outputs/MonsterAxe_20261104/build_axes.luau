local ss=game.ServerStorage
local original=Instance.new('Folder') original.Name='AxeSourceAssets_20261104' original.Parent=ss
local templates=Instance.new('Folder') templates.Name='AxeTemplates' templates.Parent=ss
local names={Default='Default axe',Good='Good axe',Golden='Golden pickaxe',Pickaxe='PickaxeModel',Godly='Godly Pickaxe',Volcanic='Volcanic Axe'}
local function parts(root)
    local r={} if root:IsA('BasePart') then table.insert(r,root) end
    for _,p in root:GetDescendants() do if p:IsA('BasePart') then table.insert(r,p) end end
    return r
end
local results={}
for tier,name in names do
    local source=workspace:FindFirstChild(name) assert(source,name)
    local copy=source:Clone()
    local geometry=Instance.new('Model') geometry.Name=tier copy.Parent=geometry
    for _,o in copy:GetDescendants() do
        if o:IsA('LuaSourceContainer') or o:IsA('JointInstance') or o:IsA('Constraint') or o:IsA('LayerCollector') or o:IsA('ProximityPrompt') then o:Destroy() end
    end
    local reference
    if tier=='Default' then reference=copy.meshpart.CFrame*CFrame.new(.8,0,0)*CFrame.Angles(0,0,math.pi/2)
    elseif tier=='Good' then reference=copy['Meshes/Axe_Cylinder'].CFrame*CFrame.new(0,-.5,0)
    elseif tier=='Pickaxe' then reference=copy.Primary.CFrame*CFrame.new(0,-.8,0)
    elseif tier=='Golden' then reference=copy.Handle.CFrame*CFrame.Angles(0,0,math.pi/2)
    elseif tier=='Godly' then reference=copy.CFrame
    else
        -- Union rigid voxel details by material; retain their original face colors.
        geometry.Parent=workspace
        local groups={}
        for _,p in parts(geometry) do p.Anchored=true local k=p.Material.Name groups[k]=groups[k] or {} table.insert(groups[k],p) end
        for _,group in groups do if #group>1 then
            local base=table.remove(group,1)
            local union=base:UnionAsync(group,Enum.CollisionFidelity.Box,Enum.RenderFidelity.Automatic)
            union.Name='VolcanicDetail' union.UsePartColor=false union.Parent=geometry
            base:Destroy() for _,p in group do p:Destroy() end
        end end
        local cf=geometry:GetBoundingBox() reference=cf
        geometry.Parent=nil
    end
    for _,p in parts(geometry) do p.CFrame=reference:ToObjectSpace(p.CFrame) end
    local _,size=geometry:GetBoundingBox()
    local scale=3.8/math.max(size.X,size.Y,size.Z)
    geometry:ScaleTo(geometry:GetScale()*scale)
    local tool=Instance.new('Tool') tool.Name=tier tool.RequiresHandle=true tool.CanBeDropped=false
    tool:SetAttribute('AxeTier',tier) tool:SetAttribute('Unlocked',tier=='Default')
    local handle=Instance.new('Part') handle.Name='Handle' handle.Size=Vector3.new(.2,.5,.2) handle.Transparency=1 handle.CanCollide=false handle.CanTouch=false handle.CanQuery=false handle.Massless=true handle.Parent=tool
    geometry.Parent=tool
    for _,p in parts(geometry) do
        p.Anchored=false p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true p.CastShadow=false
        local weld=Instance.new('WeldConstraint') weld.Part0=handle weld.Part1=p weld.Parent=p
    end
    tool.ToolTip=tier=='Default' and 'Break eggs with an overhead strike' or 'Locked progression axe'
    tool.Parent=templates
    source.Parent=original
    table.insert(results,{Tier=tier,Parts=#parts(tool)})
    task.wait()
end
local old=game.StarterPack:FindFirstChild('Pickaxe') if old then old.Parent=original end
local starter=templates.Default:Clone() starter.Name='Default Axe' starter.Parent=game.StarterPack
return game.HttpService:JSONEncode(results)
