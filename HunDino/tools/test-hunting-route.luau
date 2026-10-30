-- Studio integration test: isolated clone, manual simulation, real map ground.
-- Run with execute_luau in Edit or Server after installing DinosaurRouteController.
-- Never changes the live dinosaur, map, Lighting, or permanent script states.
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local root = assert(workspace:FindFirstChild("HuntingRainforest"), "Map missing")
local source = assert(workspace:FindFirstChild("Dinosaur01_TRex_Visual"), "Prototype missing")
local module = game:GetService("ServerScriptService"):FindFirstChild("DinosaurRouteController", true)
	or game:GetService("ServerStorage"):FindFirstChild("DinosaurRouteController", true)
assert(module and module:IsA("ModuleScript"), "Install DinosaurRouteController first")
local Controller = require(module)
local config = require(ReplicatedStorage:WaitForChild("HuntingMapConfig"))
local worldOffset = config.WorldOffset or root:GetAttribute("WorldOffset") or Vector3.zero
local report = {ok = false, version = "HuntingRouteTest.3", cases = {}, failures = {},
	checks = 0, groundQueries = 0, footprintQueries = 0}
local function check(condition, message)
	report.checks += 1
	if not condition then table.insert(report.failures, message) end
	return condition
end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function finite(v)
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z
		and math.abs(v.X) < 1e6 and math.abs(v.Y) < 1e6 and math.abs(v.Z) < 1e6
end
local function close(a, b) return (a.Position - b.Position).Magnitude < 0.001 and a.LookVector:Dot(b.LookVector) > 0.99999 end
local function numbers(t)
	local result = {}
	for _, value in t do table.insert(result, value) end
	return table.concat(result, " → ")
end

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Include
groundParams.FilterDescendantsInstances = {workspace.Terrain, root.Paths, root.Zones}
groundParams.RespectCanCollide = true
groundParams.IgnoreWater = true
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include
overlapParams.FilterDescendantsInstances = {root.Decor}
overlapParams.RespectCanCollide = true
overlapParams.MaxParts = 0

-- Conservatively bound all part corners in anatomical heading, not the body's
-- authored mesh axes. This includes the tail and feathers at tight bends.
local function geometry(model)
	local body = model.PrimaryPart
	local forward = flat(body.CFrame:VectorToWorldSpace(model:GetAttribute("ForwardInRoot"))).Unit
	local heading = CFrame.lookAt(body.Position, body.Position + forward)
	local low = Vector3.new(math.huge, math.huge, math.huge)
	local high = -low
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("CombatHitbox") ~= true then
			for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
				local p = heading:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size * Vector3.new(x, y, z) * 0.5))
				low, high = low:Min(p), high:Max(p)
			end end end
		end
	end
	local sum, count, minY = Vector3.zero, 0, math.huge
	for _, name in {"LeftHip", "RightHip"} do
		local motor = assert(model:FindFirstChild(name, true), "Hip missing")
		local rest = motor:GetAttribute("RestC0")
		for _, point in HttpService:JSONDecode(motor:GetAttribute("FootSamples")) do
			local p = (body.CFrame * rest):PointToWorldSpace(Vector3.new(point[1], point[2], point[3]))
			sum += p; count += 1; minY = math.min(minY, p.Y)
		end
	end
	local support = Vector3.new(sum.X / count, minY, sum.Z / count)
	return {size = high - low, center = (high + low) * 0.5,
		supportLocal = body.CFrame:PointToObjectSpace(support)}
end

local originalFrame = source.PrimaryPart.CFrame
local running = game:GetService("RunService"):IsRunning()
local originalAttributes = source:GetAttributes()
local originalScripts = {}
for _, child in source:GetDescendants() do
	if child:IsA("BaseScript") then originalScripts[child] = child.Enabled end
end
local folder = Instance.new("Folder")
folder.Name = "HuntingRouteTest_" .. HttpService:GenerateGUID(false)
folder.Parent = workspace
local activeController
local clone

local success, failure = xpcall(function()
	local network = Controller.ValidateNetwork(root, config)
	report.network = network
	check(network.ok == true, "Actual map network failed route validation")
	if not network.ok then return end
	local expectedAll = {A=true, B=true, C=true, R1=true, R2=true, R3=true, R4=true, R5=true}
	local allVisited = {}
	for routeIndex = 1, #config.Routes.A do
		for _, reversed in {false, true} do
			clone = source:Clone()
			clone.Name = "TestPrototype"
			clone:SetAttribute("RouteEnabled", true)
			for _, child in clone:GetDescendants() do
				if child:IsA("BaseScript") then child.Enabled = false end
				if child:IsA("BasePart") then child.Transparency = 1; child.CanCollide = false; child.CanTouch = false end
			end
			clone.Parent = folder
			local shape = geometry(clone)
			local body = clone.PrimaryPart
			local support = body.CFrame:PointToWorldSpace(shape.supportLocal)
			local home = config.position(config.zone("A"))
			local homeGround = assert(workspace:Raycast(home + Vector3.new(0, 120, 0), Vector3.new(0, -240, 0), groundParams), "No ground at A")
			clone:PivotTo(clone:GetPivot() + Vector3.new(home.X - support.X, homeGround.Position.Y - support.Y, home.Z - support.Z))
			local hip = clone:FindFirstChild("LeftHip", true)
			local hipRest = hip:GetAttribute("RestC0")
			local item = {route = routeIndex, reversed = reversed, visited = {"A"},
				steps = 0, maxGaitRadians = 0, minimumFacingDot = 1, groundMisses = 0,
				maxSupportGroundError = 0, obstructionSamples = 0, obstacles = {}}
			table.insert(report.cases, item)
			local options = {HomeZone = "A", AutoConnect = false, Speed = 12, InitialRestSeconds = 0.5,
				HomeRestSeconds = 2, RestSeconds = 0.2, MainRestSeconds = 0.2,
				InitialRouteIndex = routeIndex, InitialReverse = reversed}
			activeController = Controller.new(clone, root, config, options)
			shape.supportLocal = activeController:GetSnapshot().FootSupportLocal
			activeController:Start()
			activeController:Step(0.01) -- Settle the support onto the authored ground.
			local initial = body.CFrame
			local initialSnapshot = activeController:GetSnapshot()
			local initialSupport = body.CFrame:PointToWorldSpace(initialSnapshot.FootSupportLocal)
			activeController:Step(0.1)
			activeController:Step(0.1)
			local restingSnapshot = activeController:GetSnapshot()
			local restingSupport = body.CFrame:PointToWorldSpace(restingSnapshot.FootSupportLocal)
			item.initialRest = {rootShift = (body.Position - initial.Position).Magnitude,
				supportShift = (restingSupport - initialSupport).Magnitude,
				travelDelta = restingSnapshot.DistanceTravelled - initialSnapshot.DistanceTravelled,
				speed = restingSnapshot.Speed, state = restingSnapshot.State}
			-- Ground-normal interpolation rotates the mesh around its stationary
			-- foot anchor. The authored root is 23 studs above that anchor, so even
			-- voxel normal noise can shift it by ~0.02 studs while standing still.
			check(item.initialRest.supportShift < 0.005
				and (restingSnapshot.SupportPosition - initialSnapshot.SupportPosition).Magnitude < 0.001,
				"Route "..routeIndex..": foot anchor moved during initial home rest")
			check(math.abs(item.initialRest.travelDelta) < 0.000001 and restingSnapshot.Speed == 0
				and restingSnapshot.State == "RestingHome" and restingSnapshot.CurrentZone == "A",
				"Route "..routeIndex..": patrol advanced during initial home rest")
			check(item.initialRest.rootShift < 0.1
				and flat(initial.LookVector).Unit:Dot(flat(body.CFrame.LookVector).Unit) > 0.99999,
				"Route "..routeIndex..": initial root pose changed beyond normal settling")
			check(clone:GetAttribute("RouteWalking") ~= true, "Route "..routeIndex..": gait running during initial rest")
			local previous = activeController:GetSnapshot().SupportPosition
			local previousZone = "A"
			local obstacles = {}
			-- H2 covers 4,000 x 4,500 studs; allow the longest full patrol to finish.
			for step = 1, 30000 do
				activeController:Step(0.1)
				item.steps = step
				local snapshot = activeController:GetSnapshot()
				local p = body.Position
				local localPosition = p - worldOffset
				if not finite(p) or math.abs(localPosition.X) > (config.MapWidth or config.MapSize) / 2 or math.abs(localPosition.Z) > (config.MapDepth or config.MapSize) / 2 or p.Y < config.TerrainMin then
					error("Nonfinite or out-of-bounds route position " .. tostring(p))
				end
				local zone = snapshot.CurrentZone
				if zone and zone ~= previousZone then
					table.insert(item.visited, zone); previousZone = zone
				end
				if zone then allVisited[zone] = true end
				local delta = flat(snapshot.SupportPosition - previous)
				if snapshot.State == "Walking" and delta.Magnitude > 0.15 then
					local forward = flat(body.CFrame:VectorToWorldSpace(clone:GetAttribute("ForwardInRoot"))).Unit
					item.minimumFacingDot = math.min(item.minimumFacingDot, forward:Dot(delta.Unit))
				end
				previous = snapshot.SupportPosition
				local _, gaitAngle = hipRest:ToObjectSpace(hip.C0):ToAxisAngle()
				item.maxGaitRadians = math.max(item.maxGaitRadians, math.abs(gaitAngle))
				if step % 10 == 0 then
					local support = body.CFrame:PointToWorldSpace(shape.supportLocal)
					local hit = workspace:Raycast(support + Vector3.new(0, 100, 0), Vector3.new(0, -220, 0), groundParams)
					report.groundQueries += 1
					if not hit then item.groundMisses += 1 else
						item.maxSupportGroundError = math.max(item.maxSupportGroundError, math.abs(support.Y - hit.Position.Y))
					end
					local forward = flat(body.CFrame:VectorToWorldSpace(clone:GetAttribute("ForwardInRoot"))).Unit
					local heading = CFrame.lookAt(p, p + forward)
					local bounds = heading * CFrame.new(shape.center + Vector3.new(0, 0.6, 0))
					local found = workspace:GetPartBoundsInBox(bounds, shape.size + Vector3.new(0, 1.2, 0), overlapParams)
					report.footprintQueries += 1
					if #found > 0 then item.obstructionSamples += 1 end
					for _, part in found do obstacles[part:GetFullName()] = true end
				end
				if snapshot.CompletedCycles >= 1 then
					item.snapshot = snapshot
					check(snapshot.CurrentZone == "A", "Route "..routeIndex..": completed away from home A")
					local resting = body.CFrame
					for _ = 1, 5 do activeController:Step(0.1) end
					check(flat(resting.Position - body.Position).Magnitude < 0.01 and math.abs(resting.Y - body.Position.Y) < 0.25,
						"Route "..routeIndex..": home rest drifted beyond the gait settling bob")
					check(clone:GetAttribute("RouteWalking") ~= true, "Route "..routeIndex..": gait did not settle at home")
					break
				end
				if step % 200 == 0 then task.wait() end
			end
			local expected = table.clone(config.Routes.A[routeIndex])
			if reversed then local r = {}; for i = #expected, 1, -1 do table.insert(r, expected[i]) end; expected = r end
			check(item.snapshot ~= nil, "Route "..routeIndex..": timed out before a full cycle")
			check(numbers(item.visited) == numbers(expected), "Route "..routeIndex..": expected "..numbers(expected)..", got "..numbers(item.visited))
			check(item.maxGaitRadians > math.rad(5), "Route "..routeIndex..": feet did not animate")
			check(item.minimumFacingDot >= 0.7, "Route "..routeIndex..": moved sideways/backward; minimum dot="..item.minimumFacingDot)
			check(item.groundMisses == 0, "Route "..routeIndex..": missing physical ground")
			check(item.maxSupportGroundError < 3, "Route "..routeIndex..": support drifted from ground by "..item.maxSupportGroundError)
			check(item.obstructionSamples == 0, "Route "..routeIndex..": full dinosaur envelope intersects colliding Decor")
			if item.snapshot then
				check(item.snapshot.GroundMisses == 0, "Route "..routeIndex..": controller reported ground misses")
				check(item.snapshot.DistanceTravelled > 2000, "Route "..routeIndex..": insufficient route movement")
			end
			for name in obstacles do table.insert(item.obstacles, name) end
			table.sort(item.obstacles)
			activeController:Destroy(false); activeController = nil
			clone:Destroy(); clone = nil
			task.wait()
		end
	end
	for id in expectedAll do check(allVisited[id] == true, "A routes never visited "..id) end

	local habitats = {}
	for _, zone in config.Zones do
		if zone.kind == "Main" or zone.kind == "Rest" then table.insert(habitats, zone) end
	end
	local random = Random.new(741)
	local spawnZone = habitats[random:NextInteger(1, #habitats)]
	clone = source:Clone()
	clone.Name = "TestFreeRoamPrototype"
	clone:SetAttribute("RouteEnabled", true)
	for _, child in clone:GetDescendants() do
		if child:IsA("BaseScript") then child.Enabled = false end
		if child:IsA("BasePart") then child.Transparency = 1; child.CanCollide = false; child.CanTouch = false end
	end
	clone.Parent = folder
	local roam = {home = spawnZone.id, visited = {}, steps = 0}
	table.insert(report.cases, roam)
	activeController = Controller.new(clone, root, config, {
		HomeZone = spawnZone.id, FreeRoam = true, SpawnPosition = config.position(spawnZone),
		Random = random, AutoConnect = false, Speed = 24, InitialRestSeconds = 0.1, RestSeconds = 0.1,
	})
	activeController:Start()
	local distinct = {}
	for step = 1, 10000 do
		activeController:Step(0.1)
		roam.steps = step
		local snapshot = activeController:GetSnapshot()
		distinct[snapshot.CurrentZone] = true
		if snapshot.TargetZone then distinct[snapshot.TargetZone] = true end
		if snapshot.CompletedLegs >= 2 and snapshot.CurrentZone ~= spawnZone.id then
			roam.snapshot = snapshot
			break
		end
		if step % 200 == 0 then task.wait() end
	end
	for zone in distinct do table.insert(roam.visited, zone) end
	table.sort(roam.visited)
	check(roam.snapshot ~= nil, "Free roam: did not reach two connected zones from "..spawnZone.id)
	check(not distinct.Camp, "Free roam: entered the human-only Camp zone")
	check(roam.snapshot and roam.snapshot.GroundMisses == 0, "Free roam: lost safe ground")
	check(roam.snapshot and roam.snapshot.DistanceTravelled > 0, "Free roam: did not move")
	activeController:Destroy(false); activeController = nil
	clone:Destroy(); clone = nil
end, debug.traceback)

-- Cleanup runs even if construction or a simulation assertion raises an error.
if activeController then pcall(function() activeController:Destroy(false) end) end
if clone then clone:Destroy() end
folder:Destroy()
if not success then table.insert(report.failures, failure) end
if not running then check(close(source.PrimaryPart.CFrame, originalFrame), "Live dinosaur was moved by the isolated test") end
for child, enabled in originalScripts do check(child.Enabled == enabled, "Live script state changed: "..child.Name) end
for key, value in originalAttributes do
	-- A live play session legitimately advances the original route status.
	if not running or (not key:match("^Route") and key ~= "PreviewWalking" and key ~= "HuntingZone" and key ~= "BitePhase" and key ~= "JawOpenDegrees") then
		check(source:GetAttribute(key) == value, "Live dinosaur attribute changed: "..key)
	end
end
report.ok = #report.failures == 0
return report
