-- One bounded rain volume and a small nearest-fixture light budget per client.
local RS=game:GetService("ReplicatedStorage")
local Lighting=game:GetService("Lighting")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
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
  local fixtures={}
  local root=workspace:WaitForChild("Greybox"):WaitForChild("Environment"):WaitForChild("Torches")
  for _,model in root:GetChildren() do
   local effects={} local light
   for _,v in model:GetDescendants() do if v:IsA("ParticleEmitter") then table.insert(effects,v) elseif v:IsA("Light") then light=v end end
   table.insert(fixtures,{Position=model:GetPivot().Position,Effects=effects,Light=light})
  end
  while root.Parent do
   local camera=workspace.CurrentCamera
   local character=game.Players.LocalPlayer.Character
   local characterRoot=character and character:FindFirstChild("HumanoidRootPart")
   local position=characterRoot and characterRoot.Position or camera and camera.CFrame.Position
   local phase=state:GetAttribute("Current")
   params.FilterDescendantsInstances=character and {character} or {}
   local sheltered=position and workspace:Raycast(position,Vector3.new(0,W.RoofProbeHeight,0),params)
   rain.Enabled=phase=="Rain" and position~=nil and not sheltered
   local candidates={}
   for _,fixture in fixtures do
    fixture.Distance=position and (fixture.Position-position).Magnitude or math.huge
    table.insert(candidates,fixture)
   end
   table.sort(candidates,function(a,b) return a.Distance<b.Distance end)
   for i,fixture in candidates do
    local enabled=phase~="Sunny" and fixture.Distance<L.TorchEffectDistance and i<=L.MaxTorchEffects
    for _,emitter in fixture.Effects do emitter.Enabled=enabled end
    if fixture.Light then fixture.Light.Enabled=enabled and fixture.Distance<L.TorchLightDistance and i<=L.MaxTorchLights end
   end
   task.wait(Config.Environment.VisibilityUpdateSeconds)
  end
 end)
end
return Controller
