local config=require('../src/shared/TrainingConfig')
local weapons=require('../src/dark-jungle/Weapons')
local rules=require('../src/dark-jungle/TrainingRules')
local luau=require('@lune/luau'); local fs=require('@lune/fs')
local function fresh(id) return {WeaponId=id,Drawn=true,BusyUntil=0,Stamina=100,ComboUntil=0,LastSpend=0} end
local keys={L="Light",H="Heavy",S="Skill"}
local total=0
for _,id in weapons.Order do
 local weapon=weapons[id]; assert(#weapon.Combos==2)
 for _,combo in weapon.Combos do
  local s=fresh(id); local now=0; local spent=0
  for i=1,#combo.Input do
   local action=keys[combo.Input:sub(i,i)]
   local kind,spec=rules.attack(config,weapons,s,action,now)
   assert(kind==(if i==#combo.Input then combo.Attack else action),id.." "..combo.Input.." step "..i)
   spent+=spec.Cost*.3
   assert(math.abs(s.Stamina-(100-spent))<1e-6)
   local chain=s.ComboChain; local stamina=s.Stamina
   assert(not rules.attack(config,weapons,s,action,now+.01))
   assert(chain==s.ComboChain and stamina==s.Stamina)
   now=s.BusyUntil+.02
  end
  assert(s.ComboChain=="")
  assert(not rules.attack(config,weapons,s,combo.Attack,now),"cannot request a finisher directly")
  total+=1
 end
 for _,spec in weapon.Attacks do
  assert(spec.Windup+((spec.Hits or 1)-1)*(spec.HitInterval or .13)<spec.Duration)
  assert(spec.Windup+((spec.Shots or 1)-1)*(spec.ShotInterval or 0)<spec.Duration)
 end
 local c=weapon.Combos[1]
 for _,reset in {"Expired","Clear","EmptyStamina","Blocking","Sheathed"} do
  local s=fresh(id); local now=0
  for i=1,#c.Input-1 do
   local _,a=rules.attack(config,weapons,s,keys[c.Input:sub(i,i)],now); now=s.BusyUntil+.02
  end
  local last=keys[c.Input:sub(-1)]
  if reset=="Expired" then now=s.ComboUntil+.01
  elseif reset=="Clear" then rules.clearCombo(s)
  elseif reset=="EmptyStamina" then s.Stamina=0
  elseif reset=="Blocking" then s.Blocking=true
  else s.Drawn=false end
  local before=s.ComboChain; local result=rules.attack(config,weapons,s,last,now)
  if reset=="Expired" or reset=="Clear" then assert(result==last,id..reset)
  else assert(result==nil and before==s.ComboChain,id..reset) end
 end
end
assert(rules.staminaCost(config,config.DodgeCost)==6)
assert(rules.staminaCost(config,config.SprintCost)==3)
assert(rules.staminaCost(config,config.GuardCost)==1.2)
local s=fresh("Hammer"); s.Stamina=0; rules.regenerate(config,s,10,1); assert(s.Stamina==20)
for _,path in {"src/shared/TrainingConfig.luau","src/dark-jungle/Weapons.luau","src/dark-jungle/TrainingRules.luau","src/dark-jungle/Training.server.luau","src/dark-jungle/Training.client.luau"} do luau.compile(fs.readFile(path)) end
print("PASS",total,"combos, spending at 30%, interruption/expiry/spam/exhaustion and all script compilation")
