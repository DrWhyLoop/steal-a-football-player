-- Open ladder-steps outside the plot floors: native movement, no prompts or teleports.
local CS=game:GetService("CollectionService")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Access={}
local function part(parent,name,size,frame,visible,collide)
 local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=frame p.Anchored=true
 p.CanCollide=collide p.CanTouch=false p.CanQuery=collide p.Material=Enum.Material.Metal
 p.Color=Color3.fromRGB(65,90,140) p.Transparency=visible and 0 or 1 p.Parent=parent return p
end
function Access.Apply(plot)
 if not plot:IsDescendantOf(workspace.Greybox.Plots) or not plot:FindFirstChild("Base") then return end
 local cfg=Config.PlotAccess local old=plot:FindFirstChild("ClimbAccess")
 if old and old:GetAttribute("Version")==cfg.Version and not plot:FindFirstChild("Ladder",true) then return end
 local levels={}
 for _,m in plot:GetDescendants() do
  if m:IsA("Model") and m.Name=="Ladder" then local f,s=m:GetBoundingBox() table.insert(levels,f.Position.Y+s.Y/2) m:Destroy() end
 end
 if #levels==0 and old then for _,p in old:GetChildren() do if p:IsA("BasePart") and p.Name:match("^Landing_") then table.insert(levels,p.Position.Y+p.Size.Y/2) end end end
 if #levels==0 then levels={plot:GetAttribute("AccessFloor2Y"),plot:GetAttribute("AccessFloor3Y")} end
 if #levels<2 then return end
 table.sort(levels) plot:SetAttribute("AccessFloor2Y",levels[1]) plot:SetAttribute("AccessFloor3Y",levels[2])
 if old then old:Destroy() end
 local folder=Instance.new("Folder") folder.Name="ClimbAccess" folder:SetAttribute("Version",cfg.Version)
 local base=plot.Base local side=base.Position.X>workspace.Greybox.Plaza.PlazaFloor.Position.X and 1 or -1
 local floor1=levels[1]-(levels[2]-levels[1])
 local y={floor1,levels[1],levels[2]}
 local z=base.Position.Z+cfg.SideOffset
 for i=1,2 do
  local x0=base.Position.X+side*((i-2)*cfg.Run)
  local x1=x0+side*cfg.Run
  local bottom=Vector3.new(x0,y[i],z) local top=Vector3.new(x1,y[i+1],z)
  if i==1 then
   local entry=bottom-Vector3.new(side*3,bottom.Y-.1,0)
   part(folder,"GroundApproach",Vector3.new(cfg.Width,.2,(bottom-entry).Magnitude),CFrame.lookAt((bottom+entry)/2,bottom),true,true)
  end
  local frame=CFrame.lookAt((bottom+top)/2,top)
  part(folder,"ClimbSurface_"..i,Vector3.new(cfg.Width,.2,(top-bottom).Magnitude),frame,false,true)
  for n=0,math.ceil((top-bottom).Magnitude/cfg.RungSpacing) do
   local p=bottom:Lerp(top,n/math.ceil((top-bottom).Magnitude/cfg.RungSpacing))
   part(folder,"Rung",Vector3.new(.45,.15,cfg.Width),CFrame.new(p),true,false)
  end
  for _,offset in {-1,1} do part(folder,"Rail",Vector3.new(.18,.25,(top-bottom).Magnitude),frame*CFrame.new(offset*cfg.Width/2,0,0),true,false) end
  part(folder,"OpenLanding_"..i,Vector3.new(cfg.Width,.25,cfg.BridgeLength),CFrame.new(x1,y[i+1]-.125,z-cfg.BridgeLength/2+cfg.Width/2),true,true)
 end
 folder.Parent=plot
end
function Access.Init()
 for _,plot in CS:GetTagged("Plot") do Access.Apply(plot) end
 CS:GetInstanceAddedSignal("Plot"):Connect(function(plot) task.defer(Access.Apply,plot) end)
end
return Access
