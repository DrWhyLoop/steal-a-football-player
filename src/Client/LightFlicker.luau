-- Flickers the decorative lights tagged Config.LightFlicker.Tag (range jitter) and blinks the bulbs tagged Config.LightBlink.Tag (replaces the
-- imported flicker scripts). Streamed-in lights are picked up through the tag signals; everything is set on the client only.
local CollectionService = game:GetService("CollectionService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local F = Config.LightFlicker
local B = Config.LightBlink
local LightFlicker = {}

local function blink(bulb)
 local light = bulb:FindFirstChildOfClass("PointLight")
 if not light then return end
 local brightness = light.Brightness
 local function set(on) light.Brightness = on and brightness or 0 bulb.Transparency = on and 0 or 1 end
 while bulb:IsDescendantOf(workspace) do
  set(false) task.wait(B.Off1) set(true) task.wait(B.On) set(false) task.wait(B.Off2) set(true)
  task.wait(math.random(0, B.MaxPause))
 end
 set(true)
end
function LightFlicker.Init()
 CollectionService:GetInstanceAddedSignal(B.Tag):Connect(function(bulb) task.spawn(blink, bulb) end)
 for _, bulb in CollectionService:GetTagged(B.Tag) do task.spawn(blink, bulb) end
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
