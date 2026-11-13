local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Shared.Config)
local Remotes=require(RS.Shared.Remotes)
local Format=require(RS.Shared.NumberFormat)
local Viewport=require(script.Parent.ModelViewport)
local UIKit=require(script.Parent.UIKit)
local label,button=UIKit.Label,UIKit.Button
local UI={}
function UI.Init()
 local player=Players.LocalPlayer
 local gui=Instance.new("ScreenGui") gui.Name="TreadmillShop" gui.ResetOnSpawn=false gui.Parent=player.PlayerGui
 local open=UIKit.Nav(gui,"Treadmills","energy",4,true)
 local support=UIKit.Nav(gui,"Feedback","mail",5,true)
 local panel,title,scroll=UIKit.Panel(gui,"Shop","TREADMILLS","Train for Speed Points. More Speed Points make you walk faster. One treadmill per plot.",74)
 local hud=Instance.new("Frame") hud.Name="PlayerStats" hud.AnchorPoint=Vector2.new(0,1)
 hud.Position=UDim2.new(0,14,1,-22) hud.Size=UDim2.new(.24,0,0,78) hud.BackgroundColor3=Color3.fromRGB(18,31,45) hud.BackgroundTransparency=.12 hud.Parent=gui
 local hudSize=Instance.new("UISizeConstraint") hudSize.MinSize=Vector2.new(175,78) hudSize.MaxSize=Vector2.new(220,78) hudSize.Parent=hud
 local hudCorner=Instance.new("UICorner") hudCorner.CornerRadius=UDim.new(0,12) hudCorner.Parent=hud
 local stats=label(hud,"",UDim2.new(1,-20,1,-12),UDim2.fromOffset(10,6)) stats.TextXAlignment=Enum.TextXAlignment.Left stats.TextSize=16
 UIKit.Card(hud)
 local coin=RS:WaitForChild("UIAssets"):WaitForChild("CoinIcon"):Clone() coin.Name="CoinIcon" coin.Size=UDim2.fromOffset(22,22) coin.Position=UDim2.fromOffset(12,10) coin.BackgroundTransparency=1 coin.Parent=hud
 UIKit.Icon(hud,"energy",UDim2.fromOffset(22,22),UDim2.fromOffset(12,44))
 stats.Position=UDim2.fromOffset(44,5) stats.Size=UDim2.new(1,-52,0,32)
 stats.TextColor3=Config.UITheme.Selected stats.Font=Enum.Font.FredokaOne stats.TextSize=19
 local speedText=label(hud,"",UDim2.new(1,-52,0,30),UDim2.fromOffset(44,38))
 speedText.TextXAlignment=Enum.TextXAlignment.Left speedText.TextSize=15 speedText.TextColor3=Config.UITheme.Muted
 local counter=Instance.new("NumberValue") local speedCounter=Instance.new("NumberValue")
 counter.Changed:Connect(function(v) stats.Text="$"..Format.Money(v) end)
 speedCounter.Changed:Connect(function(v) speedText.Text=Format.Compact(v).." Speed" end)
 stats.Text="$0" speedText.Text="0 Speed"
 local cashTween,speedTween
 UIKit.OnResize(function(view)
  local compact=view.X<Config.UITheme.CompactWidth
  hud.AnchorPoint=compact and Vector2.new(0,0) or Vector2.new(0,1)
  hud.Position=compact and UDim2.fromOffset(14,14) or UDim2.new(0,14,1,-22)
 end)
 local rows={}
 local priceLabel=UIKit.PriceLabel
 for index,tier in Config.Treadmills.Catalog do
  local row,thumb,name,details,buy=UIKit.Product(scroll,tier.Id,index)
  local preview=RS:WaitForChild("TreadmillPreviewTemplates"):FindFirstChild(tier.Id)
  if preview then Viewport.Create(thumb,preview,false,false,"Float") end
  name.Text=tier.Name.." | "..Format.Exact(tier.Multiplier).."x"
  local base="+"..Format.Compact(Config.Treadmills.BaseGain*tier.Multiplier).." Speed/sec\n"
  details.Text=base..(tier.Cost and (tier.Cost==0 and "Free" or "$"..Format.Compact(tier.Cost)) or "")
  buy.Activated:Connect(function()
   local owned=player:GetAttribute("CashTreadmillTier") or 1
   if tier.GamePassId then -- a Robux item: only an explicit tap on an owned or priced row does anything
    if player:GetAttribute("PassOwned_"..tier.Id) then Remotes.TreadmillRequest:FireServer("Equip",tier.Id)
    elseif (RS:GetAttribute("PassPrice_"..tier.Id) or 0)>0 then Remotes.TreadmillRequest:FireServer("Premium",tier.Id) end
   else Remotes.TreadmillRequest:FireServer(index<=owned and "Equip" or "Buy",tier.Id) end
  end)
  table.insert(rows,{button=buy,index=index,tier=tier,details=details,base=base})
 end
 local cashPass=Config.CashPass
 local cashRow=Instance.new("Frame") cashRow.Name=cashPass.Id cashRow.Size=UDim2.new(1,-8,0,160) cashRow.BackgroundColor3=Color3.fromRGB(35,53,70) cashRow.LayoutOrder=#Config.Treadmills.Catalog+1 cashRow.Parent=scroll
 UIKit.Card(cashRow)
 local cashName=label(cashRow,cashPass.Name.." | permanent "..cashPass.Multiplier.."x cash from your plot",UDim2.new(1,-16,0,40),UDim2.fromOffset(8,6)) cashName.TextXAlignment=Enum.TextXAlignment.Left cashName.Font=Enum.Font.GothamBold
 local cashDetails=label(cashRow,"",UDim2.new(1,-16,0,44),UDim2.fromOffset(8,46)) cashDetails.TextXAlignment=Enum.TextXAlignment.Left cashDetails.TextSize=14
 local cashBuy=button(cashRow,"",UDim2.new(1,-16,0,44),UDim2.new(0,8,1,-52))
 cashBuy.Activated:Connect(function()
  if not player:GetAttribute("PassOwned_"..cashPass.Id) and (RS:GetAttribute("PassPrice_"..cashPass.Id) or 0)>0 then Remotes.TreadmillRequest:FireServer("Premium",cashPass.Id) end
 end)
 label(panel,"Walk onto your treadmill to train. Walk off to stop.",UDim2.new(1,-24,0,32),UDim2.new(0,12,1,-70))
 local message=label(panel,"",UDim2.new(1,-24,0,28),UDim2.new(0,12,1,-34)) message.TextSize=14
 local lastCash,lastPoints
 local function gain(text,color,y)
  local t=label(hud,text,UDim2.fromOffset(180,26),UDim2.fromOffset(8,y)) t.TextColor3=color
  game:GetService("TweenService"):Create(t,TweenInfo.new(.75),{Position=UDim2.fromOffset(8,y-26),TextTransparency=1}):Play()
  game:GetService("Debris"):AddItem(t,.8)
 end
 local function refresh()
  local cash,points=player:GetAttribute("Cash") or 0,player:GetAttribute("Speed") or 0
  if lastCash and cash>lastCash then gain("+$"..Format.Compact(cash-lastCash),Config.UITheme.Selected,-26) end
  if lastPoints and points>lastPoints then gain("+"..Format.Compact(points-lastPoints).." Speed",Config.UITheme.Accent,-54) end
  if lastCash~=cash then
   if cashTween then cashTween:Cancel() end
   cashTween=game:GetService("TweenService"):Create(counter,TweenInfo.new(.3,Enum.EasingStyle.Quad),{Value=cash}) cashTween:Play()
  end
  if lastPoints~=points then
   if speedTween then speedTween:Cancel() end
   speedTween=game:GetService("TweenService"):Create(speedCounter,TweenInfo.new(.3,Enum.EasingStyle.Quad),{Value=points}) speedTween:Play()
  end
  lastCash,lastPoints=cash,points
  hud.Visible=not player.PlayerGui:GetAttribute("MenuOpen")
  title.Text="TREADMILLS  |  $"..Format.Compact(cash)

  local cashOwned=player:GetAttribute("PassOwned_"..cashPass.Id)
  local cashPrice,cashText=priceLabel(cashPass.Id)
  cashDetails.Text=cashOwned and "Owned" or cashText
  UIKit.State(cashBuy,cashOwned and "Owned" or cashPrice>0 and "Buy "..cashText or cashText,cashOwned,not cashOwned and cashPrice>0)
  local owned=player:GetAttribute("CashTreadmillTier") or 1
  for _,row in rows do
   local tier=row.tier local selected=player:GetAttribute("TreadmillId")==tier.Id
   local enabled,text=true
   if tier.GamePassId then
    local passOwned=player:GetAttribute("PassOwned_"..tier.Id)
    local price,priceText=priceLabel(tier.Id)
    row.details.Text=row.base..(passOwned and "Owned" or priceText)
    text=selected and "Equipped" or passOwned and "Equip" or price>0 and "Buy "..priceText or priceText
    enabled=selected or passOwned or price>0
   else
    text=selected and "Equipped" or row.index<=owned and "Equip" or row.index==owned+1 and "Upgrade" or "Locked"
    enabled=not selected and (row.index<=owned or row.index==owned+1 and cash>=tier.Cost)
   end
   UIKit.State(row.button,text,selected,enabled)
  end
 end
 open.Activated:Connect(function() panel.Visible=not panel.Visible refresh() end)
 Remotes.TreadmillStatus.OnClientEvent:Connect(function(text) message.Text=text refresh() end)
 -- Small private structured-feedback panel, no free-form player messages.
 local feedback,_,feedbackList=UIKit.Panel(gui,"Feedback","PRIVATE FEEDBACK","Choose a category. Reports are sent privately.",16)
 feedbackList.UIListLayout.SortOrder=Enum.SortOrder.Name
 local category=1 local target=0
 local categoryButton=button(feedbackList,"Category: "..Config.PlayerData.FeedbackCategories[category],UDim2.new(1,-8,0,44),UDim2.new())
 categoryButton.Name="1_Category" categoryButton.BackgroundColor3=Config.UITheme.Card
 categoryButton.Activated:Connect(function() category=category%#Config.PlayerData.FeedbackCategories+1 categoryButton.Text="Category: "..Config.PlayerData.FeedbackCategories[category] end)
 local targetButton=button(feedbackList,"Player: none",UDim2.new(1,-8,0,44),UDim2.new())
 targetButton.Name="2_Player" targetButton.BackgroundColor3=Config.UITheme.Card
 targetButton.Activated:Connect(function()
  local options={0} for _,p in Players:GetPlayers() do if p~=player then table.insert(options,p.UserId) end end
  local index=table.find(options,target) or 1 target=options[index%#options+1]
  local p=Players:GetPlayerByUserId(target) targetButton.Text="Player: "..(p and p.DisplayName or "none")
 end)
 local feedbackMessage=label(feedbackList,"For urgent safety issues, also use Roblox's Report Abuse menu.",UDim2.new(1,-8,0,68),UDim2.new())
 feedbackMessage.Name="3_Message"
 local send=button(feedbackList,"Send feedback",UDim2.new(1,-8,0,44),UDim2.new())
 local back=button(feedbackList,"Cancel",UDim2.new(1,-8,0,44),UDim2.new())
 send.Name="4_Send" back.Name="5_Cancel" send.BackgroundColor3=Config.UITheme.Selected send.TextColor3=Color3.new(1,1,1)
 send.Activated:Connect(function() Remotes.FeedbackRequest:FireServer(Config.PlayerData.FeedbackCategories[category],target) end)
 back.Activated:Connect(function() feedback.Visible=false end)
 support.Activated:Connect(function() feedback.Visible=not feedback.Visible panel.Visible=false end)
 Remotes.FeedbackStatus.OnClientEvent:Connect(function(text) feedbackMessage.Text=text end)
 task.spawn(function() while gui.Parent do refresh() task.wait(.5) end end)
 local trainingTrack
 local function trainingChanged()
  if trainingTrack then trainingTrack:Stop() trainingTrack=nil end
  if not player:GetAttribute("Training") then return end
  local char=player.Character local animate=char and char:FindFirstChild("Animate") local h=char and char:FindFirstChildOfClass("Humanoid")
  local run=animate and (animate:FindFirstChild("run") or animate:FindFirstChild("walk"))
  local animation=run and run:FindFirstChildOfClass("Animation") local animator=h and h:FindFirstChildOfClass("Animator")
  local created
  if not animation and h then
   created=Instance.new("Animation")
   local ok,description=pcall(function() return h:GetAppliedDescription() end)
   local id=ok and description.RunAnimation or 0
   created.AnimationId=id>0 and ("rbxassetid://"..id) or h.RigType==Enum.HumanoidRigType.R6 and Config.Treadmills.RunAnimationR6 or Config.Treadmills.RunAnimationR15
   animation=created
  end
  if animation and animator then trainingTrack=animator:LoadAnimation(animation) trainingTrack.Priority=Enum.AnimationPriority.Movement trainingTrack.Looped=true trainingTrack:Play() end
  if created then created:Destroy() end
 end
 player:GetAttributeChangedSignal("Training"):Connect(trainingChanged)
 -- Local budget: imported treadmill effects run only near the observer.
 local fx=require(script.Parent.TreadmillVisibility) fx.Init()
end
return UI
