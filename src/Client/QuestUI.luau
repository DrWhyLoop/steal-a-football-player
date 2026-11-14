local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local Remotes = require(RS.Shared.Remotes)
local Format = require(RS.Shared.NumberFormat)
local Kit = require(script.Parent.UIKit)
local UI = {}

local function duration(seconds)
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 86400 then return ("%dd %dh"):format(seconds // 86400, seconds % 86400 // 3600) end
	return ("%dh %dm"):format(seconds // 3600, seconds % 3600 // 60)
end

function UI.Init()
	local player = Players.LocalPlayer
	local cfg = Config.Quests
	local gui = Instance.new("ScreenGui")
	gui.Name = "QuestMenu"
	gui.ResetOnSpawn = false
	gui.Parent = player.PlayerGui
	Kit.Screen(gui)
	local open = Kit.Nav(gui, "Quests", "profile", 6)
	local panel, title, list = Kit.Panel(gui, "Quests", "QUESTS", "", 0)
	local note -- the hint label under the title (Kit.Panel does not return it)
	for _, child in panel:GetChildren() do
		if child:IsA("TextLabel") and child ~= title then note = child end
	end

	local state, received = nil, 0
	local function countdown()
		local elapsed = os.clock() - received
		note.Text = ("Daily resets in %s  |  Weekly resets in %s"):format(duration(state.DayLeft - elapsed), duration(state.WeekLeft - elapsed))
	end
	local function header(text, order)
		local label = Kit.Label(list, text, UDim2.new(1, -8, 0, 28), UDim2.new())
		label.LayoutOrder = order
		label.Font = Enum.Font.FredokaOne
		label.TextSize = 18
		label.TextXAlignment = Enum.TextXAlignment.Left
	end
	local function row(scope, index, quest, order)
		local def = cfg.ById[quest.Id][scope]
		local frame = Instance.new("Frame")
		frame.LayoutOrder = order
		frame.Size = UDim2.new(1, -8, 0, 104)
		frame.Parent = list
		local amount = quest.Id == "Collect" and Format.Compact(quest.Target) or Format.Exact(quest.Target)
		local name = Kit.Label(frame, cfg.ById[quest.Id].Text:format(amount), UDim2.new(1, -150, 0, 26), UDim2.fromOffset(12, 8))
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Font = Enum.Font.FredokaOne
		local reward = Kit.Label(frame, ("+%d tokens"):format(def.Tokens), UDim2.fromOffset(120, 26), UDim2.new(1, -132, 0, 8))
		reward.TextXAlignment = Enum.TextXAlignment.Right
		reward.TextColor3 = Config.UITheme.Accent
		local track = Instance.new("Frame")
		track.Size = UDim2.new(1, -24, 0, 14)
		track.Position = UDim2.fromOffset(12, 40)
		track.BackgroundColor3 = Config.UITheme.Disabled
		track.Parent = frame
		Instance.new("UICorner", track).CornerRadius = UDim.new(0, 6)
		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale(math.clamp(quest.Progress / quest.Target, 0, 1), 1)
		fill.BackgroundColor3 = Config.UITheme.Selected
		fill.Parent = track
		Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 6)
		local progress = quest.Id == "Collect" and Format.Compact(quest.Progress) .. " / " .. Format.Compact(quest.Target)
			or ("%s / %s"):format(Format.Exact(quest.Progress), Format.Exact(quest.Target))
		local done = quest.Progress >= quest.Target
		local button = Kit.Button(frame, "", UDim2.new(1, -24, 0, 36), UDim2.new(0, 12, 1, -44))
		Kit.State(button, quest.Claimed and "Claimed" or done and "Claim" or progress, quest.Claimed, done and not quest.Claimed)
		button.Activated:Connect(function() Remotes.QuestRequest:FireServer("Claim", scope, index) end)
	end
	local function refresh()
		for _, child in list:GetChildren() do
			if child:IsA("GuiObject") then child:Destroy() end
		end
		if not state then return end
		title.Text = ("QUESTS  |  %s tokens"):format(Format.Exact(state.Tokens))
		countdown()
		header("DAILY", 1)
		for index, quest in state.Daily do row("Daily", index, quest, 1 + index) end
		header("WEEKLY", 10)
		for index, quest in state.Weekly do row("Weekly", index, quest, 10 + index) end
	end
	Remotes.QuestSync.OnClientEvent:Connect(function(newState)
		state, received = newState, os.clock()
		if panel.Visible then refresh() end
	end)
	open.Activated:Connect(function()
		panel.Visible = not panel.Visible
		if panel.Visible then
			Remotes.QuestRequest:FireServer("Sync")
			refresh()
		end
	end)
	task.spawn(function() -- the reset countdown
		while true do
			task.wait(30)
			if panel.Visible and state then countdown() end
		end
	end)
end

return UI
