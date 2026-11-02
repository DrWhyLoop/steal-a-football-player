--[[
	Client entry point. The client only shows UI and applies server-sent effects;
	all gameplay is decided on the server.
]]

if not game:IsLoaded() then game.Loaded:Wait() end

require(script.Parent.AnnouncementUI).Init()
require(script.Parent.CarryHud).Init()
require(script.Parent.PromptFilter).Init()
require(script.Parent.Knockback).Init()
