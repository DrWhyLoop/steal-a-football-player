-- Stage banner: text only, small, top centre. Shown when the player walks into a stage: the name with its difficulty and the recommended Speed Points
-- (red when the player has fewer Speed Points than that). The first arrival in a stage (once per account) pops up under it with a sound and the cash
-- reward: it slides in and fades out after Config.StageArrival.BannerSeconds.
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Shared.Config)
local Remotes=require(RS.Shared.Remotes)
local Format=require(RS.Shared.NumberFormat)
local StageZone=require(RS.Shared.StageZone)
local UIKit=require(script.Parent.UIKit)
local Banner={}

-- A transparent top-centre block holding outlined text lines (heights are fractions of the block).
local function block(gui,row,width,height)
 local frame=Instance.new("Frame") frame.AnchorPoint=Vector2.new(.5,0) frame.Position=UDim2.new(.5,0,0,row) frame.Size=UDim2.fromScale(width,height)
 frame.BackgroundTransparency=1 frame.Visible=false frame.Parent=gui
 return frame
end
local function line(frame,kind,y,height,maxSize)
 local label=Instance.new("TextLabel") label.AnchorPoint=Vector2.new(.5,0) label.Position=UDim2.fromScale(.5,y) label.Size=UDim2.fromScale(1,height)
 label.TextScaled=true label.Parent=frame
 Instance.new("UITextSizeConstraint",label).MaxTextSize=maxSize
 return UIKit.Text(label,kind)
end
local function fade(frame,seconds,to)
 for _,label in frame:GetChildren() do if label:IsA("TextLabel") then UIKit.Fade(label,seconds,to) end end
end

function Banner.Init()
 local player=Players.LocalPlayer
 local gui=Instance.new("ScreenGui") gui.Name="StageBanner" gui.Parent=player.PlayerGui
 UIKit.Screen(gui)
 local S=Config.UIScreen
 local stage=block(gui,S.TopStage,.5,.09)
 local title,advice=line(stage,nil,0,.55,22),line(stage,"gold",.55,.45,17)
 local token=0
 local function show(number)
  local info=Config.StageInfo[number]
  local mine=player:GetAttribute("Speed") or 0
  title.Text=("STAGE %d  -  %s  (%s)"):format(number,info.Name,info.Difficulty)
  advice.Text=("%s - yours: %s"):format(Format.Recommended(info.Points),Format.Compact(mine))
  advice.TextColor3=mine<info.Points and Config.UITheme.TextWarn or Config.UITheme.TextGold
  token+=1 local mineToken=token
  fade(stage,0,0) stage.Visible=true
  task.delay(Config.StageBanner.Seconds,function()
   if token~=mineToken then return end
   fade(stage,.6,1)
   task.delay(.6,function() if token==mineToken then stage.Visible=false end end)
  end)
 end

 local A=Config.StageArrival
 local arrival=block(gui,S.TopPopup,.5,.15)
 local heading,name,reward=line(arrival,"gold",0,.4,30),line(arrival,nil,.4,.32,22),line(arrival,"gold",.72,.28,18)
 heading.Text="NEW STAGE!"
 local grow=Instance.new("UIScale") grow.Parent=arrival
 local arrivalToken=0
 Remotes.StageArrival.OnClientEvent:Connect(function(number,cash)
  name.Text=Config.StageInfo[number].Name
  reward.Text="+$"..Format.Compact(cash)
  arrivalToken+=1 local mine=arrivalToken
  fade(arrival,0,0)
  arrival.Position=UDim2.new(.5,0,0,S.TopPopup-A.SlideOffset) grow.Scale=.7 arrival.Visible=true
  local slide=TweenInfo.new(A.SlideSeconds,Enum.EasingStyle.Back)
  TweenService:Create(arrival,slide,{Position=UDim2.new(.5,0,0,S.TopPopup)}):Play()
  TweenService:Create(grow,slide,{Scale=1}):Play()
  local sound=Instance.new("Sound") sound.SoundId=A.SoundId sound.Volume=A.SoundVolume sound.Parent=gui sound:Play()
  game:GetService("Debris"):AddItem(sound,6)
  task.delay(A.BannerSeconds,function()
   if arrivalToken~=mine then return end
   fade(arrival,A.FadeSeconds,1)
   task.delay(A.FadeSeconds,function() if arrivalToken==mine then arrival.Visible=false end end)
  end)
 end)

 local current
 while gui.Parent do
  task.wait(Config.StageBanner.CheckSeconds)
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local number=root and StageZone.At(root.Position)
  if number~=current then current=number if number then show(number) end end
 end
end
return Banner
