-- Server obstruction checks shared by mining, combat and stealing.
local Workspace = game:GetService("Workspace")

local LineOfSight = {}

function LineOfSight.IsClear(character: Model, target: Instance, position: Vector3): boolean
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return false end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, target }
	-- Ignore cosmetic parts and inactive barriers; solid walls and active barriers block.
	params.RespectCanCollide = true
	return Workspace:Raycast(root.Position, position - root.Position, params) == nil
end

return LineOfSight
