-- Upgrades shop (Config.Upgrades), opened from the More menu. Levels, tokens and cash arrive as Player attributes; the server validates every buy.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local Remotes = require(RS.Shared.Remotes)
local Format = require(RS.Shared.NumberFormat)
local Kit = require(script.Parent.UIKit)
local UI = {}

local function amount(def, value) return Format.Money(value * def.Scale) .. def.Unit end

function UI.Init()
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "UpgradeMenu"
	gui.ResetOnSpawn = false
	gui.Parent = player.PlayerGui
	local open = Kit.Nav(gui, "Upgrades", "energy", 7, true)
	local panel, title, list = Kit.Panel(gui, "Upgrades", "UPGRADES", "Permanent. Kept when you rebirth.", 30)
	local status = Kit.Label(panel, "", UDim2.new(1, -32, 0, 24), UDim2.new(0, 16, 1, -28))
	status.TextColor3 = Config.UITheme.Muted

	local rows = {}
	for order, def in Config.Upgrades.Defs do
		local frame = Instance.new("Frame")
		frame.LayoutOrder = order
		frame.Size = UDim2.new(1, -8, 0, 112)
		frame.Parent = list
		local name = Kit.Label(frame, def.Name, UDim2.new(1, -24, 0, 24), UDim2.fromOffset(12, 8))
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Font = Enum.Font.FredokaOne
		name.TextSize = 18
		local detail = Kit.Label(frame, "", UDim2.new(1, -24, 0, 36), UDim2.fromOffset(12, 32))
		detail.TextXAlignment = Enum.TextXAlignment.Left
		detail.TextYAlignment = Enum.TextYAlignment.Top
		detail.TextSize = 14
		detail.TextColor3 = Config.UITheme.Muted
		local button = Kit.Button(frame, "", UDim2.new(1, -24, 0, 36), UDim2.new(0, 12, 1, -44))
		button.Activated:Connect(function() Remotes.UpgradeRequest:FireServer("Buy", def.Id) end)
		rows[def] = {detail = detail, button = button, name = name}
	end

	local function refresh()
		local tokens, cash = player:GetAttribute("QuestTokens") or 0, player:GetAttribute("Cash") or 0
		title.Text = ("UPGRADES  |  %s tokens"):format(Format.Exact(tokens))
		for def, row in rows do
			local level = player:GetAttribute("Upgrade_" .. def.Id) or 0
			local cost = def.Costs[level + 1]
			row.name.Text = ("%s  (Lv %d/%d)"):format(def.Name, level, #def.Costs)
			row.detail.Text = def.Hint .. "\n" .. ("Now +%s"):format(amount(def, def.Step * level)) .. (cost and (" -> +%s"):format(amount(def, def.Step * (level + 1))) or "")
			if not cost then
				Kit.State(row.button, "Max level", true, false)
			else
				local price = def.Currency == "Tokens" and Format.Exact(cost) .. " tokens" or "$" .. Format.Compact(cost)
				local balance = def.Currency == "Tokens" and tokens or cash
				Kit.State(row.button, "Buy  " .. price, false, balance >= cost)
			end
		end
	end
	for _, name in {"QuestTokens", "Cash"} do player:GetAttributeChangedSignal(name):Connect(function() if panel.Visible then refresh() end end) end
	for _, def in Config.Upgrades.Defs do
		player:GetAttributeChangedSignal("Upgrade_" .. def.Id):Connect(function() if panel.Visible then refresh() end end)
	end
	Remotes.UpgradeStatus.OnClientEvent:Connect(function(text) status.Text = text end)
	open.Activated:Connect(function()
		panel.Visible = not panel.Visible
		if panel.Visible then status.Text = "" refresh() end
	end)
end

return UI
