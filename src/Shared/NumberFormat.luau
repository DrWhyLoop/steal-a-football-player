local Format={}
local suffixes={"","K","M","B","T","Qa","Qi"}
function Format.Compact(value)
 local index=1
 while math.abs(value)>=1000 and index<#suffixes do value/=1000 index+=1 end
 return index==1 and ("%.0f"):format(value) or ("%.2f%s"):format(value,suffixes[index])
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
return Format
