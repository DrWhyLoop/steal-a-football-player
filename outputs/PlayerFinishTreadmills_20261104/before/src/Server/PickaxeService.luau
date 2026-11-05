--[[
	PickaxeService: server-side mining and fighting.
	The Pickaxe Tool lives in StarterPack (edit it in Studio). When a player activates it
	(mouse click, phone tap, gamepad - Tool.Activated replicates to the server) we:
	  1. enforce a per-player cooldown,
	  2. find the nearest target in range and in front: a cube, or another player carrying a card,
	  3. damage the cube / make the player drop their card,
	  4. cue the overhead strike, then validate the target again at impact.
	No client raycasts and no remotes are involved.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local LineOfSight = require(script.Parent.LineOfSight)

local PickaxeService = {}

local CubeService, CardService -- injected in Init
local lastSwing = {} -- [Player] = os.clock()

--- Distance to `position` if it is within range and in front of (or very close to) the root.
local function reachDistance(root: BasePart, position: Vector3): number?
	local offset = position - root.Position
	local distance = offset.Magnitude
	if distance > Config.PickaxeRange then return nil end
	if distance <= Config.PickaxeCloseRange then return distance end
	local flat = Vector3.new(offset.X, 0, offset.Z)
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if look.Magnitude > 0.01 and flat.Magnitude > 0.01 and flat.Unit:Dot(look.Unit) >= Config.PickaxeFacingDot then
		return distance
	end
	return nil
end

--- Nearest cube or card-carrying player. Returns (cube, victim); at most one is set.
local function findTarget(player: Player, root: BasePart): (Part?, Player?)
	local bestDistance = math.huge
	local cube, victim
	for _, inst in ipairs(CollectionService:GetTagged("Cube")) do
		if inst.Parent and not inst:GetAttribute("Dead") then
			local distance = reachDistance(root, (inst :: Part).Position)
			if distance and distance < bestDistance and LineOfSight.IsClear(root.Parent, inst, inst.Position) then
				bestDistance, cube, victim = distance, inst :: Part, nil
			end
		end
	end
	for _, other in ipairs(Players:GetPlayers()) do
		local otherRoot = other ~= player and CardService.GetCarried(other) and other.Character
			and other.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local distance = otherRoot and reachDistance(root, otherRoot.Position)
		if distance and distance < bestDistance and LineOfSight.IsClear(root.Parent, other.Character, otherRoot.Position) then
			bestDistance, cube, victim = distance, nil, other
		end
	end
	return cube, victim
end

local function onSwing(player: Player, tool: Tool)
	local now = os.clock()
	if lastSwing[player] and now - lastSwing[player] < Config.SwingCooldown then return end

	local char = player.Character
	if not char or tool.Parent ~= char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or humanoid.Health <= 0 or not root then return end
	lastSwing[player] = now

	tool:SetAttribute('SwingStart',workspace:GetServerTimeNow())
	task.delay(Config.Axes.ImpactTime,function()
		if not char.Parent or tool.Parent~=char or humanoid.Health<=0 or not root.Parent then return end
		local cube,victim=findTarget(player,root)
		if cube then CubeService.Damage(cube,Config.PickaxeDamage,player)
		elseif victim then CardService.DropCarried(victim) end
		local handle=tool:FindFirstChild('Handle')
		local sound=handle and handle:FindFirstChild((cube or victim) and 'HitSound' or 'MissSound')
		if sound then sound:Play() end
	end)
end

local function hookTool(player: Player, tool: Instance)
	if not tool:IsA("Tool") or tool.Name ~= Config.PickaxeName or tool:GetAttribute("Hooked") then return end
	tool:SetAttribute("Hooked", true)
	for name, soundId in pairs(Config.PickaxeSounds) do
		local sound = Instance.new("Sound")
		sound.Name = name .. "Sound"
		sound.SoundId = soundId
		sound.Parent = tool.Handle
	end
	tool.Activated:Connect(function() onSwing(player, tool) end)
end

local function watch(player: Player, container: Instance)
	for _, child in ipairs(container:GetChildren()) do
		hookTool(player, child)
	end
	container.ChildAdded:Connect(function(child) hookTool(player, child) end)
end

local function onCharacterAdded(player: Player, char: Model)
	watch(player, char)
	watch(player, player:WaitForChild("Backpack"))
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(char) onCharacterAdded(player, char) end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end

function PickaxeService.Init(cubeService, cardService)
	CubeService = cubeService
	CardService = cardService
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player) lastSwing[player] = nil end)
end

return PickaxeService
