local CollectionService=game:GetService("CollectionService")
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Shared.Config)
local UIKit=require(script.Parent.UIKit)
local AutoSwing={}
-- The nearest cage within pickaxe range with a clear line of sight. The server checks range, facing, line of sight and the swing rate again.
local function nearestCage(character,root,params)
 local best,bestDistance
 for _,egg in CollectionService:GetTagged("Cube") do
  if egg:IsA("BasePart") and egg:IsDescendantOf(workspace) and not egg:GetAttribute("Dead") then
   local offset=egg.Position-root.Position
   local distance=offset.Magnitude
   if distance<=Config.PickaxeRange and (not bestDistance or distance<bestDistance) then
    params.FilterDescendantsInstances={character,egg}
    if not workspace:Raycast(root.Position,offset,params) then best,bestDistance=egg,distance end
   end
  end
 end
 return best
end

function AutoSwing.Init()
 local player=Players.LocalPlayer
 local gui=Instance.new("ScreenGui") gui.Name="AutoSwing" gui.ResetOnSpawn=false gui.DisplayOrder=-1 gui.Parent=player.PlayerGui
 local layout=Config.FocusUI
 local button=UIKit.Button(gui,"",UDim2.fromOffset(layout.ActionWidth,layout.ActionHeight),UDim2.new(0,16,1,-layout.ActionBottom))
 button.AnchorPoint=Vector2.new(0,1)
 button.TextSize=16
 UIKit.OnResize(function(view)
  button.Size=UDim2.fromOffset(view.Y<500 and 120 or layout.ActionWidth,layout.ActionHeight)
  button.Position=UDim2.new(0,16,1,-(view.Y<500 and 110 or 235))
 end)
 local params=RaycastParams.new()
 params.RespectCanCollide=true
 local on=false
 local function show()
  gui.Enabled=not player.PlayerGui:GetAttribute("MenuOpen")
  button.Visible=not player:GetAttribute("CarriedCard")
  UIKit.State(button,on and "Auto Swing · ON" or "Auto Swing · OFF",on,true)
 end
 player:GetAttributeChangedSignal("CarriedCard"):Connect(show)
 player.PlayerGui:GetAttributeChangedSignal("MenuOpen"):Connect(show)
 button.Activated:Connect(function() on=not on show() end)
 show()
 while gui.Parent do
  task.wait(Config.SwingCooldown+Config.AutoSwing.Margin)
  if not on then continue end
  local char=player.Character
  local humanoid=char and char:FindFirstChildOfClass("Humanoid")
  local root=char and char:FindFirstChild("HumanoidRootPart")
  if humanoid and humanoid.Health>0 and root and not player:GetAttribute("CarriedCard") then
   local cage=nearestCage(char,root,params)
   local tool=char:FindFirstChild(Config.PickaxeName) or player.Backpack:FindFirstChild(Config.PickaxeName)
   if cage and tool then
    local target=Vector3.new(cage.Position.X,root.Position.Y,cage.Position.Z)
    if (target-root.Position).Magnitude>.01 then root.CFrame=CFrame.lookAt(root.Position,target) end
    if tool.Parent~=char then humanoid:EquipTool(tool) end
    tool:Activate()
   end
  end
 end
end
return AutoSwing
