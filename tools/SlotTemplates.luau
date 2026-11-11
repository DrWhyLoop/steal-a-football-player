-- Edit-time tool (Studio command bar / MCP): builds ServerStorage.SlotTemplates from the three supplied, script-free
-- models in Workspace (slot_pedestal, green_button, green_button_stand), then moves the originals to
-- ServerStorage.SlotSourceAssets. EnvironmentBuilder.BuildDisplaySlots scales the templates to the sizes in Config.PlotSlots.
-- Every template model has no PrimaryPart (so WorldPivot is used), its WorldPivot at the bottom centre and an attribute SourceSize
-- (the dimension the builder normalises).
local SS = game:GetService("ServerStorage")
local GS = game:GetService("GeometryService")

local function bottomTop(part)
	local cf, s = part.CFrame, part.Size
	local ext = (math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z) / 2
	return cf.Position.Y - ext, cf.Position.Y + ext
end

local function stripPhysics(part, canTouch, canQuery)
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow = true, false, canTouch or false, canQuery or false, false
end

local function newModel(name, parts, sourceSize, extra)
	local model = Instance.new("Model")
	model.Name = name
	for _, p in parts do p.Parent = model end
	model.WorldPivot = CFrame.new()
	local cf, size = model:GetBoundingBox() -- union Positions are not their centres, so the pivot comes from the real bounds
	model.WorldPivot = CFrame.new(cf.X, cf.Y - size.Y / 2, cf.Z)
	model:SetAttribute("SourceSize", sourceSize)
	for k, v in extra or {} do model:SetAttribute(k, v) end
	return model
end

local function bounds(parts)
	local lo, hi = math.huge, -math.huge
	for _, p in parts do
		local b, t = bottomTop(p)
		lo, hi = math.min(lo, b), math.max(hi, t)
	end
	return lo, hi
end

local templates = SS:FindFirstChild("SlotTemplates") or Instance.new("Folder")
templates.Name, templates.Parent = "SlotTemplates", SS
templates:ClearAllChildren()

-- Pedestal: 96 slate pieces -> two unions (light and dark slate). TopHeight = standing surface above the bottom.
do
	local light, dark, all = {}, {}, {}
	local standTop = -math.huge
	for _, p in workspace.slot_pedestal.StatueBase:GetDescendants() do
		if p:IsA("BasePart") then
			local isLight = math.abs(p.Size.Y - 1.2) < 0.01
			table.insert(isLight and light or dark, p)
			table.insert(all, p)
			if isLight and math.abs(p.Size.Z - 5.65) < 0.01 then standTop = math.max(standTop, select(2, bottomTop(p))) end
		end
	end
	local lo = bounds(all)
	local extents = workspace.slot_pedestal.StatueBase:GetExtentsSize()
	local unions = {}
	for name, group in {Light = light, Dark = dark} do
		local first = table.remove(group, 1)
		local u = GS:UnionAsync(first, group, {CollisionFidelity = Enum.CollisionFidelity.Box, RenderFidelity = Enum.RenderFidelity.Automatic, SplitApart = false})[1]
		u.Name, u.UsePartColor, u.Material, u.Color = name, true, Enum.Material.Slate, first.Color
		u.Orientation = Vector3.zero -- the 24-sided base repeats every 15 degrees, so this keeps its look
		stripPhysics(u)
		table.insert(unions, u)
	end
	newModel("Pedestal", unions, math.max(extents.X, extents.Z), {TopHeight = standTop - lo}).Parent = templates
end

-- Collect pad: plate, glowing light and an invisible trigger volume (the only touchable part).
do
	local src = workspace.green_button
	local parts = {src.Plate:Clone(), src.Light:Clone(), src.Hitbox:Clone()}
	parts[3].Name, parts[3].Transparency = "Hitbox", 1
	stripPhysics(parts[1]) stripPhysics(parts[2]) stripPhysics(parts[3], true)
	newModel("CollectPad", parts, math.max(src.Hitbox.Size.X, src.Hitbox.Size.Z)).Parent = templates
end

-- Upgrade stand: the four main pieces (the four thin trim bars are dropped); the button is recoloured yellow by the builder.
do
	local src = workspace.green_button_stand
	local parts = {}
	for _, name in {"button", "ButtonHolder", "handle", "holder"} do
		local p = src:FindFirstChild(name, true):Clone()
		stripPhysics(p, false, true)
		p:ClearAllChildren()
		table.insert(parts, p)
	end
	local lo, hi = bounds(parts)
	newModel("UpgradeStand", parts, hi - lo).Parent = templates
end

local sources = SS:FindFirstChild("SlotSourceAssets") or Instance.new("Folder")
sources.Name, sources.Parent = "SlotSourceAssets", SS
for _, name in {"slot_pedestal", "green_button", "green_button_stand"} do
	local m = workspace:FindFirstChild(name)
	if m then m.Parent = sources end
end
