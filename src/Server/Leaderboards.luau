local Players = game:GetService("Players")
local DSS = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local Format = require(game.ReplicatedStorage.Shared.NumberFormat)
local Data = require(script.Parent.PlayerData)
local Stats = require(script.Parent.PlayerStats)
local L = Config.Leaderboards
local Boards = {}

local definitions = {
 {Key="Cash", Title="Most Cash", Stat="Cash", Prefix="$"},
 {Key="Time", Title="Most Play Time"},
 {Key="Speed", Title="Highest Speed", Stat="Speed", Suffix=" pts"},
}

local function encode(value, def)
 if not def.Stat then return math.floor(value) end
 return math.round(math.log10(1 + value) * L.ScorePrecision)
end

local function display(value, def)
 if not def.Stat then
  return ("%dh %02dm"):format(math.floor(value/3600),math.floor(value/60)%60)
 end
 return (def.Prefix or "") .. Format.Compact(10^(value/L.ScorePrecision)-1) .. (def.Suffix or "")
end

local function makeBoard(folder, plaza, def, index)
 local board = Instance.new("Part")
 board.Name = def.Key
 board.Size = L.BoardSize
 board.Anchored = true
 board.CanCollide = false
 board.CanTouch = false
 board.CanQuery = false
 board.Color = Color3.fromRGB(18,30,43)
 local offset = Vector3.new((index-2)*L.BoardSpacing,(plaza.Size.Y+board.Size.Y)/2,-plaza.Size.Z/2+L.EdgeInset)
 board.CFrame = plaza.CFrame*CFrame.new(offset)*CFrame.Angles(0,math.pi,0)
 board.Parent = folder
 local gui = Instance.new("SurfaceGui")
 gui.CanvasSize = Vector2.new(660,540)
 gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
 gui.LightInfluence = 0
 gui.Parent = board
 local function label(name,text,y,height)
  local row = Instance.new("TextLabel")
  row.Name = name
  row.BackgroundTransparency = 1
  row.Position = UDim2.fromScale(.04,y)
  row.Size = UDim2.fromScale(.92,height)
  row.Font = Enum.Font.GothamBold
  row.TextColor3 = Color3.fromRGB(235,245,255)
  row.TextScaled = true
  row.Text = text
  row.Parent = gui
  return row
 end
 label("Heading",def.Title,0,.13)
 local rows = {}
 for rank=1,L.Top do
  rows[rank] = label("Rank"..rank,rank..".  -",.15+(rank-1)*.83/L.Top,.8/L.Top)
 end
 return rows
end

function Boards.Init()
 local localOnly = RunService:IsStudio() and Config.PlayerData.StudioMemoryOnly
 local plaza = workspace.Greybox.Plaza
 local folder = Instance.new("Folder")
 folder.Name = "GlobalLeaderboards"
 folder:SetAttribute("MemoryOnly",localOnly)
 folder.Parent = plaza
 local states, names = {}, {}
 for i,def in ipairs(definitions) do
  states[i] = {definition=def,rows=makeBoard(folder,plaza.PlazaFloor,def,i),values={},written={}}
  if not localOnly then
   states[i].store = DSS:GetOrderedDataStore(L.StorePrefix..def.Key)
  end
 end
 local function refresh(state)
  local def = state.definition
  for _,p in Players:GetPlayers() do
   local profile = Data.Get(p)
   if profile and p:GetAttribute("DataReady") then
    local value = def.Stat and Stats.Get(p,def.Stat) or profile.initialPlay+math.floor(os.clock()-profile.started)
    local key, score = tostring(p.UserId), encode(value,def)
    names[key] = p.Name
    if localOnly then
     state.values[key] = score
    elseif state.written[key] ~= score and DSS:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.OrderedWrite)>0 then
     local ok, err = pcall(state.store.SetAsync,state.store,key,score)
     if ok then state.written[key] = score else warn("[Leaderboards] "..def.Key.." write: "..tostring(err)) end
    end
   end
  end
  local entries = {}
  if localOnly then
   for key,value in state.values do table.insert(entries,{key=key,value=value}) end
   table.sort(entries,function(a,b)
    if a.value==b.value then return a.key<b.key end
    return a.value>b.value
   end)
  elseif DSS:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.OrderedList)>0 then
   local ok,pages = pcall(state.store.GetSortedAsync,state.store,false,L.Top)
   if not ok then warn("[Leaderboards] "..def.Key.." list: "..tostring(pages)) return end
   entries = pages:GetCurrentPage()
  else
   return
  end
  for rank,row in ipairs(state.rows) do
   local entry = entries[rank]
   if entry then
    local key = entry.key
    if not names[key] then
     local ok,name = pcall(Players.GetNameFromUserIdAsync,Players,tonumber(key))
     if ok then names[key]=name end
    end
    row.Text = ("%d.  %s  |  %s"):format(rank,names[key] or ("User "..key),display(entry.value,def))
   else
    row.Text = rank..".  -"
   end
  end
 end
 task.spawn(function()
  repeat task.wait() until #Players:GetPlayers()>0
  while folder.Parent do
   for _,state in ipairs(states) do refresh(state) end
   folder:SetAttribute("RefreshedAt",workspace:GetServerTimeNow())
   task.wait(L.RefreshSeconds)
  end
 end)
end

return Boards
