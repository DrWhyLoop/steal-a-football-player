-- Index book: every roster character with its variant combinations (silhouettes until collected) plus the daily reward.
-- Image-first: a roster entry's optional PortraitImage is used when present, otherwise a model preview. Built from the
-- roster and Config only, one page of cells at a time, so it scales to hundreds of characters.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Shared.Config)
local Remotes=require(RS.Shared.Remotes)
local Format=require(RS.Shared.NumberFormat)
local Keys=require(RS.Shared.IndexKeys)
local UIKit=require(script.Parent.UIKit)
local Viewport=require(script.Parent.ModelViewport)
local label,button=UIKit.Label,UIKit.Button
local UI={}
local MISSING=Color3.fromRGB(60,64,72)
local function corner(parent,radius) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,radius) c.Parent=parent end

function UI.Init()
 local player=Players.LocalPlayer
 local state={index={},claimed={},daily={Ready=false,Streak=0,Reward=0}}
 local tier,page=nil,1
 for _,name in Config.TierOrder do if Keys.ByTier[name] then tier=tier or name end end

 local gui=Instance.new("ScreenGui") gui.Name="IndexBook" gui.ResetOnSpawn=false gui.Parent=player:WaitForChild("PlayerGui")
 local open=button(gui,"Index",UDim2.fromOffset(118,36),UDim2.new(1,-130,.48,-46))
 local dot=Instance.new("Frame") dot.Name="DailyDot" dot.Size=UDim2.fromOffset(14,14) dot.Position=UDim2.new(1,-8,0,-6) dot.BackgroundColor3=Color3.fromRGB(255,70,70) dot.Visible=false dot.Parent=open
 corner(dot,7)
 local panel=Instance.new("Frame") panel.Name="Book" panel.AnchorPoint=Vector2.new(.5,.5) panel.Position=UDim2.fromScale(game:GetService("UserInputService").TouchEnabled and .5 or .56,.5)
 panel.Size=UDim2.fromScale(.86,.8) panel.BackgroundColor3=Color3.fromRGB(19,27,38) panel.Visible=false panel.Parent=gui
 local cap=Instance.new("UISizeConstraint") cap.MaxSize=Vector2.new(760,660) cap.Parent=panel
 local edge=Instance.new("UIStroke") edge.Color=Color3.fromRGB(76,172,194) edge.Thickness=2 edge.Parent=panel
 corner(panel,14)
 local title=label(panel,"INDEX",UDim2.new(1,-110,0,34),UDim2.fromOffset(12,8)) title.Font=Enum.Font.GothamBold title.TextXAlignment=Enum.TextXAlignment.Left title.TextSize=20
 local close=button(panel,"Close",UDim2.fromOffset(80,32),UDim2.new(1,-92,0,10))
 local charTab=button(panel,"Characters",UDim2.new(.5,-16,0,36),UDim2.fromOffset(12,46))
 local dailyTab=button(panel,"Daily reward",UDim2.new(.5,-16,0,36),UDim2.new(.5,4,0,46))

 -- characters page
 local chars=Instance.new("Frame") chars.BackgroundTransparency=1 chars.Size=UDim2.new(1,-16,1,-94) chars.Position=UDim2.fromOffset(8,88) chars.Parent=panel
 local tierRow=Instance.new("ScrollingFrame") tierRow.BackgroundTransparency=1 tierRow.Size=UDim2.new(1,0,0,40) tierRow.CanvasSize=UDim2.new() tierRow.AutomaticCanvasSize=Enum.AutomaticSize.X
 tierRow.ScrollBarThickness=0 tierRow.ScrollingDirection=Enum.ScrollingDirection.X tierRow.Parent=chars
 local tierLayout=Instance.new("UIListLayout") tierLayout.FillDirection=Enum.FillDirection.Horizontal tierLayout.SortOrder=Enum.SortOrder.LayoutOrder tierLayout.Padding=UDim.new(0,6) tierLayout.Parent=tierRow
 local grid=Instance.new("ScrollingFrame") grid.BackgroundTransparency=1 grid.Position=UDim2.fromOffset(0,46) grid.Size=UDim2.new(1,0,1,-96) grid.CanvasSize=UDim2.new() grid.AutomaticCanvasSize=Enum.AutomaticSize.Y
 grid.ScrollBarThickness=6 grid.Parent=chars
 local gridLayout=Instance.new("UIGridLayout") gridLayout.CellSize=UDim2.fromOffset(170,206) gridLayout.CellPadding=UDim2.fromOffset(8,8) gridLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center gridLayout.Parent=grid
 local prev=button(chars,"<",UDim2.fromOffset(60,38),UDim2.new(0,0,1,-42))
 local pageLabel=label(chars,"",UDim2.new(1,-140,0,38),UDim2.new(0,70,1,-42))
 local nextPage=button(chars,">",UDim2.fromOffset(60,38),UDim2.new(1,-60,1,-42))

 -- daily page
 local daily=Instance.new("Frame") daily.BackgroundTransparency=1 daily.Size=chars.Size daily.Position=chars.Position daily.Visible=false daily.Parent=panel
 local dailyTitle=label(daily,"Daily reward",UDim2.new(1,0,0,36),UDim2.fromOffset(0,20)) dailyTitle.Font=Enum.Font.GothamBold dailyTitle.TextSize=24
 local streakLabel=label(daily,"",UDim2.new(1,0,0,34),UDim2.fromOffset(0,64)) streakLabel.TextSize=20
 local claim=button(daily,"",UDim2.fromOffset(260,52),UDim2.new(.5,-130,0,120)) claim.TextSize=20
 local dailyNote=label(daily,"A free reward once per day. Missing a day only resets your streak.",UDim2.new(1,-20,0,50),UDim2.fromOffset(10,190))

 local function have(entry) return (state.index[entry.Id] or 0)~=0 end
 local function progress(name)
  local got=0 for _,entry in Keys.ByTier[name] do if have(entry) then got+=1 end end
  return got,#Keys.ByTier[name]
 end
 local function cell(entry)
  local mask=state.index[entry.Id] or 0
  local got=mask~=0
  local frame=Instance.new("Frame") frame.Name=entry.Id frame.BackgroundColor3=Color3.fromRGB(35,53,70) frame.Parent=grid corner(frame,10)
  local art=Instance.new("Frame") art.Size=UDim2.new(1,-12,0,128) art.Position=UDim2.fromOffset(6,6) art.BackgroundColor3=Color3.fromRGB(185,211,227) art.ClipsDescendants=true art.Parent=frame
  local template=RS:FindFirstChild("PlayerRevealTemplates") and RS.PlayerRevealTemplates:FindFirstChild(entry.Id)
  if entry.PortraitImage then
   local image=Instance.new("ImageLabel") image.Name="Portrait" image.Size=UDim2.fromScale(1,1) image.BackgroundTransparency=1 image.Image=entry.PortraitImage
   image.ScaleType=Enum.ScaleType.Fit image.ImageColor3=got and Color3.new(1,1,1) or Color3.new(0,0,0) image.Parent=art
  elseif template then Viewport.Create(art,template,true,not got)
  else label(art,"?",UDim2.fromScale(1,1),UDim2.new()).TextSize=40 end
  local name=label(frame,got and entry.Name or "???",UDim2.new(1,-8,0,26),UDim2.fromOffset(4,138))
  name.Font=Enum.Font.GothamBold name.TextSize=15 name.TextColor3=got and Config.Tiers[entry.Tier].Color or Color3.fromRGB(150,155,165)
  local chips=Instance.new("Frame") chips.Name="Variants" chips.BackgroundTransparency=1 chips.Size=UDim2.new(1,-8,0,24) chips.Position=UDim2.fromOffset(4,170) chips.Parent=frame
  local list=Instance.new("UIListLayout") list.FillDirection=Enum.FillDirection.Horizontal list.HorizontalAlignment=Enum.HorizontalAlignment.Center list.SortOrder=Enum.SortOrder.LayoutOrder list.Padding=UDim.new(0,4) list.Parent=chips
  for order,variant in Keys.List do
   local lit=bit32.btest(mask,bit32.lshift(1,variant.Bit))
   local chip=Instance.new("TextLabel") chip.Name=variant.Name chip.LayoutOrder=order chip.Size=UDim2.fromOffset(22,22) chip.Font=Enum.Font.GothamBold chip.TextSize=12 chip.TextColor3=Color3.new(0,0,0)
   chip.Text=variant.Giant and "G" or "" chip.BackgroundColor3=lit and (variant.Variant and Config.Variants[variant.Variant].Tint or Color3.new(1,1,1)) or MISSING chip.Parent=chips corner(chip,6)
  end
 end
 local function render()
  local owned,total=0,#Config.PlayerRoster
  for _,entry in Config.PlayerRoster do if have(entry) then owned+=1 end end
  title.Text=("INDEX  |  %d / %d collected"):format(owned,total)
  for _,child in tierRow:GetChildren() do if child:IsA("TextButton") then
   local got,count=progress(child.Name)
   child.Text=("%s %d/%d%s"):format(child.Name,got,count,state.claimed[child.Name] and " ✓" or "")
   child.BackgroundColor3=child.Name==tier and Config.Tiers[child.Name].Color or Color3.fromRGB(41,60,78)
   child.TextColor3=child.Name==tier and Color3.new(0,0,0) or Color3.new(1,1,1)
  end end
  for _,child in grid:GetChildren() do if child:IsA("Frame") then child:Destroy() end end
  local list=Keys.ByTier[tier]
  local perPage=Config.Index.PerPage
  local pages=math.max(1,math.ceil(#list/perPage))
  page=math.clamp(page,1,pages)
  for i=(page-1)*perPage+1,math.min(#list,page*perPage) do cell(list[i]) end
  local reward=Config.Index.TierRewards[tier] or 0
  pageLabel.Text=("Page %d / %d  |  %s tier reward: $%s %s"):format(page,pages,tier,Format.Compact(reward),state.claimed[tier] and "(claimed)" or "")
  prev.Active=page>1 prev.BackgroundColor3=page>1 and Color3.fromRGB(41,93,116) or MISSING
  nextPage.Active=page<pages nextPage.BackgroundColor3=page<pages and Color3.fromRGB(41,93,116) or MISSING
 end
 local function renderDaily()
  local d=state.daily
  dot.Visible=d.Ready
  streakLabel.Text=("Streak: %d day%s"):format(d.Streak,d.Streak==1 and "" or "s")
  claim.Text=d.Ready and ("Claim $"..Format.Compact(d.Reward)) or "Claimed today. Come back tomorrow."
  claim.Active=d.Ready claim.BackgroundColor3=d.Ready and Color3.fromRGB(44,108,74) or MISSING
 end
 for order,name in Config.TierOrder do
  if Keys.ByTier[name] then
   local b=button(tierRow,name,UDim2.fromOffset(120,38),UDim2.new()) b.Name=name b.LayoutOrder=order b.TextSize=14
   b.Activated:Connect(function() tier=name page=1 render() end)
  end
 end
 local function show(tab)
  chars.Visible=tab=="chars" daily.Visible=tab=="daily"
  charTab.BackgroundColor3=tab=="chars" and Color3.fromRGB(44,108,74) or Color3.fromRGB(41,93,116)
  dailyTab.BackgroundColor3=tab=="daily" and Color3.fromRGB(44,108,74) or Color3.fromRGB(41,93,116)
 end
 charTab.Activated:Connect(function() show("chars") end)
 dailyTab.Activated:Connect(function() show("daily") end)
 prev.Activated:Connect(function() if page>1 then page-=1 render() end end)
 nextPage.Activated:Connect(function() page+=1 render() end)
 claim.Activated:Connect(function() if state.daily.Ready then Remotes.DailyClaim:FireServer() end end)
 close.Activated:Connect(function() panel.Visible=false end)
 open.Activated:Connect(function()
  panel.Visible=not panel.Visible
  if panel.Visible then Remotes.IndexRequest:FireServer() show("chars") render() renderDaily() end
 end)
 Remotes.IndexSync.OnClientEvent:Connect(function(index,claimed)
  for id,mask in index or {} do state.index[id]=mask end
  for name,done in claimed or {} do state.claimed[name]=done end
  if panel.Visible and chars.Visible then render() end
 end)
 Remotes.DailyStatus.OnClientEvent:Connect(function(status) state.daily=status renderDaily() end)
 render() renderDaily()
 Remotes.IndexRequest:FireServer()
end
return UI
