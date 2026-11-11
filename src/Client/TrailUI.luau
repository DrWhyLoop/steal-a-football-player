local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local Remotes = require(RS.Shared.Remotes)
local Format = require(RS.Shared.NumberFormat)
local Kit = require(script.Parent.UIKit)
local UI = {}

function UI.Init()
 local player = Players.LocalPlayer
 local gui = Instance.new("ScreenGui")
 gui.Name = "TrailShop"
 gui.ResetOnSpawn = false
 gui.Parent = player.PlayerGui
 local open = Kit.Button(gui,"Trails",UDim2.fromOffset(118,36),UDim2.new(1,-130,.48,-138))
 local panel,title,list = Kit.Panel(gui,"Shop","TRAILS","Equip one trail to earn more Speed points on your treadmill.",44)
 local status = Kit.Label(panel,"",UDim2.new(1,-24,0,32),UDim2.new(0,12,1,-38))
 local buttons = {}
 for index,def in ipairs(Config.Trails.Catalog) do
  local row = Instance.new("Frame")
  row.Name = def.Id
  row.LayoutOrder = index
  row.Size = UDim2.new(1,-8,0,72)
  row.BackgroundColor3 = Color3.fromRGB(35,53,70)
  row.Parent = list
  local label = Kit.Label(row,("%s  |  x%s Speed Points  |  %s"):format(def.Name,Format.Compact(def.Multiplier),def.Rarity or "Starter"),UDim2.new(.60,-12,1,0),UDim2.fromOffset(8,0))
  label.TextXAlignment = Enum.TextXAlignment.Left
  if def.Color then label.TextColor3 = def.Color end
  local button = Kit.Button(row,"",UDim2.new(.38,0,0,38),UDim2.new(.61,0,.5,-19))
  buttons[index] = button
  button.Activated:Connect(function()
   local owned = player:GetAttribute("TrailTier") or 1
   Remotes.TrailRequest:FireServer(index<=owned and "Equip" or "Buy",index)
  end)
 end
 local function refresh()
  local cash = player:GetAttribute("Cash") or 0
  local owned = player:GetAttribute("TrailTier") or 1
  local active = player:GetAttribute("TrailIndex") or 1
  title.Text = "TRAILS  |  $"..Format.Compact(cash)
  for index,button in ipairs(buttons) do
   local def = Config.Trails.Catalog[index]
   local selected = index==active
   local text = selected and "Equipped" or index<=owned and "Equip" or index==owned+1 and "Buy $"..Format.Compact(def.Cost) or "Locked"
   Kit.State(button,text,selected,not selected and (index<=owned or index==owned+1 and cash>=def.Cost))
  end
 end
 open.Activated:Connect(function() panel.Visible=not panel.Visible refresh() end)
 for _,key in {"Cash","TrailTier","TrailIndex"} do
  player:GetAttributeChangedSignal(key):Connect(function() if panel.Visible then refresh() end end)
 end
 Remotes.TrailStatus.OnClientEvent:Connect(function(text) status.Text=text refresh() end)
 refresh()
end

return UI
