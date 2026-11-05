-- Cosmetic hatch, reveal rise and safe-return feedback; never grants or selects a reward.
local CS=game:GetService("CollectionService")
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Config=require(RS.Shared.Config)
local Remotes=require(RS.Shared.Remotes)
local R=Config.Reveal
local SPARKLE="rbxasset://textures/particles/sparkles_main.dds"
local Effects={}
local active=0

local function lerp(a,b,t) return a+(b-a)*t end

-- Flash, confetti, sound and the light beam that announces the character.
local function pop(position,color)
 local anchor=Instance.new("Part") anchor.Name="HatchPop" anchor.Transparency=1 anchor.Anchored=true anchor.CanCollide=false anchor.CanTouch=false anchor.CanQuery=false anchor.Position=position anchor.Parent=workspace
 local flash=Instance.new("Part") flash.Shape=Enum.PartType.Ball flash.Material=Enum.Material.Neon flash.Color=Color3.new(1,1,1) flash.Anchored=true flash.CanCollide=false flash.CanTouch=false flash.CanQuery=false flash.CastShadow=false
 flash.Size=Vector3.one flash.Position=position flash.Transparency=0.15 flash.Parent=anchor
 local light=Instance.new("PointLight") light.Color=color light.Brightness=6 light.Range=24 light.Parent=flash
 TweenService:Create(flash,TweenInfo.new(R.PopSeconds,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.one*R.PopSize,Transparency=1,Color=color}):Play()
 TweenService:Create(light,TweenInfo.new(R.PopSeconds),{Brightness=0}):Play()
 local confetti=Instance.new("ParticleEmitter") confetti.Texture=SPARKLE confetti.Rate=0 confetti.Lifetime=NumberRange.new(1,1.6) confetti.Speed=NumberRange.new(14,28)
 confetti.SpreadAngle=Vector2.new(180,180) confetti.Acceleration=Vector3.new(0,-40,0) confetti.RotSpeed=NumberRange.new(-300,300) confetti.Size=NumberSequence.new(.6)
 confetti.LightEmission=.6 confetti.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,color),ColorSequenceKeypoint.new(.5,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,215,0))})
 confetti.Parent=anchor confetti:Emit(R.ConfettiCount)
 local sound=Instance.new("Sound") sound.SoundId=R.PopSoundId sound.Volume=R.PopSoundVolume sound.Parent=anchor sound:Play()
 local beam=Instance.new("Part") beam.Shape=Enum.PartType.Cylinder beam.Material=Enum.Material.Neon beam.Color=color beam.Anchored=true beam.CanCollide=false beam.CanTouch=false beam.CanQuery=false beam.CastShadow=false
 beam.Size=Vector3.new(R.BeamHeight,R.BeamWidth,R.BeamWidth) beam.CFrame=CFrame.new(position+Vector3.new(0,R.BeamHeight/2,0))*CFrame.Angles(0,0,math.pi/2) beam.Transparency=0.3 beam.Parent=anchor
 TweenService:Create(beam,TweenInfo.new(R.BeamSeconds),{Transparency=1,Size=Vector3.new(R.BeamHeight,R.BeamWidth*.3,R.BeamWidth*.3)}):Play()
 Debris:AddItem(anchor,math.max(R.BeamSeconds,2))
end

-- The still server egg is animated locally: it swells, shakes harder, glows and cracks with sparkles, then pops when destroyed.
local function hatch(egg,tier)
 local root=Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if not egg or not egg.Parent or not root or active>=R.MaxConcurrent or (root.Position-egg.Position).Magnitude>R.MaxDistance then return end
 active+=1
 local color=Config.Tiers[tier].Color
 local rest,size,position=egg.CFrame,egg.Size,egg.Position
 local glow=Instance.new("Highlight") glow.FillColor=color glow.OutlineColor=color glow.FillTransparency=1 glow.DepthMode=Enum.HighlightDepthMode.Occluded glow.Parent=egg
 local cracks=Instance.new("ParticleEmitter") cracks.Texture=SPARKLE cracks.Rate=R.SparkRateStart cracks.Lifetime=NumberRange.new(.3,.6) cracks.Speed=NumberRange.new(3,7)
 cracks.SpreadAngle=Vector2.new(180,180) cracks.LightEmission=1 cracks.Size=NumberSequence.new(.5) cracks.Color=ColorSequence.new(color) cracks.Parent=egg
 local start=os.clock()
 local connection
 connection=RunService.RenderStepped:Connect(function()
  if not egg.Parent then connection:Disconnect() return end
  local alpha=math.min((os.clock()-start)/R.SwellSeconds,1)
  local shake=lerp(R.ShakeStart,R.ShakeEnd,alpha)
  egg.Size=size*lerp(1,R.SwellScale,alpha)
  egg.CFrame=rest*CFrame.Angles((math.random()-.5)*shake,0,(math.random()-.5)*shake*2)
  glow.FillTransparency=lerp(1,R.GlowFillEnd,alpha)
  cracks.Rate=lerp(R.SparkRateStart,R.SparkRateEnd,alpha)
 end)
 local removed
 removed=egg.AncestryChanged:Connect(function() -- the server destroys the egg when the card spawns
  if egg:IsDescendantOf(workspace) then return end
  removed:Disconnect() active-=1 pop(position,color)
 end)
end

-- Cards revealed from an egg spin and rise into the server-set final CFrame, locally.
local function rise(card)
 if card:GetAttribute("State")~="Revealing" then return end
 local final=card.CFrame
 local start=os.clock()
 local connection
 connection=RunService.RenderStepped:Connect(function()
  if not card.Parent then connection:Disconnect() return end
  local alpha=math.min((os.clock()-start)/R.RiseSeconds,1)
  local lift=1-TweenService:GetValue(alpha,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
  local spin=1-TweenService:GetValue(alpha,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
  card.CFrame=final*CFrame.new(0,-lift*R.DisplayHeight/2,0)*CFrame.Angles(0,spin*R.SpinTurns*2*math.pi,0)
  if alpha>=1 then connection:Disconnect() end
 end)
end

function Effects.Init()
 Remotes.EggReveal.OnClientEvent:Connect(hatch)
 CS:GetInstanceAddedSignal("Card"):Connect(rise)
 for _,card in CS:GetTagged("Card") do rise(card) end
 Remotes.SafeReturn.OnClientEvent:Connect(function(name)
  local gui=Instance.new("ScreenGui") gui.Name="SafeReturn" gui.ResetOnSpawn=false gui.Parent=Players.LocalPlayer.PlayerGui
  local text=Instance.new("TextLabel") text.AnchorPoint=Vector2.new(0.5,0.5) text.Position=UDim2.fromScale(0.5,0.27)
  text.Size=UDim2.fromScale(0.7,0.09) text.BackgroundTransparency=1 text.TextScaled=true text.Font=Enum.Font.GothamBold
  text.Text="SAFE! "..name text.TextColor3=R.SafeColor text.TextStrokeTransparency=0.3 text.Parent=gui
  TweenService:Create(text,TweenInfo.new(R.SafeCelebrationSeconds),{Position=UDim2.fromScale(0.5,0.20),TextTransparency=1,TextStrokeTransparency=1}):Play()
  local char=Players.LocalPlayer.Character
  if char then
   local glow=Instance.new("Highlight") glow.FillColor=R.SafeColor glow.FillTransparency=0.6 glow.OutlineTransparency=1 glow.DepthMode=Enum.HighlightDepthMode.Occluded glow.Parent=char
   TweenService:Create(glow,TweenInfo.new(R.SafeCelebrationSeconds),{FillTransparency=1}):Play()
   Debris:AddItem(glow,R.SafeCelebrationSeconds)
  end
  Debris:AddItem(gui,R.SafeCelebrationSeconds)
 end)
end
return Effects
