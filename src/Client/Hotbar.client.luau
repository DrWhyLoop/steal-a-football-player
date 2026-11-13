local Players=game:GetService("Players")
local StarterGui=game:GetService("StarterGui")
local Input=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local Config=require(game.ReplicatedStorage.Shared.Config)
local UIKit=require(script.Parent.UIKit)
local settings=Config.HotbarUI
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
repeat
 local ok=pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end)
 if ok then break end
 task.wait(.2)
until not script.Parent

local gui=Instance.new("ScreenGui")
gui.Name="ToolHotbar" gui.ResetOnSpawn=false gui.DisplayOrder=10 gui.Parent=playerGui
local bar=Instance.new("Frame")
bar.Name="Bar" bar.AnchorPoint=Vector2.new(.5,1)
bar.Position=UDim2.new(.5,0,1,-settings.Bottom)
bar.BackgroundTransparency=1 bar.Parent=gui
local layout=Instance.new("UIListLayout")
layout.FillDirection=Enum.FillDirection.Horizontal layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
layout.Padding=UDim.new(0,settings.Gap) layout.SortOrder=Enum.SortOrder.LayoutOrder layout.Parent=bar

local inventory=Instance.new("Frame")
inventory.Name="Inventory" inventory.AnchorPoint=Vector2.new(.5,1)
inventory.Position=UDim2.new(.5,0,1,-settings.Bottom-settings.SlotHeight-14)
inventory.Size=UDim2.fromOffset(360,200) inventory.BackgroundColor3=Config.UITheme.Background
inventory.Visible=false inventory.Parent=gui
local round=Instance.new("UICorner") round.CornerRadius=UDim.new(0,12) round.Parent=inventory
local heading=Instance.new("TextLabel")
heading.Size=UDim2.new(1,-24,0,32) heading.Position=UDim2.fromOffset(12,4)
heading.BackgroundTransparency=1 heading.Text="BACKPACK" heading.TextSize=15
heading.Font=Enum.Font.FredokaOne heading.TextColor3=Config.UITheme.Text heading.Parent=inventory
local list=Instance.new("ScrollingFrame")
list.Size=UDim2.new(1,-20,1,-45) list.Position=UDim2.fromOffset(10,38)
list.BackgroundTransparency=1 list.BorderSizePixel=0 list.ScrollBarThickness=4
list.AutomaticCanvasSize=Enum.AutomaticSize.Y list.CanvasSize=UDim2.new() list.Parent=inventory
local grid=Instance.new("UIGridLayout")
grid.CellSize=UDim2.fromOffset(78,72) grid.CellPadding=UDim2.fromOffset(7,7) grid.Parent=list
local order=setmetatable({},{__mode="k"})
local serial=0
local tools,buttons={},{}
local shownCount=0
local function equip(tool)
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not humanoid or humanoid.Health<=0 or not tool.Parent then return end
 if tool.Parent==character then humanoid:UnequipTools() else humanoid:EquipTool(tool) end
end
local function toggleInventory()
 inventory.Visible=not inventory.Visible
 if inventory.Visible and Input.GamepadEnabled then
  for _,child in list:GetChildren() do if child:IsA("GuiButton") then GuiService.SelectedObject=child break end end
 end
end
local function makeButton(parent,tool,index)
 local button=Instance.new("TextButton")
 button.Name=tool and ("Slot"..index) or "Backpack"
 button.Size=UDim2.fromOffset(settings.SlotWidth,settings.SlotHeight)
 button.BackgroundColor3=Config.UITheme.Card button.BackgroundTransparency=.08
 button.Text="" button.AutoButtonColor=true button.LayoutOrder=index button.Parent=parent
 local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,10) corner.Parent=button
 local stroke=Instance.new("UIStroke") stroke.Name="Selection" stroke.Color=Config.UITheme.Border stroke.Thickness=1 stroke.Parent=button
 local key=Instance.new("TextLabel")
 key.BackgroundTransparency=1 key.Position=UDim2.fromOffset(7,3) key.Size=UDim2.fromOffset(18,15)
 key.Text=tool and (index<=10 and tostring(index%10) or "") or "~"
 key.Font=Enum.Font.GothamMedium key.TextSize=11 key.TextColor3=Config.UITheme.Muted key.Parent=button
 local icon=Instance.new("TextLabel")
 icon.BackgroundTransparency=1 icon.Position=UDim2.new(0,4,0,19) icon.Size=UDim2.new(1,-8,0,18)
 icon.Font=Enum.Font.FredokaOne icon.TextSize=13 icon.TextColor3=settings.Accent
 icon.Text=tool and (tool.Name==Config.PickaxeName and "AXE" or tool.Name==Config.Bat.Name and "BAT" or "PLAYER") or "BAG"
 icon.Parent=button
 if tool and tool.TextureId~="" then
  icon.Visible=false
  local image=Instance.new("ImageLabel")
  image.BackgroundTransparency=1 image.Position=UDim2.new(.5,-12,0,16) image.Size=UDim2.fromOffset(24,24)
  image.Image=tool.TextureId image.Parent=button
 end
 local name=Instance.new("TextLabel")
 name.Name="ToolName" name.BackgroundTransparency=1 name.Position=UDim2.new(0,6,1,-29)
 name.Size=UDim2.new(1,-12,0,23) name.Font=Enum.Font.GothamMedium name.TextSize=11
 name.TextColor3=Config.UITheme.Text name.TextWrapped=true
 name.Text=tool and tool.Name or "Backpack" name.Parent=button
 local accent=Instance.new("Frame")
 accent.Name="Equipped" accent.Position=UDim2.new(0,8,1,-3) accent.Size=UDim2.new(1,-16,0,2)
 accent.BackgroundColor3=settings.Accent accent.BorderSizePixel=0 accent.Visible=false accent.Parent=button
 UIKit.Card(button)
 UIKit.Animate(button)
 button.Activated:Connect(function() if tool then equip(tool) else toggleInventory() end end)
 return {tool=tool,button=button,stroke=stroke,accent=accent}
end
local function rank(tool)
 return tool.Name==Config.PickaxeName and 1 or tool.Name==Config.Bat.Name and 2 or 3
end
local function refresh()
 gui.Enabled=not playerGui:GetAttribute("MenuOpen")
 local current={}
 for _,container in {player:FindFirstChildOfClass("Backpack"),player.Character} do
  if container then
   for _,tool in container:GetChildren() do
    if tool:IsA("Tool") then
     if not order[tool] then serial+=1 order[tool]=serial end
     table.insert(current,tool)
    end
   end
  end
 end
 table.sort(current,function(a,b) return rank(a)==rank(b) and order[a]<order[b] or rank(a)<rank(b) end)
 local changed=#current~=#tools
 for i,tool in current do if tools[i]~=tool then changed=true break end end
 local viewport=UIKit.Viewport()
 local capacity=math.max(1,math.floor((viewport.X-32)/(settings.MinSlotWidth+settings.Gap))-1)
 local count=math.min(#current,settings.MaxSlots,capacity)
 if count~=shownCount then changed=true end
 local width=math.min(settings.SlotWidth,(viewport.X-32)/(count+1)-settings.Gap)
 bar.Size=UDim2.fromOffset((width+settings.Gap)*(count+1),settings.SlotHeight)
 inventory.Size=UDim2.fromOffset(math.min(360,viewport.X-32),math.min(240,viewport.Y*.42))
 if changed then
  for _,parent in {bar,list} do for _,child in parent:GetChildren() do if child:IsA("GuiButton") then child:Destroy() end end end
  buttons={} tools=current shownCount=count
  for i,tool in tools do
   if i<=shownCount then table.insert(buttons,makeButton(bar,tool,i)) end
   table.insert(buttons,makeButton(list,tool,i))
  end
  makeButton(bar,nil,count+1)
 end
 for _,item in buttons do
  local selected=item.tool.Parent==player.Character
  item.stroke.Color=selected and settings.Accent or Config.UITheme.Border
  item.stroke.Thickness=selected and 2 or 1
  item.accent.Visible=selected
  if item.button.Parent==bar then item.button.Size=UDim2.fromOffset(width,settings.SlotHeight) end
 end
 local bag=bar:FindFirstChild("Backpack")
 if bag then bag.Size=UDim2.fromOffset(width,settings.SlotHeight) end
end
local keys={Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four,Enum.KeyCode.Five,Enum.KeyCode.Six,Enum.KeyCode.Seven,Enum.KeyCode.Eight,Enum.KeyCode.Nine,Enum.KeyCode.Zero}
Input.InputBegan:Connect(function(input,processed)
 if processed or Input:GetFocusedTextBox() or playerGui:GetAttribute("MenuOpen") then return end
 local index=table.find(keys,input.KeyCode)
 if index and tools[index] then equip(tools[index])
 elseif input.KeyCode==Enum.KeyCode.Backquote or input.KeyCode==Enum.KeyCode.ButtonY then toggleInventory()
 elseif input.KeyCode==Enum.KeyCode.ButtonL1 or input.KeyCode==Enum.KeyCode.ButtonR1 then
  local selected=0
  for i,tool in tools do if tool.Parent==player.Character then selected=i break end end
  if #tools>0 then
   local direction=input.KeyCode==Enum.KeyCode.ButtonR1 and 1 or -1
   equip(tools[(selected-1+direction)%#tools+1])
  end
 end
end)
while gui.Parent do refresh() task.wait(settings.RefreshSeconds) end
