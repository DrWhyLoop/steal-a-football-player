local CollectionService = game:GetService("CollectionService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local FootballBall = {}

function FootballBall.Init()
 local ball = CollectionService:GetTagged("CourtFootball")[1]
 local pitch = CollectionService:GetTagged("CourtPitch")[1]
 if not ball or not pitch then return end
 local tuning = Config.Football
 local home = ball.CFrame
 ball:SetNetworkOwner(nil)

 local prompt = Instance.new("ProximityPrompt")
 prompt.Name = "KickPrompt"
 prompt.ActionText = "Kick"
 prompt.ObjectText = "Football"
 prompt.MaxActivationDistance = tuning.KickRange
 prompt.Parent = ball

 local nextKick = 0
 prompt.Triggered:Connect(function(player)
  local character = player.Character
  local root = character and character:FindFirstChild("HumanoidRootPart")
  local humanoid = character and character:FindFirstChildOfClass("Humanoid")
  if not root or not humanoid or humanoid.Health <= 0 or os.clock() < nextKick then return end
  if (root.Position-ball.Position).Magnitude > tuning.KickRange then return end
  local ray = RaycastParams.new()
  ray.FilterDescendantsInstances = {character,ball}
  ray.RespectCanCollide = true
  if workspace:Raycast(root.Position,ball.Position-root.Position,ray) then return end

  local offset = (ball.Position-root.Position)*Vector3.new(1,0,1)
  if offset.Magnitude == 0 then return end
  nextKick = os.clock()+tuning.KickCooldown
  local velocity = offset.Unit*tuning.KickSpeed+Vector3.yAxis*tuning.KickLift
  ball:ApplyImpulse((velocity-ball.AssemblyLinearVelocity)*ball.AssemblyMass)
 end)

 task.spawn(function()
  while ball.Parent do
   task.wait(tuning.ResetInterval)
   local localPosition = pitch.CFrame:PointToObjectSpace(ball.Position)
   if math.abs(localPosition.X)>pitch.Size.X/2+tuning.ResetMargin
    or math.abs(localPosition.Z)>pitch.Size.Z/2+tuning.ResetMargin
    or localPosition.Y < -tuning.ResetBelow then
    ball.CFrame = home
    ball.AssemblyLinearVelocity = Vector3.zero
    ball.AssemblyAngularVelocity = Vector3.zero
   end
  end
 end)
end

return FootballBall
