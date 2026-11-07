-- Flickers the decorative lights tagged Config.LightFlicker.Tag (replaces the imported flicker scripts). Streamed-in lights are picked up
-- through the tag signal; the range is set on the client only.
local CollectionService = game:GetService("CollectionService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local F = Config.LightFlicker
local LightFlicker = {}
function LightFlicker.Init()
 local lights = {}
 CollectionService:GetInstanceAddedSignal(F.Tag):Connect(function(light) lights[light] = true end)
 CollectionService:GetInstanceRemovedSignal(F.Tag):Connect(function(light) lights[light] = nil end)
 for _, light in CollectionService:GetTagged(F.Tag) do lights[light] = true end
 task.spawn(function()
  while true do
   task.wait(F.Step)
   for light in lights do light.Range = math.random(F.Min, F.Max) end
  end
 end)
end
return LightFlicker
