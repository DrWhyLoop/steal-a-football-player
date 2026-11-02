--[[
	AnnouncementUI: top-of-screen banner for server-wide announcements (e.g. GOAT cube spawned).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local AnnouncementUI = {}

function AnnouncementUI.Init()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "AnnouncementGui"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 50
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	local banner = Instance.new("TextLabel")
	banner.Name = "Banner"
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, 70)
	banner.Size = UDim2.new(0.8, 0, 0, 56)
	banner.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	banner.BackgroundTransparency = 0.25
	banner.TextColor3 = Config.Tiers.GOAT.Color
	banner.TextScaled = true
	banner.Font = Enum.Font.GothamBlack
	banner.Visible = false
	banner.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = banner
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 34
	limit.Parent = banner

	local token = 0
	Remotes.Announcement.OnClientEvent:Connect(function(text: string)
		token += 1
		local mine = token
		banner.Text = text
		banner.TextTransparency = 0
		banner.BackgroundTransparency = 0.25
		banner.Visible = true
		task.delay(Config.AnnouncementSeconds, function()
			if token ~= mine then return end
			local tween = TweenService:Create(banner, TweenInfo.new(0.6), { TextTransparency = 1, BackgroundTransparency = 1 })
			tween:Play()
			tween.Completed:Wait()
			if token == mine then banner.Visible = false end
		end)
	end)
end

return AnnouncementUI
