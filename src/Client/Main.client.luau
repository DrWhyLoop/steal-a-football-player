--[[
	Client entry point. The client only shows UI and applies server-sent effects;
	all gameplay is decided on the server.
]]

if not game:IsLoaded() then game.Loaded:Wait() end

require(script.Parent.AnnouncementUI).Init()
require(script.Parent.CarryHud).Init()
require(script.Parent.PromptFilter).Init()
require(script.Parent.SlotUI).Init()
require(script.Parent.Knockback).Init()

require(script.Parent.LandscapeController).Init()
require(script.Parent.WeatherController).Init()
require(script.Parent.AnimalMotion).Init()
require(script.Parent.CharacterMotion).Init()

require(script.Parent.RewardEffects).Init()
require(script.Parent.LuckyOdds).Init()
require(script.Parent.IndexUI).Init()

require(script.Parent.TreadmillUI).Init()
require(script.Parent.PickaxeUI).Init()
task.spawn(require(script.Parent.AutoSwing).Init)
task.spawn(require(script.Parent.StageBanner).Init)

require(script.Parent.PlayerLabels).Init()
