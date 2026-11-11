-- Studio-only pose previews. Imported scripts and animation assets are never executed.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local Pose=require(game.ReplicatedStorage.Shared.MonsterPose)
local Players = game:GetService("Players")
local preview = workspace:WaitForChild("MonsterStagePreview",10)
if not preview then return end
local previewRotation = CFrame.Angles(0,preview:GetAttribute("PreviewYaw") or 0,0)

local function bind(model, mode)
 local view = {model=model,mode=mode,roots={},links={},segments={}}
 if mode=="Sand" then
  local head=model:FindFirstChild("HEAD")
  if not head or not head:IsA("Model") then return nil end
  local center=head:GetBoundingBox().Position
  view.origin=center
  for _,name in {"HEAD","Face","BODY","TAIL"} do
   local segment=model:FindFirstChild(name)
   if not segment or not segment:IsA("Model") then return nil end
   local anchor=(name=="HEAD" or name=="Face") and center or segment:GetBoundingBox().Position
   local distance=anchor.X-center.X
   local rest=CFrame.new(center+Vector3.xAxis*distance):ToObjectSpace(segment:GetPivot())
   table.insert(view.segments,{model=segment,rest=rest,distance=distance})
  end
  return view
 end
 local torso = mode=="WalkIdle" and model:FindFirstChild("Torso",true)
 local jointRotation = torso and torso.CFrame.Rotation or previewRotation
 if mode=="Bramble" then
  local left=model:FindFirstChild("LeftUpperArm",true)
  local right=model:FindFirstChild("RightUpperArm",true)
  if not left or not right then return nil end
  local across=right.Position-left.Position
  jointRotation=CFrame.lookAt(Vector3.zero,Vector3.yAxis:Cross(across))
 end
 local graph,parts = {},{}
 local function add(a,b,joint)
  if not graph[a] or not graph[b] then return end
  local rest=a.CFrame:ToObjectSpace(b.CFrame)
  local pivot=joint and a.CFrame:ToObjectSpace(CFrame.new((a.CFrame*joint.C0).Position)*jointRotation)
  local link={a=a,b=b,rest=rest,pivot=pivot,name=b.Name:lower()}
  table.insert(graph[a],link)
  table.insert(graph[b],link)
 end
 local descendants=model:GetDescendants()
 local count=0
 for _,d in descendants do if d:IsA("Motor6D") and d.Part0 and d.Part1 then count+=1 end end
 if count<(model:GetAttribute("PreviewJointCount") or 1) or count==0 then return nil end
 for _,part in descendants do
  if part:IsA("BasePart") then graph[part]={} table.insert(parts,part) end
 end
 for _,joint in descendants do
  if joint:IsA("Motor6D") then add(joint.Part0,joint.Part1,joint) end
 end
 for _,joint in descendants do
  if joint:IsA("Weld") or joint:IsA("WeldConstraint") then add(joint.Part0,joint.Part1) end
 end
 local root=model:FindFirstChild("GuardRoot",true) or model:FindFirstChild("HumanoidRootPart",true)
 if root and graph[root] then table.insert(parts,1,root) end
 local seen={}
 for _,part in parts do
  if seen[part] then continue end
  seen[part]=true
  table.insert(view.roots,{part=part,home=part.CFrame})
  local queue={part}
  local index=1
  while index<=#queue do
   local here=queue[index]
   index+=1
   for _,edge in graph[here] do
    local other=edge.a==here and edge.b or edge.a
    if not seen[other] then
     seen[other]=true
     table.insert(queue,other)
     table.insert(view.links,{from=here,to=other,edge=edge,reverse=edge.b==here})
    end
   end
  end
 end
 return view
end

-- A closed preview route parameterized by distance, with tangent-continuous turns.
local straight, radius = 18, 28
local turn = math.pi*radius
local routeLength = 2*(straight+turn)
local function sandFrame(origin,distance)
 local s=distance%routeLength
 local x,z,yaw
 if s<straight then
  x,z,yaw=-s,0,0
 elseif s<straight+turn then
  local angle=(s-straight)/radius
  x,z,yaw=-straight-radius*math.sin(angle),radius*(math.cos(angle)-1),-angle
 elseif s<2*straight+turn then
  x,z,yaw=s-2*straight-turn,-2*radius,-math.pi
 else
  local angle=(s-2*straight-turn)/radius
  x,z,yaw=radius*math.sin(angle),-radius*(1+math.cos(angle)),-math.pi-angle
 end
 return CFrame.new(origin+Vector3.new(x,0,z))*CFrame.Angles(0,yaw,0)
end

-- Ease into and out of both speed bands, with a full stop between laps.
local function sandProgress(t)
 local cycle=24
 local u=(t%cycle)/cycle
 local distance=routeLength*(math.floor(t/cycle)+u-math.sin(2*math.pi*u)/(2*math.pi))
 local speedWeight=(1-math.cos(2*math.pi*u))/2
 return distance,speedWeight
end

local views={}
local function add(group)
 for _,model in group:GetChildren() do
  local mode=model:GetAttribute("PreviewMotion")
  if model:IsA("Model") and mode and mode~="Still" and not views[model] then views[model]=bind(model,mode) end
 end
end

local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if elapsed<1/30 then return end
 elapsed=0
 local player=Players.LocalPlayer
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 local center=preview:GetAttribute("PreviewCenter")
 if not root or not center or (root.Position-center).Magnitude>420 then return end
 for _,group in preview:GetChildren() do add(group) end
 local now=os.clock()
 for model,view in views do
  if not model:IsDescendantOf(preview) then views[model]=nil continue end
  local walkIdle=view.mode=="WalkIdle"
  local phase=now*((view.mode=="Walk" or view.mode=="Bramble" or walkIdle) and 6 or 4)
  local cycle=now%8
  local stride=walkIdle and math.clamp(math.min(cycle-2,8-cycle)*2,0,1) or 1
  if view.mode=="Sand" then
   view.started=view.started or now
   local distance,weight=sandProgress(now-view.started)
   for _,segment in view.segments do
    local offset=distance-segment.distance
    local lift=(1+math.sin(offset*.45))*.18*weight
    segment.model:PivotTo((sandFrame(view.origin,offset)+Vector3.yAxis*lift)*segment.rest)
   end
   continue
  end
  local worm=view.mode=="Earth"
  local bob=worm and .12 or (walkIdle and (.025+.065*stride) or .09)
  for _,part in view.roots do part.part.CFrame=part.home+Vector3.yAxis*(1+math.sin(phase*2))*bob end
  for _,link in view.links do
   local e=link.edge
   local offset=e.rest
   if e.pivot then offset=e.pivot*Pose.Joint(e.name,phase,view.mode,stride)*e.pivot:Inverse()*offset end
   link.to.CFrame=link.from.CFrame*(link.reverse and offset:Inverse() or offset)
  end
 end
end)
