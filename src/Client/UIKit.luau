-- Shared visuals from the supplied UI packs, with resize-safe motion and menu coordination.
local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Theme=Config.UITheme
local Format=require(game.ReplicatedStorage.Shared.NumberFormat)
local Assets=game.ReplicatedStorage:WaitForChild("UIAssets")
local ButtonTemplate=Assets:WaitForChild("ButtonTemplate")
local Kit={}
local windows={}
local nav,navMore
local screens,kept={},{} -- registered ScreenGuis (with their ViewportScale) and those that stay visible when the UI is hidden
local view,uiScale,hidden,scheduled,cameraSignal=Vector2.new(1280,720),1,false,false,nil
local resizeListeners={}

--- Usable screen size in UI units: the real size inside Roblox's reserved areas (top bar, capture buttons) divided by the UI scale.
function Kit.Viewport() return view end

local function refresh()
 scheduled=false
 local probe
 for gui in screens do if gui.Parent then probe=gui break end end
 local camera=workspace.CurrentCamera
 local size=probe and probe.AbsoluteSize or camera and camera.ViewportSize
 if not size or size.X<=0 or size.Y<=0 then return end
 local S=Config.UIScreen
 uiScale=math.clamp(math.min(size.X/S.ReferenceX,size.Y/S.ReferenceY),S.MinScale,S.MaxScale)
 view=size/uiScale
 for _,viewportScale in screens do viewportScale.Scale=uiScale end
 for _,fn in resizeListeners do fn(view) end
end
local function queue() if not scheduled then scheduled=true task.defer(refresh) end end -- resize events arrive in bursts: one refresh per frame
local function bindCamera()
 if cameraSignal then cameraSignal:Disconnect() end
 local camera=workspace.CurrentCamera
 if camera then cameraSignal=camera:GetPropertyChangedSignal("ViewportSize"):Connect(queue) end
 queue()
end

function Kit.OnResize(callback)
 table.insert(resizeListeners,callback)
 callback(view)
end

--- Registers a ScreenGui right after it is parented: it stays out of Roblox's reserved areas (CoreUISafeInsets), follows one live UIScale driven by the
--- viewport size and is hidden by the hide toggle unless `keepVisible`.
function Kit.Screen(gui,keepVisible)
 gui.ResetOnSpawn=false gui.IgnoreGuiInset=false gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
 local scale=Instance.new("UIScale") scale.Name="ViewportScale" scale.Parent=gui
 screens[gui]=scale
 if keepVisible then kept[gui]=true elseif hidden then gui.Enabled=false end
 gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(queue)
 gui.Destroying:Connect(function() screens[gui]=nil kept[gui]=nil end)
 if not cameraSignal then
  workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
  bindCamera()
 end
 queue()
end

--- True when custom UI may be shown: no menu is open and the hide toggle is off (for guis that switch themselves with the menu).
function Kit.Visible() return not hidden and not Players.LocalPlayer.PlayerGui:GetAttribute("MenuOpen") end

--- Text without a box: white (kind nil), "gold" for highlights or "warn" for warnings, always with the dark outline.
function Kit.Text(label,kind)
 label.BackgroundTransparency=1 label.BorderSizePixel=0
 for _,child in label:GetChildren() do if child:IsA("UICorner") or child:IsA("UIStroke") then child:Destroy() end end
 label.TextColor3=kind=="gold" and Theme.TextGold or kind=="warn" and Theme.TextWarn or Theme.TextMain
 label.Font=Enum.Font.FredokaOne label.TextStrokeTransparency=1
 local stroke=Instance.new("UIStroke") stroke.Name="Outline" stroke.Color=Theme.Outline stroke.Thickness=Theme.OutlineThickness stroke.Parent=label
 return label
end

--- Fades a Kit.Text label and its outline to `to` (0 = shown, 1 = gone).
function Kit.Fade(label,seconds,to)
 local info=TweenInfo.new(seconds)
 TweenService:Create(label,info,{TextTransparency=to}):Play()
 local stroke=label:FindFirstChild("Outline")
 if stroke then TweenService:Create(stroke,info,{Transparency=to}):Play() end
end

--- The corner eye button that hides every custom ScreenGui (and H on a keyboard); tap again to bring them back. Never hides itself.
function Kit.HideToggle()
 local S=Config.UIScreen
 local playerGui=Players.LocalPlayer:WaitForChild("PlayerGui")
 local gui=Instance.new("ScreenGui") gui.Name="UIToggle" gui.DisplayOrder=100 gui.Parent=playerGui
 Kit.Screen(gui,true)
 local button=Instance.new("TextButton") button.Name="Eye" button.Text="" button.AutoButtonColor=false button.BackgroundTransparency=1
 button.Position=UDim2.fromOffset(S.EyeMargin,S.EyeMargin) button.Size=UDim2.fromOffset(S.EyeSize,S.EyeSize) button.Parent=gui
 Instance.new("UIAspectRatioConstraint",button)
 local function shape(size,fill,rotation) -- a white shape on a dark outline: the dark stroke is drawn first, the white one on top
  local outer=Instance.new("Frame") outer.AnchorPoint=Vector2.new(.5,.5) outer.Position=UDim2.fromScale(.5,.5) outer.Size=size outer.Rotation=rotation or 0
  outer.BackgroundTransparency=fill and 0 or 1 outer.BackgroundColor3=Theme.TextMain outer.BorderSizePixel=0 outer.Parent=button
  Instance.new("UICorner",outer).CornerRadius=UDim.new(1,0)
  local dark=Instance.new("UIStroke") dark.Color=Theme.Outline dark.Thickness=fill and 3 or 6 dark.Parent=outer
  if fill then return outer end
  local inner=outer:Clone() inner.Parent=button
  inner.UIStroke.Color=Theme.TextMain inner.UIStroke.Thickness=3
  return outer
 end
 shape(UDim2.fromScale(.92,.54))
 shape(UDim2.fromScale(.24,.24),true)
 local slash=shape(UDim2.fromScale(1.05,.1),true,-45) slash.Visible=false
 local function set(value)
  hidden=value
  playerGui:SetAttribute("UIHidden",hidden)
  for other in screens do if not kept[other] then other.Enabled=not hidden end end
  slash.Visible=hidden
 end
 button.Activated:Connect(function() set(not hidden) end)
 Input.InputBegan:Connect(function(input,processed)
  if not processed and input.KeyCode==S.EyeKey and not Input:GetFocusedTextBox() then set(not hidden) end
 end)
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
  Kit.Screen(root)
  local function column(name)
   local f=Instance.new("Frame") f.Name=name f.AnchorPoint=Vector2.new(1,.5) f.Position=UDim2.new(1,0,.5,0)
   f.BackgroundTransparency=1 f.AutomaticSize=Enum.AutomaticSize.Y f.Parent=root
   local layout=Instance.new("UIListLayout") layout.Padding=UDim.new(0,Theme.NavGap) layout.SortOrder=Enum.SortOrder.LayoutOrder layout.Parent=f
   return f
  end
  nav=column("Dock") navMore=column("MoreMenu") navMore.Visible=false
  Kit.OnResize(function(view)
   local w=view.X<Theme.CompactWidth and Theme.NavCompactWidth or Theme.NavWidth
   nav.Size=UDim2.fromOffset(w,0) -- the height follows the button count
   navMore.Size=UDim2.fromOffset(w,0)
   local edge=Config.UIScreen.CaptureReserve/uiScale -- Roblox's capture buttons keep their size in pixels, so the reserve is divided by the UI scale
   nav.Position=UDim2.new(1,-edge,.5,0)
   navMore.Position=UDim2.new(1,-edge-w-Theme.NavGap,.5,0)
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
