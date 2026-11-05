-- Cosmetic reveal and safe-return feedback; never grants or selects a reward.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Config=require(RS.Shared.Config)
local Remotes=require(RS.Shared.Remotes)
local Effects={}
function Effects.Init()
 Remotes.EggReveal.OnClientEvent:Connect(function(position,tier)
  local root=Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
  if not root or (root.Position-position).Magnitude>Config.Reveal.MaxDistance then return end
  local anchor=Instance.new("Part") anchor.Name="HatchSparkles" anchor.Transparency=1 anchor.Anchored=true anchor.CanCollide=false anchor.CanTouch=false anchor.CanQuery=false anchor.Position=position anchor.Parent=workspace
  local emitter=Instance.new("ParticleEmitter") emitter.Texture="rbxasset://textures/particles/sparkles_main.dds" emitter.Rate=0 emitter.Lifetime=NumberRange.new(.3,.6) emitter.Speed=NumberRange.new(3,6) emitter.SpreadAngle=Vector2.new(180,180) emitter.LightEmission=1 emitter.Color=ColorSequence.new(Config.Tiers[tier].Color) emitter.Parent=anchor emitter:Emit(Config.Reveal.SparkCount)
  Debris:AddItem(anchor,1)
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
