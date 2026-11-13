-- Edit-time (run through the Studio MCP execute_luau, Edit mode). Places the templates in ServerStorage.StageProps.Stage1..Stage12 along both edges of
-- their stage (Config.StageProps): inside the edge band only, never in the first/last EndClear studs, never near a cage spawn marker, never overlapping
-- another prop, and stopping at PartBudget Parts. Props are anchored and non-colliding. Scripts, GUIs and prompts inside templates are stripped.
-- Set STAGES to the stages to (re)place; their previous props are removed first. Props land in Workspace.Greybox.Environment.<FolderName>.Stage_N.
local STAGES = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}
local SS = game:GetService("ServerStorage")
local configCopy = game.ReplicatedStorage.Shared.Config:Clone() -- a fresh require, the MCP session caches modules
configCopy.Parent = SS
local Config = require(configCopy)
configCopy:Destroy()
local P = Config.StageProps
local env = workspace.Greybox.Environment
local root = env:FindFirstChild(P.FolderName) or Instance.new("Folder")
root.Name, root.Parent = P.FolderName, env
local markers = {}
for _, marker in workspace.Greybox.CubeSpawns:GetDescendants() do
	if marker:IsA("BasePart") then table.insert(markers, marker.Position) end
end

local function partCount(item)
	local n = item:IsA("BasePart") and 1 or 0
	for _, d in item:GetDescendants() do if d:IsA("BasePart") then n += 1 end end
	return n
end
local function strip(item)
	local removed = 0
	for _, d in item:GetDescendants() do
		if d:IsA("LuaSourceContainer") or d:IsA("LayerCollector") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") or d:IsA("RemoteEvent") then
			d:Destroy() removed += 1
		elseif d:IsA("BasePart") then
			d.Anchored, d.CanCollide, d.CanTouch, d.CanQuery = true, false, false, false
		end
	end
	if item:IsA("BasePart") then item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery = true, false, false, false end
	return removed
end
local function bounds(item)
	if item:IsA("Model") then return item:GetBoundingBox() end
	return item.CFrame, item.Size
end

local report = {}
for _, n in STAGES do
	local old = root:FindFirstChild("Stage_" .. n)
	if old then old:Destroy() end
	local templates = SS.StageProps["Stage" .. n]:GetChildren()
	local floor = workspace.Greybox.Hallway.Stages["Stage_" .. n]
	local random = Random.new(P.Seed + n)
	local out = Instance.new("Folder")
	out.Name = "Stage_" .. n
	local width, length, top = floor.Size.X, floor.Size.Z, floor.Position.Y + floor.Size.Y / 2
	local z0 = floor.Position.Z - length / 2
	local placed, parts, skipped, removed, tries = {}, 0, 0, 0, 0
	while #templates > 0 and tries < #templates * P.Attempts do
		tries += 1
		local template = templates[(tries - 1) % #templates + 1]
		local cost = partCount(template)
		if parts + cost > P.PartBudget then break end
		local _, size = bounds(template)
		local radius = math.max(size.X, size.Z) / 2
		if radius > P.BandInner - P.BandOuter then -- the footprint must fit between the lane edge and the wall
			skipped += 1
		else
			for _ = 1, P.Attempts do
				local side = random:NextInteger(0, 1) == 0 and -1 or 1
				local x = floor.Position.X + side * random:NextNumber(width / 2 - P.BandInner + radius, width / 2 - P.BandOuter)
				local z = random:NextNumber(z0 + P.EndClear + radius, z0 + length - P.EndClear - radius)
				local free = true
				for _, m in markers do
					if (Vector2.new(m.X, m.Z) - Vector2.new(x, z)).Magnitude < P.SpawnClear + radius then free = false break end
				end
				for _, other in placed do
					if free and (other.Position - Vector2.new(x, z)).Magnitude < other.Radius + radius + P.MinGap then free = false end
				end
				if free then
					local clone = template:Clone()
					removed += strip(clone)
					clone.Parent = out
					clone:PivotTo(CFrame.new(x, top, z) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0))
					local c, s2 = bounds(clone)
					clone:PivotTo(clone:GetPivot() + Vector3.new(0, top - (c.Position.Y - s2.Y / 2), 0)) -- stand on the floor
					table.insert(placed, {Position = Vector2.new(x, z), Radius = radius})
					parts += cost
					break
				end
			end
		end
	end
	out.Parent = root
	report[#report + 1] = ("Stage %d: %d props, %d/%d parts, %d too wide, %d script-like objects stripped"):format(n, #placed, parts, P.PartBudget, skipped, removed)
end
return table.concat(report, "\n")
