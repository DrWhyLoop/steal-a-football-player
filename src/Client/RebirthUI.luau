local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local Remotes = require(RS.Shared.Remotes)
local Format = require(RS.Shared.NumberFormat)
local Rebirth = require(RS.Shared.Rebirth)
local Kit = require(script.Parent.UIKit)
local UI = {}

function UI.Init()
	local player = Players.LocalPlayer
	local cfg = Config.Rebirth
	local gui = Instance.new("ScreenGui")
	gui.Name = "RebirthMenu"
	gui.ResetOnSpawn = false
	gui.Parent = player.PlayerGui
	local open = Kit.Nav(gui, "Rebirth", "confirm", 0)
	local panel, title, list = Kit.Panel(gui, "Rebirth", "REBIRTH", "Reset your Speed Points for a permanent boost. Cash, footballers, tools, trails, treadmills and upgrades are kept.", 0)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -8, 0, 250)
	card.Parent = list

	local level = Kit.Label(card, "", UDim2.new(1, -24, 0, 28), UDim2.fromOffset(12, 10))
	level.Font = Enum.Font.FredokaOne
	level.TextSize = 20
	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -24, 0, 22)
	track.Position = UDim2.fromOffset(12, 46)
	track.BackgroundColor3 = Config.UITheme.Disabled
	track.Parent = card
	Instance.new("UICorner", track).CornerRadius = UDim.new(0, 8)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Config.UITheme.Selected
	fill.Parent = track
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 8)
	local points = Kit.Label(card, "", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(12, 74))
	points.TextColor3 = Config.UITheme.Muted
	local multipliers = Kit.Label(card, "", UDim2.new(1, -24, 0, 70), UDim2.fromOffset(12, 100))
	multipliers.TextXAlignment = Enum.TextXAlignment.Left
	local status = Kit.Label(card, "", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(12, 172))
	status.TextColor3 = Config.UITheme.Muted
	local button = Kit.Button(card, "", UDim2.new(1, -24, 0, 44), UDim2.new(0, 12, 1, -56))

	local confirmUntil = 0
	local function refresh()
		local count = player:GetAttribute("Rebirths") or 0
		local speed = player:GetAttribute("Speed") or 0
		local ready = Rebirth.Ready(speed, count)
		local levelNow = Rebirth.Level(speed, count)
		local maxed = count >= cfg.Max
		title.Text = ("REBIRTH  |  %d/%d done"):format(count, cfg.Max)
		level.Text = maxed and "Max rebirths reached" or ("Level %d/%d"):format(levelNow, cfg.Segments)
		fill.Size = UDim2.fromScale(maxed and 1 or levelNow / cfg.Segments, 1)
		points.Text = maxed and "" or ("%s / %s Speed Points"):format(Format.Compact(speed), Format.Compact(Rebirth.Requirement(count)))
		local nextCount = math.min(count + 1, cfg.Max)
		multipliers.Text = ("Income x%.2f -> x%.2f\nSpeed gain x%.2f -> x%.2f\nResets: Speed Points only"):format(
			Rebirth.Income(count), Rebirth.Income(nextCount), Rebirth.Gain(count), Rebirth.Gain(nextCount))
		local confirming = ready and os.clock() < confirmUntil
		Kit.State(button, maxed and "Max" or confirming and "Tap again to confirm" or ready and "Rebirth" or "Fill the bar first", confirming, ready)
	end
	button.Activated:Connect(function()
		if os.clock() < confirmUntil then
			confirmUntil = 0
			Remotes.RebirthRequest:FireServer()
		else
			confirmUntil = os.clock() + cfg.ConfirmSeconds
			task.delay(cfg.ConfirmSeconds, refresh)
		end
		refresh()
	end)
	open.Activated:Connect(function()
		panel.Visible = not panel.Visible
		confirmUntil = 0
		refresh()
	end)
	for _, key in { "Speed", "Rebirths" } do
		player:GetAttributeChangedSignal(key):Connect(function() if panel.Visible then refresh() end end)
	end
	Remotes.RebirthStatus.OnClientEvent:Connect(function(text) status.Text = text refresh() end)
	refresh()
end

return UI
