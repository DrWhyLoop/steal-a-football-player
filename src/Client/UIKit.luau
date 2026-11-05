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
return Kit
