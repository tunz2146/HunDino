-- Server patrol for the existing segmented prototype. This controller owns both
-- root placement and the six-joint gait; keep the old circular MotionRuntime disabled.
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local HttpService = game:GetService("HttpService")
local Controller = {}
Controller.__index = Controller
local owners = setmetatable({}, {__mode = "k"})
local Y = Vector3.yAxis
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function finite(v)
	return typeof(v) == "Vector3" and v.X == v.X and v.Y == v.Y and v.Z == v.Z
		and math.abs(v.X) < 1e6 and math.abs(v.Y) < 1e6 and math.abs(v.Z) < 1e6
end
local function number(value, fallback, minimum, maximum)
	if type(value) ~= "number" or value ~= value then return fallback end
	return math.clamp(value, minimum, maximum)
end
local function approach(current, target, distance)
	return current + math.clamp(target - current, -distance, distance)
end
local function angleDelta(a, b) return (b - a + math.pi) % (2 * math.pi) - math.pi end
local function reverse(points)
	local result = {}
	for i = #points, 1, -1 do table.insert(result, points[i]) end
	return result
end
local function buildNetwork(map, config)
	local report = {ok = true, errors = {}, paths = 0, routes = 0}
	local network = {}
	local function failure(message) report.ok = false; table.insert(report.errors, message) end
	local paths = map:FindFirstChild("Paths")
	if not paths then failure("Missing map Paths"); return network, report end
	for _, path in paths:GetChildren() do
		if not path:IsA("Model") or path:GetAttribute("HumanOnly") == true then continue end
		local a, b = path:GetAttribute("FromZone"), path:GetAttribute("ToZone")
		if type(a) ~= "string" or type(b) ~= "string" then failure(path.Name .. " has no endpoints"); continue end
		local segments = {}
		for _, part in path:GetChildren() do
			if part:IsA("BasePart") and part.Name == "WalkSurface" then table.insert(segments, part) end
		end
		table.sort(segments, function(x, z) return (x:GetAttribute("SampleIndex") or 0) < (z:GetAttribute("SampleIndex") or 0) end)
		local points = {}
		for _, part in segments do
			local start, finish = part:GetAttribute("RouteStart"), part:GetAttribute("RouteEnd")
			if typeof(start) ~= "Vector3" or typeof(finish) ~= "Vector3" then failure(path.Name .. " has invalid surface samples"); continue end
			if #points == 0 then table.insert(points, start)
			elseif (points[#points] - start).Magnitude > 2 then failure(path.Name .. " has a gap") end
			if (flat(finish) - flat(points[#points])).Magnitude > .01 then table.insert(points, finish) end
		end
		if #points < 2 then failure(path.Name .. " has no traversable samples"); continue end
		network[a] = network[a] or {}; network[b] = network[b] or {}
		network[a][b] = points
		if path:GetAttribute("Bidirectional") == true then network[b][a] = reverse(points) end
		report.paths += 1
	end
	for home, routes in config.Routes do
		for index, route in routes do
			report.routes += 1
			if route[1] ~= home or route[#route] ~= home then failure(home .. "/" .. index .. " does not return home") end
			for i = 1, #route - 1 do
				if not (network[route[i]] and network[route[i]][route[i + 1]]) then failure(route[i] .. " -> " .. route[i + 1] .. " missing") end
				if not (network[route[i + 1]] and network[route[i + 1]][route[i]]) then failure(route[i + 1] .. " -> " .. route[i] .. " missing") end
			end
		end
	end
	return network, report
end
function Controller.ValidateNetwork(map, config)
	local _, report = buildNetwork(map, config)
	return report
end
function Controller.new(model, map, config, options)
	assert(not owners[model], "Dinosaur already has a route controller")
	options = options or {}
	local root = assert(model.PrimaryPart, "Dinosaur requires a PrimaryPart")
	assert(root.Anchored, "Route prototype requires its anchored body root")
	local oldRuntime = model:FindFirstChild("MotionRuntime")
	assert(not oldRuntime or oldRuntime.Disabled, "Disable old MotionRuntime before installing route movement")
	local unrestricted=options.UnrestrictedRoam==true
 local network,report={}, {ok=true,errors={}}
 if not unrestricted then network,report=buildNetwork(map,config) end
	assert(report.ok, table.concat(report.errors, "; "))
	local home = options.HomeZone or model:GetAttribute("HuntingZone") or "A"
	local freeRoam = options.FreeRoam == true
	local homeRoutes = (config.Routes and config.Routes[home]) or {}
	assert(unrestricted or (freeRoam and network[home]) or #homeRoutes > 0, "No routes for home " .. tostring(home))
	local localForward = model:GetAttribute("ForwardInRoot")
	assert(typeof(localForward) == "Vector3" and flat(localForward).Magnitude > .1, "Missing dinosaur ForwardInRoot")
	local worldForward = flat(root.CFrame:VectorToWorldSpace(localForward)).Unit
	local heading = CFrame.lookAt(Vector3.zero, worldForward)
	local offset = heading:ToObjectSpace(root.CFrame.Rotation)
	local motors, footSum, footCount, footLow = {}, Vector3.zero, 0, math.huge
	for _, joint in model:GetDescendants() do
		if not joint:IsA("Motor6D") or joint.Name == "JawMotor" then continue end
		local rest = joint:GetAttribute("RestC0")
		assert(typeof(rest) == "CFrame", joint.Name .. " missing RestC0")
		local data = {joint = joint, rest = rest}
		local encoded = joint:GetAttribute("FootSamples")
		if encoded then
			data.foot = HttpService:JSONDecode(encoded)
			for _, sample in data.foot do
				local point = rest:PointToWorldSpace(Vector3.new(sample[1], sample[2], sample[3]))
				footSum += point; footCount += 1; footLow = math.min(footLow, point.Y)
			end
		end
		motors[joint.Name] = data
	end
	for _, name in {"LeftHip", "RightHip", "LeftShoulder", "RightShoulder", "Tail", "Neck"} do assert(motors[name], "Missing gait joint " .. name) end
	assert(footCount > 0 and motors.LeftHip.foot and motors.RightHip.foot, "Missing foot samples")
	-- A foot-based anchor follows the corridor center, even though the mesh root
	-- is offset about seven studs from the animal's actual support footprint.
	local supportLocal = Vector3.new(footSum.X / footCount, footLow, footSum.Z / footCount)
	local supportWorld = root.CFrame:PointToWorldSpace(supportLocal)
	local groundParams = RaycastParams.new()
	groundParams.FilterType = Enum.RaycastFilterType.Include
	groundParams.FilterDescendantsInstances = if unrestricted then {model} else {workspace.Terrain, map:WaitForChild("Paths"), map:WaitForChild("Zones")}
	groundParams.RespectCanCollide = true; groundParams.IgnoreWater = true
 if unrestricted then
  groundParams.FilterType=Enum.RaycastFilterType.Exclude
  groundParams.FilterDescendantsInstances={model,workspace:FindFirstChild("TrainingPets")}
  groundParams.IgnoreWater=false
 end
	local decorParams = RaycastParams.new()
	decorParams.FilterType = Enum.RaycastFilterType.Include
	decorParams.FilterDescendantsInstances = if unrestricted then {} else {map:WaitForChild("Decor")}
	decorParams.RespectCanCollide = true
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = if unrestricted then {} else {map.Decor}
	overlapParams.RespectCanCollide = true
 if unrestricted then
  local obstacleRoots={}
  for _,item in workspace:GetChildren() do
   if item~=model and not item:IsA("Terrain") and item.Name~="TrainingPets" then table.insert(obstacleRoots,item) end
  end
  decorParams.FilterDescendantsInstances=obstacleRoots
  overlapParams.FilterDescendantsInstances=obstacleRoots
 end
	local low, high = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	local anatomy = CFrame.lookAt(supportWorld, supportWorld + worldForward)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("CombatHitbox") ~= true then
			for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
				local p = anatomy:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size * Vector3.new(x, y, z) * .5))
				low, high = low:Min(p), high:Max(p)
			end end end
		end
	end
	local restSeconds = number(config.RestSeconds, 60, 0, 600)
	local self = setmetatable({Model = model, Root = root, Map = map, Config = config, HomeZone = home,
		_network = network, _motors = motors, _supportLocal = supportLocal, _headingOffset = offset,
		_position = flat(supportWorld), _groundY = supportWorld.Y, _yaw = math.atan2(worldForward.X, worldForward.Z), _up = Y,
		_groundParams = groundParams, _originalRoot = root.CFrame, _originalAttributes = {},
		_decorParams = decorParams, _overlapParams = overlapParams,
		_collisionSize = high - low + Vector3.new(2, if unrestricted then -2 else 1, 2), _collisionCenter = (high + low) * .5 + Vector3.new(0,if unrestricted then 1.5 else 0,0),
		_combatLeash = number(options.CombatLeashStuds or options.CombatLeash or config.CombatLeashStuds, 260, 20, 400),
		_campSafeRadius = number(options.CampSafeRadius or config.CampSafeRadius, 110, 50, 400),
		_combatSpeed = number(options.CombatSpeed, 16, 1, 24),
		_combatSlope = math.rad(number(options.CombatSlopeDegrees, 28, 5, 35)), _combatBlocked = false,
		_speed = 0, _phase = 0, _blend = 0, _nod = 0, _attributeElapsed = 0,
		_state = "Stopped", _currentZone = home, _targetZone = home, _restRemaining = 0,
		_routeIndex = number(options.InitialRouteIndex, 1, 1, math.max(1, #homeRoutes)),
		_reversed = options.InitialReverse == true, _fixedRouteIndex = options.FixedRouteIndex,
		_unrestrictedRoam=unrestricted,_roamRest=options.InitialRestSeconds or 2,_roamGeneration=0,
		_freeRoam = freeRoam, _previousZone = nil, _random = options.Random or Random.new(),
		_reverseEachCycle = options.ReverseEachCycle ~= false,
		_maxSpeed = number(options.Speed, 12, 1, 24), _acceleration = number(options.Acceleration, 6, 1, 30),
		_turnSpeed = math.rad(number(options.TurnSpeedDegrees, 65, 10, 180)),
		_initialRest = number(options.InitialRestSeconds, restSeconds, 0, 600),
		_homeRest = number(options.HomeRestSeconds, restSeconds, 0, 600),
		_rest = number(options.RestSeconds, restSeconds, 0, 600), _mainRest = number(options.MainRestSeconds, restSeconds, 0, 600),
		_autoConnect = options.AutoConnect ~= false, _running = false, _destroyed = false,
		_cycles = 0, _legs = 0, _travelled = 0, _groundMisses = 0, _visited = {home}}, Controller)
	self._routeIndex = math.floor(self._routeIndex)
	if self._fixedRouteIndex then self._routeIndex = math.floor(number(self._fixedRouteIndex, 1, 1, math.max(1, #homeRoutes))) end
	if freeRoam or options.SpawnPosition ~= nil then
		assert(freeRoam, "Random spawn position requires free-roam mode")
		local spawnPosition = options.SpawnPosition or config.position(config.zone(home))
		assert(finite(spawnPosition), "Random spawn position must be a finite Vector3")
		local zone = config.zone(home)
		assert(unrestricted or (flat(spawnPosition) - flat(config.position(zone))).Magnitude <= zone.width * .5,
			"Random spawn position must remain inside its home zone")
		self._position = flat(spawnPosition)
		local hit = self:_ground(self._position)
		assert(hit and hit.Normal.Y >= math.cos(math.rad(35)), "Random spawn position has no safe ground")
		self._groundY = hit.Position.Y
  local direction
  if unrestricted then local yaw=self._random:NextNumber(-math.pi,math.pi);direction=Vector3.new(math.sin(yaw),0,math.cos(yaw))
  else
		local exits = self._network[home]
		local destinations = {}
		for destination in exits do table.insert(destinations, destination) end
		table.sort(destinations)
		assert(#destinations > 0, "Free-roam spawn zone has no connected paths: " .. home)
		local nextZone = destinations[self._random:NextInteger(1, #destinations)]
		local nextPosition = flat(self.Config.position(self.Config.zone(nextZone)))
		direction = (nextPosition - self._position).Unit
  end
		self._yaw = math.atan2(direction.X, direction.Z)
		self:_place(0, hit, direction, 0)
	end
	for _, key in {"RouteEnabled", "RouteState", "RouteCurrentZone", "RouteTargetZone", "RouteHomeZone", "RouteIndex",
		"RouteReversed", "RouteCyclesCompleted", "RouteLegsCompleted", "RouteDistanceTravelled", "RouteSpeed",
		"RouteWalking", "RouteGroundMisses", "RouteRestRemaining", "RouteMotionMode", "RouteCombatBlocked",
		"HuntingZone", "MapRole", "PreviewWalking", "UnrestrictedRoam", "RoamDestination"} do self._originalAttributes[key] = {value = model:GetAttribute(key)} end
	model:SetAttribute("PreviewWalking", false)
	model:SetAttribute("MapRole", "HuntingPrototype_RoutePatrol")
	model:SetAttribute("RouteHomeZone", home)
	if model:GetAttribute("RouteEnabled") == nil then model:SetAttribute("RouteEnabled", true) end
	owners[model] = self
	self:_publish()
	return self
end
function Controller:_publish()
	local m = self.Model
 m:SetAttribute("UnrestrictedRoam",self._unrestrictedRoam==true)
 m:SetAttribute("RoamDestination",self._roamGoal)
	m:SetAttribute("RouteState", self._state); m:SetAttribute("RouteCurrentZone", self._currentZone)
	m:SetAttribute("RouteTargetZone", self._targetZone); m:SetAttribute("RouteIndex", self._routeIndex)
	m:SetAttribute("RouteReversed", self._reversed); m:SetAttribute("RouteCyclesCompleted", self._cycles)
	m:SetAttribute("RouteLegsCompleted", self._legs); m:SetAttribute("RouteDistanceTravelled", self._travelled)
	m:SetAttribute("RouteSpeed", self._speed); m:SetAttribute("RouteWalking", self._blend > .05)
	m:SetAttribute("RouteGroundMisses", self._groundMisses)
	m:SetAttribute("RouteRestRemaining", math.max(0, self._restRemaining))
	m:SetAttribute("RouteMotionMode", self._motionMode or "Patrol")
	m:SetAttribute("RouteCombatBlocked", self._combatBlocked)
	m:SetAttribute("HuntingZone", self._currentZone)
end
function Controller:GetSnapshot()
	return {State = self._state, CurrentZone = self._currentZone, TargetZone = self._targetZone,
		RouteIndex = self._routeIndex, Reversed = self._reversed, CompletedCycles = self._cycles,
		CompletedLegs = self._legs, VisitedZones = table.clone(self._visited), DistanceTravelled = self._travelled,
		GroundMisses = self._groundMisses, Speed = self._speed, RestRemaining = self._restRemaining,
		SupportPosition = self._position + Y * self._groundY, FootSupportLocal = self._supportLocal,
		MotionMode = self._motionMode or "Patrol", CombatBlocked = self._combatBlocked,
		UnrestrictedRoam=self._unrestrictedRoam==true,
		PatrolAnchor = self._combatSnapshot and self._combatSnapshot.anchor or nil,
		FacingDirection = Vector3.new(math.sin(self._yaw), 0, math.cos(self._yaw))}
end
function Controller:_ground(position)
 if self._unrestrictedRoam then
  local ceiling=math.max(self._groundY+120,self.Config.TerrainMax+100)
  return workspace:Raycast(Vector3.new(position.X,ceiling,position.Z),Vector3.new(0,-(ceiling-self.Config.TerrainMin+200),0),self._groundParams)
 end
	return workspace:Raycast(Vector3.new(position.X, self.Config.TerrainMax + 100, position.Z),
		Vector3.new(0, -(self.Config.TerrainMax - self.Config.TerrainMin + 200), 0), self._groundParams)
end
function Controller:_outsideCombatBounds(position)
 if self._unrestrictedRoam then return false end
	local camp = self.Config.position(self.Config.zone("Camp"))
	local offset = self.Config.WorldOffset or self.Map:GetAttribute("WorldOffset") or Vector3.zero
	local localPosition = position - offset
	return math.abs(localPosition.X) > (self.Config.MapWidth or self.Config.MapSize) * .5 - 36
		or math.abs(localPosition.Z) > (self.Config.MapDepth or self.Config.MapSize) * .5 - 36
		or (flat(position) - flat(camp)).Magnitude < self._campSafeRadius
end
function Controller:BeginCombat()
	if self._destroyed or not self._running or self._dead or self.Model:GetAttribute("RouteEnabled") == false then return false end
	if not self._combatSnapshot then
		self._combatSnapshot = {state = self._state, rest = self._restRemaining,
			anchor = self._position + Y * self._groundY}
		self._combatTrail = {self._combatSnapshot.anchor}
		self._combatTravel = 0
	elseif self._motionMode == "Returning" then
		-- Returning uses the existing trail backwards. Discard the already
		-- traversed tail before a new hit starts another chase from this point.
		while #self._combatTrail > self._returnIndex do table.remove(self._combatTrail) end
		table.insert(self._combatTrail, self._position + Y * self._groundY)
	end
	self._motionMode = "Combat"; self._combatGoal = nil; self._combatFace = nil
	self._combatBlocked = false; self._speed = 0; self._state = "Combat"
	self:_publish()
	return true
end
function Controller:SetCombatGoal(position, options)
	if self._motionMode ~= "Combat" or self._dead or not finite(position) then return false end
	if self:_outsideCombatBounds(position)
		or (not self._unrestrictedRoam and (flat(position) - flat(self._combatSnapshot.anchor)).Magnitude > self._combatLeash) then
		self._combatGoal = nil; self._speed = 0; self._combatBlocked = true
		return false
	end
	options = options or {}
	self._combatGoal = flat(position)
	self._combatStop = number(options.StopDistance, 18, 0, 40)
	self._combatGoalSpeed = number(options.Speed, self._combatSpeed, 1, 24)
	return true
end
function Controller:FaceCombat(position)
	if self._motionMode ~= "Combat" or not finite(position) then return false end
	self._combatFace = flat(position)
	return true
end
function Controller:_resumePatrol()
	local saved = self._combatSnapshot
	if not saved then return end
	self._state = saved.state; self._restRemaining = saved.rest; self._speed = 0
	self._motionMode = nil; self._combatSnapshot = nil; self._combatGoal = nil; self._combatFace = nil
	self._combatTrail = nil; self._returnIndex = nil; self._combatBlocked = false
	self:_publish()
end
function Controller:EndCombat()
	if not self._combatSnapshot or self._dead then return end
 if self._unrestrictedRoam then
  self._roamGeneration+=1;self._roamGoal=nil;self._roamPoints=nil;self._roamRest=self._random:NextNumber(2,5)
  self._combatSnapshot=nil;self._combatGoal=nil;self._combatFace=nil;self._combatTrail=nil;self._returnIndex=nil
  self._motionMode=nil;self._combatBlocked=false;self._speed=0;self._state="Resting";self:_publish();return
 end
	if self._motionMode == "Returning" then return end
	self._combatGoal = nil; self._combatFace = nil; self._speed = 0; self._combatBlocked = false
	self._motionMode = "Returning"; self._state = "ReturningToPatrol"
	self._returnIndex = #self._combatTrail
	if (self._position - flat(self._combatSnapshot.anchor)).Magnitude < .02 then self:_resumePatrol()
	else self:_publish() end
end
function Controller:SetDead(dead)
	if self._destroyed or self._dead == (dead == true) then return end
	self._dead = dead == true; self._speed = 0
	if self._dead then
		self._deadState = self._state; self._deadMotion = self._motionMode
		self._state = "Dead"; self._motionMode = "Dead"
	else
		self._state = self._deadState or "RestingHome"; self._motionMode = self._deadMotion
		self._deadState = nil; self._deadMotion = nil
		if self._combatSnapshot then self:EndCombat() end
	end
	self:_publish()
end
function Controller:_safeCombatGround(candidate, direction, dt)
	local distance = (candidate - self._position).Magnitude
	local hit = self:_ground(candidate)
	if not hit or hit.Material==Enum.Material.Water or hit.Normal.Y < math.cos(self._combatSlope)
		or math.abs(hit.Position.Y - self._groundY) > math.tan(self._combatSlope) * distance + .65 then return nil end
	local yaw = self._yaw + math.clamp(angleDelta(self._yaw, math.atan2(direction.X, direction.Z)), -self._turnSpeed * dt, self._turnSpeed * dt)
	local forward = Vector3.new(math.sin(yaw), 0, math.cos(yaw))
	local right = forward:Cross(Y)
	-- Both feet need nearby support, even when the central ray is still on a
	-- road lip. A full body sweep prevents clipping through trees and dividers.
	for _, offset in {right * 7, -right * 7, forward * 8, -forward * 8} do
		local footHit = self:_ground(candidate + offset)
		if not footHit or math.abs(footHit.Position.Y - hit.Position.Y) > math.tan(self._combatSlope) * offset.Magnitude + 1.4 then return nil end
	end
	local ground = candidate + Y * hit.Position.Y
	local frame = CFrame.lookAt(ground, ground + forward) * CFrame.new(self._collisionCenter)
	if #workspace:GetPartBoundsInBox(frame, self._collisionSize, self._overlapParams) > 0 then return nil end
	if distance > .001 then
		local oldGround = self._position + Y * self._groundY
		local start = CFrame.lookAt(oldGround, oldGround + forward) * CFrame.new(self._collisionCenter)
		if workspace:Blockcast(start, self._collisionSize, ground - oldGround, self._decorParams) then return nil end
	end
	return hit
end
function Controller:_combatStep(dt)
	local returning = self._motionMode == "Returning"
	local target = if returning then flat(self._combatTrail[self._returnIndex]) else self._combatGoal
	local direction = Vector3.new(math.sin(self._yaw), 0, math.cos(self._yaw))
	local distance = if target then (target - self._position).Magnitude else 0
	local stop = if returning then 0 else self._combatStop or 18
	if target and distance > .02 then direction = (target - self._position).Unit end
	if not returning and distance <= stop and self._combatFace and (self._combatFace - self._position).Magnitude > .02 then
		direction = (self._combatFace - self._position).Unit
	end
	local turning = math.abs(angleDelta(self._yaw, math.atan2(direction.X, direction.Z))) > math.rad(45)
	local desiredSpeed = if target and distance > stop and not turning then (if returning then self._maxSpeed * (if self.Model:GetAttribute("Weak") then .6 else 1) else self._combatGoalSpeed) else 0
	self._speed = if desiredSpeed == 0 then 0 else approach(self._speed, desiredSpeed, self._acceleration * dt)
	local step = math.min(math.max(0, distance - stop), self._speed * dt)
	local candidate = self._position + direction * step
	local blocked = self:_outsideCombatBounds(candidate)
	if not returning and not self._unrestrictedRoam and ((candidate - flat(self._combatSnapshot.anchor)).Magnitude > self._combatLeash
		or self._combatTravel + step > 320) then blocked = true end
	local hit = if not blocked then self:_safeCombatGround(candidate, direction, dt) else nil
	self._combatBlocked = hit == nil
	if hit then
		self._position = candidate
		if step > 0 and not returning then
			self._combatTravel += step
			local point = candidate + Y * hit.Position.Y
			if (point - self._combatTrail[#self._combatTrail]).Magnitude >= 2 then table.insert(self._combatTrail, point) end
		end
		self._state = if returning then "ReturningToPatrol" else "Combat"
		local bob = self:_gait(dt, step > 0)
		self:_place(dt, hit, direction, bob)
	else
		self._speed = 0
		self._state = if returning then "ReturnBlocked" else "CombatBlocked"
		local stationary = self:_ground(self._position)
		local bob = self:_gait(dt, false)
		if stationary then self:_place(dt, stationary, Vector3.new(math.sin(self._yaw), 0, math.cos(self._yaw)), bob) end
	end
	if returning and (self._position - target).Magnitude < .02 then
		if self._returnIndex > 1 then self._returnIndex -= 1
		else self:_resumePatrol() end
	end
end
-- This mode samples walkable world space; it never selects an authored route.
function Controller:_chooseRoamGoal()
 self._roamGeneration=(self._roamGeneration or 0)+1
 local generation=self._roamGeneration
 self._roamPoints=nil;self._roamIndex=nil;self._roamAge=0;self._roamBlocked=0
 self._roamGoal=nil
 for _=1,16 do
  local angle=self._random:NextNumber(-math.pi,math.pi)
  local candidate=self._position+Vector3.new(math.sin(angle),0,math.cos(angle))*self._random:NextNumber(40,150)
  local hit=self:_ground(candidate)
  if hit and hit.Material~=Enum.Material.Water and hit.Normal.Y>=math.cos(self._combatSlope) then
   self._roamGoal=hit.Position;break
  end
 end
 if not self._roamGoal then self._roamRest=1;return end
 self._targetZone="Free";self._state="Wandering"
 local start=self._position+Y*(self._groundY+.5)
 local goal=self._roamGoal
 local destination=goal+Y*.5
 task.spawn(function()
  local path
  local ok=pcall(function()
   path=PathfindingService:CreatePath({AgentRadius=math.clamp(math.min(self._collisionSize.X,self._collisionSize.Z)*.25,4,14),
    AgentHeight=math.clamp(self._collisionSize.Y,8,60),AgentCanJump=false,AgentCanClimb=false,WaypointSpacing=12,Costs={Water=math.huge}})
   path:ComputeAsync(start,destination)
  end)
  if not self._destroyed and self._roamGeneration==generation and self._roamGoal==goal
   and ok and path.Status==Enum.PathStatus.Success then
   local points={}
   for _,waypoint in path:GetWaypoints() do
    if waypoint.Action==Enum.PathWaypointAction.Jump then points={};break end
    table.insert(points,waypoint.Position)
   end
   if #points>=2 then self._roamPoints=points;self._roamIndex=2 end
  end
  if path then path:Destroy() end
 end)
end
function Controller:_freeWanderStep(dt,elapsed)
 if (self._roamRest or 0)>0 then
  self._roamRest=math.max(0,self._roamRest-elapsed);self._state="Resting";self._speed=0
  local hit=self:_ground(self._position)
  local bob=self:_gait(dt,false)
  if hit then self:_place(dt,hit,Vector3.new(math.sin(self._yaw),0,math.cos(self._yaw)),bob) end
  return
 end
 if not self._roamGoal then self:_chooseRoamGoal();return end
 self._roamAge=(self._roamAge or 0)+elapsed
 local target=flat(if self._roamPoints then self._roamPoints[self._roamIndex] else self._roamGoal)
 local delta=target-self._position
 if delta.Magnitude<7 then
  if self._roamPoints and self._roamIndex<#self._roamPoints then self._roamIndex+=1
  else
   self._legs+=1;self._roamGoal=nil;self._roamRest=self._random:NextNumber(2,8)
   local nearest,distance=nil,math.huge
   for _,zone in self.Config.Zones do
    local gap=(flat(self.Config.position(zone))-self._position).Magnitude
    if gap<distance then nearest=zone.id;distance=gap end
   end
   if nearest then self._currentZone=nearest;table.insert(self._visited,nearest);if #self._visited>40 then table.remove(self._visited,1) end end
  end
  return
 end
 local desired=delta.Unit
 local turning=math.abs(angleDelta(self._yaw,math.atan2(desired.X,desired.Z)))>math.rad(45)
 self._speed=if turning then 0 else approach(self._speed,self._maxSpeed*(if self.Model:GetAttribute("Weak") then .6 else 1),self._acceleration*dt)
 local step=math.min(delta.Magnitude,self._speed*dt)
 local hit,candidate,direction
 for _,degrees in {0,25,-25,50,-50,85,-85,120,-120} do
  local yaw=math.atan2(desired.X,desired.Z)+math.rad(degrees)
  local testDirection=Vector3.new(math.sin(yaw),0,math.cos(yaw))
  local testPosition=self._position+testDirection*step
  local ground=self:_safeCombatGround(testPosition,testDirection,dt)
  if ground then hit=ground;candidate=testPosition;direction=testDirection;break end
 end
 if hit then
  self._position=candidate;self._travelled+=step;self._roamBlocked=0;self._state=if turning then "Turning" else "Wandering"
  local bob=self:_gait(dt,step>.01);self:_place(dt,hit,direction,bob)
 else
  self._speed=0;self._groundMisses+=1;self._roamBlocked=(self._roamBlocked or 0)+elapsed;self._state="FindingPath"
  local stationary=self:_ground(self._position);local bob=self:_gait(dt,false)
  if stationary then self:_place(dt,stationary,desired,bob) end
 end
 if self._roamBlocked>1.2 or self._roamAge>28 then self._roamGoal=nil;self._roamRest=self._random:NextNumber(.3,1.2) end
end

function Controller:_beginCycle()
	local source = self.Config.Routes[self.HomeZone][self._routeIndex]
	self._route = if self._reversed then reverse(source) else table.clone(source)
	self._legIndex = 1
	self:_beginLeg()
end
function Controller:_beginWanderLeg()
	local exits = self._network[self._currentZone]
	local destinations = {}
	for destination in exits do
		local zone = self.Config.zone(destination)
		if zone.kind ~= "Camp" and destination ~= self._previousZone then
			table.insert(destinations, destination)
		end
	end
	table.sort(destinations)
	if #destinations == 0 then
		for destination in exits do
			if self.Config.zone(destination).kind ~= "Camp" then table.insert(destinations, destination) end
		end
		table.sort(destinations)
	end
	assert(#destinations > 0, "Free-roam zone has no safe connected paths: " .. self._currentZone)
	local nextZone = destinations[self._random:NextInteger(1, #destinations)]
	self._points = self._network[self._currentZone][nextZone]
	self._sampleIndex = 2
	self._targetZone = nextZone
	self._state = "Walking"
	self:_publish()
end
function Controller:_beginLeg()
	local a, b = self._route[self._legIndex], self._route[self._legIndex + 1]
	self._points = self._network[a][b]
	self._sampleIndex = 2
	self._targetZone = b; self._state = "Walking"
	self:_publish()
end
function Controller:_arrive()
	self._previousZone = self._currentZone
	self._currentZone = self._targetZone; self._legs += 1; self._speed = 0
	table.insert(self._visited, self._currentZone)
	if #self._visited > 40 then table.remove(self._visited, 1) end
	if self._freeRoam then
		self._state = "Resting"; self._restRemaining = self._rest
	elseif self._legIndex == #self._route - 1 then
		self._cycles += 1; self._state = "RestingHome"; self._restRemaining = self._homeRest
	else
		local zone = self.Config.zone(self._currentZone)
		self._state = "Resting"; self._restRemaining = if zone.kind == "Rest" then self._rest else self._mainRest
	end
	self:_publish()
end
local function footOffset(data, angle, lift, bob)
	local restMinimum, minimum = math.huge, math.huge
	for _, point in data.foot do
		restMinimum = math.min(restMinimum, point[2])
		minimum = math.min(minimum, point[2] * math.cos(angle) - point[3] * math.sin(angle))
	end
	return restMinimum - minimum + lift - bob
end
function Controller:_gait(dt, moving)
	local target = if moving then math.clamp(self._speed / self._maxSpeed, 0, 1) else 0
	self._blend += (target - self._blend) * math.min(1, dt * 7)
	if self._blend < .0001 then self._blend = 0 end
	local blend = self._blend
	self._phase += dt * math.pi * 2 * .66 * math.clamp(self._maxSpeed / 6, .5, 1.5) * blend
	local phase = self._phase
	local bob = .18 * (1 - math.cos(phase * 2)) * .5 * blend
	for name, sign in {LeftHip = 1, RightHip = -1} do
		local data = self._motors[name]
		local angle = math.sin(phase) * sign * math.rad(11) * blend * (if self.Model:GetAttribute("Weak") and name == "LeftHip" then .5 else 1)
		local lift = math.max(0, math.cos(phase) * sign) * .8 * blend
		data.joint.C0 = data.rest * CFrame.new(0, footOffset(data, angle, lift, bob), 0) * CFrame.Angles(angle, 0, 0)
	end
	for name, sign in {LeftShoulder = -1, RightShoulder = 1} do
		local data = self._motors[name]
		data.joint.C0 = data.rest * CFrame.Angles(math.sin(phase) * sign * .065 * blend, 0, 0)
	end
	self._motors.Tail.joint.C0 = self._motors.Tail.rest * CFrame.Angles(0, math.sin(phase - .4) * .035 * blend, 0)
	local bite = self.Model:GetAttribute("BitePhase")
	local nod = if self.Model:GetAttribute("Trapped") then -math.rad(14) elseif bite == "Closing" then -math.rad(5) elseif bite == "Opening" or bite == "Holding" then math.rad(1.5) else 0
	self._nod += (nod - self._nod) * math.min(1, dt * 15)
	self._motors.Neck.joint.C0 = self._motors.Neck.rest * CFrame.Angles(self._nod + math.sin(phase * 2) * .012 * blend, 0, 0)
	return bob
end
function Controller:_place(dt, hit, direction, bob)
	self._yaw += math.clamp(angleDelta(self._yaw, math.atan2(direction.X, direction.Z)), -self._turnSpeed * dt, self._turnSpeed * dt)
	-- Ground normals come only from authored roads/clearings or Terrain. Smooth
	-- the pitch/roll at road joins without allowing a steep wall to flip the rig.
	local normal = if hit.Normal.Y >= .85 then hit.Normal else Y
	self._up = self._up:Lerp(normal, math.min(1, dt * 7)).Unit
	local forward = Vector3.new(math.sin(self._yaw), 0, math.cos(self._yaw))
	forward = (forward - self._up * forward:Dot(self._up)).Unit
	local rotation = CFrame.lookAt(Vector3.zero, forward, self._up) * self._headingOffset
	local ground = Vector3.new(self._position.X, hit.Position.Y, self._position.Z)
	self._groundY = hit.Position.Y
	local position = ground - rotation:VectorToWorldSpace(self._supportLocal) + self._up * bob
	self.Root.CFrame = CFrame.new(position) * rotation
end
function Controller:Step(dt)
	if not self._running or self._destroyed then return end
	if not self.Model.Parent or not self.Root.Parent then self:Stop(); return end
	local elapsed = number(dt, 0, 0, 60)
	dt = math.min(elapsed, .12)
	if dt <= 0 then return end
	local enabled = self.Model:GetAttribute("RouteEnabled") ~= false
	if self._dead then
		self._speed = 0; self._state = "Dead"
		local hit = self:_ground(self._position)
		local bob = self:_gait(dt, false)
		if hit then self:_place(dt, hit, Vector3.new(math.sin(self._yaw), 0, math.cos(self._yaw)), bob) end
	elseif not enabled then
		self._speed = 0
		local bob = self:_gait(dt, false)
		local hit = self:_ground(self._position)
		if hit then self:_place(dt, hit, Vector3.new(math.sin(self._yaw), 0, math.cos(self._yaw)), bob) end
		self._pausedState = self._pausedState or self._state; self._state = "Paused"
	else
		if self._pausedState then self._state = self._pausedState; self._pausedState = nil end
		if self._motionMode == "Combat" or self._motionMode == "Returning" then
			self:_combatStep(dt)
  elseif self._unrestrictedRoam then self:_freeWanderStep(dt,elapsed)
		else
		local walking = self._state == "Walking" or self._state == "Turning" or self._state == "GroundBlocked"
		if not walking then
			self._restRemaining = math.max(0, self._restRemaining - elapsed)
			if self._restRemaining <= 0 then
				if self._freeRoam then self:_beginWanderLeg()
				elseif not self._route then self:_beginCycle()
				elseif self._state == "RestingHome" then
					if not self._fixedRouteIndex then self._routeIndex = self._routeIndex % #self.Config.Routes[self.HomeZone] + 1 end
					if self._reverseEachCycle then self._reversed = not self._reversed end
					self:_beginCycle()
				else self._legIndex += 1; self:_beginLeg() end
			end
			local bob = self:_gait(dt, false)
			local hit = self:_ground(self._position)
			if hit then self:_place(dt, hit, Vector3.new(math.sin(self._yaw), 0, math.cos(self._yaw)), bob) end
		else
			local target = flat(self._points[self._sampleIndex])
			local delta = target - self._position
			local distance = delta.Magnitude
			if distance < .02 then
				if self._sampleIndex < #self._points then self._sampleIndex += 1 else self:_arrive() end
			else
				local remaining = distance
				for i = self._sampleIndex, #self._points - 1 do remaining += (flat(self._points[i + 1]) - flat(self._points[i])).Magnitude end
				local desiredSpeed = math.min(self._maxSpeed * (if self.Model:GetAttribute("Weak") then .6 else 1), math.sqrt(2 * self._acceleration * remaining))
				local turning = math.abs(angleDelta(self._yaw, math.atan2(delta.X, delta.Z))) > math.rad(45)
				-- Turn toward a newly selected road before advancing. This avoids
				-- walking backwards out of a rest stop when reversing an itinerary.
				self._speed = if turning then 0 else approach(self._speed, desiredSpeed, self._acceleration * dt)
				local step = if turning then 0 else math.min(distance, self._speed * dt)
				local candidate = self._position + delta.Unit * step
				local hit = self:_ground(candidate)
				if not hit then
					self._state = "GroundBlocked"; self._speed = 0; self._groundMisses += 1
					self:_gait(dt, false)
				else
					self._state = if turning then "Turning" else "Walking"; self._position = candidate; self._travelled += step
					local bob = self:_gait(dt, not turning)
					self:_place(dt, hit, delta.Unit, bob)
					if step >= distance - .001 then
						if self._sampleIndex < #self._points then self._sampleIndex += 1 else self:_arrive() end
					end
				end
			end
		end
		end
	end
	self._attributeElapsed += elapsed
	if self._attributeElapsed >= .2 then self._attributeElapsed = 0; self:_publish() end
end
function Controller:Start()
	assert(not self._destroyed, "Controller destroyed")
	if self._running then return self end
	self._running = true
	if self._stoppedState then self._state = self._stoppedState; self._stoppedState = nil
	elseif self._state == "Stopped" then self._state = "RestingHome"; self._restRemaining = self._initialRest end
	if self._autoConnect then self._connection = RunService.Heartbeat:Connect(function(dt) self:Step(dt) end) end
	self:_publish(); return self
end
function Controller:Stop()
	if self._connection then self._connection:Disconnect(); self._connection = nil end
	if self._state ~= "Stopped" then self._stoppedState = self._state end
	self._running = false; self._speed = 0; self._state = "Stopped"; self._blend = 0
	for _, data in self._motors do data.joint.C0 = data.rest end
	self:_publish()
end
function Controller:Destroy(restore)
	if self._destroyed then return end
	self:Stop(); self._destroyed = true; owners[self.Model] = nil
	if restore then
		self.Root.CFrame = self._originalRoot
		for key, original in self._originalAttributes do self.Model:SetAttribute(key, original.value) end
	end
end
return Controller
