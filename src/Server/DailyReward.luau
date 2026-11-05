-- Free daily reward. Days are UTC day numbers computed on the server. Claiming yesterday continues the streak; missing a day only
-- resets it. No timers, no popups: the client just shows the state and a Claim button.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Shared.Config)
local Remotes=require(RS.Shared.Remotes)
local PlayerData=require(script.Parent.PlayerData)
local CashService=require(script.Parent.CashService)
local cfg=Config.Daily
local D={Clock=os.time} -- replaceable in tests
local cooldown={}
local lastReady={}

local function state(data)
 local today=D.Clock()//86400
 local daily=data.Daily
 local ready=daily.LastDay~=today
 local alive=daily.LastDay==today or daily.LastDay==today-1 -- streak not broken
 local nextStreak=ready and (alive and daily.Streak+1 or 1) or daily.Streak
 return {Ready=ready,Streak=alive and daily.Streak or 0,NextStreak=nextStreak,Today=today,
  Reward=ready and cfg.BaseCash+cfg.StepCash*(math.min(nextStreak,cfg.CapDays)-1) or 0}
end

function D.Send(player)
 local profile=PlayerData.Get(player)
 if not profile or player:GetAttribute("DataReady")~=true then return end
 local s=state(profile.data)
 lastReady[player]=s.Ready
 Remotes.DailyStatus:FireClient(player,{Ready=s.Ready,Streak=s.Streak,Reward=s.Reward})
end

function D.Claim(player)
 local profile=PlayerData.Get(player)
 if not profile or player:GetAttribute("DataReady")~=true or (cooldown[player] or 0)>os.clock() then return end
 cooldown[player]=os.clock()+cfg.ClaimCooldownSeconds
 local s=state(profile.data)
 if s.Ready then -- the day record and the cash change together before any yield
  profile.data.Daily={LastDay=s.Today,Streak=s.NextStreak}
  CashService.AddCash(player,s.Reward)
  task.spawn(PlayerData.RequestSave,player)
 end
 D.Send(player)
end

function D.Init()
 Remotes.DailyClaim.OnServerEvent:Connect(D.Claim)
 Remotes.IndexRequest.OnServerEvent:Connect(D.Send)
 local function added(player)
  player:GetAttributeChangedSignal("DataReady"):Connect(function() D.Send(player) end)
 end
 Players.PlayerAdded:Connect(added)
 Players.PlayerRemoving:Connect(function(player) cooldown[player]=nil lastReady[player]=nil end)
 for _,player in Players:GetPlayers() do added(player) end
 task.spawn(function() -- a new UTC day can start while a player is online
  while true do
   task.wait(cfg.RefreshSeconds)
   for _,player in Players:GetPlayers() do
    local profile=PlayerData.Get(player)
    if profile and state(profile.data).Ready~=lastReady[player] then D.Send(player) end
   end
  end
 end)
end
return D
