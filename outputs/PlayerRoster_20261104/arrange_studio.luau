-- Edit-time repair/placement helper. Never install as a runtime game script.
local workspace = game:GetService('Workspace')
local storage = game:GetService('ServerStorage')
local assets = game:GetService('AssetService')
local preview = workspace:FindFirstChild('PlayerPreview_20261104')
local imported = workspace:FindFirstChild('PlayerRoster_Batch_20261104')
assert(preview and imported, 'Expected preview and imported batch')
local rollback = storage:FindFirstChild('_PlayerRosterImportRollback_20261104')
if not rollback then
    rollback = Instance.new('Folder')
    rollback.Name = '_PlayerRosterImportRollback_20261104'
    preview:Clone().Parent = rollback
    imported:Clone().Parent = rollback
    rollback.Parent = storage
end

local heights = {7, 7.35, 6.75, 7.7, 6.95, 7.25, 7.2, 7.1, 7.05, 7.2, 7.25, 7.5, 7.5, 7.7}
local results = {}
for index = 1, 14 do
    local name = string.format('Player_%02d', index)
    local model = preview:FindFirstChild(name)
    if model then
        model.PrimaryPart = model:FindFirstChildWhichIsA('MeshPart', true)
    else
        local source = imported:FindFirstChild(name)
        assert(source and source:IsA('MeshPart'), 'Missing imported mesh ' .. name)
        local editable = assets:CreateEditableMeshAsync(Content.fromUri(source.MeshId))
        local ids = editable:GetBones()
        assert(#ids >= 50 and #ids <= 52, 'Incorrect skin bone count for ' .. name)
        local bones = {}
        local frames = {}
        local parents = {}
        model = Instance.new('Model')
        model.Name = name
        local mesh = source:Clone()
        mesh.Name = 'PlayerMesh'
        mesh.CFrame = CFrame.identity
        mesh.Parent = model
        model.PrimaryPart = mesh
        -- The importer merged same-named joints across all 13 skeletons.
        -- Recover each asset's own bind pose, in mesh-local space.
        for _, id in ids do
            local bone = Instance.new('Bone')
            bone.Name = editable:GetBoneName(id)
            bones[id] = bone
            frames[id] = editable:GetBoneCFrame(id)
            parents[id] = editable:GetBoneParent(id)
        end
        for _, id in ids do
            local parentId = parents[id]
            local bone = bones[id]
            if parentId ~= 0 and bones[parentId] then
                bone.CFrame = frames[parentId]:ToObjectSpace(frames[id])
                bone.Parent = bones[parentId]
            else
                bone.CFrame = frames[id]
                bone.Parent = mesh
            end
        end
        editable:Destroy()
        local controller = Instance.new('AnimationController')
        controller.Name = 'AnimationController'
        controller.Parent = model
        model:ScaleTo(heights[index] / mesh.Size.Y)
        model.Parent = preview
    end
    local mesh = model.PrimaryPart
    mesh.Anchored = true
    mesh.CanCollide = false
    mesh.CanTouch = false
    mesh.CanQuery = false
    mesh.CastShadow = true
    mesh.Color = Color3.new(1, 1, 1)
    mesh.Material = Enum.Material.SmoothPlastic
    local column = (index - 1) % 7
    local row = math.floor((index - 1) / 7)
    local x = -270 + column * 10
    local z = -900 + row * 20
    model:PivotTo(CFrame.new(x, 2.4 + mesh.Size.Y / 2, z))
    model:SetAttribute('PreviewOnly', true)
    model:SetAttribute('PreviewIndex', index)
    model:SetAttribute('TargetHeight', heights[index])
    local stand = preview:FindFirstChild(name .. '_Stand') or Instance.new('Part')
    stand.Name = name .. '_Stand'
    stand.Size = Vector3.new(9, 2.4, 8)
    stand.Position = Vector3.new(x, 1.2, z)
    stand.Anchored = true
    stand.Material = Enum.Material.SmoothPlastic
    stand.Color = Color3.fromRGB(48, 57, 67)
    stand.TopSurface = Enum.SurfaceType.Smooth
    stand.BottomSurface = Enum.SurfaceType.Smooth
    stand.Parent = preview
    local plaque = preview:FindFirstChild(name .. '_Label') or Instance.new('Part')
    plaque:ClearAllChildren()
    plaque.Name = name .. '_Label'
    plaque.Size = Vector3.new(8, 1.2, 0.1)
    plaque.Position = Vector3.new(x, 1.3, z - 4.06)
    plaque.Anchored = true
    plaque.CanCollide = false
    plaque.CanTouch = false
    plaque.CanQuery = false
    plaque.Color = Color3.fromRGB(20, 26, 34)
    plaque.Parent = preview
    local gui = Instance.new('SurfaceGui')
    gui.Face = Enum.NormalId.Front
    gui.CanvasSize = Vector2.new(800, 120)
    gui.LightInfluence = 0
    gui.ZOffset = 1
    gui.Parent = plaque
    local label = Instance.new('TextLabel')
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = string.format('PLAYER %02d', index)
    label.TextColor3 = Color3.fromRGB(235, 239, 245)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = gui
    table.insert(results, {Name = name, Height = mesh.Size.Y, Mesh = mesh.MeshId, Texture = mesh.TextureID})
    task.wait()
end
for _, name in {'PreviewStand', 'PreviewLabel'} do
    local old = preview:FindFirstChild(name)
    if old then old:Destroy() end
end
imported.Name = 'OriginalMergedImport'
imported.Parent = rollback
game:GetService('Selection'):Set({})
return game:GetService('HttpService'):JSONEncode(results)
