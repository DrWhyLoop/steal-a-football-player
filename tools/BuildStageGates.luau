-- Edit-time (run through the Studio MCP execute_luau, Edit mode). Builds an open arch at every stage entrance: two pillars and a sign plate above the lanes
-- (clear of the walls, so the next stage stays visible below it) with the stage name, difficulty and recommended Speed, readable from far away.
-- Rebuilds Workspace.Greybox.Environment.<Config.StageGate.FolderName>; run it again after changing Config.StageInfo names or Points.
local SS = game:GetService("ServerStorage")
local configCopy = game.ReplicatedStorage.Shared.Config:Clone() -- a fresh require, the MCP session caches modules
configCopy.Parent = SS
local Config = require(configCopy)
configCopy:Destroy()
local Format = require(game.ReplicatedStorage.Shared.NumberFormat)
local G = Config.StageGate
local env = workspace.Greybox.Environment
local root = env:FindFirstChild(G.FolderName) or Instance.new("Folder")
root.Name, root.Parent = G.FolderName, env
root:ClearAllChildren()

local function label(parent, text, size, position, color, rich)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency, l.Size, l.Position, l.Text = 1, size, position, text
	l.TextScaled, l.Font, l.TextColor3, l.RichText, l.Parent = true, Enum.Font.FredokaOne, color, rich or false, parent
	return l
end
for n = 1, Config.StageCount do
	local floor, info = workspace.Greybox.Hallway.Stages["Stage_" .. n], Config.StageInfo[n]
	local gate = Instance.new("Model")
	gate.Name = "Gate_" .. n
	local top = floor.Position.Y + floor.Size.Y / 2
	local z = floor.Position.Z - floor.Size.Z / 2 + G.Offset
	local function part(name, size, position, color)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Position, p.Color, p.Material = name, size, position, color, Enum.Material.SmoothPlastic
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
		p.Parent = gate
		return p
	end
	local plateWidth = floor.Size.X - 2 * G.Inset
	local height = G.PillarHeight + G.PlateHeight
	for _, side in {-1, 1} do
		part("Pillar" .. side, Vector3.new(G.PillarWidth, height, G.PillarWidth), Vector3.new(floor.Position.X + side * (plateWidth / 2 - G.PillarWidth / 2), top + height / 2, z), G.PillarColor)
	end
	local plate = part("Plate", Vector3.new(plateWidth - 2 * G.PillarWidth, G.PlateHeight, G.PlateThickness), Vector3.new(floor.Position.X, top + G.PillarHeight + G.PlateHeight / 2, z), G.PlateColor)
	for _, face in {Enum.NormalId.Front, Enum.NormalId.Back} do -- Front faces the players walking up from the base
		local gui = Instance.new("SurfaceGui")
		gui.Name, gui.Face, gui.SizingMode, gui.CanvasSize, gui.LightInfluence, gui.Parent = "Sign", face, Enum.SurfaceGuiSizingMode.FixedSize, G.Canvas, 0, plate
		label(gui, info.Name, UDim2.fromScale(0.96, 0.46), UDim2.fromScale(0.02, 0.02), Config.UITheme.Accent)
		label(gui, ('STAGE %d  -  <font color="#%s">%s</font>'):format(n, Config.DifficultyColor[info.Difficulty]:ToHex(), info.Difficulty:upper()), UDim2.fromScale(0.96, 0.24), UDim2.fromScale(0.02, 0.48), Color3.new(1, 1, 1), true)
		label(gui, Format.Recommended(info.Points), UDim2.fromScale(0.96, 0.26), UDim2.fromScale(0.02, 0.72), Color3.fromRGB(190, 215, 235))
	end
	gate.Parent = root
end
return #root:GetChildren() .. " gates"
