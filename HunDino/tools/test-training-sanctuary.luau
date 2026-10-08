local fs=require('@lune/fs'); local r=require('@lune/roblox'); local luau=require('@lune/luau')
local config=require('../src/shared/TrainingConfig'); local weapons=require('../src/dark-jungle/Weapons'); local rules=require('../src/dark-jungle/TrainingRules')
local function fresh(id) return {WeaponId=id,InTraining=true,Drawn=true,BusyUntil=0,Sprinting=false,Blocking=false,Stamina=100,ComboStep=0,ComboUntil=0,LastSpend=0} end
local count=0
local function test(name,f) f(); count+=1; print('PASS',name) end
test('All seven weapons spend server-defined stamina; reject early repeated attacks',function()
 assert(#weapons.Order==7)
 for _,id in weapons.Order do
  for _,action in {'Light','Heavy','Skill'} do
   local s=fresh(id); local kind,spec=rules.attack(config,weapons,s,action,0)
   assert(kind==action and s.Stamina==100-rules.staminaCost(config,spec.Cost),id..action)
   assert(not rules.attack(config,weapons,s,action,.01),id..' spam')
   assert(s.Stamina==100-rules.staminaCost(config,spec.Cost))
  end
 end
end)
test('Every weapon has two distinct server-resolved finishers',function()
 local keys={L='Light',H='Heavy',S='Skill'}
 for _,id in weapons.Order do
  assert(#weapons[id].Combos==2)
  for _,combo in weapons[id].Combos do
   local s=fresh(id); local now=0; local kind
   for letter in combo.Input:gmatch('.') do
    kind=rules.attack(config,weapons,s,keys[letter],now); now=s.BusyUntil+.02
   end
   assert(kind==combo.Attack,id..combo.Input)
  end
 end
end)
test('Equip requires valid ID, training, sheathed, idle state',function()
 local s=fresh('Hammer'); assert(not rules.canEquip(s,weapons,'Bow',0))
 s.Drawn=false; assert(rules.canEquip(s,weapons,'Bow',0))
 for _,id in {'Order','NotAWeapon',7,{}} do assert(not rules.canEquip(s,weapons,id,0)) end
 s.InTraining=false; assert(not rules.canEquip(s,weapons,'Bow',0)); s.InTraining=true
 s.BusyUntil=1; assert(not rules.canEquip(s,weapons,'Bow',0))
end)
test('Guard/exhaustion/sheathe cannot attack; no guard regeneration',function()
 local s=fresh('SwordShield'); s.Blocking=true; assert(not rules.attack(config,weapons,s,'Light',0))
 s.Stamina=20; rules.regenerate(config,s,10,1); assert(s.Stamina==20)
 s.Blocking=false; s.Stamina=0; assert(not rules.attack(config,weapons,s,'Light',0))
 s.Stamina=100; s.Drawn=false; assert(not rules.attack(config,weapons,s,'Light',0))
end)
local process=require('@lune/process')
local g=r.deserializePlace(fs.readFile(process.args[1] or 'HunDino_DarkJungle_v2_3.rbxl'))
local world=g:GetService('Workspace'); local t=world.HunDinoL0.Training
test('Expanded arena, seven selectable racks, four ranged targets and return gate',function()
 assert(t.Ground.Size.X==460 and t.Ground.Size.Z==420)
 assert(#t.WeaponRacks:GetChildren()==7 and #t.Dummies:GetChildren()==7)
 local archery=0
 for _,d in t.Dummies:GetChildren() do
  if d:GetAttribute('Kind')=='Archery' then archery+=1 end
  assert(d.Target.SignGui.Text.Text:find('1000 / 1000',1,true))
 end
 assert(archery==4 and t.ToLobby.ToLobbyPrompt.KeyboardKeyCode==r.Enum.KeyCode.G)
 assert(t.Arrival.CFrame.Position.Y>t.Ground.CFrame.Position.Y+t.Ground.Size.Y/2)
 for _,id in weapons.Order do
  assert(t.WeaponRacks[id]:FindFirstChild('EquipPrompt'))
  assert(g:GetService('ServerStorage').TrainingWeapons[id].Main.PrimaryPart)
 end
end)
test('UTF-8 UI, anchored geometry and embedded code compile',function()
 local scripts=0
 for _,item in g:GetDescendants() do
  if item:IsA('BasePart') then assert(item.Anchored,item:GetFullName()) end
  if item:IsA('LuaSourceContainer') then luau.compile(item.Source); scripts+=1 end
  if item:IsA('TextLabel') then for _,cp in utf8.codes(item.Text) do assert(not (cp>=128 and cp<=159) and cp~=65533,item:GetFullName()) end end
 end
 assert(scripts==7,'unexpected script count '..scripts)
 local shared=g:GetService('ReplicatedStorage').Shared
 local function same(source,path)
  local a=source:gsub('\r\n','\n'); local b=fs.readFile(path):gsub('\r\n','\n')
  if a~=b then
   for i=1,math.max(#a,#b) do if a:byte(i)~=b:byte(i) then
    warn('Source mismatch',path,'lengths',#a,#b,'byte',i,'embedded',a:sub(math.max(1,i-20),i+40),'file',b:sub(math.max(1,i-20),i+40)); break
   end end
  end
  return a==b
 end
 assert(same(shared.Weapons.Source,'src/dark-jungle/Weapons.luau'))
 assert(same(shared.TrainingRules.Source,'src/dark-jungle/TrainingRules.luau'))
 assert(same(shared.TrainingConfig.Source,'src/shared/TrainingConfig.luau'))
 assert(same(g:GetService('ServerScriptService').HunDinoTraining.Source,'src/dark-jungle/Training.server.luau'))
 assert(same(g:GetService('StarterPlayer').StarterPlayerScripts.HunDinoTraining.Source,'src/dark-jungle/Training.client.luau'))
end)
print('PASSED',count,'groups. Studio play verification required.')
