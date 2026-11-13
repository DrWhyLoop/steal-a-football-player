-- One camera-focused readout replaces the overlapping character, upgrade and collect billboards.
local Players=game:GetService("Players")
local CS=game:GetService("CollectionService")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Format=require(game.ReplicatedStorage.Shared.NumberFormat)
local PlotWatch=require(script.Parent.PlotWatch)
local UIKit=require(script.Parent.UIKit)
local Labels={}

function Labels.Init()
 local player=Players.LocalPlayer
 local playerGui=player:WaitForChild("PlayerGui")
 local comparison=playerGui:FindFirstChild("RewardComparisonLabels")
 if comparison then comparison:Destroy() end
 local gui=Instance.new("ScreenGui")
 gui.Name="FocusedDetails" gui.ResetOnSpawn=false gui.DisplayOrder=5 gui.Parent=playerGui
 local panel=Instance.new("Frame")
 panel.Name="Panel" panel.AnchorPoint=Vector2.new(.5,1)
 panel.Position=UDim2.new(.5,0,1,-Config.FocusUI.Bottom)
 panel.Size=UDim2.fromOffset(Config.FocusUI.PanelWidth,Config.FocusUI.PanelHeight)
 panel.BackgroundColor3=Config.UITheme.Background panel.BackgroundTransparency=.08
 panel.Visible=false panel.Parent=gui
 local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,12) corner.Parent=panel
 local stroke=Instance.new("UIStroke") stroke.Color=Config.UITheme.Border stroke.Transparency=.25 stroke.Parent=panel
 local width=Instance.new("UISizeConstraint") width.MaxSize=Vector2.new(Config.FocusUI.PanelWidth,Config.FocusUI.PanelHeight) width.Parent=panel
 local function line(name,y,size,color)
  local text=Instance.new("TextLabel")
  text.Name=name text.BackgroundTransparency=1 text.Position=UDim2.fromOffset(14,y)
  text.Size=UDim2.new(1,-28,0,size+6) text.Font=Enum.Font.FredokaOne text.TextSize=size
  text.TextXAlignment=Enum.TextXAlignment.Left text.TextTruncate=Enum.TextTruncate.AtEnd
  text.TextColor3=color text.Parent=panel
  return text
 end
 local title=line("Title",8,18,Config.UITheme.Text)
 local subtitle=line("Subtitle",34,13,Config.UITheme.Muted)
 local value=line("Value",57,18,Config.UITheme.Selected)
 local slots={}
 PlotWatch.Each(function(plot)
  for _,slot in plot.Slots:GetChildren() do table.insert(slots,slot) end
 end)
 local sight=RaycastParams.new()
 sight.RespectCanCollide=true
 local function inFront(camera,root,position,exclude)
  if (position-root.Position).Magnitude>Config.FocusUI.Range then return nil end
  local point,onScreen=camera:WorldToViewportPoint(position)
  if not onScreen then return nil end
  local center=camera.ViewportSize/2
  local score=(Vector2.new(point.X,point.Y)-center).Magnitude/math.min(center.X,center.Y)
  if score>Config.FocusUI.ScreenRadius*2 then return nil end
  local ignore={player.Character,exclude}
  local offset=position-camera.CFrame.Position
  for _=1,6 do
   sight.FilterDescendantsInstances=ignore
   local hit=workspace:Raycast(camera.CFrame.Position,offset,sight)
   if not hit then return score end
   if hit.Instance.Transparency<.95 then return nil end
   table.insert(ignore,hit.Instance)
  end
  return nil
 end
 task.spawn(function()
  while gui.Parent do
   task.wait(Config.FocusUI.RefreshSeconds)
   local camera=workspace.CurrentCamera
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   local best,bestScore
   for _,card in CS:GetTagged("Card") do
    local old=card:FindFirstChild("HeadLabel") if old then old:Destroy() end
    if camera and root and card:IsDescendantOf(workspace) and card:GetAttribute("State")~="Carried" then
     local visual=card:FindFirstChild("PlayerVisual")
     local mesh=visual and visual.PrimaryPart
     if mesh then
      local score=inFront(camera,root,mesh.Position,card)
      if score and (not bestScore or score<bestScore) then best,bestScore={kind="Player",card=card},score end
     end
    end
   end
   for i=#slots,1,-1 do
    local slot=slots[i]
    if not slot.Parent then table.remove(slots,i) continue end
    for _,pair in {{"UpgradePanel","Upgrade"},{"CollectPad","Collect"}} do
     local ref=slot:FindFirstChild(pair[1])
     local target=ref and ref.Value
     if target then
      local info=target:FindFirstChild("InfoGui")
      if info then info.Enabled=false end
      if camera and root and slot:GetAttribute("CardName") then
       local score=inFront(camera,root,target.Position,target.Parent)
       if score and (not bestScore or score<bestScore) then best,bestScore={kind=pair[2],slot=slot,target=target},score end
      end
     end
    end
   end
   local carrying=player:GetAttribute("CarriedCard")
   local hotbar=playerGui:FindFirstChild("ToolHotbar")
   panel.Visible=best~=nil and not carrying and not playerGui:GetAttribute("MenuOpen") and not (hotbar and hotbar.Inventory.Visible)
   panel:SetAttribute("FocusKind",best and best.kind)
   panel:SetAttribute("FocusedItemId",nil)
   panel:SetAttribute("FocusedSlot",nil)
   if not panel.Visible then continue end
   local viewport=UIKit.Viewport()
   local short=viewport.Y<500
   panel.Size=UDim2.fromOffset(math.min(Config.FocusUI.PanelWidth,viewport.X-32),short and 84 or Config.FocusUI.PanelHeight)
   panel.Position=UDim2.new(.5,0,1,-(short and 90 or Config.FocusUI.Bottom))
   subtitle.TextColor3=Config.UITheme.Muted
   if best.kind=="Player" then
    local card=best.card
    title.Text=card:GetAttribute("CardName") or "Footballer"
    local variant=card:GetAttribute("Variant") or "Normal"
    local size=card:GetAttribute("SizeTier") or "Normal"
    subtitle.Text=(card:GetAttribute("Tier") or "")..(size~="Normal" and " · "..size or "")..(variant~="Normal" and " · "..variant or "")
    local expiry=card:GetAttribute("WorldExpiresAt")
    local timer=expiry and (" · %ds left"):format(math.max(0,math.ceil(expiry-workspace:GetServerTimeNow()))) or ""
    value.Text="$"..Format.Money(card:GetAttribute("CashPerSecond") or 0).."/second"..timer
    value.TextColor3=Config.UITheme.Selected
    panel:SetAttribute("FocusedItemId",card:GetAttribute("ItemId"))
   elseif best.kind=="Upgrade" then
    local slot=best.slot
    title.Text="Upgrade · "..slot:GetAttribute("CardName")
    local level=slot:GetAttribute("UpgradeLevel") or 0
    local cost=slot:GetAttribute("UpgradeCost")
    subtitle.Text=cost and ("Level %d → %d · Cost $%s"):format(level,level+1,Format.Money(cost)) or ("Level %d · Maximum"):format(level)
    local nextIncome=slot:GetAttribute("NextIncome") or 0
    value.Text=cost and ("$%s/s → $%s/s"):format(Format.Money(nextIncome/Config.PlotSlots.IncomeGrowth),Format.Money(nextIncome)) or "Fully upgraded"
    subtitle.TextColor3=cost and (player:GetAttribute("Cash") or 0)<cost and Config.PlotSlots.CantAffordColor or Config.UITheme.Muted
    value.TextColor3=Config.UITheme.Selected
    panel:SetAttribute("FocusedSlot",slot.Name)
   else
    title.Text="Collect earnings"
    subtitle.Text=best.slot:GetAttribute("CardName")
    local info=best.target:FindFirstChild("InfoGui")
    value.Text=info and info.Label.Text or "$0"
    value.TextColor3=Config.UITheme.Selected
    panel:SetAttribute("FocusedSlot",best.slot.Name)
   end
  end
 end)
end
return Labels
