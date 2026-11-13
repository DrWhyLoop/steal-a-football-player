local SS=game:GetService("ServerStorage")
local RS=game:GetService("ReplicatedStorage")
local config=RS.Shared.Config:Clone() config.Parent=SS local R=require(config).Reveal config:Destroy()
local fit=RS.Shared.CageFit:Clone() fit.Parent=SS local Fit=require(fit) fit:Destroy()
local originals=SS:FindFirstChild("CageTemplates_BeforeCharacterReveal_20261111")
if not originals then
 originals=Instance.new("Folder") originals.Name="CageTemplates_BeforeCharacterReveal_20261111" originals.Parent=SS
 for id=1,36 do SS.CageTemplates["Cage "..id]:Clone().Parent=originals if id%6==0 then task.wait() end end
end
local report={}
for id=1,36 do
 local entry=workspace.CageLineup[string.format("Cage_%02d",id)]
 local m=entry.Cage:Clone() m.Name="Cage "..id m.PrimaryPart=nil
 for _,v in m:GetDescendants() do
  if v:IsA("LuaSourceContainer") or v:IsA("LayerCollector") or v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then v:Destroy() end
 end
 local center,size=Fit.Bounds(m) m.WorldPivot=CFrame.new(center)
 local visible,shells=0,0
 for _,v in m:GetDescendants() do
  if v:IsA("BasePart") then
   v.Anchored=true v.CanCollide=false v.CanTouch=false v.CanQuery=false
   if v.Transparency<1 then
    visible+=1
    local c,s=v.CFrame,v.Size
    local dimensions=Vector3.new(math.abs(c.RightVector.X)*s.X+math.abs(c.UpVector.X)*s.Y+math.abs(c.LookVector.X)*s.Z,
     math.abs(c.RightVector.Y)*s.X+math.abs(c.UpVector.Y)*s.Y+math.abs(c.LookVector.Y)*s.Z,
     math.abs(c.RightVector.Z)*s.X+math.abs(c.UpVector.Z)*s.Y+math.abs(c.LookVector.Z)*s.Z)
    local shell=(v:IsA("MeshPart") or v:IsA("UnionOperation")) and dimensions.X>=size.X*R.ShellFraction and dimensions.Y>=size.Y*R.ShellFraction and dimensions.Z>=size.Z*R.ShellFraction
    v:SetAttribute("FractureShell",shell or nil)
    if shell then shells+=1 end
   end
  end
 end
 m:SetAttribute("CageDesign",id) m:SetAttribute("BreakPrepared",true)
 local old=SS.CageTemplates:FindFirstChild(m.Name) if old then old:Destroy() end
 m.Parent=SS.CageTemplates
 table.insert(report,{id=id,visible=visible,shells=shells})
 if id%6==0 then task.wait() end
end
local previous=RS:FindFirstChild("CageOccupantTemplate")
if previous then previous:Destroy() end
local template=workspace.CageLineup.Cage_01.Occupant:Clone() template.Name="CageOccupantTemplate"
for _,tag in template:GetTags() do template:RemoveTag(tag) end
for key in template:GetAttributes() do template:SetAttribute(key,nil) end
for _,v in template:GetDescendants() do
 if v:IsA("LuaSourceContainer") or v:IsA("LayerCollector") or v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then v:Destroy()
 elseif v:IsA("Motor6D") then v.Transform=CFrame.identity
 elseif v:IsA("BasePart") then v.Anchored=true v.CanCollide=false v.CanTouch=false v.CanQuery=false end
end
template:ScaleTo(1) template:PivotTo(CFrame.new()) Fit.ApplyPose(template)
template.Parent=RS
return {cages=report,occupantParts=16,backup=originals:GetFullName()}
