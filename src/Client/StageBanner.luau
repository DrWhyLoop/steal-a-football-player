-- Stage banner: shown when the player walks into a stage. Names the stage with its difficulty and the recommended Speed Points,
-- in red when the player has fewer Speed Points than that.
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Format=require(game.ReplicatedStorage.Shared.NumberFormat)
local UIKit=require(script.Parent.UIKit)
local StageZone=require(script.Parent.StageZone)
local Banner={}
function Banner.Init()
 local player=Players.LocalPlayer
 local gui=Instance.new("ScreenGui") gui.Name="StageBanner" gui.ResetOnSpawn=false gui.Parent=player.PlayerGui
 local label=Instance.new("TextLabel") label.AnchorPoint=Vector2.new(.5,0) label.Position=UDim2.new(.5,0,0,70) label.Size=UDim2.fromOffset(560,76)
 label.BackgroundColor3=Color3.fromRGB(14,22,32) label.BackgroundTransparency=.25 label.TextColor3=Config.UITheme.Text label.Font=Enum.Font.FredokaOne
 label.TextSize=22 label.RichText=true label.Visible=false label.Parent=gui
 local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,12) corner.Parent=label
 UIKit.Card(label)
 label.TextWrapped=true
 UIKit.OnResize(function(view)
  label.Size=UDim2.fromOffset(math.min(560,view.X-32),view.X<Config.UITheme.CompactWidth and 100 or 76)
  label.Position=UDim2.new(.5,0,0,20)
 end)
 local token=0
 local function show(stage)
  local info=Config.StageInfo[stage]
  local mine=player:GetAttribute("Speed") or 0
  local color=mine<info.Points and "#AD3429" or "#28733F"
  label.Text=('STAGE %d  -  %s  (%s)\n<font size="18" color="%s">%s - yours: %s</font>'):format(stage,info.Name,info.Difficulty,color,Format.Recommended(info.Points),Format.Compact(mine))
  token+=1 local mine_token=token
  label.TextTransparency=0 label.BackgroundTransparency=.25 label.Visible=true
  task.delay(Config.StageBanner.Seconds,function()
   if token~=mine_token then return end
   TweenService:Create(label,TweenInfo.new(.6),{TextTransparency=1,BackgroundTransparency=1}):Play()
   task.delay(.6,function() if token==mine_token then label.Visible=false end end)
  end)
 end
 local current
 while gui.Parent do
  task.wait(Config.StageBanner.CheckSeconds)
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local stage=root and StageZone.At(root.Position)
  if stage~=current then current=stage if stage then show(stage) end end
 end
end
return Banner
