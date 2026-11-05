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
  local anchor=Instance.new("Part") anchor.Name="EggShuffle" anchor.Anchored=true anchor.Transparency=1
  anchor.CanCollide=false anchor.CanTouch=false anchor.CanQuery=false anchor.CFrame=CFrame.new(position) anchor.Parent=workspace
  Debris:AddItem(anchor,Config.Reveal.ShuffleSeconds+1)
  local gui=Instance.new("BillboardGui") gui.Size=UDim2.fromOffset(220,50) gui.StudsOffset=Vector3.new(0,4,0) gui.AlwaysOnTop=true gui.Parent=anchor
  local text=Instance.new("TextLabel") text.Size=UDim2.fromScale(1,1) text.BackgroundTransparency=1 text.TextScaled=true
  text.Font=Enum.Font.GothamBold text.TextColor3=Config.Tiers[tier].Color text.TextStrokeTransparency=0.2 text.Parent=gui
  local pool={} for _,entry in Config.PlayerRoster do if entry.Tier==tier then table.insert(pool,entry) end end
  local visual
  local start=os.clock() local index=0
  while os.clock()-start<Config.Reveal.ShuffleSeconds and anchor.Parent do
   index=index%#pool+1 local entry=pool[index]
   if visual then visual:Destroy() end
   visual=templates[entry.Id]:Clone() visual.Size*=Config.Reveal.DisplayHeight/visual.Size.Y
   visual.CFrame=CFrame.new(position)*CFrame.Angles(0,math.pi,0) visual.Parent=anchor text.Text=entry.Name
   local remaining=Config.Reveal.ShuffleSeconds-(os.clock()-start)
   if remaining>0 then task.wait(math.min(Config.Reveal.ShuffleStep,remaining)) end
  end
  anchor:Destroy() active-=1
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
