-- Shows the variant odds of a Lucky Egg while the player looks at it (screen-centre aim, so it also works on touch).
local CS=game:GetService("CollectionService")
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Shared.Config)
local UIKit=require(script.Parent.UIKit)
local Lucky=Config.LuckyEgg
local LuckyOdds={}
function LuckyOdds.Init()
 local player=Players.LocalPlayer
 local gui=Instance.new("ScreenGui") gui.Name="LuckyOdds" gui.DisplayOrder=40 gui.Parent=player:WaitForChild("PlayerGui")
 UIKit.Screen(gui)
 local text=Instance.new("TextLabel") text.AnchorPoint=Vector2.new(.5,0) text.Position=UDim2.fromScale(.5,.62) text.Size=UDim2.fromScale(.8,.06)
 text.TextScaled=true text.Visible=false text.Parent=gui
 Instance.new("UITextSizeConstraint",text).MaxTextSize=22
 UIKit.Text(text,"gold")
 text.Text=("Lucky Cage: %.1f–%.1fx luck · better size, variant and income rolls"):format(Config.Luck.LuckyMin,Config.Luck.LuckyMax)
 task.spawn(function()
  while true do
   task.wait(Config.CardLabels.RefreshSeconds/2)
   local camera=workspace.CurrentCamera
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   local seen=false
   if camera and root then
    for _,egg in CS:GetTagged("Cube") do
     if egg:GetAttribute("Lucky") and not egg:GetAttribute("Dead") and (egg.Position-root.Position).Magnitude<=Lucky.OddsDistance then
      if camera.CFrame.LookVector:Dot((egg.Position-camera.CFrame.Position).Unit)>=Lucky.LookDot then seen=true break end
     end
    end
   end
   text.Visible=seen
  end
 end)
end
return LuckyOdds
