-- HP bars above eggs, built on the client from the egg attributes. The gui is sized in studs (see Config.EggBars), so it shrinks with distance
-- like the egg, it is not drawn through walls, and a full-health egg only shows it when the player is close.
local CS=game:GetService("CollectionService")
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Format=require(game.ReplicatedStorage.Shared.NumberFormat)
local B=Config.EggBars
local EggBars={}

local function textColor(egg)
 return egg:GetAttribute("Golden") and Config.GoldenColor or egg:GetAttribute("Lucky") and Config.LuckyEgg.Color
  or egg:GetAttribute("Size")=="Secret" and Config.SecretEgg.Color or Color3.new(1,1,1)
end

local function build(egg,parent)
 local rowHeight=B.TextHeight+B.BarHeight
 local gui=Instance.new("BillboardGui") gui.Name="EggBar" gui.Adornee=egg gui.AlwaysOnTop=false gui.LightInfluence=0 gui.MaxDistance=math.huge
 gui.Size=UDim2.fromScale(math.max(egg.Size.X,egg.Size.Z)*B.LabelWidth,rowHeight)
 gui.StudsOffsetWorldSpace=Vector3.new(0,egg.Size.Y/2+B.Gap+rowHeight/2,0)
 local text=Instance.new("TextLabel") text.Name="Text" text.BackgroundTransparency=1 text.Size=UDim2.fromScale(1,B.TextHeight/rowHeight)
 text.TextWrapped=false text.Font=Enum.Font.GothamBold text.TextColor3=textColor(egg) text.TextStrokeTransparency=0.3 text.Parent=gui
 local bar=Instance.new("Frame") bar.Name="Bar" bar.AnchorPoint=Vector2.new(.5,1) bar.Position=UDim2.fromScale(.5,1)
 bar.Size=UDim2.fromScale(1/B.LabelWidth,B.BarHeight/rowHeight) bar.BackgroundColor3=Color3.new(0,0,0) bar.BackgroundTransparency=0.35 bar.BorderSizePixel=0 bar.Parent=gui
 Instance.new("UICorner",bar).CornerRadius=UDim.new(.5,0)
 local fill=Instance.new("Frame") fill.Name="Fill" fill.BorderSizePixel=0 fill.Parent=bar
 Instance.new("UICorner",fill).CornerRadius=UDim.new(.5,0)
 gui.Parent=parent
 return gui
end

-- One line: the largest size that fits the row height, shrunk when the text is wider than the gui (TextScaled does not rescale in a
-- studs-sized gui). The gui is only laid out once it is drawn, so the update loop calls this for every visible bar.
local function fit(text)
 if text.AbsoluteSize.Y<=0 then return end
 text.TextSize=math.min(100,text.AbsoluteSize.Y)
 if text.TextBounds.X>text.AbsoluteSize.X then text.TextSize=math.floor(text.TextSize*text.AbsoluteSize.X/text.TextBounds.X) end
end

local function refresh(egg,gui)
 if not gui.Parent then return end -- the bar of an egg that streamed out or was destroyed is gone
 local hp,maxHp=egg:GetAttribute("HP"),egg:GetAttribute("MaxHP")
 local size=Config.EggSizeById[egg:GetAttribute("Size")]
 local parts={}
 if egg:GetAttribute("Lucky") then table.insert(parts,Config.LuckyEgg.Label) end
 if size and size.Label then table.insert(parts,size.Label) end
 table.insert(parts,Format.Compact(hp).."/"..Format.Compact(maxHp))
 gui.Text.Text=table.concat(parts," · ")
 local fraction=math.clamp(hp/maxHp,0,1)
 gui.Bar.Fill.Size=UDim2.fromScale(fraction,1)
 gui.Bar.Fill.BackgroundColor3=Color3.fromHSV(fraction*0.33,0.85,1) -- green at full health, red when nearly broken
end

function EggBars.Init()
 local player=Players.LocalPlayer
 local parent=player:WaitForChild("PlayerGui")
 local bars={} -- [egg] = gui
 local function add(egg)
  if bars[egg] or not egg:GetAttribute("MaxHP") then return end
  local gui=build(egg,parent) bars[egg]=gui
  refresh(egg,gui)
  egg:GetAttributeChangedSignal("HP"):Connect(function() refresh(egg,gui) end)
 end
 CS:GetInstanceAddedSignal("Cube"):Connect(add)
 CS:GetInstanceRemovedSignal("Cube"):Connect(function(egg) if bars[egg] then bars[egg]:Destroy() bars[egg]=nil end end)
 for _,egg in CS:GetTagged("Cube") do add(egg) end
 task.spawn(function()
  while true do
   task.wait(B.CheckSeconds)
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   for egg,gui in bars do
    if not egg.Parent or not gui.Parent then gui:Destroy() bars[egg]=nil continue end
    local recentHit=egg:GetAttribute("LastHitUserId")==player.UserId
     and workspace:GetServerTimeNow()-(egg:GetAttribute("LastHitAt") or -math.huge)<=B.HitShowSeconds
    gui.Enabled=root~=nil and not egg:GetAttribute("Dead") and (recentHit or (egg.Position-root.Position).Magnitude<=B.ShowDistance)
    if gui.Enabled then fit(gui.Text) end
   end
  end
 end)
end
return EggBars
