local SS=game:GetService("ServerStorage")
local CS=game:GetService("CollectionService")
local modules=Instance.new("Folder") modules.Name="CageFitEditRead" modules.Parent=SS
for _,name in {"Config","CageFit","CageOccupant"} do game.ReplicatedStorage.Shared[name]:Clone().Parent=modules end
local Build=require(modules.CageOccupant)
local template=game.ReplicatedStorage:WaitForChild("CageOccupantTemplate")
local lineup=workspace:FindFirstChild("CageLineup")
if not lineup then lineup=Instance.new("Model") lineup.Name="CageLineup" lineup.Parent=workspace end
local pedestals={}
for _,v in workspace:GetChildren() do
 if v:IsA("BasePart") and v:FindFirstChild("PedestalLabel") then
  local id=tonumber(v.PedestalLabel.CageNumber.Text:match("CAGE (%d+)"))
  if id then pedestals[id]=v end
 end
end
-- Recover the user's ungrouped lineup without changing part transforms, sizes or appearance.
local entries={}
if #lineup:GetChildren()==0 then
 for id=1,36 do
  assert(pedestals[id],"Missing pedestal "..id)
  local entry=Instance.new("Model") entry.Name=string.format("Cage_%02d",id) entry:SetAttribute("CageNumber",id)
  local cage=Instance.new("Model") cage.Name="Cage" cage.Parent=entry
  entries[id]={entry=entry,cage=cage,pedestal=pedestals[id]}
 end
 local assigned=0
 for _,v in workspace:GetChildren() do
  if (v:IsA("BasePart") or v:IsA("Model")) and v.Name~="Pedestal" and v~=lineup then
   local cf
   if v:IsA("BasePart") then cf=v.CFrame else cf=v:GetBoundingBox() end
   local p=cf.Position local id=math.floor((p.Z+800)/14+.5)+1
   if id>=1 and id<=36 and math.abs(p.X-1254)<10 and math.abs(p.Z-(-800+(id-1)*14))<7 and p.Y>1.3 and p.Y<60 then
    v.Parent=entries[id].cage assigned+=1
    if assigned%100==0 then task.wait() end
   end
  end
 end
 for id=1,36 do local e=entries[id];assert(#e.cage:GetChildren()>0,"Empty cage "..id);e.pedestal.Parent=e.entry;e.entry.Parent=lineup end
else
 for id=1,36 do local e=assert(lineup:FindFirstChild(string.format("Cage_%02d",id)));entries[id]={entry=e,cage=e.Cage,pedestal=e.Pedestal} end
end
local out={}
for id=1,36 do
 local e=entries[id] e.entry.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 local previous=e.entry:FindFirstChild("Occupant") if previous then previous:Destroy() end
 local model=Build.Create(template,e.cage,e.pedestal)
 model:SetAttribute("CageNumber",id) model.Parent=e.entry CS:AddTag(model,"Npc")
 table.insert(out,{id=id,height=model:GetAttribute("PreviewHeight"),ratio=model:GetAttribute("FittedHeightFraction")})
 if id%6==0 then task.wait() end
end
modules:Destroy()
return out
