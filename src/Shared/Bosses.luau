-- Original, asset-free boss recipes. All adornments are body-local primitive geometry.
local C = Color3.fromRGB
local V = Vector3.new
local M = Enum.Material

local function shape(name, body, kind, size, position, color, rotation, material)
	return {
		Name = name, Body = body, Shape = kind, Size = V(unpack(size)),
		Position = V(unpack(position)), Color = color,
		Rotation = V(unpack(rotation or {0, 0, 0})), Material = material,
	}
end

local function particle(body, position, color, texture, rate, speed, size)
	return {
		Type = "Particle", Body = body, Position = V(unpack(position)), Color = color,
		Texture = texture, Rate = rate, Speed = speed, Size = size,
		Lifetime = NumberRange.new(1.1, 1.7), Spread = Vector2.new(22, 22),
	}
end

local function light(color)
	return {Type = "Light", Body = "UpperTorso", Position = V(0, 0, -0.6), Color = color}
end

local function recipe(name, stage, scale, skin, shirt, shorts, socks, boots, eyes)
	return {
		Name = name, Stage = stage, Scale = scale, SkinColor = skin,
		ShirtColor = shirt, ShortsColor = shorts, SocksColor = socks, BootsColor = boots,
		Materials = {}, Eyes = {Color = eyes, Size = V(0.23, 0.14, 0.06), Separation = 0.29, Height = 0.08},
		Hair = {}, Extras = {}, Effects = {},
	}
end

local white, black = C(237, 240, 244), C(18, 21, 29)
local orange, gold = C(255, 112, 21), C(255, 193, 52)
local bosses = {}

local robot = recipe("Robot Tower", 1, {Height = 1.22, Width = 0.65, BodyType = 0.2, Proportion = 0.8}, C(137, 150, 163), C(93, 105, 118), C(56, 64, 76), C(156, 166, 177), C(44, 50, 60), white)
robot.Materials = {Skin = M.Metal}
robot.Eyes.Size = V(0.63, 0.17, 0.07)
robot.Eyes.Separation = 0.32
robot.Eyes.Depth = 0.73
table.insert(robot.Extras, shape("VisorBacking", "Head", "Block", {1.18, 0.36, 0.11}, {0, 0.08, -0.62}, black))
for _, side in {-1, 1} do
	local limb = side == -1 and "Left" or "Right"
	table.insert(robot.Extras, shape("NeckBolt" .. limb, "UpperTorso", "Cylinder", {0.22, 0.25, 0.25}, {side * 0.42, 0.87, 0}, black, {0, 0, 90}, M.Metal))
	table.insert(robot.Extras, shape("ElbowBolt" .. limb, limb .. "LowerArm", "Cylinder", {0.23, 0.26, 0.26}, {side * 0.32, 0.5, 0}, black, nil, M.Metal))
	table.insert(robot.Extras, shape("KneeBolt" .. limb, limb .. "LowerLeg", "Cylinder", {0.23, 0.28, 0.28}, {side * 0.37, 0.6, 0}, black, nil, M.Metal))
end
table.insert(bosses, robot)

local launcher = recipe("Long-Throw Launcher", 2, {Height = 0.92, Width = 1.2, Legs = 0.78, Arms = 1.25, Head = 1.06, BodyType = 0.3, Proportion = 0}, C(184, 133, 88), C(37, 135, 74), C(22, 62, 41), C(218, 234, 216), black, white)
launcher.Eyes.Height = 0
launcher.Hair = {shape("FlatCrop", "Head", "Ball", {1.34, 0.2, 1.23}, {0, 0.59, 0}, C(54, 40, 29))}
for _, side in {-1, 1} do
	local limb = side == -1 and "Left" or "Right"
	for j = 0, 7 do
		local a = j / 8 * math.pi * 3
		table.insert(launcher.Extras, shape("Spring" .. limb .. j, limb .. "LowerArm", "Cylinder", {0.35, 0.13, 0.13}, {math.cos(a) * 0.35, 0.26 + j * 0.065, math.sin(a) * 0.35}, C(156, 111, 40), {0, -math.deg(a), 0}, M.Metal))
	end
	table.insert(launcher.Extras, shape("Brow" .. limb, "Head", "Block", {0.46, 0.12, 0.12}, {side * 0.28, 0.2, -0.64}, C(61, 43, 28), {0, 0, side * 14}))
end
table.insert(launcher.Extras, shape("TowelTop", "LeftUpperArm", "Block", {0.8, 0.13, 0.9}, {0, 0.59, 0}, white))
table.insert(launcher.Extras, shape("TowelDrape", "LeftUpperArm", "Block", {0.65, 1.1, 0.12}, {0, 0.05, -0.43}, white))
table.insert(bosses, launcher)

local lion = recipe("Lion Mane", 3, {Height = 1, Width = 1.18, Arms = 1.08, BodyType = 0.55, Proportion = 0.2}, C(139, 79, 44), C(21, 41, 89), C(15, 28, 63), C(33, 57, 115), C(221, 161, 55), gold)
for j = 0, 13 do
	local a = j / 14 * math.pi * 2
	table.insert(lion.Hair, shape("Mane" .. j, "Head", "Wedge", {0.58, 0.83, 0.8}, {math.sin(a) * 0.91, math.cos(a) * 0.91, 0.05}, j % 2 == 0 and C(166, 77, 26) or C(206, 115, 43), {0, 0, -math.deg(a)}))
end
table.insert(bosses, lion)

local wing = recipe("Wing Spark", 4, {Width = 0.82, Height = 1.02, BodyType = 0.5, Proportion = 0.7}, C(200, 146, 99), white, C(38, 108, 198), white, C(42, 116, 224), C(60, 245, 255))
for j = -2, 2 do
	table.insert(wing.Hair, shape("LightningHair" .. j, "Head", "Wedge", {0.33, 0.8 + (2 - math.abs(j)) * 0.12, 0.85}, {j * 0.25, 0.78, 0}, C(255, 217, 42), {0, 0, j * -13}))
end
for _, side in {"Left", "Right"} do
	table.insert(wing.Extras, shape(side .. "BlueTrim", side .. "UpperArm", "Block", {0.69, 0.18, 0.69}, {0, -0.43, 0}, C(33, 116, 231)))
	table.insert(wing.Effects, particle(side .. "Foot", {0, 0, 0.1}, C(54, 177, 255), "sparkles", 4, NumberRange.new(0.9, 1.8), 0.55))
end
table.insert(bosses, wing)

local bulldog = recipe("Bicycle Bulldog", 5, {Width = 1.5, Depth = 1.2, Height = 0.91, BodyType = 0.35, Proportion = 0}, C(136, 86, 53), C(178, 32, 38), black, C(175, 29, 33), black, C(255, 206, 102))
for _, side in {-1, 1} do
	table.insert(bulldog.Extras, shape("Jowl" .. side, "Head", "Ball", {0.52, 0.56, 0.35}, {side * 0.4, -0.25, -0.65}, C(166, 108, 68)))
end
table.insert(bulldog.Extras, shape("Collar", "UpperTorso", "Ball", {1.15, 0.26, 1.15}, {0, 0.79, 0}, black))
for j = -2, 2 do
	table.insert(bulldog.Extras, shape("CollarSpike" .. j, "UpperTorso", "Wedge", {0.16, 0.28, 0.2}, {j * 0.22, 0.86, -0.62}, C(192, 200, 208), {0, 0, 180}, M.Metal))
end
table.insert(bosses, bulldog)

local header = recipe("Final Header", 6, {Height = 0.94, Head = 1.65, Width = 1.08, BodyType = 0.3, Proportion = 0.1}, C(167, 113, 78), C(21, 32, 62), C(13, 23, 47), C(32, 48, 84), C(227, 232, 236), C(255, 48, 54))
header.Hair = {shape("CloseCrop", "Head", "Ball", {1.32, 0.19, 1.2}, {0, 0.59, 0.02}, C(36, 29, 27))}
header.Extras = {shape("Forehead", "Head", "Ball", {1.4, 0.35, 0.28}, {0, 0.35, -0.64}, C(187, 130, 91))}
table.insert(bosses, header)

local rocket = recipe("Bun Rocket", 7, {Width = 0.86, Height = 1, BodyType = 0.55, Proportion = 0.7}, C(194, 139, 92), white, C(236, 100, 26), white, C(238, 91, 22), C(255, 182, 76))
rocket.Hair = {
	shape("SlickHair", "Head", "Ball", {1.31, 0.23, 1.2}, {0, 0.57, 0.04}, C(50, 29, 23)),
	shape("RocketBun", "Head", "Cylinder", {0.65, 0.55, 0.55}, {0, 0.93, 0.12}, C(76, 41, 26), {0, 0, 90}),
}
-- Stacked tapered cylinders form an asset-free low-poly cone on the rocket bun.
for j = 0, 4 do
	local diameter = 0.5 - j * 0.1
	table.insert(rocket.Hair, shape("BunCone" .. j, "Head", "Cylinder", {0.08, diameter, diameter}, {0, 1.29 + j * 0.08, 0.12}, C(94, 48, 26), {0, 0, 90}))
end
for _, side in {"Left", "Right"} do
	table.insert(rocket.Extras, shape(side .. "OrangeTrim", side .. "UpperArm", "Block", {0.69, 0.16, 0.69}, {0, -0.43, 0}, C(244, 113, 26)))
	table.insert(rocket.Effects, particle(side .. "Foot", {0, 0, 0.46}, orange, "fire", 4, NumberRange.new(1.2, 2.1), 1.5))
end
table.insert(bosses, rocket)

local granite = recipe("Granite Glove", 8, {Width = 1.4, Depth = 1.3, Height = 0.94, Hands = 1.4, BodyType = 0.2, Proportion = 0}, C(79, 87, 81), C(221, 178, 30), C(49, 58, 52), C(77, 86, 78), C(49, 57, 52), C(255, 168, 37))
granite.Materials = {Default = M.Slate}
for _, side in {"Left", "Right"} do
	table.insert(granite.Extras, shape(side .. "Glove", side .. "Hand", "Ball", {1.12, 0.85, 0.95}, {0, -0.05, -0.12}, C(126, 136, 126), nil, M.Slate))
	table.insert(granite.Extras, shape(side .. "GloveCuff", side .. "LowerArm", "Block", {0.88, 0.25, 0.86}, {0, -0.48, 0}, C(48, 70, 51), nil, M.Slate))
end
granite.Extras[#granite.Extras + 1] = shape("MossShoulder", "LeftUpperArm", "Block", {0.74, 0.18, 0.7}, {0, 0.53, 0}, C(76, 114, 43), nil, M.Grass)
granite.Extras[#granite.Extras + 1] = shape("MossBrow", "Head", "Block", {0.65, 0.16, 0.16}, {-0.2, 0.35, -0.63}, C(83, 121, 42), nil, M.Grass)
granite.Extras[#granite.Extras + 1] = shape("MossKnee", "RightLowerLeg", "Block", {0.6, 0.35, 0.13}, {0, 0.25, -0.38}, C(77, 110, 41), nil, M.Grass)
table.insert(bosses, granite)

local viking = recipe("Viking Engine", 9, {Height = 0.99, Width = 1.22, BodyType = 0.5, Proportion = 0.1}, C(202, 154, 110), C(104, 190, 231), C(235, 238, 240), C(104, 190, 231), C(40, 52, 65), C(147, 230, 255))
viking.Extras = {shape("Helmet", "Head", "Ball", {1.5, 0.57, 1.4}, {0, 0.55, 0.03}, C(104, 116, 127), nil, M.Metal)}
for _, side in {-1, 1} do
	for j = 1, 3 do
		table.insert(viking.Extras, shape("HelmetHorn" .. side .. j, "Head", "Cylinder", {0.44, 0.3 - j * 0.045, 0.3 - j * 0.045}, {side * (0.65 + j * 0.2), 0.57 + j * 0.19, 0.05}, C(207, 199, 168), {0, 0, side * (j * 17)}))
	end
	for j = 1, 5 do
		table.insert(viking.Hair, shape("Braid" .. side .. j, "Head", "Ball", {0.3, 0.35, 0.32}, {side * (0.65 + (j % 2) * 0.04), 0.25 - j * 0.3, 0.22}, C(211, 172, 61)))
	end
	local arm = side == -1 and "LeftUpperArm" or "RightUpperArm"
	table.insert(viking.Extras, shape("Pipe" .. side, arm, "Cylinder", {0.55, 0.27, 0.27}, {0, 0.78, 0.15}, C(92, 105, 115), {0, 0, 90}, M.Metal))
	table.insert(viking.Effects, particle("Pipe" .. side, {0.25, 0, 0}, white, "smoke", 3, NumberRange.new(1.4, 2.3), 0.8))
end
table.insert(bosses, viking)

local meteor = recipe("Meteor Nine", 10, {Width = 1.02, Height = 0.98, BodyType = 0.55, Proportion = 0.3}, C(37, 33, 31), black, black, black, C(38, 35, 31), orange)
meteor.Materials = {Skin = M.Basalt}
meteor.Hair = {shape("FrontTuft", "Head", "Wedge", {0.3, 0.32, 0.4}, {0, 0.68, -0.4}, black, {0, 180, 0})}
for _, side in {-1, 1} do
	local arm = side == -1 and "LeftLowerArm" or "RightLowerArm"
	table.insert(meteor.Extras, shape("ArmCrack" .. side, arm, "Block", {0.1, 0.85, 0.08}, {0, 0, -0.37}, orange, {0, 0, side * 17}, M.Neon))
	table.insert(meteor.Extras, shape("TorsoCrack" .. side, "UpperTorso", "Block", {0.08, 0.9, 0.08}, {side * 0.6, -0.1, -0.54}, orange, {0, 0, side * 24}, M.Neon))
	local upper = side == -1 and "LeftUpperArm" or "RightUpperArm"
	table.insert(meteor.Extras, shape("OrangeTrim" .. side, upper, "Block", {0.69, 0.16, 0.69}, {0, -0.44, 0}, orange))
	local foot = side == -1 and "LeftFoot" or "RightFoot"
	table.insert(meteor.Effects, particle(foot, {0, 0.05, 0}, orange, "fire", 4, NumberRange.new(1.2, 2.1), 1.5))
end
table.insert(meteor.Effects, light(orange))
table.insert(bosses, meteor)

local samba = recipe("Samba Grin", 11, {Height = 0.96, Width = 1, BodyType = 0.45, Proportion = 0.45}, C(135, 78, 43), C(247, 205, 36), C(106, 46, 158), C(247, 205, 36), C(69, 40, 100), C(195, 79, 255))
samba.Extras = {
	shape("Grin", "Head", "Ball", {1.1, 0.3, 0.16}, {0, -0.27, -0.65}, white, {0, 0, 0}),
	shape("Headband", "Head", "Block", {1.36, 0.2, 1.24}, {0, 0.37, 0}, C(197, 32, 43)),
}
for j = -2, 2 do
	table.insert(samba.Hair, shape("CrownCurl" .. j, "Head", "Ball", {0.4, 0.45, 0.65}, {j * 0.25, 0.65, 0.05}, C(34, 24, 21)))
end
for _, side in {-1, 1} do
	for j = 1, 4 do
		table.insert(samba.Hair, shape("LongCurl" .. side .. j, "Head", "Ball", {0.35, 0.39, 0.46}, {side * 0.66, 0.35 - j * 0.29, 0.3}, C(39, 27, 22)))
	end
	for j = 1, 3 do
		local arm = side == -1 and "LeftUpperArm" or "RightUpperArm"
		local colors = {C(36, 194, 171), C(232, 65, 99), C(126, 73, 220)}
		table.insert(samba.Extras, shape("Feather" .. side .. j, arm, "Wedge", {0.22, 0.8, 0.34}, {side * (0.12 + j * 0.15), 0.58 + j * 0.06, 0.05}, colors[j], {0, 0, side * (-20 - j * 12)}))
	end
end
samba.Effects = {particle("UpperTorso", {0, 0.6, 0}, C(213, 134, 255), "sparkles", 4, NumberRange.new(0.7, 1.1), 0.55)}
table.insert(bosses, samba)

local demon = recipe("Crimson Demon", 12, {Height = 1.24, Width = 1.12, BodyType = 0.6, Proportion = 0.4}, C(180, 127, 91), C(184, 20, 35), black, C(185, 24, 38), white, C(255, 30, 46))
for j = -2, 2 do
	table.insert(demon.Hair, shape("GelledSpike" .. j, "Head", "Wedge", {0.3, 0.6 + (2 - math.abs(j)) * 0.14, 0.9}, {j * 0.25, 0.78, 0.04}, C(22, 22, 29), {0, 0, -j * 12}))
end
for _, side in {-1, 1} do
	for j = 1, 3 do
		table.insert(demon.Extras, shape("DarkHorn" .. side .. j, "Head", "Cylinder", {0.27, 0.22 - j * 0.045, 0.22 - j * 0.045}, {side * (0.77 + 0.1 * math.sin(j * 0.8)), 0.45 + j * 0.23, -0.4}, C(61, 31, 40), {0, 0, side * (55 + j * 20)}))
	end
end
for j = 1, 3 do
	table.insert(demon.Extras, shape("Tail" .. j, "LowerTorso", "Cylinder", {0.4, 0.14, 0.14}, {0.1 + j * 0.12, -0.18 - j * 0.18, 0.5 + j * 0.2}, C(85, 25, 35), {0, -55, 60}))
end
table.insert(demon.Extras, shape("TailPoint", "LowerTorso", "Wedge", {0.3, 0.35, 0.3}, {0.5, -0.89, 1.18}, C(91, 25, 35), {45, 0, 180}))
demon.Effects = {
	particle("UpperTorso", {0, 0, -0.75}, C(155, 24, 39), "smoke", 4, NumberRange.new(0.8, 1.3), 1.4),
	particle("LowerTorso", {0, 0, -0.65}, C(237, 46, 48), "sparkles", 4, NumberRange.new(0.8, 1.7), 0.4),
	light(C(235, 27, 42)),
}
	table.insert(demon.Effects, {
		Type = "Lightning", Body = "UpperTorso", Position = V(0, 0, 0), Color = C(225, 26, 48),
		Points = {V(-1.25, -0.7, -0.85), V(-1.4, 0, -0.85), V(-1.2, 0.75, -0.85),
			V(0, 1, -0.85), V(1.2, 0.75, -0.85), V(1.4, 0, -0.85), V(1.25, -0.7, -0.85),
			V(0, -1, -0.85), V(-1.25, -0.7, -0.85)},
	})
table.insert(bosses, demon)

local storm = recipe("Pocket Storm", 12, {Height = 1.12, Width = 1.38, Depth = 1.15, BodyType = 0.25, Proportion = 0}, C(204, 155, 110), C(26, 45, 96), C(23, 37, 81), C(26, 45, 96), C(238, 215, 53), white)
storm.Hair = {shape("NeatHair", "Head", "Ball", {1.33, 0.25, 1.22}, {0, 0.56, 0.02}, C(86, 52, 33))}
for _, side in {"Left", "Right"} do
	table.insert(storm.Extras, shape(side .. "LightningCuff", side .. "UpperArm", "Ball", {0.77, 0.16, 0.8}, {0, -0.43, 0}, C(244, 221, 47)))
end
table.insert(storm.Extras, shape("LightningCollar", "UpperTorso", "Ball", {1.12, 0.17, 1.13}, {0, 0.73, 0}, C(244, 221, 47)))
for j = -1, 1 do
	table.insert(storm.Extras, shape("StormCloud" .. j, "Head", "Ball", {0.86, 0.52 + (1 - math.abs(j)) * 0.22, 0.78}, {j * 0.57, 1.35, 0}, C(62, 71, 88)))
end
for _, side in {"Left", "Right"} do
	local effect = particle(side .. "LowerLeg", {0, 0, 0}, C(66, 156, 255), "sparkles", 4, NumberRange.new(1.1, 1.7), 0.65)
	effect.Spread = Vector2.new(180, 180)
	effect.Acceleration = V(0, 0.7, 0)
	table.insert(storm.Effects, effect)
end
table.insert(storm.Effects, light(C(53, 130, 255)))
table.insert(bosses, storm)

-- Fallback geometry remains entirely recipe-driven when catalog IDs are absent.
for _, boss in bosses do
		if boss.Name == "Wing Spark" or boss.Name == "Pocket Storm" then
			for _, side in {"Left", "Right"} do
				table.insert(boss.Effects, {
					Type = "Lightning", Body = side .. "LowerLeg", Position = V(0, 0, -0.55),
					Color = C(65, 190, 255),
					Points = {V(-0.5, -0.55, 0), V(0.25, -0.15, -0.1), V(-0.2, 0.18, -0.1), V(0.5, 0.55, 0)},
				})
			end
		end
	boss.StageScale = 1 + (boss.Stage - 1) / 11 * 0.6
	for _, spec in boss.Extras do
		if spec.Shape == "Block" and not spec.Name:find("Crack") and not spec.Name:find("Visor") then
			spec.Shape = (spec.Name:find("Feather") or spec.Name == "TowelDrape") and "Wedge" or "Ball"
		end
	end
end

return bosses
