-- Durable account format. Pure data only: usable in Studio and in Lune tests.
-- Economy remains authoritative for its own migrations, transactions and receipts.
local ProfileSchema = {}
local VERSION = 1
local MAX_TIME = 253402300799
local MAX_COUNT = 1000000000
local MAX_SERIAL = 2147483647
local WEAPONS = {Hammer=true, SwordShield=true, Katana=true, Glaive=true,
	DualDaggers=true, Bow=true, GreatAxe=true}
local ARMORS = {Training=true, Leather=true, Metal=true, Bone=true, None=true}
local SLOTS = {"Head", "Chest", "Arms", "Waist", "Legs"}
local CONTROL_PREFS={AutoBowAim=true,AutoBowFire=false,SwapBowButtons=false,MeleeStance=1,RangedStance=1,KatanaCarry=1}
local FIELDS = {DataVersion=true, Economy=true, Loadout=true, Preferences=true,
	Pet=true, Statistics=true, CreatedAt=true, UpdatedAt=true}

local function integer(value, maximum)
	return type(value) == "number" and value == value and value >= 0
		and value <= maximum and value % 1 == 0
end

local function clone(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for key, child in value do copy[key] = clone(child) end
	return copy
end

-- Reject cycles, executable values, metatables and invalid floats before cloning.
-- The bounded depth also keeps malformed input from exhausting the Lua stack.
local function plain(value, visiting, depth)
	local kind = type(value)
	if kind == "number" then return value == value and math.abs(value) < math.huge end
	if kind ~= "table" then return kind == "string" or kind == "boolean" end
	if depth > 24 or visiting[value] or getmetatable(value) ~= nil then return false end
	visiting[value] = true
	for key, child in value do
		if (type(key) ~= "string" and not integer(key, MAX_TIME))
			or not plain(child, visiting, depth + 1) then
			visiting[value] = nil
			return false
		end
	end
	visiting[value] = nil
	return true
end

local function exactFields(value, names)
	if type(value) ~= "table" then return false end
	local allowed = {}
	for _, name in names do allowed[name] = true; if value[name] == nil then return false end end
	for key in value do if not allowed[key] then return false end end
	return true
end

local function armor(kind)
	local result = {}
	for _, slot in SLOTS do result[slot] = kind end
	return result
end

local function validArmor(value)
	if not exactFields(value, SLOTS) then return false end
	for _, slot in SLOTS do if not ARMORS[value[slot]] then return false end end
	return true
end

-- Numeric dictionary keys are unsafe through Roblox JSON/DataStore serialization.
-- Decode only canonical positive decimal keys, rejecting aliases/collisions.
local function decodeOperations(economy)
	if type(economy) ~= "table" or type(economy.OperationReceipts) ~= "table" then return false end
	local decoded = {}
	for key, receipt in economy.OperationReceipts do
		local n
		if type(key) == "number" then n = key
		elseif type(key) == "string" and key:match("^[1-9]%d*$") then n = tonumber(key) end
		if not integer(n, MAX_SERIAL) or n == 0 or decoded[n] ~= nil
			or (type(key) == "string" and tostring(n) ~= key) then return false end
		decoded[n] = receipt
	end
	economy.OperationReceipts = decoded
	return true
end

local function decodeDisplaySlots(economy)
	if economy.DisplaySlots == nil then return true end -- Validated v2 migration adds the empty collection.
	if type(economy.DisplaySlots) ~= "table" then return false end
	local decoded = {}
	for key, specimenId in economy.DisplaySlots do
		local slot
		if type(key) == "number" then slot = key
		elseif type(key) == "string" and key:match("^[1-5]$") then slot = tonumber(key) end
		if not integer(slot, 5) or slot == 0 or decoded[slot] ~= nil then return false end
		decoded[slot] = specimenId
	end
	economy.DisplaySlots = decoded
	return true
end

function ProfileSchema.new(economyRules)
	assert(type(economyRules) == "table" and type(economyRules.new) == "function"
		and type(economyRules.apply) == "function", "Economy rules are required")
	local schema = {DataVersion = VERSION}

	function schema.Default(nowUnix)
		assert(integer(nowUnix, MAX_TIME), "Default requires a Unix timestamp")
		return {DataVersion=VERSION, Economy=economyRules.new(),
			Loadout={WeaponId="Hammer", PetWeaponId="Hammer", PlayerArmor=armor("Training"), PetArmor=armor("Metal")},
			Preferences={ShowComboGuide=true, ShowDamage=true, ShowComboFX=true, AimSensitivity=1,AutoBowAim=true,AutoBowFire=false,SwapBowButtons=false,MeleeStance=1,RangedStance=1,KatanaCarry=1},
			Pet={HealReadyAt=0}, Statistics={HuntsCompleted=0, HuntsFailed=0, Captures=0},
			CreatedAt=nowUnix, UpdatedAt=nowUnix}
	end

	function schema.Validate(data)
		if type(data) ~= "table" or not plain(data, {}, 0) then return nil, "InvalidProfile" end
		if data.DataVersion ~= VERSION then
			return nil, if integer(data.DataVersion, MAX_SERIAL) and data.DataVersion > VERSION then "FutureDataVersion" else "InvalidDataVersion"
		end
		for field in FIELDS do if data[field] == nil then return nil, "MissingField:" .. field end end
		for field in data do if not FIELDS[field] then return nil, "UnknownField:" .. tostring(field) end end
		if not integer(data.CreatedAt, MAX_TIME) or not integer(data.UpdatedAt, MAX_TIME)
			or data.UpdatedAt < data.CreatedAt then return nil, "InvalidTimestamps" end
		local loadout = data.Loadout
		if not exactFields(loadout, {"WeaponId", "PetWeaponId", "PlayerArmor", "PetArmor"})
			or not WEAPONS[loadout.WeaponId] or not WEAPONS[loadout.PetWeaponId]
			or not validArmor(loadout.PlayerArmor) or not validArmor(loadout.PetArmor) then return nil, "InvalidLoadout" end
		local preferences = clone(data.Preferences)
  if type(preferences)~="table" then return nil,"InvalidPreferences" end
  for key,value in CONTROL_PREFS do if preferences[key]==nil then preferences[key]=value end end
  if not exactFields(preferences,{"ShowComboGuide","ShowDamage","ShowComboFX","AimSensitivity","AutoBowAim","AutoBowFire","SwapBowButtons","MeleeStance","RangedStance","KatanaCarry"})
   or type(preferences.ShowComboGuide)~="boolean" or type(preferences.ShowDamage)~="boolean" or type(preferences.ShowComboFX)~="boolean"
   or type(preferences.AutoBowAim)~="boolean" or type(preferences.AutoBowFire)~="boolean" or type(preferences.SwapBowButtons)~="boolean"
   or (preferences.AimSensitivity~=.5 and preferences.AimSensitivity~=.75 and preferences.AimSensitivity~=1)
   or not integer(preferences.MeleeStance,6) or preferences.MeleeStance<1
   or not integer(preferences.RangedStance,3) or preferences.RangedStance<1
   or not integer(preferences.KatanaCarry,2) or preferences.KatanaCarry<1 then return nil,"InvalidPreferences" end

		if not exactFields(data.Pet, {"HealReadyAt"}) or not integer(data.Pet.HealReadyAt, MAX_TIME) then return nil, "InvalidPet" end
		if not exactFields(data.Statistics, {"HuntsCompleted", "HuntsFailed", "Captures"}) then return nil, "InvalidStatistics" end
		for _, value in data.Statistics do if not integer(value, MAX_COUNT) then return nil, "InvalidStatistics" end end
		local normalized = clone(data)
  normalized.Preferences=preferences
		if not decodeOperations(normalized.Economy) then return nil, "InvalidOperationReceipts" end
		if not decodeDisplaySlots(normalized.Economy) then return nil, "InvalidDisplaySlots" end
		local economy, reason = economyRules.new(normalized.Economy)
		if not economy then return nil, "Economy:" .. tostring(reason) end
		normalized.Economy = economy
		return normalized
	end

	function schema.Encode(data)
		local encoded, reason = schema.Validate(data)
		if not encoded then return nil, reason end
		local receipts = {}
		for key, receipt in encoded.Economy.OperationReceipts do receipts[tostring(key)] = receipt end
		encoded.Economy.OperationReceipts = receipts
		local slots = {}
		for slot, specimenId in encoded.Economy.DisplaySlots do slots[tostring(slot)] = specimenId end
		encoded.Economy.DisplaySlots = slots
		return encoded
	end

	-- Loading never resumes a half-finished hunt: only its unspent reserved items
	-- return. Committed loot and claim ledgers remain intact, without new rewards.
	-- The caller must durably save this repaired profile before permitting actions.
	function schema.Recover(data)
		local recovered, reason = schema.Validate(data)
		if not recovered then return nil, reason end
		local run = recovered.Economy.ActiveRun
		if not run then return recovered end
		local request = {Op="CloseRun", RunId=run.Id, RunSerial=run.Serial}
		if run.State == "Preparing" then request.EntryFailed = true
		else request.Traps, request.Potions = run.Traps, run.Potions end
		local receipt = economyRules.apply(recovered.Economy, request)
		if not receipt.Ok then return nil, "RecoveryFailed:" .. tostring(receipt.Code) end
  if run.State=="Hunting" and run.Mode~="Exploration" then
   recovered.Statistics.HuntsFailed=math.min(MAX_COUNT,recovered.Statistics.HuntsFailed+1)
  end
		return recovered, receipt
	end

	schema.Decode = schema.Validate
	return schema
end

return ProfileSchema
