-- Portable control/state tests. No live profiles, network requests or Studio save.
local fs=require('@lune/fs')
local luau=require('@lune/luau')
local r=require('@lune/roblox')
local serde=require('@lune/serde')
local Config=require('../src/shared/TrainingConfig')
local Weapons=require('../studio-pet-integration/Weapons')
local Schema=require('../src/data/ProfileSchema').new(require('../src/hunting/HuntEconomyRules'))
local Handling=Config.Controls.Handling(r.CFrame,r.Vector3)
local checks=0
local function check(ok,message) checks+=1;assert(ok,message) end
local function section(source,name)
 local start=assert(source:find('local function '..name..'(',1,true),name)
 return source:sub(start,assert(source:find('\nend',start,true))+3)
end
local function same(a,b)
 if type(a)~=type(b) then return false end
 if type(a)~='table' then return a==b end
 for key,value in a do if not same(value,b[key]) then return false end end
 for key in b do if a[key]==nil then return false end end
 return true
end
local now=1792400000
local profile=Schema.Default(now)
local economy=serde.encode('json',profile.Economy)
local legacy=table.clone(profile.Preferences)
for _,key in {'AutoBowAim','AutoBowFire','SwapBowButtons','MeleeStance','RangedStance','KatanaCarry'} do profile.Preferences[key]=nil end
local migrated=assert(Schema.Validate(profile))
check(migrated.Preferences.AutoBowAim==true and migrated.Preferences.AutoBowFire==false,'Legacy aim/fire defaults')
check(migrated.Preferences.MeleeStance==1 and migrated.Preferences.RangedStance==1,'Legacy stance defaults')
check(serde.encode('json',migrated.Economy)==economy,'Control migration changed economic data')
check(profile.Preferences.AutoBowAim==nil,'Migration mutated caller input')
for _,key in {'AutoBowAim','AutoBowFire','SwapBowButtons'} do
 for _,bad in {1,'true',{},0/0} do local p=Schema.Default(now);p.Preferences[key]=bad;check(Schema.Validate(p)==nil,'Invalid boolean '..key) end
end
for _,key in {'MeleeStance','RangedStance'} do
 for _,bad in {0,if key=='MeleeStance' then 7 else 4,-1,1.5,0/0,math.huge,'1'} do local p=Schema.Default(now);p.Preferences[key]=bad;check(Schema.Validate(p)==nil,'Invalid stance '..key) end
end
for stance=1,3 do
 local p=Schema.Default(now);p.Preferences.MeleeStance=stance;p.Preferences.RangedStance=4-stance
 p.Preferences.AutoBowAim=false;p.Preferences.AutoBowFire=true;p.Preferences.SwapBowButtons=true
 local decoded=assert(Schema.Decode(serde.decode('json',serde.encode('json',assert(Schema.Encode(p))))))
 check(same(p,decoded),'Control settings did not survive JSON')
end
print('PASS legacy control migration, strict validation and saved preferences')

local client=fs.readFile('src/savegame/Training.client.luau')
local buttonSource=section(client,'bowMouseButton')..'\nreturn bowMouseButton'
for _,swapped in {false,true} do
 local button=luau.load(buttonSource,{environment={Enum=r.Enum,player={GetAttribute=function() return swapped end}},injectGlobals=true})()
 check(button(true)~=(button(false)),'Aim and fire share a mouse button')
 check(button(true)==(if swapped then r.Enum.UserInputType.MouseButton1 else r.Enum.UserInputType.MouseButton2),'Aim button mapping')
end
local autoStart=assert(client:find(' local autoFire=',1,true))
local autoEnd=assert(client:find(' chargeClock+=dt',autoStart,true))
local autoBlock=client:sub(autoStart,autoEnd-1)
local autoStep=luau.load([[return function(state)
 local activeCharge,readyAt,aiming=state.Charge,state.ReadyAt or 0,state.Aiming
 local attrs={AutoBowFire=state.AutoFire,Drawn=state.Drawn,WeaponId='Bow',ProfileReady=state.Ready,InTraining=true,AdminFlying=false}
 local player={GetAttribute=function(_,key) return attrs[key] end}
 local held={Light=state.ManualHeld==true}
 local GuiService={MenuIsOpen=false};local UIS={GetFocusedTextBox=function() return nil end}
 local function menuOpen() return state.Menu==true end
 local os={clock=function() return state.Now end}
 local function cancelHeld() activeCharge=nil;state.Cancels=(state.Cancels or 0)+1 end
 local function send(_,automatic) state.Starts=(state.Starts or 0)+1;activeCharge={Automatic=automatic,Started=state.Now,Time=1.2,Id=1} end
 local function aimDirection() return true,true end
 local remote={FireServer=function(_,action) if action=='ChargeRelease' then state.Releases=(state.Releases or 0)+1 end end}
]]..autoBlock..[[
 state.Charge=activeCharge;state.ReadyAt=readyAt;return state
end]],{injectGlobals=true})()
for _,field in {'Aiming','AutoFire','Drawn','Ready'} do
 local state={Aiming=true,AutoFire=true,Drawn=true,Ready=true,Now=1};state[field]=false
 autoStep(state);check(not state.Starts,'Automatic fire bypassed '..field)
end
local state={Aiming=true,AutoFire=true,Drawn=true,Ready=true,Now=1}
autoStep(state);check(state.Starts==1 and state.Charge.Automatic,'Automatic charge did not start')
state.Now=2;autoStep(state);check(not state.Releases,'Automatic fire released early')
state.Now=2.21;autoStep(state);check(state.Releases==1 and state.Charge==nil,'Automatic fire did not release once')
state.Now=2.22;autoStep(state);check(state.Starts==1,'Automatic fire ignored cooldown')
state.Now=3;autoStep(state);state.Menu=true;autoStep(state);check(state.Charge==nil and state.Cancels==1,'Opening a menu did not cancel automatic fire')
print('PASS mouse-button swapping and guarded automatic-fire state machine')

local server=fs.readFile('src/savegame/TrainingMerchant.server.luau')
local clock=0
local env={CFrame=r.CFrame,Vector3=r.Vector3,Weapons=Weapons,Config=Config,Handling=Handling,
 os={clock=function() return clock end},workspace={GetServerTimeNow=function() return clock end},sync=function(s) s.Syncs=(s.Syncs or 0)+1 end}
local definitions=''
for _,name in {'stowedWeaponPose','heldWeaponPose','clearDraw','weaponPose','animateDraw','updatePresentation'} do definitions..=section(server,name)..'\n' end
local poses=luau.load(definitions..'return {pose=weaponPose,animate=animateDraw,step=updatePresentation}',{environment=env,injectGlobals=true})()
local function actor(id)
 local character=r.Instance.new('Model')
 local function part(name,position,size)
  local p=r.Instance.new('Part');p.Name=name;p.CFrame=r.CFrame.new(position);p.Size=size or r.Vector3.new(1,2,1);p.Parent=character;return p
 end
 local torso=part('Torso',r.Vector3.new(10,3,0),r.Vector3.new(2,2,1))
 local left=part('Left Arm',r.Vector3.new(8.5,3,0));local right=part('Right Arm',r.Vector3.new(11.5,3,0))
 local handle=part('Handle',torso.CFrame.Position)
 local grip=r.Instance.new('Weld');grip.Part0=torso;grip.Part1=handle;grip.Parent=handle
 local s={Character=character,Root=torso,Player={GetAttribute=function() return 1 end,SetAttribute=function() end},WeaponId=id,Grip=grip,Drawn=false,BusyUntil=0}
 if id=='DualDaggers' then local off=r.Instance.new('Weld');off.Part0=torso;off.Part1=handle;off.Parent=handle;s.OffGrip=off end
 return s,left,right
end
for _,id in Weapons.Order do
 clock=0;local s,left,right=actor(id);poses.pose(s)
 local before=s.Grip.Part0.CFrame*s.Grip.C0
 s.ChangeDraw=true;poses.animate(s,true);poses.step(s)
 check((s.Grip.Part0.CFrame*s.Grip.C0).Position:FuzzyEq(before.Position,.0001),'Draw snapped at start: '..id)
 for frame=1,math.ceil(Config.Controls.DrawSeconds*60)+1 do clock=frame/60;left.CFrame*=r.CFrame.new(.004,0,0)*r.CFrame.Angles(.025,0,0);right.CFrame*=r.CFrame.new(.004,0,0);poses.step(s) end
 check(s.Drawn and s.ChangeDraw==nil and not s.DrawMotion,'Draw did not finish: '..id)
 check(s.Grip.Part0==(if Weapons[id].Ranged then left else right),'Wrong holding hand: '..id)
 if Weapons[id].Ranged then check((s.Grip.Part0.CFrame*s.Grip.C0).UpVector:Dot(s.Root.CFrame.UpVector)>.999,'Raised left arm tipped the bow sideways') end
 if s.OffGrip then check(s.OffGrip.Part0==left,'Offhand detached') end
 s.BusyUntil=clock;s.ChangeDraw=false;poses.animate(s,false)
 for frame=1,math.ceil(Config.Controls.DrawSeconds*60)+1 do clock+=1/60;poses.step(s) end
 check(not s.Drawn and s.Grip.Part0==s.Root,'Stow did not finish: '..id)
end
local cancelled=actor('Bow');clock=0;poses.pose(cancelled);cancelled.ChangeDraw=true;poses.animate(cancelled,true)
clock=.2;poses.step(cancelled);cancelled.ChangeDraw=nil;clock=2;poses.step(cancelled)
check(not cancelled.Drawn and cancelled.DrawMotion==nil,'Cancelled transition completed after travel/death')
print('PASS seven weapon draw/stow transitions, moving hand targets and cancellation')

local selections,messages=0,0
local hotkey=luau.load(section(server,'weaponHotkey')..'\nreturn weaponHotkey',{environment={
 Weapons=Weapons,os={clock=function() return clock end},
 message=function() messages+=1 end,
 equipWeapon=function(s,id) selections+=1;s.WeaponId=id;s.BusyUntil=clock+.3 end},injectGlobals=true})()
for slot,id in Weapons.Order do
 clock=0;local s=actor('Hammer');s.InTraining=true
 hotkey(s,slot)
 check(s.WeaponId==id and not s.Drawn and s.ChangeDraw==nil,'Slot must select without drawing '..id)
 clock=1;hotkey(s,slot)
 check(not s.Drawn and s.ChangeDraw==nil,'Same slot must not trigger draw/stow '..id)
 s.Drawn=true;local old=s.WeaponId;hotkey(s,if slot==7 then 1 else slot+1)
 check(s.WeaponId==old and s.Drawn,'Slot switched a drawn weapon without R')
end
local blocked=actor('Hammer');blocked.InTraining=true;clock=2
for _,bad in {0,8,-1,1.5,0/0,math.huge,'1'} do hotkey(blocked,bad) end
check(blocked.WeaponId=='Hammer','Malformed slot changed weapon')
blocked.ChangeDraw=true;hotkey(blocked,2)
check(blocked.WeaponId=='Hammer','Slot interrupted a hand-contact transition')
blocked.ChangeDraw=nil;blocked.Travelling=true;hotkey(blocked,2)
check(blocked.WeaponId=='Hammer','Slot changed weapon during travel')
check(messages>=7,'Missing manual stow instructions')
print('PASS manual R handling; 1-7 select only; drawn/busy/travel/malformed slots rejected')

for carry=1,2 do
 local p=Schema.Default(now);p.Preferences.KatanaCarry=carry
 local decoded=assert(Schema.Decode(serde.decode('json',serde.encode('json',assert(Schema.Encode(p))))))
 check(decoded.Preferences.KatanaCarry==carry,'Katana position did not survive saved profile')
end
local old=Schema.Default(now);old.Preferences.KatanaCarry=nil
check(assert(Schema.Validate(old)).Preferences.KatanaCarry==1,'Legacy katana must default to right-hip carry')
for _,bad in {0,3,-1,1.5,math.huge,0/0,'1',true} do
 local p=Schema.Default(now);p.Preferences.KatanaCarry=bad;check(Schema.Validate(p)==nil,'Invalid katana carry value accepted')
end
local function skeletalActor(r15,scale)
 local character=r.Instance.new('Model')
 local function part(name,size)
  local p=r.Instance.new('Part');p.Name=name;p.Size=size*scale;p.CFrame=r.CFrame.new(0,3,0);p.Parent=character;return p
 end
 local torso=part(if r15 then 'UpperTorso' else 'Torso',r.Vector3.new(2,2,1))
 local function joint(name,p0,p1,c0,c1)
  local m=r.Instance.new('Motor6D');m.Name=name;m.Part0=p0;m.Part1=p1;m.C0=r.CFrame.new(c0*scale);m.C1=r.CFrame.new(c1*scale);m.Parent=p0
  p1.CFrame=p0.CFrame*m.C0*m.C1:Inverse()
  return m
 end
 for _,side in {'left','right'} do
  local sign=if side=='left' then -1 else 1
  if r15 then
   local upper=part(side..'UpperArm',r.Vector3.new(.8,1.2,.8))
   local lower=part(side..'LowerArm',r.Vector3.new(.7,1.1,.7))
   local hand=part(side..'Hand',r.Vector3.new(.7,.45,.7))
   joint(side..'Shoulder',torso,upper,r.Vector3.new(sign,.7,0),r.Vector3.new(0,.5,0))
   joint(side..'Elbow',upper,lower,r.Vector3.new(0,-.5,0),r.Vector3.new(0,.48,0))
   joint(side..'Wrist',lower,hand,r.Vector3.new(0,-.48,0),r.Vector3.new(0,.2,0))
  else
   local arm=part(side..' Arm',r.Vector3.new(1,2,1))
   joint(side..' Shoulder',torso,arm,r.Vector3.new(sign,.5,0),r.Vector3.new(-sign*.5,.5,0))
  end
 end
 return character,torso,Handling.arm(character,'left'),Handling.arm(character,'right')
end
local function applySolved(arm,transforms)
 for _,m in {arm.Shoulder,arm.Elbow,arm.Wrist} do
  if m then
   local transform=transforms[m] or r.CFrame.new()
   m.Part1.CFrame=m.Part0.CFrame*m.C0*transform*m.C1:Inverse()
  end
 end
 return arm.Hand.CFrame:PointToWorldSpace(arm.Palm)
end
for _,r15 in {false,true} do
 for _,scale in {.8,1,1.25} do
  local character,torso,left,right=skeletalActor(r15,scale)
  for _,arm in {left,right} do
   for _,target in {r.Vector3.new(0,.5,-1.2),r.Vector3.new(2,2,1),r.Vector3.new(-3,-1,-2),r.Vector3.new(.1,.1,0)} do
    local transforms,contact=Handling.solve(arm,torso.CFrame*r.CFrame.new(target*scale))
    local palm=applySolved(arm,transforms)
    check((palm-contact.Position).Magnitude<.001,'Hand detached from weapon contact '..tostring(r15))
    for _,joint in {arm.Shoulder,arm.Elbow,arm.Wrist} do
     if joint then
      local a=joint.Part0.CFrame*joint.C0*(transforms[joint] or r.CFrame.new())
      local b=joint.Part1.CFrame*joint.C1
      check((a.Position-b.Position).Magnitude<.001,'Arm joint separated')
     end
    end
   end
  end
  local handoff=Handling.handoff(left,right,torso.CFrame)
  local _,lc=Handling.solve(left,handoff);local _,rc=Handling.solve(right,handoff)
  check((lc.Position-rc.Position).Magnitude<.08,'Two hands cannot meet for dagger handoff')
  for _,id in Weapons.Order do
   local mount=Handling.mount(id,false,1,torso.Size)
   local ready=Handling.ready(id,false,1,false,0)
   for frame=0,100 do
    local q=frame/100
    local draw=Handling.path(mount,ready,Handling.phase(q,true),id,Handling.scale(id))
    local stow=Handling.path(mount,ready,Handling.phase(1-q,false),id,Handling.scale(id))
    check((draw.Position-stow.Position).Magnitude<.0001,'Stow did not retrace draw path')
    if q<=Handling.Grab then check((draw.Position-mount.Position).Magnitude<.0001,'Weapon moved before hand contact') end
   end
  end
 end
end
local leftMount=Handling.mount('DualDaggers',true,1,r.Vector3.new(2,2,1))
local rightMount=Handling.mount('DualDaggers',false,1,r.Vector3.new(2,2,1))
check(leftMount.X>0 and rightMount.X>0,'Both daggers must be on the right waist')
check(leftMount.UpVector.Y<-.999 and rightMount.UpVector.Y<-.999,'Daggers must stow vertically with blades down')
check((leftMount.Position-rightMount.Position).Magnitude>.35,'Two daggers overlap at the belt')
local polearm=Handling.mount('Glaive',false,1,r.Vector3.new(2,2,1))
check(polearm.X>1 and polearm.UpVector.Y>.999,'Polearm must sit upright at the right waist')
local back=Handling.mount('Katana',false,2,r.Vector3.new(2,2,1))
local hip=Handling.mount('Katana',false,1,r.Vector3.new(2,2,1))
check(back.Z>.5 and hip.Z<0 and hip.X>0,'Katana back/right-hip mounts were not distinct')
local ready=Handling.ready('DualDaggers',false,1,false,0)
local offReady=Handling.ready('DualDaggers',true,1,false,0)
check(ready.UpVector.X<-.7 and offReady.UpVector.X>.7,'Default dual guard must cross high and low')
local handoff=r.CFrame.new(0,.5,-1.1)
for _,q in {0,.1,.18,.24,.35,.45,.54,.7,1} do
 local main,off,rh,lh=Handling.dual(rightMount,leftMount,ready,offReady,handoff,r.CFrame.new(1,-1,0),r.CFrame.new(-1,-1,0),q)
 if q<=.18 then check((off.Position-leftMount.Position).Magnitude<.0001,'Off dagger moved before pickup') end
 if q<=.54 then check((main.Position-rightMount.Position).Magnitude<.0001,'Main dagger moved before second pickup') end
 if q>=.18 and q<.35 then check((off.Position-rh.Position).Magnitude<.0001,'First dagger left picking hand') end
 if q>=.35 then check((off.Position-lh.Position).Magnitude<.0001,'Transferred dagger left the left hand') end
 if q>=.54 then check((main.Position-rh.Position).Magnitude<.0001,'Second dagger left right hand') end
end
print('PASS R6/R15 hand contacts, joined arm bones, reverse stow, two right-waist daggers and katana carry migration')

for _,r15 in {false,true} do
 local character,torso,left,right=skeletalActor(r15,1)
 for carry=1,2 do
  local mount=torso.CFrame:ToObjectSpace(Handling.reach(right,torso.CFrame*Handling.mount('Katana',false,carry,torso.Size)))
  local ready=Handling.ready('Katana',false,1,false,0)
  local previousMain,previousSheath
  for step=0,200 do
   local q=step/200
   local main,sheath=Handling.katana(torso.CFrame,mount,ready,q,.68,right,left)
   if previousMain then
    check((main.Position-previousMain.Position).Magnitude<.22,'Katana jumped between draw frames')
    check((sheath.Position-previousSheath.Position).Magnitude<.35,'Scabbard jumped between draw frames')
   end
   if q>=.4 and q<=Handling.Clear then
    check(math.abs(main.UpVector:Dot(sheath.UpVector))>.999,'Katana rotated inside its scabbard')
   end
   if math.abs(q-Handling.Clear)<.0001 then
    local gap=main:ToObjectSpace(sheath).Y-.72*.68
    check(gap>3.02,'Katana tip did not clear the scabbard before changing angle')
   end
   previousMain,previousSheath=main,sheath
  end
 end
end

for _,r15 in {false,true} do
 local character,torso,left,right=skeletalActor(r15,1)
 for _,id in {'Katana','GreatAxe','Glaive','SwordShield'} do
  local goal=torso.CFrame*Handling.ready(id,false,3,false,0)
  local offset=if id=='GreatAxe' or id=='Glaive' then .65 else -.44*Handling.scale(id)
  local main=Handling.twoHand(right,left,goal,offset)
  local _,rp=Handling.solve(right,main)
  local _,lp=Handling.solve(left,main*r.CFrame.new(0,offset,0))
  check((rp.Position-main.Position).Magnitude<.03,'Main hand detached during a two-hand guard')
  check((lp.Position-(main*r.CFrame.new(0,offset,0)).Position).Magnitude<.04,'Support hand missed the weapon handle')
 end
end

local configSource=fs.readFile('src/hunting/DinosaurCombatConfig.luau')
local factions=luau.load(configSource,{environment={Vector3=r.Vector3},injectGlobals=true})()
local function entity(kind,id,attrs)
 attrs=attrs or {}
 return {UserId=id,GetAttribute=function(_,key) return attrs[key] end,SetAttribute=function(_,key,value) attrs[key]=value end,IsA=function(_,class) return class==kind end}
end
local hunter=entity('Player',11,{})
local pet=entity('Model',nil,{CombatFaction='Hunters',OwnerUserId=11})
local friend=entity('Player',12,{})
local wild=entity('Model',nil,{CombatFaction='Wildlife'})
check(factions.Allied(hunter,pet),'Owner and pet must be allies')
check(factions.Allied(hunter,friend),'Default hunters must be allies')
check(not factions.Allied(hunter,wild),'Wildlife faction should differ')
local owned=entity('Model',nil,{OwnerUserId=11})
check(factions.Allied(owned,hunter),'Explicit owner relation was ignored')
local combatSource=fs.readFile('src/hunting/DinosaurCombat.luau')
local combatClass=luau.load(combatSource,{environment={game={GetService=function() return {} end},script={Parent={WaitForChild=function() return true end}},require=function() return factions end,Vector3=r.Vector3},injectGlobals=true})()
local function combat()
 local patrol={BeginCombat=function() return true end,SetDead=function() end,EndCombat=function() end}
 local self=setmetatable({Model=wild,Settings=factions,Session={Patrol=patrol},_health=1200,_time=1,_lastHits={},_petLastHits={},_tokens={},_target=nil},combatClass)
 self.CanHit=function(_,p) return not factions.Allied(wild,p),'Friendly' end
 self._publish=function() end;self._setPhase=function() end
 return self
end
local battle=combat()
check(battle._target==nil,'Neutral animal starts with an enemy')
check(battle:Damage(hunter,20,r.Vector3.zero,'pet:1','Pet')==20 and battle._target==hunter and battle._targetKind=='Pet','Pet attack retaliation targets the wrong entity')
check(battle:Damage(friend,20,r.Vector3.zero,'human:1','Projectile')==20 and battle._target==friend and battle._targetKind=='Player','Human attack retaliation targets the wrong entity')
wild:SetAttribute('CombatFaction','Hunters');local health=battle._health
check(battle:Damage(hunter,20,r.Vector3.zero,'friendly:1')==0 and battle._health==health,'Ally damage was accepted')
wild:SetAttribute('CombatFaction','Wildlife')
print('PASS faction/owner relations and retaliation against the actual attacking entity')

local companion=fs.readFile('src/hunting/PetCompanionController.luau')
local biteStart=assert(companion:find('function Controller:DamageInBite(',1,true))
local bite=companion:sub(biteStart,assert(companion:find('\nend',biteStart,true))+3)
local controller={}
local biteMethod=luau.load(bite..'\nreturn Controller.DamageInBite',{environment={Controller=controller,Vector3=r.Vector3,Enum=r.Enum,BODY_OFFSET=r.Vector3.new(0,2,0),
 finite=function(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end,
 vector=function(v) return typeof(v)=='Vector3' end,RaycastParams={new=function() return {} end},workspace={Raycast=function() return nil end}},injectGlobals=true})()
local petActor={Player=hunter,Pet=pet,Character={},PetFolder={},_biteTokens={},_canAct=function() return true end,_hunting=function() return true end,
 Damage=function(self,n) self.Applied=(self.Applied or 0)+n;return n end}
petActor.Pet.PrimaryPart={Position=r.Vector3.zero}
local attacker=entity('Model',nil,{CombatTargetUserId=12,CombatTargetKind='Pet',CombatFaction='Wildlife'})
check(biteMethod(petActor,r.CFrame.new(0,2,0),r.Vector3.new(26,16,36),1,24,attacker,10)==0,'Bystander pet took a bite')
attacker:SetAttribute('CombatTargetUserId',11);attacker:SetAttribute('CombatTargetKind','Player')
check(biteMethod(petActor,r.CFrame.new(0,2,0),r.Vector3.new(26,16,36),2,24,attacker,10)==0,'Nonattacking pet took its owner retaliation')
attacker:SetAttribute('CombatTargetKind','Pet');attacker:SetAttribute('CombatFaction','Hunters')
check(biteMethod(petActor,r.CFrame.new(0,2,0),r.Vector3.new(26,16,36),3,24,attacker,10)==0,'Allied animal damaged a pet')
attacker:SetAttribute('CombatFaction','Wildlife')
check(biteMethod(petActor,r.CFrame.new(0,2,0),r.Vector3.new(26,16,36),4,24,attacker,10)==24,'Attacking pet was immune to retaliation')
check(biteMethod(petActor,r.CFrame.new(0,2,0),r.Vector3.new(26,16,36),4,24,attacker,10)==0,'Bite damaged its victim twice')
print('PASS targeted pet retaliation, allied/bystander protection and one hit per bite')

local routeSource=fs.readFile('src/hunting/DinosaurRouteController.luau')
local paths=0
local obstacles={Overlap=false,Sweep=false}
local world={GetPartBoundsInBox=function() return if obstacles.Overlap then {true} else {} end,
 Blockcast=function() return if obstacles.Sweep then {} else nil end}
local pathfinder={CreatePath=function() return {Status=r.Enum.PathStatus.Success,ComputeAsync=function(self,a,b) self.A=a;self.B=b;paths+=1 end,
 GetWaypoints=function(self) return {{Position=self.A,Action=r.Enum.PathWaypointAction.Walk},{Position=self.B,Action=r.Enum.PathWaypointAction.Walk}} end,Destroy=function() end} end}
local routes=luau.load(routeSource,{environment={Vector3=r.Vector3,CFrame=r.CFrame,Enum=r.Enum,workspace=world,game={GetService=function(_,name) return if name=='PathfindingService' then pathfinder else {} end},task={spawn=function(fn) fn() end}},injectGlobals=true})()
local seed=1
local random={NextNumber=function(_,a,b) seed=(seed*48271)%2147483647;return a+(b-a)*(seed/2147483647) end}
local roam=setmetatable({_position=r.Vector3.new(10000,0,10000),_groundY=0,_yaw=0,_collisionSize=r.Vector3.new(20,25,30),
 _random=random,_unrestrictedRoam=true,_roamRest=0,_roamGeneration=0,_maxSpeed=12,_acceleration=6,_combatSlope=math.rad(28),
 _speed=0,_travelled=0,_groundMisses=0,_legs=0,_visited={},_state='Resting',Model=entity('Model',nil,{}),
 Config={Zones={{id='A'}},position=function() return r.Vector3.zero end,TerrainMax=128,TerrainMin=-48}},routes)
roam._ground=function(_,position) return {Position=r.Vector3.new(position.X,0,position.Z),Normal=r.Vector3.yAxis,Material=r.Enum.Material.Grass} end
roam._safeCombatGround=function(self,position) return self:_ground(position) end
roam._gait=function() return 0 end;roam._place=function(self,_,_,direction) self._yaw=math.atan2(direction.X,direction.Z) end;roam._publish=function() end
check(roam:_outsideCombatBounds(r.Vector3.new(20000,0,-20000))==false,'Free roaming retained a map/camp boundary')
local start=roam._position
for _=1,1800 do roam:_freeWanderStep(.1,.1) end
check(roam._travelled>200 and roam._legs>0 and paths>0,'Wildlife did not roam outside authored routes')
check((roam._position-start).Magnitude>20,'Wildlife stayed tied to its home')
roam._motionMode='Combat';roam._combatSnapshot={anchor=start};roam._combatTrail={start};roam:EndCombat()
check(roam._motionMode==nil and roam._combatSnapshot==nil and roam._roamRest>0,'Animal snapped back to a home route after combat')
print('PASS world-space wandering beyond old zones and resuming from the current location')
roam._safeCombatGround=nil;roam._turnSpeed=math.rad(65);roam._collisionCenter=r.Vector3.new(0,12,0);roam._overlapParams={};roam._decorParams={}
local ground=roam._ground
local point=roam._position+r.Vector3.xAxis
check(roam:_safeCombatGround(point,r.Vector3.xAxis,.1)~=nil,'Safe ground was rejected')
obstacles.Overlap=true;check(roam:_safeCombatGround(point,r.Vector3.xAxis,.1)==nil,'Animal clipped a body obstacle');obstacles.Overlap=false
obstacles.Sweep=true;check(roam:_safeCombatGround(point,r.Vector3.xAxis,.1)==nil,'Animal tunneled through an obstacle');obstacles.Sweep=false
roam._ground=function(self,p) local result=ground(self,p);result.Material=r.Enum.Material.Water;return result end
check(roam:_safeCombatGround(point,r.Vector3.xAxis,.1)==nil,'Animal walked into water')
roam._ground=function(self,p) local result=ground(self,p);result.Position+=r.Vector3.new(0,25,0);return result end
check(roam:_safeCombatGround(point,r.Vector3.xAxis,.1)==nil,'Animal climbed an unsupported cliff')
roam._ground=function(self,p) if (p-point).Magnitude>2 then return nil end;return ground(self,p) end
check(roam:_safeCombatGround(point,r.Vector3.xAxis,.1)==nil,'Animal walked without foot support')
print('PASS obstruction sweeps, footprint support, cliffs and water rejection')

local starts,destroys=0,0
local randomSource={NextNumber=function(_,a,b) return (a+b)/2 end,NextInteger=function(_,a) return a end}
local sessionModule=luau.load(fs.readFile('src/hunting/HuntingSession.luau'),{environment={Vector3=r.Vector3,
 Random={new=function() return randomSource end},workspace={GetServerTimeNow=function() return clock end},
 DateTime={now=function() return {UnixTimestampMillis=now*1000,UnixTimestamp=now} end}},injectGlobals=true})()
local sessionConfig={Zones={{id='A',kind='Main'},{id='R1',kind='Rest'}},position=function() return r.Vector3.zero end,HuntDurationSeconds=60}
local forest=entity('Model',nil,{})
local routeFactory={new=function(_,_,_,options)
 check(options.UnrestrictedRoam==true,'Session did not enable unrestricted roaming')
 return {Start=function(self) starts+=1;return self end,Destroy=function() destroys+=1 end}
end}
local session=sessionModule.new(forest,sessionConfig,wild,routeFactory)
check(session.Patrol~=nil and starts==1,'Wildlife requires a player before it starts roaming')
session:Enter(hunter);session:Exit(hunter)
check(session.Patrol~=nil and destroys==0,'Wildlife was reset when the last player left')
session:Enter(friend);check(starts==1,'A returning player created a second controller')
session:Destroy();check(destroys==1 and session.Patrol==nil,'Session teardown leaked its wildlife controller')
print('PASS wildlife starts independently of hunters and cleans up exactly once')


-- Upgraded avatars expose AnimationConstraint with read-only Motor6D aliases.
-- Use attachment-backed aliases so a future accidental C0/C1 write fails here too.
local function upgradedActor(r15)
 local character,torso=skeletalActor(r15,1)
 local constraints,motors={},{}
 for _,motor in character:GetDescendants() do
  if not motor:IsA('Motor6D') then continue end
  table.insert(motors,motor)
  local a=r.Instance.new('Attachment');a.CFrame=motor.C0;a.Parent=motor.Part0
  local b=r.Instance.new('Attachment');b.CFrame=motor.C1;b.Parent=motor.Part1
  local state={Name=motor.Name,Parent=motor.Parent,Attachment0=a,Attachment1=b,Transform=r.CFrame.new()}
  local joint=setmetatable({}, {
   __index=function(_,key)
    if key=='IsA' then return function(_,class) return class=='AnimationConstraint' or class=='Constraint' end end
    if key=='C0' then return state.Attachment0 and state.Attachment0.CFrame end
    if key=='C1' then return state.Attachment1 and state.Attachment1.CFrame end
    if key=='Part0' then return state.Attachment0 and state.Attachment0.Parent end
    if key=='Part1' then return state.Attachment1 and state.Attachment1.Parent end
    return state[key]
   end,
   __newindex=function(_,key,value)
    assert(key~='C0' and key~='C1' and key~='Part0' and key~='Part1','Upgraded joint aliases are read-only')
    state[key]=value
   end,
  })
  table.insert(constraints,joint)
 end
 local wrapper={GetDescendants=function() return constraints end}
 return wrapper,torso,constraints,motors
end
for _,r15 in {false,true} do
 local character,torso,constraints,motors=upgradedActor(r15)
 local left,right=Handling.arm(character,'left'),Handling.arm(character,'right')
 check(left~=nil and right~=nil,'Upgraded avatar arms were silently ignored')
 for _,arm in {left,right} do
  for _,id in {'Hammer','GreatAxe','Katana','Bow','DualDaggers'} do
   local modelGoal=torso.CFrame*Handling.ready(id,false,1,false,0)
   local grip=Handling.grip(id)
   local transforms,contact=Handling.solve(arm,modelGoal*grip)
   local palm=applySolved(arm,transforms)
   check((palm-contact.Position).Magnitude<.001,'AnimationConstraint hand detached from grip: '..id)
  end
 end
 local combined={};for _,m in motors do table.insert(combined,m) end
 for _,c in constraints do table.insert(combined,c) end
 local preferred=Handling.arm({GetDescendants=function() return combined end},'right')
 check(preferred.Shoulder:IsA('AnimationConstraint'),'Legacy duplicate masked the upgraded active joint')
 local shoulder=right.Shoulder;local attachment=shoulder.Attachment1
 shoulder.Attachment1=nil
 check(Handling.arm(character,'right')==nil,'Partially streamed shoulder was treated as ready')
 shoulder.Attachment1=attachment
 check(Handling.arm(character,'right')~=nil,'Late-arriving shoulder could not recover')
end
for _,id in {'Hammer','GreatAxe'} do
 local ready=Handling.ready(id,false,1,false,0)
 check(ready.UpVector.X<-.85 and ready.UpVector.Y>.2 and ready.UpVector.Y<.5,'Heavy weapon must sit diagonally across the front: '..id)
 check(not Handling.twoHanded(id,1),'Relaxed heavy weapon still forces two hands: '..id)
 check(Handling.twoHanded(id,3),'Optional two-handed heavy guard was lost: '..id)
 for _,r15 in {false,true} do
  local character,torso,left,right=skeletalActor(r15,1)
  local grip=Handling.grip(id)
  local transforms,palm=Handling.solve(right,torso.CFrame*ready*grip)
  local model=palm*grip:Inverse()
  local actual=applySolved(right,transforms)
  check((model:PointToWorldSpace(grip.Position)-actual).Magnitude<.001,'Heavy handle is not in the palm')
  check(actual.Y>torso.CFrame.Position.Y-.65 and actual.Y<torso.CFrame.Position.Y+.05,'Heavy hand must be slightly raised near the waist')
 end
end
local katanaReady=Handling.ready('Katana',false,1,false,0)
check(katanaReady.X>.9 and katanaReady.UpVector.Y>.6,'Katana must be held at the right hand, not across the shoulders')
check(not Handling.twoHanded('Katana',1),'Default katana should remain in the right hand after the draw')
print('PASS upgraded-joint discovery, streamed rig recovery, palm contact and relaxed axe/hammer holds')
for _,r15 in {false,true} do
 local character,torso,left,right=skeletalActor(r15,1)
 for carry=1,2 do
  local mount=torso.CFrame:ToObjectSpace(Handling.reach(right,torso.CFrame*Handling.mount('Katana',false,carry,torso.Size)))
  local ready=Handling.ready('Katana',false,1,false,0)
  for step=0,152 do
   local q=step/200
   local main,sheath=Handling.katana(torso.CFrame,mount,ready,q,.68,right,left)
   local relative=main:ToObjectSpace(sheath)
   check(math.abs(relative.X)<.001 and math.abs(relative.Z+.08*.68)<.001,'Blade left the scabbard centerline before clearing')
   check(main.UpVector:Dot(sheath.UpVector)>.999,'Blade turned across the scabbard during extraction')
  end
 end
end
print('PASS katana keeps its blade on the scabbard centerline throughout insertion/extraction')



check(#Config.Controls.MeleeStances==6 and #Config.Controls.RangedStances==3,'Melee/ranged stance counts diverged')
for stance=1,6 do
 local profile=Schema.Default(now)
 local coins=serde.encode('json',profile.Economy)
 profile.Preferences.MeleeStance=stance
 local saved=assert(Schema.Encode(profile))
 local decoded=assert(Schema.Decode(serde.decode('json',serde.encode('json',saved))))
 check(decoded.Preferences.MeleeStance==stance,'New guard did not survive saved JSON')
 check(serde.encode('json',decoded.Economy)==coins,'Changing a guard changed economy')
end
local requestSource=fs.readFile('src/data/ProfileService.luau')
local requestAt=assert(requestSource:find('function Service:Request(',1,true))
local requestBody=requestSource:sub(requestAt,assert(requestSource:find('\nend',requestAt,true))+3)
local attributes={}
local requestClock=100
local preferenceMethod=luau.load(requestBody..'\nreturn Service.Request',{environment={Service={},PREFS={MeleeStance=true,RangedStance=true},os={clock=function() return requestClock end},set=function(_,key,value) attributes[key]=value end},injectGlobals=true})()
local fakePlayer={}
local service={Entries={[fakePlayer]={}},CanMutate=function() return true end}
for value=1,6 do requestClock+=1;preferenceMethod(service,fakePlayer,'Preference','MeleeStance',value);check(attributes.MeleeStance==value,'Server rejected a valid melee guard') end
for _,value in {0,7,1.5,math.huge,0/0,'4',true} do requestClock+=1;preferenceMethod(service,fakePlayer,'Preference','MeleeStance',value);check(attributes.MeleeStance==6,'Server accepted an invalid melee guard') end
requestClock+=1;preferenceMethod(service,fakePlayer,'Preference','RangedStance',3)
requestClock+=1;preferenceMethod(service,fakePlayer,'Preference','RangedStance',4)
check(attributes.RangedStance==3,'Adding melee guards widened ranged settings')
local bStart=assert(client:find('elseif input.KeyCode==Enum.KeyCode.B then',1,true))
bStart=assert(client:find('\n',bStart,true))+1
local bEnd=assert(client:find(' elseif input.KeyCode==Enum.KeyCode.LeftShift then',bStart,true))
local nextStance=luau.load('return function(ranged,current) local result;local player={GetAttribute=function() return current end};local function requestControlPreference(key,value) result=value end\n'..client:sub(bStart,bEnd-1)..'\nreturn result end',{environment={Config=Config},injectGlobals=true})()
for _,ranged in {false,true} do
 local count=if ranged then 3 else 6
 local current=1
 for index=1,count*2 do current=nextStance(ranged,current);check(current==index%count+1,'B skipped a stance or wrapped early') end
end
print('PASS six saved melee guards, bounded server requests and complete B-key cycling')

for _,r15 in {false,true} do
 local character,torso,left,right=skeletalActor(r15,1)
 for stance=4,6 do
  for _,id in {'Katana','Glaive','Hammer','GreatAxe'} do
   local grip=Handling.grip(id)
   local support=Handling.supportOffset(id,stance)
   local frame=Handling.twoHand(right,left,torso.CFrame*Handling.ready(id,false,stance,false,0)*grip,support-grip.Y)*grip:Inverse()
   local _,main=Handling.solve(right,frame*grip)
   local _,off=Handling.solve(left,frame*r.CFrame.new(0,support,0))
   check((main.Position-(frame*grip).Position).Magnitude<.04,'Main hand left the handle in an added guard')
   check((off.Position-(frame*r.CFrame.new(0,support,0)).Position).Magnitude<.05,'Support hand left the handle in an added guard')
  end
 end
end
check(Handling.ready('Katana',false,5,false,0).Y>Handling.ready('Katana',false,4,false,0).Y+.8,'Overhead guard was not raised')
check(Handling.ready('Katana',false,6,false,0).Y<Handling.ready('Katana',false,4,false,0).Y-.5,'Low guard did not lower the hands')

local function bodyRig(segmented)
 local model=r.Instance.new('Model')
 local function part(name,size,cf)
  local p=r.Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf or r.CFrame.new();p.Parent=model;return p
 end
 local root=part('HumanoidRootPart',r.Vector3.new(2,2,1),r.CFrame.new(0,3,0))
 local joints={}
 local function motor(name,parent,child,c0,c1)
  local m=r.Instance.new('Motor6D');m.Name=name;m.Part0=parent;m.Part1=child;m.C0=c0;m.C1=c1;m.Transform=r.CFrame.new();m.Parent=parent
  child.CFrame=parent.CFrame*c0*c1:Inverse()
  table.insert(joints,m);return m
 end
 local pelvis=part(if segmented then 'LowerTorso' else 'Torso',r.Vector3.new(2,if segmented then 1 else 2,1))
 local rot=if segmented then r.CFrame.new() else r.CFrame.Angles(-math.pi/2,0,-math.pi/2)
 motor(if segmented then 'Root' else 'RootJoint',root,pelvis,rot,rot)
 if segmented then
  local torso=part('UpperTorso',r.Vector3.new(2,1,1))
  motor('Waist',pelvis,torso,r.CFrame.new(0,.5,0),r.CFrame.new(0,-.5,0))
 end
 local feet={}
 for _,side in {'Left','Right'} do
  local sign=if side=='Left' then -1 else 1
  if segmented then
   local upper=part(side..'UpperLeg',r.Vector3.new(.8,1,.8))
   local lower=part(side..'LowerLeg',r.Vector3.new(.8,1,.8))
   local foot=part(side..'Foot',r.Vector3.new(.8,.5,1))
   motor(side..'Hip',pelvis,upper,r.CFrame.new(sign*.5,-.5,0),r.CFrame.new(0,.5,0))
   motor(side..'Knee',upper,lower,r.CFrame.new(0,-.5,0),r.CFrame.new(0,.5,0))
   motor(side..'Ankle',lower,foot,r.CFrame.new(0,-.5,0),r.CFrame.new(0,.25,0))
   feet[side]=foot
  else
   local leg=part(side..' Leg',r.Vector3.new(1,2,1))
   local axis=r.CFrame.Angles(0,sign*math.pi/2,0)
   motor(side..' Hip',pelvis,leg,r.CFrame.new(sign,-1,0)*axis,r.CFrame.new(sign*.5,1,0)*axis)
   feet[side]=leg
  end
 end
 return root,joints,feet
end
for _,segmented in {false,true} do
 local root,joints,feet=bodyRig(segmented)
 local untouched=root.CFrame
 local baselineLeft,baselineRight=feet.Left.CFrame,feet.Right.CFrame
 for stance=4,6 do
  for _,m in joints do
   local offset=Handling.bodyPose(stance,m.Name:lower():gsub('%s',''),segmented)
   local transform=Handling.bodyTransform(m,r.CFrame.new(),offset)
   m.Part1.CFrame=m.Part0.CFrame*m.C0*transform*m.C1:Inverse()
  end
  check(root.CFrame==untouched,'Visual guard moved the root collision part')
  check(math.abs(feet.Left.CFrame.X-feet.Right.CFrame.X)>1.2,'Added guard did not widen the feet')
  for _,foot in feet do
   local bottom=math.huge
   for _,x in {-1,1} do for _,z in {-1,1} do
    bottom=math.min(bottom,foot.CFrame:PointToWorldSpace(r.Vector3.new(x*foot.Size.X*.5,-foot.Size.Y*.5,z*foot.Size.Z*.5)).Y)
   end end
   check(bottom>-.12 and bottom<.12,'Guard feet floated/clipped excessively: '..tostring(segmented)..' '..stance..' '..bottom)
  end
  for _,m in joints do
   local offset=Handling.bodyPose(1,m.Name:lower():gsub('%s',''),segmented)
   local transform=Handling.bodyTransform(m,r.CFrame.new(),offset)
   m.Part1.CFrame=m.Part0.CFrame*m.C0*transform*m.C1:Inverse()
  end
  check((feet.Left.CFrame.Position-baselineLeft.Position).Magnitude<.001 and (feet.Right.CFrame.Position-baselineRight.Position).Magnitude<.001,'Guard overlay accumulated into the walking pose')
 end
end
print('PASS added guard hand contacts, wide grounded stance, unchanged root collider and clean pose restoration')

print('RESULT '..checks..' combat-control, migration, presentation, faction and roaming checks passed')
