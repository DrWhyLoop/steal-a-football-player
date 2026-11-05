-- HumanoidDescription R15 skeletons with original, asset-free procedural surfaces.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local BossFactory = {}

local canonical = {
	Head = Vector3.new(1.3, 1.2, 1.2), UpperTorso = Vector3.new(2, 1.6, 1), LowerTorso = Vector3.new(1.8, 0.7, 1),
	UpperArm = Vector3.new(0.65, 1.1, 0.68), LowerArm = Vector3.new(0.61, 1.1, 0.63),
	Hand = Vector3.new(0.62, 0.5, 0.64), UpperLeg = Vector3.new(0.8, 1.25, 0.8),
	LowerLeg = Vector3.new(0.72, 1.25, 0.74), Foot = Vector3.new(0.8, 0.45, 1.16),
}

local function localScale(frame, scale)
	return CFrame.new(frame.Position * scale) * frame.Rotation
end

local function primitive(model, name, shape, size, frame, color, material)
	local p = Instance.new(shape == "Wedge" and "WedgePart" or "Part")
	if p:IsA("Part") then
		p.Shape = shape == "Ball" and Enum.PartType.Ball or shape == "Cylinder" and Enum.PartType.Cylinder or Enum.PartType.Block
		if shape == "Head" then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = p
		end
	end
	p.Name, p.Size, p.CFrame = name, size, frame
	p.Color, p.Material = color, material or Enum.Material.SmoothPlastic
	p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
	p.Massless = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function weld(parent, part)
	local joint = Instance.new("WeldConstraint")
	joint.Part0, joint.Part1 = parent, part
	joint.Parent = part
end

local function category(name)
	if name == "Head" or name:find("LowerArm") or name:find("Hand") then return "Skin" end
	if name == "UpperTorso" or name:find("UpperArm") then return "Shirt" end
	if name == "LowerTorso" or name:find("UpperLeg") then return "Shorts" end
	return name:find("Foot") and "Boots" or "Socks"
end

local function key(name)
	return name:gsub("^Left", ""):gsub("^Right", "")
end

function BossFactory.Build(recipe, groundFrame)
	local s = recipe.Scale
	local description = Instance.new("HumanoidDescription")
	description.HeightScale, description.WidthScale = s.Height or 1, s.Width or 1
	description.DepthScale, description.HeadScale = s.Depth or 1, s.Head or 1
	description.BodyTypeScale, description.ProportionScale = s.BodyType or 0, s.Proportion or 0
	description.HeadColor, description.TorsoColor = recipe.SkinColor, recipe.ShirtColor
	description.LeftArmColor, description.RightArmColor = recipe.SkinColor, recipe.SkinColor
	description.LeftLegColor, description.RightLegColor = recipe.ShortsColor, recipe.ShortsColor
	local model = Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	description:Destroy()
	model.Name = recipe.Name
	local humanoid, root = model:FindFirstChildOfClass("Humanoid"), model.HumanoidRootPart
	humanoid.AutomaticScalingEnabled, humanoid.AutoRotate = false, false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	root.Anchored, root.Transparency = true, 1
	root.CanCollide, root.CanTouch, root.CanQuery = false, false, false
	model.PrimaryPart = root

	local replacements, parts, scales = {}, {}, {}
	-- Keep the engine's R15 skeleton and scaling; replace default surfaces without asset IDs.
	for _, old in model:GetChildren() do
		if old:IsA("BasePart") and old ~= root then
			local name = old.Name
			local factor = name == "LowerTorso" and Vector3.new(1, 2, 1) or Vector3.one
			if name:find("Arm") then factor *= s.Arms or 1 end
			if name:find("Hand") then
				factor *= (s.Arms or 1) * (s.Hands or 1)
				factor *= Vector3.new(0.85, math.max(1, old.Size.X * 0.65 / old.Size.Y), 0.85)
			end
			if name:find("Leg") then factor *= Vector3.new(1, s.Legs or 1, 1) end
			local kind = category(name)
			local color = kind == "Skin" and recipe.SkinColor or recipe[kind .. "Color"]
			local material = recipe.Materials[kind] or recipe.Materials.Default
			local p = primitive(model, name, name == "Head" and "Head" or "Ball", old.Size * factor, old.CFrame, color, material)
			replacements[old], parts[name] = p, p
			scales[name] = p.Size / canonical[key(name)]
			old.Name = "_Replaced_" .. name
			for _, child in old:GetChildren() do
				if child:IsA("Motor6D") or child:IsA("Attachment") then
					if child:IsA("Attachment") then child.CFrame = localScale(child.CFrame, factor) end
					child.Parent = p
				end
			end
		end
	end
	local joints = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BodyColors") or d:IsA("Motor6D") or d:IsA("Decal") or d:IsA("SurfaceAppearance") or d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
	end
	for old in replacements do old:Destroy() end
	-- Build explicit Motor6Ds from the description's paired R15 rig attachments.
	-- Engine-generated models can use animation constraints rather than Motor6Ds.
		parts.HumanoidRootPart = root
	local links = {
		{"Root", "HumanoidRootPart", "LowerTorso"}, {"Waist", "LowerTorso", "UpperTorso"},
		{"Neck", "UpperTorso", "Head"},
	}
	for _, side in {"Left", "Right"} do
		table.insert(links, {side .. "Shoulder", "UpperTorso", side .. "UpperArm"})
		table.insert(links, {side .. "Elbow", side .. "UpperArm", side .. "LowerArm"})
		table.insert(links, {side .. "Wrist", side .. "LowerArm", side .. "Hand"})
		table.insert(links, {side .. "Hip", "LowerTorso", side .. "UpperLeg"})
		table.insert(links, {side .. "Knee", side .. "UpperLeg", side .. "LowerLeg"})
		table.insert(links, {side .. "Ankle", side .. "LowerLeg", side .. "Foot"})
	end
	for _, link in links do
		local a, b = parts[link[2]], parts[link[3]]
		local attachmentName = link[1] .. "RigAttachment"
		local joint = Instance.new("Motor6D")
		joint.Name, joint.Part0, joint.Part1 = link[1], a, b
		joint.C0, joint.C1 = a[attachmentName].CFrame, b[attachmentName].CFrame
		joint.Parent = a
		joints[a] = joints[a] or {}
		table.insert(joints[a], joint)
	end
	local queue = {root}
	local index = 1
	while index <= #queue do
		local parent = queue[index]
		for _, joint in joints[parent] or {} do
			joint.Part1.CFrame = parent.CFrame * joint.C0 * joint.C1:Inverse()
			table.insert(queue, joint.Part1)
		end
		index += 1
	end

	local function adorn(spec)
		local parent = assert(parts[spec.Body], "Unknown body: " .. spec.Body)
		local scale = scales[spec.Body]
		local rotation = spec.Rotation or Vector3.zero
		local frame = CFrame.new(spec.Position) * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
		local p = primitive(model, spec.Name, spec.Shape or "Ball", spec.Size * scale, parent.CFrame * localScale(frame, scale), spec.Color, spec.Material)
		weld(parent, p)
		parts[spec.Name], scales[spec.Name] = p, scale
	end
	-- Rounded joint caps keep ellipsoid limb ends visually connected.
	for _, side in {"Left", "Right"} do
		for _, segment in {"UpperArm", "LowerArm", "LowerLeg"} do
			local body = side .. segment
			local p = parts[body]
			local diameter = math.min(p.Size.X, p.Size.Z)
			local cap = primitive(model, body .. "JointCap", "Ball", Vector3.one * diameter,
				p.CFrame * CFrame.new(0, p.Size.Y / 2, 0), p.Color, p.Material)
			weld(p, cap)
		end
	end
	-- Short rounded bridges close visible gaps at the neck, waist and wrists.
	for _, link in links do
		if link[1] == "Neck" or link[1] == "Waist" or link[1]:find("Wrist") or link[1]:find("Shoulder") then
			local a, b = parts[link[2]], parts[link[3]]
			local joint = a:FindFirstChild(link[1])
			local diameter = math.min(a.Size.X, b.Size.X) * 0.65
			local length = math.min(a.Size.Y, b.Size.Y) * 0.4 + 0.15
			local p = primitive(model, link[1] .. "Bridge", "Cylinder", Vector3.new(length, diameter, diameter),
				a.CFrame * joint.C0 * CFrame.Angles(0, 0, link[1]:find("Shoulder") and 0 or math.rad(90)), b.Color, b.Material)
			weld(a, p)
		end
	end
	for _, spec in recipe.Hair do adorn(spec) end
	for _, spec in recipe.Extras do adorn(spec) end
	for _, side in {-1, 1} do
		adorn({
			Name = side == -1 and "LeftEye" or "RightEye", Body = "Head", Shape = "Block",
			Size = recipe.Eyes.Size, Position = Vector3.new(side * recipe.Eyes.Separation, recipe.Eyes.Height, -(recipe.Eyes.Depth or 0.625)),
			Color = recipe.Eyes.Color, Material = Enum.Material.Neon,
		})
	end

	local rate, lights = 0, 0
	for i, spec in recipe.Effects do
		local attachment = Instance.new("Attachment")
		attachment.Name = "BossEffectAttachment" .. i
		attachment.Position = spec.Position * scales[spec.Body]
		attachment.Parent = assert(parts[spec.Body])
		attachment.WorldCFrame = CFrame.new(attachment.WorldPosition)
		if spec.Type == "Light" then
			lights += 1
			local effect = Instance.new("PointLight")
			effect.Name, effect.Color = "BossLight", spec.Color
			effect.Range, effect.Brightness = Config.BossLightRange, Config.BossLightBrightness
			effect.Shadows, effect.Enabled = false, false
			effect.Parent = attachment
		elseif spec.Type == "Lightning" then
			local previous
			for pointIndex, point in spec.Points do
				local node = Instance.new("Attachment")
				node.Name = "LightningNode" .. i .. "_" .. pointIndex
				node.Position = (spec.Position + point) * scales[spec.Body]
				node.Parent = parts[spec.Body]
				if previous then
					local beam = Instance.new("Beam")
					beam.Name = "BossLightning"
					beam.Attachment0, beam.Attachment1 = previous, node
					beam.Color = ColorSequence.new(spec.Color)
					beam.Width0, beam.Width1 = 0.09, 0.09
					beam.LightEmission, beam.FaceCamera = 1, true
					beam.Enabled = false
					beam.Parent = attachment
				end
				previous = node
			end
		elseif spec.Type == "Particle" then
			rate += spec.Rate
			local effect = Instance.new("ParticleEmitter")
			effect.Name = "BossParticles"
			effect.Texture = "rbxasset://textures/particles/" .. spec.Texture .. "_main.dds"
			effect.Color = ColorSequence.new(spec.Color)
			effect.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, spec.Size), NumberSequenceKeypoint.new(0.6, spec.Size * 0.8), NumberSequenceKeypoint.new(1, 0)})
			effect.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.8, 0.3), NumberSequenceKeypoint.new(1, 1)})
			effect.Lifetime, effect.Rate, effect.Speed = spec.Lifetime, spec.Rate, spec.Speed
			effect.SpreadAngle = spec.Spread
			effect.Acceleration = spec.Acceleration or Vector3.new(0, 1.2, 0)
			effect.LightEmission = spec.Texture == "smoke" and 0.1 or 0.9
			effect.Rotation, effect.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-65, 65)
			effect.Enabled = false
			effect.Parent = attachment
		end
	end
	local count = 0
	for _, d in model:GetDescendants() do if d:IsA("BasePart") then count += 1 end end
	assert(count <= Config.BossMaxParts and rate <= Config.BossMaxParticleRate and lights <= 1, "Boss budget exceeded: " .. recipe.Name)
	model:ScaleTo(recipe.StageScale)
	local floorY = math.min(parts.LeftFoot.Position.Y - parts.LeftFoot.Size.Y / 2, parts.RightFoot.Position.Y - parts.RightFoot.Size.Y / 2)
	local rootHeight = root.Position.Y - floorY
	model:PivotTo(groundFrame * CFrame.new(0, rootHeight, 0))
	model:SetAttribute("BossName", recipe.Name)
	model:SetAttribute("Stage", recipe.Stage)
	model:SetAttribute("StageScale", recipe.StageScale)
	model:SetAttribute("PartCount", count)
	model:SetAttribute("ParticleRate", rate)
	model:SetAttribute("LightCount", lights)
	model:SetAttribute("GroundToRoot", rootHeight)
	return model
end

function BossFactory.SetEffectsEnabled(model, enabled)
	for _, d in model:GetDescendants() do
		if d:IsA("ParticleEmitter") or d:IsA("PointLight") or d:IsA("Trail") or d:IsA("Beam") then d.Enabled = enabled end
	end
end

return BossFactory
