-- Shared builder using supplied meshes, native R15 rigs and layered clothing.
local Players=game:GetService("Players")
local SS=game:GetService("ServerStorage")
local configCopy=game.ReplicatedStorage.Shared.Config:Clone()
configCopy.Parent=SS
local Config=require(configCopy)
configCopy:Destroy()
local Factory={}
local function classicJoints(model)
 for _,v in model:GetDescendants() do
  if v:IsA("AnimationConstraint") then
   local a0,a1=v.Attachment0,v.Attachment1
   if a0 and a1 then
    local motor=Instance.new("Motor6D") motor.Name=v.Name motor.Part0=a0.Parent motor.Part1=a1.Parent motor.C0=a0.CFrame motor.C1=a1.CFrame motor.Parent=a1.Parent
   end
   v:Destroy()
  elseif v:IsA("BallSocketConstraint") then v:Destroy() end
 end
end
local function clean(model)
 for _,v in model:GetDescendants() do
  if v:IsA("LuaSourceContainer") or v:IsA("LayerCollector") or v:IsA("Sound") or v:IsA("ProximityPrompt") or v:IsA("ClickDetector") then v:Destroy() end
 end
end
local function accessory(source)
 if source:IsA("Accessory") then
  local a=source:Clone() clean(a)
  for _,v in a:GetDescendants() do if v:IsA("JointInstance") or v:IsA("WeldConstraint") or v:IsA("Constraint") then v:Destroy() end end
  for _,v in a:GetDescendants() do if v:IsA("BasePart") then v.Anchored=false v.CanCollide=false v.CanTouch=false v.CanQuery=false v.Massless=true end end
  return a
 end
 local a=Instance.new("Accessory") a.Name=source.Name
 local handle=source:IsA("BasePart") and source:Clone() or source:FindFirstChild("Handle"):Clone()
 handle.Name="Handle" handle.Parent=a clean(a)
 for _,v in a:GetDescendants() do if v:IsA("JointInstance") or v:IsA("WeldConstraint") or v:IsA("Constraint") then v:Destroy() end end
 for _,v in a:GetDescendants() do if v:IsA("BasePart") then v.Anchored=false v.CanCollide=false v.CanTouch=false v.CanQuery=false v.Massless=true end end
 if source:IsA("Hat") then a.AttachmentPoint=source.AttachmentPoint end
 return a
end
local function garment(model,source,color)
 local a=accessory(source)
 for _,v in a:GetDescendants() do
  if v:IsA("BasePart") then v.Color=color v.Material=Enum.Material.Fabric if v:IsA("MeshPart") then v.TextureID="" end
  elseif v:IsA("SurfaceAppearance") or v:IsA("Decal") or v:IsA("Texture") then v:Destroy() end
 end
 model.Humanoid:AddAccessory(a)
 return a
end
function Factory.Build(recipe)
 local sources=SS.CharacterSourceAssets
 local d=Instance.new("HumanoidDescription")
 d.HeightScale=recipe.Height d.WidthScale=recipe.Width d.DepthScale=recipe.Width d.HeadScale=1 d.BodyTypeScale=0.3
 d.HeadColor=recipe.Skin d.TorsoColor=recipe.Skin d.LeftArmColor=recipe.Skin d.RightArmColor=recipe.Skin d.LeftLegColor=recipe.Skin d.RightLegColor=recipe.Skin
 local model=Players:CreateHumanoidModelFromDescriptionAsync(d,Enum.HumanoidRigType.R15) d:Destroy()
 classicJoints(model)
 if recipe.Body=="Slim" then
  local native=model
  model=sources.Slim:Clone() clean(model)
  model.Humanoid.BodyWidthScale.Value=recipe.Width*Config.CharacterPreview.SlimWidthMultiplier
  model.Humanoid.BodyDepthScale.Value=Config.CharacterPreview.SlimDepthMultiplier
  local oldHead=model.Head local head=native.Head:Clone()
  for _,v in head:GetChildren() do if v:IsA("Motor6D") or v:IsA("Constraint") then v:Destroy() end end
  head.CFrame=oldHead.CFrame
  for _,v in model:GetDescendants() do if v:IsA("Motor6D") then if v.Part0==oldHead then v.Part0=head end if v.Part1==oldHead then v.Part1=head end end end
  oldHead:Destroy() head.Parent=model native:Destroy()
  head.CFrame=model.UpperTorso.CFrame*model.UpperTorso.NeckRigAttachment.CFrame*head.NeckRigAttachment.CFrame:Inverse()
  local neck=Instance.new("Motor6D") neck.Name="Neck" neck.Part0=model.UpperTorso neck.Part1=head neck.C0=model.UpperTorso.NeckRigAttachment.CFrame neck.C1=head.NeckRigAttachment.CFrame neck.Parent=head
  model.Humanoid:BuildRigFromAttachments()
 end
 local _,bodySize=model:GetBoundingBox() model:ScaleTo(Config.CharacterPreview.BodyHeight*recipe.Height/bodySize.Y)
 model.Name=recipe.Name clean(model)
 local bodyColors=model:FindFirstChildOfClass("BodyColors") if bodyColors then bodyColors:Destroy() end
 for _,v in model:GetDescendants() do
  if v:IsA("Decal") or v:IsA("SurfaceAppearance") then v:Destroy()
  elseif v:IsA("BasePart") then
   v.Color=recipe.Skin v.Material=Enum.Material.SmoothPlastic
   if v:IsA("MeshPart") then v.TextureID="" end
   v.Anchored=false v.CanCollide=false v.CanTouch=false v.CanQuery=false v.Massless=true
  end
 end
 local h=model.Humanoid h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 local faceSource=sources[recipe.Face]:FindFirstChildWhichIsA("Decal",true)
 if recipe.Face=="Fierce cartoon face" then for _,v in sources[recipe.Face]:GetDescendants() do if v:IsA("Decal") and v.Texture:find("36021254",1,true) then faceSource=v end end end
 assert(faceSource,"Face image missing: "..recipe.Face)
 local face=faceSource:Clone() face.Name="face" face.Face=Enum.NormalId.Front face.Parent=model.Head
 garment(model,sources["TShirt_TyeDye_001-Black"],recipe.Shirt)
 garment(model,sources.Shorts,recipe.Shorts)
 for _,side in {"Left","Right"} do
  for _,item in {{Part=side.."LowerLeg",Name=side.."KitSock",Color=recipe.Socks},{Part=side.."Foot",Name=side.."KitBoot",Color=recipe.Boots}} do
   local limb=model[item.Part]
   local shell=limb:Clone() shell:ClearAllChildren() shell.Name=item.Name
   shell.Size=limb.Size*Config.CharacterPreview.KitShellScale shell.CFrame=limb.CFrame
   shell.Color=item.Color shell.Material=Enum.Material.Fabric shell.Transparency=0
   shell.Anchored=false shell.CanCollide=false shell.CanTouch=false shell.CanQuery=false shell.Massless=true
   if shell:IsA("MeshPart") then shell.TextureID="" end
   local weld=Instance.new("WeldConstraint") weld.Part0=limb weld.Part1=shell weld.Parent=shell
   shell.Parent=model
  end
 end
 if recipe.Hair then
  local a=accessory(sources[recipe.Hair])
  local handle=a.Handle
  if recipe.Hair=="Straight short hair" then
   local attachment=Instance.new("Attachment") attachment.Name="HairAttachment" attachment.CFrame=CFrame.new(recipe.HairAttachmentOffset) attachment.Parent=handle
  end
  if recipe.HairMeshScale then local mesh=handle:FindFirstChildOfClass("SpecialMesh") if mesh then mesh.Scale*=recipe.HairMeshScale end end
  h:AddAccessory(a)
 end
 if recipe.Beard then h:AddAccessory(accessory(sources[recipe.Beard])) end
 for _,v in model:GetDescendants() do if v:IsA("BasePart") then v.CanCollide=false v.CanTouch=false v.CanQuery=false v.Massless=true end end
 model.HumanoidRootPart.Anchored=true
 model:SetAttribute("PreviewOnly",true)
 return model
end
return Factory
