-- Rebirth maths shared by the server (validation) and the client (bar). `count` = rebirths already done.
local Config=require(script.Parent.Config)
local R=Config.Rebirth
local M={}
function M.Requirement(count) return R.BaseRequirement*R.RequirementGrowth^count end -- Speed Points needed for rebirth number count+1
function M.Income(count) return 1+R.IncomeStep*count end
function M.Gain(count) return 1+R.GainStep*count end
function M.Ready(points,count) return count<R.Max and points>=M.Requirement(count) end
function M.Level(points,count)
	return math.min(R.Segments,math.floor(R.Segments*math.log10(1+points)/math.log10(1+M.Requirement(count))))
end
return M
