-- Daily and weekly quests that pay Quest Tokens (never sold for Robux, see Config.Quests). Progress is counted only by server code
-- through Track(); the client can only ask for a sync or a claim, and both are validated here.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Shared.Config)
local Remotes=require(RS.Shared.Remotes)
local Data=require(script.Parent.PlayerData)
local cfg=Config.Quests
local Q={}
local incomeOf -- function(player) -> income per second (injected by Main)
local dirty,nextRequest,lastPosition={},{},{}

local function today() return os.time()//86400 end
local function weekOf(day) return (day+3)//7 end -- the Unix epoch was a Thursday, so weeks start on Monday

local function make(kind,scope,player)
	local def=kind[scope]
	local target=def.Target or math.max(cfg.MinCollect,math.ceil(incomeOf(player)*def.IncomeSeconds))
	return {Id=kind.Id,Target=target,Progress=0,Claimed=false}
end

local function generate(player,scope,seed)
	local list={}
	if scope=="Daily" then
		local pool,random=table.clone(cfg.Kinds),Random.new(seed)
		for _=1,cfg.DailyCount do table.insert(list,make(table.remove(pool,random:NextInteger(1,#pool)),scope,player)) end
	else
		for _,kind in cfg.Kinds do table.insert(list,make(kind,scope,player)) end
	end
	return list
end

-- A new UTC day or week replaces the unclaimed quests. Returns true when something was regenerated.
local function ensure(player,data)
	local q,day=data.Quests,today()
	local changed=false
	if q.Day~=day or #q.Daily==0 then q.Day=day q.Victims={} q.Daily=generate(player,"Daily",day) changed=true end
	local week=weekOf(day)
	if q.Week~=week or #q.Weekly==0 then q.Week=week q.Weekly=generate(player,"Weekly",week) changed=true end
	return changed
end

local function send(player)
	local profile=Data.Get(player)
	if not profile then return end
	local d,day=profile.data,today()
	Remotes.QuestSync:FireClient(player,{Tokens=d.QuestTokens,DayLeft=(day+1)*86400-os.time(),WeekLeft=(weekOf(day)*7+4)*86400-os.time(),
		Daily=d.Quests.Daily,Weekly=d.Quests.Weekly})
end

local function ready(player) return Data.Get(player) and player:GetAttribute("DataReady")==true end

--- Count progress for `kind` ("Break", "Place", "Play", "Collect", "Steal"). A Steal needs the victim's user id and counts once per victim per day.
function Q.Track(player,kind,amount,victimId)
	if not ready(player) then return end
	local data=Data.Get(player).data
	ensure(player,data)
	local q=data.Quests
	if kind=="Steal" then
		local key=tostring(victimId)
		local count=0
		for _ in q.Victims do count+=1 end
		if q.Victims[key] or count>=cfg.MaxVictims then return end
		q.Victims[key]=true
	end
	for _,scope in {"Daily","Weekly"} do
		for _,quest in q[scope] do
			if quest.Id==kind and not quest.Claimed then quest.Progress=math.min(quest.Target,quest.Progress+amount) end
		end
	end
	dirty[player]=true
end

--- Add (or with a negative amount spend) tokens. Returns false, changing nothing, if the balance would go below zero.
function Q.AddTokens(player,amount)
	if not ready(player) then return false end
	local data=Data.Get(player).data
	if data.QuestTokens+amount<0 then return false end
	data.QuestTokens=math.min(cfg.MaxTokens,data.QuestTokens+amount)
	player:SetAttribute("QuestTokens",data.QuestTokens)
	return true
end

local function claim(player,scope,index)
	if not ready(player) then return end
	local data=Data.Get(player).data
	if (scope~="Daily" and scope~="Weekly") or type(index)~="number" or index%1~=0 then return end
	ensure(player,data)
	local quest=data.Quests[scope][index]
	if not quest or quest.Claimed or quest.Progress<quest.Target then send(player) return end
	quest.Claimed=true -- the flag and the tokens change together before any yield
	Q.AddTokens(player,cfg.ById[quest.Id][scope].Tokens)
	send(player)
	task.spawn(Data.RequestSave,player)
end

function Q.Init(incomeFunction)
	incomeOf=incomeFunction
	Remotes.QuestRequest.OnServerEvent:Connect(function(player,action,scope,index)
		if (nextRequest[player] or 0)>os.clock() then return end
		nextRequest[player]=os.clock()+cfg.RequestGap
		if action=="Claim" then claim(player,scope,index) elseif action=="Sync" and ready(player) then send(player) end
	end)
	local function added(player)
		player:GetAttributeChangedSignal("DataReady"):Connect(function()
			if not ready(player) then return end
			local data=Data.Get(player).data
			ensure(player,data)
			player:SetAttribute("QuestTokens",data.QuestTokens)
			send(player)
		end)
	end
	Players.PlayerAdded:Connect(added)
	for _,player in Players:GetPlayers() do added(player) end
	Players.PlayerRemoving:Connect(function(player) dirty[player]=nil nextRequest[player]=nil lastPosition[player]=nil end)
	task.spawn(function() -- batch progress updates to the client
		while true do
			task.wait(cfg.SyncSeconds)
			for player in dirty do dirty[player]=nil if player.Parent then send(player) end end
		end
	end)
	task.spawn(function() -- play time and day/week rollover while online
		while true do
			task.wait(cfg.PlayTickSeconds)
			for _,player in Players:GetPlayers() do
				if ready(player) then
					local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					local last=lastPosition[player]
					lastPosition[player]=root and root.Position
					if root and last and (root.Position-last).Magnitude>=cfg.MinMoveStuds or player:GetAttribute("Training") then Q.Track(player,"Play",1) end
					if ensure(player,Data.Get(player).data) then send(player) end
				end
			end
		end
	end)
end

return Q
