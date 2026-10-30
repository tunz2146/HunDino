-- Pure profile/migration/JSON round-trip tests; never touches player DataStores.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local E = require("../src/hunting/HuntEconomyRules")
local S = require("../src/data/ProfileSchema").new(E)
local checks, groups = 0, 0
local NOW = 1792400000
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
local function test(name, body) body(); groups += 1; print("PASS", name) end
local function apply(profile, request)
	local receipt = E.apply(profile.Economy, request)
	check(receipt.Ok, tostring(request.Op) .. " failed: " .. receipt.Code)
	return receipt
end
local function base(profile, operation, fields)
	local request = clone(fields or {})
	request.Op, request.OperationSerial = operation, profile.Economy.OperationSerial + 1
	return apply(profile, request), request
end
local function open(profile, preparing)
	local serial = profile.Economy.RunSerial + 1
	local ids = {RunId="run:" .. serial, RunSerial=serial, MonsterId="monster:" .. serial}
	apply(profile, {Op="OpenRun", RunId=ids.RunId, MonsterId=ids.MonsterId, RunSerial=serial})
	if not preparing then apply(profile, {Op="StartRun", RunId=ids.RunId, RunSerial=serial}) end
	return ids
end
local function inRun(profile, ids, operation, fields)
	local request = clone(fields or {})
	request.Op, request.RunId, request.RunSerial = operation, ids.RunId, ids.RunSerial
	return apply(profile, request), request
end
local function defeated(profile)
	local ids = open(profile)
	for index=1, 6 do inRun(profile, ids, "Ore", {Index=index}) end
	inRun(profile, ids, "Finish", {Result="Defeated"})
	for index=1, 3 do inRun(profile, ids, "Carve", {Index=index, TypeRoll=0.1}) end
	inRun(profile, ids, "CloseRun")
	return ids
end
local function provision(profile)
	for _=1, 3 do
		base(profile, "Buy", {Item="RawTrap"})
		base(profile, "CraftTrap")
		base(profile, "Buy", {Item="SleepPotion"})
	end
end
local function specimen(ids)
	return {Id=string.format("%08x-0000-4000-8000-%012x", ids.RunSerial, ids.RunSerial),
		SpeciesId="TRex", Name="T-Rex", Variant="Normal", Element="None", SizeScale=1,
		CapturedAt=NOW, SourceRunId=ids.RunId, SourceMonsterId=ids.MonsterId}
end
local function captured(profile)
	local ids = open(profile)
	local record = specimen(ids)
	local receipt, request = inRun(profile, ids, "Finish", {Result="Captured", Traps=2, Potions=2, Specimen=record,
		Rolls={{TypeRoll=0.1,QuantityRoll=0.1}, {TypeRoll=0.5,QuantityRoll=0.5}, {TypeRoll=0.75,QuantityRoll=0.99}}})
	inRun(profile, ids, "CloseRun")
	return ids, receipt, request
end
local function roundTrip(profile)
	local encoded = assert(S.Encode(profile))
	return assert(S.Validate(serde.decode("json", serde.encode("json", encoded)))), encoded
end

test("Default is independent, complete and contains no transient combat state", function()
	luau.compile(fs.readFile("src/data/ProfileSchema.luau"))
	local a, b = S.Default(NOW), S.Default(NOW)
	check(a.DataVersion == 1 and a.Economy.DataVersion == 2 and a.Economy.Coins == 80, "Versioned starter")
	check(a.Loadout.WeaponId == "Hammer" and a.Loadout.PetWeaponId == "Hammer", "Starter weapons")
	check(a.Loadout.PlayerArmor.Chest == "Training" and a.Loadout.PetArmor.Chest == "Metal", "Starter armor")
	check(a.Pet.HealReadyAt == 0 and a.CreatedAt == NOW and a.UpdatedAt == NOW, "Timestamps")
	check(S.Validate(a) ~= nil and same(roundTrip(a), a), "Default survives serialization")
	a.Economy.Coins, a.Loadout.PlayerArmor.Head = 0, "None"
	check(b.Economy.Coins == 80 and b.Loadout.PlayerArmor.Head == "Training", "New accounts do not alias")
	check(a.Health == nil and a.Stamina == nil and a.Position == nil, "No transient state")
end)

test("Crafting, upgrades, choices, rewards and specimen GUIDs survive actual JSON", function()
	local p = S.Default(NOW)
	defeated(p); defeated(p)
	provision(p)
	local upgrade, request = base(p, "UpgradeHammer")
	local ids, finish, finishRequest = captured(p)
	p.Loadout.WeaponId, p.Loadout.PetWeaponId = "Bow", "Katana"
	p.Loadout.PlayerArmor.Head, p.Loadout.PlayerArmor.Chest = "Bone", "Leather"
	p.Loadout.PetArmor.Legs = "None"
	p.Preferences.ShowComboGuide=false; p.Preferences.ShowDamage=false; p.Preferences.ShowComboFX=false; p.Preferences.AimSensitivity=0.75
	p.Pet.HealReadyAt, p.UpdatedAt = NOW + 119, NOW + 1
	p.Statistics = {HuntsCompleted=3, HuntsFailed=0, Captures=1}
	local restored, encoded = roundTrip(p)
	check(same(restored, p), "All durable data survives JSON exactly")
	for key in encoded.Economy.OperationReceipts do check(type(key) == "string", "Receipt map serialized with string keys") end
	check(restored.Economy.HammerLevel == 2 and restored.Economy.Materials.Skin == 7, "Upgrade and gathered/captured loot retained")
	check(restored.Economy.OwnedSpecimens[finish.SpecimenId].Id == specimen(ids).Id, "Owned GUID retained")
	check(restored.Economy.OwnedSpecimens[finish.SpecimenId].Serial == 1, "Specimen sequence retained")
	local before = clone(restored)
	local again = apply(restored, request)
	check(again.Replay and again.HammerLevel == upgrade.HammerLevel and same(before, restored), "Upgrade receipt prevents repeated charge")
	again = apply(restored, finishRequest)
	check(again.Replay and again.SpecimenId == finish.SpecimenId and same(before, restored), "Capture receipt prevents duplicate individual/reward")
	restored.Economy.OwnedSpecimens[finish.SpecimenId].Name = "changed locally"
	check(p.Economy.OwnedSpecimens[finish.SpecimenId].Name == "T-Rex", "Validation deep-clones ownership")
end)

test("Sparse recent operation receipts remain dictionaries through JSON after eviction", function()
	local p = S.Default(NOW)
	for _=1, 20 do defeated(p) end
	for _=1, 70 do base(p, "Buy", {Item="SleepPotion"}) end
	check(p.Economy.OperationOrder[1] == 7 and #p.Economy.OperationOrder == 64, "Bounded ledger evicted oldest")
	local restored, encoded = roundTrip(p)
	check(encoded.Economy.OperationReceipts[7] == nil and encoded.Economy.OperationReceipts["7"] ~= nil, "Sparse key seven encoded as string")
	check(same(restored, p) and restored.Economy.OperationReceipts[7].OperationSerial == 7, "Sparse ledger restored without holes/loss")
	local before = clone(restored)
	check(apply(restored, {Op="Buy", OperationSerial=7, Item="RawTrap"}).Replay and same(before, restored), "Retained receipt replay cannot substitute an item")
	local stale = E.apply(restored.Economy, {Op="Buy", OperationSerial=1, Item="RawTrap"})
	check(not stale.Ok and stale.Code == "StaleOperation" and same(before, restored), "Evicted operation cannot be reissued")
end)

test("Wrapped economy v1 migrates without resetting coins, crafted items or receipts", function()
	local legacy = S.Default(NOW)
	defeated(legacy); provision(legacy)
	legacy.Economy.DataVersion, legacy.Economy.OwnedSpecimens, legacy.Economy.SpecimenSerial = 1, nil, nil
	legacy.Loadout.WeaponId, legacy.Pet.HealReadyAt = "DualDaggers", NOW + 20
	local original = clone(legacy)
	local migrated = assert(S.Validate(legacy))
	check(same(legacy, original), "Migration does not mutate source")
	check(migrated.Economy.DataVersion == 2 and migrated.Economy.SpecimenSerial == 0, "Collection migration applied")
	local reversed = clone(migrated)
	reversed.Economy.DataVersion, reversed.Economy.OwnedSpecimens, reversed.Economy.SpecimenSerial = 1, nil, nil
	check(same(reversed, original), "No reset or repeat starter grant during migration")
	check(same(roundTrip(migrated), migrated), "Migrated data remains serializable")
end)

test("Preparing-run recovery refunds reservations once and grants no quest loot", function()
	local p = S.Default(NOW); defeated(p); provision(p)
	local ids = open(p, true)
	local original = clone(p)
	local recovered, receipt = S.Recover(p)
	check(receipt and receipt.Ok and receipt.Result == "EntryFailed", "Preparing run uses entry failure")
	check(same(p, original), "Recover leaves source untouched until caller commits")
	check(recovered.Economy.ActiveRun == nil and recovered.Economy.StoredConsumables.IronTrap == 3
		and recovered.Economy.StoredConsumables.SleepPotion == 3, "All unentered reservations returned")
	check(recovered.Economy.Coins == p.Economy.Coins and same(recovered.Economy.Materials, p.Economy.Materials), "No result reward fabricated")
	check(same(recovered.Statistics, p.Statistics), "Statistics are not counted twice by recovery")
	local second, secondReceipt = S.Recover(roundTrip(recovered))
	check(secondReceipt == nil and same(second, recovered), "Repeated recovery is a no-op")
	local before = clone(second)
	check(inRun(second, ids, "CloseRun", {EntryFailed=true}).Replay and same(second, before), "Old run close cannot refund twice")
end)

test("Interrupted hunt preserves ore, closes as failed and returns only synchronized unused items", function()
	local p = S.Default(NOW); defeated(p); provision(p)
	local ids = open(p)
	inRun(p, ids, "Ore", {Index=1})
	inRun(p, ids, "SyncItems", {Traps=1, Potions=2})
	local recovered, receipt = S.Recover(roundTrip(p))
	check(receipt.Result == "Failed" and receipt.ReturnedTraps == 1 and receipt.ReturnedPotions == 2, "Known unused items returned")
	check(recovered.Economy.StoredConsumables.IronTrap == 1 and recovered.Economy.StoredConsumables.SleepPotion == 2, "Consumed items stay consumed")
	check(recovered.Economy.Materials.Iron == p.Economy.Materials.Iron and recovered.Economy.Coins == p.Economy.Coins, "Gathered ore retained; no finish bonus")
	check(recovered.Economy.ClosedRuns[#recovered.Economy.ClosedRuns].Claims["Ore:1"] ~= nil, "Source claim retained")
	check(same(S.Recover(recovered), recovered), "Interrupted run cannot recover twice")
end)

test("Already captured interrupted hunt closes without duplicating committed rewards/specimens", function()
	local p = S.Default(NOW); defeated(p); provision(p)
	local ids = open(p)
	local finish, request = inRun(p, ids, "Finish", {Result="Captured", Traps=2, Potions=2, Specimen=specimen(ids),
		Rolls={{TypeRoll=0.1,QuantityRoll=0.1}, {TypeRoll=0.5,QuantityRoll=0.5}, {TypeRoll=0.75,QuantityRoll=0.99}}})
	local recovered, receipt = S.Recover(roundTrip(p))
	check(receipt.Result == "Captured" and recovered.Economy.SpecimenSerial == 1, "Committed outcome retained")
	check(same(recovered.Economy.OwnedSpecimens, p.Economy.OwnedSpecimens)
		and same(recovered.Economy.Materials, p.Economy.Materials) and recovered.Economy.Coins == p.Economy.Coins, "No second package")
	local before = clone(recovered)
	check(apply(recovered, request).Replay and same(recovered, before), "Committed finish replays after load")
	check(recovered.Economy.OwnedSpecimens[finish.SpecimenId] ~= nil, "Original individual remains owned")
end)

test("Malformed and future profiles fail closed instead of becoming new starter accounts", function()
	local p = S.Default(NOW)
	local corruptions = {
		function(x) x.DataVersion=2 end,
		function(x) x.DataVersion=0 end,
		function(x) x.CreatedAt=-1 end,
		function(x) x.UpdatedAt=NOW-1 end,
		function(x) x.UpdatedAt=math.huge end,
		function(x) x.Pet.HealReadyAt=0/0 end,
		function(x) x.Pet.HealReadyAt=1.5 end,
		function(x) x.Statistics.Captures=-1 end,
		function(x) x.Loadout.WeaponId="Injected" end,
		function(x) x.Loadout.PetWeaponId="" end,
		function(x) x.Loadout.PlayerArmor.Head="Injected" end,
		function(x) x.Loadout.PetArmor.Legs=nil end,
		function(x) x.Preferences.ShowDamage="true" end,
		function(x) x.Preferences.AimSensitivity=2 end,
		function(x) x.Economy.Coins=-1 end,
		function(x) x.Economy.DataVersion=3 end,
		function(x) x.Economy=nil end,
		function(x) x.Extension={} end,
		function(x) x.Extension=x end,
		function(x) x.Loadout.Extension=function() end end,
	}
	for _, corrupt in corruptions do
		local bad=clone(p); corrupt(bad)
		local value, reason=S.Validate(bad)
		check(value == nil and type(reason) == "string", "Corrupt data rejected with reason")
		check(S.Encode(bad) == nil and S.Recover(bad) == nil, "Invalid data cannot save/recover")
	end
	for _, bad in {false, "profile", 12, {}, E.new()} do check(S.Validate(bad) == nil, "Unrecognized data is never treated as fresh") end
	local _, reason=S.Validate({DataVersion=2})
	check(reason == "FutureDataVersion", "Future schema reported explicitly")
	check(not pcall(function() S.Default(-1) end), "Invalid creation timestamp rejected")
end)

test("Operation receipt key aliases, collisions, missing receipts and malformed receipts reject", function()
	local p=S.Default(NOW); base(p,"Buy",{Item="SleepPotion"})
	for _, key in {"01", "1.0", "1e0", "0", "-1", "2147483648", "bad"} do
		local bad=assert(S.Encode(p)); bad.Economy.OperationReceipts[key]=bad.Economy.OperationReceipts["1"]
		check(S.Validate(bad) == nil, "Noncanonical receipt key rejected")
	end
	local bad=assert(S.Encode(p)); bad.Economy.OperationReceipts[1]=clone(bad.Economy.OperationReceipts["1"])
	check(S.Validate(bad) == nil, "Numeric/string key collision rejected")
	bad=assert(S.Encode(p)); bad.Economy.OperationReceipts["1"]=nil
	check(S.Validate(bad) == nil, "Missing receipt never silently reconstructed")
	bad=assert(S.Encode(p)); bad.Economy.OperationReceipts["1"].OperationSerial=2
	check(S.Validate(bad) == nil, "Key/body mismatch rejected by economy validator")
	check(S.Validate(setmetatable(clone(p), {})) == nil, "Metatable rejected")
end)

test("All supported weapons, armor choices and sensitivity presets validate", function()
	for _, weapon in {"Hammer","SwordShield","Katana","Glaive","DualDaggers","Bow","GreatAxe"} do
		local p=S.Default(NOW); p.Loadout.WeaponId,p.Loadout.PetWeaponId=weapon,weapon
		check(S.Validate(p) ~= nil, "Supported player/pet weapon")
	end
	for _, kind in {"Training","Leather","Metal","Bone","None"} do
		local p=S.Default(NOW)
		for _, slot in {"Head","Chest","Arms","Waist","Legs"} do p.Loadout.PlayerArmor[slot],p.Loadout.PetArmor[slot]=kind,kind end
		check(S.Validate(p) ~= nil, "Supported full armor sets")
	end
	for _, sensitivity in {0.5,0.75,1} do
		local p=S.Default(NOW); p.Preferences.AimSensitivity=sensitivity
		check(S.Validate(p) ~= nil, "Supported sensitivity preset")
	end
end)

test("Recovery errors are atomic rather than dropping a reservation or overwriting the profile", function()
	local p=S.Default(NOW)
	p.Economy.StoredConsumables.IronTrap=3
	open(p,true)
	p.Economy.StoredConsumables.IronTrap=E.Config.MaximumCount
	local before=clone(p)
	local recovered,reason=S.Recover(p)
	check(recovered == nil and reason == "RecoveryFailed:Capacity", "Overflow blocks recovery")
	check(same(p,before) and p.Economy.ActiveRun ~= nil, "Source data and reservation remain intact on failure")
end)

test("Sparse five-tube assignments survive JSON, move and clear with ownership intact", function()
	local p=S.Default(NOW)
	defeated(p);provision(p)
	local _,finish=captured(p)
	local owned=clone(p.Economy.OwnedSpecimens)
	for slot=1,5 do
		base(p,"SetDisplaySlot",{Slot=slot,SpecimenId=finish.SpecimenId})
		local restored,encoded=roundTrip(p)
		check(encoded.Economy.DisplaySlots[tostring(slot)]==finish.SpecimenId
			and encoded.Economy.DisplaySlots[slot]==nil,"Sparse slots serialize as canonical string dictionary keys")
		check(same(restored,p) and restored.Economy.DisplaySlots[slot]==finish.SpecimenId,"Assigned tube survives actual JSON")
		local occupied=0;for _ in restored.Economy.DisplaySlots do occupied+=1 end
		check(occupied==1 and same(restored.Economy.OwnedSpecimens,owned),"Move has exactly one displayed GUID and preserves records")
	end
	base(p,"SetDisplaySlot",{Slot=5,SpecimenId=false})
	local restored=roundTrip(p)
	check(next(restored.Economy.DisplaySlots)==nil and same(restored.Economy.OwnedSpecimens,owned),"Empty collection after removal remains persistable")
	local legacy=clone(p);legacy.Economy.DisplaySlots=nil
	local migrated=assert(S.Validate(legacy))
	check(next(migrated.Economy.DisplaySlots)==nil and same(migrated.Economy.OwnedSpecimens,owned),"Existing v2 account gains only the empty display map")
end)

test("Display persistence rejects noncanonical keys, collisions and dangling individuals", function()
	local p=S.Default(NOW);defeated(p);provision(p)
	local _,finish=captured(p)
	base(p,"SetDisplaySlot",{Slot=5,SpecimenId=finish.SpecimenId})
	for _,key in {"01","5.0","5e0","0","6","bad"} do
		local bad=assert(S.Encode(p));bad.Economy.DisplaySlots[key]=finish.SpecimenId
		check(S.Validate(bad)==nil,"Noncanonical display key cannot overwrite a slot")
	end
	local bad=assert(S.Encode(p));bad.Economy.DisplaySlots[5]=finish.SpecimenId
	check(S.Validate(bad)==nil,"Numeric/string display key collision rejected")
	bad=assert(S.Encode(p));bad.Economy.DisplaySlots["1"]=finish.SpecimenId
	check(S.Validate(bad)==nil,"Same individual cannot persist in two tubes")
	bad=assert(S.Encode(p));bad.Economy.OwnedSpecimens[finish.SpecimenId]=nil
	check(S.Validate(bad)==nil,"Dangling display reference prevents save instead of losing ownership")
end)

print("Profile schema:", checks, "checks /", groups, "groups PASS")
