-- Pre-publish security scan. Run in Edit mode (Studio command bar, or the MCP execute_luau tool). It only READS: it reports paths and deletes nothing.
-- Scans Workspace, ReplicatedStorage, ServerStorage, ServerScriptService, StarterGui, StarterPlayer, Lighting (plus StarterPack and ReplicatedFirst) for:
--   REQUIRE_ID_OR_VALUE  require(<number>) or require(<anything>.Value): loads a module by asset id
--   LOADSTRING           loadstring
--   GETFENV_SETFENV      getfenv / setfenv
--   POPUP_NAME           instances named Runtime, ScreenBuilder, RuntimeInput, InputBinding (the fake "Roblox Studio Disconnected / Error 0x89AF2" popup)
--   POPUP_TEXT           script source mentioning 0x89AF2 or "workspace verification"
--   TEXTURE_LOADER       TextureConfigurationLoader (name or source)
--   SCRIPT_IN_MODEL      any script (Script, LocalScript, ModuleScript) inside a Model, e.g. imported decor
--   NOT_IN_SRC           any script whose path is not one of ours (the OURS list below = the files in src/ plus ServerStorage.PurchaseSupport)
-- OURS is generated from src/: when src gains or loses a file, ask Claude to regenerate it (or edit the list). The result string lists
-- "[RULE] path (class, enabled/DISABLED)"; DISABLED scripts are still reported because a Studio plugin or a later Enable can run them.

local SERVICES = {"Workspace", "ReplicatedStorage", "ServerStorage", "ServerScriptService", "StarterGui", "StarterPlayer", "Lighting", "StarterPack", "ReplicatedFirst"}
local POPUP_NAMES = {Runtime = true, ScreenBuilder = true, RuntimeInput = true, InputBinding = true}
local MAX_PER_RULE = 400 -- paths printed per rule; the counts are always complete

local OURS = {
 ["ReplicatedStorage.Shared.CageOccupant"]=true,
 ["ReplicatedStorage.Shared.CageFit"]=true,
 ["StarterPlayer.StarterPlayerScripts.Client.Hotbar"]=true,
 ["ReplicatedStorage.Shared.RewardMath"]=true,
 ["StarterPlayer.StarterPlayerScripts.Client.VariantEffects"]=true,
 ["ReplicatedStorage.Shared.Rebirth"]=true,
 ["ServerScriptService.Server.RebirthService"]=true,
 ["ServerScriptService.Server.QuestService"]=true,
 ["ServerScriptService.Server.UpgradeShop"]=true,
 ["StarterPlayer.StarterPlayerScripts.Client.StageMood"]=true,
 ["StarterPlayer.StarterPlayerScripts.Client.StageTwistFX"]=true,
 ["ReplicatedStorage.Shared.StageZone"]=true,
 ["ReplicatedStorage.Shared.StageTwistMath"]=true,
 ["ReplicatedStorage.Shared.SetBonus"]=true,
 ["ServerScriptService.Server.StageTwists"]=true,
 ["ServerScriptService.Server.StageArrival"]=true,
 ["StarterPlayer.StarterPlayerScripts.Client.UpgradeUI"]=true,
 ["StarterPlayer.StarterPlayerScripts.Client.QuestUI"]=true,
 ["StarterPlayer.StarterPlayerScripts.Client.RebirthUI"]=true,
	["ServerScriptService.Server.Announcer"]=true, ["ServerScriptService.Server.BossFactory"]=true, ["ServerScriptService.Server.CardService"]=true,
	["ServerScriptService.Server.CashService"]=true, ["ServerScriptService.Server.CharacterFactory"]=true,
	["ServerScriptService.Server.CubeService"]=true, ["ServerScriptService.Server.DailyReward"]=true,
	["ServerScriptService.Server.EnvironmentBuilder"]=true, ["ServerScriptService.Server.FeedbackService"]=true,
	["ServerScriptService.Server.FootballBall"]=true, ["ServerScriptService.Server.FootballLobby"]=true,
	["ServerScriptService.Server.GuardService"]=true, ["ServerScriptService.Server.IndexService"]=true,
	["ServerScriptService.Server.Leaderboards"]=true, ["ServerScriptService.Server.LineOfSight"]=true,
	["ServerScriptService.Server.Main"]=true, ["ServerScriptService.Server.MonsterFactory"]=true, ["ServerScriptService.Server.PickaxeService"]=true,
	["ServerScriptService.Server.PlayerData"]=true, ["ServerScriptService.Server.PlayerReward"]=true, ["ServerScriptService.Server.PlayerStats"]=true,
	["ServerScriptService.Server.PlotAccess"]=true, ["ServerScriptService.Server.PlotService"]=true, ["ServerScriptService.Server.PurchaseLog"]=true,
	["ServerScriptService.Server.Purchases"]=true, ["ServerScriptService.Server.SlotService"]=true, ["ServerScriptService.Server.ToolShop"]=true,
	["ServerScriptService.Server.TorchMount"]=true, ["ServerScriptService.Server.TrailShop"]=true, ["ServerScriptService.Server.TreadmillService"]=true,
	["ServerScriptService.Server.WeatherService"]=true, ["ServerScriptService.Server.WorldBuilder"]=true,
	["ServerScriptService.Server.WorldLayout"]=true, ["StarterPlayer.StarterPlayerScripts.Client.AnimalMotion"]=true,
	["StarterPlayer.StarterPlayerScripts.Client.AnnouncementUI"]=true, ["StarterPlayer.StarterPlayerScripts.Client.AutoSwing"]=true,
	["StarterPlayer.StarterPlayerScripts.Client.CarryHud"]=true, ["StarterPlayer.StarterPlayerScripts.Client.CharacterMotion"]=true,
	["StarterPlayer.StarterPlayerScripts.Client.EggBars"]=true, ["StarterPlayer.StarterPlayerScripts.Client.FootballLobbyUI"]=true,
	["StarterPlayer.StarterPlayerScripts.Client.IndexUI"]=true, ["StarterPlayer.StarterPlayerScripts.Client.Knockback"]=true,
	["StarterPlayer.StarterPlayerScripts.Client.LandscapeController"]=true, ["StarterPlayer.StarterPlayerScripts.Client.LightFlicker"]=true,
	["StarterPlayer.StarterPlayerScripts.Client.LuckyOdds"]=true, ["StarterPlayer.StarterPlayerScripts.Client.Main"]=true,
	["StarterPlayer.StarterPlayerScripts.Client.ModelViewport"]=true, ["StarterPlayer.StarterPlayerScripts.Client.MonsterPreview"]=true,
	["StarterPlayer.StarterPlayerScripts.Client.NpcMotion"]=true, ["StarterPlayer.StarterPlayerScripts.Client.PlayerLabels"]=true,
	["StarterPlayer.StarterPlayerScripts.Client.PlotWatch"]=true, ["StarterPlayer.StarterPlayerScripts.Client.PromptFilter"]=true,
	["StarterPlayer.StarterPlayerScripts.Client.RewardEffects"]=true, ["StarterPlayer.StarterPlayerScripts.Client.SlotUI"]=true,
	["StarterPlayer.StarterPlayerScripts.Client.StageBanner"]=true, ["StarterPlayer.StarterPlayerScripts.Client.ToolUI"]=true,
	["StarterPlayer.StarterPlayerScripts.Client.TrailUI"]=true, ["StarterPlayer.StarterPlayerScripts.Client.TreadmillUI"]=true,
	["StarterPlayer.StarterPlayerScripts.Client.TreadmillVisibility"]=true, ["StarterPlayer.StarterPlayerScripts.Client.UIKit"]=true,
	["StarterPlayer.StarterPlayerScripts.Client.WeatherController"]=true, ["ReplicatedStorage.Shared.AnimationClips"]=true,
	["ReplicatedStorage.Shared.Bosses"]=true, ["ReplicatedStorage.Shared.Characters"]=true, ["ReplicatedStorage.Shared.Config"]=true,
	["ReplicatedStorage.Shared.HurtPose"]=true, ["ReplicatedStorage.Shared.IndexKeys"]=true, ["ReplicatedStorage.Shared.MonsterPose"]=true,
	["ReplicatedStorage.Shared.NumberFormat"]=true, ["ReplicatedStorage.Shared.Remotes"]=true, ["ReplicatedStorage.Shared.RigAnimation"]=true,
	["ServerStorage.PurchaseSupport"]=true,
}

local function word(source, name) return source:find("%f[%w_]" .. name .. "%f[^%w_]") ~= nil end

local function suspiciousRequire(source)
	for args in source:gmatch("require%s*(%b())") do
		if args:find("^%(%s*%-?%d") or args:find("%.Value") then return args end
	end
	return nil
end

local findings, order = {}, {"REQUIRE_ID_OR_VALUE", "LOADSTRING", "GETFENV_SETFENV", "POPUP_NAME", "POPUP_TEXT", "TEXTURE_LOADER", "SCRIPT_IN_MODEL", "NOT_IN_SRC"}
for _, rule in order do findings[rule] = {} end

local function describe(instance)
	local text = instance:GetFullName() .. " (" .. instance.ClassName
	if instance:IsA("BaseScript") then text ..= instance.Enabled and ", enabled" or ", DISABLED" end
	return text .. ")"
end

local function report(rule, instance, note)
	table.insert(findings[rule], (note and note .. " " or "") .. describe(instance))
end

local scanned, scripts = 0, 0
for _, serviceName in SERVICES do
	local service = game:FindFirstChild(serviceName)
	if service then
		for _, d in service:GetDescendants() do
			scanned += 1
			if POPUP_NAMES[d.Name] then report("POPUP_NAME", d) end
			if d.Name == "TextureConfigurationLoader" then report("TEXTURE_LOADER", d) end
			if d:IsA("LuaSourceContainer") then
				scripts += 1
				local source = d.Source
				local args = suspiciousRequire(source)
				if args then report("REQUIRE_ID_OR_VALUE", d, "require" .. args:sub(1, 60)) end
				if word(source, "loadstring") then report("LOADSTRING", d) end
				if word(source, "getfenv") or word(source, "setfenv") then report("GETFENV_SETFENV", d) end
				if source:find("0x89AF2", 1, true) or source:lower():find("workspace verification", 1, true) then report("POPUP_TEXT", d) end
				if source:find("TextureConfigurationLoader", 1, true) then report("TEXTURE_LOADER", d) end
				if d:FindFirstAncestorOfClass("Model") then report("SCRIPT_IN_MODEL", d) end
				if not OURS[d:GetFullName()] then report("NOT_IN_SRC", d) end
			end
		end
	end
end

local lines = {("Scanned %d instances, %d scripts in %d services."):format(scanned, scripts, #SERVICES)}
local total = 0
for _, rule in order do
	local list = findings[rule]
	table.sort(list)
	total += #list
	table.insert(lines, ("== %s: %d"):format(rule, #list))
	for i = 1, math.min(#list, MAX_PER_RULE) do table.insert(lines, "  " .. list[i]) end
	if #list > MAX_PER_RULE then table.insert(lines, ("  ... %d more"):format(#list - MAX_PER_RULE)) end
end
table.insert(lines, total == 0 and "CLEAN: nothing found." or ("FINDINGS: %d (review every path; nothing was deleted)."):format(total))
return table.concat(lines, "\n")
