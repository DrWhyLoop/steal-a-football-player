-- Cosmetic animal motion, computed on each client from the server time: nothing replicates and the server does no work. Only animals
-- within Config.World.AnimalMotion.Distance of the player move. They walk a slow circle around their home facing their walking
-- direction and bob slightly; animals with Radius 0 (the shore reptiles) only bob.
local CS=game:GetService("CollectionService")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Config=require(game.ReplicatedStorage.Shared.Config)
local M=Config.World.AnimalMotion
local Motion={}
function Motion.Init()
 local active,start={},{} -- start[model] = {Y, rotation} captured the first time an animal comes near
 task.spawn(function()
  while true do
   task.wait(M.CheckSeconds)
   local root=Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
   table.clear(active)
   if root then
    local here=Vector2.new(root.Position.X,root.Position.Z)
    for _,model in CS:GetTagged("WorldAnimal") do
     local x,z=model:GetAttribute("HomeX"),model:GetAttribute("HomeZ")
     if x and (Vector2.new(x,z)-here).Magnitude<=M.Distance then
      active[model]=true
      if not start[model] then local pivot=model:GetPivot() start[model]={Y=pivot.Position.Y,Rotation=pivot-pivot.Position} end
     end
    end
   end
  end
 end)
 RunService.Heartbeat:Connect(function()
  local t=workspace:GetServerTimeNow()
  for model in active do
   local origin=start[model]
   local x,z,phase=model:GetAttribute("HomeX"),model:GetAttribute("HomeZ"),model:GetAttribute("Phase")
   local radius,speed=model:GetAttribute("Radius"),model:GetAttribute("Speed")
   local y=origin.Y+math.sin(t*M.BobSpeed+phase)*M.BobHeight
   if radius>0 then
    local angle=phase+t*speed/radius
    local position=Vector3.new(x+radius*math.cos(angle),y,z+radius*math.sin(angle))
    model:PivotTo(CFrame.lookAt(position,position+Vector3.new(-math.sin(angle),0,math.cos(angle)))*CFrame.Angles(0,model:GetAttribute("ForwardYaw"),0))
   else
    model:PivotTo(CFrame.new(x,y,z)*origin.Rotation)
   end
  end
 end)
end
return Motion
