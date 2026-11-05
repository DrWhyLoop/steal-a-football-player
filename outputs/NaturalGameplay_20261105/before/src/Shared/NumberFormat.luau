local Format={}
local suffixes={"","K","M","B","T","Qa","Qi"}
function Format.Compact(value)
 local index=1
 while math.abs(value)>=1000 and index<#suffixes do value/=1000 index+=1 end
 return index==1 and ("%.0f"):format(value) or ("%.2f%s"):format(value,suffixes[index])
end
function Format.Exact(value)
 if value%1~=0 then return tostring(value) end
 local s=("%.0f"):format(value)
 local result=s:reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
 return result
end
return Format
