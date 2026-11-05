-- Server clock and weather state; no client requests control weather.
local RS=game:GetService("ReplicatedStorage")
local W=require(RS.Shared.Config).Weather
local Weather={}
function Weather.Init()
 local state=Instance.new("Folder") state.Name="WeatherState"
 state:SetAttribute("CycleStart",workspace:GetServerTimeNow()-W.StartHour/24*W.DaySeconds)
 state.Parent=RS
 local dayIndex
 task.spawn(function()
  while state.Parent do
   local elapsed=workspace:GetServerTimeNow()-state:GetAttribute("CycleStart")
   local day=math.floor(elapsed/W.DaySeconds)
   if day~=dayIndex then dayIndex=day state:SetAttribute("RainToday",math.random()<W.RainChance) end
   local hour=(elapsed%W.DaySeconds)/W.DaySeconds*24
   local phase="Sunny"
   if hour>=W.NightHour or hour<W.DayStartHour then phase="Night"
   elseif hour>=W.EveningHour then phase="Evening"
   elseif state:GetAttribute("RainToday") and hour>=W.RainStartHour and hour<W.RainEndHour then phase="Rain" end
   state:SetAttribute("Current",phase)
   task.wait(W.UpdateSeconds)
  end
 end)
end
return Weather
