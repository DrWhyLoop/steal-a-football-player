-- Collection sets (Config.Sets), derived from the Index bitmasks: a tier's Gold set is complete when every roster footballer of the tier has been
-- collected in Gold or better, its Diamond star the same for Diamond or better. Shared by the server (income) and the Index screen.
local Config = require(script.Parent.Config)
local Keys = require(script.Parent.IndexKeys)
local S = {}
-- Index bits 2i and 2i+1 are variant number i and its Giant version, and variants are ordered by value, so "or better" = any bit from there up.
local function shift(variant) return table.find(Config.Index.VariantOrder, variant) * 2 end
local goldShift, diamondShift = shift(Config.Sets.GoldVariant), shift(Config.Sets.DiamondVariant)

--- Footballers of `tier` collected in Gold or better, in Diamond or better, and the tier size.
function S.Counts(index, tier)
	local gold, diamond = 0, 0
	for _, entry in Keys.ByTier[tier] do
		local mask = index[entry.Id] or 0
		if bit32.rshift(mask, goldShift) ~= 0 then gold += 1 end
		if bit32.rshift(mask, diamondShift) ~= 0 then diamond += 1 end
	end
	return gold, diamond, #Keys.ByTier[tier]
end

--- Income bonus of the Gold set and of the Diamond star (0 until complete).
function S.Bonus(index, tier)
	local gold, diamond, total = S.Counts(index, tier)
	local value = Config.Sets.Gold[tier] or 0
	return gold == total and value or 0, diamond == total and value * Config.Sets.DiamondFactor or 0
end

--- Combined income bonus of every complete set, capped at Config.Sets.Cap.
function S.Total(index)
	local sum = 0
	for tier in Keys.ByTier do
		local gold, diamond = S.Bonus(index, tier)
		sum += gold + diamond
	end
	return math.min(Config.Sets.Cap, sum)
end
return S
