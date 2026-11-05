-- Auto Swing: a toggle button that keeps swinging the equipped pickaxe. The server still enforces the swing cooldown, range and
-- facing for every swing (PickaxeService), so this only saves taps; faster requests are simply ignored.
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Shared.Config)
local UIKit=require(script.Parent.UIKit)
local AutoSwing={}
function AutoSwing.Init()
 local player=Players.LocalPlayer
 local gui=Instance.new("ScreenGui") gui.Name="AutoSwing" gui.ResetOnSpawn=false gui.Parent=player.PlayerGui
 local button=UIKit.Button(gui,"Auto Swing",UDim2.fromOffset(140,44),UDim2.new(1,-152,.48,-144))
 local on=false
 local function show() UIKit.State(button,on and "Auto Swing: ON" or "Auto Swing: OFF",on,true) end
 button.Activated:Connect(function() on=not on show() end)
 show()
 while gui.Parent do
  task.wait(Config.SwingCooldown+Config.AutoSwing.Margin)
  local char=player.Character
  local humanoid=char and char:FindFirstChildOfClass("Humanoid")
  if on and humanoid and humanoid.Health>0 and not player:GetAttribute("CarriedCard") then
   local tool=char:FindFirstChild(Config.PickaxeName) or player.Backpack:FindFirstChild(Config.PickaxeName)
   if tool then
    if tool.Parent~=char then humanoid:EquipTool(tool) end
    tool:Activate()
   end
  end
 end
end
return AutoSwing
