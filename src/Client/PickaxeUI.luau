-- Pickaxe shop: scrolling list with a model picture, Power and price per pickaxe. The server decides every purchase.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Shared.Config)
local Remotes=require(RS.Shared.Remotes)
local Format=require(RS.Shared.NumberFormat)
local Viewport=require(script.Parent.ModelViewport)
local UIKit=require(script.Parent.UIKit)
local UI={}
function UI.Init()
 local player=Players.LocalPlayer
 local gui=Instance.new("ScreenGui") gui.Name="PickaxeShop" gui.ResetOnSpawn=false gui.Parent=player.PlayerGui
 local open=UIKit.Button(gui,"Pickaxes",UDim2.fromOffset(118,36),UDim2.new(1,-130,.48,-92))
 local panel,title,scroll=UIKit.Panel(gui,"Shop","PICKAXES","Power is the damage of one hit. Buy a stronger pickaxe to break tougher eggs faster.",44)
 local message=UIKit.Label(panel,"",UDim2.new(1,-24,0,32),UDim2.new(0,12,1,-38)) message.TextSize=14
 local previews=RS:WaitForChild("PickaxePreviewTemplates")
 local rows={}
 for index,def in Config.Pickaxes do
  local row=Instance.new("Frame") row.Name=def.Id row.Size=UDim2.new(1,-8,0,150) row.BackgroundColor3=Color3.fromRGB(35,53,70) row.LayoutOrder=index row.Parent=scroll
  local thumb=Instance.new("Frame") thumb.Name="PickaxePicture" thumb.Size=UDim2.new(.42,-8,0,104) thumb.Position=UDim2.fromOffset(8,6) thumb.BackgroundColor3=Color3.fromRGB(185,211,227) thumb.Parent=row
  local preview=previews:FindFirstChild(def.Id)
  if preview then Viewport.Create(thumb,preview,false) end
  local name=UIKit.Label(row,def.Name,UDim2.new(.58,-16,0,40),UDim2.new(.42,4,0,8)) name.TextXAlignment=Enum.TextXAlignment.Left name.Font=Enum.Font.GothamBold
  local details=UIKit.Label(row,("Power %s\n%s"):format(Format.Compact(def.Power),def.Cost==0 and "Free" or "$"..Format.Compact(def.Cost)),UDim2.new(.58,-16,0,56),UDim2.new(.42,4,0,50))
  details.TextXAlignment=Enum.TextXAlignment.Left details.TextSize=14
  local buy=UIKit.Button(row,"",UDim2.new(1,-16,0,32),UDim2.new(0,8,1,-38))
  buy.Activated:Connect(function() Remotes.PickaxeRequest:FireServer(player:GetAttribute("PickaxeOwned_"..def.Id) and "Equip" or "Buy",def.Id) end)
  table.insert(rows,{def=def,button=buy})
 end
 local function refresh()
  local cash=player:GetAttribute("Cash") or 0
  title.Text="PICKAXES  |  $"..Format.Compact(cash)
  for _,row in rows do
   local id=row.def.Id
   local owned,equipped=player:GetAttribute("PickaxeOwned_"..id),player:GetAttribute("PickaxeId")==id
   local affordable=cash>=row.def.Cost
   UIKit.State(row.button,equipped and "Equipped" or owned and "Equip" or "Buy $"..Format.Compact(row.def.Cost),equipped,not equipped and (owned or affordable))
  end
 end
 open.Activated:Connect(function() panel.Visible=not panel.Visible refresh() end)
 Remotes.PickaxeStatus.OnClientEvent:Connect(function(text) message.Text=text refresh() end)
 for _,name in {"Cash","PickaxeId"} do player:GetAttributeChangedSignal(name):Connect(function() if panel.Visible then refresh() end end) end
end
return UI
