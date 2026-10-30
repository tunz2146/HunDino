-- Integration tests against a JSON-serializing UpdateAsync fake. No Roblox
-- Instances, real DataStore, account IDs or production credentials are used.
local serde = require("@lune/serde")
local Economy = require("../src/hunting/HuntEconomyRules")
local Schema = require("../src/data/ProfileSchema").new(Economy)
local ProfileStore = require("../src/data/ProfileStore")
local NOW = 1792400000
local checks, groups = 0, 0
local function check(condition, message) checks += 1; assert(condition, message) end
local function same(a, b)
	if type(a) ~= type(b) then return false end
	if type(a) ~= "table" then return a == b end
	for key, value in a do if not same(value, b[key]) then return false end end
	for key, value in b do if not same(value, a[key]) then return false end end
	return true
end
local function clone(value)
	if type(value) ~= "table" then return value end
	local copy = {}; for key, child in value do copy[key] = clone(child) end; return copy
end
local function json(value)
	return if value == nil then nil else serde.decode("json", serde.encode("json", value))
end
local function test(name, body) body(); groups += 1; print("PASS", name) end

local function fake()
	local ds = {Values={}, Calls=0, Writes=0, Callbacks=0, FailBefore=0, FailAfter=0, RepeatCallbacks=3, ReplayCommitted=true}
	function ds:UpdateAsync(key, transform)
		self.Calls += 1
		if self.FailBefore > 0 then self.FailBefore -= 1; error("Injected network failure before callback") end
		-- Roblox may discard a callback result and invoke the callback again.
		local result
		for _=1, self.RepeatCallbacks do
			self.Callbacks += 1
			result = transform(json(self.Values[key]))
		end
		if result ~= nil then
			self.Values[key] = json(result)
			self.Writes += 1
			if self.ReplayCommitted then
				self.Callbacks += 1
				local replayed = transform(json(self.Values[key]))
				if replayed ~= nil then self.Values[key] = json(replayed) end
			end
		end
		if self.FailAfter > 0 then self.FailAfter -= 1; error("Injected lost response after commit") end
		return json(result)
	end
	return ds
end

local function repository(ds, clock, token)
	return ProfileStore.new({Store=ds, Token=token, Now=function() return clock.Now end,
		Sleep=function() end, MaxAttempts=3, LeaseSeconds=30, Validate=Schema.Validate, Encode=Schema.Encode})
end
local function load(repo, clock)
	local ok, status, data = repo:Load("test-account", Schema.Default(clock.Now))
	check(ok, "Load failed: " .. tostring(status))
	return data, status
end
local function save(repo, clock, profile, release)
	profile.UpdatedAt = clock.Now
	local ok, status, data = repo:Save("test-account", profile, release)
	check(ok, "Save failed: " .. tostring(status))
	check(same(data, profile), "Committed account equals caller's validated snapshot")
	return data, status
end

-- Statistics are part of the same caller-owned snapshot as the economy change.
-- The pure schema/repository deliberately do not infer gameplay statistics.
local function apply(profile, request)
	local receipt = Economy.apply(profile.Economy, request)
	check(receipt.Ok, tostring(request.Op) .. " failed: " .. tostring(receipt.Code))
	if request.Op == "Finish" and not receipt.Replay then
		local stats = profile.Statistics
		if receipt.Result == "Failed" then stats.HuntsFailed += 1
		else stats.HuntsCompleted += 1 end
		if receipt.Result == "Captured" then stats.Captures += 1 end
	end
	return receipt
end
local function base(profile, operation, fields)
	local request = clone(fields or {})
	request.Op, request.OperationSerial = operation, profile.Economy.OperationSerial + 1
	return apply(profile, request), request
end
local function open(profile, preparing)
	local n = profile.Economy.RunSerial + 1
	local ids = {RunId="integration-run:" .. n, RunSerial=n, MonsterId="integration-monster:" .. n}
	apply(profile, {Op="OpenRun", RunId=ids.RunId, MonsterId=ids.MonsterId, RunSerial=n})
	if not preparing then apply(profile, {Op="StartRun", RunId=ids.RunId, RunSerial=n}) end
	return ids
end
local function run(profile, ids, operation, fields)
	local request = clone(fields or {})
	request.Op, request.RunId, request.RunSerial = operation, ids.RunId, ids.RunSerial
	return apply(profile, request), request
end
local function defeat(profile)
	local ids = open(profile)
	for index=1, 6 do run(profile, ids, "Ore", {Index=index}) end
	local finish, request = run(profile, ids, "Finish", {Result="Defeated"})
	for index=1, 3 do run(profile, ids, "Carve", {Index=index, TypeRoll=0.1}) end
	run(profile, ids, "CloseRun")
	return ids, finish, request
end
local function provision(profile)
	for _=1, 3 do
		base(profile, "Buy", {Item="RawTrap"})
		base(profile, "CraftTrap")
		base(profile, "Buy", {Item="SleepPotion"})
	end
end
local function capture(profile, close)
	local ids = open(profile)
	local record = {Id=string.format("%08x-0000-4000-8000-%012x", ids.RunSerial, ids.RunSerial),
		SpeciesId="TRex", Name="T-Rex", Variant="Normal", Element="None", SizeScale=1,
		CapturedAt=NOW+1, SourceRunId=ids.RunId, SourceMonsterId=ids.MonsterId}
	local receipt, request = run(profile, ids, "Finish", {Result="Captured", Traps=2, Potions=2, Specimen=record,
		Rolls={{TypeRoll=0.1,QuantityRoll=0.1}, {TypeRoll=0.5,QuantityRoll=0.5}, {TypeRoll=0.75,QuantityRoll=0.99}}})
	if close then run(profile, ids, "CloseRun") end
	return ids, receipt, request
end
local function recover(profile)
	local data, receipt = Schema.Recover(profile)
	check(data ~= nil, "Schema recovery must succeed")
	return data, receipt
end

test("Complete account round trip preserves every current durable field across server tokens", function()
	local ds, clock = fake(), {Now=NOW}
	local a = repository(ds, clock, "complete-session-a")
	local p, status = load(a, clock)
	check(status == "Created", "Only first acquisition creates account")
	defeat(p); defeat(p); provision(p)
	local _, upgradeRequest = base(p, "UpgradeHammer")
	local _, finish, captureRequest = capture(p, true)
	base(p, "SetDisplaySlot", {Slot=5, SpecimenId=finish.SpecimenId})
	p.Loadout.WeaponId, p.Loadout.PetWeaponId = "Bow", "Katana"
	p.Loadout.PlayerArmor = {Head="Bone", Chest="Leather", Arms="Metal", Waist="None", Legs="Training"}
	p.Loadout.PetArmor = {Head="None", Chest="Bone", Arms="Training", Waist="Leather", Legs="Metal"}
	for key,value in {ShowComboGuide=false, ShowDamage=false, ShowComboFX=true, AimSensitivity=0.5} do p.Preferences[key]=value end
	p.Pet.HealReadyAt = NOW+119
	clock.Now += 2
	save(a, clock, p, true)
	check(ds.Values["test-account"].Session == nil, "Release removes lease")
	local b = repository(ds, clock, "complete-session-b")
	local restored, loaded = load(b, clock)
	check(loaded == "Loaded" and same(restored, p), "New session restores complete account exactly")
	check(restored.Statistics.HuntsCompleted == 3 and restored.Statistics.Captures == 1
		and restored.Statistics.HuntsFailed == 0, "Statistics persisted with reward transactions")
	check(restored.Economy.HammerLevel == 2 and restored.Economy.StoredConsumables.IronTrap == 2
		and restored.Economy.StoredConsumables.SleepPotion == 2, "Upgrade, crafted and remaining items retained")
	check(restored.Economy.OwnedSpecimens[finish.SpecimenId].Serial == 1, "Specimen identity retained")
	check(restored.Economy.DisplaySlots[5] == finish.SpecimenId and restored.Economy.DisplaySlots[1] == nil,
		"Sparse center tube assignment is restored by a new server session")
	check(restored.Pet.HealReadyAt == NOW+119, "Pet cooldown is absolute Unix time, not a new free heal")
	local before = clone(restored)
	check(apply(restored, upgradeRequest).Replay and apply(restored, captureRequest).Replay, "Old requests use durable receipts")
	check(same(restored, before), "Repeated rewards/upgrades change neither progress nor statistics")
	check(ds.Callbacks > ds.Calls, "Every write exercised repeated callbacks")
end)

test("Expired crash lease recovers synchronized unused items and collected ore exactly once", function()
	local ds, clock = fake(), {Now=NOW+1000}
	local a = repository(ds, clock, "crash-hunting-a")
	local p = load(a, clock)
	defeat(p); provision(p)
	local ids = open(p)
	run(p, ids, "Ore", {Index=1})
	run(p, ids, "SyncItems", {Traps=1, Potions=2})
	save(a, clock, p)
	local b = repository(ds, clock, "crash-hunting-b")
	local ok, why = b:Load("test-account", Schema.Default(clock.Now))
	check(not ok and why == "Locked", "Live lease protects the original server")
	clock.Now += 31
	local recovered, receipt = recover(load(b, clock))
	check(receipt.Result == "Failed" and receipt.ReturnedTraps == 1 and receipt.ReturnedPotions == 2, "Recovery returns only unspent synchronized reserve")
	check(recovered.Economy.Materials.Iron == p.Economy.Materials.Iron and recovered.Economy.Coins == p.Economy.Coins,
		"Collected ore remains owned without a false success bonus")
	check(recovered.Statistics.HuntsCompleted == 1 and recovered.Statistics.HuntsFailed == 1, "Recovery failure counted once in committed snapshot")
	save(b, clock, recovered, true)
	local c = repository(ds, clock, "crash-hunting-c")
	local again, secondReceipt = recover(load(c, clock))
	check(secondReceipt == nil and same(again, recovered), "Second server load cannot return items/count failure again")
	local before = clone(again)
	check(run(again, ids, "CloseRun", {Traps=3, Potions=3}).Replay and same(before, again), "Forged old remaining counts replay the existing close")
	local saved, code = a:Save("test-account", p)
	check(not saved and code == "SessionLost", "Expired owner cannot overwrite recovered inventory")
	check(same(assert(Schema.Validate(ds.Values["test-account"].Data)), recovered), "Durable recovery survives stale-owner save attempt")
end)

test("Committed capture then crash retains one specimen/reward package and one statistics update", function()
	local ds, clock = fake(), {Now=NOW+2000}
	local a = repository(ds, clock, "crash-captured-a")
	local p = load(a, clock)
	defeat(p); provision(p)
	local ids, finish, captureRequest = capture(p, false)
	save(a, clock, p)
	clock.Now += 31
	local b = repository(ds, clock, "crash-captured-b")
	local recovered, receipt = recover(load(b, clock))
	check(receipt.Result == "Captured" and receipt.ReturnedTraps == 2 and receipt.ReturnedPotions == 2, "Captured run only returns unused items")
	check(recovered.Economy.SpecimenSerial == 1 and same(recovered.Economy.OwnedSpecimens, p.Economy.OwnedSpecimens), "No additional specimen on recovery")
	check(same(recovered.Economy.Materials, p.Economy.Materials) and recovered.Economy.Coins == p.Economy.Coins, "No repeated capture loot")
	check(same(recovered.Statistics, p.Statistics) and recovered.Statistics.Captures == 1, "Recovery does not count capture twice")
	local before = clone(recovered)
	check(apply(recovered, captureRequest).Replay and same(before, recovered), "Finish receipt remains replayable after closing during recovery")
	check(recovered.Economy.OwnedSpecimens[finish.SpecimenId].SourceMonsterId == ids.MonsterId, "Original source-bound GUID retained")
	save(b, clock, recovered, true)
	local c = repository(ds, clock, "crash-captured-c")
	check(same(recover(load(c, clock)), recovered), "A subsequent acquisition remains identical")
end)

test("Sparse receipts beyond sixty-four, duplicate callbacks and lost save responses never duplicate rewards", function()
	local ds, clock = fake(), {Now=NOW+3000}
	local a = repository(ds, clock, "sparse-a")
	local p = load(a, clock)
	local latest, lastFinish
	for _=1, 20 do local ids, _, request=defeat(p); latest,lastFinish=ids,request end
	for _=1, 70 do base(p, "Buy", {Item="SleepPotion"}) end
	check(p.Economy.OperationOrder[1] == 7 and #p.Economy.OperationOrder == 64, "Operation history retains a sparse bounded window")
	ds.FailAfter = 2
	save(a, clock, p)
	check(ds.Values["test-account"].Revision == 1 and #ds.Values["test-account"].RecentCommits == 1, "Lost responses/repeated callbacks produce one account commit")
	local raw = ds.Values["test-account"].Data.Economy
	check(raw.OperationReceipts["7"] ~= nil and raw.OperationReceipts[7] == nil, "Stored ledger is a JSON dictionary, never a sparse array")
	save(a, clock, p, true)
	local b = repository(ds, clock, "sparse-b")
	local restored = load(b, clock)
	check(same(restored, p) and restored.Statistics.HuntsCompleted == 20, "All sparse receipts and statistics survive fresh session")
	local before = clone(restored)
	local receipt = apply(restored, {Op="Buy", OperationSerial=7, Item="RawTrap"})
	check(receipt.Replay and receipt.Item == "SleepPotion", "Operation replay cannot substitute a new item")
	lastFinish.Result = "Captured"
	check(apply(restored, lastFinish).Replay, "Duplicate finish cannot change defeated result to capture")
	check(run(restored, latest, "Carve", {Index=1, TypeRoll=0.99}).Replay, "Duplicate carve cannot reroll its material")
	check(same(before, restored), "Every duplicate leaves materials, currencies, statistics and specimen collection identical")
	local old = Economy.apply(restored.Economy, {Op="Buy", OperationSerial=1, Item="SleepPotion"})
	check(not old.Ok and old.Code == "StaleOperation" and same(before, restored), "Even evicted serials cannot execute again")
end)

test("Future/corrupt stored profiles never default or overwrite an existing account", function()
	local corruptions = {
		function(envelope) envelope.Data.DataVersion=2 end,
		function(envelope) envelope.FormatVersion=2 end,
		function(envelope) envelope.Data.Economy.Coins=-1 end,
		function(envelope) envelope.Data.Economy.DataVersion=99 end,
		function(envelope) envelope.Data.Loadout.WeaponId="unrecognized" end,
		function(envelope) envelope.Data.Preferences.AimSensitivity=100 end,
		function(envelope) envelope.Data.Economy.OperationReceipts["01"]={Ok=true,Code="Purchased",Replay=false,OperationSerial=1} end,
	}
	for index, corrupt in corruptions do
		local ds, clock = fake(), {Now=NOW+4000}
		local seed = repository(ds, clock, "corrupt-seed-" .. index)
		local p=load(seed, clock); base(p,"Buy",{Item="SleepPotion"}); save(seed,clock,p,true)
		corrupt(ds.Values["test-account"])
		local before = json(ds.Values["test-account"])
		local successor = repository(ds, clock, "corrupt-next-" .. index)
		local ok, reason = successor:Load("test-account", Schema.Default(clock.Now))
		check(not ok and type(reason) == "string", "Corrupt/future load returns failure")
		check(same(ds.Values["test-account"], before), "Failed load leaves entire envelope untouched")
		local writes = ds.Writes
		local saved, code = successor:Save("test-account", Schema.Default(clock.Now), true)
		check(not saved and code == "NotLoaded" and ds.Writes == writes, "Failed load cannot subsequently write starter account")
	end
end)

test("Temporary unavailable load cannot grant starter twice or replace a real account", function()
	local ds, clock = fake(), {Now=NOW+5000}
	local a = repository(ds, clock, "outage-a")
	local p=load(a, clock); base(p,"Buy",{Item="SleepPotion"}); save(a,clock,p,true)
	local before = json(ds.Values["test-account"])
	local b = repository(ds, clock, "outage-b")
	ds.FailBefore = 3
	local ok, code = b:Load("test-account", Schema.Default(clock.Now))
	check(not ok and code == "LoadFailed" and same(ds.Values["test-account"], before), "Outage leaves previous progress intact")
	check(not b:Save("test-account", Schema.Default(clock.Now)), "No write before a successful load")
	local restored=load(b, clock)
	check(same(restored,p) and restored.Economy.Coins == 70 and restored.Economy.StoredConsumables.SleepPotion == 1,
		"Retry loads original spending/inventory without another eighty coins")
end)

print("Profile JSON integration:", checks, "checks /", groups, "groups PASS")
