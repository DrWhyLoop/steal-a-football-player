-- Only nearby clients create the light variant effects. No server emitters or lights.
local Players=game:GetService("Players")
local CS=game:GetService("CollectionService")
local Config=require(game.ReplicatedStorage.Shared.Config)
local library=game.ReplicatedStorage:WaitForChild("VFXLibrary"):WaitForChild("Variants")
local settings=Config.VariantEffects
local active={}
while script.Parent do
 task.wait(settings.RefreshSeconds)
 local character=Players.LocalPlayer.Character
 local observer=character and character:FindFirstChild("HumanoidRootPart")
 local candidates={}
 if observer then
  for _,card in CS:GetTagged("Card") do
   local visual=card:FindFirstChild("PlayerVisual")
   local mesh=visual and visual.PrimaryPart
   if mesh and card:IsDescendantOf(workspace) then
    local distance=(mesh.Position-observer.Position).Magnitude
    if distance<settings.Far then table.insert(candidates,{card=card,mesh=mesh,distance=distance}) end
   end
  end
 end
 table.sort(candidates,function(a,b) return a.distance<b.distance end)
 local retained={}
 for index,item in candidates do
  if index>settings.MaxVisible then break end
  local card,mesh=item.card,item.mesh
  local effect=active[card]
  if not effect or effect.mesh~=mesh then
   if effect then effect.anchor:Destroy() end
   local template=library:FindFirstChild(card:GetAttribute("Variant") or "Normal")
   if template then
    local anchor=Instance.new("Attachment") anchor.Name="VariantEffect" anchor.Parent=mesh
    local emitter=template:Clone() emitter.Enabled=true emitter.Rate=settings.Rate emitter.Parent=anchor
    local appearance=mesh:FindFirstChildWhichIsA("SurfaceAppearance")
    effect={anchor=anchor,emitter=emitter,mesh=mesh,appearance=appearance,color=appearance and appearance.Color or mesh.Color}
    active[card]=effect
   end
  end
  if effect then
   retained[card]=true
   effect.anchor.Position=Vector3.new(0,-mesh.Size.Y/2+settings.FootOffset,0)
   local fade=math.clamp((settings.Far-item.distance)/(settings.Far-settings.Near),0,1)
   effect.emitter.Rate=settings.Rate*fade
   local variant=card:GetAttribute("Variant") or "Normal"
   local tint=Config.Variants[variant].Tint
   if variant=="Rainbow" then
    tint=Color3.fromHSV((workspace:GetServerTimeNow()/settings.RainbowSeconds)%1,.45,1)
    local color=effect.color:Lerp(tint,Config.RewardRoll.TintBlend)
    if effect.appearance then effect.appearance.Color=color else mesh.Color=color end
   end
   effect.emitter.Color=ColorSequence.new(tint)
  end
 end
 for card,effect in active do
  if not retained[card] then
   if effect.mesh.Parent then
    if effect.appearance then effect.appearance.Color=effect.color else effect.mesh.Color=effect.color end
   end
   effect.anchor:Destroy()
   active[card]=nil
  end
 end
end
