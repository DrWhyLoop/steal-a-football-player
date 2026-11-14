--[[
	CarryHud: small readout of the card being carried. Purely cosmetic - reads the
	CarriedCard / CarriedTier attributes the server sets on the player.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Remotes=require(ReplicatedStorage.Shared.Remotes)
local Kit=require(script.Parent.UIKit)
local CarryHud = {}

function CarryHud.Init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "CarryHudGui"
	gui.Parent = playerGui
	Kit.Screen(gui)

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -90)
	label.Size = UDim2.fromScale(0.5, 0.06)
	label.TextScaled = true
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Visible = false
	label.Parent = gui
	Instance.new("UITextSizeConstraint", label).MaxTextSize = 20
	Kit.Text(label, "gold")

 local layout=Config.FocusUI
 local drop=Instance.new("TextButton")
 drop.Name="Drop" drop.AnchorPoint=Vector2.new(0,1)
 drop.Position=UDim2.new(0,16,1,-layout.ActionBottom)
 drop.Size=UDim2.fromOffset(layout.ActionWidth,layout.ActionHeight)
 drop.BackgroundColor3=Color3.fromRGB(165,65,48)
 drop.Text="Drop player" drop.TextColor3=Color3.new(1,1,1)
 drop.Font=Enum.Font.GothamBold drop.TextSize=16 drop.Visible=false drop.Parent=gui
 local rounding=Instance.new("UICorner") rounding.CornerRadius=UDim.new(0,10) rounding.Parent=drop

 Kit.Animate(drop)
 Kit.OnResize(function(view)
  drop.Size=UDim2.fromOffset(view.Y<500 and 120 or layout.ActionWidth,layout.ActionHeight)
  drop.Position=UDim2.new(0,16,1,-(view.Y<500 and 110 or 235))
 end)
 drop.Activated:Connect(function() Remotes.DropPlayer:FireServer() end)
 local function refresh()
  gui.Enabled=Kit.Visible()
		drop.Visible=player:GetAttribute("CanDropPlayer")==true
  local name = player:GetAttribute("CarriedCard")
		local tier = player:GetAttribute("CarriedTier")
		if name and tier then
			label.Text = ("%s · %s"):format(name, tier)
			label.Visible = true
		else
			label.Visible = false
		end
	end

	player:GetAttributeChangedSignal("CarriedCard"):Connect(refresh)
	player:GetAttributeChangedSignal("CarriedTier"):Connect(refresh)
 player:GetAttributeChangedSignal("CanDropPlayer"):Connect(refresh)
	playerGui:GetAttributeChangedSignal("MenuOpen"):Connect(refresh)
	playerGui:GetAttributeChangedSignal("UIHidden"):Connect(refresh)
 refresh()
end

return CarryHud
