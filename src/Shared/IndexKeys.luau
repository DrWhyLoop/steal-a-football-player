-- Data-driven index layout derived from Config.PlayerRoster and Config.Index.VariantOrder (no per-character code).
-- A variant combination (material + Giant) is one bit: (materialIndex * 2) + (giant and 1 or 0), materialIndex 0 = normal.
local Config=require(script.Parent.Config)
local K={ById={},ByTier={},List={}}
for _,entry in Config.PlayerRoster do
 K.ById[entry.Id]=entry
 K.ByTier[entry.Tier]=K.ByTier[entry.Tier] or {}
 table.insert(K.ByTier[entry.Tier],entry)
end
-- Display list: Normal, Gold, Diamond, Giant, Giant Gold, Giant Diamond (for the current VariantOrder)
local materials={false}
for _,material in Config.Index.VariantOrder do table.insert(materials,material) end
for _,giant in {false,true} do
 for materialIndex,material in materials do
  local name=(giant and "Giant" or "")..((giant and material) and " " or "")..(material or "")
  table.insert(K.List,{Variant=material or nil,Giant=giant or nil,Bit=(materialIndex-1)*2+(giant and 1 or 0),Name=name=="" and "Normal" or name})
 end
end
-- Bit number for a card's variant attributes, or nil for an unknown variant.
function K.Bit(variant,giant)
 local materialIndex=0
 if variant then
  local found=table.find(Config.Index.VariantOrder,variant)
  if not found then return nil end
  materialIndex=found
 end
 return materialIndex*2+(giant and 1 or 0)
end
return K
