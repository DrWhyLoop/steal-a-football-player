-- Client-side stage mood: entering a stage tweens one ColorCorrection effect, the Atmosphere Decay/Glare/Offset and the Bloom to Config.StageInfo[n].Mood;
-- fog Density/Haze scales are published as Lighting attributes that WeatherController multiplies in. Storm Dome forces rain and flashes lightning (visual only).
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local StageZone = require(RS.Shared.StageZone)
local M = Config.StageMood
local Mood = {}

function Mood.Init()
	local player = Players.LocalPlayer
	local atmosphere, bloom = Lighting:FindFirstChildOfClass("Atmosphere"), Lighting:FindFirstChildOfClass("BloomEffect")
	local effect = Instance.new("ColorCorrectionEffect")
	effect.Name = "StageMood"
	effect.Parent = Lighting
	local base = table.clone(M.Neutral) -- Decay, Glare and Offset below start from the place's own Atmosphere
	base.Decay, base.Glare, base.Offset = atmosphere.Decay, atmosphere.Glare, atmosphere.Offset
	local baseBloom = bloom.Intensity
	local current, tweens, token = nil, {}, 0

	local function tween(target, goal)
		local t = TweenService:Create(target, TweenInfo.new(M.TweenSeconds), goal)
		table.insert(tweens, t)
		t:Play()
	end
	local function apply(stage)
		local mood = stage and Config.StageInfo[stage].Mood or base
		for _, t in tweens do t:Cancel() end
		tweens = {}
		token += 1
		tween(effect, {TintColor = mood.Tint, Saturation = mood.Saturation, Contrast = mood.Contrast, Brightness = mood.Brightness})
		tween(atmosphere, {Decay = mood.Decay, Glare = mood.Glare, Offset = mood.Offset})
		tween(bloom, {Intensity = baseBloom * mood.Bloom})
		Lighting:SetAttribute("StageDensityScale", mood.DensityScale)
		Lighting:SetAttribute("StageHazeScale", mood.HazeScale)
		Lighting:SetAttribute("StageRain", mood.Rain == true)
		local mine = token
		if mood.Lightning then
			task.spawn(function()
				while token == mine do
					task.wait(Random.new():NextNumber(mood.Lightning.Min, mood.Lightning.Max))
					if token ~= mine then return end
					for _ = 1, 2 do -- a double flash, then back to the stage's brightness
						effect.Brightness = mood.Brightness + mood.Lightning.Flash
						task.wait(M.FlashSeconds)
						TweenService:Create(effect, TweenInfo.new(M.FlashDecay), {Brightness = mood.Brightness}):Play()
						task.wait(M.FlashDecay)
					end
				end
			end)
		end
	end

	apply(nil)
	while effect.Parent do
		task.wait(M.CheckSeconds)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local stage = root and StageZone.At(root.Position)
		if stage ~= current then current = stage apply(stage) end
	end
end

return Mood
