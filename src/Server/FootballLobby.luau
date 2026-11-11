local Players = game:GetService("Players")
local Collection = game:GetService("CollectionService")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config).FootballLobby
local Remotes = require(Shared.Remotes)
local Lobby = {}

function Lobby.Init(plots, slots)
 local pitch = Collection:GetTagged("CourtPitch")[1]
 if not pitch then return end
 local entry = Instance.new("Part")
 entry.Name = "FootballLobbyEntrance"
 entry.Size = Vector3.one
 entry.Anchored = true
 entry.Transparency = 1
 entry.CanCollide = false
 entry.CanTouch = false
 entry.CanQuery = false
 local plaza = workspace.Greybox.Plaza.PlazaFloor
 local side = pitch.CFrame:PointToObjectSpace(plaza.Position).Z < 0 and -1 or 1
 entry.CFrame = pitch.CFrame*CFrame.new(0,pitch.Size.Y/2,pitch.Size.Z/2*side)
 entry.Parent = workspace
 local prompt = Instance.new("ProximityPrompt")
 prompt.ActionText = "Open lobby"
 prompt.ObjectText = "Football Court"
 prompt.MaxActivationDistance = Config.EntryRange
 prompt.RequiresLineOfSight = false
 prompt.Parent = entry

 local sessions, requests = {}, {}
 local staged
 local function send(player, page, data)
  if player.Parent == Players then Remotes.FootballLobby:FireClient(player,page,data) end
 end
 local function near(player)
  local char = player.Character
  local root = char and char:FindFirstChild("HumanoidRootPart")
  local humanoid = char and char:FindFirstChildOfClass("Humanoid")
  return player:GetAttribute("DataReady") == true and root and humanoid and humanoid.Health>0
   and (root.Position-entry.Position).Magnitude<=Config.LobbyRange
 end
 local function cards(player)
  local plot = plots.GetPlot(player)
  return plot and slots.GetFootballCards(plot) or {}
 end
 local function count(items)
  local total = 0
  for _ in items do total += 1 end
  return total
 end
 local function close(session, message)
  if staged == session then staged = nil end
  if session.folder then session.folder:Destroy() end
  for _,card in session.reserved or {} do
   if card.Parent then card:SetAttribute("FootballReserved",nil) end
  end
  for _,player in session.players do
   if sessions[player] == session then sessions[player] = nil send(player,"Closed",message) end
  end
 end
 local function timeout(session, phase, seconds)
  task.delay(seconds,function()
   if sessions[session.players[1]]==session and session.phase==phase then close(session,"Football lobby timed out.") end
  end)
 end
 local function open(player)
  if not near(player) or sessions[player] then return end
  local opponents = {}
  for _,other in Players:GetPlayers() do
   if other~=player and near(other) and not sessions[other] then
    table.insert(opponents,{id=other.UserId,name=other.DisplayName,count=count(cards(other))})
   end
  end
  send(player,"Open",{opponents=opponents,count=count(cards(player))})
 end
 local function roster(player)
  local list = {}
  for id,card in cards(player) do table.insert(list,{id=id,name=card:GetAttribute("CardName"),tier=card:GetAttribute("Tier")}) end
  table.sort(list,function(a,b) return a.name==b.name and a.id<b.id or a.name<b.name end)
  return list
 end
 local function validate(player, selection, mode)
  if not near(player) or type(selection)~="table" or type(selection.starters)~="table"
   or #selection.starters~=mode.Starters or type(selection.stake)~="string" then return end
  local owned = cards(player)
  if count(owned)<mode.Starters+1 or not owned[selection.stake] then return end
  local found, team = {[selection.stake]=true}, {}
  for i=1,mode.Starters do
   local id = selection.starters[i]
   if type(id)~="string" or found[id] or not owned[id] then return end
   found[id] = true
   team[i] = owned[id]
  end
  return team,owned[selection.stake]
 end
 local function stage(session)
  if staged then close(session,"The court is busy. Try again shortly.") return end
  local mode = Config.Modes[session.mode]
  local teams, reserved = {}, {}
  for i,player in session.players do
   local team,stake = validate(player,session.selections[player],mode)
   if not team then close(session,"A lineup changed or a player left the entrance.") return end
   teams[i] = team
   table.insert(reserved,stake)
   for _,card in team do
    local visual = card:FindFirstChild("PlayerVisual")
    if not visual or not visual.PrimaryPart then close(session,"A lineup model is unavailable.") return end
    table.insert(reserved,card)
   end
  end
  local folder = Instance.new("Folder")
  folder.Name = "FootballLineups"
  session.folder,session.reserved,session.phase = folder,reserved,"Staged"
  staged = session
  for _,card in reserved do card:SetAttribute("FootballReserved",true) end
  local center = pitch.Position+Vector3.yAxis*pitch.Size.Y/2
  local length, width = pitch.CFrame.RightVector,pitch.CFrame.LookVector
  for teamIndex,team in teams do
   local sign = teamIndex==1 and -1 or 1
   local index = 0
   for row,playersInRow in mode.Rows do
    local depth = Config.TeamDepth*(#mode.Rows-row+1)/#mode.Rows
    for column=1,playersInRow do
     index += 1
     local source = team[index].PlayerVisual
     local visual = source:Clone()
     for _,item in visual:GetDescendants() do
      if item:IsA("LuaSourceContainer") or item:IsA("WeldConstraint") then item:Destroy()
      elseif item:IsA("BasePart") then item.Anchored=true item.CanCollide=false item.CanTouch=false item.CanQuery=false end
     end
     for _,tag in visual:GetTags() do visual:RemoveTag(tag) end
     visual.Name = team[index]:GetAttribute("CardName")
     visual:SetAttribute("Team",teamIndex)
     local across = ((column-.5)/playersInRow-.5)*pitch.Size.Z*Config.TeamWidth
     local point = center+length*(pitch.Size.X*depth*sign)+width*across+Vector3.yAxis*visual.PrimaryPart.Size.Y/2
     visual:PivotTo(CFrame.lookAt(point,point-length*sign))
     visual.Parent = folder
    end
   end
  end
  folder.Parent = workspace
  for _,player in session.players do send(player,"Staged",session.mode) end
  timeout(session,"Staged",Config.StagingSeconds)
 end

 prompt.Triggered:Connect(open)
 Remotes.FootballRequest.OnServerEvent:Connect(function(player, action, value, modeId)
  if (requests[player] or 0)>os.clock() then return end
  requests[player] = os.clock()+Config.RequestGap
  local session = sessions[player]
  if action=="Cancel" and session then close(session,"Football lobby closed.") return end
  if not near(player) then return end
  if action=="Open" then open(player)
  elseif action=="Invite" and not session and type(value)=="number" and value%1==0 and math.abs(value)<=2^53 and type(modeId)=="string" then
   local mode = Config.Modes[modeId]
   local opponent = Players:GetPlayerByUserId(value)
   if not mode or not opponent or opponent==player or sessions[opponent] or not near(opponent) then
    send(player,"Notice","Choose an available opponent at the court.") return
   end
   if count(cards(player))<mode.Starters+1 or count(cards(opponent))<mode.Starters+1 then
    send(player,"Notice",("Both plots need %d placed players."):format(mode.Starters+1)) return
   end
   session = {players={player,opponent},mode=modeId,phase="Invited",selections={}}
   sessions[player],sessions[opponent] = session,session
   send(player,"Waiting","Challenge sent to "..opponent.DisplayName..".")
   send(opponent,"Invite",{name=player.DisplayName,mode=modeId})
   timeout(session,"Invited",Config.InviteSeconds)
  elseif action=="Accept" and session and session.phase=="Invited" and player==session.players[2] then
   local mode = Config.Modes[session.mode]
   for _,member in session.players do
    if not near(member) or count(cards(member))<mode.Starters+1 then close(session,"Both players must be eligible at the entrance.") return end
   end
   session.phase = "Selecting"
   for _,member in session.players do send(member,"Select",{mode=session.mode,roster=roster(member)}) end
   timeout(session,"Selecting",Config.SelectionSeconds)
  elseif action=="Ready" and session and session.phase=="Selecting" then
   if not validate(player,value,Config.Modes[session.mode]) then send(player,"Notice","Select the required starters and one different stake.") return end
   session.selections[player] = value
   send(player,"Waiting","Lineup confirmed. Waiting for your opponent.")
   if session.selections[session.players[1]] and session.selections[session.players[2]] then stage(session) end
  end
 end)
 Players.PlayerRemoving:Connect(function(player)
  if sessions[player] then close(sessions[player],"Your opponent left the server.") end
  requests[player] = nil
 end)
end

return Lobby
