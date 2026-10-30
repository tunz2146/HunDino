-- Prototype combat tuning; shared by all server-created controllers.
-- Rest durations are real seconds and live in DinosaurRouteController.
local Config = {
	MaxHealth = 1200,
	MaxDamagePerHit = 200,
	MaxWeaponRange = 250,
	MinimumHitInterval = .08,
	AttackTokenLifetime = 8,
	BiteDamage = 24,
	BiteWindup = .95,
	BiteActiveSeconds = .18,
	BiteRecovery = .45,
	BiteCooldown = 3.5,
	BiteRange = 36,
	BiteMinimumFacingDot = .2,
	BiteHitboxSize = Vector3.new(26, 16, 36),
	BiteForwardOffset = 18,
	BiteHeightAboveGround = 8,
	ChaseSpeed = 16,
	ChaseStopDistance = 18,
	LeashDistance = 260,
	AggroTimeout = 25,
	BlockedTimeout = 2.5,
	CampMargin = 20,
	HealthbarDistance = 220,
}

function Config.Faction(object)
 if not object then return nil end
 local faction=object:GetAttribute("CombatFaction")
 if type(faction)=="string" and faction~="" then return faction end
 if object:IsA("Player") then return if object.Team then "Team:"..object.Team.Name else "Hunters" end
 local owner=object:GetAttribute("OwnerUserId")
 return if type(owner)=="number" and owner>0 then "Owner:"..tostring(owner) else nil
end
function Config.Allied(a,b)
 if not a or not b then return false end
 local fa,fb=Config.Faction(a),Config.Faction(b)
 if fa and fb and fa==fb then return true end
 if a:GetAttribute("OwnerUserId") and b:IsA("Player") then return a:GetAttribute("OwnerUserId")==b.UserId end
 if b:GetAttribute("OwnerUserId") and a:IsA("Player") then return b:GetAttribute("OwnerUserId")==a.UserId end
 return false
end
return Config
