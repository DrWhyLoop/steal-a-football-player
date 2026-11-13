-- Plaza NPCs: cosmetic, computed on each client (nothing replicates, the server does no work). The models are anchored, non-colliding and have an AnimationController instead of a Humanoid (a Humanoid turns limb collision back on).
-- Near the player an NPC walks its Config.Npc route with a walk clip, pauses to idle at each corner and waves when the player comes close.
local CS = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local N = Config.Npc
local Motion = {}
local CageFit=require(game.ReplicatedStorage.Shared.CageFit)

local function flat(v: Vector3): Vector3 return Vector3.new(v.X, 0, v.Z) end

local function distanceTo(model,home,root)
 local distance=root and (flat(home)-flat(root.Position)).Magnitude or math.huge
 local camera=workspace.CurrentCamera
 if model:GetAttribute("CagePreview") and camera then distance=math.min(distance,(home-camera.CFrame.Position).Magnitude) end
 return distance
end

local function newNpc(model: Model)
	local spectatorSource = model:GetAttribute("SpectatorSource")
	local preview=model:GetAttribute("CagePreview")
 local route = preview and {Rig="R15"} or N.Routes[spectatorSource or model.Name]
	local controller = model:FindFirstChildWhichIsA("AnimationController")
	local animator = controller and controller:FindFirstChildWhichIsA("Animator")
	if not route or not animator then return nil end
	local tracks = {}
	for name, id in (preview and N.CagePreview.Animations or N.Animations[route.Rig]) do
		if spectatorSource and name ~= "Idle" then continue end
		local animation = Instance.new("Animation") animation.AnimationId = "rbxassetid://" .. id
		tracks[name] = animator:LoadAnimation(animation)
		tracks[name].Priority = N.Priority[name]
  if preview then tracks[name].Looped=true end
		animation:Destroy()
	end
	local home = model:GetAttribute("Home")
	local points = {}
 local interior
 if preview then
  local cage=model.Parent:FindFirstChild("Cage") or model.Parent:FindFirstChild("CageVisual")
  local pedestal=model.Parent:FindFirstChild("Pedestal")
  if not cage or not cage:FindFirstChildWhichIsA("BasePart",true) or not model:FindFirstChild("LeftFoot") or not model:FindFirstChild("RightFoot") then return nil end
  interior=CageFit.Interior(cage,pedestal,N.CagePreview,model:GetAttribute("BaseFloorY"))
 end
	if preview then
  local half=model:GetAttribute("WalkHalfExtents")
  for _,offset in {Vector3.new(-half.X,0,-half.Z),Vector3.new(half.X,0,-half.Z),Vector3.new(half.X,0,half.Z),Vector3.new(-half.X,0,half.Z)} do table.insert(points,home+offset) end
 else
  for _, offset in route.Points do table.insert(points, home + offset) end
 end
	if spectatorSource then tracks.Idle.Looped = true end
	return { interior=interior,preview=preview,speed=preview and N.CagePreview.SpeedPerHeight*model:GetAttribute("PreviewHeight") or N.WalkSpeed, spectator = spectatorSource ~= nil, model = model, tracks = tracks, points = points, target = 2, position = home, look = model:GetPivot().LookVector,
		state = "", stateEnd = 0, lastWave = -N.WaveCooldown }
end

local function setState(npc, state: string, now: number)
	if npc.state == state then return end
	if npc.tracks[npc.state] then npc.tracks[npc.state]:Stop(N.Fade) end
	npc.state = state
	local track = npc.tracks[state == "Walk" and "Walk" or state == "Wave" and "Wave" or "Idle"]
	track:Play(N.Fade)
	if state == "Walk" then track:AdjustSpeed(npc.preview and math.max(N.CagePreview.MinAnimationSpeed,npc.speed/N.AnimRefSpeed) or npc.speed/N.AnimRefSpeed) end
	npc.stateEnd = now + (state == "Wave" and N.WaveSeconds or state == "Idle" and (npc.preview and N.CagePreview.Pause or math.random(N.IdlePause[1], N.IdlePause[2])) or math.huge)
end

function Motion.Init()
	local npcs = {} -- model -> state, only for NPCs near the player
 CS:GetInstanceRemovedSignal(N.Tag):Connect(function(model)
  local npc=npcs[model]
  if npc then for _,track in npc.tracks do track:Stop(0) track:Destroy() end npcs[model]=nil end
 end)
	task.spawn(function()
		while true do
			task.wait(N.CheckSeconds)
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			for model, npc in npcs do
				if not model.Parent or not root or distanceTo(model,npc.position,root) > N.ActiveDistance * 1.2 then
					for _, track in npc.tracks do track:Stop(0) track:Destroy() end
					if model.Parent and not npc.spectator then
      local home=model:GetAttribute("Home")
      if npc.preview then
       for _,joint in model:GetDescendants() do if joint:IsA("Motor6D") then joint.Transform=CFrame.identity end end
       model.PrimaryPart.CFrame=CFrame.lookAt(home,home+npc.look)
       local floor=CageFit.FloorAt(npc.interior.surfaces,home.X,home.Z,npc.interior.floor)
       CageFit.ApplyPose(model,floor+N.CagePreview.FloorClearance)
      else model:PivotTo(CFrame.lookAt(home,home+npc.look)) end
     end
					npcs[model] = nil
				end
			end
			if root then
				for _, model in CS:GetTagged(N.Tag) do
					local home = model:GetAttribute("Home")
					if not npcs[model] and home and distanceTo(model,home,root) <= N.ActiveDistance then
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
			if npc.spectator or npc.model:GetAttribute("RevealActive") then continue end
			local toPlayer = root and flat(root.Position - npc.position)
			local wantLook = nil
			if not npc.preview and npc.state ~= "Wave" and toPlayer and toPlayer.Magnitude <= N.WaveDistance and now - npc.lastWave >= N.WaveCooldown then
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
				local step = npc.speed * dt
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
			if npc.preview then npc.model.PrimaryPart.CFrame=CFrame.lookAt(npc.position,npc.position+npc.look)
   else npc.model:PivotTo(CFrame.lookAt(npc.position, npc.position + npc.look)) end
		end
	end)
 -- Apply after the animation pose: one sole stays on the measured base surface.
 RunService:BindToRenderStep("CagePreviewFeet",Enum.RenderPriority.Last.Value,function()
  for model,npc in npcs do
   if npc.preview and model.Parent and not model:GetAttribute("RevealActive") then
    local pos=model:GetPivot().Position
    local floor=CageFit.FloorAt(npc.interior.surfaces,pos.X,pos.Z,npc.interior.floor)
    CageFit.ApplyPose(model,floor+N.CagePreview.FloorClearance)
   end
  end
 end)
end

return Motion
