-- Studio-side, repeatable landscaping. Called through MCP; never runs on server startup.
local SS = game:GetService("ServerStorage")
local CS = game:GetService("CollectionService")
local configCopy = game.ReplicatedStorage.Shared.Config:Clone()
configCopy.Parent = SS
local Config = require(configCopy)
configCopy:Destroy()
local E = Config.Environment
local Format = require(game.ReplicatedStorage.Shared.NumberFormat)
local Builder = {}
local function folder(name, parent)
	local f = parent:FindFirstChild(name)
	if not f then f = Instance.new("Folder") f.Name = name f.Parent = parent end
	return f
end
local function environment()
	return folder("Environment", workspace.Greybox)
end
local function bounds(obj)
	local lo, hi
	for _, p in {obj, table.unpack(obj:GetDescendants())} do
		if p:IsA("BasePart") then
			for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
				local q = p.CFrame:PointToWorldSpace(p.Size * Vector3.new(x, y, z) / 2)
				lo = lo and Vector3.new(math.min(lo.X,q.X),math.min(lo.Y,q.Y),math.min(lo.Z,q.Z)) or q
				hi = hi and Vector3.new(math.max(hi.X,q.X),math.max(hi.Y,q.Y),math.max(hi.Z,q.Z)) or q
			end end end
		end
	end
	assert(lo, "Asset has no physical parts")
	return {Center = (lo+hi)/2, Size = hi-lo, Min = lo, Max = hi}
end
local function abs(v) return Vector3.new(math.abs(v.X), math.abs(v.Y), math.abs(v.Z)) end
local function strip(model)
	for _, d in model:GetDescendants() do
		for _, tag in CS:GetTags(d) do CS:RemoveTag(d, tag) end
		if d:IsA("LuaSourceContainer") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector")
			or d:IsA("LayerCollector") or d:IsA("Light") or d:IsA("ParticleEmitter") or d:IsA("Sound") then
			d:Destroy()
		end
	end
end
local function fit(source, name, target, targetSize, reference)
	local ref = reference or bounds(source)
	local scale = targetSize / ref.Size
	local model = Instance.new("Model")
	model.Name = name
	local copy = source:Clone()
	copy.Parent = model
	strip(model)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			local localScale = Vector3.new(abs(p.CFrame.RightVector):Dot(scale), abs(p.CFrame.UpVector):Dot(scale), abs(p.CFrame.LookVector):Dot(scale))
			local position = (p.Position-ref.Center) * scale
			local rotation = p.CFrame.Rotation
			p.Size *= localScale
			p.CFrame = target * CFrame.new(position) * rotation
			p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
			p.CastShadow = false
			for _, mesh in p:GetChildren() do
				if mesh:IsA("SpecialMesh") and mesh.MeshType == Enum.MeshType.FileMesh then
					mesh.Scale *= localScale
					mesh.Offset *= localScale
				end
			end
		end
	end
	return model
end
local function smallAsset(source, name, position, scale, angle)
	local b = bounds(source)
	local size = b.Size * scale
	return fit(source,name,CFrame.new(position+Vector3.new(0,size.Y/2,0))*CFrame.Angles(0,angle or 0,0),size)
end
-- Entrance sign text: stage name, difficulty word (coloured) and the recommended Speed Points.
local function stageSignText(n)
	local info=Config.StageInfo[n]
	return ('STAGE %d - %s\n<font color="#%s">%s</font>\n%s'):format(n,info.Name,Config.DifficultyColor[info.Difficulty]:ToHex(),info.Difficulty:upper(),Format.Recommended(info.Points))
end

local function sign(parent,name,position,size,face,text,color)
	local p=Instance.new("Part")
	p.Name,p.Size,p.Position=name,size,position
	p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,false,false,false
	p.Color,p.Material=color,Enum.Material.SmoothPlastic
	p.Parent=parent
	local gui=Instance.new("SurfaceGui")
	gui.Name="SurfaceGui" gui.Face=face gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud gui.PixelsPerStud=30 gui.Parent=p
	local label=Instance.new("TextLabel")
	label.Name="Label" label.Size=UDim2.fromScale(0.94,0.92) label.Position=UDim2.fromScale(0.03,0.04)
	label.BackgroundTransparency=1 label.Text=text label.RichText=true label.TextScaled=true label.Font=Enum.Font.GothamBold
	label.TextColor3=Color3.fromRGB(243,241,210) label.Parent=gui
	return p
end

-- Rewrites the size and text of the existing entrance signs (edit time, after Config.StageInfo or StageSignSize change).
function Builder.UpdateStageSigns()
	for n=1,Config.StageCount do
		for _,side in {-1,1} do
			local part=workspace.Greybox.Environment.Stages["Stage_"..n]["StageSign_"..side]
			part.Size=E.StageSignSize
			part.SurfaceGui.Label.RichText=true part.SurfaceGui.Label.Text=stageSignText(n)
		end
	end
end

function Builder.BuildStage(n)
	local sources=SS.EnvironmentSourceAssets
	local stage=workspace.Greybox.Hallway.Stages["Stage_"..n]
	local root=folder("Stages",environment())
	local old=root:FindFirstChild("Stage_"..n) if old then old:Destroy() end
	local group=Instance.new("Folder") group.Name="Stage_"..n group.Parent=root
	stage.Material=Enum.Material.Grass stage.Color=E.GrassColor
	local top=stage.Position.Y+stage.Size.Y/2
	local cellX=stage.Size.X/E.GrassColumns
	local halfLength=(stage.Size.Z-E.LabelClearLength)/2
	local cellZ=halfLength/E.GrassRowsPerHalf
	local grass=folder("Grass",group)
	for _, direction in {-1,1} do
		for row=1,E.GrassRowsPerHalf do
			for col=1,E.GrassColumns do
				local x=-stage.Size.X/2+(col-0.5)*cellX
				local z=direction*(E.LabelClearLength/2+(row-0.5)*cellZ)
				local center=stage.Position+Vector3.new(x,stage.Size.Y/2+E.GrassHeight/2-0.04,z)
				local rotation=(n+row+col)%2*math.pi
				local patch=fit(sources["Realistic grass"],"GrassPatch",CFrame.new(center)*CFrame.Angles(0,rotation,0),
					Vector3.new(cellX*E.GrassOverlap,E.GrassHeight,cellZ*E.GrassOverlap))
				patch.Parent=grass
			end
		end
	end
	local count=0 for _,d in grass:GetDescendants() do if d:IsA("BasePart") then count+=1 end end
	assert(count<=E.MaxGrassPartsPerStage,"Grass budget exceeded")
	local rng=Random.new(E.Seed+n)
	for _, side in {-1,1} do
		sign(group,"StageSign_"..side,Vector3.new(stage.Position.X+side*(stage.Size.X/2-0.35),top+E.StageSignHeight,stage.Position.Z-stage.Size.Z/2+18),
			E.StageSignSize,side==1 and Enum.NormalId.Left or Enum.NormalId.Right,
			stageSignText(n),E.StageSignColor)
		for _, fraction in {-0.32,0.32} do
			local position=Vector3.new(stage.Position.X+side*(stage.Size.X/2-E.EdgeInset),top,stage.Position.Z+stage.Size.Z*fraction)
			smallAsset(sources.Bush,"EdgeBush",position,E.BushScale,rng:NextNumber(0,math.pi*2)).Parent=group
		end
		local bambooPosition=Vector3.new(stage.Position.X+side*(stage.Size.X/2-E.EdgeInset),top,stage.Position.Z+side*stage.Size.Z*0.12)
		smallAsset(sources.Bamboo,"Bamboo",bambooPosition,E.BambooScale,rng:NextNumber(0,math.pi*2)).Parent=group
		local leafPosition=Vector3.new(stage.Position.X+side*(stage.Size.X/2-E.EdgeInset),top,stage.Position.Z+stage.Size.Z*0.42)
		smallAsset(sources["Bush Leaves Grass"],"BushLeaves",leafPosition,E.BushLeafScale,0).Parent=group
		for i=1,E.TuftsPerStage/2 do
			local position=Vector3.new(stage.Position.X+side*(stage.Size.X/2-E.EdgeInset-2),top,stage.Position.Z+rng:NextNumber(-stage.Size.Z*0.43,stage.Size.Z*0.43))
			smallAsset(sources.Grass,"NaturalTuft",position,E.TuftScale,rng:NextNumber(0,math.pi*2)).Parent=group
		end
	end
	group:SetAttribute("GrassParts",count)
	return {Stage=n,GrassParts=count}
end

function Builder.BuildWalls()
	local g=workspace.Greybox
	local first,last=g.Hallway.Stages.Stage_1,g.Hallway.Stages["Stage_"..Config.StageCount]
	local startZ,finishZ=first.Position.Z-first.Size.Z/2,last.Position.Z+last.Size.Z/2
	local source=SS.EnvironmentSourceAssets.GrassToplingsH1
	local ref=bounds(source)
	local wallFolder=folder("Walls",environment())
	wallFolder:ClearAllChildren()
	for _,side in {-1,1} do
		local x=first.Position.X+side*(first.Size.X/2+E.WallDepth/2+E.WallOutsideOffset)
		local target=CFrame.new(x,first.Position.Y+first.Size.Y/2+E.WallHeight/2,(startZ+finishZ)/2)
		local targetSize=Vector3.new(E.WallDepth,E.WallHeight,finishZ-startZ)
		for _,segment in source:GetChildren() do
			if segment:IsA("Model") then
				local clone=fit(segment,(side==1 and "Right_" or "Left_")..segment.Name,target,targetSize,ref)
				clone.Parent=wallFolder
				task.wait()
			end
		end
		local collider=g.Hallway.Walls[side==1 and "Wall_Right" or "Wall_Left"]
		collider.Transparency=1 collider.CastShadow=false
	end
	return {Length=finishZ-startZ,Segments=#wallFolder:GetChildren()}
end

function Builder.BuildPlot(n)
	local plot=workspace.Greybox.Plots["Plot_"..n]
	local base=plot.Base
	local old=plot:FindFirstChild("Visuals") if old then old:Destroy() end
	local source=SS.EnvironmentSourceAssets.Plots["Plot 1"]
	local ref=bounds(source)
	local xSize,zSize=base.Size.X-E.PlotInset*2,base.Size.Z-E.PlotInset*2
	local heightScale=math.min(xSize/ref.Size.X,zSize/ref.Size.Z)
	local size=Vector3.new(xSize,ref.Size.Y*heightScale,zSize)
	local top=base.Position.Y+base.Size.Y/2
	local plaza=workspace.Greybox.Plaza.PlazaFloor
	local side=base.Position.X>plaza.Position.X and 1 or -1
	local rotation=side==1 and math.pi or 0
	local frame=CFrame.new(base.Position.X,top+size.Y/2,base.Position.Z)*CFrame.Angles(0,rotation,0)
	local visual=fit(source,"Visuals",frame,size)
	local count=0
	for _,d in visual:GetDescendants() do
		if d:IsA("BasePart") then
			count+=1
			-- Floors and structural supports collide; decorative trim and pads do not.
			d.CanCollide=(d.Size.Y<0.65 and math.max(d.Size.X,d.Size.Z)>10)
				or (d.Size.Y>2 and math.min(d.Size.X,d.Size.Z)>0.2 and not d.Name:match("^Slot"))
			d.CastShadow=d.CanCollide
		end
	end
	assert(count<=E.MaxPlotVisualParts,"Plot budget exceeded")
	local padCount=0
	for i=1,Config.PlotSlots.SlotsPerFloor do
		local pad
		for _,p in visual:GetDescendants() do
			if p:IsA("BasePart") and p.Name=="Slot"..i and p.Position.Y<top+1.5 and p.Size.Y>0.06 and p.Size.Y<0.13 then
				pad=p break
			end
		end
		assert(pad,"Ground-floor display pad missing: "..i)
		local slot=plot.Slots["Slot_"..i]
		slot.Size=Vector3.new(pad.Size.X,E.SlotThickness,pad.Size.Z)
		slot.CFrame,slot.Color,slot.Material=pad.CFrame,pad.Color,pad.Material
		slot.Transparency=0 slot.CanCollide=false slot.CanTouch=false
		pad:Destroy()
		padCount+=1
	end
	visual.Parent=plot
 require(script.Parent.PlotAccess).Apply(plot)
	base.Transparency=1
	local spawn=plot.PlotSpawn
	spawn.Transparency=1
	spawn.Position=Vector3.new(base.Position.X-side*(base.Size.X/2-4),top+0.8,base.Position.Z)
	spawn.CFrame=CFrame.lookAt(spawn.Position,spawn.Position+Vector3.new(side,0,0))
	local button=plot.LockButton
	button.Position=Vector3.new(base.Position.X-side*(base.Size.X/2-2.5),top+1.1,base.Position.Z+E.PlotLockOffset)
	button.Size=Vector3.new(2,0.6,2)
	local ownerSign=plot.Sign
	ownerSign.Size=E.PlotSignSize
	ownerSign.Position=Vector3.new(base.Position.X-side*(base.Size.X/2-0.2),top+E.PlotSignHeight,base.Position.Z)
	ownerSign.Color=E.StageSignColor ownerSign.Transparency=0 ownerSign.CanCollide=false
	ownerSign.SurfaceGui.Face=side==1 and Enum.NormalId.Left or Enum.NormalId.Right
	ownerSign.SurfaceGui.Label.Size=UDim2.fromScale(0.95,0.9)
	for _,wall in plot.Barrier:GetChildren() do
		wall.Size=Vector3.new(wall.Size.X,Config.LockBarrierHeight,wall.Size.Z)
		wall.Position=Vector3.new(wall.Position.X,top+Config.LockBarrierHeight/2,wall.Position.Z)
	end
	plot.LockStatus.Position=Vector3.new(base.Position.X,top+Config.LockBarrierHeight+4,base.Position.Z)
	visual:SetAttribute("FittedSize",size)
 Builder.BuildDisplaySlots(n)
	return {Plot=n,VisualParts=count-padCount,Slots=padCount,Height=size.Y}
end

function Builder.BuildTrees()
	local root=folder("Trees",environment())
	root:ClearAllChildren()
	for n=1,Config.StageCount,E.WillowStageInterval do
		local stage=workspace.Greybox.Hallway.Stages["Stage_"..n]
		for _,side in {-1,1} do
			local p=Vector3.new(stage.Position.X+side*(stage.Size.X/2+E.TreeOutsideOffset),
				stage.Position.Y+stage.Size.Y/2,stage.Position.Z)
			smallAsset(SS.EnvironmentSourceAssets["Willow Tree"],"WillowTree",p,E.WillowScale,side*math.pi/3).Parent=root
		end
		task.wait()
	end
	local plaza=workspace.Greybox.Plaza.PlazaFloor
	for _,side in {-1,1} do
		local p=Vector3.new(plaza.Position.X+side*(plaza.Size.X/2+E.PlazaTreeOutsideOffset),plaza.Position.Y+plaza.Size.Y/2,plaza.Position.Z)
		smallAsset(SS.EnvironmentSourceAssets["Willow Tree"],"PlazaWillow",p,E.WillowScale,0).Parent=root
	end
	return #root:GetChildren()
end

-- Prepare small, script-free templates; clients only instantiate nearby scenery.
function Builder.PrepareSurroundings()
 local sources = SS.EnvironmentSourceAssets
 local extra = sources.Surroundings
 local RS = game.ReplicatedStorage
 local templates = folder("EnvironmentTemplates", RS)
 templates:ClearAllChildren()
 for _, source in extra:GetChildren() do
  if source.Name:match("^Palm Tree_") or source.Name:match("^Fern_") or source.Name:match("^Swamp Plant_") or source.Name:match("^Bush_") then
   local b = bounds(source)
   local scale = source.Name:match("^Palm") and Config.Landscape.PalmScale or source.Name:match("^Bush") and Config.Landscape.BushScale or Config.Landscape.PlantScale
   fit(source, source.Name, CFrame.new(0,b.Size.Y*scale/2,0), b.Size*scale).Parent = templates
  end
 end
 fit(sources["Realistic grass"], "GroundGrass", CFrame.new(0,Config.Landscape.GrassHeight/2,0), Vector3.new(Config.Landscape.GrassCellSize*1.04,Config.Landscape.GrassHeight,Config.Landscape.GrassCellSize*1.04)).Parent=templates
 return #templates:GetChildren()
end

local function groundBounds()
 return {Position=Config.Landscape.GroundCenter,Size=Config.Landscape.GroundSize,CFrame=CFrame.new(Config.Landscape.GroundCenter)}
end

function Builder.BuildGroundStrip(index)
 local base=groundBounds()
 local depth=Config.Landscape.GroundDepth
 local width=Config.Landscape.BorderSegmentLength
 local count=math.ceil(base.Size.X/width)
 assert(index>=1 and index<=count)
 local left=-base.Size.X/2+(index-1)*width
 local right=math.min(left+width,base.Size.X/2)
 workspace.Terrain:FillBlock(base.CFrame*CFrame.new((left+right)/2,base.Size.Y/2-depth/2,0),Vector3.new(right-left,depth,base.Size.Z),Enum.Material.Grass)
 -- Half-filled top voxels keep the visible surface at baseplate height (full voxels bulge 2 studs above it).
 local surfaceY=base.Position.Y+base.Size.Y/2
 local region=Region3.new(Vector3.new(base.Position.X+left,surfaceY-4,base.Position.Z-base.Size.Z/2),Vector3.new(base.Position.X+right,surfaceY,base.Position.Z+base.Size.Z/2)):ExpandToGrid(4)
 local materials,occupancy=workspace.Terrain:ReadVoxels(region,4)
 for x=1,#occupancy do for z=1,#occupancy[x][1] do occupancy[x][1][z]=0.5 end end
 workspace.Terrain:WriteVoxels(region,4,materials,occupancy)
 workspace.Terrain:SetMaterialColor(Enum.Material.Grass,E.GrassColor)
 workspace.Baseplate.Material=Enum.Material.Grass workspace.Baseplate.Color=E.GrassColor workspace.Baseplate.Transparency=1
 return {Strip=index,Count=count}
end

-- Prevent native grass blades from poking through the raised gameplay floors.
function Builder.TrimPlayAreas()
 local function trim(part)
  local half=Vector3.new(part.Size.X/2,0,part.Size.Z/2)
  local groundY=workspace.Baseplate.Position.Y+workspace.Baseplate.Size.Y/2
  local region=Region3.new(Vector3.new(part.Position.X-half.X,groundY-Config.Landscape.GroundDepth,part.Position.Z-half.Z),Vector3.new(part.Position.X+half.X,groundY,part.Position.Z+half.Z)):ExpandToGrid(4)
  workspace.Terrain:ReplaceMaterial(region,4,Enum.Material.Grass,Enum.Material.LeafyGrass)
 end
 for _,stage in workspace.Greybox.Hallway.Stages:GetChildren() do if stage:IsA("BasePart") then trim(stage) end end
 for _,plot in workspace.Greybox.Plots:GetChildren() do if plot:FindFirstChild("Base") then trim(plot.Base) end end
 trim(workspace.Greybox.Plaza.PlazaFloor)
 local apron=workspace.Greybox.Hallway:FindFirstChild("EntranceApron")
 if apron then trim(apron) end
 workspace.Greybox.Plaza.PlazaFloor.Material=Enum.Material.Grass
 workspace.Greybox.Plaza.PlazaFloor.Color=E.GrassColor
end

function Builder.BuildPerimeter(side)
 local L=Config.Landscape
 local base=groundBounds()
 local root=folder("Perimeter",environment())
 local name="Side_"..side
 local old=root:FindFirstChild(name) if old then old:Destroy() end
 local group=Instance.new("Model") group.Name=name group.Parent=root
 local alongX=side<=2
 local length=alongX and base.Size.X or base.Size.Z
 local direction=side%2==1 and -1 or 1
 local offset=alongX and Vector3.new(0,base.Size.Y/2+L.BorderHeight/2,direction*(base.Size.Z/2-L.BorderDepth/2)) or Vector3.new(direction*(base.Size.X/2-L.BorderDepth/2),base.Size.Y/2+L.BorderHeight/2,0)
 local frame=base.CFrame*CFrame.new(offset)*CFrame.Angles(0,alongX and math.pi/2 or 0,0)
 local collisionCount=math.ceil(length/2048)
 for i=1,collisionCount do
  local collider=Instance.new("Part") collider.Name=i==1 and "BorderCollision" or "BorderCollision_"..i
  collider.Size=Vector3.new(L.BorderDepth,L.BorderHeight,length/collisionCount)
  collider.CFrame=frame*CFrame.new(0,0,-length/2+(i-0.5)*length/collisionCount)
  collider.Anchored=true collider.Transparency=1 collider.CastShadow=false collider.Parent=group
 end
 local source=SS.EnvironmentSourceAssets.GrassToplingsH1:GetChildren()[1]:GetChildren()[1]
 local count=math.ceil(length/L.BorderSegmentLength)
 for i=1,count do
  local segment=fit(source,"GrassBorder_"..i,frame*CFrame.new(0,0,-length/2+(i-0.5)*length/count),Vector3.new(L.BorderDepth,L.BorderHeight,length/count+0.2))
  segment.Parent=group task.wait()
 end
 return count
end

-- Seal asset openings from the outside; preserve the existing border transforms.
function Builder.BuildPerimeterBacking()
 local L=Config.Landscape
 local source
 for _,model in workspace:GetChildren() do
  if model.Name=="MainWall" then
   for _,part in model:GetDescendants() do
    if part:IsA("Part") and part.Material==Enum.Material.Slate then
     if not source or part.Size.X*part.Size.Y*part.Size.Z>source.Size.X*source.Size.Y*source.Size.Z then source=part end
    end
   end
  end
 end
 assert(source,"MainWall slate reference is missing")
 local root=folder("Perimeter",environment())
 local count=0
 for side=1,4 do
  local group=root["Side_"..side]
  local old=group:FindFirstChild("SolidBacking") if old then old:Destroy() end
  local backing=Instance.new("Folder") backing.Name="SolidBacking"
  for _,collider in group:GetChildren() do if collider:IsA("BasePart") and collider.Name:match("^BorderCollision") then
  local outward=side%2==1 and -1 or 1
  local worldOutward=side<=2 and Vector3.new(0,0,outward) or Vector3.new(outward,0,0)
  local depthOffset=collider.CFrame.RightVector:Dot(worldOutward)*(collider.Size.X+L.BorderBackingDepth)/2
  local length=collider.Size.Z+L.BorderCornerOverlap*2
  local segments=math.ceil(length/L.BorderBackingSegmentLength)
  for i=1,segments do
   local part=source:Clone() part:ClearAllChildren()
   for _,tag in CS:GetTags(part) do CS:RemoveTag(part,tag) end
   part.Name="WallBacking_"..i
   part.Size=Vector3.new(L.BorderBackingDepth,collider.Size.Y+L.BorderBackingGroundOverlap,length/segments+0.1)
   part.CFrame=collider.CFrame*CFrame.new(depthOffset,-L.BorderBackingGroundOverlap/2,-length/2+(i-0.5)*length/segments)
   part.Anchored=true part.CanCollide=true part.CanTouch=false part.CanQuery=true part.CastShadow=false part.Transparency=0
   part.Parent=backing count+=1
  end
  end end
  backing.Parent=group task.wait()
 end
 return count
end

function Builder.BuildTorches()
 local L=Config.Landscape
 local root=folder("Torches",environment()) root:ClearAllChildren()
 local source=SS.EnvironmentSourceAssets.Surroundings.WallTorch_1
 local b=bounds(source)
 local function mount(position,angle,name)
  local model=Instance.new("Model") model.Name=name
  local copy=source:Clone() copy.Parent=model
  local frame=CFrame.new(position)*CFrame.Angles(0,angle,0)
  local firstLight
  for _,v in model:GetDescendants() do
   if v:IsA("LuaSourceContainer") then v:Destroy()
   elseif v:IsA("BasePart") then
    v.Size*=L.TorchScale v.CFrame=frame*CFrame.new((v.Position-b.Center)*L.TorchScale)*v.CFrame.Rotation
    v.Anchored=true v.CanCollide=false v.CanTouch=false v.CanQuery=false v.CastShadow=false
   elseif v:IsA("Light") then
    if firstLight then v:Destroy() else firstLight=v v.Enabled=false v.Shadows=false v.Range=L.TorchLightRange v.Brightness=L.TorchLightBrightness end
   elseif v:IsA("ParticleEmitter") then
    v.Enabled=false v.Rate=v.Name=="Fire" and L.TorchFireRate or v.Name=="Glow" and L.TorchGlowRate or L.TorchSmokeRate
   end
  end
  model.WorldPivot=frame model:SetAttribute("TorchFixture",true) model.Parent=root
 end
 for _,plot in workspace.Greybox.Plots:GetChildren() do
  local base=plot:FindFirstChild("Base")
  if base then
   for floor=0,2 do for _,x in {-1,1} do for _,z in {-1,1} do
    local p=base.Position+Vector3.new(x*(base.Size.X/2-L.TorchMountInset),base.Size.Y/2+L.TorchMountHeight+floor*L.TorchFloorSpacing,z*(base.Size.Z/2-L.TorchMountInset))
    mount(p,x==1 and math.pi or 0,plot.Name.."_Torch")
   end end end
  end
  task.wait()
 end
 for n=1,Config.StageCount do
  local stage=workspace.Greybox.Hallway.Stages["Stage_"..n]
  for _,side in {-1,1} do for i=1,L.TorchStagesPerSide do
   local p=stage.Position+Vector3.new(side*(stage.Size.X/2-0.9),stage.Size.Y/2+L.TorchMountHeight,stage.Size.Z*((i-0.5)/L.TorchStagesPerSide-0.5))
   mount(p,side==1 and 0 or math.pi,"Stage_"..n.."_Torch")
  end end
  task.wait()
 end
 require(script.Parent.TorchMount).Apply()
 return #root:GetChildren()
end

-- Ground-floor trim only; both side gates stay open for the existing plot controls.
function Builder.BuildFences()
 local root=folder("PlotFences",environment())
 root:ClearAllChildren()
 local source=SS.EnvironmentSourceAssets.Fence
 local ref=bounds(source)
 local count=0
 for _,plot in workspace.Greybox.Plots:GetChildren() do
  local base=plot.Base
  local x=base.Size.X/2+E.FenceOutsideOffset
  local z=base.Size.Z/2+E.FenceOutsideOffset
  local y=base.Position.Y+base.Size.Y/2+E.FenceHeight/2
  local group=Instance.new("Folder") group.Name=plot.Name group.Parent=root
  local function section(position,length,angle)
   local model=fit(source,"FenceSection",CFrame.new(position)*CFrame.Angles(0,angle,0),
    Vector3.new(E.FenceDepth,E.FenceHeight,length),ref)
   model.Parent=group count+=1
  end
  for _,side in {-1,1} do
   section(Vector3.new(base.Position.X,y,base.Position.Z+side*z),2*x,math.pi/2)
   local length=z-E.FenceGateWidth/2
   for _,endSide in {-1,1} do
    section(Vector3.new(base.Position.X+side*x,y,base.Position.Z+endSide*(E.FenceGateWidth/2+length/2)),length,0)
   end
  end
  task.wait()
 end
 return count
end

-- Rebuild every display from ServerStorage.SlotTemplates (scaled to Config.PlotSlots): a pedestal standing on the floor where the old
-- gray pad was, a collect pad in front of it and a yellow upgrade button stand beside it. The first run also removes the old pad,
-- its plinth stack and the old green/brown panels; later runs reuse the pad position stored on each pedestal.
local function scaled(template: Model, size: number): Model
 local model=template:Clone()
 model:ScaleTo(size/template:GetAttribute("SourceSize"))
 return model
end

local function billboard(part: BasePart, offset: number, textColor: Color3)
 local P=Config.PlotSlots
 local gui=Instance.new("BillboardGui") gui.Name="InfoGui" gui.Size=UDim2.fromOffset(P.LabelWidth,P.LabelHeight) gui.StudsOffsetWorldSpace=Vector3.new(0,offset,0)
 gui.MaxDistance=P.LabelDistance gui.LightInfluence=0 gui.Enabled=false gui.Adornee=part gui.Parent=part
 local label=Instance.new("TextLabel") label.Name="Label" label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1 label.Font=Enum.Font.GothamBold
 label.TextScaled=true label.TextColor3=textColor label.TextStrokeTransparency=0.3 label.RichText=true label.Parent=gui
end

function Builder.BuildDisplaySlots(n)
 local plot=workspace.Greybox.Plots["Plot_"..n]
 local P=Config.PlotSlots
 local templates=SS.SlotTemplates
 local pads,old={},{} -- pads[id]={CFrame,Size}; old = parts of the previous display to delete
 for _,p in plot.Visuals:GetDescendants() do if p:IsA("BasePart") then
  local id=tonumber(p.Name:match("^Slot(%d+)$"))
  if id and p.Size.X>2 and p.Size.X<2.3 and p.Size.Y>0.045 and p.Size.Y<0.065 and p.Size.Z>3.3 then pads[id]={CFrame=p.CFrame,Size=p.Size} end
 end end
 for _,m in (plot:FindFirstChild("Pedestals") and plot.Pedestals:GetChildren() or {}) do
  local id=tonumber(m.Name:match("%d+"))
  if id and not pads[id] then pads[id]={CFrame=m:GetAttribute("PadCFrame"),Size=m:GetAttribute("PadSize")} end
 end
 -- Old display: everything of the pad stack (pad, plinth slabs, frame lines, placeholder) within the pad footprint above the floor.
 for _,p in plot.Visuals:GetDescendants() do if p:IsA("BasePart") and p.Size.X<6 and p.Size.Z<6 then
  for _,pad in pads do
   local d=pad.CFrame:PointToObjectSpace(p.Position)
   if math.abs(d.X)<pad.Size.X/2+0.5 and math.abs(d.Z)<pad.Size.Z/2+1 and d.Y>-1.3 and d.Y<0.2 then table.insert(old,p) break end
  end
 end end
 local groundParams=RaycastParams.new() groundParams.FilterType=Enum.RaycastFilterType.Include groundParams.FilterDescendantsInstances={plot.Visuals,plot.Base}
 local function groundY(position: Vector3,fallback: number)
  local hit=workspace:Raycast(position+Vector3.new(0,2,0),Vector3.new(0,-6,0),groundParams)
  return hit and hit.Position.Y or fallback
 end
 for _,name in {"Pedestals","CollectPads","UpgradeStands","NewSlots"} do local f=plot:FindFirstChild(name) if f then f:Destroy() end end
 local function newFolder(name) local f=Instance.new("Folder") f.Name=name f.Parent=plot return f end
 local pedestals,collects,stands,slots=newFolder("Pedestals"),newFolder("CollectPads"),newFolder("UpgradeStands"),newFolder("NewSlots")
 local count,parts=0,0
 for id=1,Config.SlotsPerPlot do
  local pad=assert(pads[id],"Missing gray display "..id)
  local center=pad.CFrame.Position
  local direction=center.Z<plot.Base.Position.Z and 1 or -1
  local floorY=groundY(center,center.Y-1.1)
  local pedestal=scaled(templates.Pedestal,P.PedestalDiameter)
  pedestal.Name="Pedestal_"..id pedestal:PivotTo(CFrame.new(center.X,floorY,center.Z))
  pedestal:SetAttribute("PadCFrame",pad.CFrame) pedestal:SetAttribute("PadSize",pad.Size) pedestal.Parent=pedestals
  local top=floorY+pedestal:GetAttribute("TopHeight")*pedestal:GetScale()
  local slot=Instance.new("Part") slot.Name="Slot_"..id slot.Size=Vector3.new(pad.Size.X,E.SlotThickness,pad.Size.Z) slot.CFrame=CFrame.new(center.X,top-E.SlotThickness/2,center.Z)
  slot.Anchored=true slot.Transparency=1 slot.CanCollide=false slot.CanTouch=false slot.CanQuery=false slot:SetAttribute("SlotIndex",id) slot:SetAttribute("Floor",math.ceil(id/P.SlotsPerFloor)) slot.Parent=slots CS:AddTag(slot,"Slot")
  -- collect pad in front of the pedestal
  local padPosition=center+Vector3.new(0,0,direction*P.CollectPadOffset)
  local collect=scaled(templates.CollectPad,P.CollectPadSize)
  collect.Name="CollectPad_"..id collect:PivotTo(CFrame.new(padPosition.X,groundY(padPosition,floorY),padPosition.Z)) collect.Parent=collects
  collect.Light.Color=P.CollectLightColor
  billboard(collect.Hitbox,collect.Hitbox.Size.Y/2+1,Color3.fromRGB(120,255,120))
  -- yellow upgrade button stand beside it
  local standPosition=center+Vector3.new(P.StandSideOffset,0,direction*P.StandForwardOffset)
  local stand=scaled(templates.UpgradeStand,P.StandHeight)
  stand.Name="UpgradeStand_"..id stand:PivotTo(CFrame.new(standPosition.X,groundY(standPosition,floorY),standPosition.Z)*CFrame.Angles(0,direction==1 and 0 or math.pi,0)) stand.Parent=stands
  local button=stand.button button.Color=P.UpgradeButtonColor
  billboard(button,1.4,Color3.new(1,1,1))
  local prompt=Instance.new("ProximityPrompt") prompt.Name="UpgradePrompt" prompt.ActionText="Upgrade" prompt.KeyboardKeyCode=P.UpgradeKey prompt.MaxActivationDistance=P.UpgradePromptDistance prompt.RequiresLineOfSight=false prompt.Parent=button
  for name,target in {CollectPad=collect.Hitbox,UpgradePanel=button} do local ref=Instance.new("ObjectValue") ref.Name=name ref.Value=target ref.Parent=slot end
  for _,name in {"SlotPrompt","StealPrompt"} do local sp=Instance.new("ProximityPrompt") sp.Name=name sp.MaxActivationDistance=P.PromptDistance sp.HoldDuration=name=="StealPrompt" and Config.StealHoldSeconds or 0 sp.RequiresLineOfSight=name=="StealPrompt" sp.Parent=slot end
  count+=1
 end
 for _,folder in {pedestals,collects,stands,slots} do for _,d in folder:GetDescendants() do if d:IsA("BasePart") then parts+=1 end end end
 assert(parts<=P.PartBudgetPerSlot*Config.SlotsPerPlot,"Slot part budget exceeded: "..parts)
 for _,p in old do local parent=p.Parent if parent then p:Destroy() while parent and parent~=plot.Visuals and parent:IsA("Model") and not parent:FindFirstChildWhichIsA("BasePart",true) do local up=parent.Parent parent:Destroy() parent=up end end end
 for _,s in plot.Slots:GetChildren() do for _,tag in CS:GetTags(s) do CS:RemoveTag(s,tag) end end
 plot.Slots:Destroy()
 for _,name in {"EarningsPanels","UpgradePanels"} do local f=plot:FindFirstChild(name) if f then f:Destroy() end end
 slots.Name="Slots"
 return count,parts
end

return Builder
