-- Logic thuần: dùng chung với bài kiểm tra ngoài Studio.
local Rules = {}
function Rules.attack(config, state, action, now)
	if action ~= "Light" and action ~= "Heavy" and action ~= "Skill" then return nil end
	if not state.Drawn or now < state.BusyUntil or state.Sprinting then return nil end
	local step = if now <= state.ComboUntil then state.ComboStep else 0
	local kind = if action == "Skill" and step == 2 then "Finisher" else action
	local attack = config.Attacks[kind]
	if state.Stamina < attack.Cost then return nil end
	state.Stamina -= attack.Cost
	state.BusyUntil = now + attack.Duration
	state.LastSpend = state.BusyUntil
	state.ComboStep = if action == "Light" then 1 elseif action == "Heavy" and step == 1 then 2 else 0
	state.ComboUntil = state.BusyUntil + config.ComboWindow
	return kind, attack
end
function Rules.regenerate(config, state, now, dt)
	if not state.Sprinting and now >= state.BusyUntil and now - state.LastSpend >= config.RegenDelay then
		state.Stamina = math.min(config.MaxStamina, state.Stamina + config.StaminaRegen * dt)
	end
end
return Rules
