-- Shared saved-plot repair; every server and newly tagged plot receives the same access.
local CS=game:GetService("CollectionService")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Access={}
local bound=setmetatable({},{__mode="k"})
local function exits(plot,container)
 local levels={}
 for _,p in container:GetChildren() do if p:IsA("BasePart") and p.Name:match("^Landing_") then table.insert(levels,p) end end
 table.sort(levels,function(a,b) return a.Position.Y<b.Position.Y end)
 for i,part in levels do
  local prompt=part:FindFirstChild("ExitPrompt") or Instance.new("ProximityPrompt")
  prompt.Name="ExitPrompt" prompt.ActionText="Step onto floor "..(i+1) prompt.ObjectText="Ladder landing"
  prompt.MaxActivationDistance=Config.PlotAccess.ExitDistance prompt.RequiresLineOfSight=false prompt.Parent=part
  if not bound[prompt] then
   bound[prompt]=true
   prompt.Triggered:Connect(function(player)
    if plot:GetAttribute("OwnerUserId")~=player.UserId then return end
    local char=player.Character local root=char and char:FindFirstChild("HumanoidRootPart") local h=char and char:FindFirstChildOfClass("Humanoid")
    if not root or not h or h.Health<=0 or (root.Position-part.Position).Magnitude>Config.PlotAccess.ExitDistance then return end
    local side=plot.Base.Position.X>workspace.Greybox.Plaza.PlazaFloor.Position.X and 1 or -1
    local target=Vector3.new(part.Position.X-side*(part.Size.X/2-1),part.Position.Y+part.Size.Y/2+h.HipHeight+root.Size.Y/2+.1,part.Position.Z)
    root.AssemblyLinearVelocity=Vector3.zero
    char:PivotTo(CFrame.lookAt(target,Vector3.new(plot.Base.Position.X,target.Y,plot.Base.Position.Z)))
    h:ChangeState(Enum.HumanoidStateType.Running)
   end)
  end
 end
end
local function landing(container,frame,size,index,side)
 local cfg=Config.PlotAccess
 local p=Instance.new("Part") p.Name="Landing_"..index p.Size=Vector3.new(cfg.LandingDepth,.3,size.Z)
 p.CFrame=CFrame.new(frame.Position.X-side*cfg.LandingDepth/2+.5*side,frame.Position.Y+size.Y/2-.15,frame.Position.Z)
 p.Color=Color3.fromRGB(59,77,131) p.Material=Enum.Material.Metal p.Anchored=true p.CanCollide=true p.CanTouch=false p.CanQuery=true p.Parent=container
end
function Access.Apply(plot)
 if not plot:IsDescendantOf(workspace.Greybox.Plots) or not plot:FindFirstChild("Base") then return end
 local cfg=Config.PlotAccess local container=plot:FindFirstChild("ClimbAccess")
 local plaza=workspace.Greybox.Plaza.PlazaFloor local side=plot.Base.Position.X>plaza.Position.X and 1 or -1
 local original={}
 for _,m in plot:GetDescendants() do if m:IsA("Model") and m.Name=="Ladder" then table.insert(original,m) end end
 if #original==0 then
  if container and (container:GetAttribute("Version") or 0)<cfg.Version then
   for _,p in container:GetChildren() do if p:IsA("TrussPart") then
    local index=p.Name:match("(%d+)$")
    local frame=CFrame.new(p.Position-Vector3.new(side*cfg.OutwardOffset,cfg.TopExtension/2,0))
    landing(container,frame,Vector3.new(0,p.Size.Y-cfg.TopExtension,cfg.LandingWidth),index,side)
   end end
   container:SetAttribute("Version",cfg.Version)
  end
  if container then exits(plot,container) end
  return
 end
 if container then container:Destroy() end
 container=Instance.new("Folder") container.Name="ClimbAccess" container:SetAttribute("Version",cfg.Version)
 for index,model in original do
  local frame,size=model:GetBoundingBox()
  local ladder=Instance.new("TrussPart") ladder.Name="Ladder_"..index
  ladder.Size=Vector3.new(cfg.LadderWidth,size.Y+cfg.TopExtension,cfg.LadderDepth)
  ladder.CFrame=CFrame.new(frame.Position+Vector3.new(side*cfg.OutwardOffset,cfg.TopExtension/2,0))
  ladder.Color=Color3.fromRGB(65,90,140) ladder.Material=Enum.Material.Metal ladder.Anchored=true ladder.CanCollide=true ladder.CanTouch=true ladder.CanQuery=true ladder.Parent=container
  landing(container,frame,size,index,side) model:Destroy()
 end
 container.Parent=plot
 exits(plot,container)
end
function Access.Init()
 for _,plot in CS:GetTagged("Plot") do Access.Apply(plot) end
 CS:GetInstanceAddedSignal("Plot"):Connect(function(plot) task.defer(Access.Apply,plot) end)
end
return Access
