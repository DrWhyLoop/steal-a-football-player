-- With streaming each client only has nearby parts loaded, but local scenery (LandscapeController) must stay off the stages, plots,
-- plaza, lakes, treehouses and paths everywhere. The server publishes their footprints once as a JSON attribute on ReplicatedStorage:
-- { {x, z, halfX, halfZ}, ... } (axis-aligned bounds). Tags: StageZone, ClearZone, and the Base part of every Plot.
local CollectionService=game:GetService("CollectionService")
local HttpService=game:GetService("HttpService")
local Layout={}
local function footprint(inst)
	local cf,size
	if inst:IsA("Model") then cf,size=inst:GetBoundingBox() else cf,size=inst.CFrame,inst.Size end
	local half=size/2
	local function reach(axis) return math.abs(cf.RightVector[axis])*half.X+math.abs(cf.UpVector[axis])*half.Y+math.abs(cf.LookVector[axis])*half.Z end
	return {cf.Position.X,cf.Position.Z,reach("X"),reach("Z")}
end
function Layout.Zones()
	local zones={}
	for _,tag in {"StageZone","ClearZone"} do
		for _,inst in CollectionService:GetTagged(tag) do table.insert(zones,footprint(inst)) end
	end
	for _,plot in CollectionService:GetTagged("Plot") do
		if plot:FindFirstChild("Base") then table.insert(zones,footprint(plot.Base)) end
	end
	return zones
end
function Layout.Publish()
	game:GetService("ReplicatedStorage"):SetAttribute("ClearZones",HttpService:JSONEncode(Layout.Zones()))
end
return Layout
