-- Which stage a position is in (the stage floors carry the StageZone tag and a Stage attribute). Shared by the banner and the mood.
local CS = game:GetService("CollectionService")
local Zone = {}
function Zone.At(position)
	for _, floor in CS:GetTagged("StageZone") do
		local p = floor.CFrame:PointToObjectSpace(position)
		if math.abs(p.X) <= floor.Size.X / 2 and math.abs(p.Z) <= floor.Size.Z / 2 then return floor:GetAttribute("Stage") end
	end
end
return Zone
