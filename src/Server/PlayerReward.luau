-- One server draw and one sanitized visual builder for all roster members.
local Config=require(game.ReplicatedStorage.Shared.Config)
local Templates=game.ServerStorage:WaitForChild("PlayerTemplates")
local Reward={}
local rng=Random.new()
function Reward.Pool(tier)
 local pool={} for _,entry in Config.PlayerRoster do if entry.Tier==tier then table.insert(pool,entry) end end
 assert(#pool>0,"Empty player pool: "..tier)
 return pool
end
function Reward.Pick(tier)
 local pool=Reward.Pool(tier) local total=0
 for _,entry in pool do total+=entry.Weight end
 local roll=rng:NextNumber()*total
 for _,entry in pool do roll-=entry.Weight if roll<0 then return entry end end
 return pool[#pool]
end
local Math=require(game.ReplicatedStorage.Shared.RewardMath)
local variants={}
for _,name in Config.RewardVariantOrder do
 table.insert(variants,{Id=name,Weight=Config.Variants[name].Weight})
end

local function draw(list,luck)
 local weights,total=Math.Weights(list,luck)
 local roll=rng:NextNumber()*total
 for index,item in list do
  roll-=weights[index]
  if roll<0 then return item.Id end
 end
 return list[#list].Id
end

function Reward.Roll(luck,minimum)
 local size=draw(Config.RewardSizes,luck)
 local material=draw(variants,luck)
 local minimumRank=minimum and table.find(Config.RewardVariantOrder,minimum)
 if minimumRank and table.find(Config.RewardVariantOrder,material)<minimumRank then material=minimum end
 return material,size
end
-- Luck L: the value on the break counter (rounded to one decimal so the counter lands on it). A Lucky Cage rolls the high range.
-- `bonus` (the Cage luck upgrade) is added to the roll and the total never exceeds LuckyMax.
function Reward.Luck(lucky,bonus)
 local L=Config.Luck
 local value=lucky and L.LuckyMin+(L.LuckyMax-L.LuckyMin)*rng:NextNumber() or L.Min+(L.Max-L.Min)*rng:NextNumber()^L.Power
 return math.floor(math.min(L.LuckyMax,value+(bonus or 0))/L.Step+.5)*L.Step
end
-- Income factor inside the footballer's range; luck pushes the roll towards the top.
function Reward.IncomeRoll(entry,luck)
 local range=entry.IncomeRange or Config.IncomeRange[entry.Tier]
 return range.Min+(range.Max-range.Min)*rng:NextNumber()^(1/luck)
end
Reward.IncomeMultiplier=Math.Multiplier

function Reward.Resize(card,displayScale)
 local model=card:FindFirstChild("PlayerVisual")
 if not model then return end
 local weld=model:FindFirstChild("VisualWeld",true)
 if weld then weld:Destroy() end
 local mesh=model.PrimaryPart
 local size=Config.RewardSizeById[card:GetAttribute("SizeTier")] or Config.RewardSizeById.Normal
 model:ScaleTo(displayScale or size.Scale)
 model:PivotTo(card.CFrame*CFrame.new(0,(mesh.Size.Y-card.Size.Y)/2,0))
 local joint=Instance.new("WeldConstraint")
 joint.Name="VisualWeld" joint.Part0=card joint.Part1=mesh joint.Parent=mesh
end

function Reward.Attach(card,id,variant)
 local mesh=Templates:FindFirstChild(id):Clone()
 local model=Instance.new("Model")
 model.Name="PlayerVisual"
 mesh.Name="PlayerMesh"
 local factor=Config.Reveal.DisplayHeight/mesh.Size.Y
 mesh.Size*=factor
 for _,bone in mesh:GetDescendants() do
  if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*factor)*bone.CFrame.Rotation end
 end
 mesh.CFrame=card.CFrame
 mesh.Anchored=false mesh.Massless=true
 local tint=Config.Variants[variant].Tint
 local appearance=mesh:FindFirstChildWhichIsA("SurfaceAppearance")
 if appearance then appearance.Color=appearance.Color:Lerp(tint,Config.RewardRoll.TintBlend)
 else mesh.Color=mesh.Color:Lerp(tint,Config.RewardRoll.TintBlend) end
 mesh.CanCollide=false mesh.CanTouch=false mesh.CanQuery=false
 mesh.Parent=model model.PrimaryPart=mesh
 model:SetAttribute("AnimationClip","RunR6")
 model:SetAttribute("Moving",false)
 model.Parent=card
 Reward.Resize(card)
 model:AddTag("AnimatedCharacter")
end

-- One common maximum derived from every roster mesh prevents adjacent different players from overlapping.
local maxFootprint=0
for _,entry in Config.PlayerRoster do
 local mesh=Templates:FindFirstChild(entry.Id)
 if mesh then
  local unit=mesh.Size*Config.Reveal.DisplayHeight/mesh.Size.Y
  maxFootprint=math.max(maxFootprint,Vector2.new(unit.X,unit.Z).Magnitude)
 end
end

function Reward.DisplayScale(slot,sizeId)
 local settings=Config.RewardDisplay
 local nearest,ceiling=math.huge,math.huge
 for _,other in slot.Parent:GetChildren() do
  if other:IsA("BasePart") and other~=slot then
   local delta=other.Position-slot.Position
   local horizontal=Vector2.new(delta.X,delta.Z).Magnitude
   if math.abs(delta.Y)<settings.SameFloorTolerance then nearest=math.min(nearest,horizontal)
   elseif delta.Y>0 then ceiling=math.min(ceiling,delta.Y-settings.FloorGap) end
  end
 end
 local maximum=math.min(nearest*settings.SpacingFraction/maxFootprint,ceiling/Config.Reveal.DisplayHeight)
 if maximum==math.huge then maximum=Config.RewardSizes[#Config.RewardSizes].Scale end
 local minimum=math.min(Config.RewardSizes[1].Scale,maximum*settings.MinimumRatio)
 local size=Config.RewardSizeById[sizeId] or Config.RewardSizeById.Normal
 local first,last=Config.RewardSizes[1].Scale,Config.RewardSizes[#Config.RewardSizes].Scale
 return minimum+(maximum-minimum)*(size.Scale-first)/(last-first)
end

return Reward
