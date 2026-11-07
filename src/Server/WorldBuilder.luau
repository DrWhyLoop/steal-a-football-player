-- Edit-time builder (run through the Studio MCP, never at startup). Places the world outside the stages into Workspace.World from the
-- source models in ServerStorage.WorldSourceAssets: lakes, treehouses, stone paths, the jungle and the animals. Everything is placed
-- deterministically (Config.World.Seed), copies share the source meshes, and nothing is placed on a stage, plot, plaza, lake,
-- treehouse or path. Run Builder.Build() to (re)build; it replaces Workspace.World.
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Config = require(game.ReplicatedStorage.Shared.Config)
local Layout = require(script.Parent.WorldLayout)
local W = Config.World
local Builder = {}

local sources = ServerStorage:WaitForChild("WorldSourceAssets")
local rng
local zones = {}    -- reserved footprints {x, z, halfX, halfZ}
local segments = {} -- stone paths {Vector2 a, Vector2 b}

local function blocked(x: number, z: number, margin: number): boolean
	for _, r in zones do
		if math.abs(x - r[1]) < r[3] + margin and math.abs(z - r[2]) < r[4] + margin then return true end
	end
	local p = Vector2.new(x, z)
	for _, s in segments do
		local ab = s[2] - s[1]
		local t = math.clamp((p - s[1]):Dot(ab) / ab:Dot(ab), 0, 1)
		if (p - (s[1] + ab * t)).Magnitude < W.PathClear + margin then return true end
	end
	return false
end

local function anchorAll(model: Instance)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then d.Anchored = true d.CastShadow = false end
	end
end

-- Clone `source` (scaled), stand it on the ground with its bounding box centred on (x, z) and turned by `yaw` radians.
local function place(source: Instance, x: number, z: number, yaw: number, parent: Instance, scale: number?): Model
	local m = source:Clone()
	if scale and scale ~= 1 then m:ScaleTo(m:GetScale() * scale) end
	m:PivotTo(CFrame.Angles(0, yaw, 0))
	local cf, size = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + Vector3.new(x - cf.Position.X, W.GroundY - (cf.Position.Y - size.Y / 2), z - cf.Position.Z))
	anchorAll(m)
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	m.Parent = parent
	return m
end

local function footprint(m: Model): {number}
	local cf, size = m:GetBoundingBox()
	local half = size / 2
	local function reach(axis) return math.abs(cf.RightVector[axis]) * half.X + math.abs(cf.UpVector[axis]) * half.Y + math.abs(cf.LookVector[axis]) * half.Z end
	return {cf.Position.X, cf.Position.Z, reach("X"), reach("Z")}
end

local function reserveModel(m: Model)
	CollectionService:AddTag(m, "ClearZone") -- WorldLayout publishes it so local scenery stays off it
	table.insert(zones, footprint(m))
end

local function buildLakes(root: Instance)
	local folder = Instance.new("Folder") folder.Name = "Lakes" folder.Parent = root
	for _, lake in W.Lakes do
		local m = place(sources[lake.Source], lake.Position.X, lake.Position.Y, lake.Yaw, folder, lake.Scale)
		reserveModel(m)
		-- the Forest Lake stones glow at night only: their existing lights are switched by WeatherController (tag NightGlow)
		for _, d in m:GetDescendants() do
			if d:IsA("Light") or d:IsA("ParticleEmitter") then d.Enabled = false CollectionService:AddTag(d, "NightGlow") end
		end
	end
end

local function buildTreehouses(root: Instance)
	local folder = Instance.new("Folder") folder.Name = "Treehouses" folder.Parent = root
	for _, house in W.Treehouses do reserveModel(place(sources["Remastered Tree House"], house.Position.X, house.Position.Y, house.Yaw, folder)) end
end

local function buildPaths(root: Instance)
	local folder = Instance.new("Folder") folder.Name = "Paths" folder.Parent = root
	local stones = sources.Stones:GetChildren()
	local P = W.Path
	for _, path in W.Paths do
		local group = Instance.new("Folder") group.Name = path.Name group.Parent = folder
		for i = 1, #path.Points - 1 do
			local a, b = path.Points[i], path.Points[i + 1]
			table.insert(segments, {a, b})
			local direction = (b - a).Unit
			local side = Vector2.new(-direction.Y, direction.X)
			for distance = 0, (b - a).Magnitude, P.Step do
				for _, lane in {-P.Lane, P.Lane} do
					local p = a + direction * distance + side * (lane + rng:NextNumber(-P.Jitter, P.Jitter))
					local stone = stones[rng:NextInteger(1, #stones)]:Clone()
					stone.CFrame = CFrame.new(p.X, W.GroundY + stone.Size.Y / 2 + P.Lift, p.Y) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
					stone.Anchored, stone.CanCollide, stone.CanTouch, stone.CanQuery, stone.CastShadow = true, false, false, false, false
					stone.Parent = group
				end
			end
		end
	end
end

-- Trees only block at their trunk: every mesh part is non-colliding and one invisible cylinder (a clone of one template) stands at the
-- trunk, sized and offset from the Trunk part by the fractions in Config.World.Jungle.Trunk.
local trunkTemplate = Instance.new("Part")
trunkTemplate.Name, trunkTemplate.Shape, trunkTemplate.Transparency = "TrunkCollider", Enum.PartType.Cylinder, 1
trunkTemplate.Anchored, trunkTemplate.CanCollide, trunkTemplate.CanTouch, trunkTemplate.CanQuery, trunkTemplate.CastShadow = true, true, false, false, false

local function makeTrunkCollider(tree: Model, kind: string)
	local T = W.Jungle.Trunk
	local def, trunk = T[kind], tree:FindFirstChild("Trunk")
	for _, d in tree:GetDescendants() do
		if d:IsA("BasePart") then d.CanCollide, d.CanTouch, d.CanQuery = false, false, false end
	end
	local diameter = def.Diameter * trunk.Size.X
	local centre = trunk.CFrame:PointToWorldSpace(Vector3.new(def.Offset.X * trunk.Size.X, 0, def.Offset.Y * trunk.Size.Z))
	local collider = trunkTemplate:Clone()
	collider.Size = Vector3.new(T.Height, diameter, diameter)
	collider.CFrame = CFrame.new(centre.X, trunk.Position.Y - trunk.Size.Y / 2 + T.Height / 2, centre.Z) * CFrame.Angles(0, 0, math.pi / 2)
	collider.Parent = tree
end

local function buildJungle(root: Instance)
	local folder = Instance.new("Folder") folder.Name = "Jungle" folder.Parent = root
	local J = W.Jungle
	local types = {}
	for _, name in J.Types do
		local parts = 0
		for _, d in sources[name]:GetDescendants() do if d:IsA("BasePart") then parts += 1 end end
		table.insert(types, {Name = name, Source = sources[name], Parts = parts + 1}) -- +1: the trunk collider
	end
	local candidates, area = {}, 0
	for _, band in J.Bands do
		area += (band.XMax - band.XMin) * (J.ZMax - J.ZMin)
		for x = band.XMin, band.XMax - J.Cell, J.Cell do
			for z = J.ZMin, J.ZMax - J.Cell, J.Cell do
				table.insert(candidates, Vector2.new(x + rng:NextNumber(0, J.Cell), z + rng:NextNumber(0, J.Cell)))
			end
		end
	end
	for i = #candidates, 2, -1 do local j = rng:NextInteger(1, i) candidates[i], candidates[j] = candidates[j], candidates[i] end
	local wanted, parts, count = math.floor(area * J.Density), 0, 0
	for _, p in candidates do
		if count >= wanted then break end
		local kind = types[rng:NextInteger(1, #types)]
		if parts + kind.Parts > J.PartBudget then break end
		if not blocked(p.X, p.Y, W.ClearMargin) then
			makeTrunkCollider(place(kind.Source, p.X, p.Y, rng:NextNumber(0, math.pi * 2), folder, rng:NextNumber(J.Scale[1], J.Scale[2])), kind.Name)
			parts += kind.Parts count += 1
			if count % 200 == 0 then task.wait() end -- keep Studio responsive while building
		end
	end
	return count, parts
end

local function addAnimal(folder: Instance, def, x: number, z: number)
	local m = place(sources[def.Source], x, z, rng:NextNumber(0, math.pi * 2), folder)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then d.CanCollide, d.CanTouch, d.CanQuery = false, false, false end
	end
	m:SetAttribute("HomeX", x) m:SetAttribute("HomeZ", z)
	m:SetAttribute("Radius", def.Radius) m:SetAttribute("Speed", def.Speed)
	m:SetAttribute("ForwardYaw", def.ForwardYaw or 0) -- turns the model's own front onto its walking direction
	m:SetAttribute("Phase", rng:NextNumber(0, math.pi * 2))
	CollectionService:AddTag(m, "WorldAnimal")
end

local function buildAnimals(root: Instance)
	local folder = Instance.new("Folder") folder.Name = "Animals" folder.Parent = root
	local J, A = W.Jungle, W.AnimalArea
	for _, def in W.Animals do
		for _ = 1, def.Count do
			for _ = 1, 200 do
				local band = J.Bands[rng:NextInteger(1, #J.Bands)]
				local near = rng:NextNumber() < A.NearShare -- part of the herd is placed near the start so new players meet animals early
				local x = rng:NextNumber(band.XMin, band.XMax)
				local z = near and rng:NextNumber(J.ZMin, A.NearZMax) or rng:NextNumber(A.NearZMax, J.ZMax)
				if not blocked(x, z, W.ClearMargin + def.Radius) then addAnimal(folder, def, x, z) break end
			end
		end
	end
	-- reptiles rest on the shore of the normal Lake
	for _, def in W.ShoreAnimals do
		local lake = W.ShoreLake
		addAnimal(folder, def, lake.Position.X + def.Offset.X, lake.Position.Y + def.Offset.Y)
	end
end

function Builder.Build()
	local old = workspace:FindFirstChild("World") if old then old:Destroy() end
	local root = Instance.new("Folder") root.Name = "World" root.Parent = workspace
	rng = Random.new(W.Seed)
	zones, segments = {}, {}
	for _, z in Layout.Zones() do table.insert(zones, z) end
	buildLakes(root)
	buildTreehouses(root)
	buildPaths(root)
	local trees, treeParts = buildJungle(root)
	buildAnimals(root)
	return {Trees = trees, TreeParts = treeParts}
end

return Builder
