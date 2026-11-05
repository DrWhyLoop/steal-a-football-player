--[[
	BuildGreybox: Studio-side tool (NOT game code). Rebuilds Workspace/Greybox from Config.
	Run it in EDIT mode (command bar / MCP execute_luau). Layout numbers come from
	ReplicatedStorage/Shared/Config; only builder-local geometry lives here.
	Tags used by the game scripts: StageZone, CubeSpawn, Plot, Slot, LockButton.
]]

local CS = game:GetService("CollectionService")
local WS = game:GetService("Workspace")

local Config
do -- load a fresh copy of Config (require caches within a Studio session)
	local copy = game.ReplicatedStorage.Shared.Config:Clone()
	copy.Parent = game.ReplicatedStorage
	Config = require(copy)
	copy:Destroy()
end

local WIDTH, HALF = Config.HallwayWidth, Config.HallwayWidth / 2
local WALL_H = 30
local PLOT, GAP, ROWS = 34, 6, 3
local SLOT, SLOT_STEP, PER_ROW = 4.5, 6.4, 5
local DARK = Color3.fromRGB(35, 35, 40)
local PLOT_COLORS = {
	Color3.fromRGB(90, 160, 90), Color3.fromRGB(90, 150, 170), Color3.fromRGB(170, 150, 90),
	Color3.fromRGB(160, 100, 140), Color3.fromRGB(130, 130, 200), Color3.fromRGB(190, 110, 90),
}

local old = WS:FindFirstChild("Greybox")
if old then old:Destroy() end
local root = Instance.new("Folder")
root.Name = "Greybox"

local function newFolder(name, parent)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function part(name, size, pos, color, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function addLabel(p, face, text, size, rot, color)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SurfaceGui"
	gui.Face = face
	gui.ClipsDescendants = false
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.Parent = p
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = size
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Text = text
	label.Rotation = rot or 0
	label.Parent = gui
end

local function prompt(parent, name, action, object, maxDistance)
	local p = Instance.new("ProximityPrompt")
	p.Name = name
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = 0
	p.MaxActivationDistance = maxDistance
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

local folders = {}
for _, name in ipairs({ "Hallway", "Plaza", "Plots", "CubeSpawns", "Cubes", "Cards", "Guards" }) do
	folders[name] = newFolder(name, root)
end
local stagesFolder = newFolder("Stages", folders.Hallway)
local wallsFolder = newFolder("Walls", folders.Hallway)

-- Hallway stages along +Z, with cube spawn markers
local z0 = 0
for n = 1, Config.StageCount do
	local len = Config.GetStageLength(n)
	local zc = z0 + len / 2
	local tier = Config.StageTier[n]
	local floor = part("Stage_" .. n, Vector3.new(WIDTH, 1, len), Vector3.new(0, 0.5, zc),
		Config.Tiers[tier].Color:Lerp(Color3.fromRGB(30, 30, 30), 0.5), stagesFolder)
	floor:SetAttribute("Stage", n)
	floor:SetAttribute("Tier", tier)
	CS:AddTag(floor, "StageZone")
	addLabel(floor, Enum.NormalId.Top, "STAGE " .. n, UDim2.fromOffset(56 * 20, 14 * 20), 270)
	part("Divider_" .. n, Vector3.new(WIDTH, 1.05, 0.6), Vector3.new(0, 0.5, z0 + len), DARK, stagesFolder)

	local count = Config.CubeCountPerStage[n]
	local markers = newFolder("Stage_" .. n, folders.CubeSpawns)
	local columns = #Config.CubeColumnX
	local rows = math.ceil(count / columns)
	for i = 1, count do
		local x, zm = 0, zc
		if n ~= Config.GoatStage then
			x = Config.CubeColumnX[(i - 1) % columns + 1]
			zm = z0 + len * (math.ceil(i / columns) - 0.5) / rows
		end
		local marker = part("CubeSpawn_" .. i, Vector3.new(6, 0.2, 6), Vector3.new(x, 1.1, zm), Config.Tiers[tier].Color, markers)
		marker.Material = Enum.Material.Neon
		marker.Transparency = Config.CubeSpawnMarkerTransparency
		marker.CanCollide = false
		marker.CanTouch = false
		marker:SetAttribute("Stage", n)
		CS:AddTag(marker, "CubeSpawn")
	end
	z0 += len
end
local total = z0

-- Walls
local function wall(name, size, pos)
	local w = part(name, size, pos, Color3.fromRGB(70, 70, 80), wallsFolder)
	w.Transparency = 0.3
end
wall("Wall_Left", Vector3.new(2, WALL_H, total), Vector3.new(-HALF - 1, WALL_H / 2, total / 2))
wall("Wall_Right", Vector3.new(2, WALL_H, total), Vector3.new(HALF + 1, WALL_H / 2, total / 2))
wall("Wall_End", Vector3.new(WIDTH + 4, WALL_H, 2), Vector3.new(0, WALL_H / 2, total + 1))
for _, side in ipairs({ 1, -1 }) do
	wall("Entrance_" .. (side == 1 and "Right" or "Left"), Vector3.new(PLOT, WALL_H, 2),
		Vector3.new(side * (HALF + 1 + PLOT / 2), WALL_H / 2, 0))
end

-- Forecourt (same width as hallway) + default spawn
local depth = ROWS * (PLOT + GAP) + GAP
part("PlazaFloor", Vector3.new(WIDTH, 1, depth), Vector3.new(0, 0.5, -depth / 2), Color3.fromRGB(95, 95, 105), folders.Plaza)
local spawn = WS.SpawnLocation
spawn.Size = Vector3.new(12, 0.2, 12)
spawn.Position = Vector3.new(0, 1.1, -depth / 2)
spawn.Neutral = true
spawn.Duration = 0

-- Plots: 2 sides x 3 rows, flush against the forecourt
local H = Config.LockBarrierHeight
local index = 0
for _, side in ipairs({ 1, -1 }) do
	for r = 1, ROWS do
		index += 1
		local cx = side * (HALF + PLOT / 2)
		local cz = -(GAP + PLOT / 2 + (r - 1) * (PLOT + GAP))
		local plot = Instance.new("Model")
		plot.Name = "Plot_" .. index
		plot.PrimaryPart = part("Base", Vector3.new(PLOT, 1, PLOT), Vector3.new(cx, 0.5, cz), PLOT_COLORS[index], plot)
		plot:SetAttribute("PlotIndex", index)
		plot:SetAttribute("OwnerUserId", 0)
		CS:AddTag(plot, "Plot")

		local plotSpawn = Instance.new("SpawnLocation")
		plotSpawn.Name = "PlotSpawn"
		plotSpawn.Size = Vector3.new(6, 0.2, 6)
		plotSpawn.Position = Vector3.new(side * (HALF + 5), 1.1, cz)
		plotSpawn.Anchored = true
		plotSpawn.Neutral = true
		plotSpawn.Duration = 0
		plotSpawn.Transparency = 0.5
		plotSpawn.AllowTeamChangeOnTouch = false
		plotSpawn.Parent = plot

		local sign = part("Sign", Vector3.new(1, 8, 24), Vector3.new(side * (HALF + PLOT - 0.5), 5, cz), DARK, plot)
		addLabel(sign, side == 1 and Enum.NormalId.Left or Enum.NormalId.Right, "Free Plot", UDim2.fromScale(0.9, 0.5))

		-- Slots (owner prompt + steal prompt; the client hides whichever does not apply)
		local slots = newFolder("Slots", plot)
		for s = 1, Config.SlotsPerPlot do
			local row = math.ceil(s / PER_ROW)
			local col = (s - 1) % PER_ROW + 1
			local pos = Vector3.new(side * (HALF + 15 + (row - 1) * 10), 1.2, cz + (col - 3) * SLOT_STEP)
			local slot = part("Slot_" .. s, Vector3.new(SLOT, 0.4, SLOT), pos, Color3.fromRGB(50, 50, 55), slots)
			slot:SetAttribute("SlotIndex", s)
			CS:AddTag(slot, "Slot")
			addLabel(slot, Enum.NormalId.Top, tostring(s), UDim2.fromScale(1, 1), side == 1 and 180 or 0, Color3.fromRGB(200, 200, 200))
			prompt(slot, "SlotPrompt", "Place card", "Slot " .. s, 10)
			prompt(slot, "StealPrompt", "Steal", "Slot " .. s, 10)
		end

		-- Base lock: button, barrier walls (collision toggled at runtime), countdown anchor
		local button = part("LockButton", Vector3.new(3, 1, 3), Vector3.new(side * (HALF + 5), 1.5, cz + 9), Color3.fromRGB(220, 60, 60), plot)
		button.Material = Enum.Material.Neon
		CS:AddTag(button, "LockButton")
		prompt(button, "LockPrompt", "Lock base", "Base lock", 8)

		local barrier = newFolder("Barrier", plot)
		local function barrierWall(name, size, pos)
			local w = part(name, size, pos, Config.LockBarrierColor, barrier)
			w.Material = Enum.Material.Neon
			w.Transparency = 1
			w.CanCollide = false
			w.CanTouch = false
			w.CanQuery = false
			w.CastShadow = false
		end
		local y = 1 + H / 2
		barrierWall("Front", Vector3.new(1, H, PLOT + 1), Vector3.new(side * HALF, y, cz))
		barrierWall("Back", Vector3.new(1, H, PLOT + 1), Vector3.new(side * (HALF + PLOT), y, cz))
		barrierWall("Left", Vector3.new(PLOT + 1, H, 1), Vector3.new(cx, y, cz - PLOT / 2))
		barrierWall("Right", Vector3.new(PLOT + 1, H, 1), Vector3.new(cx, y, cz + PLOT / 2))

		local status = part("LockStatus", Vector3.one, Vector3.new(cx, H + 6, cz), DARK, plot)
		status.Transparency = 1
		status.CanCollide = false
		status.CanQuery = false
		local gui = Instance.new("BillboardGui")
		gui.Name = "StatusGui"
		gui.Size = UDim2.fromOffset(240, 60)
		gui.AlwaysOnTop = true
		gui.Enabled = false
		gui.Parent = status
		local text = Instance.new("TextLabel")
		text.Name = "Label"
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.TextScaled = true
		text.Font = Enum.Font.GothamBlack
		text.TextColor3 = Config.LockBarrierColor
		text.TextStrokeTransparency = 0.2
		text.Parent = gui

		plot.Parent = folders.Plots
	end
end

root.Parent = WS
return ("built: hallway length %d, forecourt depth %d, descendants %d"):format(total, depth, #root:GetDescendants())
