local Config=require(script.Parent.Config)
local Math={}

function Math.Weights(list,luck)
 local weights,total={},0
 for index,item in list do
  local weight=item.Weight*luck^((index-1)*Config.RewardRoll.LuckExponent)
  weights[index]=weight
  total+=weight
 end
 return weights,total
end

function Math.Multiplier(sizeId,variant,roll)
 local size=Config.RewardSizeById[sizeId] or Config.RewardSizeById.Normal
 local material=Config.Variants[variant] or Config.Variants.Normal
 local raw=size.Income*material.Income*roll
 local start=Config.RewardRoll.SoftStart
 return math.min(Config.RewardRoll.AbsoluteMax,raw<=start and raw or start+math.sqrt(raw-start))
end

function Math.Reveal(luck)
 local progress=math.clamp((luck-Config.Luck.Min)/(Config.Luck.LuckyMax-Config.Luck.Min),0,1)
 local r=Config.Reveal
 local growth=r.GrowthMinSeconds+(r.GrowthMaxSeconds-r.GrowthMinSeconds)*progress
 local scale=r.GrowthMinScale+(r.GrowthMaxScale-r.GrowthMinScale)*progress
 return r.BreakSeconds+growth+r.FlashSeconds,growth,scale
end

return Math
