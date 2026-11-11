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
-- Variants: Gold/Diamond are exclusive (Diamond first), Giant rolls independently; a Lucky Egg uses its own boosted odds.
function Reward.Roll(lucky,oddsMultiplier)
 local odds=lucky and Config.LuckyEgg.Odds or Config.VariantOdds
 local m=oddsMultiplier or 1 -- a bigger egg multiplies every variant chance
 local roll=rng:NextNumber()
 local variant=(roll<odds.Diamond*m and "Diamond") or (roll<(odds.Diamond+odds.Gold)*m and "Gold") or nil
 return variant,rng:NextNumber()<odds.Giant*m or nil
end
-- Luck L: the value on the break counter (rounded to one decimal so the counter lands on it). A Lucky Cage rolls the high range.
function Reward.Luck(lucky)
 local L=Config.Luck
 local value=lucky and L.LuckyMin+(L.LuckyMax-L.LuckyMin)*rng:NextNumber() or L.Min+(L.Max-L.Min)*rng:NextNumber()^L.Power
 return math.floor(value/L.Step+.5)*L.Step
end
-- Income factor inside the footballer's range; luck pushes the roll towards the top.
function Reward.IncomeRoll(entry,luck)
 local range=entry.IncomeRange or Config.IncomeRange[entry.Tier]
 return range.Min+(range.Max-range.Min)*rng:NextNumber()^(1/luck)
end
function Reward.IncomeMultiplier(variant,giant)
 return (variant and Config.Variants[variant].Income or 1)*(giant and Config.GiantVariant.Income or 1)
end
-- Character size: Giant and the egg size multiply, capped so a Huge Giant never towers over its display.
function Reward.Scale(giant,eggSize)
 local size=eggSize and Config.EggSizeById[eggSize]
 local scale=size and (size.CharacterScale or size.Scale) or 1
 return math.min(Config.CardScaleCap,(giant and Config.GiantVariant.Size or 1)*scale)
end
function Reward.Attach(card,id,variant,giant,eggSize)
 local mesh=Templates:FindFirstChild(id):Clone()
 local model=Instance.new("Model") model.Name="PlayerVisual"
 mesh.Name="PlayerMesh"
 local size=Reward.Scale(giant,eggSize)
 local scale=Config.Reveal.DisplayHeight/mesh.Size.Y*size
 mesh.Size*=scale
 for _,bone in mesh:GetDescendants() do if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end end
 mesh.CFrame=card.CFrame*CFrame.new(0,(size-1)*Config.Reveal.DisplayHeight/2,0) mesh.Anchored=false mesh.Massless=true -- feet stay where the card's feet would be
 if variant then
  local look=mesh:FindFirstChildWhichIsA("SurfaceAppearance")
  if look then look.Color=Config.Variants[variant].Tint else mesh.Color=Config.Variants[variant].Tint end
  local sparkle=Instance.new("ParticleEmitter") sparkle.Texture="rbxasset://textures/particles/sparkles_main.dds" sparkle.Rate=Config.Variants.SparkleRate
  sparkle.Lifetime=NumberRange.new(.6,1) sparkle.Speed=NumberRange.new(1,2) sparkle.LightEmission=1 sparkle.Size=NumberSequence.new(.5*size)
  sparkle.Color=ColorSequence.new(Config.Variants[variant].Tint) sparkle.Parent=mesh
 local glow=Config.Variants[variant].Glow
 if glow then -- crystal sheen over any kit color (a multiply tint alone would shift the hue)
  local highlight=Instance.new("Highlight") highlight.FillColor=glow highlight.OutlineColor=glow highlight.FillTransparency=Config.Variants[variant].GlowFill highlight.DepthMode=Enum.HighlightDepthMode.Occluded highlight.Parent=mesh
 end
 end
 mesh.CanCollide=false mesh.CanTouch=false mesh.CanQuery=false
 mesh.Parent=model model.PrimaryPart=mesh
 local weld=Instance.new("WeldConstraint") weld.Part0=card weld.Part1=mesh weld.Parent=mesh
 model:SetAttribute("AnimationClip","RunR6") model:SetAttribute("Moving",false)
 model.Parent=card model:AddTag("AnimatedCharacter")
end
return Reward
