-- Server-owned hunting companion. Health/cooldowns live in Memory, not in a client GUI
-- or in the replaceable character model. This module never teleports a following pet.
local PathfindingService = game:GetService("PathfindingService")

local Controller = {}
Controller.__index = Controller

local UP = Vector3.new(0, 1, 0)
local BODY_OFFSET = Vector3.new(0, 2, 0)
local NAV_SIZE = Vector3.new(2, 3.4, 1.8)
local CHASE_LIMIT = 80

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end
local function finite(n)
	return type(n) == "number" and n == n and math.abs(n) < math.huge
end
local function vector(v)
	return typeof(v) == "Vector3" and finite(v.X) and finite(v.Y) and finite(v.Z)
end
local function setAttribute(object, key, value)
	if object and object.Parent and object:GetAttribute(key) ~= value then object:SetAttribute(key, value) end
end

function Controller.new(options)
	local self = setmetatable({}, Controller)
	for key, value in options do self[key] = value end
	assert(self.Player and self.Pet and self.Character and self.Humanoid and self.Root, "Missing companion owner")
	assert(self.Animator and self.Rules and self.Memory and self.Combat, "Missing companion services")
	self._generation = 0
	self._attackSerial = 0
	self._attack = nil
	self._healing = nil
	self._path = nil
	self._waypoints = nil
	self._pathPending = false
	self._pathReadyAt = 0
	self._biteTokens = {}
	self._state = "Following"
	self._destroyed = false
	self._returning = false
	self._recovering = false
	self:_publish()
	return self
end

function Controller:_now()
	return workspace:GetServerTimeNow()
end
function Controller:_alive()
	return not self._destroyed and self.Player.Parent ~= nil and self.Character.Parent ~= nil
		and self.Pet.Parent ~= nil and self.Pet.PrimaryPart ~= nil and self.Root.Parent ~= nil
		and self.Humanoid.Parent ~= nil and self.Humanoid.Health > 0
end
function Controller:_canAct()
	return self:_alive() and self.CanAct() == true and self.Player:GetAttribute("AdminFlying") ~= true
		and self.Player:GetAttribute("HuntCaptureActive") ~= true
end
function Controller:_hunting()
	return self.Player:GetAttribute("InHunting") == true
end
function Controller:_stunned(now)
	return now < (self.Memory.StunnedUntil or 0)
end
function Controller:_publish()
	local memory = self.Memory
	for _, object in {self.Player, self.Pet} do
		setAttribute(object, "PetHealth", memory.Health)
		setAttribute(object, "PetMaxHealth", self.Rules.Config.MaxHealth)
		setAttribute(object, "PetState", self._state)
		setAttribute(object, "PetStunnedUntil", memory.StunnedUntil or 0)
		setAttribute(object, "PetHealReadyAt", memory.HealReadyAt or 0)
		setAttribute(object, "PetHealCasting", self._healing ~= nil)
		setAttribute(object, "PetNextAttackAt", memory.NextAttackAt or 0)
		setAttribute(object, "PetHealingUntil", if self._healing then self._healing.FinishAt or 0 else 0)
	end
end
function Controller:_moving(on)
	setAttribute(self.Pet, "PetMoving", on)
	setAttribute(self.Pet, "PetSpeed", 1.3)
	self.Animator:SetMoving(on, 1.3)
end
function Controller:_setState(state)
	self._state = state
	self:_publish()
end
function Controller:_clearAttack()
	self._attackSerial += 1
	self._attack = nil
	self.Animator.OnHit = nil
	self.Animator:CancelAttack()
	setAttribute(self.Pet, "PetAttackStarted", -1)
end
function Controller:_clearPath()
	self._generation += 1
	if self._path then self._path:Destroy() end
	self._path = nil
	self._waypoints = nil
	self._pathGoal = nil
	self._waypointIndex = nil
end
function Controller:_clearMedicine()
	if self._medicineOrb then self._medicineOrb:Destroy(); self._medicineOrb = nil end
end
function Controller:Cancel(reason)
	if self._destroyed then return end
	-- Each hunt restarts the dinosaur's bite counter. Ordinary interruption must
	-- keep its token, so a stun or a fly toggle cannot duplicate the current bite.
	if reason == "Travel" or reason == "SessionReset" then table.clear(self._biteTokens) end
	self._healing = nil
	self:_clearAttack()
	self:_clearPath()
	self:_clearMedicine()
	self:_moving(false)
	self:_setState(if self:_stunned(self:_now()) then "Stunned" else "Following")
end
function Controller:ResetForArea(now)
	self:Cancel("SessionReset")
	self.Rules.rest(self.Memory, now or self:_now())
	self._returning, self._recovering = false, false
	self:_setState("Following")
end
function Controller:_followGoal()
	local aiming = self.Player:GetAttribute("BowAiming") == true
	return self.Root.CFrame:PointToWorldSpace(if aiming then Vector3.new(-7, 0, 7) else Vector3.new(3, 0, 4))
end
function Controller:_recoveryGoal()
	local point=self.Combat:GetClosestHitPoint(self.Root.Position+BODY_OFFSET,CHASE_LIMIT)
	if not point then return self:_followGoal() end
	local away=flat(self.Root.Position-point)
	if away.Magnitude<.1 then away=-flat(self.Root.CFrame.LookVector) end
	-- Stay outside the bite area even when the owner keeps fighting nearby.
	return point+away.Unit*(self.Rules.Config.RecoverySafeRange+8)
end
function Controller:_targetAttackable()
	local snapshot = self.Combat:GetSnapshot()
	return snapshot and not snapshot.Captured and snapshot.Health > snapshot.MaxHealth * .1
end

-- Ignore the visual pet/owner and the dinosaur for floor sampling. Their feet
-- must not become accidental bridges over a lake or a gap in the real ground.
function Controller:_navigationParams()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignored = {self.Character, self.PetFolder or self.Pet}
	if self.Combat.Model then table.insert(ignored, self.Combat.Model) end
	params.FilterDescendantsInstances = ignored
	params.RespectCanCollide = true
	params.IgnoreWater = false
	return params
end
function Controller:_ground(point, referenceY, params)
	local hit = workspace:Raycast(Vector3.new(point.X, referenceY + 3, point.Z), Vector3.new(0, -8, 0), params)
	if not hit or hit.Material == Enum.Material.Water or hit.Normal.Y < .65 then return nil end
	return Vector3.new(point.X, hit.Position.Y + .03, point.Z)
end
function Controller:_segment(from, to, params)
	local delta = flat(to - from)
	if delta.Magnitude < .01 then return nil end
	local ground = self:_ground(to, from.Y, params)
	if not ground or math.abs(ground.Y - from.Y) > math.min(2.2, 1 + delta.Magnitude * .7) then return nil end
	local side = Vector3.new(-delta.Z, 0, delta.X).Unit * .65
	for _, offset in {side, -side} do
		local edge = self:_ground(ground + offset, from.Y, params)
		if not edge or math.abs(edge.Y - ground.Y) > 1.2 then return nil end
	end
	-- Sweep the pet's width, rather than a single thin ray that can slip through
	-- a tree trunk or the corner of one of the valley's cliff walls.
	local rise = math.max(0, ground.Y - from.Y)
	local origin = CFrame.lookAt(from + Vector3.new(0, 2.25 + rise, 0), from + delta + Vector3.new(0, 2.25 + rise, 0))
	local obstacle = workspace:Blockcast(origin, NAV_SIZE, ground - from, params)
	if obstacle then return nil end
	return ground
end
function Controller:_requestPath(goal, now)
	if self._destroyed or self._pathPending or now < self._pathReadyAt then return end
	self._pathReadyAt = now + 1.5
	self._pathPending = true
	local generation = self._generation
	local origin = self.Pet.PrimaryPart.Position
	-- Path computation yields, so it never runs in the game's Heartbeat loop.
	task.spawn(function()
		local path
		local ok = pcall(function()
			path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 4, AgentCanJump = false,
				AgentCanClimb = false, WaypointSpacing = 3, Costs = {Water = math.huge}})
			path:ComputeAsync(origin + UP, goal + UP)
		end)
		self._pathPending = false
		if self._destroyed or generation ~= self._generation or not self:_canAct()
			or not self.Pet.PrimaryPart or (self.Pet.PrimaryPart.Position - origin).Magnitude > 10 then
			if path then path:Destroy() end
			return
		end
		if ok and path.Status == Enum.PathStatus.Success then
			if self._path then self._path:Destroy() end
			self._path, self._pathGoal = path, goal
			self._waypoints = path:GetWaypoints()
			self._waypointIndex = 2
		else
			if path then path:Destroy() end
		end
	end)
end
function Controller:_walk(goal, now, dt, stopDistance)
	local from = self.Pet.PrimaryPart.Position
	local delta = flat(goal - from)
	if delta.Magnitude <= (stopDistance or .3) then self:_moving(false); return false end
	local params = self:_navigationParams()
	if self._pathGoal and (flat(goal - self._pathGoal)).Magnitude > 7 then self:_clearPath() end
	local direction = delta
	if self._waypoints then
		local waypoint = self._waypoints[self._waypointIndex]
		while waypoint and (flat(waypoint.Position - from)).Magnitude < 1.2 do
			self._waypointIndex += 1
			waypoint = self._waypoints[self._waypointIndex]
		end
		if waypoint and waypoint.Action == Enum.PathWaypointAction.Jump then
			self:_clearPath()
			self:_moving(false)
			return false
		elseif waypoint then direction = flat(waypoint.Position - from) else self:_clearPath() end
	end
	local distance = math.min(direction.Magnitude, self.Rules.Config.MoveSpeed * math.clamp(dt, 0, .25))
	if distance < .01 then self:_moving(false); return false end
	local nextPosition = self:_segment(from, from + direction.Unit * distance, params)
	if not nextPosition then
		if self._waypoints then self:_clearPath() end
		self:_requestPath(goal, now)
		self:_moving(false)
		return false
	end
	self.Pet:PivotTo(CFrame.lookAt(nextPosition, nextPosition + direction.Unit))
	self:_moving(true)
	return true
end
function Controller:_face(point)
	local origin = self.Pet.PrimaryPart.Position
	local direction = flat(point - origin)
	if direction.Magnitude > .01 then self.Pet:PivotTo(CFrame.lookAt(origin, origin + direction.Unit)) end
end
function Controller:_lineOfSight(origin, point, target)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {self.Character, self.PetFolder or self.Pet}
	params.RespectCanCollide = true
	params.IgnoreWater = false
	local delta = point - origin
	if delta.Magnitude < .01 then return true end
	local hit = workspace:Raycast(origin, delta, params)
	return not hit or hit.Distance >= delta.Magnitude - .35 or (target and hit.Instance:IsDescendantOf(target))
end
function Controller:_attackAllowed(now)
	return self:_canAct() and self:_hunting() and self.IsEngaged() == true and not self:_stunned(now)
		and self:_targetAttackable() and not self._recovering
		and not self._healing and (self.Pet.PrimaryPart.Position - self.Root.Position).Magnitude <= CHASE_LIMIT
end
function Controller:_attackPoint(range)
	local center = self.Pet.PrimaryPart.Position + BODY_OFFSET
	local point = self.Combat:GetClosestHitPoint(center, range)
	if not point or (point - self.Root.Position).Magnitude > CHASE_LIMIT then return nil end
	return point
end
function Controller:_startAttack(now)
	if self._attack or self.Animator:IsAttacking() or not self:_attackAllowed(now)
		or not self.Rules.canAttack(self.Memory, now) then return end
	local point = self:_attackPoint(self.Rules.Config.AttackRange)
	local center = self.Pet.PrimaryPart.Position + BODY_OFFSET
	if not point or not self:_lineOfSight(center, point, self.Combat.Model) then return end
	local count = self.Animator:GetHitCount()
	if count < 1 then return end
	self._attackSerial += 1
	local serial = self._attackSerial
	local attack = {Serial = serial, HitCount = count, Fired = {},
		TokenPrefix = string.format("pet:%d:%.6f:%d", self.Player.UserId, now, serial)}
	self._attack = attack
	self.Animator.OnHit = function(index)
		if self._destroyed or self._attack ~= attack or serial ~= self._attackSerial or attack.Hit or attack.Fired[index] then return end
		attack.Fired[index] = true
		local hitNow = self:_now()
		if not self:_attackAllowed(hitNow) then return end
		local hitPoint = self:_attackPoint(self.Rules.Config.AttackRange)
		local origin = self.Pet.PrimaryPart.Position + BODY_OFFSET
		if not hitPoint or not self:_lineOfSight(origin, hitPoint, self.Combat.Model) then return end
		-- One strike per visit, even when a weapon animation has several markers.
		attack.Hit = true
		self._returning = true
		self.Memory.NextAttackAt = hitNow + self.Rules.Config.AttackInterval
		local amount = self.Rules.Config.AttackDamage
		local token = string.format("%s:%d", attack.TokenPrefix, index)
		local applied = self.Combat:Damage(self.Player, amount, hitPoint, token, "Pet")
		if applied > 0 then
			if self.OnDamage then self.OnDamage(applied, hitPoint) end
			if self.Remote then
				self.Remote:FireAllClients("Hit", hitPoint, applied, true)
				if self.Pet:GetAttribute("PetWeaponId") == "Bow" then self.Remote:FireAllClients("Shot", origin, hitPoint, false) end
			end
		end
	end
	self:_face(point)
	if self.Animator:Attack() then
		self.Rules.beginAttack(self.Memory, now)
		setAttribute(self.Pet, "PetAttackStarted", now)
		setAttribute(self.Pet, "PetAttackSequence", (self.Pet:GetAttribute("PetAttackSequence") or 0) + 1)
		self:_moving(false)
		self:_setState("Attacking")
	else
		self._attack = nil
		self.Animator.OnHit = nil
	end
end

function Controller:_updateMedicine(now)
	if not self._medicineOrb then
		local orb = Instance.new("Part")
		orb.Name = "PetMedicineOrb"
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(1.05, 1.05, 1.05)
		orb.Color = Color3.fromRGB(98, 255, 135)
		orb.Material = Enum.Material.Neon
		orb.Anchored = true
		orb.CanCollide, orb.CanTouch, orb.CanQuery = false, false, false
		orb.Parent = self.Pet
		self._medicineOrb = orb
	end
	local carried = self.Pet.PrimaryPart.CFrame:PointToWorldSpace(Vector3.new(1.2, 2.4, -.2))
	local healing = self._healing
	if healing and healing.StartedAt then
		local t = math.clamp((now - healing.StartedAt) / self.Rules.Config.HealCastSeconds, 0, 1)
		local destination = self.Root.Position + Vector3.new(0, .2, 0)
		carried = carried:Lerp(destination, t) + UP * math.sin(t * math.pi) * 1.8
	end
	self._medicineOrb.Position = carried
end
function Controller:RequestHeal(now)
	if self._destroyed then return false, "Unavailable" end
	now = now or self:_now()
	self.Rules.tick(self.Memory, now)
	if not self:_canAct() then return false, "Unavailable" end
	if self._healing then return false, "Healing" end
	local allowed, reason = self.Rules.canHeal(self.Memory, now, self.Humanoid.Health, self.Humanoid.MaxHealth)
	if not allowed then self:_publish(); return false, reason end
	self:_clearAttack()
	self:_clearPath()
	self._healing = {RequestedAt = now}
	self:_updateMedicine(now)
	self:_setState("HealApproach")
	return true
end
function Controller:_stepHeal(now, dt)
	local healing = self._healing
	if not healing then return false end
	local allowed = self.Rules.canHeal(self.Memory, now, self.Humanoid.Health, self.Humanoid.MaxHealth)
	if not self:_canAct() or self:_stunned(now) or not allowed or now - healing.RequestedAt > 12 then
		self:Cancel("HealInterrupted")
		return false
	end
	local center = self.Pet.PrimaryPart.Position + BODY_OFFSET
	local ownerPoint = self.Root.Position
	local distance = (center - ownerPoint).Magnitude
	local visible = self:_lineOfSight(center, ownerPoint, self.Character)
	if distance > self.Rules.Config.HealRange or not visible then
		healing.StartedAt, healing.FinishAt = nil, nil
		local desired = self.Root.CFrame:PointToWorldSpace(Vector3.new(2.4, 0, 1))
		self:_walk(desired, now, dt, .25)
		self:_setState("HealApproach")
	elseif not healing.StartedAt then
		healing.StartedAt, healing.FinishAt = now, now + self.Rules.Config.HealCastSeconds
		self:_moving(false)
		self:_face(ownerPoint)
		self:_setState("Healing")
	elseif now >= healing.FinishAt then
		-- Recheck owner life/range/LOS at the commit frame; the cooldown begins
		-- only after a real heal, never merely for requesting or interrupting one.
		local currentHealth = self.Humanoid.Health
		local amount = self.Rules.commitHeal(self.Memory, now, currentHealth, self.Humanoid.MaxHealth)
		if amount > 0 then self.Humanoid.Health = math.min(self.Humanoid.MaxHealth, currentHealth + amount) end
		self._healing = nil
		self:_clearMedicine()
		self:_setState("Following")
		return true
	end
	self:_updateMedicine(now)
	self:_publish()
	return true
end

function Controller:Damage(amount, now)
	if self._destroyed or not self:_canAct() then return 0 end
	now = now or self:_now()
	local applied = self.Rules.damage(self.Memory, amount, now)
	if applied > 0 then
		if self:_stunned(now) then self:Cancel("Stunned"); self:_setState("Stunned") end
		self:_publish()
	end
	return applied
end
function Controller:DamageInBite(cf, size, sequence, damage, sourceModel, now)
	if not self:_canAct() or not self:_hunting() or not finite(damage) or damage <= 0
		or typeof(cf) ~= "CFrame" or not vector(size) or size.X <= 0 or size.Y <= 0 or size.Z <= 0
		or (type(sequence) ~= "number" and type(sequence) ~= "string") then return 0 end
	now = now or self:_now()
	local sourceKey = sourceModel or self.Combat.Model
 if sourceKey then
  local target=sourceKey:GetAttribute("CombatTargetUserId")
  local kind=sourceKey:GetAttribute("CombatTargetKind")
  if (target~=nil and target~=self.Player.UserId) or (kind~=nil and kind~="Pet") then return 0 end
  local faction=sourceKey:GetAttribute("CombatFaction")
  if faction and faction==self.Pet:GetAttribute("CombatFaction") then return 0 end
 end
	local token = self._biteTokens[sourceKey]
	if token and token.Sequence == sequence then return 0 end
	local center = self.Pet.PrimaryPart.Position + BODY_OFFSET
	local localPoint = cf:PointToObjectSpace(center)
	if math.abs(localPoint.X) > size.X * .5 or math.abs(localPoint.Y) > size.Y * .5
		or math.abs(localPoint.Z) > size.Z * .5 then return 0 end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignored = {self.Character, self.PetFolder or self.Pet}
	if sourceKey then table.insert(ignored, sourceKey) end
	params.FilterDescendantsInstances = ignored
	params.RespectCanCollide = true
	params.IgnoreWater = false
	local delta = center - cf.Position
	local obstruction = workspace:Raycast(cf.Position, delta, params)
	if obstruction and obstruction.Distance < delta.Magnitude - .2 then return 0 end
	self._biteTokens[sourceKey] = {Sequence = sequence, At = now}
	for model, entry in self._biteTokens do if now - entry.At > 60 then self._biteTokens[model] = nil end end
	return self:Damage(damage, now)
end

-- The old training dummy follower remains authoritative when this returns false.
-- Animator:Update is still called once by Training.server after either mover.
function Controller:Step(now, dt)
	if self._destroyed then return false end
	now = now or self:_now()
	local center = self.Pet.PrimaryPart and self.Pet.PrimaryPart.Position + BODY_OFFSET
	local nearOwner = center and (center - self.Root.Position).Magnitude <= 14
	local threatNear = center and self:_hunting() and self.Combat:GetClosestHitPoint(center, self.Rules.Config.RecoverySafeRange) ~= nil
	local nearRetreat = center and self._recovering and (center-self.Root.Position).Magnitude<=CHASE_LIMIT
	local recovering = (nearOwner or nearRetreat) and not threatNear and not self._attack and not self._healing
	self.Rules.tick(self.Memory, now, recovering)
	if self.Memory.Health <= self.Rules.Config.MaxHealth * self.Rules.Config.RetreatRatio then self._recovering = true end
	if self.Memory.Health >= self.Rules.Config.MaxHealth then self._recovering = false end
	if not self:_canAct() then
		local handled = self:_hunting() or self.Player:GetAttribute("AdminFlying") == true
			or self:_stunned(now) or self._healing ~= nil or not self:_alive()
		if self._attack or self._healing or self._waypoints then self:Cancel("Inactive") end
		self:_moving(false)
		self:_setState(if self:_stunned(now) then "Stunned" elseif handled then "Waiting" else "Following")
		return handled
	end
	if self:_stunned(now) then
		if self._attack or self._healing then self:Cancel("Stunned") end
		self:_moving(false)
		self:_setState("Stunned")
		return true
	end
	if self:_stepHeal(now, dt) then return true end
	if self._recovering then
		if self._attack then self:_clearAttack() end
		self:_walk(self:_recoveryGoal(), now, dt, 1)
		self:_setState("Recovering")
		return true
	end
	if not self:_hunting() then
		if self._attack then self:_clearAttack() end
		if self._waypoints then self:_clearPath() end
		self:_setState("Following")
		return false
	end
	if self._attack then
		if not self:_attackAllowed(now) or self._attack.Hit then self:_clearAttack(); self._returning = true
		elseif not self.Animator:IsAttacking() then self._attack = nil; self.Animator.OnHit = nil; self._returning = true
		else self:_moving(false); self:_setState("Attacking"); return true end
	end
	local home = self:_followGoal()
	if self._returning or not self.Rules.canAttack(self.Memory, now) then
		self:_walk(home, now, dt, 1)
		if flat(self.Pet.PrimaryPart.Position - home).Magnitude <= 1.25 then self._returning = false end
		self:_setState(if self._returning then "Returning" else "Waiting")
		return true
	end
	local engaged = self:_attackAllowed(now)
	local point = if engaged then self:_attackPoint(CHASE_LIMIT) else nil
	if point then
		local center = self.Pet.PrimaryPart.Position + BODY_OFFSET
		if (point - center).Magnitude <= self.Rules.Config.AttackRange and self:_lineOfSight(center, point, self.Combat.Model) then
			self:_moving(false)
			self:_face(point)
			self:_startAttack(now)
			if not self._attack then self:_setState("Following") end
		else
			self:_walk(point, now, dt, 2.8)
			self:_setState("Following")
		end
	else
		self:_walk(home, now, dt, 1)
		self:_setState("Following")
	end
	self:_publish()
	return true
end
function Controller:GetSnapshot()
	return {
		Health = self.Memory.Health,
		MaxHealth = self.Rules.Config.MaxHealth,
		State = self._state,
		StunnedUntil = self.Memory.StunnedUntil or 0,
		HealReadyAt = self.Memory.HealReadyAt or 0,
		NextAttackAt = self.Memory.NextAttackAt or 0,
		Healing = self._healing ~= nil,
		HealingUntil = if self._healing then self._healing.FinishAt or 0 else 0,
		Position = if self.Pet.PrimaryPart then self.Pet.PrimaryPart.Position else nil,
		AttackSerial = self._attackSerial,
		PathPending = self._pathPending,
		PathFollowing = self._waypoints ~= nil,
		Destroyed = self._destroyed,
	}
end
function Controller:Destroy()
	if self._destroyed then return end
	self:Cancel("Destroyed")
	self._destroyed = true
	table.clear(self._biteTokens)
end

return Controller
