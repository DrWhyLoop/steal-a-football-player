-- Label above each yellow upgrade button, drawn from slot attributes so the cost can turn red from the viewer's own cash,
-- the short message shown when the server rejects an upgrade, and the collect-pad press effect with its floating +$X.
local TweenService=game:GetService("TweenService")
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Remotes=require(game.ReplicatedStorage.Shared.Remotes)
local Format=require(game.ReplicatedStorage.Shared.NumberFormat)
local PlotWatch=require(script.Parent.PlotWatch)
local SlotUI={}
local player=Players.LocalPlayer
local function render(slot)
 local gui=slot.UpgradePanel.Value.InfoGui
 local level=slot:GetAttribute("UpgradeLevel") or 0
 local cost=slot:GetAttribute("UpgradeCost")
 local owner=slot:FindFirstAncestorOfClass("Model"):GetAttribute("OwnerUserId")==player.UserId
 gui.Enabled=false
 if not owner then gui.Label.Text=("LV %d"):format(level)
 elseif not cost then gui.Label.Text=("LV %d · MAX"):format(level)
 else
  local color=(player:GetAttribute("Cash") or 0)<cost and Config.PlotSlots.CantAffordColor or Color3.new(1,1,1)
  gui.Label.Text=('LV %d · <font color="#%s">$%s</font> · Next $%s/s'):format(level,color:ToHex(),Format.Money(cost),Format.Money(slot:GetAttribute("NextIncome")))
 end
end

-- Collecting: the pad dips and flashes, a sound plays and +$X floats up from it.
local function collectEffect(slot,amount)
 local P=Config.PlotSlots
 local pad=slot:FindFirstChild("CollectPad") and slot.CollectPad.Value
 if not pad then return end
 local plate,light=pad.Parent.Plate,pad.Parent.Light
 local half=TweenInfo.new(P.CollectEffectSeconds/2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,true)
 TweenService:Create(plate,half,{CFrame=plate.CFrame-Vector3.new(0,plate.Size.X*0.5,0)}):Play() -- the plate's thin axis is X
 TweenService:Create(light,half,{Color=Color3.new(1,1,1)}):Play()
 local sound=Instance.new("Sound") sound.SoundId=P.CollectSoundId sound.Parent=pad sound.PlayOnRemove=true sound:Destroy()
 local gui=Instance.new("BillboardGui") gui.Size=UDim2.fromOffset(P.LabelWidth,P.LabelHeight) gui.StudsOffsetWorldSpace=Vector3.new(0,pad.Size.Y+1,0) gui.AlwaysOnTop=true gui.Adornee=pad gui.Parent=pad
 local text=Instance.new("TextLabel") text.Size=UDim2.fromScale(1,1) text.BackgroundTransparency=1 text.Font=Enum.Font.GothamBlack text.TextScaled=true
 text.TextColor3=Color3.fromRGB(120,255,120) text.TextStrokeTransparency=0.2 text.Text="+$"..Format.Money(amount) text.Parent=gui
 local rise=TweenInfo.new(1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
 TweenService:Create(gui,rise,{StudsOffsetWorldSpace=gui.StudsOffsetWorldSpace+Vector3.new(0,3,0)}):Play()
 TweenService:Create(text,rise,{TextTransparency=1,TextStrokeTransparency=1}):Play()
 task.delay(1,function() gui:Destroy() end)
end
function SlotUI.Init()
 local slots={}
 PlotWatch.Each(function(plot)
  plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function() for _,slot in plot.Slots:GetChildren() do render(slot) end end)
  for _,slot in plot.Slots:GetChildren() do
   table.insert(slots,slot)
   for _,attribute in {"CardName","UpgradeLevel","UpgradeCost","NextIncome"} do slot:GetAttributeChangedSignal(attribute):Connect(function() render(slot) end) end
   render(slot)
  end
 end)
 player:GetAttributeChangedSignal("Cash"):Connect(function() for _,slot in slots do if slot:GetAttribute("UpgradeCost") then render(slot) end end end)

 Remotes.CollectResult.OnClientEvent:Connect(collectEffect)

 local gui=Instance.new("ScreenGui") gui.Name="SlotMessages" gui.ResetOnSpawn=false gui.DisplayOrder=50 gui.Parent=player:WaitForChild("PlayerGui")
 local text=Instance.new("TextLabel") text.AnchorPoint=Vector2.new(.5,1) text.Position=UDim2.new(.5,0,1,-225) text.Size=UDim2.fromOffset(280,44)
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
