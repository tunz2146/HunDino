-- Server health, weapon hurtboxes, and retaliation for the route-driven prototype.
-- The route controller is the only writer of root placement and gait. No remote
-- accepts damage numbers, target identities, or a claimed hit from the client.
local RunService = game:GetService("RunService")
local Defaults = require(script.Parent:WaitForChild("DinosaurCombatConfig"))

local Combat = {}
Combat.__index = Combat
local owners = setmetatable({}, { __mode = "k" })
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function finite(n) return type(n) == "number" and n == n and math.abs(n) < math.huge end
local function vector(v) return typeof(v) == "Vector3" and finite(v.X) and finite(v.Y) and finite(v.Z) end
local function nearestPoint(part, position)
	local p, h = part.CFrame:PointToObjectSpace(position), part.Size * .5
	return part.CFrame:PointToWorldSpace(Vector3.new(math.clamp(p.X, -h.X, h.X), math.clamp(p.Y, -h.Y, h.Y), math.clamp(p.Z, -h.Z, h.Z)))
end
local function inside(part, position, tolerance)
	local p, h = part.CFrame:PointToObjectSpace(position), part.Size * .5 + Vector3.one * (tolerance or 0)
	return math.abs(p.X) <= h.X and math.abs(p.Y) <= h.Y and math.abs(p.Z) <= h.Z
end
local function settings(overrides)
	local result = table.clone(Defaults)
	for key, value in overrides or {} do
		if result[key] ~= nil and typeof(result[key]) == typeof(value) then result[key] = value end
	end
	return result
end
local function newPart(folder, name, size, cf, attachTo)
	local part = Instance.new("Part")
	part.Name = name; part.Size = size; part.CFrame = cf
	part.Transparency = 1; part.CanCollide = false; part.CanTouch = false
	part.CanQuery = false; part.CastShadow = false; part.Massless = true
	part.Material = Enum.Material.Neon; part.Color = Color3.fromRGB(70, 180, 255)
	part:SetAttribute("CombatHitbox", true)
	part.Parent = folder
	local weld = Instance.new("Weld")
	weld.Name = "FollowRig"; weld.Part0 = attachTo; weld.Part1 = part
	weld.C0 = attachTo.CFrame:ToObjectSpace(cf); weld.Parent = part
	return part, weld
end

function Combat.new(model, forest, mapConfig, session, options)
	assert(not owners[model], "Dinosaur already has a combat controller")
	options = options or {}
	local root = assert(model.PrimaryPart, "Dinosaur needs a PrimaryPart")
	local self = setmetatable({
		Model = model, Forest = forest, MapConfig = mapConfig, Session = session,
		Root = root, Settings = settings(options.Settings),
		_health = 0, _state = "Idle", _time = 0, _target = nil, _tokens = {}, _lastHits = {}, _petLastHits = {},
		_attackSequence = 0, _attackHits = 0, _lastAttack = -math.huge,
		_phase = "Idle", _phaseUntil = 0, _lastDamaged = -math.huge,
		_autoConnect = options.AutoConnect ~= false, _running = false, _destroyed = false,
		_original = {}, _hurtboxes = {}, _damagePlayer = options.DamagePlayer, _damagePets = options.DamagePets,
		_blockedFor = 0, _publishElapsed = 0,
	}, Combat)
	assert(finite(self.Settings.MaxHealth) and self.Settings.MaxHealth > 0, "MaxHealth must be positive")
	for _, key in {"Health", "MaxHealth", "CombatState", "CombatTargetUserId", "AttackReady", "AttackSequence", "AttackPhase", "AttackHits", "DinosaurDead", "Weak", "Trapped", "Captured", "TrapUntil", "CapturePoint", "CombatFaction", "CombatTargetKind"} do
		self._original[key] = { value = model:GetAttribute(key) }
	end
	if model:GetAttribute("CombatFaction")==nil then model:SetAttribute("CombatFaction","Wildlife") end
	if model:GetAttribute("ShowCombatHitboxes") == nil then model:SetAttribute("ShowCombatHitboxes", false) end
	local folder = Instance.new("Folder"); folder.Name = "CombatHitboxes"; folder.Parent = model; self._folder = folder
	-- The lower-leg volumes reach the feet. A player can hit the animal from the
	-- ground rather than having to jump to its 30-stud-high torso.
	for _, definition in {
		{"BodyHurtbox", "body", "body_geom", Vector3.new(.9, .9, .9)},
		{"HeadHurtbox", "head", "head_geom", Vector3.new(.9, .9, .9)},
		{"LeftLegHurtbox", "left leg", "left leg_geom", Vector3.new(.94, .99, .94)},
		{"RightLegHurtbox", "right leg", "right leg_geom", Vector3.new(.94, .99, .94)},
	} do
		local group = assert(model:FindFirstChild(definition[2]), "Missing " .. definition[2])
		local source = assert(group:FindFirstChild(definition[3], true), "Missing " .. definition[3])
		local box = newPart(folder, definition[1], source.Size * definition[4], source.CFrame, source)
		box.CanQuery = true; box:SetAttribute("DinosaurHurtbox", true)
		table.insert(self._hurtboxes, box)
	end
	self._attackBox, self._attackWeld = newPart(folder, "BiteAttackHitbox", self.Settings.BiteHitboxSize, root.CFrame, root)
	self._attackBox:SetAttribute("DinosaurAttackHitbox", true)
	local highlight = Instance.new("Highlight")
	highlight.Name = "CombatWarning"; highlight.Adornee = model
	highlight.FillTransparency = .85; highlight.OutlineTransparency = .15
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded; highlight.Enabled = false
	highlight.Parent = folder; self._highlight = highlight
	self:_createHealthbar()
	local jawModule = model:FindFirstChild("JawController")
	if jawModule then self._jaw = require(jawModule).new(model) end
	self._debugConnection = model:GetAttributeChangedSignal("ShowCombatHitboxes"):Connect(function() self:_showBoxes() end)
	owners[model] = self
	self:Reset()
	return self
end

function Combat:_createHealthbar()
	local gui = Instance.new("BillboardGui")
	gui.Name = "DinosaurHealthbar"; gui.Adornee = self.Root
	gui.Size = UDim2.fromOffset(260, 64); gui.StudsOffsetWorldSpace = Vector3.new(0, 23, 0)
	gui.AlwaysOnTop = true; gui.MaxDistance = self.Settings.HealthbarDistance; gui.Parent = self.Model
	local frame = Instance.new("Frame"); frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(17, 27, 22); frame.BackgroundTransparency = .12; frame.BorderSizePixel = 0; frame.Parent = gui
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = frame
	local label = Instance.new("TextLabel"); label.Name = "HealthText"; label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -12, 0, 25); label.Position = UDim2.fromOffset(6, 3)
	label.Font = Enum.Font.GothamBold; label.TextSize = 14; label.TextColor3 = Color3.fromRGB(242, 240, 221); label.Parent = frame
	local track = Instance.new("Frame"); track.Name = "Track"; track.Position = UDim2.fromOffset(10, 30)
	track.Size = UDim2.new(1, -20, 0, 9); track.BorderSizePixel = 0; track.BackgroundColor3 = Color3.fromRGB(40, 48, 43); track.Parent = frame
	local fill = Instance.new("Frame"); fill.Name = "Fill"; fill.Size = UDim2.fromScale(1, 1); fill.BorderSizePixel = 0; fill.Parent = track
	local status = Instance.new("TextLabel"); status.Name = "Status"; status.BackgroundTransparency = 1
	status.Position = UDim2.fromOffset(6, 42); status.Size = UDim2.new(1, -12, 0, 18)
	status.Font = Enum.Font.Gotham; status.TextSize = 11; status.TextColor3 = Color3.fromRGB(205, 216, 193); status.Parent = frame
	self._gui, self._hpText, self._hpFill, self._statusText = gui, label, fill, status
end
function Combat:_publish()
	local model = self.Model
	model:SetAttribute("Health", self._health); model:SetAttribute("MaxHealth", self.Settings.MaxHealth)
	model:SetAttribute("CombatState", self._state)
 model:SetAttribute("CombatTargetKind",self._targetKind)
	model:SetAttribute("CombatTargetUserId", if self._target then self._target.UserId else 0)
	model:SetAttribute("AttackPhase", self._phase); model:SetAttribute("AttackSequence", self._attackSequence)
	model:SetAttribute("AttackHits", self._attackHits); model:SetAttribute("DinosaurDead", self._health <= 0)
	model:SetAttribute("Weak", self._health > 0 and self._health <= self.Settings.MaxHealth * .1)
	model:SetAttribute("Trapped", self._trapOwner ~= nil); model:SetAttribute("TrapUntil", self._trapUntil or 0)
	model:SetAttribute("Captured", self._captured == true)
	model:SetAttribute("CapturePoint", self:GetCapturePoint())
	model:SetAttribute("AttackReady", self._health > 0 and not self._captured and not self._trapOwner and self._target ~= nil)
	local ratio = math.clamp(self._health / self.Settings.MaxHealth, 0, 1)
	self._hpText.Text = string.format("T-REX  %d / %d", math.ceil(self._health), self.Settings.MaxHealth)
	self._hpFill.Size = UDim2.fromScale(ratio, 1)
	self._hpFill.BackgroundColor3 = if ratio > .5 then Color3.fromRGB(111, 181, 92) elseif ratio > .25 then Color3.fromRGB(232, 181, 71) else Color3.fromRGB(222, 85, 64)
	self._statusText.Text = if self._captured then "ĐÃ BẮT SỐNG" elseif self._health <= 0 then "ĐÃ HẠ"
		elseif self._trapOwner then "MẮC BẪY — ĐẾN TRƯỚC MÕM ĐỂ CHO UỐNG"
		elseif self._health <= self.Settings.MaxHealth * .1 then "ĐÃ YẾU — CÓ THỂ BẮT SỐNG"
		elseif self._phase == "Windup" then "CHUẨN BỊ CẮN — NÉ SANG BÊN!"
		elseif self._target then "ĐANG PHẢN CÔNG" elseif self._state == "Returning" then "QUAY LẠI TUYẾN" else "ĐANG TUẦN TRA / NGHỈ CHÂN"
end
function Combat:_showBoxes()
	local debug = self.Model:GetAttribute("ShowCombatHitboxes") == true
	for _, box in self._hurtboxes do box.Transparency = if debug then .7 else 1 end
	local active = self._phase == "Active"
	self._attackBox.Color = if active then Color3.fromRGB(244, 80, 48) else Color3.fromRGB(255, 177, 55)
	self._attackBox.Transparency = if self._phase == "Windup" then .86 elseif active then .74 elseif debug then .82 else 1
	self._highlight.Enabled = self._phase == "Windup" or active
	self._highlight.FillColor = self._attackBox.Color; self._highlight.OutlineColor = self._attackBox.Color
end
function Combat:_setPhase(phase, duration)
	self._phase = phase; self._phaseUntil = self._time + (duration or 0)
	self:_showBoxes(); self:_publish()
end
function Combat:_patrol() return self.Session and self.Session.Patrol end
function Combat:_character(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") or player:GetAttribute("InHunting") ~= true then return nil end
	if Defaults.Allied(self.Model,player) then return nil end
	local questOwner = self.Model:GetAttribute("QuestOwnerUserId")
	if questOwner and (player.UserId ~= questOwner or self.Model:GetAttribute("QuestCombatAllowed") == false) then return nil end
	if player:GetAttribute("AdminFlying")==true then return nil end
	if not self.Session or not self.Session.Players[player] then return nil end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not character.Parent or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return nil end
 local unrestricted=self.Session and self.Session.Patrol and self.Session.Patrol._unrestrictedRoam
 if not unrestricted then
	local offset = self.MapConfig.WorldOffset or self.Forest:GetAttribute("WorldOffset") or Vector3.zero
	local p = root.Position - offset
	local limitX = (self.MapConfig.MapWidth or self.MapConfig.MapSize or 1620) * .5 + 105
	local limitZ = (self.MapConfig.MapDepth or self.MapConfig.MapSize or 1620) * .5 + 105
	if math.abs(p.X) > limitX or math.abs(p.Z) > limitZ or p.Y < (self.MapConfig.TerrainMin or -48) - 20 or p.Y > (self.MapConfig.TerrainMax or 128) + 120 then return nil end
	local zones = self.Forest:FindFirstChild("Zones")
	local camp = zones and zones:FindFirstChild("Camp")
	local node = camp and camp:FindFirstChild("Node")
	local safeRadius = self.MapConfig.CampSafeRadius or ((camp and camp:GetAttribute("Width") or 180) * .5 + self.Settings.CampMargin)
	if node and (flat(root.Position - node.Position)).Magnitude < safeRadius then return nil end
 end
	return character, humanoid, root
end
function Combat:_victim(player)
 local character,humanoid,root=self:_character(player)
 if not character then return nil end
 if self._targetKind=="Pet" then
  local folder=workspace:FindFirstChild("TrainingPets")
  local pet=folder and folder:FindFirstChild("Pet_"..player.UserId)
  if not pet or not pet.PrimaryPart or (pet:GetAttribute("PetHealth") or 0)<=0 or Defaults.Allied(self.Model,pet) then return nil end
  return pet,nil,pet.PrimaryPart
 end
 return character,humanoid,root
end
function Combat:_lineOfSight(origin, destination, character)
	local delta = destination - origin
	if delta.Magnitude < .01 then return true end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignored = {self.Model}
	if character then table.insert(ignored, character) end
	local pets = workspace:FindFirstChild("TrainingPets")
	if pets then table.insert(ignored, pets) end
	params.FilterDescendantsInstances = ignored
	params.IgnoreWater = true; params.RespectCanCollide = true
	local hit = workspace:Raycast(origin, delta, params)
	return not hit or hit.Distance >= delta.Magnitude - .35
end
function Combat:GetHurtboxes() return table.clone(self._hurtboxes) end
function Combat:FromRayHit(instance)
	if self._destroyed or self._captured or self._health <= 0 or typeof(instance) ~= "Instance" or not instance:IsA("BasePart") then return false end
	if instance == self._attackBox then return false end
	if instance:GetAttribute("DinosaurHurtbox") == true and instance:IsDescendantOf(self.Model) then return true end
	for _, groupName in {"body", "head", "left leg", "right leg"} do
		local group = self.Model:FindFirstChild(groupName)
		if group and instance:IsDescendantOf(group) then return true end
	end
	return false
end
function Combat:GetAimPoint()
	return self._hurtboxes[1].Position
end
function Combat:GetClosestHitPoint(origin, range, direction, arc)
	if self._destroyed or self._captured or self._health <= 0 or not vector(origin) or not finite(range) or range < 0 then return nil end
	local forward = if vector(direction) and flat(direction).Magnitude > .01 then flat(direction).Unit else nil
	local threshold = if finite(arc) then math.clamp(arc, -1, 1) else -.1
	local best, bestBox, bestDistance = nil, nil, math.min(range, self.Settings.MaxWeaponRange) + .001
	for _, box in self._hurtboxes do
		local point = nearestPoint(box, origin)
		local delta = point - origin
		local horizontal = flat(delta)
		if delta.Magnitude < bestDistance and (not forward or horizontal.Magnitude < .1 or forward:Dot(horizontal.Unit) >= threshold) then
			best, bestBox, bestDistance = point, box, delta.Magnitude
		end
	end
	return best, bestBox
end
function Combat:CanHit(player, point, maxRange)
	if self._destroyed or not self._running then return false, "Inactive" end
	if self._captured then return false, "Captured" end
	if self._health <= 0 then return false, "Dead" end
	local character, _, root = self:_character(player)
	if not character then return false, "NotHunting" end
	if not vector(point) or not finite(maxRange) or maxRange < 0 then return false, "InvalidHit" end
	if (point - root.Position).Magnitude > math.min(maxRange, self.Settings.MaxWeaponRange) + 2.5 then return false, "OutOfRange" end
	local inBox = false
	for _, box in self._hurtboxes do if inside(box, point, 1.5) then inBox = true; break end end
	-- The four query volumes define damageable body, head, and legs. The tail
	-- remains visual rather than silently granting a hit outside these volumes.
	if not inBox then return false, "OutsideHurtbox" end
	if not self:_lineOfSight(root.Position + Vector3.new(0, 1, 0), point, character) then return false, "Obstructed" end
	return true
end
function Combat:MeleeStrike(player, origin, direction, range, arc, damage, token)
	local character, _, root = self:_character(player)
	if not character or not vector(origin) or (origin - root.Position).Magnitude > 6 then return 0, nil, "InvalidOrigin" end
	if not vector(direction) or flat(direction).Magnitude < .01 or not finite(range) or range <= 0 then return 0, nil, "InvalidDirection" end
	local point = self:GetClosestHitPoint(origin, range, direction, arc)
	if not point then return 0, nil, "Miss" end
	local allowed, reason = self:CanHit(player, point, range)
	if not allowed then return 0, nil, reason end
	local applied, damageReason = self:Damage(player, damage, point, token)
	return applied, point, damageReason
end
function Combat:Damage(player, damage, point, token, source)
	local allowed, reason = self:CanHit(player, point, self.Settings.MaxWeaponRange)
	if not allowed then return 0, reason end
	if not finite(damage) or damage <= 0 or damage > self.Settings.MaxDamagePerHit then return 0, "InvalidDamage" end
	if token ~= nil and (type(token) ~= "string" or #token == 0 or #token > 160) then return 0, "InvalidToken" end
	-- A server-owned companion strike must not suppress a simultaneous player hit.
	local hitTimes = if source == "Pet" then self._petLastHits else self._lastHits
	local last = hitTimes[player]
	-- A server-scheduled volley has several distinct arrows. Each still needs
	-- its own once-only token, but must not suppress another arrow in the volley.
	if source ~= "Projectile" and last and self._time - last < self.Settings.MinimumHitInterval - .0001 then return 0, "HitCooldown" end
	local tokens = self._tokens[player]
	if not tokens then tokens = {}; self._tokens[player] = tokens end
	if token and tokens[token] and tokens[token] > self._time then return 0, "DuplicateHit" end
	for previous, expires in tokens do if expires <= self._time then tokens[previous] = nil end end
	if token then tokens[token] = self._time + self.Settings.AttackTokenLifetime end
	hitTimes[player] = self._time
	local beforeHP = self._health
	local applied = math.min(self._health, damage)
	if source == "Pet" then
		local threshold = self.Settings.MaxHealth * .1
		if beforeHP <= threshold then return 0, "CaptureProtected" end
		applied = math.min(applied, beforeHP - threshold)
	end
	self._health -= applied; self._lastDamaged = self._time
	if self._health <= 0 then
		self:ReleaseTrap(self._trapOwner)
		self:_clearTarget("Dead")
		local patrol = self:_patrol(); if patrol then patrol:SetDead(true) end
		self._state = "Dead"
	else
		local patrol = self:_patrol()
		if patrol then
			local kind=if source=="Pet" then "Pet" else "Player"
   if self._target~=player or self._targetKind~=kind then self:_cancelAttack() end
			if patrol:BeginCombat() ~= false then
				self._target = player;self._targetKind=kind; self._state = "Chasing"; self._blockedFor = 0
			end
		end
	end
	self:_publish()
	if self.OnDamage then self.OnDamage(player,beforeHP,self._health) end
	return applied
end
function Combat:_cancelAttack()
	self._attackVictim = nil; self._attackHit = false
	if self._jaw then self._jaw:Cancel() end
	self:_setPhase("Idle")
end
function Combat:_clearTarget(state)
	local wasTarget = self._target ~= nil
	self._target = nil;self._targetKind=nil; self._blockedFor = 0
	self:_cancelAttack()
	if wasTarget then local patrol = self:_patrol(); if patrol then patrol:EndCombat() end end
	self._state = state or (if wasTarget then "Returning" else "Idle")
	self:_publish()
end
function Combat:PlayerExited(player)
	self._tokens[player] = nil; self._lastHits[player] = nil; self._petLastHits[player] = nil
	if self._target == player or self._attackVictim == player then self:_clearTarget() end
end
function Combat:_supportAndForward()
	local patrol = self:_patrol()
	local snapshot = patrol and patrol:GetSnapshot()
	local support = snapshot and snapshot.SupportPosition
	if not vector(support) then support = self.Root.Position - Vector3.new(0, 23, 0) end
	local direction = self.Root.CFrame:VectorToWorldSpace(self.Model:GetAttribute("ForwardInRoot") or Vector3.new(0, 0, -1))
	direction = flat(direction)
	if direction.Magnitude < .01 then direction = Vector3.new(0, 0, -1) else direction = direction.Unit end
	return support, direction, snapshot
end
function Combat:GetSupportPoint()
	local support = self:_supportAndForward()
	return support
end
function Combat:GetCapturePoint()
	local support, direction = self:_supportAndForward()
	local point = support + direction * (self.Settings.BiteForwardOffset + 16)
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {workspace.Terrain, self.Forest}; params.RespectCanCollide = true
	local hit = workspace:Raycast(point + Vector3.new(0, 24, 0), Vector3.new(0, -64, 0), params)
	return if hit and hit.Material ~= Enum.Material.Water and hit.Normal.Y > .6 then hit.Position + Vector3.new(0, 2.5, 0) else nil
end
function Combat:TrapFor(runId, untilTime)
	if self._destroyed or self._captured or self._health <= 0 or type(runId) ~= "string"
		or not finite(untilTime) or untilTime <= workspace:GetServerTimeNow() or self._trapOwner then return false end
	self._trapOwner, self._trapUntil = runId, untilTime
	self._trapRouteEnabled = self.Model:GetAttribute("RouteEnabled")
	self.Model:SetAttribute("RouteEnabled", false)
	self:_cancelAttack(); self._state = "Trapped"; self:_publish()
	return true
end
function Combat:ReleaseTrap(runId)
	if not self._trapOwner or (runId ~= nil and runId ~= self._trapOwner) then return false end
	self._trapOwner, self._trapUntil = nil, nil
	self.Model:SetAttribute("RouteEnabled", self._trapRouteEnabled)
	self._trapRouteEnabled = nil
	self._state = if self._target then "Chasing" else "Idle"
	self:_publish(); return true
end
function Combat:Capture(runId, verifiedNow)
	if self._destroyed or self._captured or self._health <= 0 or self._health > self.Settings.MaxHealth * .1
		or self._trapOwner ~= runId or (verifiedNow or workspace:GetServerTimeNow()) > (self._trapUntil or 0) then return false end
	self._captured = true; self._captureGeneration = (self._captureGeneration or 0) + 1
	local generation = self._captureGeneration
	self:_clearTarget("Captured"); self:ReleaseTrap(runId); self._state = "Captured"
	local patrol = self:_patrol(); if patrol then patrol:SetDead(true); patrol:Stop() end
	self._captureScale = self.Model:GetScale(); self._captureVisuals = {}
	for _, part in self.Model:GetDescendants() do
		if part:IsA("BasePart") then self._captureVisuals[part] = part.Transparency end
	end
	self._gui.Enabled = false; self:_publish()
	task.spawn(function()
		for step = 1, 20 do
			if self._destroyed or not self._captured or self._captureGeneration ~= generation then return end
			local alpha = step / 20
			self.Model:ScaleTo(self._captureScale * (1 - .85 * alpha))
			for part, original in self._captureVisuals do if part.Parent then part.Transparency = original + (1 - original) * alpha end end
			task.wait(.1)
		end
	end)
	return true
end
function Combat:_updateAttackBox()
	local support, direction = self:_supportAndForward()
	local center = support + direction * self.Settings.BiteForwardOffset + Vector3.yAxis * self.Settings.BiteHeightAboveGround
	local cf = CFrame.lookAt(center, center + direction)
	self._attackWeld.C0 = self.Root.CFrame:ToObjectSpace(cf)
	return support, direction, cf
end
function Combat:_canBite(player)
	local character, humanoid, root = self:_victim(player)
	if not character then return false end
	local support, forward, cf = self:_updateAttackBox()
	local offset = flat(root.Position - support)
	if offset.Magnitude > self.Settings.BiteRange or offset.Magnitude < .01 or forward:Dot(offset.Unit) < self.Settings.BiteMinimumFacingDot then return false end
	local localRoot = cf:PointToObjectSpace(root.Position)
	local half = self.Settings.BiteHitboxSize * .5 + Vector3.new(1.5, 2, 1.5)
	if math.abs(localRoot.X) > half.X or math.abs(localRoot.Y) > half.Y or math.abs(localRoot.Z) > half.Z then return false end
	if not self:_lineOfSight(support + Vector3.yAxis * 7, root.Position, character) then return false end
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	overlap.FilterDescendantsInstances = {character}; overlap.RespectCanCollide = false
	local foundBody = false
	for _, part in workspace:GetPartBoundsInBox(cf, self.Settings.BiteHitboxSize, overlap) do
		if part == root or part.Parent == character then foundBody = true; break end
	end
	return foundBody, humanoid
end
function Combat:_startAttack()
	self._attackVictim = self._target; self._attackHit = false
	self._attackSequence += 1; self._lastAttack = self._time
	self._state = "Windup"; self:_setPhase("Windup", self.Settings.BiteWindup)
	-- Open the jaw during the warning, then bite once when the active window opens.
	if self._jaw then self._jaw:SetOpenAngle(20) end
end
function Combat:_attackStep()
	if self._phase == "Windup" and self._time >= self._phaseUntil then
		self._state = "Biting"; self:_setPhase("Active", self.Settings.BiteActiveSeconds)
		if self._jaw then task.spawn(function() if not self._destroyed and self._phase == "Active" then self._jaw:Bite() end end) end
	end
	if self._phase == "Active" then
		if not self._attackHit and self._attackVictim == self._target then
			local valid, humanoid = self:_canBite(self._attackVictim)
			if valid and self._targetKind~="Pet" then
				self._attackHit = true; self._attackHits += 1
				if self._damagePlayer then self._damagePlayer(self._attackVictim, self.Settings.BiteDamage, self.Model)
				else humanoid:TakeDamage(self.Settings.BiteDamage) end
				self:_publish()
			end
		end
		-- Pets use the same short, server-owned bite volume and sequence. The
		-- companion controller checks its body, line of sight and one hit per bite.
		if self._damagePets and self._targetKind=="Pet" and self._phase == "Active" and self._health > 0 then
			self._damagePets(self._attackBox.CFrame, self.Settings.BiteHitboxSize,
				self._attackSequence, self.Settings.BiteDamage, self.Model, self._target and self._target.UserId)
		end
		if self._time >= self._phaseUntil then self._state = "Recovering"; self:_setPhase("Recovery", self.Settings.BiteRecovery) end
	elseif self._phase == "Recovery" and self._time >= self._phaseUntil then
		self._state = "Chasing"; self:_setPhase("Idle")
	end
end
function Combat:Step(dt)
	if not self._running or self._destroyed then return end
	if not finite(dt) or dt <= 0 then return end
	dt = math.min(dt, .2); self._time += dt
	if not self.Model.Parent or not self.Root.Parent then self:Destroy(); return end
	if self._captured then return end
	if self._trapOwner then
		if self._health <= 0 or workspace:GetServerTimeNow() > self._trapUntil then self:ReleaseTrap(self._trapOwner)
		else self._state = "Trapped"; self:_publish(); return end
	end
	self:_updateAttackBox()
	if self._target and self._health > 0 then
		local character, _, targetRoot = self:_victim(self._target)
		local support, _, snapshot = self:_supportAndForward()
		local patrol = self:_patrol()
		local anchor = snapshot and snapshot.PatrolAnchor
		local leashed = not (snapshot and snapshot.UnrestrictedRoam) and vector(anchor) and targetRoot and flat(targetRoot.Position - anchor).Magnitude > self.Settings.LeashDistance
		if not character or not patrol or leashed or self._time - self._lastDamaged > self.Settings.AggroTimeout then self:_clearTarget()
		else
			self._blockedFor = if snapshot and snapshot.CombatBlocked then self._blockedFor + dt else 0
			if self._blockedFor >= self.Settings.BlockedTimeout then self:_clearTarget()
			elseif self._phase ~= "Idle" then
				-- The warning locks its direction. Running behind or sideways can evade
				-- the actual short active volume; the dinosaur never snaps to a player.
				patrol:SetCombatGoal(support, {StopDistance = 0, Speed = self.Settings.ChaseSpeed * (if self._health <= self.Settings.MaxHealth * .1 then .6 else 1)})
				self:_attackStep()
			else
				local distance = flat(targetRoot.Position - support).Magnitude
				if distance <= self.Settings.BiteRange then
					patrol:SetCombatGoal(support, {StopDistance = 0, Speed = self.Settings.ChaseSpeed * (if self._health <= self.Settings.MaxHealth * .1 then .6 else 1)})
					patrol:FaceCombat(targetRoot.Position)
					if self._time - self._lastAttack >= self.Settings.BiteCooldown and self:_canBite(self._target) then self:_startAttack() end
				elseif patrol:SetCombatGoal(targetRoot.Position, {StopDistance = self.Settings.ChaseStopDistance, Speed = self.Settings.ChaseSpeed * (if self._health <= self.Settings.MaxHealth * .1 then .6 else 1)}) == false then self:_clearTarget() end
			end
		end
	elseif self._state == "Returning" then
		local patrol = self:_patrol()
		local snapshot = patrol and patrol:GetSnapshot()
		if not snapshot or snapshot.MotionMode == "Patrol" then self._state = "Idle"; self:_publish() end
	end
	self._publishElapsed += dt
	if self._publishElapsed >= .2 then self._publishElapsed = 0; self:_publish() end
end
function Combat:GetSnapshot()
	return {Health = self._health, MaxHealth = self.Settings.MaxHealth, State = self._state,
		Captured = self._captured == true, Trapped = self._trapOwner ~= nil, TrapUntil = self._trapUntil,
		TargetUserId = if self._target then self._target.UserId else 0,
		AttackSequence = self._attackSequence, AttackPhase = self._phase, AttackHits = self._attackHits,
		Time = self._time, AttackBoxCFrame = self._attackBox.CFrame, AttackBoxSize = self._attackBox.Size}
end
function Combat:Start()
	assert(not self._destroyed, "Combat controller destroyed")
	if self._running then return self end
	self._running = true
	if self._autoConnect then self._connection = RunService.Heartbeat:Connect(function(dt) self:Step(dt) end) end
	self:_publish(); return self
end
function Combat:Reset()
	if self._destroyed then return end
	self._captureGeneration = (self._captureGeneration or 0) + 1
	self._captured = false; self:ReleaseTrap(self._trapOwner)
	if self._captureScale then self.Model:ScaleTo(self._captureScale); self._captureScale = nil end
	for part, transparency in self._captureVisuals or {} do if part.Parent then part.Transparency = transparency end end
	self._captureVisuals = nil; self._gui.Enabled = true
	self:_clearTarget("Idle")
	self._health = self.Settings.MaxHealth; self._lastDamaged = -math.huge; self._lastAttack = -math.huge
	self._tokens = {}; self._lastHits = {}; self._petLastHits = {}; self._attackSequence = 0; self._attackHits = 0
	local patrol = self:_patrol(); if patrol then patrol:SetDead(false) end
	self:_updateAttackBox(); self:_publish()
end
function Combat:Destroy(restore)
	if self._destroyed then return end
	self:_clearTarget("Idle"); self._running = false; self._destroyed = true
	if self._connection then self._connection:Disconnect() end
	if self._debugConnection then self._debugConnection:Disconnect() end
	self._folder:Destroy(); self._gui:Destroy(); owners[self.Model] = nil
	if restore then for key, original in self._original do self.Model:SetAttribute(key, original.value) end end
end
return Combat
