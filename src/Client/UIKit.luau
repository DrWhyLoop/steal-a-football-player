-- Shared plain-menu widgets (labels, buttons) so menus look and behave alike.
local Kit={}
function Kit.Label(parent,text,size,pos)
 local t=Instance.new("TextLabel") t.Text=text t.Size=size t.Position=pos t.BackgroundTransparency=1
 t.Font=Enum.Font.Gotham t.TextColor3=Color3.fromRGB(235,240,250) t.TextWrapped=true t.TextSize=16 t.Parent=parent return t
end
function Kit.Button(parent,text,size,pos)
 local b=Instance.new("TextButton") b.Text=text b.Size=size b.Position=pos b.BackgroundColor3=Color3.fromRGB(41,93,116)
 b.TextColor3=Color3.new(1,1,1) b.Font=Enum.Font.GothamBold b.TextSize=15 b.Parent=parent
 local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,8) corner.Parent=b return b
end
-- Shop button state: label plus enabled/selected colouring.
function Kit.State(b,text,selected,enabled)
 b.Text=text b.Active=enabled b.AutoButtonColor=enabled
 b.BackgroundColor3=selected and Color3.fromRGB(44,108,74) or enabled and Color3.fromRGB(41,93,116) or Color3.fromRGB(70,76,84)
end
-- Standard shop window: title, Close button, hint line and a scrolling list of rows. `footer` is the height reserved under the list.
-- Returns panel, title label, scroll.
function Kit.Panel(gui,name,title,hint,footer)
 local panel=Instance.new("Frame") panel.Name=name panel.AnchorPoint=Vector2.new(.5,.5) panel.Position=UDim2.fromScale(game:GetService("UserInputService").TouchEnabled and .5 or .56,.5)
 panel.Size=UDim2.fromScale(.86,.78) panel.BackgroundColor3=Color3.fromRGB(19,27,38) panel.Visible=false panel.Parent=gui
 local cap=Instance.new("UISizeConstraint") cap.MaxSize=Vector2.new(720,650) cap.Parent=panel
 local gradient=Instance.new("UIGradient") gradient.Color=ColorSequence.new(Color3.fromRGB(255,255,255),Color3.fromRGB(170,210,255)) gradient.Rotation=90 gradient.Parent=panel
 local edge=Instance.new("UIStroke") edge.Color=Color3.fromRGB(76,172,194) edge.Thickness=2 edge.Parent=panel
 local rounded=Instance.new("UICorner") rounded.CornerRadius=UDim.new(0,14) rounded.Parent=panel
 local heading=Kit.Label(panel,title,UDim2.new(1,-110,0,38),UDim2.fromOffset(12,8)) heading.Font=Enum.Font.GothamBold
 Kit.Button(panel,"Close",UDim2.fromOffset(80,32),UDim2.new(1,-92,0,10)).Activated:Connect(function() panel.Visible=false end)
 Kit.Label(panel,hint,UDim2.new(1,-24,0,42),UDim2.fromOffset(12,48))
 local scroll=Instance.new("ScrollingFrame") scroll.Name="Catalog" scroll.BackgroundTransparency=1 scroll.Position=UDim2.fromOffset(12,100)
 scroll.Size=UDim2.new(1,-24,1,-(100+footer)) scroll.CanvasSize=UDim2.new() scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y scroll.ScrollBarThickness=6 scroll.Parent=panel
 local layout=Instance.new("UIListLayout") layout.SortOrder=Enum.SortOrder.LayoutOrder layout.Padding=UDim.new(0,8) layout.Parent=scroll
 return panel,heading,scroll
end
return Kit
