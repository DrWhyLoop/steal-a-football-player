--[[
	CarryHud: small readout of the card being carried. Purely cosmetic - reads the
	CarriedCard / CarriedTier attributes the server sets on the player.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local CarryHud = {}

function CarryHud.Init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "CarryHudGui"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -90)
	label.Size = UDim2.new(0, 320, 0, 40)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	label.BackgroundTransparency = 0.3
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Visible = false
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	local function refresh()
		local name = player:GetAttribute("CarriedCard")
		local tier = player:GetAttribute("CarriedTier")
		if name and tier then
			label.Text = ("Carrying: %s [%s]"):format(name, tier)
			label.TextColor3 = Config.Tiers[tier].Color
			label.Visible = true
		else
			label.Visible = false
		end
	end

	player:GetAttributeChangedSignal("CarriedCard"):Connect(refresh)
	player:GetAttributeChangedSignal("CarriedTier"):Connect(refresh)
	refresh()
end

return CarryHud
