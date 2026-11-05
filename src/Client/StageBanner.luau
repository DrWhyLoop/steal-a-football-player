-- Stage banner: shown when the player walks into a stage. Names the stage and the recommended movement speed (studs/s),
-- in red when the player is slower than that.
local Players=game:GetService("Players")
local CS=game:GetService("CollectionService")
local TweenService=game:GetService("TweenService")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Banner={}
local function stageAt(position)
 for _,floor in CS:GetTagged("StageZone") do
  local p=floor.CFrame:PointToObjectSpace(position)
  if math.abs(p.X)<=floor.Size.X/2 and math.abs(p.Z)<=floor.Size.Z/2 then return floor:GetAttribute("Stage") end
 end
end
function Banner.Init()
 local player=Players.LocalPlayer
 local gui=Instance.new("ScreenGui") gui.Name="StageBanner" gui.ResetOnSpawn=false gui.Parent=player.PlayerGui
 local label=Instance.new("TextLabel") label.AnchorPoint=Vector2.new(.5,0) label.Position=UDim2.new(.5,0,0,70) label.Size=UDim2.fromOffset(420,76)
 label.BackgroundColor3=Color3.fromRGB(14,22,32) label.BackgroundTransparency=.25 label.TextColor3=Color3.new(1,1,1) label.Font=Enum.Font.GothamBold
 label.TextSize=22 label.RichText=true label.Visible=false label.Parent=gui
 local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,12) corner.Parent=label
 local token=0
 local function show(stage)
  local info=Config.StageInfo[stage]
  local mine=player:GetAttribute("MovementSpeed") or Config.BaseWalkSpeed
  local color=mine<info.Speed and "#FF7070" or "#7DFF9B"
  label.Text=('STAGE %d  -  %s\n<font size="18" color="%s">Recommended speed: %d (yours: %.0f)</font>'):format(stage,info.Name,color,info.Speed,mine)
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
  local stage=root and stageAt(root.Position)
  if stage~=current then current=stage if stage then show(stage) end end
 end
end
return Banner
