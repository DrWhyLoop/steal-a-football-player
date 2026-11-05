-- Server-wide announcement for rare hatches (see Config.Announce), rate limited so the banner is never spammed.
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Shared.Config)
local Remotes=require(RS.Shared.Remotes)
local cfg=Config.Announce
local A={}
local recent={} -- os.clock() of announcements in the last minute
local lastBy=setmetatable({},{__mode="k"})

function A.Hatched(player,entry,tier,variant,giant)
 if not (cfg.Tiers[tier] or (giant and cfg.Giant) or (variant and cfg.Variants[variant])) then return end
 local now=os.clock()
 while recent[1] and now-recent[1]>60 do table.remove(recent,1) end
 if now-(lastBy[player] or -math.huge)<cfg.PlayerGapSeconds or #recent>=cfg.MaxPerMinute or (recent[#recent] and now-recent[#recent]<cfg.GlobalGapSeconds) then return end
 table.insert(recent,now) lastBy[player]=now
 local tags=(giant and "GIANT " or "")..(variant and variant:upper().." " or "")
 if tags=="" then tags=tier:upper().." " end
 Remotes.Announcement:FireAllClients(("%s hatched a %s%s!"):format(player.DisplayName,tags,entry.Name))
end
return A
