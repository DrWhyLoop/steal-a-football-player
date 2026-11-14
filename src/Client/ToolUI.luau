-- Tools shop: cash tools (bought with cash) and premium tools (Robux game passes with the live price). The server decides everything.
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
 local gui=Instance.new("ScreenGui") gui.Name="ToolShop" gui.ResetOnSpawn=false gui.Parent=player.PlayerGui
 UIKit.Screen(gui)
 local open=UIKit.Nav(gui,"Tools","key",2)
 local panel,title,scroll=UIKit.Panel(gui,"Shop","TOOLS","Choose your next tool. Compare power, unlock it, then equip.",44)
 local message=UIKit.Label(panel,"",UDim2.new(1,-24,0,32),UDim2.new(0,12,1,-38)) message.TextSize=14
 local previews=RS:WaitForChild("ToolPreviewTemplates")
 local function header(text,order)
  local label=UIKit.Label(scroll,text,UDim2.new(1,-8,0,28),UDim2.new()) label.Font=Enum.Font.GothamBold label.LayoutOrder=order
 end
 -- One row: picture, name, details text and the main button (plus an optional arm button for the Robot Arm Drill).
 local function makeRow(def,order,withArm)
  local row,thumb,name,details,buy=UIKit.Product(scroll,def.Id,order,withArm)
  local preview=previews:FindFirstChild(def.Id)
  if preview then Viewport.Create(thumb,preview,false,false,"Spin") end
  name.Text=def.Name
  local arm
  if withArm then
   arm=UIKit.Button(row,"",UDim2.new(1,-24,0,44),UDim2.new(0,12,1,-106))
   arm.Activated:Connect(function()
    local modes=Config.ArmModes
    Remotes.ToolRequest:FireServer("Arm",modes[(table.find(modes,player:GetAttribute("ArmMode") or modes[1]) or 0)%#modes+1])
   end)
  end
  return {def=def,name=name,details=details,button=buy,arm=arm}
 end
 local cashRows,premiumRows={},{}
 header("CASH TOOLS",0)
 for index,def in Config.CashTools do
  local row=makeRow(def,index)
  row.name.TextColor3=Config.UITheme.Text
  row.details.Text=("%s | Power %s\n%s"):format(def.Rarity,Format.Compact(def.Power),def.Cost==0 and "Free" or "$"..Format.Compact(def.Cost))
  row.button.Activated:Connect(function() Remotes.ToolRequest:FireServer(player:GetAttribute("ToolOwned_"..def.Id) and "Equip" or "Buy",def.Id) end)
  table.insert(cashRows,row)
 end
 header("PREMIUM TOOLS",100)
 for index,def in Config.PremiumTools do
  local row=makeRow(def,100+index,def.Arms)
  row.button.Activated:Connect(function() Remotes.ToolRequest:FireServer(player:GetAttribute("PassOwned_"..def.Id) and "Equip" or "Premium",def.Id) end)
  table.insert(premiumRows,row)
 end
 local function refresh()
  local cash=player:GetAttribute("Cash") or 0
  title.Text="TOOLS  |  $"..Format.Compact(cash)
  for _,row in cashRows do
   local id=row.def.Id
   local owned,equipped=player:GetAttribute("ToolOwned_"..id),player:GetAttribute("ToolId")==id
   UIKit.State(row.button,equipped and "Equipped" or owned and "Equip" or "Buy $"..Format.Compact(row.def.Cost),equipped,not equipped and (owned or cash>=row.def.Cost))
  end
  local best=Config.CashTools[1].Power
  for _,def in Config.CashTools do
   if player:GetAttribute("ToolOwned_"..def.Id) then best=math.max(best,def.Power) end
  end
  for _,row in premiumRows do
   local def=row.def
   local owned,equipped=player:GetAttribute("PassOwned_"..def.Id),player:GetAttribute("ToolId")==def.Id
   local price,priceText=UIKit.PriceLabel(def.Id)
   local note=owned and "Owned" or def.ComingSoon and "Coming soon" or priceText
   row.details.Text=("Power %s (%sx your best tool)\n%s"):format(Format.Compact(best*def.Multiplier),def.Multiplier,note)
   UIKit.State(row.button,equipped and "Equipped" or owned and "Equip" or def.ComingSoon and "Coming soon" or price>0 and "Buy "..priceText or priceText,equipped,not equipped and (owned or (not def.ComingSoon and price>0)))
   if row.arm then row.arm.Visible=owned==true UIKit.State(row.arm,"Arm: "..(player:GetAttribute("ArmMode") or Config.ArmModes[1]),false,true) end
  end
 end
 open.Activated:Connect(function() panel.Visible=not panel.Visible refresh() end)
 Remotes.ToolStatus.OnClientEvent:Connect(function(text) message.Text=text refresh() end)
 for _,name in {"Cash","ToolId","ArmMode"} do player:GetAttributeChangedSignal(name):Connect(function() if panel.Visible then refresh() end end) end
end
return UI
