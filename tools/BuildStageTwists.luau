-- Edit-time (run through the Studio MCP execute_luau, Edit mode). Builds the static parts of the stage twists from Config.StageTwists into
-- Workspace.Greybox.Environment.StageTwists.Stage_N: tagged TwistZone discs (Kind, Stage, Radius, Index attributes read by Server/StageTwists),
-- lanterns (TwistLantern), minecart rails and warning markers (TwistMarker) and the container tracks. Repeatable: the folder is rebuilt.
local SS = game:GetService("ServerStorage")
local CS = game:GetService("CollectionService")
local configCopy = game.ReplicatedStorage.Shared.Config:Clone() -- a fresh require, the MCP session caches modules
configCopy.Parent = SS
local Config = require(configCopy)
configCopy:Destroy()
local T = Config.StageTwists
local env = workspace.Greybox.Environment
local root = env:FindFirstChild("StageTwists") or Instance.new("Folder")
root.Name, root.Parent = "StageTwists", env
root:ClearAllChildren()

local report = {}
for stage, cfg in T.Stages do
	local floor = workspace.Greybox.Hallway.Stages["Stage_" .. stage]
	local out = Instance.new("Folder")
	out.Name = "Stage_" .. stage
	local width, length = floor.Size.X, floor.Size.Z
	local top = floor.Position.Y + floor.Size.Y / 2
	local random = Random.new(Config.StageLook.Seed + 100 + stage)
	local function part(name, size, cframe, material, color, tag)
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Material, p.Color = name, size, cframe, material, color
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
		if tag then CS:AddTag(p, tag) end
		p.Parent = out
		return p
	end
	if cfg.Zones then -- discs placed at random without overlapping each other
		local zone, placed = cfg.Zones, {}
		local height = zone.Height or T.ZoneHeight
		for index = 1, zone.Count do
			for _ = 1, 60 do
				local x = floor.Position.X + random:NextNumber(-width / 2 + zone.Radius + 2, width / 2 - zone.Radius - 2)
				local z = floor.Position.Z + random:NextNumber(-length / 2 + T.EndMargin + zone.Radius, length / 2 - T.EndMargin - zone.Radius)
				local free = true
				for _, other in placed do if (other - Vector2.new(x, z)).Magnitude < zone.Radius * 2 + 2 then free = false break end end
				if free then
					table.insert(placed, Vector2.new(x, z))
					local disc = part(cfg.Kind .. index, Vector3.new(height, zone.Radius * 2, zone.Radius * 2),
						CFrame.new(x, top + 0.1 + height / 2, z) * CFrame.Angles(0, 0, math.pi / 2), zone.Material, zone.Color, "TwistZone")
					disc.Shape, disc.Transparency = Enum.PartType.Cylinder, zone.Transparency or 0
					disc:SetAttribute("Kind", cfg.Kind)
					disc:SetAttribute("Stage", stage)
					disc:SetAttribute("Radius", zone.Radius)
					disc:SetAttribute("Index", index)
					break
				end
			end
		end
	elseif cfg.Kind == "Blackout" then -- lanterns along both edges
		for index = 1, cfg.Lanterns do
			local side = index % 2 == 1 and -1 or 1
			local x = floor.Position.X + side * (width / 2 - 3)
			local z = floor.Position.Z - length / 2 + length * math.ceil(index / 2) / (cfg.Lanterns / 2 + 1)
			part("Post" .. index, Vector3.new(1, 9, 1), CFrame.new(x, top + 4.5, z), Enum.Material.Slate, Color3.fromRGB(50,45,45))
			local bulb = part("Bulb" .. index, Vector3.new(2.4, 2.4, 2.4), CFrame.new(x, top + 10, z), Enum.Material.Neon, cfg.LitColor, "TwistLantern")
			bulb.Shape = Enum.PartType.Ball
		end
	elseif cfg.Kind == "Cart" then -- one rail per lane with a warning marker at each end
		for lane = 1, cfg.Lanes do
			local z = floor.Position.Z - length / 2 + length * lane / (cfg.Lanes + 1)
			part("Rail" .. lane, Vector3.new(width, 0.1, 1.4), CFrame.new(floor.Position.X, top + 0.1, z), Enum.Material.Metal, Color3.fromRGB(70,70,76))
			for _, side in {-1, 1} do
				local marker = part("Marker" .. lane .. (side < 0 and "L" or "R"), Vector3.new(2, 4, 2), CFrame.new(floor.Position.X + side * (width / 2 - 2), top + 2, z), Enum.Material.SmoothPlastic, T.IdleMarker, "TwistMarker")
				marker:SetAttribute("Lane", lane)
			end
		end
	elseif cfg.Kind == "Container" then -- one track strip per container lane
		for index = 1, cfg.Count do
			local z = floor.Position.Z - length / 2 + length * index / (cfg.Count + 1)
			part("Track" .. index, Vector3.new(width - 2 * cfg.Edge + cfg.Size.X, 0.1, cfg.Size.Z), CFrame.new(floor.Position.X, top + 0.1, z), Enum.Material.Metal, Color3.fromRGB(190,160,60))
		end
	end
	out.Parent = root
	report[stage] = ("Stage %d %s: %d parts"):format(stage, cfg.Kind, #out:GetChildren())
end
return table.concat(report, "\n")
