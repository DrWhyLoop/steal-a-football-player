-- Static, brightly lit model portraits for shop cards and the hatch result.
local View={}
function View.Create(parent,template,fromFront)
 local frame=Instance.new("ViewportFrame") frame.Name="ModelPreview" frame.BackgroundTransparency=1
 frame.Size=UDim2.fromScale(1,1) frame.Ambient=Color3.fromRGB(210,220,235) frame.LightColor=Color3.new(1,1,1)
 frame.LightDirection=Vector3.new(-1,-1,-1) frame.Parent=parent
 local world=Instance.new("WorldModel") world.Parent=frame
 local copy=template:Clone() local model
 if copy:IsA("Model") then model=copy else model=Instance.new("Model") copy.Parent=model end
 for _,v in model:GetDescendants() do
  if v:IsA("BasePart") then v.Anchored=true v.CanCollide=false v.CastShadow=false
  elseif v:IsA("ParticleEmitter") or v:IsA("Light") or v:IsA("Beam") or v:IsA("Trail") then v.Enabled=false end
 end
 local cf,size=model:GetBoundingBox() model:PivotTo(CFrame.new(-cf.Position)*model:GetPivot()) model.Parent=world
 local camera=Instance.new("Camera") camera.FieldOfView=35 camera.Parent=frame frame.CurrentCamera=camera
 local distance=math.max(size.X,size.Y,size.Z)*1.9
 camera.CFrame=CFrame.lookAt(fromFront and Vector3.new(0,size.Y*.07,-distance) or Vector3.new(distance*.5,distance*.4,distance),Vector3.zero)
 return frame
end
return View
