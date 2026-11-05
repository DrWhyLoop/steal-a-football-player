-- Visual-only poses. The server owns damage, movement rules and guard targeting.
local Players=game:GetService('Players')
local CS=game:GetService('CollectionService')
local RunService=game:GetService('RunService')
local Shared=game.ReplicatedStorage.Shared
local Config=require(Shared.Config)
local Rig=require(Shared.RigAnimation)
local Motion={}
function Motion.Init()
    local avatars={} local models={}
    local function characterAdded(player,char)
        local humanoid=char:WaitForChild('Humanoid')
        local root=char:WaitForChild('HumanoidRootPart')
        local entry={character=char,humanoid=humanoid,root=root,rig=Rig.Bind(char)}
        avatars[player]=entry
        char.DescendantAdded:Connect(function(o)
            if o:IsA('Motor6D') or o:IsA('AnimationConstraint') then entry.rebind=true end
        end)
    end
    local function playerAdded(player)
        player.CharacterAdded:Connect(function(char) characterAdded(player,char) end)
        if player.Character then task.spawn(characterAdded,player,player.Character) end
    end
    Players.PlayerAdded:Connect(playerAdded)
    Players.PlayerRemoving:Connect(function(player) avatars[player]=nil end)
    for _,p in Players:GetPlayers() do playerAdded(p) end
    local function addModel(model)
        task.spawn(function()
            if model:HasTag('Guard') then model:WaitForChild('Visual') end
            if not model:IsDescendantOf(workspace) then return end
            models[model]={rig=Rig.Bind(model,model:GetAttribute('MonsterDesign')),active=false}
        end)
    end
    for _,tag in {'Guard','AnimatedCharacter'} do
        CS:GetInstanceAddedSignal(tag):Connect(addModel)
        CS:GetInstanceRemovedSignal(tag):Connect(function(m) models[m]=nil end)
        for _,m in CS:GetTagged(tag) do addModel(m) end
    end
    RunService.PreSimulation:Connect(function()
        local me=Players.LocalPlayer.Character
        local observer=me and me:FindFirstChild('HumanoidRootPart')
        local now=workspace:GetServerTimeNow()
        for player,a in avatars do
            if a.character.Parent and a.root.Parent and a.humanoid.Health>0 then
                if a.rebind then a.rig=Rig.Bind(a.character) a.rebind=false end
                local near=player==Players.LocalPlayer or observer and (observer.Position-a.root.Position).Magnitude<=Config.Axes.AnimationDistance
                local tool=a.character:FindFirstChild(Config.PickaxeName)
                local start=tool and tool:GetAttribute('SwingStart')
                Rig.PoseAvatar(a.rig,0,false,near and start and now-start or nil)
                local hurt=a.character:GetAttribute("HurtStart")
                Rig.PoseHurt(a.rig,near and hurt and now-hurt or nil)
            end
        end
        for model,view in models do
            local root=model.PrimaryPart
            if not model.Parent then models[model]=nil
            elseif root then
                local near=observer and (root.Position-observer.Position).Magnitude<=Config.MonsterGuards.EffectsDistance
                local moving=near and model:GetAttribute('Moving')==true
                if near or view.active then Rig.PoseBones(view.rig,model:GetAttribute('AnimationClip') or 'RunR6',now,moving,model:GetAttribute('AnimationScale')) end
                view.active=near
            end
        end
    end)
end
return Motion
