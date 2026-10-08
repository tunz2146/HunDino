local Rules={}
function Rules.attack(config,weapons,state,action,now)
	if action~="Light" and action~="Heavy" and action~="Skill" then return nil end
	if not state.Drawn or now<state.BusyUntil or state.Sprinting or state.Blocking then return nil end
	local weapon=weapons[state.WeaponId]; if not weapon then return nil end
	local step=if now<=state.ComboUntil then state.ComboStep else 0
	local kind=if weapon.Combo and action=="Skill" and step==2 then "Finisher" else action
	local spec=weapon.Attacks[kind]
	if state.Stamina<spec.Cost then return nil end
	state.Stamina-=spec.Cost; state.BusyUntil=now+spec.Duration; state.LastSpend=state.BusyUntil
	state.ComboStep=if not weapon.Combo then 0 elseif action=="Light" then 1 elseif action=="Heavy" and step==1 then 2 else 0
	state.ComboUntil=state.BusyUntil+config.ComboWindow
	return kind,spec
end
function Rules.canEquip(state,weapons,id,now)
	return typeof(id)=="string" and weapons[id]~=nil and id~="Order" and state.InTraining
		and not state.Drawn and not state.Blocking and not state.Sprinting and now>=state.BusyUntil
end
function Rules.regenerate(config,state,now,dt)
	if not state.Sprinting and not state.Blocking and now>=state.BusyUntil and now-state.LastSpend>=config.RegenDelay then
		state.Stamina=math.min(config.MaxStamina,state.Stamina+config.StaminaRegen*dt)
	end
end
return Rules
