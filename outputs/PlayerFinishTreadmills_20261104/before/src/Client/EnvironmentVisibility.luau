-- Local vegetation fading keeps distant decorative mesh overdraw bounded.
local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.Config)
local Visibility = {}

function Visibility.Init()
	task.spawn(function()
		local greybox = workspace:WaitForChild("Greybox")
		local environment = greybox:WaitForChild("Environment", 10)
		if not environment then return end
		local groups = {}
		for _, group in environment.Stages:GetChildren() do
			local floor = greybox.Hallway.Stages:FindFirstChild(group.Name)
			if floor then
				local parts = {}
				for _, part in group:GetDescendants() do
					if part:IsA("BasePart") and not part.Name:find("StageSign_", 1, true) then table.insert(parts, part) end
				end
				table.insert(groups, {Floor = floor, Parts = parts, Alpha = -1})
			end
		end
		while environment.Parent do
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			for _, group in groups do
				local alpha = 1
				if root then
					local offset = root.Position - group.Floor.Position
					local dx = math.max(math.abs(offset.X) - group.Floor.Size.X / 2, 0)
					local dz = math.max(math.abs(offset.Z) - group.Floor.Size.Z / 2, 0)
					local distance = math.sqrt(dx * dx + dz * dz)
					local fadeStart = Config.Environment.VegetationViewDistance - Config.Environment.VegetationFadeDistance
					alpha = math.clamp((distance - fadeStart) / Config.Environment.VegetationFadeDistance, 0, 1)
				end
				alpha = math.floor(alpha * 4 + 0.5) / 4
				if alpha ~= group.Alpha then
					for _, part in group.Parts do part.LocalTransparencyModifier = alpha end
					group.Alpha = alpha
				end
			end
			task.wait(Config.Environment.VisibilityUpdateSeconds)
		end
	end)
end

return Visibility
