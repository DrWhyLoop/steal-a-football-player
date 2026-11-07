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
 local open=UIKit.Button(gui,"Tools",UDim2.fromOffset(118,36),UDim2.new(1,-130,.48,-92))
 local panel,title,scroll=UIKit.Panel(gui,"Shop","TOOLS","Cash tools hit harder the more you pay. A premium tool is only ever a little stronger than your best cash tool.",44)
 local message=UIKit.Label(panel,"",UDim2.new(1,-24,0,32),UDim2.new(0,12,1,-38)) message.TextSize=14
 local previews=RS:WaitForChild("ToolPreviewTemplates")
 local function header(text,order)
  local label=UIKit.Label(scroll,text,UDim2.new(1,-8,0,28),UDim2.new()) label.Font=Enum.Font.GothamBold label.LayoutOrder=order
 end
 -- One row: picture, name, details text and the main button (plus an optional arm button for the Robot Arm Drill).
 local function makeRow(def,order,height,withArm)
  local row=Instance.new("Frame") row.Name=def.Id row.Size=UDim2.new(1,-8,0,height) row.BackgroundColor3=Color3.fromRGB(35,53,70) row.LayoutOrder=order row.Parent=scroll
  local thumb=Instance.new("Frame") thumb.Name="ToolPicture" thumb.Size=UDim2.new(.42,-8,0,104) thumb.Position=UDim2.fromOffset(8,6) thumb.BackgroundColor3=Color3.fromRGB(185,211,227) thumb.Parent=row
  local preview=previews:FindFirstChild(def.Id)
  if preview then Viewport.Create(thumb,preview,false) end
  local name=UIKit.Label(row,def.Name,UDim2.new(.58,-16,0,40),UDim2.new(.42,4,0,8)) name.TextXAlignment=Enum.TextXAlignment.Left name.Font=Enum.Font.GothamBold
  local details=UIKit.Label(row,"",UDim2.new(.58,-16,0,56),UDim2.new(.42,4,0,50)) details.TextXAlignment=Enum.TextXAlignment.Left details.TextSize=14
  local buy=UIKit.Button(row,"",UDim2.new(1,-16,0,32),UDim2.new(0,8,1,-38))
  local arm
  if withArm then
   arm=UIKit.Button(row,"",UDim2.new(.58,-16,0,28),UDim2.new(.42,4,0,112))
   arm.Activated:Connect(function()
    local modes=Config.ArmModes
    Remotes.ToolRequest:FireServer("Arm",modes[(table.find(modes,player:GetAttribute("ArmMode") or modes[1]) or 0)%#modes+1])
   end)
  end
  return {def=def,details=details,button=buy,arm=arm}
 end
 local cashRows,premiumRows={},{}
 header("CASH TOOLS",0)
 for index,def in Config.CashTools do
  local row=makeRow(def,index,150)
  row.details.Text=("Power %s\n%s"):format(Format.Compact(def.Power),def.Cost==0 and "Free" or "$"..Format.Compact(def.Cost))
  row.button.Activated:Connect(function() Remotes.ToolRequest:FireServer(player:GetAttribute("ToolOwned_"..def.Id) and "Equip" or "Buy",def.Id) end)
  table.insert(cashRows,row)
 end
 header("PREMIUM TOOLS",100)
 for index,def in Config.PremiumTools do
  local row=makeRow(def,100+index,def.Arms and 190 or 160,def.Arms)
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
  for _,row in premiumRows do
   local def=row.def
   local owned,equipped=player:GetAttribute("PassOwned_"..def.Id),player:GetAttribute("ToolId")==def.Id
   local price,priceText=UIKit.PriceLabel(def.Id)
   local note=owned and "Owned" or def.ComingSoon and "Coming soon" or priceText..(price>0 and "\nOpens Roblox's purchase window. Nothing is charged until you confirm there." or "")
   row.details.Text=("Power x%.2f of your best cash tool\n%s"):format(def.Multiplier,note)
   UIKit.State(row.button,equipped and "Equipped" or owned and "Equip" or def.ComingSoon and "Coming soon" or price>0 and "Buy "..priceText or priceText,equipped,not equipped and (owned or (not def.ComingSoon and price>0)))
   if row.arm then row.arm.Visible=owned==true UIKit.State(row.arm,"Arm: "..(player:GetAttribute("ArmMode") or Config.ArmModes[1]),false,true) end
  end
 end
 open.Activated:Connect(function() panel.Visible=not panel.Visible refresh() end)
 Remotes.ToolStatus.OnClientEvent:Connect(function(text) message.Text=text refresh() end)
 for _,name in {"Cash","ToolId","ArmMode"} do player:GetAttributeChangedSignal(name):Connect(function() if panel.Visible then refresh() end end) end
end
return UI
