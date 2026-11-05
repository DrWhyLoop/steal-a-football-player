-- Upgrade (brown) panel text, drawn from slot attributes so the cost can turn red from the viewer's own cash,
-- plus the short message shown when the server rejects an upgrade.
local CS=game:GetService("CollectionService")
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Remotes=require(game.ReplicatedStorage.Shared.Remotes)
local Format=require(game.ReplicatedStorage.Shared.NumberFormat)
local SlotUI={}
local player=Players.LocalPlayer
local function render(slot)
 local label=slot.UpgradePanel.Value.InfoGui.Label
 local level=slot:GetAttribute("UpgradeLevel") or 0
 local cost=slot:GetAttribute("UpgradeCost")
 local owner=slot:FindFirstAncestorOfClass("Model"):GetAttribute("OwnerUserId")==player.UserId
 label.RichText=true
 if slot:GetAttribute("CardName")==nil then label.Text="Place a player"
 elseif not owner then label.Text=("Lv %d"):format(level)
 elseif not cost then label.Text=("Lv %d\nMAX LEVEL"):format(level)
 else
  local color=(player:GetAttribute("Cash") or 0)<cost and Config.PlotSlots.CantAffordColor or Color3.new(1,1,1)
  label.Text=('Lv %d\n<font color="#%s">Upgrade: $%s</font>\nNext: $%s/s'):format(level,color:ToHex(),Format.Money(cost),Format.Money(slot:GetAttribute("NextIncome")))
 end
end
function SlotUI.Init()
 local slots={}
 for _,plot in CS:GetTagged("Plot") do
  plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function() for _,slot in plot.Slots:GetChildren() do render(slot) end end)
  for _,slot in plot.Slots:GetChildren() do
   table.insert(slots,slot)
   for _,attribute in {"CardName","UpgradeLevel","UpgradeCost","NextIncome"} do slot:GetAttributeChangedSignal(attribute):Connect(function() render(slot) end) end
   render(slot)
  end
 end
 task.spawn(function()
  player:GetAttributeChangedSignal("Cash"):Connect(function() for _,slot in slots do if slot:GetAttribute("UpgradeCost") then render(slot) end end end)
 end)

 local gui=Instance.new("ScreenGui") gui.Name="SlotMessages" gui.ResetOnSpawn=false gui.DisplayOrder=50 gui.Parent=player:WaitForChild("PlayerGui")
 local text=Instance.new("TextLabel") text.AnchorPoint=Vector2.new(.5,1) text.Position=UDim2.fromScale(.5,.82) text.Size=UDim2.fromOffset(280,44)
 text.BackgroundColor3=Color3.fromRGB(20,20,20) text.BackgroundTransparency=.2 text.TextColor3=Color3.new(1,1,1) text.TextScaled=true text.Font=Enum.Font.GothamBold text.Visible=false text.Parent=gui
 Instance.new("UICorner",text).CornerRadius=UDim.new(0,10)
 local token=0
 Remotes.UpgradeResult.OnClientEvent:Connect(function(reason)
  token+=1 local mine=token
  text.Text=Config.PlotSlots.Messages[reason] or "" text.Visible=text.Text~=""
  task.delay(Config.PlotSlots.MessageSeconds,function() if token==mine then text.Visible=false end end)
 end)
end
return SlotUI
