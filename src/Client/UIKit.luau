-- Shared visuals from the supplied UI packs, with resize-safe motion and menu coordination.
local Players=game:GetService("Players")
local GuiService=game:GetService("GuiService")
local TweenService=game:GetService("TweenService")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Theme=Config.UITheme
local Format=require(game.ReplicatedStorage.Shared.NumberFormat)
local Assets=game.ReplicatedStorage:WaitForChild("UIAssets")
local ButtonTemplate=Assets:WaitForChild("ButtonTemplate")
local Kit={}
local windows={}
local nav,navMore
local viewportSignal
local resizeListeners={}

function Kit.Viewport()
 local camera=workspace.CurrentCamera
 local viewport=camera and camera.ViewportSize or Vector2.new(1280,720)
 local topLeft,bottomRight=GuiService:GetGuiInset()
 return viewport-topLeft-bottomRight
end

function Kit.OnResize(callback)
 table.insert(resizeListeners,callback)
 callback(Kit.Viewport())
 if not viewportSignal then
  local function bind()
   if viewportSignal then viewportSignal:Disconnect() end
   local camera=workspace.CurrentCamera
   if camera then viewportSignal=camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    for _,fn in resizeListeners do fn(Kit.Viewport()) end
   end) end
   for _,fn in resizeListeners do fn(Kit.Viewport()) end
  end
  workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bind)
  bind()
 end
end

function Kit.Card(frame)
 frame.BackgroundColor3=Theme.Card
 frame.BorderSizePixel=0
 if not frame:FindFirstChildWhichIsA("UICorner") then
  local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,12) corner.Parent=frame
 end
 if not frame:FindFirstChildWhichIsA("UIStroke") then
  local stroke=Instance.new("UIStroke") stroke.Color=Theme.Border stroke.Transparency=.25 stroke.Parent=frame
 end
 local edge=frame:FindFirstChildWhichIsA("UIStroke") edge.Color=Theme.Border edge.Transparency=.25
end

function Kit.Icon(parent,name,size,pos)
 local image=Instance.new("ImageLabel")
 image.Name="Icon" image.BackgroundTransparency=1 image.Image=Theme.Icons[name] or ""
 image.ImageColor3=Theme.Text image.ScaleType=Enum.ScaleType.Fit image.Size=size image.Position=pos image.Parent=parent
 return image
end

function Kit.Animate(button)
 if button:GetAttribute("MotionStyled") then return end
 button:SetAttribute("MotionStyled",true)
 local scale=button:FindFirstChildWhichIsA("UIScale") or Instance.new("UIScale")
 scale.Name="MotionScale" scale.Parent=button
 local tween
 local iconTween
 local hovering=false
 local function iconMotion(angle)
  local icon=button:FindFirstChild("Icon")
  if icon and icon:IsA("ImageLabel") then
   if iconTween then iconTween:Cancel() end
   iconTween=TweenService:Create(icon,TweenInfo.new(Theme.MotionSeconds),{Rotation=angle}) iconTween:Play()
  end
 end
 local function move(value)
  if tween then tween:Cancel() end
  tween=TweenService:Create(scale,TweenInfo.new(Theme.MotionSeconds,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=value})
  tween:Play()
 end
 button.MouseEnter:Connect(function() hovering=true if button.Active then iconMotion(-8) move(Theme.HoverScale) end end)
 button.MouseLeave:Connect(function() hovering=false iconMotion(0) move(1) end)
 button.SelectionGained:Connect(function() if button.Active then iconMotion(-8) move(Theme.HoverScale) end end)
 button.SelectionLost:Connect(function() iconMotion(0) move(1) end)
 button.InputBegan:Connect(function(input)
  if button.Active and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then move(Theme.PressScale) end
 end)
 button.InputEnded:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then move(hovering and Theme.HoverScale or 1) end
 end)
 button.Activated:Connect(function()
  if button.Active then
   local flash=Instance.new("Frame") flash.Name="PressFlash" flash.Size=UDim2.fromScale(1,1) flash.BackgroundColor3=Color3.new(1,1,1) flash.BackgroundTransparency=.65 flash.BorderSizePixel=0 flash.ZIndex=button.ZIndex+1 flash.Parent=button
   local round=Instance.new("UICorner") round.CornerRadius=UDim.new(0,10) round.Parent=flash
   local fade=TweenService:Create(flash,TweenInfo.new(Theme.WindowSeconds),{BackgroundTransparency=1}) fade:Play()
   game:GetService("Debris"):AddItem(flash,Theme.WindowSeconds)
  end
  if button.Active then move(Theme.PressScale) task.delay(Theme.MotionSeconds,function() if button.Parent then move(hovering and Theme.HoverScale or 1) end end) end
 end)
end

function Kit.Label(parent,text,size,pos)
 local t=Instance.new("TextLabel") t.Text=text t.Size=size t.Position=pos t.BackgroundTransparency=1
 t.Font=Enum.Font.BuilderSans t.TextColor3=Theme.Text t.TextWrapped=true t.TextSize=16 t.Parent=parent
 return t
end

function Kit.Button(parent,text,size,pos)
 local b=ButtonTemplate:Clone()
 b.AnchorPoint=Vector2.zero
 b.Name="TextButton" b.Text=text b.Size=size b.Position=pos b.Rotation=0 b.Visible=true
 b.BackgroundColor3=Theme.Button b.TextColor3=Theme.Text b.Font=Enum.Font.FredokaOne b.TextSize=15
 b.TextWrapped=true b.AutoButtonColor=false
 local corner=b:FindFirstChildWhichIsA("UICorner") if corner then corner.CornerRadius=UDim.new(0,10) end
 local stroke=b:FindFirstChildWhichIsA("UIStroke") if stroke then stroke.Color=Theme.Border stroke.Thickness=1 stroke.Transparency=.25 end
 local gradient=b:FindFirstChildWhichIsA("UIGradient") if gradient then gradient.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(255,226,165)) gradient.Rotation=90 end
 if text=="Close" or text=="Cancel" then b.BackgroundColor3=Theme.Card end
 b.Parent=parent
 Kit.Animate(b)
 return b
end

-- more=true puts the button in the popup behind the "More" button, so the dock stays short on phones
function Kit.Nav(gui,text,icon,order,more)
 if not nav then
  local root=Instance.new("ScreenGui") root.Name="GameNavigation" root.ResetOnSpawn=false root.DisplayOrder=3 root.Parent=Players.LocalPlayer.PlayerGui
  local function column(name,x)
   local f=Instance.new("Frame") f.Name=name f.AnchorPoint=Vector2.new(1,.5) f.Position=UDim2.new(1,x,.5,0)
   f.BackgroundTransparency=1 f.AutomaticSize=Enum.AutomaticSize.Y f.Parent=root
   local layout=Instance.new("UIListLayout") layout.Padding=UDim.new(0,Theme.NavGap) layout.SortOrder=Enum.SortOrder.LayoutOrder layout.Parent=f
   return f
  end
  nav=column("Dock",-16) navMore=column("MoreMenu",-16-Theme.NavGap) navMore.Visible=false
  Kit.OnResize(function(view)
   local w=view.X<Theme.CompactWidth and Theme.NavCompactWidth or Theme.NavWidth
   nav.Size=UDim2.fromOffset(w,0) -- the height follows the button count
   navMore.Size=UDim2.fromOffset(w,0)
   navMore.Position=UDim2.new(1,-16-w-Theme.NavGap,.5,0)
  end)
  local toggle=Kit.Nav(nil,"More","",Theme.NavMoreOrder)
  toggle.Activated:Connect(function() navMore.Visible=not navMore.Visible end)
 end
 local b=Kit.Button(more and navMore or nav,text,UDim2.new(1,0,0,Theme.NavHeight),UDim2.new())
 if more then b.Activated:Connect(function() navMore.Visible=false end) end
 b.Name=text b.LayoutOrder=order b.TextXAlignment=Enum.TextXAlignment.Left
 local padding=Instance.new("UIPadding") padding.PaddingLeft=UDim.new(0,38) padding.PaddingRight=UDim.new(0,5) padding.Parent=b
 Kit.Icon(b,icon,UDim2.fromOffset(20,20),UDim2.new(0,-29,.5,-10))
 return b
end

function Kit.PriceLabel(id)
 local price=game.ReplicatedStorage:GetAttribute("PassPrice_"..id) or 0
 return price,price>0 and "R$ "..Format.Exact(price) or price<0 and "Price unavailable" or "Not available yet"
end

function Kit.State(b,text,selected,enabled)
 b.Text=text b.Active=enabled b.AutoButtonColor=false
 b.TextColor3=selected and Color3.new(1,1,1) or Theme.Text
 b.BackgroundColor3=selected and Theme.Selected or enabled and Theme.Button or Theme.Disabled
 local stroke=b:FindFirstChildWhichIsA("UIStroke")
 if stroke then stroke.Transparency=selected and .15 or .65 end
end

function Kit.Window(panel)
 panel.AnchorPoint=Vector2.new(.5,.5) panel.Position=UDim2.fromScale(.5,.5)
 panel.BackgroundColor3=Theme.Background
 Kit.Card(panel)
 panel.BackgroundColor3=Theme.Background
 local scale=Instance.new("UIScale") scale.Name="WindowMotion" scale.Parent=panel
 local gui=panel:FindFirstAncestorOfClass("ScreenGui")
 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 local shade=Instance.new("Frame") shade.Name="ModalShade" shade.Size=UDim2.fromScale(1,1)
 shade.Active=true shade.BackgroundColor3=Color3.new(0,0,0) shade.BackgroundTransparency=1 shade.BorderSizePixel=0 shade.Visible=false shade.ZIndex=1 shade.Parent=gui
 panel.ZIndex=2
 windows[panel]=true
 Kit.OnResize(function(view)
  if not panel.Parent then return end
  panel.Size=UDim2.fromOffset(math.min(Theme.WindowWidth,view.X-Theme.Margin*2),math.min(Theme.WindowHeight,view.Y-Theme.Margin*2))
 end)
 panel:GetPropertyChangedSignal("Visible"):Connect(function()
  shade.Visible=panel.Visible
  if panel.Visible then
   for other in windows do if other~=panel and other.Parent then other.Visible=false end end
   gui.DisplayOrder=20
   Players.LocalPlayer.PlayerGui:SetAttribute("MenuOpen",true)
   if nav then nav.Visible=false end
   scale.Scale=.96
   TweenService:Create(scale,TweenInfo.new(Theme.WindowSeconds,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
  else
   local anyOpen=false
   for other in windows do if other.Parent and other.Visible then anyOpen=true break end end
   if not anyOpen then
    Players.LocalPlayer.PlayerGui:SetAttribute("MenuOpen",false)
    if nav then nav.Visible=true end
    gui.DisplayOrder=0
   end
  end
 end)
end

function Kit.Panel(gui,name,title,hint,footer)
 local panel=Instance.new("Frame") panel.Name=name panel.Visible=false panel.Parent=gui
 Kit.Window(panel)
 local heading=Kit.Label(panel,title,UDim2.new(1,-116,0,38),UDim2.fromOffset(18,10)) heading.Font=Enum.Font.FredokaOne heading.TextSize=21 heading.TextXAlignment=Enum.TextXAlignment.Left
 heading.TextScaled=true
 local textLimit=Instance.new("UITextSizeConstraint") textLimit.MinTextSize=14 textLimit.MaxTextSize=21 textLimit.Parent=heading
 local close=Kit.Button(panel,"Close",UDim2.fromOffset(80,44),UDim2.new(1,-96,0,12))
 close.Name="Close"
 close.Activated:Connect(function() panel.Visible=false end)
 local note=Kit.Label(panel,hint,UDim2.new(1,-36,0,42),UDim2.fromOffset(18,52)) note.TextSize=14 note.TextColor3=Theme.Muted note.TextXAlignment=Enum.TextXAlignment.Left
 local scroll=Instance.new("ScrollingFrame") scroll.Name="Catalog" scroll.BackgroundTransparency=1 scroll.BorderSizePixel=0 scroll.Position=UDim2.fromOffset(16,104)
 scroll.Size=UDim2.new(1,-32,1,-(104+footer)) scroll.CanvasSize=UDim2.new() scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
 scroll.ScrollBarThickness=4 scroll.ScrollBarImageColor3=Theme.Accent scroll.Parent=panel
 local layout=Instance.new("UIListLayout") layout.SortOrder=Enum.SortOrder.LayoutOrder layout.Padding=UDim.new(0,10) layout.Parent=scroll
 scroll.ChildAdded:Connect(function(child) if child:IsA("Frame") then Kit.Card(child) end end)
 return panel,heading,scroll
end

-- Fixed vertical lanes, proportional image/text columns. Minimum useful width is 280px.
function Kit.Product(parent,id,order,extra)
 local row=Instance.new("Frame") row.Name=id row.LayoutOrder=order row.Size=UDim2.new(1,-8,0,extra and 254 or 204) row.Parent=parent Kit.Card(row)
 local art=Instance.new("Frame") art.Name="Picture" art.Position=UDim2.fromOffset(12,12) art.Size=UDim2.new(.38,-16,0,126) art.ClipsDescendants=true art.Parent=row Kit.Card(art) art.BackgroundColor3=Theme.Preview
 local name=Kit.Label(row,"",UDim2.new(.62,-24,0,44),UDim2.new(.38,8,0,12)) name.Name="ProductName" name.Font=Enum.Font.FredokaOne name.TextSize=18 name.TextXAlignment=Enum.TextXAlignment.Left name.TextScaled=true
 local limit=Instance.new("UITextSizeConstraint") limit.MinTextSize=12 limit.MaxTextSize=18 limit.Parent=name
 local details=Kit.Label(row,"",UDim2.new(.62,-24,0,76),UDim2.new(.38,8,0,60)) details.Name="Details" details.TextSize=14 details.TextColor3=Theme.Muted details.TextXAlignment=Enum.TextXAlignment.Left details.TextYAlignment=Enum.TextYAlignment.Top
 local action=Kit.Button(row,"",UDim2.new(1,-24,0,44),UDim2.new(0,12,1,-56)) action.Name="Action"
 return row,art,name,details,action
end

return Kit
