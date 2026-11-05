--[[
	Remotes: single place that defines RemoteEvents.
	Server creates them; client waits for them.
	Add a name to NAMES to add a new remote (e.g. future client->server requests).
	Note: pickaxe hits do NOT need a remote - Tool.Activated replicates to the server
	(works on mouse, touch and gamepad).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
 "EggReveal", -- cosmetic only; reward is selected on the server
 "SafeReturn",
	"Announcement", -- server -> one/all clients: (text: string)
	"Knockback",    -- server -> hit client: (velocity: Vector3), client applies it locally
}

local folder
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in ipairs(NAMES) do
		if not folder:FindFirstChild(name) then
			local r = Instance.new("RemoteEvent")
			r.Name = name
			r.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes")
end

local Remotes = {}
for _, name in ipairs(NAMES) do
	Remotes[name] = folder:WaitForChild(name)
end

return Remotes
