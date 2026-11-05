local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Shared.Config)
local Remotes=require(RS.Shared.Remotes)
local Format=require(RS.Shared.NumberFormat)
local Viewport=require(script.Parent.ModelViewport)
local UI={}
local function label(parent,text,size,pos)
 local t=Instance.new("TextLabel") t.Text=text t.Size=size t.Position=pos t.BackgroundTransparency=1
 t.Font=Enum.Font.Gotham t.TextColor3=Color3.fromRGB(235,240,250) t.TextWrapped=true t.TextSize=16 t.Parent=parent return t
end
local function button(parent,text,size,pos)
 local b=Instance.new("TextButton") b.Text=text b.Size=size b.Position=pos b.BackgroundColor3=Color3.fromRGB(41,93,116)
 b.TextColor3=Color3.new(1,1,1) b.Font=Enum.Font.GothamBold b.TextSize=15 b.Parent=parent
 local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,8) corner.Parent=b return b
end
function UI.Init()
 local player=Players.LocalPlayer
 local gui=Instance.new("ScreenGui") gui.Name="TreadmillShop" gui.ResetOnSpawn=false gui.Parent=player.PlayerGui
 local open=button(gui,"Treadmills",UDim2.fromOffset(118,42),UDim2.new(1,-130,.48,0))
 local support=button(gui,"Feedback",UDim2.fromOffset(118,36),UDim2.new(1,-130,.48,48))
 local panel=Instance.new("Frame") panel.Name="Shop" panel.AnchorPoint=Vector2.new(.5,.5) panel.Position=UDim2.fromScale(game:GetService("UserInputService").TouchEnabled and .5 or .56,.5)
 panel.Size=UDim2.fromScale(.86,.78) panel.BackgroundColor3=Color3.fromRGB(19,27,38) panel.Visible=false panel.Parent=gui
 local cap=Instance.new("UISizeConstraint") cap.MaxSize=Vector2.new(720,650) cap.Parent=panel
 local gradient=Instance.new("UIGradient") gradient.Color=ColorSequence.new(Color3.fromRGB(255,255,255),Color3.fromRGB(170,210,255)) gradient.Rotation=90 gradient.Parent=panel
 local edge=Instance.new("UIStroke") edge.Color=Color3.fromRGB(76,172,194) edge.Thickness=2 edge.Parent=panel
 local rounded=Instance.new("UICorner") rounded.CornerRadius=UDim.new(0,14) rounded.Parent=panel
 local title=label(panel,"TREADMILLS",UDim2.new(1,-110,0,38),UDim2.fromOffset(12,8)) title.Font=Enum.Font.GothamBold
 local close=button(panel,"Close",UDim2.fromOffset(80,32),UDim2.new(1,-92,0,10))
 close.Activated:Connect(function() panel.Visible=false end)
 local hud=Instance.new("Frame") hud.Name="PlayerStats" hud.AnchorPoint=Vector2.new(0,1)
 hud.Position=UDim2.new(0,14,1,-22) hud.Size=UDim2.new(.24,0,0,104) hud.BackgroundColor3=Color3.fromRGB(18,31,45) hud.BackgroundTransparency=.12 hud.Parent=gui
 local hudSize=Instance.new("UISizeConstraint") hudSize.MinSize=Vector2.new(175,104) hudSize.MaxSize=Vector2.new(220,104) hudSize.Parent=hud
 local hudCorner=Instance.new("UICorner") hudCorner.CornerRadius=UDim.new(0,12) hudCorner.Parent=hud
 local stats=label(hud,"",UDim2.new(1,-20,1,-12),UDim2.fromOffset(10,6)) stats.TextXAlignment=Enum.TextXAlignment.Left stats.TextSize=16
 label(panel,"Train for Speed points. Movement increases gradually, up to "..Config.Treadmills.MaxWalkSpeed.." studs/s. One treadmill per plot.",UDim2.new(1,-24,0,42),UDim2.fromOffset(12,48))
 local scroll=Instance.new("ScrollingFrame") scroll.Name="Catalog" scroll.BackgroundTransparency=1 scroll.Position=UDim2.fromOffset(12,100)
 scroll.Size=UDim2.new(1,-24,1,-174) scroll.CanvasSize=UDim2.new() scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y scroll.ScrollBarThickness=6 scroll.Parent=panel
 local layout=Instance.new("UIListLayout") layout.SortOrder=Enum.SortOrder.LayoutOrder layout.Padding=UDim.new(0,8) layout.Parent=scroll
 local rows={}
 for index,tier in Config.Treadmills.Catalog do
  local row=Instance.new("Frame") row.Name=tier.Id row.Size=UDim2.new(1,-8,0,176) row.BackgroundColor3=Color3.fromRGB(35,53,70) row.LayoutOrder=index row.Parent=scroll
  local thumb=Instance.new("Frame") thumb.Name="TreadmillPicture" thumb.Size=UDim2.new(.42,-8,0,128) thumb.Position=UDim2.fromOffset(8,6) thumb.BackgroundColor3=Color3.fromRGB(185,211,227) thumb.Parent=row
  local preview=RS:WaitForChild("TreadmillPreviewTemplates"):FindFirstChild(tier.Id)
  if preview then Viewport.Create(thumb,preview,false) end
  local name=label(row,tier.Name.." | "..Format.Exact(tier.Multiplier).."x Training",UDim2.new(.58,-16,0,44),UDim2.new(.42,4,0,8)) name.TextXAlignment=Enum.TextXAlignment.Left
  local cost=tier.Cost and (tier.Cost==0 and "Free" or "$"..Format.Compact(tier.Cost)) or ("R$ "..Format.Exact(tier.ExpectedRobux).." | Not available yet")
  local details=label(row,"+"..Format.Compact(Config.Treadmills.BaseGain*tier.Multiplier).." Speed/sec | "..cost,UDim2.new(.58,-16,0,64),UDim2.new(.42,4,0,50)) details.TextXAlignment=Enum.TextXAlignment.Left details.TextSize=14
  local buy=button(row,"",UDim2.new(1,-16,0,32),UDim2.new(0,8,1,-40))
  buy.Activated:Connect(function()
   local owned=player:GetAttribute("CashTreadmillTier") or 1
   if tier.GamePassId then if tier.GamePassId<=0 then return end Remotes.TreadmillRequest:FireServer(player:GetAttribute("PremiumTreadmillOwned") and "Equip" or "Premium",tier.Id)
   else Remotes.TreadmillRequest:FireServer(index<=owned and "Equip" or "Buy",tier.Id) end
  end)
  table.insert(rows,{button=buy,index=index,tier=tier})
 end
 label(panel,"Walk onto your treadmill to train. Walk off to stop.",UDim2.new(1,-24,0,32),UDim2.new(0,12,1,-70))
 local message=label(panel,"",UDim2.new(1,-24,0,28),UDim2.new(0,12,1,-34)) message.TextSize=14
 local lastCash,lastPoints
 local function gain(text,color,y)
  local t=label(hud,text,UDim2.fromOffset(180,26),UDim2.fromOffset(8,y)) t.TextColor3=color
  game:GetService("TweenService"):Create(t,TweenInfo.new(.75),{Position=UDim2.fromOffset(8,y-26),TextTransparency=1}):Play()
  game:GetService("Debris"):AddItem(t,.8)
 end
 local function refresh()
  local st=player:FindFirstChild("leaderstats") local cash=st and st:FindFirstChild("Cash") local points=st and st:FindFirstChild("Speed")
  if cash and lastCash and cash.Value>lastCash then gain("+$"..Format.Compact(cash.Value-lastCash),Color3.fromRGB(125,255,150),-26) end
  if points and lastPoints and points.Value>lastPoints then gain("+"..Format.Compact(points.Value-lastPoints).." Speed",Color3.fromRGB(100,210,255),-54) end
  lastCash=cash and cash.Value lastPoints=points and points.Value
  hud.Visible=not panel.Visible or workspace.CurrentCamera.ViewportSize.X>=1100
  title.Text="TREADMILLS  |  $"..Format.Compact(cash and cash.Value or 0)
  stats.Text=("CASH  $%s\nSPEED  %s points\nMOVE  %.1f studs/s"):format(Format.Compact(cash and cash.Value or 0),Format.Compact(points and points.Value or 0),player:GetAttribute("MovementSpeed") or Config.BaseWalkSpeed)
  local owned=player:GetAttribute("CashTreadmillTier") or 1
  for _,row in rows do
   local tier=row.tier local selected=player:GetAttribute("TreadmillId")==tier.Id
   row.button.Text=selected and "Equipped" or tier.GamePassId and (tier.GamePassId<=0 and "Not available" or "Premium") or row.index<=owned and "Equip" or row.index==owned+1 and "Upgrade" or "Locked"
   row.button.BackgroundColor3=selected and Color3.fromRGB(44,108,74) or Color3.fromRGB(41,93,116)
  end
 end
 open.Activated:Connect(function() panel.Visible=not panel.Visible refresh() end)
 Remotes.TreadmillStatus.OnClientEvent:Connect(function(text) message.Text=text refresh() end)
 -- Small private structured-feedback panel, no free-form player messages.
 local feedback=Instance.new("Frame") feedback.Name="Feedback" feedback.AnchorPoint=Vector2.new(.5,.5) feedback.Position=UDim2.fromScale(.5,.5)
 feedback.Size=UDim2.fromScale(.8,.55) feedback.BackgroundColor3=Color3.fromRGB(19,27,38) feedback.Visible=false feedback.Parent=gui
 local constraint=Instance.new("UISizeConstraint") constraint.MaxSize=Vector2.new(500,440) constraint.Parent=feedback
 label(feedback,"PRIVATE FEEDBACK",UDim2.new(1,0,0,38),UDim2.fromOffset(0,10))
 local category=1 local target=0
 local categoryButton=button(feedback,Config.PlayerData.FeedbackCategories[category],UDim2.new(1,-32,0,44),UDim2.fromOffset(16,60))
 categoryButton.Activated:Connect(function() category=category%#Config.PlayerData.FeedbackCategories+1 categoryButton.Text=Config.PlayerData.FeedbackCategories[category] end)
 local targetButton=button(feedback,"Player: none",UDim2.new(1,-32,0,44),UDim2.fromOffset(16,116))
 targetButton.Activated:Connect(function()
  local options={0} for _,p in Players:GetPlayers() do if p~=player then table.insert(options,p.UserId) end end
  local index=table.find(options,target) or 1 target=options[index%#options+1]
  local p=Players:GetPlayerByUserId(target) targetButton.Text="Player: "..(p and p.DisplayName or "none")
 end)
 local feedbackMessage=label(feedback,"For urgent safety issues, also use Roblox's Report Abuse menu.",UDim2.new(1,-32,0,68),UDim2.fromOffset(16,170))
 local send=button(feedback,"Send",UDim2.new(.45,-20,0,40),UDim2.new(0,16,1,-55))
 local back=button(feedback,"Close",UDim2.new(.45,-20,0,40),UDim2.new(.55,4,1,-55))
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
