-- Các giá trị L0 là cấu hình thử, không phải cân bằng cuối của game.
return {
	Version = "v2.3-combos",
	-- Costs here and in Weapons are base costs; scale once when spending.
	StaminaCostScale = 0.30,
	GuardCost = 4,
	LobbyCapacity = 12,
	MaxStamina = 100,
	StaminaRegen = 20,
	RegenDelay = 0.75,
	WalkSpeed = 16,
	SprintSpeed = 25,
	SprintCost = 10,
	SheatheTime = 1,
	DodgeCost = 20,
	DodgeTime = 0.4,
	DodgeSpeed = 34,
	ComboWindow = 1.35,
	DummyHealth = 1000,
	PetDamage = 12,
	PetInterval = 4,
	Attacks = {
		Light = { Damage = 36, Cost = 8, Windup = 0.18, Duration = 0.55, Range = 9 },
		Heavy = { Damage = 70, Cost = 16, Windup = 0.45, Duration = 1.10, Range = 10 },
		Skill = { Damage = 50, Cost = 12, Windup = 0.3, Duration = 0.7, Range = 10 },
		Finisher = { Damage = 140, Cost = 20, Windup = 0.5, Duration = 1.2, Range = 12 },
	},
}
