--[[
	AnnouncementUI: top-centre text for server-wide announcements (e.g. GOAT cube spawned). No box: gold text with a dark outline.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local UIKit = require(script.Parent.UIKit)
local AnnouncementUI = {}

function AnnouncementUI.Init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "AnnouncementGui"
	gui.DisplayOrder = 50
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	UIKit.Screen(gui)

	local banner = Instance.new("TextLabel")
	banner.Name = "Banner"
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, Config.UIScreen.TopAnnounce)
	banner.Size = UDim2.fromScale(0.8, 0.07)
	banner.TextScaled = true
	banner.Visible = false
	banner.Parent = gui
	Instance.new("UITextSizeConstraint", banner).MaxTextSize = 26
	UIKit.Text(banner, "gold")

	local token = 0
	Remotes.Announcement.OnClientEvent:Connect(function(text: string)
		token += 1
		local mine = token
		banner.Text = text
		UIKit.Fade(banner, 0, 0)
		banner.Visible = true
		task.delay(Config.AnnouncementSeconds, function()
			if token ~= mine then return end
			UIKit.Fade(banner, 0.6, 1)
			task.wait(0.6)
			if token == mine then banner.Visible = false end
		end)
	end)
end

return AnnouncementUI
