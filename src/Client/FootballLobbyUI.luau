local Players = game:GetService("Players")
local Shared = game.ReplicatedStorage.Shared
local Modes = require(Shared.Config).FootballLobby.Modes
local Remotes = require(Shared.Remotes)
local Kit = require(script.Parent.UIKit)
local UI = {}

function UI.Init()
 local gui = Instance.new("ScreenGui")
 gui.Name = "FootballLobby"
 gui.ResetOnSpawn = false
 gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
 local panel,title,list = Kit.Panel(gui,"Lobby","FOOTBALL COURT","Challenge another player at the court.",90)
 local status = Kit.Label(panel,"",UDim2.new(1,-24,0,34),UDim2.new(0,12,1,-82))
 local leave = Kit.Button(panel,"Cancel",UDim2.fromOffset(115,34),UDim2.new(0,12,1,-43))
 local function cancel()
  Remotes.FootballRequest:FireServer("Cancel")
  panel.Visible = false
 end
 leave.Activated:Connect(cancel)
 for _,child in panel:GetChildren() do
  if child:IsA("TextButton") and child.Text=="Close" then child.Activated:Connect(cancel) end
 end
 local function clear()
  for _,child in list:GetChildren() do if child:IsA("GuiObject") then child:Destroy() end end
  list.CanvasPosition = Vector2.zero
 end
 local function button(text, callback)
  local b = Kit.Button(list,text,UDim2.new(1,-8,0,42),UDim2.new())
  b.LayoutOrder = #list:GetChildren()
  b.Activated:Connect(callback)
  return b
 end
 Remotes.FootballLobby.OnClientEvent:Connect(function(page,data)
  panel.Visible = true
  if page=="Notice" then status.Text=data return end
  clear()
  title.Text = "FOOTBALL COURT"
  if page=="Open" then
   status.Text = ("%d placed players. Choose a mode."):format(data.count)
   for _,id in {"4v4","11v11"} do
    local mode = Modes[id]
    button(("%s  |  %d placed players required"):format(id,mode.Starters+1),function()
     clear()
     status.Text = "Choose an opponent at the entrance."
     if #data.opponents==0 then status.Text="No opponents nearby. Ask another player to come to the court." end
     for _,opponent in data.opponents do
      button(("%s  |  %d placed"):format(opponent.name,opponent.count),function()
       Remotes.FootballRequest:FireServer("Invite",opponent.id,id)
      end)
     end
     button("Refresh opponents",function() Remotes.FootballRequest:FireServer("Open") end)
    end)
   end
  elseif page=="Invite" then
   status.Text = data.name.." challenged you to "..data.mode.."."
   button("Accept challenge",function() Remotes.FootballRequest:FireServer("Accept") end)
   button("Decline challenge",function() Remotes.FootballRequest:FireServer("Cancel") end)
  elseif page=="Select" then
   title.Text = data.mode.." LINEUP"
   local needed = Modes[data.mode].Starters
   local starters, stake = {}, nil
   local function refresh()
    status.Text = ("%d/%d starters  |  Stake: %s"):format(#starters,needed,stake and "selected" or "choose one extra")
   end
   button("Confirm lineup",function()
    if #starters==needed and stake then
     Remotes.FootballRequest:FireServer("Ready",{starters=starters,stake=stake})
    else
     status.Text="Pick all starters and a separate stake."
    end
   end)
   local rows = {}
   local function refreshRows()
    for _,row in rows do
     row.start.Text=table.find(starters,row.id) and "Selected" or "Start"
     row.stake.Text=stake==row.id and "Staked" or "Stake"
    end
    refresh()
   end
   for _,card in data.roster do
    local frame = Instance.new("Frame")
    frame.Size=UDim2.new(1,-8,0,46)
    frame.BackgroundColor3=Color3.fromRGB(30,48,63)
    frame.LayoutOrder=#list:GetChildren()
    frame.Parent=list
    local name=Kit.Label(frame,card.name.."  |  "..card.tier,UDim2.fromScale(.54,1),UDim2.new())
    name.TextSize=14
    local start=Kit.Button(frame,"Start",UDim2.fromScale(.21,.85),UDim2.fromScale(.55,.075))
    local wager=Kit.Button(frame,"Stake",UDim2.fromScale(.21,.85),UDim2.fromScale(.78,.075))
    table.insert(rows,{id=card.id,start=start,stake=wager})
    start.Activated:Connect(function()
     local index=table.find(starters,card.id)
     if index then table.remove(starters,index)
     elseif #starters<needed then
      if stake==card.id then stake=nil end
      table.insert(starters,card.id)
     end
     refreshRows()
    end)
    wager.Activated:Connect(function()
     local index=table.find(starters,card.id)
     if index then table.remove(starters,index) end
     if stake==card.id then stake=nil else stake=card.id end
     refreshRows()
    end)
   end
   refreshRows()
  elseif page=="Staged" then
   status.Text=data.." squads assembled on the pitch."
  elseif page=="Waiting" or page=="Closed" then
   status.Text=data
  end
 end)
end

return UI
