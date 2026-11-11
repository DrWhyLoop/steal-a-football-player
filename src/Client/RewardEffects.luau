-- Cosmetic cage-break glow, burst, reveal pop-in and safe-return feedback; never grants or selects a reward.
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

-- Starburst: thin neon rays in the plane facing the camera that shoot outwards and fade.
local function rays(anchor,position,color,count)
 local camera=workspace.CurrentCamera
 local right,up=camera.CFrame.RightVector,camera.CFrame.UpVector
 for i=1,count do
  local angle=i/count*2*math.pi+math.random()*.2
  local direction=right*math.cos(angle)+up*math.sin(angle)
  local ray=Instance.new("Part") ray.Material=Enum.Material.Neon ray.Color=color ray.Anchored=true ray.CanCollide=false ray.CanTouch=false ray.CanQuery=false ray.CastShadow=false
  local length=R.RayLength*(.6+math.random()*.4)
  ray.Size=Vector3.new(.35,.35,length) ray.Transparency=.1
  ray.CFrame=CFrame.lookAt(position+direction*R.RayLength*.15,position+direction)*CFrame.new(0,0,-length/2)
  ray.Parent=anchor
  TweenService:Create(ray,TweenInfo.new(R.PopSeconds*2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Transparency=1,Size=Vector3.new(.05,.05,length*1.6),CFrame=ray.CFrame*CFrame.new(0,0,-R.RayLength*.5)}):Play()
 end
end

-- Pop text above the burst: one coloured line per lucky/variant tag, floating up and fading.
local function popText(anchor,lines)
 local gui=Instance.new("BillboardGui") gui.Size=UDim2.fromOffset(300,36*#lines) gui.StudsOffsetWorldSpace=Vector3.new(0,R.PopTextHeight,0) gui.AlwaysOnTop=true gui.Adornee=anchor gui.Parent=anchor
 for i,line in lines do
  local text=Instance.new("TextLabel") text.BackgroundTransparency=1 text.Position=UDim2.fromScale(0,(i-1)/#lines) text.Size=UDim2.fromScale(1,1/#lines)
  text.TextScaled=true text.Font=Enum.Font.GothamBlack text.Text=line.Text text.TextColor3=line.Color text.TextStrokeTransparency=.2 text.Parent=gui
  TweenService:Create(text,TweenInfo.new(R.PopTextSeconds*.5,Enum.EasingStyle.Quad,Enum.EasingDirection.In,0,false,R.PopTextSeconds*.5),{TextTransparency=1,TextStrokeTransparency=1}):Play()
 end
 TweenService:Create(gui,TweenInfo.new(R.PopTextSeconds,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{StudsOffsetWorldSpace=Vector3.new(0,R.PopTextHeight+3,0)}):Play()
end

-- A short camera shake for Rare and above (the tiers in ShakeStrength), weaker the farther the player is.
local function shake(position,tier)
 local strength=R.ShakeStrength[tier]
 local character=Players.LocalPlayer.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not strength or not humanoid or not root then return end
 local amount=strength*math.max(0,1-(root.Position-position).Magnitude/R.ShakeDistance)
 if amount<=0 then return end
 local stop=os.clock()+R.ShakeSeconds
 local connection
 connection=RunService.RenderStepped:Connect(function()
  if os.clock()>=stop or not humanoid.Parent then humanoid.CameraOffset=Vector3.zero connection:Disconnect() return end
  humanoid.CameraOffset=Vector3.new((math.random()-.5)*2*amount,(math.random()-.5)*2*amount,0)
 end)
end

-- The burst: white flash, starburst of rays, confetti, loud pop, light beam, pop text and camera shake. A Lucky Cage is bigger and gold.
local function pop(position,tier,lucky,lines)
 local color=Config.Tiers[tier].Color
 local anchor=Instance.new("Part") anchor.Name="HatchPop" anchor.Transparency=1 anchor.Anchored=true anchor.CanCollide=false anchor.CanTouch=false anchor.CanQuery=false anchor.Position=position anchor.Parent=workspace
 local flash=Instance.new("Part") flash.Shape=Enum.PartType.Ball flash.Material=Enum.Material.Neon flash.Color=Color3.new(1,1,1) flash.Anchored=true flash.CanCollide=false flash.CanTouch=false flash.CanQuery=false flash.CastShadow=false
 flash.Size=Vector3.one flash.Position=position flash.Transparency=0.15 flash.Parent=anchor
 local light=Instance.new("PointLight") light.Color=color light.Brightness=6 light.Range=24 light.Parent=flash
 TweenService:Create(flash,TweenInfo.new(R.PopSeconds,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.one*(lucky and R.LuckyPopSize or R.PopSize),Transparency=1,Color=color}):Play()
 TweenService:Create(light,TweenInfo.new(R.PopSeconds),{Brightness=0}):Play()
 rays(anchor,position,lucky and R.RayColorLucky or color,lucky and R.LuckyRayCount or R.RayCount)
 local confetti=Instance.new("ParticleEmitter") confetti.Texture=SPARKLE confetti.Rate=0 confetti.Lifetime=NumberRange.new(1,1.6) confetti.Speed=NumberRange.new(14,28)
 confetti.SpreadAngle=Vector2.new(180,180) confetti.Acceleration=Vector3.new(0,-40,0) confetti.RotSpeed=NumberRange.new(-300,300) confetti.Size=NumberSequence.new(.6)
 confetti.LightEmission=.6 confetti.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,color),ColorSequenceKeypoint.new(.5,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,215,0))})
 confetti.Parent=anchor confetti:Emit(lucky and R.ConfettiCount*2 or R.ConfettiCount)
 local sound=Instance.new("Sound") sound.SoundId=R.PopSoundId sound.Volume=R.PopSoundVolume sound.Parent=anchor sound:Play()
 local beam=Instance.new("Part") beam.Shape=Enum.PartType.Cylinder beam.Material=Enum.Material.Neon beam.Color=color beam.Anchored=true beam.CanCollide=false beam.CanTouch=false beam.CanQuery=false beam.CastShadow=false
 beam.Size=Vector3.new(R.BeamHeight,R.BeamWidth,R.BeamWidth) beam.CFrame=CFrame.new(position+Vector3.new(0,R.BeamHeight/2,0))*CFrame.Angles(0,0,math.pi/2) beam.Transparency=0.3 beam.Parent=anchor
 TweenService:Create(beam,TweenInfo.new(R.BeamSeconds),{Transparency=1,Size=Vector3.new(R.BeamHeight,R.BeamWidth*.3,R.BeamWidth*.3)}):Play()
 if #lines>0 then popText(anchor,lines) end
 shake(position,tier)
 Debris:AddItem(anchor,math.max(R.BeamSeconds,R.PopTextSeconds*1.5,2))
end

-- The glow: a soft, lumpy white blob (overlapping neon balls inside a faint halo) takes the cage's place and swells, pulses and jitters harder towards the end while the luck
-- counter ticks up to the server's value, then it bursts. Only the nearest MaxConcurrent hatches get the full glow; the rest just burst on time.
local function hatch(position,tier,luck,lucky,variant,giant,radius)
 local root=Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if not root or (root.Position-position).Magnitude>R.MaxDistance then return end
 local lines={}
 if lucky then table.insert(lines,Config.PopText.Lucky) end
 if variant then table.insert(lines,Config.PopText[variant]) end
 if giant then table.insert(lines,Config.PopText.Giant) end
 if active>=R.MaxConcurrent then task.delay(R.GlowSeconds,pop,position,tier,lucky,lines) return end
 active+=1
 local anchor=Instance.new("Part") anchor.Name="CageGlow" anchor.Transparency=1 anchor.Anchored=true anchor.CanCollide=false anchor.CanTouch=false anchor.CanQuery=false anchor.Position=position anchor.Parent=workspace
 local balls={}
 for _,spec in {{1,.1,Vector3.zero},{.7,.2,Vector3.new(.55,.3,0)},{.65,.2,Vector3.new(-.5,.25,.25)},{.6,.25,Vector3.new(.1,-.25,-.55)},{.55,.25,Vector3.new(-.25,.6,-.2)},{1.3,.8,Vector3.zero}} do
  local ball=Instance.new("Part") ball.Shape=Enum.PartType.Ball ball.Material=Enum.Material.Neon ball.Color=Color3.new(1,1,1) ball.Transparency=spec[2]
  ball.Anchored=true ball.CanCollide=false ball.CanTouch=false ball.CanQuery=false ball.CastShadow=false ball.Parent=anchor
  table.insert(balls,{part=ball,size=spec[1],offset=spec[3]})
 end
 local sparkles=Instance.new("ParticleEmitter") sparkles.Texture=SPARKLE sparkles.Rate=R.SparkRateStart sparkles.Lifetime=NumberRange.new(.3,.6) sparkles.Speed=NumberRange.new(3,7)
 sparkles.SpreadAngle=Vector2.new(180,180) sparkles.LightEmission=1 sparkles.Size=NumberSequence.new(.5) sparkles.Color=ColorSequence.new(Config.Tiers[tier].Color) sparkles.Parent=anchor
 local gui=Instance.new("BillboardGui") gui.Size=UDim2.fromOffset(240,40) gui.StudsOffsetWorldSpace=Vector3.new(0,radius*R.GlowScale+R.CounterHeight,0) gui.AlwaysOnTop=true gui.Adornee=anchor gui.Parent=anchor
 local counter=Instance.new("TextLabel") counter.Size=UDim2.fromScale(1,1) counter.BackgroundTransparency=1 counter.TextScaled=true counter.Font=Enum.Font.GothamBlack
 counter.TextColor3=R.CounterColor counter.TextStrokeTransparency=.2 counter.Parent=gui
 local tick=Instance.new("Sound") tick.SoundId=R.TickSoundId tick.Volume=R.TickVolume tick.Parent=anchor
 local start,nextTick=os.clock(),0
 local connection
 connection=RunService.RenderStepped:Connect(function()
  local elapsed=os.clock()-start
  local alpha=math.min(elapsed/R.GlowSeconds,1)
  local scale=lerp(1,R.GlowScale,alpha)*(1+.06*math.sin(elapsed*lerp(R.PulseStart,R.PulseEnd,alpha)*2*math.pi))
  local jitter=lerp(R.JitterStart,R.JitterEnd,alpha)*radius
  for _,ball in balls do
   ball.part.Size=Vector3.one*radius*2*scale*ball.size
   ball.part.Position=position+ball.offset*radius*scale*.55+Vector3.new(math.random()-.5,math.random()-.5,math.random()-.5)*jitter
  end
  sparkles.Rate=lerp(R.SparkRateStart,R.SparkRateEnd,alpha)
  counter.Text=("x%.1f Luck"):format(lerp(1,luck,math.min(alpha/.85,1))) -- reaches the server's value at 85% and holds it
  if elapsed>=nextTick then tick.PlaybackSpeed=lerp(1,1.8,alpha) tick:Play() nextTick=elapsed+1/lerp(R.TickStart,R.TickEnd,alpha) end
  if alpha>=1 then
   connection:Disconnect() active-=1 anchor:Destroy()
   pop(position,tier,lucky,lines)
  end
 end)
end

-- A local visual pops in at full size (a Lucky Cage's character overshoots) without moving the authoritative card or its welds.
local function rise(card)
 if card:GetAttribute("State")~="Revealing" then return end
 local visual=card:FindFirstChild("PlayerVisual")
 local mesh=visual and visual.PrimaryPart
 local root=Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if not mesh or not root or (root.Position-card.Position).Magnitude>R.MaxDistance then return end
 local copy=Instance.new("Model") copy.Name="HatchRise"
 local part=mesh:Clone()
 for _,child in part:GetDescendants() do
  if child:IsA("WeldConstraint") or child:IsA("ParticleEmitter") then child:Destroy() end
 end
 part.Anchored=true part.Parent=copy copy.PrimaryPart=part
 local final=mesh.CFrame
 local foot=final*CFrame.new(0,-mesh.Size.Y/2,0)
 local height=mesh.Size.Y
 local oldTransparency=mesh.LocalTransparencyModifier
 mesh.LocalTransparencyModifier=1
 copy.Parent=workspace
 local start=os.clock()
 local connection
 connection=RunService.RenderStepped:Connect(function()
  local alpha=math.min((os.clock()-start)/R.RiseSeconds,1)
  if alpha>=1 or not card.Parent or card:GetAttribute("State")~="Revealing" then
   connection:Disconnect() copy:Destroy()
   if mesh.Parent then mesh.LocalTransparencyModifier=oldTransparency end
   return
  end
  local progress=TweenService:GetValue(alpha,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
  local scale=lerp(card:GetAttribute("LuckyBreak") and R.LuckyScale or R.StartScale,1,progress)
  copy:ScaleTo(scale)
  copy:PivotTo(foot*CFrame.new(0,height*scale/2,0))
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
