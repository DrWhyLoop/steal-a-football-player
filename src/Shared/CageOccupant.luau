-- Shared fitting for inspection copies and nearby client-only live-cage occupants.
local Config=require(script.Parent.Config)
local Fit=require(script.Parent.CageFit)
local Occupant={}
function Occupant.Create(template,cage,pedestal,baseY)
 local settings=Config.Npc.CagePreview
 local model=template:Clone()
 model.Name="Occupant"
 for _,tag in model:GetTags() do model:RemoveTag(tag) end
 local root=model:FindFirstChild("HumanoidRootPart")
 assert(root,"Occupant template needs a root")
 model.PrimaryPart=root
 model:PivotTo(CFrame.new())
 Fit.ApplyPose(model)
 local inside=Fit.Interior(cage,pedestal,settings,baseY)
 local center,body=Fit.Bounds(model)
 local height=center.Y+body.Y/2-Fit.FeetLow(model)
 local available=inside.roof-inside.floor
 assert(available>0,"Cage interior has no height")
 local wanted=(available*settings.HeightFraction-settings.FloorClearance)/height
 local diagonal=math.sqrt(body.X^2+body.Z^2)
 local inner=inside.size*settings.InnerFraction
 local limit=math.min(inner.X,inner.Z)*settings.BodyWidthFraction/(diagonal*settings.BodyRadiusFactor*2)
 local factor=math.min(wanted,limit)
 model:ScaleTo(model:GetScale()*factor)
 local _,size=Fit.Bounds(model)
 local home=Vector3.new(inside.center.X,inside.floor+root.Position.Y-Fit.FeetLow(model)+settings.FloorClearance,inside.center.Z)
 model:PivotTo(CFrame.new(home))
 Fit.ApplyPose(model,inside.floor+settings.FloorClearance)
 for _,part in model:GetDescendants() do
  if part:IsA("BasePart") then part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false end
 end
 local radius=math.sqrt(size.X^2+size.Z^2)*settings.BodyRadiusFactor
 local rx,rz=math.max(0,inner.X/2-radius),math.max(0,inner.Z/2-radius)
 local design=cage:GetAttribute("CageDesign") or cage.Parent:GetAttribute("CageNumber")
 if table.find({4,6,13,19,36},design) then local r=math.min(rx,rz)*settings.RoundRouteFactor rx,rz=r,r end
 model:SetAttribute("CagePreview",true)
 model:SetAttribute("CageNumber",design)
 model:SetAttribute("CageBoundsCenter",inside.center)
 model:SetAttribute("CageBoundsSize",inside.size)
 model:SetAttribute("BaseFloorY",baseY)
 model:SetAttribute("Home",model:GetPivot().Position)
 model:SetAttribute("WalkHalfExtents",Vector3.new(rx,0,rz))
 model:SetAttribute("PreviewHeight",size.Y)
 model:SetAttribute("InteriorFloorY",inside.floor)
 model:SetAttribute("InteriorRoofY",inside.roof)
 model:SetAttribute("FittedHeightFraction",(height*factor+settings.FloorClearance)/available)
 model:SetAttribute("WidthLimited",factor<wanted-.0001)
 return model
end
return Occupant
