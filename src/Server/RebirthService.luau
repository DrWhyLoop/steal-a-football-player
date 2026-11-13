-- Rebirth: resets Speed Points only (everything else is kept) and raises the permanent income and Speed gain multipliers.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Shared.Config)
local Remotes=require(RS.Shared.Remotes)
local Rebirth=require(RS.Shared.Rebirth)
local Data=require(script.Parent.PlayerData)
local Stats=require(script.Parent.PlayerStats)
local S={}
local nextRequest={}

local function request(player)
	local profile=Data.Get(player)
	if not profile or player:GetAttribute("DataReady")~=true or (nextRequest[player] or 0)>os.clock() then return end
	nextRequest[player]=os.clock()+Config.Rebirth.RequestGap
	local data=profile.data
	if not Rebirth.Ready(Stats.Get(player,"Speed"),data.Rebirths) then
		Remotes.RebirthStatus:FireClient(player,"Fill the rebirth bar first.")
		return
	end
	-- the reset and the new count change together before any yield
	data.Rebirths+=1
	player:SetAttribute("Rebirths",data.Rebirths)
	Stats.Set(player,"Speed",0)
	Remotes.RebirthStatus:FireClient(player,("Rebirth %d complete!"):format(data.Rebirths))
	task.spawn(Data.RequestSave,player)
end

function S.Init()
	Remotes.RebirthRequest.OnServerEvent:Connect(request)
	Players.PlayerRemoving:Connect(function(player) nextRequest[player]=nil end)
end

return S
