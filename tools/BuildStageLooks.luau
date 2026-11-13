-- Edit-time (run through the Studio MCP execute_luau, Edit mode; never on server startup). Applies Config.StageInfo[n].Look to the 12 stages:
-- floor and wall materials/colours, hedge tops, vines, which organic props stay (the rest wait in ServerStorage.StageLookBackup) and the decor parts.
-- Repeatable: props are restored from the backup first, colours come from stored originals and the decor folder is rebuilt.
local SS = game:GetService("ServerStorage")
local configCopy = game.ReplicatedStorage.Shared.Config:Clone() -- a fresh require, the MCP session caches modules
configCopy.Parent = SS
local Config = require(configCopy)
configCopy:Destroy()
local L = Config.StageLook
local env = workspace.Greybox.Environment
local floors = {}
for n = 1, Config.StageCount do floors[n] = workspace.Greybox.Hallway.Stages["Stage_" .. n] end

local function stageOf(z)
	for n, floor in floors do
		if math.abs(z - floor.Position.Z) <= floor.Size.Z / 2 then return n end
	end
end
local function setLook(part, material, color)
	if material then part.Material = material end
	part.Color = color
	for _, appearance in part:GetChildren() do
		if appearance:IsA("SurfaceAppearance") then appearance.Color = color end
	end
end
-- Colour from the stored original (so a rerun never compounds), blended towards the stage tint.
local function tint(part, plant)
	local original = part:GetAttribute("StageLookOriginal") or part.Color
	part:SetAttribute("StageLookOriginal", original)
	part.Color = plant and original:Lerp(plant, 0.65) or original
end
local function category(child)
	if child.Name == "Grass" then return "Grass" end
	if child.Name == "BushLeaves" or child.Name == "EdgeBush" then return "Bush" end
	if child.Name == "NaturalTuft" then return "Tuft" end
	if child.Name == "Bamboo" then return "Bamboo" end
end
local function folder(name, parent)
	local f = parent:FindFirstChild(name) or Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local backup = folder(L.BackupFolder, SS)
for n = 1, Config.StageCount do -- restore everything first
	local saved = backup:FindFirstChild("Stage_" .. n)
	if saved then for _, child in saved:GetChildren() do child.Parent = env.Stages["Stage_" .. n] end end
end

local report = {}
for n = 1, Config.StageCount do
	local look = Config.StageInfo[n].Look
	setLook(floors[n], look.Floor.Material, look.Floor.Color)
	local stageFolder, moved = env.Stages["Stage_" .. n], 0
	for _, child in stageFolder:GetChildren() do
		local kind = category(child)
		if kind and not look.Keep[kind] then
			child.Parent = folder("Stage_" .. n, backup)
			moved += 1
		elseif kind then
			for _, part in child:GetDescendants() do if part:IsA("BasePart") then tint(part, look.Plant) end end
		end
	end
	report[n] = {moved = moved, decor = 0}
end

for _, part in env.Walls:GetDescendants() do -- wall blocks are named fatblock, everything else is the hedge top
	local n = part:IsA("BasePart") and stageOf(part.Position.Z)
	if n then
		local walls = Config.StageInfo[n].Look.Walls
		if part.Name == "fatblock" then setLook(part, walls.Material, walls.Color)
		else setLook(part, walls.TopNeon and Enum.Material.Neon or walls.TopMetal and Enum.Material.Metal or Enum.Material.Plastic, walls.Top) end
	end
end
for _, vine in env.WallVines:GetChildren() do
	local n = vine:IsA("BasePart") and stageOf(vine.Position.Z)
	local color = n and Config.StageInfo[n].Look.Walls.Vine
	if n then
		vine.Transparency = color and 0 or 1
		if color then setLook(vine, nil, color) end
	end
end

local root = folder(L.FolderName, env)
root:ClearAllChildren()
for n = 1, Config.StageCount do
	local floor, look = floors[n], Config.StageInfo[n].Look
	local out = folder("Stage_" .. n, root)
	local random = Random.new(L.Seed + n)
	local width, length = floor.Size.X, floor.Size.Z
	local centre = floor.Position
	local top = centre.Y + floor.Size.Y / 2 + L.DecorLift
	local count = 0
	local function add(entry, index, size, x, z, yaw, shape)
		count += 1
		local part = Instance.new("Part")
		part.Name = entry.Layout .. index
		part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
		part.Material = entry.Material
		part.Color = entry.Colors[(index - 1) % #entry.Colors + 1]
		local lift = L.DecorHeight / 2 + count * 0.001 -- tiny steps so overlapping parts never z-fight
		if shape == "Disc" then
			part.Shape = Enum.PartType.Cylinder
			part.Size = Vector3.new(L.DecorHeight, size.X, size.X)
			part.CFrame = CFrame.new(x, top + lift, z) * CFrame.Angles(0, yaw, math.pi / 2)
		else
			part.Size = Vector3.new(size.X, L.DecorHeight, size.Y)
			part.CFrame = CFrame.new(x, top + lift, z) * CFrame.Angles(0, yaw, 0)
		end
		part.Parent = out
	end
	for _, entry in look.Decor do
		local total = entry.Count
		for i = 1, total do
			if entry.Layout == "Stripes" then
				local band = length / total
				add(entry, i, Vector2.new(width, band), centre.X, centre.Z - length / 2 + band * (i - 0.5), 0)
			elseif entry.Layout == "Cross" then
				add(entry, i, Vector2.new(width, entry.Width), centre.X, centre.Z - length / 2 + length * i / (total + 1), 0)
			elseif entry.Layout == "Edge" then
				local side = i % 2 == 1 and -1 or 1
				add(entry, i, Vector2.new(entry.Width, length), centre.X + side * (width / 2 - entry.Width / 2 - 1), centre.Z, 0)
			elseif entry.Layout == "Long" then
				add(entry, i, Vector2.new(entry.Width, length - 2 * L.EndMargin), centre.X + (i - (total + 1) / 2) * width / (total + 1), centre.Z, 0)
			else -- Scatter
				local a, b = entry.Size[1], entry.Size[2]
				local size = entry.Shape == "Disc" and Vector2.new(random:NextNumber(a, b), 0) or Vector2.new(random:NextNumber(a, b), random:NextNumber(a, b) * 0.6)
				add(entry, i, size, centre.X + random:NextNumber(-width / 2 + 8, width / 2 - 8),
					centre.Z + random:NextNumber(-length / 2 + L.EndMargin, length / 2 - L.EndMargin), random:NextNumber(0, math.pi), entry.Shape)
			end
		end
	end
	assert(count <= L.PartBudget, ("Stage %d decor %d exceeds PartBudget %d"):format(n, count, L.PartBudget))
	report[n].decor = count
end
local lines = {}
for n, r in report do lines[n] = ("Stage %d: %d decor parts, %d prop groups moved to backup"):format(n, r.decor, r.moved) end
return table.concat(lines, "\n")
