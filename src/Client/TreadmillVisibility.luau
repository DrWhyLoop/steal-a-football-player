local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Visibility={}
function Visibility.Init()
 local folder=workspace.Greybox:WaitForChild("OwnedTreadmills")
 local groups={}
 local function add(model)
  if not model:IsA("Model") or model.Name~="Visual" then return end
  local effects={}
  for _,v in model:GetDescendants() do if v:IsA("ParticleEmitter") or v:IsA("Light") or v:IsA("Beam") or v:IsA("Trail") then table.insert(effects,v) end end
  groups[model]={effects=effects,active=false}
 end
 folder.DescendantAdded:Connect(add)
 for _,v in folder:GetDescendants() do add(v) end
 task.spawn(function() while true do task.wait(.5)
  local c=Players.LocalPlayer.Character local root=c and c:FindFirstChild("HumanoidRootPart")
  for _,pad in folder:GetChildren() do
   local label=pad:FindFirstChild("Label")
   if label then label.Enabled=pad:GetAttribute("OwnerUserId")==Players.LocalPlayer.UserId and root~=nil and (root.Position-pad.Position).Magnitude<=Config.Treadmills.LabelDistance end
  end
  for model,group in groups do
   if not model:IsDescendantOf(folder) then groups[model]=nil
   else local enabled=root and (model:GetPivot().Position-root.Position).Magnitude<Config.Treadmills.EffectsDistance or false
    if enabled~=group.active then for _,v in group.effects do v.Enabled=enabled end group.active=enabled end
   end
  end
 end end)
end
return Visibility
