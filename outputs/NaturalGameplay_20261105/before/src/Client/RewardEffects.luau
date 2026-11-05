-- Cosmetic reveal and safe-return feedback; never grants or selects a reward.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Config=require(RS.Shared.Config)
local Remotes=require(RS.Shared.Remotes)
local Effects={}
local active=0
function Effects.Init()
 local templates=RS:WaitForChild("PlayerRevealTemplates")
 Remotes.EggReveal.OnClientEvent:Connect(function(position,tier,winner)
  local root=Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
  if not root or (root.Position-position).Magnitude>Config.Reveal.MaxDistance or active>=Config.Reveal.MaxConcurrent then return end
  active+=1
  local winnerEntry
  for _,entry in Config.PlayerRoster do if entry.Id==winner then winnerEntry=entry break end end
  if not winnerEntry or not templates:FindFirstChild(winner) then active-=1 return end
  local gui=Instance.new("ScreenGui") gui.Name="EggHatchReveal" gui.ResetOnSpawn=false gui.Parent=Players.LocalPlayer.PlayerGui
  local panel=Instance.new("Frame") panel.AnchorPoint=Vector2.new(.5,.5) panel.Position=UDim2.fromScale(.5,.45)
  panel.Size=UDim2.fromScale(.40,.52) panel.BackgroundColor3=Color3.fromRGB(237,247,255) panel.Parent=gui
  local cap=Instance.new("UISizeConstraint") cap.MinSize=Vector2.new(220,260) cap.MaxSize=Vector2.new(430,470) cap.Parent=panel
  local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,20) corner.Parent=panel
  local stroke=Instance.new("UIStroke") stroke.Color=Config.Tiers[tier].Color stroke.Thickness=4 stroke.Parent=panel
  local portrait=Instance.new("Frame") portrait.Size=UDim2.new(1,-24,.70,0) portrait.Position=UDim2.fromOffset(12,12) portrait.BackgroundTransparency=1 portrait.Parent=panel
  require(script.Parent.ModelViewport).Create(portrait,templates[winner],true)
  local text=Instance.new("TextLabel") text.Size=UDim2.new(1,-20,.20,0) text.Position=UDim2.new(0,10,.72,0) text.BackgroundTransparency=1
  text.Text=winnerEntry.Name.."\n"..tier.." | Pick up your player!" text.TextColor3=Color3.fromRGB(23,40,60) text.Font=Enum.Font.GothamBold text.TextSize=20 text.TextWrapped=true text.Parent=panel
  local scale=Instance.new("UIScale") scale.Scale=.65 scale.Parent=panel
  TweenService:Create(scale,TweenInfo.new(Config.Reveal.PopSeconds,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
  local anchor=Instance.new("Part") anchor.Transparency=1 anchor.Anchored=true anchor.CanCollide=false anchor.CanTouch=false anchor.CanQuery=false anchor.CFrame=CFrame.new(position) anchor.Parent=workspace
  local emitter=Instance.new("ParticleEmitter") emitter.Texture="rbxasset://textures/particles/sparkles_main.dds" emitter.Rate=0 emitter.Lifetime=NumberRange.new(.4,.8)
  emitter.Speed=NumberRange.new(4,8) emitter.SpreadAngle=Vector2.new(180,180) emitter.LightEmission=1 emitter.Color=ColorSequence.new(Config.Tiers[tier].Color) emitter.Parent=anchor emitter:Emit(Config.Reveal.SparkCount)
  Debris:AddItem(anchor,1)
  task.wait(Config.Reveal.ShuffleSeconds)
  gui:Destroy() active-=1
 end)
 Remotes.SafeReturn.OnClientEvent:Connect(function(name)
  local gui=Instance.new("ScreenGui") gui.Name="SafeReturn" gui.ResetOnSpawn=false gui.Parent=Players.LocalPlayer.PlayerGui
  local text=Instance.new("TextLabel") text.AnchorPoint=Vector2.new(0.5,0.5) text.Position=UDim2.fromScale(0.5,0.27)
  text.Size=UDim2.fromScale(0.7,0.09) text.BackgroundTransparency=1 text.TextScaled=true text.Font=Enum.Font.GothamBold
  text.Text="SAFE! "..name text.TextColor3=Config.Reveal.SafeColor text.TextStrokeTransparency=0.3 text.Parent=gui
  TweenService:Create(text,TweenInfo.new(Config.Reveal.SafeCelebrationSeconds),{Position=UDim2.fromScale(0.5,0.20),TextTransparency=1,TextStrokeTransparency=1}):Play()
  local char=Players.LocalPlayer.Character
  if char then
   local glow=Instance.new("Highlight") glow.FillColor=Config.Reveal.SafeColor glow.FillTransparency=0.6 glow.OutlineTransparency=1 glow.DepthMode=Enum.HighlightDepthMode.Occluded glow.Parent=char
   TweenService:Create(glow,TweenInfo.new(Config.Reveal.SafeCelebrationSeconds),{FillTransparency=1}):Play()
   Debris:AddItem(glow,Config.Reveal.SafeCelebrationSeconds)
  end
  Debris:AddItem(gui,Config.Reveal.SafeCelebrationSeconds)
 end)
end
return Effects
