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
 Kit.Screen(gui)
 local open = Kit.Nav(gui,"Trails","star",1,true)
 local panel,title,list = Kit.Panel(gui,"Shop","TRAILS","Equip one trail to earn more Speed points on your treadmill.",44)
 local status = Kit.Label(panel,"",UDim2.new(1,-24,0,32),UDim2.new(0,12,1,-38))
 local buttons = {}
 for index,def in ipairs(Config.Trails.Catalog) do
  local row = Instance.new("Frame")
  row.Name = def.Id
  row.LayoutOrder = index
  row.Size = UDim2.new(1,-8,0,152)
  row.Parent = list
  Kit.Card(row)
  local swatch=Instance.new("Frame") swatch.Name="TrailSwatch" swatch.Size=UDim2.fromOffset(54,54) swatch.Position=UDim2.fromOffset(12,14) swatch.Rotation=-8 swatch.Parent=row Kit.Card(swatch)
  swatch.BackgroundColor3=def.Color or Config.UITheme.Accent
  local icon=Kit.Icon(swatch,"star",UDim2.fromOffset(30,30),UDim2.fromOffset(12,12)) icon.ImageColor3=Color3.new(1,1,1)
  local name=Kit.Label(row,def.Name,UDim2.new(1,-92,0,30),UDim2.fromOffset(80,12)) name.TextXAlignment=Enum.TextXAlignment.Left name.Font=Enum.Font.FredokaOne
  local details=Kit.Label(row,("x%s Speed Points | %s"):format(Format.Compact(def.Multiplier),def.Rarity or "Starter"),UDim2.new(1,-92,0,38),UDim2.fromOffset(80,42)) details.TextXAlignment=Enum.TextXAlignment.Left details.TextSize=14 details.TextColor3=Config.UITheme.Muted
  local button = Kit.Button(row,"",UDim2.new(1,-24,0,44),UDim2.new(0,12,1,-56))
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
