-- Mount stage torch backing plates against the actual wall collider faces.
local Mount={}
function Mount.Apply()
 local g=workspace.Greybox
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={g.Hallway.Walls}
 local fixed=0
 for _,model in g.Environment.Torches:GetChildren() do
  local index=tonumber(model.Name:match("^Stage_(%d+)_"))
  if index then
   local stage=g.Hallway.Stages["Stage_"..index] local position=model:GetPivot().Position
   local side=position.X>stage.Position.X and 1 or -1
   local hit=workspace:Raycast(Vector3.new(stage.Position.X,position.Y,position.Z),Vector3.new(side*stage.Size.X,0,0),params)
   local holder=model:FindFirstChild("Holder",true)
   if hit and holder and holder:IsA("BasePart") then
    model:PivotTo(CFrame.new(position)*CFrame.Angles(0,side==1 and math.pi or 0,0))
    local extent=math.abs(holder.CFrame.RightVector.X)*holder.Size.X/2+math.abs(holder.CFrame.UpVector.X)*holder.Size.Y/2+math.abs(holder.CFrame.LookVector.X)*holder.Size.Z/2
    local x=hit.Position.X-side*(extent+.02)-(holder.Position.X-model:GetPivot().Position.X)
    model:PivotTo(CFrame.new(x,position.Y,position.Z)*CFrame.Angles(0,side==1 and math.pi or 0,0)) fixed+=1
   end
  end
 end
 return fixed
end
return Mount
