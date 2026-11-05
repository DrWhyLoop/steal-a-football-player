-- One BillboardGui per character, adorned to its head bone so it moves with the animation.
-- Shows name (+ GIANT / variant tags) and tier-colored rarity; a status line only while the character is in the world or carried.
local CS=game:GetService("CollectionService")
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Labels={}
local STATUS_STATES={World=true,Revealing=true,Carried=true,Safe=true}
local function addLine(gui,y,height,color)
 local line=Instance.new("TextLabel") line.BackgroundTransparency=1 line.Position=UDim2.fromScale(0,y) line.Size=UDim2.fromScale(1,height)
 line.TextScaled=true line.Font=Enum.Font.GothamBold line.TextColor3=color line.TextStrokeTransparency=0.2 line.Parent=gui
 return line
end
function Labels.Init()
 local entries={}
 local function add(card)
  task.spawn(function()
   local visual=card:WaitForChild("PlayerVisual",5)
   local mesh=visual and visual:FindFirstChildWhichIsA("MeshPart",true) if not mesh or entries[card] then return end
   local anchor=mesh:FindFirstChild("Head",true)
   if not (anchor and anchor:IsA("Bone")) then anchor=Instance.new("Attachment") anchor.Position=Vector3.new(0,mesh.Size.Y/2,0) anchor.Parent=mesh end
   local gui=Instance.new("BillboardGui") gui.Name="HeadLabel" gui.Adornee=anchor gui.AlwaysOnTop=true gui.MaxDistance=Config.CardLabels.Distance
   local full=UDim2.fromOffset(Config.CardLabels.Width,Config.CardLabels.Height)
   gui.Size=full gui.StudsOffsetWorldSpace=Vector3.new(0,Config.CardLabels.HeadClearance,0)
   local variant=card:GetAttribute("Variant")
   local tag=(card:GetAttribute("Giant") and "GIANT " or "")..(variant and variant:upper().." " or "")
   addLine(gui,0,.4,variant and Config.Variants[variant].Tint or Color3.new(1,1,1)).Text=tag..card:GetAttribute("CardName")
   addLine(gui,.4,.32,Config.Tiers[card:GetAttribute("Tier")].Color).Text=card:GetAttribute("Tier")
   entries[card]={status=addLine(gui,.72,.28,Config.CardLabels.StatusColor)}
   if card:GetAttribute("State")=="Revealing" then -- name and rarity pop in as the character rises
    gui.Size=UDim2.fromOffset(0,0)
    TweenService:Create(gui,TweenInfo.new(Config.Reveal.RiseSeconds,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=full}):Play()
   end
   gui.Parent=card
  end)
 end
 CS:GetInstanceAddedSignal("Card"):Connect(add)
 for _,card in CS:GetTagged("Card") do add(card) end
 task.spawn(function()
  while true do
   task.wait(Config.CardLabels.RefreshSeconds)
   for card,e in entries do
    if not card.Parent then entries[card]=nil
    else
     local expiry=card:GetAttribute("WorldExpiresAt")
     local remaining=expiry and math.max(0,expiry-workspace:GetServerTimeNow()) or card:GetAttribute("RemainingLifetime")
     local reserved=card:GetAttribute("BreakerUserId")~=Players.LocalPlayer.UserId and workspace:GetServerTimeNow()<(card:GetAttribute("PriorityUntil") or 0)
     e.status.Text=reserved and "Reserved" or STATUS_STATES[card:GetAttribute("State")] and not card:GetAttribute("Escaped") and remaining
      and ("%ds%s"):format(math.ceil(remaining),expiry and " remaining" or " paused") or ""
    end
   end
  end
 end)
end
return Labels
