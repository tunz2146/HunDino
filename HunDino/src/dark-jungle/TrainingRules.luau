local Rules={}
local keys={Light="L",Heavy="H",Skill="S"}
function Rules.staminaCost(config,base) return base*config.StaminaCostScale end
function Rules.clearCombo(state)
 state.ComboChain=""; state.ComboStep=0; state.ComboUntil=0
end
function Rules.attack(config,weapons,state,action,now)
 if not keys[action] then return nil end
 if not state.Drawn or now<state.BusyUntil or state.Sprinting or state.Blocking then return nil end
 local weapon=weapons[state.WeaponId]; if not weapon or not weapon.Attacks then return nil end
 local chain=(if now<=state.ComboUntil then state.ComboChain or "" else "")..keys[action]
 local kind=action
 for _,combo in weapon.Combos do
  if chain==combo.Input then kind=combo.Attack; break end
 end
 local spec=weapon.Attacks[kind]; local cost=Rules.staminaCost(config,spec.Cost)
 if state.Stamina+1e-7<cost then return nil end
 state.Stamina=math.max(0,state.Stamina-cost); state.BusyUntil=now+spec.Duration; state.LastSpend=state.BusyUntil
 -- Keep the longest suffix that starts a recipe; rejected inputs never advance it.
 local prefix=""
 if kind==action then
  for start=1,#chain do
   local suffix=chain:sub(start)
   for _,combo in weapon.Combos do
    if #suffix<#combo.Input and combo.Input:sub(1,#suffix)==suffix and #suffix>#prefix then prefix=suffix end
   end
  end
 end
 state.ComboChain=prefix; state.ComboStep=#prefix; state.ComboUntil=state.BusyUntil+config.ComboWindow
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
