-- Plaza NPCs: cosmetic, computed on each client (nothing replicates, the server does no work). The models are anchored, non-colliding and have an AnimationController instead of a Humanoid (a Humanoid turns limb collision back on).
-- Near the player an NPC walks its Config.Npc route with a walk clip, pauses to idle at each corner and waves when the player comes close.
local CS = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local N = Config.Npc
local Motion = {}

local function flat(v: Vector3): Vector3 return Vector3.new(v.X, 0, v.Z) end

local function newNpc(model: Model)
	local spectatorSource = model:GetAttribute("SpectatorSource")
	local route = N.Routes[spectatorSource or model.Name]
	local controller = model:FindFirstChildWhichIsA("AnimationController")
	local animator = controller and controller:FindFirstChildWhichIsA("Animator")
	if not route or not animator then return nil end
	local tracks = {}
	for name, id in N.Animations[route.Rig] do
		if spectatorSource and name ~= "Idle" then continue end
		local animation = Instance.new("Animation") animation.AnimationId = "rbxassetid://" .. id
		tracks[name] = animator:LoadAnimation(animation)
		tracks[name].Priority = N.Priority[name]
		animation:Destroy()
	end
	local home = model:GetAttribute("Home")
	local points = {}
	for _, offset in route.Points do table.insert(points, home + offset) end
	if spectatorSource then tracks.Idle.Looped = true end
	return { spectator = spectatorSource ~= nil, model = model, tracks = tracks, points = points, target = 2, position = home, look = model:GetPivot().LookVector,
		state = "", stateEnd = 0, lastWave = -N.WaveCooldown }
end

local function setState(npc, state: string, now: number)
	if npc.state == state then return end
	if npc.tracks[npc.state] then npc.tracks[npc.state]:Stop(N.Fade) end
	npc.state = state
	local track = npc.tracks[state == "Walk" and "Walk" or state == "Wave" and "Wave" or "Idle"]
	track:Play(N.Fade)
	if state == "Walk" then track:AdjustSpeed(N.WalkSpeed / N.AnimRefSpeed) end
	npc.stateEnd = now + (state == "Wave" and N.WaveSeconds or state == "Idle" and math.random(N.IdlePause[1], N.IdlePause[2]) or math.huge)
end

function Motion.Init()
	local npcs = {} -- model -> state, only for NPCs near the player
	task.spawn(function()
		while true do
			task.wait(N.CheckSeconds)
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			for model, npc in npcs do
				if not model.Parent or not root or (flat(npc.position) - flat(root.Position)).Magnitude > N.ActiveDistance * 1.2 then
					for _, track in npc.tracks do track:Stop(0) track:Destroy() end
					if model.Parent and not npc.spectator then model:PivotTo(CFrame.lookAt(model:GetAttribute("Home"), model:GetAttribute("Home") + npc.look)) end
					npcs[model] = nil
				end
			end
			if root then
				for _, model in CS:GetTagged(N.Tag) do
					local home = model:GetAttribute("Home")
					if not npcs[model] and home and (flat(home) - flat(root.Position)).Magnitude <= N.ActiveDistance then
						npcs[model] = newNpc(model)
						if npcs[model] then setState(npcs[model], "Idle", os.clock()) end
					end
				end
			end
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local now = os.clock()
		for _, npc in npcs do
			if npc.spectator then continue end
			local toPlayer = root and flat(root.Position - npc.position)
			local wantLook = nil
			if npc.state ~= "Wave" and toPlayer and toPlayer.Magnitude <= N.WaveDistance and now - npc.lastWave >= N.WaveCooldown then
				npc.lastWave = now
				setState(npc, "Wave", now)
			end
			if npc.state == "Wave" then
				if toPlayer and toPlayer.Magnitude > 0.01 then wantLook = toPlayer.Unit end
				if now >= npc.stateEnd then setState(npc, "Idle", now) end
			elseif npc.state == "Idle" then
				if now >= npc.stateEnd then setState(npc, "Walk", now) end
			else
				local to = flat(npc.points[npc.target] - npc.position)
				local step = N.WalkSpeed * dt
				if to.Magnitude <= step then
					npc.position = npc.points[npc.target]
					npc.target = npc.target % #npc.points + 1
					setState(npc, "Idle", now)
				else
					wantLook = to.Unit
					npc.position += wantLook * step
				end
			end
			if wantLook then npc.look = npc.look:Lerp(wantLook, 1 - math.exp(-N.TurnRate * dt)).Unit end
			npc.model:PivotTo(CFrame.lookAt(npc.position, npc.position + npc.look))
		end
	end)
end

return Motion
