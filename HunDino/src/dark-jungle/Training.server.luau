-- L0: sảnh + bãi tập; không có thưởng, DataStore hay nhiệm vụ săn.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.TrainingConfig)
local Rules = require(ReplicatedStorage.Shared.TrainingRules)
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local weaponTemplates = game:GetService("ServerStorage"):WaitForChild("TrainingWeapons")
local map = workspace:WaitForChild("HunDinoL0")
local dummies = map.Training.Dummies
local remote = Instance.new("RemoteEvent")
remote.Name = "HunDinoTrainingAction"; remote.Parent = ReplicatedStorage
local states, owners = {}, {}
local pets = Instance.new("Folder"); pets.Name = "TrainingPets"; pets.Parent = workspace

local function makePart(parent, name, size, color, cf, anchored)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = color
	p.CFrame = cf; p.Anchored = anchored or false; p.CanCollide = false
	p.CanTouch = false; p.Massless = true; p.Material = Enum.Material.SmoothPlastic
	p.Parent = parent; return p
end
local function weld(a, b, offset)
	b.CFrame = a.CFrame * offset
	local w = Instance.new("Weld"); w.Part0 = a; w.Part1 = b; w.C0 = offset; w.Parent = b
	return w
end
local function alive(s)
	return s and s.Character and s.Character.Parent and s.Humanoid.Health > 0 and s.Root.Parent
end
local function grounded(s)
	return not s.Humanoid.Sit and not s.Root.Anchored
		and s.Humanoid.FloorMaterial ~= Enum.Material.Air
end
local function sync(s)
	local p = s.Player
	p:SetAttribute("Stamina", math.floor(s.Stamina + 0.5))
	p:SetAttribute("Drawn", s.Drawn)
	p:SetAttribute("WeaponId", s.WeaponId)
	p:SetAttribute("Blocking", s.Blocking)
	p:SetAttribute("BowBoost", s.BowBoostUntil > os.clock())
	p:SetAttribute("TrainingDamage", s.Damage)
	p:SetAttribute("PetDamage", s.PetDamage)
	p:SetAttribute("ComboStep", if os.clock() <= s.ComboUntil then s.ComboStep else 0)
end
local function message(s, text)
	remote:FireClient(s.Player, "Message", text)
end
local function equipArmor(s, enabled)
	if s.Armor then s.Armor:Destroy(); s.Armor = nil end
	s.Player:SetAttribute("TrainingArmor", enabled)
	if not enabled then return end
	local torso = s.Character:FindFirstChild("UpperTorso") or s.Character:FindFirstChild("Torso")
	if not torso then return end
	local armor = Instance.new("Model"); armor.Name = "TrainingArmor"; armor.Parent = s.Character; s.Armor = armor
	local chest = makePart(armor, "LeatherPlate", Vector3.new(2.15, 1.7, 0.4), Color3.fromRGB(92, 71, 48), torso.CFrame)
	weld(torso, chest, CFrame.new(0, 0, -0.62))
	local badge = makePart(armor, "HunterBadge", Vector3.new(0.4, 0.6, 0.12), Color3.fromRGB(232, 183, 95), torso.CFrame)
	weld(torso, badge, CFrame.new(0, 0.25, -0.88))
	for _, side in {-1, 1} do
		local limb = s.Character:FindFirstChild(if side == -1 then "LeftUpperArm" else "RightUpperArm")
			or s.Character:FindFirstChild(if side == -1 then "Left Arm" else "Right Arm")
		if limb then
			local p = makePart(armor, "Shoulder", Vector3.new(1.1, 0.5, 1.1), Color3.fromRGB(68, 106, 98), limb.CFrame)
			weld(limb, p, CFrame.new(0, 0.5, 0))
		end
	end
end
local function weaponPose(s)
	if not s.Grip or not s.Grip.Parent then return end
	local torso = s.Character:FindFirstChild("UpperTorso") or s.Character:FindFirstChild("Torso") or s.Root
	local left = s.Character:FindFirstChild("LeftHand") or s.Character:FindFirstChild("Left Arm") or torso
	local right = s.Character:FindFirstChild("RightHand") or s.Character:FindFirstChild("Right Arm") or torso
	if s.Drawn then
		s.Grip.Part0 = if s.WeaponId == "Bow" then left else right
		s.RestPose = if s.WeaponId == "Bow" then CFrame.new(0, .1, -.5) * CFrame.Angles(0, -math.pi/2, 0)
			else CFrame.new(0, -.5, -.5) * CFrame.Angles(math.rad(-25), 0, math.rad(10))
	else
		s.Grip.Part0 = torso
		s.RestPose = CFrame.new(.5, -1, 1) * CFrame.Angles(0, 0, math.rad(-30))
	end
	s.Grip.C0 = s.RestPose
	if s.OffGrip then
		s.OffGrip.Part0 = if s.Drawn then left else torso
		s.OffRest = if s.Drawn then CFrame.new(0, -.3, -.35) else CFrame.new(-.7, -.7, 1.3)
		s.OffGrip.C0 = if s.Blocking then CFrame.new(.5,.5,-1) * CFrame.Angles(0,-.3,0) else s.OffRest
	end
	if s.SheathGrip then s.SheathGrip.Part0 = torso; s.SheathGrip.C0 = CFrame.new(.5,-1,1.04)*CFrame.Angles(0,0,math.rad(-30)) end
end

local function createWeapon(s)
	if s.WeaponModel then s.WeaponModel:Destroy() end
	s.OffGrip = nil; s.SheathGrip = nil
	local model = weaponTemplates[s.WeaponId]:Clone(); model.Name = "TrainingWeapon"
	for _, assembly in model:GetChildren() do
		local handle = assembly.PrimaryPart
		for _, p in assembly:GetChildren() do
			if p:IsA("BasePart") then
				p.Anchored = false; p.CanCollide = false; p.CanQuery = false; p.Massless = true
				if p ~= handle then weld(handle,p,handle.CFrame:ToObjectSpace(p.CFrame)) end
			end
		end
		local grip = weld(s.Root,handle,CFrame.new())
		if assembly.Name == "Main" then s.Grip = grip elseif assembly.Name == "Offhand" then s.OffGrip = grip else s.SheathGrip = grip end
	end
	model.Parent = s.Character; s.WeaponModel = model; weaponPose(s)
end
local function equipWeapon(s,id)
	if not Rules.canEquip(s,Weapons,id,os.clock()) then
		message(s,"Cất vũ khí bằng R và dừng động tác trước khi đổi trong bãi tập."); return
	end
	s.WeaponId=id; s.ComboStep=0; s.ComboUntil=0; s.LastTarget=nil; s.BowBoostUntil=0; s.Aiming=false
	s.BusyUntil=os.clock()+.3; s.WantSprint=false
	createWeapon(s); sync(s); message(s,"Đã chọn "..Weapons[id].Name..". Nhấn R để rút.")
end
local function createPet(s)
	local pet = Instance.new("Model"); pet.Name = "Pet_" .. s.Player.UserId; pet.Parent = pets
	local base = CFrame.new(s.Root.Position + Vector3.new(3, -1.5, 3))
	local function piece(name, size, offset, color)
		return makePart(pet, name, size, color or Color3.fromRGB(73, 150, 124), base * CFrame.new(offset), true)
	end
	local body = piece("Body", Vector3.new(1.8, 1.3, 2.6), Vector3.zero)
	pet.PrimaryPart = body
	piece("Head", Vector3.new(1.6, 1.3, 1.5), Vector3.new(0, 0.65, -1.45))
	piece("Snout", Vector3.new(1.4, 0.6, 0.8), Vector3.new(0, 0.35, -2.4))
	piece("Tail", Vector3.new(0.7, 0.7, 2), Vector3.new(0, 0.1, 2))
	piece("Saddle", Vector3.new(1.85, 0.3, 1.3), Vector3.new(0, 0.7, 0.1), Color3.fromRGB(123, 83, 46))
	for _, x in {-0.8, 0.8} do
		for _, z in {-0.8, 0.8} do piece("Foot", Vector3.new(0.6, 0.6, 0.9), Vector3.new(x, -0.7, z)) end
		piece("Eye", Vector3.new(0.15, 0.3, 0.3), Vector3.new(x, 0.9, -1.85), Color3.fromRGB(20, 27, 25))
	end
	s.Pet = pet; s.PetClock = 0
end
local function updateDummy(dummy)
	local gui = dummy.Target.SignGui.Text
	gui.Text = (dummy:GetAttribute("Label") or "HÌNH NỘM " .. dummy.Name:match("%d+")) .. "\n" .. dummy:GetAttribute("Health") .. " / " .. Config.DummyHealth
end
local function hit(s, dummy, damage, isPet)
	if not dummy:IsDescendantOf(dummies) then return end
	local hp = dummy:GetAttribute("Health")
	local applied = math.min(hp, damage)
	hp -= applied
	if isPet then s.PetDamage += applied else s.Damage += applied end
	-- Đây là hình nộm vô hạn, làm đầy lại khi bị hạ; không phát thưởng.
	dummy:SetAttribute("Health", if hp <= 0 then Config.DummyHealth else hp)
	updateDummy(dummy)
	remote:FireAllClients("Hit", dummy.Target.Position, applied, isPet)
	sync(s)
end
local function directionOK(v, ranged)
	return typeof(v) == "Vector3" and v.X == v.X and v.Y == v.Y and v.Z == v.Z
		and math.abs(v.X) < 2 and math.abs(v.Z) < 2 and math.abs(v.Y) < (if ranged then 2 else .01) and v.Magnitude > 0.5
end
local function lineOfSight(s, pos, dummy)
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {s.Character, pets}
	local result = workspace:Raycast(s.Root.Position, pos - s.Root.Position, params)
	return not result or result.Instance:IsDescendantOf(dummy)
end
local function attack(s, action, direction)
	local weapon=Weapons[s.WeaponId]
	if not s.InTraining or not directionOK(direction,weapon.Ranged) then return end
	local now = os.clock()
	local kind, spec = Rules.attack(Config, Weapons, s, action, now)
	if not kind then return end
	direction = direction.Unit
	local flat=Vector3.new(direction.X,0,direction.Z)
	if flat.Magnitude>.01 then s.Root.CFrame = CFrame.lookAt(s.Root.Position, s.Root.Position + flat) end
	s.Humanoid.AutoRotate = false
	local character = s.Character
	local boosted=weapon.Ranged and now<s.BowBoostUntil
	if weapon.Ranged then s.BowBoostUntil=0 end
	remote:FireClient(s.Player, "Attack", kind, weapon.Skill)
	local windup = s.RestPose * CFrame.Angles(math.rad(100), 0, math.rad(-30))
	if weapon.Ranged then windup=s.RestPose*CFrame.new(0,0,.25) end
	TweenService:Create(s.Grip, TweenInfo.new(spec.Windup), {C0 = windup}):Play()
	task.delay(spec.Windup, function()
		if not alive(s) or s.Character ~= character or states[s.Player] ~= s then return end
		if weapon.Ranged then
			TweenService:Create(s.Grip,TweenInfo.new(.16),{C0=s.RestPose}):Play()
			local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances={s.Character,pets}
			local origin=s.Root.Position+Vector3.new(0,.8,0)
			for i=1,spec.Shots or 1 do
				local angle=if i==1 then 0 elseif i==2 then math.rad(-4) else math.rad(4)
				local aim=CFrame.fromAxisAngle(Vector3.yAxis,angle):VectorToWorldSpace(direction)
				local result=workspace:Raycast(origin,aim*spec.Range,params)
				local endpoint=if result then result.Position else origin+aim*spec.Range
				remote:FireAllClients("Shot",origin,endpoint,boosted and i==1)
				if result then
					for _,dummy in dummies:GetChildren() do if result.Instance:IsDescendantOf(dummy) then
						hit(s,dummy,math.floor(spec.Damage*(if boosted and i==1 then 1.25 else 1)+.5),false)
						break
					end end
				end
			end
			return
		end
		for n=1,spec.Hits or 1 do
			if n>1 then task.wait(.13) end
			if not alive(s) or s.Character~=character or states[s.Player]~=s then return end
			TweenService:Create(s.Grip, TweenInfo.new(.1), {C0=s.RestPose*CFrame.Angles(math.rad(-95),0,if n%2==0 then -.4 else .4)}):Play()
			if s.OffGrip and s.WeaponId=="DualDaggers" then TweenService:Create(s.OffGrip,TweenInfo.new(.1),{C0=s.OffRest*CFrame.Angles(-1.5,0,if n%2==0 then .4 else -.4)}):Play() end
			for _, dummy in dummies:GetChildren() do
				local delta = dummy.Target.Position - s.Root.Position
				local targetFlat = Vector3.new(delta.X, 0, delta.Z)
				if delta.Magnitude <= spec.Range and targetFlat.Magnitude > 0 and direction:Dot(targetFlat.Unit) >= (spec.Arc or .3)
					and lineOfSight(s, dummy.Target.Position, dummy) then
					hit(s, dummy, spec.Damage, false); s.LastTarget = dummy; s.TargetUntil = now + 12
				end
			end
		end
	end)
	task.delay(spec.Duration, function()
		if states[s.Player] ~= s or not alive(s) or s.Character ~= character then return end
		TweenService:Create(s.Grip, TweenInfo.new(0.12), {C0 = s.RestPose}):Play()
		if s.OffGrip then TweenService:Create(s.OffGrip,TweenInfo.new(.12),{C0=s.OffRest}):Play() end
		s.Humanoid.AutoRotate = true
	end)
	sync(s)
end
local function toggleDraw(s, target)
	if os.clock() < s.BusyUntil then return end
	s.BusyUntil = os.clock() + Config.SheatheTime; s.ComboStep = 0; s.Sprinting = false
	s.Blocking=false; s.BowBoostUntil=0; s.Aiming=false; weaponPose(s)
	s.ChangeDraw = target
	message(s, (if target then "Đang rút " else "Đang cất ")..Weapons[s.WeaponId].Name.."…")
end
local function travel(s, destination)
	if s.Travelling then return end
	if os.clock() < s.BusyUntil then return end
	s.InTraining = destination == "Training"; s.Drawn = false; s.WantSprint = false; s.Sprinting = false
	s.ChangeDraw = nil; s.ComboStep = 0; s.LastTarget = nil; s.BusyUntil = os.clock() + 0.5
	s.Blocking=false; s.Aiming=false; s.BowBoostUntil=0
	s.Humanoid.AutoRotate = true; weaponPose(s)
	local cf = if s.InTraining then map.Training.Arrival.CFrame * CFrame.Angles(0, 0, 0)
		else map.Lobby.Arrival.CFrame
	s.Travelling = true
 local before = s.Character
 s.BusyUntil = math.huge
 pcall(function() s.Player:RequestStreamAroundAsync(cf.Position, 3) end)
 s.Travelling = false
 if not alive(s) or states[s.Player] ~= s or s.Character ~= before then return end
 s.BusyUntil = os.clock() + 0.5
 s.Character:PivotTo(cf); s.Root.AssemblyLinearVelocity = Vector3.zero
	s.Pet:PivotTo(cf * CFrame.new(3, -1.5, 3))
	s.Player:SetAttribute("InTraining", s.InTraining)
	message(s, if s.InTraining then "Nhấn I chọn vũ khí, R để rút. Cận chiến bên trái, cung bên phải." else "Đã trở về trại thợ săn.")
	sync(s)
end
local function bindPrompt(part, callback)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	prompt.Triggered:Connect(function(player)
		local s = states[player]
		-- Prompt vẫn phải được xác minh trên server.
		if not alive(s) or (s.Root.Position - part.Position).Magnitude > 12 or os.clock() < s.BusyUntil then return end
		callback(s)
	end)
end
bindPrompt(map.Lobby.ToTraining, function(s) travel(s, "Training") end)
bindPrompt(map.Training.ToLobby, function(s) travel(s, "Lobby") end)
bindPrompt(map.Training.EquipmentRack, function(s)
	if s.Drawn then message(s, "Cất vũ khí bằng R trước khi thay giáp."); return end
	equipArmor(s, not s.Player:GetAttribute("TrainingArmor")); s.BusyUntil = os.clock() + 0.3
end)
bindPrompt(map.Training.ResetPost, function(s)
	if s.Drawn then message(s, "Cất vũ khí bằng R trước khi tương tác."); return end
	s.Damage = 0; s.PetDamage = 0; s.Stamina = Config.MaxStamina; s.ComboStep = 0; s.LastTarget = nil
	s.Humanoid.Health = s.Humanoid.MaxHealth; s.BusyUntil = os.clock() + 0.3; sync(s)
	message(s, "Đã xóa thống kê của bạn. Bắt đầu lượt tập mới!")
end)
for _,rack in map.Training.WeaponRacks:GetChildren() do
	bindPrompt(rack,function(s) equipWeapon(s,rack.Name) end)
end
remote.OnServerEvent:Connect(function(player, action, value)
	local s = states[player]
	if not alive(s) or typeof(action) ~= "string" then return end
	local now = os.clock()
	-- Giới hạn cả request không hợp lệ trước khi xử lý trạng thái.
	if now - s.PacketWindow >= 1 then s.PacketWindow = now; s.Packets = 0 end
	s.Packets += 1; if s.Packets > 30 then return end
	if action == "EquipWeapon" then
		equipWeapon(s,value)
	elseif action == "Aim" then
		s.Aiming=value==true and s.WeaponId=="Bow" and s.Drawn
	elseif action == "Guard" then
		if value==false then s.Blocking=false; weaponPose(s)
		elseif value==true and s.WeaponId=="SwordShield" and s.Drawn and now>=s.BusyUntil and s.Stamina>0 then
			s.Blocking=true; s.Sprinting=false; s.WantSprint=false; s.ComboStep=0; weaponPose(s)
		end
		sync(s)
	elseif action == "Sprint" then
		if typeof(value) ~= "boolean" then return end
		s.WantSprint = value; if value then s.Blocking=false; weaponPose(s) end
		if not value then s.Sprinting = false end
	elseif action == "Draw" then
		s.WantSprint = false; toggleDraw(s, not s.Drawn)
	elseif action == "Light" or action == "Heavy" or action == "Skill" then
		attack(s, action, value)
	elseif action == "Jump" and not s.Blocking and now >= s.BusyUntil and grounded(s) and now - s.LastJumpAt >= 0.45 then
		s.LastJumpAt = now; s.BusyUntil = now + 0.15
		remote:FireClient(player, "Jump", s.Character)
	elseif action == "Dodge" and not s.Blocking and directionOK(value) and now >= s.BusyUntil and grounded(s)
		and now - s.LastJumpAt >= 0.45 and s.Stamina >= Config.DodgeCost then
		s.Stamina -= Config.DodgeCost; s.LastSpend = now + Config.DodgeTime
		s.ComboStep = 0; s.BusyUntil = now + Config.DodgeTime; s.Sprinting = false
		if s.WeaponId=="Bow" and s.Drawn and s.Aiming then s.BowBoostUntil=now+4 end
		local a = Instance.new("Attachment"); a.Name = "DodgeAttachment"; a.Parent = s.Root
		local velocity = Instance.new("LinearVelocity"); velocity.Name = "DodgeVelocity"; velocity.Attachment0 = a
		velocity.RelativeTo = Enum.ActuatorRelativeTo.World; velocity.MaxForce = 100000
		-- Constrain only the ground plane; gravity must remain free on slopes/edges.
		velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
		velocity.PrimaryTangentAxis = Vector3.xAxis; velocity.SecondaryTangentAxis = Vector3.zAxis
		local direction = value.Unit
		velocity.PlaneVelocity = Vector2.new(direction.X, direction.Z) * Config.DodgeSpeed
		velocity.Parent = s.Root
		task.delay(Config.DodgeTime, function() velocity:Destroy(); a:Destroy() end)
		sync(s)
	end
end)
local function baseSign(id, text)
	local part = map.BaseSigns:FindFirstChild("Base" .. id)
	part.SignGui.Text.Text = string.format("BASE %02d\n%s", id, text)
end
local function setup(player)
	local baseId
	for id = 1, Config.LobbyCapacity do if not owners[id] then baseId = id; break end end
	if not baseId then player:Kick("Trại đã đủ 12 người. Hãy vào máy chủ khác."); return end
	owners[baseId] = player; player:SetAttribute("BaseId", baseId); baseSign(baseId, player.DisplayName)
	local function characterAdded(character)
		local old = states[player]; if old and old.Pet then old.Pet:Destroy() end
		local humanoid = character:WaitForChild("Humanoid")
		local rootPart = character:WaitForChild("HumanoidRootPart")
		if player.Character ~= character or not player.Parent then return end
		local s = {
			Player = player, Character = character, Humanoid = humanoid, Root = rootPart,
			Stamina = Config.MaxStamina, LastSpend = 0, BusyUntil = 0, Drawn = false,
			ComboStep = 0, ComboUntil = 0, Damage = 0, PetDamage = 0, InTraining = false,
			WantSprint = false, Sprinting = false, PacketWindow = 0, Packets = 0, LastJumpAt = -math.huge,
			WeaponId=player:GetAttribute("WeaponId") or "Hammer", Blocking=false, Aiming=false, BowBoostUntil=0,
		}
		states[player] = s
		player:SetAttribute("InTraining", false)
		createWeapon(s); equipArmor(s, true); createPet(s); sync(s)
		humanoid.Died:Connect(function()
			s.WantSprint = false; s.LastTarget = nil; if s.Pet then s.Pet:Destroy() end
		end)
	end
	player.CharacterAdded:Connect(characterAdded)
	if player.Character then task.spawn(characterAdded, player.Character) end
end
Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(function(player)
	local s = states[player]; if s and s.Pet then s.Pet:Destroy() end
	states[player] = nil
	local id = player:GetAttribute("BaseId")
	if id and owners[id] == player then owners[id] = nil; baseSign(id, "Chưa có chủ") end
end)
for _, player in Players:GetPlayers() do task.spawn(setup, player) end
local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
	accumulator += dt; if accumulator < 0.1 then return end
	dt = math.min(accumulator, 0.25); accumulator = 0
	local now = os.clock()
	for _, s in states do
		if not alive(s) then continue end
		if s.ChangeDraw ~= nil and now >= s.BusyUntil then
			s.Drawn = s.ChangeDraw; s.ChangeDraw = nil; weaponPose(s)
		end
		if s.WantSprint and s.Drawn and now >= s.BusyUntil then toggleDraw(s, false) end
		s.Sprinting = s.WantSprint and not s.Drawn and now >= s.BusyUntil and s.Stamina > 0
			and s.Humanoid.MoveDirection.Magnitude > 0.1
		if s.Sprinting then
			s.Stamina = math.max(0, s.Stamina - Config.SprintCost * dt); s.LastSpend = now
			if s.Stamina == 0 then s.WantSprint = false; s.Sprinting = false end
		end
		if s.Blocking then
			s.Stamina=math.max(0,s.Stamina-4*dt); s.LastSpend=now
			if s.Stamina==0 then s.Blocking=false; weaponPose(s) end
		end
		Rules.regenerate(Config, s, now, dt)
		s.Humanoid.WalkSpeed = if s.Blocking then 6 elseif now < s.BusyUntil then 8 elseif s.Sprinting then Config.SprintSpeed else Config.WalkSpeed
		-- Pet cơ bản: theo chủ, đánh mục tiêu chủ vừa đánh, có kiểm tra vật cản.
		local target = s.LastTarget
		local active = s.InTraining and target and now < s.TargetUntil
			and (target.Target.Position - s.Root.Position).Magnitude < 18
		local goal = if active then target.Target.Position + Vector3.new(3, -2.2, 3)
			else s.Root.CFrame:PointToWorldSpace(Vector3.new(3, -1.8, 4))
		local petPos = s.Pet.PrimaryPart.Position
		local delta = goal - petPos
		local filter = RaycastParams.new(); filter.FilterType = Enum.RaycastFilterType.Exclude
		filter.FilterDescendantsInstances = {s.Character, pets}
		local step = delta * math.min(1, 18 * dt / math.max(delta.Magnitude, 0.01))
		local obstruction = workspace:Raycast(petPos, step, filter)
		if not obstruction then
			local newPos = petPos + step
			local flat = Vector3.new(delta.X, 0, delta.Z)
			if flat.Magnitude > 0.1 then s.Pet:PivotTo(CFrame.lookAt(newPos, newPos + flat)) end
		end
		if active and (s.Pet.PrimaryPart.Position - target.Target.Position).Magnitude <= 7
			and now >= s.PetClock and lineOfSight(s, target.Target.Position, target) then
			s.PetClock = now + Config.PetInterval; hit(s, target, Config.PetDamage, true)
		end
		sync(s)
	end
end)
print("[HunDino L0] Sảnh 12 base và bãi tập đã khởi tạo.")
