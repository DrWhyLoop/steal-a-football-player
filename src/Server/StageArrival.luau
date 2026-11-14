-- First arrival in a stage: once per account (profile.StagesReached, a bit per stage, never reset by a rebirth) the player gets Config.StageArrival.Seconds
-- of the stage tier income and a banner. The bit is set before the cash is paid.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local Remotes = require(RS.Shared.Remotes)
local StageZone = require(RS.Shared.StageZone)
local Data = require(script.Parent.PlayerData)
local CashService = require(script.Parent.CashService)
local A = Config.StageArrival
local Arrival = {}

function Arrival.Init()
	task.spawn(function()
		while true do
			task.wait(A.CheckSeconds)
			for _, player in Players:GetPlayers() do
				local profile = player:GetAttribute("DataReady") == true and Data.Get(player)
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local stage = profile and root and humanoid and humanoid.Health > 0 and StageZone.At(root.Position)
				local bit = stage and bit32.lshift(1, stage - 1)
				if bit and not bit32.btest(profile.data.StagesReached, bit) then
					profile.data.StagesReached = bit32.bor(profile.data.StagesReached, bit)
					local cash = Config.Tiers[Config.StageTier[stage]].CashPerSecond * A.Seconds
					CashService.AddCash(player, cash)
					Remotes.StageArrival:FireClient(player, stage, cash)
					task.spawn(Data.RequestSave, player)
				end
			end
		end
	end)
end

return Arrival
