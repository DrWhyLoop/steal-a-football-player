-- Deterministic nearby scenery: distant copies are destroyed, not merely hidden.
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Shared.Config)
local L=Config.Landscape
local Landscape={}
function Landscape.Init()
 task.spawn(function()
  local templates=RS:WaitForChild("EnvironmentTemplates")
  local root=Instance.new("Folder") root.Name="LocalLandscape" root.Parent=workspace
  local palms,plants,bushes={},{},{}
  for _,v in templates:GetChildren() do
   if v.Name:match("^Palm") then table.insert(palms,v)
   elseif v.Name:match("^Bush") then table.insert(bushes,v)
   elseif v.Name~="GroundGrass" then table.insert(plants,v) end
  end
  local clear={} -- footprints published by WorldLayout (streaming means stages and plots may not be loaded here)
  while not RS:GetAttribute("ClearZones") do task.wait(.2) end
  for _,z in game:GetService("HttpService"):JSONDecode(RS:GetAttribute("ClearZones")) do
   table.insert(clear,{X=z[1],Z=z[2],HX=z[3]+L.ClearMargin,HZ=z[4]+L.ClearMargin})
  end
  local function allowed(p,margin)
   local localPoint=p-L.GroundCenter
   if math.abs(localPoint.X)>L.GroundSize.X/2-margin or math.abs(localPoint.Z)>L.GroundSize.Z/2-margin then return false end
   for _,r in clear do if math.abs(p.X-r.X)<r.HX and math.abs(p.Z-r.Z)<r.HZ then return false end end
   return true
  end
  local function place(template,parent,p,angle)
   local clone=template:Clone()
   clone:PivotTo(CFrame.new(p)*CFrame.Angles(0,angle,0)*template:GetPivot())
   clone.Parent=parent
  end
  local cells,grass={},{ }
  local top=L.GroundCenter.Y+L.GroundSize.Y/2
  local function update(cache,size,radius,isGrass,position)
   local wanted={}
   local cx,cz=math.floor(position.X/size),math.floor(position.Z/size)
   local reach=math.ceil(radius/size)
   for x=cx-reach,cx+reach do for z=cz-reach,cz+reach do
    local p=Vector3.new((x+0.5)*size,top,(z+0.5)*size)
    if (Vector2.new(p.X-position.X,p.Z-position.Z)).Magnitude<=radius and allowed(p,size/2) then
     local key=x..":"..z wanted[key]=true
     if not cache[key] then
      local group=Instance.new("Folder") group.Name=(isGrass and "Grass_" or "Plants_")..key
      local rng=Random.new(L.Seed+x*73856093+z*19349663)
      if isGrass then
       place(templates.GroundGrass,group,p,rng:NextInteger(0,1)*math.pi)
      else
       local function add(list)
        local q=p+Vector3.new(rng:NextNumber(-size*0.35,size*0.35),0,rng:NextNumber(-size*0.35,size*0.35))
        if #list>0 and allowed(q,L.ClearMargin) then place(list[rng:NextInteger(1,#list)],group,q,rng:NextNumber(0,math.pi*2)) end
       end
       add(palms) add(bushes) for _=1,3 do add(plants) end
      end
      group.Parent=root cache[key]=group
     end
    end
   end end
   for key,group in cache do if not wanted[key] then group:Destroy() cache[key]=nil end end
  end
  while root.Parent do
   local character=game.Players.LocalPlayer.Character
   local hrp=character and character:FindFirstChild("HumanoidRootPart")
   local camera=workspace.CurrentCamera
   local p=hrp and hrp.Position or camera and camera.CFrame.Position
   if p then update(cells,L.CellSize,L.ViewRadius,false,p) update(grass,L.GrassCellSize,L.GrassRadius,true,p) end
   task.wait(L.UpdateSeconds)
  end
 end)
end
return Landscape
