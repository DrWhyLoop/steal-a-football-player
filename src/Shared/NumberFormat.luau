local Format={}
local suffixes={"","K","M","B","T","Qa","Qi","Sx","Sp","Oc","No","Dc"}
-- Compact form up to Dc (1e33); anything larger falls back to scientific notation. Rounding that would print 1000 moves to the next suffix.
function Format.Compact(value)
 local sign=value<0 and "-" or ""
 local scaled,index=math.abs(value),1
 while scaled>=1000 and index<#suffixes do scaled/=1000 index+=1 end
 local decimals=index==1 and "%.0f" or "%.2f"
 if tonumber(decimals:format(scaled))>=1000 and index<#suffixes then scaled/=1000 index+=1 decimals="%.2f" end
 if scaled>=1000 then return sign..("%.2e"):format(math.abs(value)) end
 return sign..decimals:format(scaled)..suffixes[index]
end
-- Cash amounts: whole numbers stay plain, fractions keep up to 2 decimals, 1,000+ use suffixes.
function Format.Money(value)
 if math.abs(value)>=1000 then return Format.Compact(value) end
 return (("%.2f"):format(value):gsub("%.?0+$",""))
end
function Format.Exact(value)
 if value%1~=0 then return tostring(value) end
 local s=("%.0f"):format(value)
 local result=s:reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
 return result
end
-- Sign and banner text for a stage's recommended Speed Points.
function Format.Recommended(points) return points>0 and "Recommended: "..Format.Compact(points).." Speed" or "Recommended: Any Speed" end
return Format
