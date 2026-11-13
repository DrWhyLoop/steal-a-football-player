-- Shared shop portraits. Animation only advances for visible, on-screen previews.
local RunService=game:GetService("RunService")
local Theme=require(game.ReplicatedStorage.Shared.Config).UITheme
local View={}
local animated={}
local elapsed=0
local function visible(frame)
 local position,size=frame.AbsolutePosition,frame.AbsoluteSize
 local node=frame
 while node do
  if node:IsA("GuiObject") then
   if not node.Visible then return false end
   if node.ClipsDescendants or node:IsA("ScrollingFrame") then
    local p,s=node.AbsolutePosition,node.AbsoluteSize
    if position.X+size.X<=p.X or position.X>=p.X+s.X or position.Y+size.Y<=p.Y or position.Y>=p.Y+s.Y then return false end
   end
  elseif node:IsA("ScreenGui") and not node.Enabled then return false end
  node=node.Parent
 end
 return frame:IsDescendantOf(game.Players.LocalPlayer.PlayerGui)
end
RunService.RenderStepped:Connect(function(dt)
 elapsed+=dt
 if elapsed<1/Theme.PreviewFPS then return end
 local step=elapsed elapsed=0
 for frame,item in animated do
  if not frame.Parent then animated[frame]=nil
  elseif visible(frame) then
   item.time+=step
   local turn=item.mode=="Spin" and item.time*Theme.PreviewTurnSpeed or math.sin(item.time*.6)*.12
   local bob=item.mode=="Float" and math.sin(item.time*Theme.PreviewBobSpeed)*item.height*Theme.PreviewBob or 0
   item.model:PivotTo(CFrame.new(0,bob,0)*CFrame.Angles(0,turn,0)*item.pivot)
   frame:SetAttribute("PreviewTime",item.time)
  end
 end
end)
function View.Create(parent,template,fromFront,silhouette,motion)
 local frame=Instance.new("ViewportFrame") frame.Name="ModelPreview" frame.BackgroundTransparency=1
 frame.Size=UDim2.fromScale(1,1) frame.Ambient=Color3.fromRGB(210,205,193) frame.LightColor=Color3.new(1,1,1)
 frame.LightDirection=Vector3.new(-1,-1,-1) frame.Parent=parent
 local world=Instance.new("WorldModel") world.Parent=frame
 local copy=template:Clone() local model
 if copy:IsA("Model") then model=copy else model=Instance.new("Model") copy.Parent=model end
 for _,v in model:GetDescendants() do
  if v:IsA("BasePart") then
   v.Anchored=true v.CanCollide=false v.CastShadow=false
   if silhouette then v.Color=Color3.new(0,0,0) if v:IsA("MeshPart") then v.TextureID="" end end
  elseif silhouette and v:IsA("SurfaceAppearance") then v:Destroy()
  elseif v:IsA("ParticleEmitter") or v:IsA("Light") or v:IsA("Beam") or v:IsA("Trail") then v.Enabled=false end
 end
 local cf,size=model:GetBoundingBox() model:PivotTo(CFrame.new(-cf.Position)*model:GetPivot()) model.Parent=world
 local camera=Instance.new("Camera") camera.FieldOfView=35 camera.Parent=frame frame.CurrentCamera=camera
 local function fit()
  local aspect=frame.AbsoluteSize.X/math.max(1,frame.AbsoluteSize.Y)
  local diameter=math.max(size.X,size.Y,size.Z)
  local distance=diameter*1.95/math.min(1,math.max(.3,aspect))
  camera.CFrame=CFrame.lookAt(fromFront and Vector3.new(0,size.Y*.07,-distance) or Vector3.new(distance*.5,distance*.4,distance),Vector3.zero)
 end
 frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit) fit()
 if motion then animated[frame]={model=model,pivot=model:GetPivot(),height=size.Y,time=0,mode=motion} end
 return frame
end
return View
