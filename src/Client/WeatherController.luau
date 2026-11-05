-- One local rain volume; every dim, shadow-free torch is active throughout the night.
local RS=game:GetService("ReplicatedStorage")
local Lighting=game:GetService("Lighting")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local CS=game:GetService("CollectionService")
local Config=require(RS.Shared.Config)
local W,L=Config.Weather,Config.Landscape
local Controller={}
function Controller.Init()
 local state=RS:WaitForChild("WeatherState")
 local skies=RS:WaitForChild("WeatherSkies")
 local atmosphere=Lighting:FindFirstChildOfClass("Atmosphere")
 local lightTween,atmosphereTween
 local function apply()
  local preset=W.Presets[state:GetAttribute("Current")]
  if not preset then return end
  local old=Lighting:FindFirstChildOfClass("Sky") if old then old:Destroy() end
  local sky=skies[preset.Sky]:Clone() sky.Name="ActiveWeatherSky" sky.Parent=Lighting
  if lightTween then lightTween:Cancel() end
  lightTween=TweenService:Create(Lighting,TweenInfo.new(W.TransitionSeconds),{Brightness=preset.Brightness,Ambient=preset.Ambient,OutdoorAmbient=preset.OutdoorAmbient}) lightTween:Play()
  if atmosphere then
   if atmosphereTween then atmosphereTween:Cancel() end
   atmosphereTween=TweenService:Create(atmosphere,TweenInfo.new(W.TransitionSeconds),{Density=preset.Density,Haze=preset.Haze,Color=preset.Color}) atmosphereTween:Play()
  end
 end
 state:GetAttributeChangedSignal("Current"):Connect(apply) apply()
 local rainPart=Instance.new("Part") rainPart.Name="LocalWeatherRain" rainPart.Size=Vector3.new(W.RainArea,0.1,W.RainArea)
 rainPart.Transparency=1 rainPart.Anchored=true rainPart.CanCollide=false rainPart.CanTouch=false rainPart.CanQuery=false rainPart.CastShadow=false rainPart.Parent=workspace
 local rain=Instance.new("ParticleEmitter") rain.Name="Rain" rain.Texture=W.RainTexture rain.EmissionDirection=Enum.NormalId.Bottom
 rain.Rate=W.RainRate rain.Speed=NumberRange.new(W.RainSpeed) rain.Lifetime=NumberRange.new(W.RainLifetime)
 rain.Size=NumberSequence.new(W.RainSize) rain.Transparency=NumberSequence.new(W.RainTransparency) rain.Orientation=Enum.ParticleOrientation.FacingCameraWorldUp
 rain.SpreadAngle=Vector2.new(4,4) rain.LightEmission=0.25 rain.Enabled=false rain.Parent=rainPart
 local params=RaycastParams.new() params.RespectCanCollide=true params.FilterType=Enum.RaycastFilterType.Exclude
 RunService.RenderStepped:Connect(function()
  local elapsed=workspace:GetServerTimeNow()-state:GetAttribute("CycleStart")
  Lighting.ClockTime=(elapsed%W.DaySeconds)/W.DaySeconds*24
  local camera=workspace.CurrentCamera
  if camera then rainPart.Position=camera.CFrame.Position+Vector3.new(0,W.RainHeight,0) end
 end)
 task.spawn(function()
  local glow=setmetatable({},{__mode="k"}) -- lights and emitters that are on at night (torches and the Forest Lake stones)
  local function trackTorch(v)
   if v:IsA("ParticleEmitter") then v.Rate=v.Name=="Fire" and L.TorchFireRate or v.Name=="Glow" and L.TorchGlowRate or L.TorchSmokeRate glow[v]=true
   elseif v:IsA("Light") then v.Brightness=L.TorchLightBrightness v.Range=L.TorchLightRange v.Shadows=false glow[v]=true end
  end
  local root=workspace:WaitForChild("Greybox"):WaitForChild("Environment"):WaitForChild("Torches")
  root.DescendantAdded:Connect(trackTorch) -- streaming loads torches as the player approaches
  for _,v in root:GetDescendants() do trackTorch(v) end
  local function trackGlow(v) if v:IsA("Light") then v.Shadows=false end glow[v]=true end
  CS:GetInstanceAddedSignal("NightGlow"):Connect(trackGlow)
  for _,v in CS:GetTagged("NightGlow") do trackGlow(v) end
  while root.Parent do
   local camera=workspace.CurrentCamera
   local character=game.Players.LocalPlayer.Character
   local characterRoot=character and character:FindFirstChild("HumanoidRootPart")
   local position=characterRoot and characterRoot.Position or camera and camera.CFrame.Position
   local phase=state:GetAttribute("Current")
   params.FilterDescendantsInstances=character and {character} or {}
   local sheltered=position and workspace:Raycast(position,Vector3.new(0,W.RoofProbeHeight,0),params)
   rain.Enabled=phase=="Rain" and position~=nil and not sheltered
   local night=phase=="Night"
   for v in glow do v.Enabled=night end
   task.wait(Config.Environment.VisibilityUpdateSeconds)
  end
 end)
end
return Controller
