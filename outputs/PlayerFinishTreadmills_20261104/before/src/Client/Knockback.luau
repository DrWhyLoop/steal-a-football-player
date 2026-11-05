--[[
	Knockback: the server validates a hit (e.g. a guard touch) and tells this client to apply
	the impulse locally, because the client owns its character's physics. The Humanoid's ground
	controller cancels a plain impulse, so the character is briefly put in PlatformStand.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Knockback = {}

function Knockback.Init()
	Remotes.Knockback.OnClientEvent:Connect(function(velocity: Vector3)
		local char = Players.LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid then return end
		humanoid.PlatformStand = true
		root.AssemblyLinearVelocity = velocity
		task.delay(Config.KnockbackStunSeconds, function()
			humanoid.PlatformStand = false
		end)
	end)
end

return Knockback
