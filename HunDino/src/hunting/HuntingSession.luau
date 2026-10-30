-- Server-owned visits to the connected forest. Lighting is applied per client.
local Session = {}
Session.__index = Session

local ATTRIBUTES = {"HuntStartedAt", "HuntStartServerTime", "HuntEntryClockHours", "HuntTimeScale", "HuntDuration", "HuntRemainingSeconds", "HuntClockStoppedAt"}

local function wallTime()
	return DateTime.now().UnixTimestampMillis / 1000
end

function Session:RestartClock(player, duration)
	local visit = self.Players[player]; if not visit then return end
	local started = wallTime()
	visit.StartedAt, visit.Duration, visit.FrozenAt = started, duration or self.Duration, nil
	player:SetAttribute("HuntStartedAt", started)
	player:SetAttribute("HuntStartServerTime", workspace:GetServerTimeNow())
	player:SetAttribute("HuntEntryClockHours", ((started + (self.Config.TimezoneOffsetMinutes or 420) * 60) % 86400) / 3600)
	player:SetAttribute("HuntDuration", visit.Duration); player:SetAttribute("HuntRemainingSeconds", visit.Duration)
	player:SetAttribute("HuntClockStoppedAt", nil)
end

function Session:FreezeClock(player)
	local visit = self.Players[player]; if not visit or visit.FrozenAt then return end
	visit.FrozenAt = wallTime()
	player:SetAttribute("HuntClockStoppedAt", workspace:GetServerTimeNow())
end

function Session.new(forest, config, dinosaur, routeController)
	local self=setmetatable({
		Forest = forest, Config = config, Dinosaur = dinosaur, Routes = routeController,
		Players = {}, Count = 0, Patrol = nil, Random = Random.new(),
		Duration = math.max(30, config.HuntDurationSeconds or 40 * 60),
	}, Session)
 self:_ensurePatrol()
 return self
end

function Session:_ensurePatrol()
	if not self.Patrol then
		local habitats = {}
		for _, zone in self.Config.Zones do
			if zone.kind == "Main" or zone.kind == "Rest" then
				table.insert(habitats, zone)
			end
		end
		assert(#habitats > 0, "Hunting map has no safe dinosaur spawn zones")
		local spawnZone = habitats[self.Random:NextInteger(1, #habitats)]
		self.Patrol = self.Routes.new(self.Dinosaur, self.Forest, self.Config, {
			HomeZone = spawnZone.id,
			FreeRoam = true,
   UnrestrictedRoam=true,
			SpawnPosition = self.Config.position(spawnZone),
			Random = self.Random,
			InitialRestSeconds = self.Random:NextNumber(2, 8),
			RestSeconds = self.Random:NextNumber(6, 14),
		})
		self.Patrol:Start()
		if self.Combat then self.Combat:Reset() end
	end
end

function Session:Enter(player)
	-- A Studio zone jump keeps the current visit and its original entry clock.
	if self.Players[player] then return end
 self:_ensurePatrol()
 if self.Count==0 and self.Combat and (self.Dinosaur:GetAttribute("DinosaurDead")==true or self.Dinosaur:GetAttribute("Captured")==true) then self.Combat:Reset() end
	local started = wallTime()
	self.Players[player] = {StartedAt = started, Duration = self.Duration}
	self.Count += 1
	player:SetAttribute("HuntStartedAt", started)
	player:SetAttribute("HuntStartServerTime", workspace:GetServerTimeNow())
	player:SetAttribute("HuntEntryClockHours", ((started + (self.Config.TimezoneOffsetMinutes or 420) * 60) % 86400) / 3600)
	player:SetAttribute("HuntTimeScale", self.Config.TimeScale or 30)
	player:SetAttribute("HuntDuration", self.Duration)
	player:SetAttribute("HuntRemainingSeconds", self.Duration)
	player:SetAttribute("InHunting", true)
	self.Forest:SetAttribute("ActiveHunters", self.Count)
end

function Session:Exit(player)
	if self.Combat then self.Combat:PlayerExited(player) end
	player:SetAttribute("InHunting", false)
	for _, attribute in ATTRIBUTES do player:SetAttribute(attribute, nil) end
	if self.Players[player] then
		self.Players[player] = nil
		self.Count -= 1
	end
	self.Forest:SetAttribute("ActiveHunters", self.Count)
 -- Wildlife keeps roaming even when the final hunter returns to the lobby.
end

function Session:Expired()
	local now, expired = wallTime(), {}
	for player, visit in self.Players do
		local remaining = math.max(0, math.ceil(visit.Duration - ((visit.FrozenAt or now) - visit.StartedAt)))
		if player:GetAttribute("HuntRemainingSeconds") ~= remaining then player:SetAttribute("HuntRemainingSeconds", remaining) end
		if remaining == 0 then table.insert(expired, player) end
	end
	return expired
end

function Session:IsOutside(position)
	local offset = self.Config.WorldOffset or self.Forest:GetAttribute("WorldOffset") or Vector3.new(0, 0, 6500)
	local localPosition = position - offset
	local limitX = (self.Config.MapWidth or self.Config.MapSize or 1620) / 2 + 105
	local limitZ = (self.Config.MapDepth or self.Config.MapSize or 1620) / 2 + 105
	return localPosition.Y < (self.Config.TerrainMin or -48) - 20
		or math.abs(localPosition.X) > limitX or math.abs(localPosition.Z) > limitZ
end

function Session:Destroy()
	local players = {}
	for player in self.Players do table.insert(players, player) end
	for _, player in players do self:Exit(player) end
 if self.Patrol then self.Patrol:Destroy(true);self.Patrol=nil end
end

return Session
