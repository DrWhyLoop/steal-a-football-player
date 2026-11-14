-- Which stage a position is in (the stage floors carry the StageZone tag and a Stage attribute). Returns the stage number and its floor part.
-- Shared by the server (twists, first arrival) and the client (banner, mood, twist drawing).
local CS = game:GetService("CollectionService")
local Zone = {}
function Zone.At(position)
	for _, floor in CS:GetTagged("StageZone") do
		local p = floor.CFrame:PointToObjectSpace(position)
		if math.abs(p.X) <= floor.Size.X / 2 and math.abs(p.Z) <= floor.Size.Z / 2 then return floor:GetAttribute("Stage"), floor end
	end
end
return Zone
