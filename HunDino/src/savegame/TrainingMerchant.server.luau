-- Connected lobby, training and hunting combat with a server-owned companion.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.TrainingConfig)
local Handling=Config.Controls.Handling(CFrame,Vector3)
local Rules = require(ReplicatedStorage.Shared.TrainingRules)
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Bow = require(ReplicatedStorage.Shared.BowBallistics)
local weaponTemplates = game:GetService("ServerStorage"):WaitForChild("TrainingWeapons")
local PetStanding = require(ReplicatedStorage.Shared:WaitForChild("PetStanding"))
local PetAnimator = require(ReplicatedStorage.Shared:WaitForChild("PetAnimator"))
local PetPlacement = require(ReplicatedStorage.Shared:WaitForChild("PetPlacement"))
local ArmorEquipment=require(ReplicatedStorage.Shared:WaitForChild("ArmorEquipment"))
local map = workspace:WaitForChild("HunDinoL0")
local forest = workspace:WaitForChild("HuntingRainforest")
local huntingConfig = require(ReplicatedStorage:WaitForChild("HuntingMapConfig"))
local huntingRuntime = game:GetService("ServerScriptService"):WaitForChild("HuntingRuntime")
local PetCombatRules = require(huntingRuntime:WaitForChild("PetCombatRules"))
local PetCompanionController = require(huntingRuntime:WaitForChild("PetCompanionController"))
local HuntQuestRules = require(huntingRuntime:WaitForChild("HuntQuestRules"))
local HuntQuestService = require(huntingRuntime:WaitForChild("HuntQuestService"))
local HuntEconomyService = require(huntingRuntime:WaitForChild("HuntEconomyService"))
local ProfileService=require(game.ServerScriptService:WaitForChild("AccountData"):WaitForChild("ProfileService"))
local profiles=ProfileService.new()
local states, owners, companionMemories = {}, {}, {}
local quests, economy
Players.RespawnTime = HuntQuestRules.Config.RespawnDelay
local hunting = require(huntingRuntime:WaitForChild("HuntingSession")).new(forest, huntingConfig,
	workspace:WaitForChild("Dinosaur01_TRex_Visual"), require(huntingRuntime:WaitForChild("DinosaurRouteController")))
local dinosaurCombat = require(huntingRuntime:WaitForChild("DinosaurCombat")).new(
	workspace:WaitForChild("Dinosaur01_TRex_Visual"), forest, huntingConfig, hunting, {
		DamagePets = function(cf, size, sequence, damage, sourceModel, targetUserId)
			local now = workspace:GetServerTimeNow()
			for _, s in states do
				if s.Companion and s.InHunting and not s.Travelling and s.Player.UserId==targetUserId then
					s.Companion:DamageInBite(cf, size, sequence, damage, sourceModel, now)
				end
			end
		end,
	})
hunting.Combat = dinosaurCombat
dinosaurCombat:Start()
local dummies = map.Training.Dummies
local remote = Instance.new("RemoteEvent")
remote.Name = "HunDinoTrainingAction"; remote.Parent = ReplicatedStorage
local pets = Instance.new("Folder"); pets.Name = "TrainingPets"; pets.Parent = workspace

local function makePart(parent, name, size, color, cf, anchored)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = color
	p.CFrame = cf; p.Anchored = anchored or false; p.CanCollide = false
	p.CanTouch = false; p.Massless = true; p.Material = Enum.Material.SmoothPlastic
	p.Parent = parent; return p
end
local function weld(a, b, offset)
	b.CFrame = a.CFrame * offset
	local w = Instance.new("Weld"); w.Part0 = a; w.Part1 = b; w.C0 = offset; w.Parent = b
	return w
end
local function alive(s)
	return s and s.Character and s.Character.Parent and s.Humanoid.Health > 0 and s.Root.Parent
end
local function grounded(s)
	return not s.Humanoid.Sit and not s.Root.Anchored
		and s.Humanoid.FloorMaterial ~= Enum.Material.Air
end
local function sync(s)
	local p = s.Player
	p:SetAttribute("Stamina", math.floor(s.Stamina + 0.5))
	p:SetAttribute("Drawn", s.Drawn)
	p:SetAttribute("Charging",s.Charge~=nil)
	p:SetAttribute("BowAiming",s.WeaponId=="Bow" and s.Drawn and (s.Aiming or s.Charge~=nil))
	p:SetAttribute("WeaponId", s.WeaponId)
 local faction=p:GetAttribute("CombatFaction") or (if p.Team then "Team:"..p.Team.Name else "Hunters")
 s.Character:SetAttribute("CombatFaction",faction);s.Character:SetAttribute("OwnerUserId",p.UserId)
 if s.Pet then s.Pet:SetAttribute("CombatFaction",faction);s.Pet:SetAttribute("OwnerUserId",p.UserId) end
	p:SetAttribute("PetWeaponId",s.PetWeaponId)
	p:SetAttribute("Blocking", s.Blocking)
	p:SetAttribute("BowBoost", s.BowBoostUntil > os.clock())
	p:SetAttribute("TrainingDamage", s.Damage)
	p:SetAttribute("PetDamage", s.PetDamage)
	p:SetAttribute("ComboStep", if os.clock() <= s.ComboUntil then s.ComboStep else 0)
	p:SetAttribute("ComboChain", if os.clock() <= s.ComboUntil then s.ComboChain or "" else "")
end
local function message(s, text)
	remote:FireClient(s.Player, "Message", text)
end
local function applyArmorTarget(s,target)
 local equipment=ArmorEquipment.read(s.Player,target)
 local model=if target=="Pet" then s.Pet else s.Character
 if model then
  local armor=ArmorEquipment.apply(model,target,equipment)
  if target=="Player" then
   s.Armor=armor
   local any=false;for _,id in equipment do if id~="None" then any=true;break end end
   s.Player:SetAttribute("TrainingArmor",any)
  end
 end
end
local function equipArmor(s,enabled)
 for _,slot in ArmorEquipment.Slots do
  local name="PlayerArmor_"..slot
  if not s.ArmorInitialized then
   if s.Player:GetAttribute(name)==nil then s.Player:SetAttribute(name,if enabled then "Training" else "None") end
  else s.Player:SetAttribute(name,if enabled then "Training" else "None") end
 end
 s.ArmorInitialized=true
 applyArmorTarget(s,"Player")
end
-- Both hands and the visible model use the same contact-based plan.
local function stowedWeaponPose(s, offhand, torso)
 local pose=Handling.mount(s.WeaponId,offhand,s.Player:GetAttribute("KatanaCarry") or 1,torso.Size)
 local arm=Handling.arm(s.Character,if (offhand and s.WeaponId~="DualDaggers") or Weapons[s.WeaponId].Ranged then "left" else "right")
 local grip=Handling.grip(s.WeaponId)
 return torso.CFrame:ToObjectSpace(Handling.reach(arm,torso.CFrame*pose*grip)*grip:Inverse())
end
local function heldWeaponPose(s, offhand, limb)
 local ranged=Weapons[s.WeaponId].Ranged==true
 local stance=s.Player:GetAttribute(if ranged then "RangedStance" else "MeleeStance") or 1
 local torso=s.Character:FindFirstChild("UpperTorso") or s.Character:FindFirstChild("Torso") or s.Root
 local arm=Handling.arm(s.Character,if offhand or ranged then "left" else "right")
 local goal=torso.CFrame*Handling.ready(s.WeaponId,offhand,stance,false,0)
 local grip=Handling.grip(s.WeaponId)
 return limb.CFrame:ToObjectSpace(Handling.reach(arm,goal*grip)*grip:Inverse())
end
local function clearDraw(s)
 s.DrawMotion=nil
 for _,tween in s.DrawTweens or {} do tween:Cancel() end
 s.DrawTweens={}
 if s.Character and s.Character.Parent then s.Character:SetAttribute("WeaponDrawTarget",nil) end
 s.Player:SetAttribute("WeaponHandling",false)
end
local function weaponPose(s)
 if not s.Grip or not s.Grip.Parent then return end
 clearDraw(s)
 local torso=s.Character:FindFirstChild("UpperTorso") or s.Character:FindFirstChild("Torso") or s.Root
 local left=s.Character:FindFirstChild("LeftHand") or s.Character:FindFirstChild("Left Arm") or torso
 local right=s.Character:FindFirstChild("RightHand") or s.Character:FindFirstChild("Right Arm") or torso
 local hand=if Weapons[s.WeaponId].Ranged then left else right
 local mount=stowedWeaponPose(s,false,torso)
 s.Grip.Part0=if s.Drawn then hand else torso
 s.RestPose=if s.Drawn then heldWeaponPose(s,false,hand) else mount
 s.Grip.C0=s.RestPose
 s.Character:SetAttribute("WeaponPresentationDrawn",s.Drawn==true)
 s.Character:SetAttribute("WeaponMainRestC0",s.RestPose)
 s.Character:SetAttribute("WeaponMainMountC0",mount)
 if s.OffGrip then
  s.OffGrip.Part0=if s.Drawn then left else torso
  s.OffRest=if s.Drawn then heldWeaponPose(s,true,left) else stowedWeaponPose(s,true,torso)
  s.OffGrip.C0=s.OffRest
  s.Character:SetAttribute("WeaponOffRestC0",s.OffRest)
  s.Character:SetAttribute("WeaponOffMountC0",stowedWeaponPose(s,true,torso))
 end
 if s.SheathGrip then
  s.SheathGrip.Part0=torso
  s.SheathGrip.C0=mount*CFrame.new(0,.72*Handling.scale(s.WeaponId),-.08*Handling.scale(s.WeaponId))
 end
 s.PresentationStance=s.Player:GetAttribute(if Weapons[s.WeaponId].Ranged then "RangedStance" else "MeleeStance") or 1
 local carry=s.Player:GetAttribute("KatanaCarry") or 1
 local strap=s.WeaponModel and s.WeaponModel:FindFirstChild("KatanaShoulderStrap")
 local strapWeld=strap and strap:FindFirstChildOfClass("Weld")
 if strapWeld then
  strap.Size=if carry==1 then Vector3.new(.14,torso.Size.X+.35,.08) else Vector3.new(.14,2.3,.08)
  strapWeld.C0=if carry==1 then CFrame.new(0,-torso.Size.Y*.5+.2,torso.Size.Z*.5+.14)*CFrame.Angles(0,0,math.pi/2) else CFrame.new(.2,0,torso.Size.Z*.5+.14)*CFrame.Angles(0,0,.48)
 end
 s.PresentationCarry=carry
end
local function animateDraw(s,target)
 local torso=s.Character:FindFirstChild("UpperTorso") or s.Character:FindFirstChild("Torso") or s.Root
 local left=s.Character:FindFirstChild("LeftHand") or s.Character:FindFirstChild("Left Arm") or torso
 local right=s.Character:FindFirstChild("RightHand") or s.Character:FindFirstChild("Right Arm") or torso
 local motion={Target=target,Started=os.clock(),Duration=Config.Controls.DrawSeconds,Grips={},Torso=torso}
 for _,entry in {{s.Grip,if Weapons[s.WeaponId].Ranged then left else right,false},{s.OffGrip,left,true}} do
  local grip,hand,offhand=entry[1],entry[2],entry[3]
  if grip and grip.Parent and grip.Part0 then
   grip.C0=torso.CFrame:ToObjectSpace(grip.Part0.CFrame*grip.C0);grip.Part0=torso
   table.insert(motion.Grips,{Grip=grip,Hand=hand,Offhand=offhand,Mount=stowedWeaponPose(s,offhand,torso)})
  end
 end
 s.DrawMotion=motion
 s.Character:SetAttribute("WeaponDrawTarget",target)
 s.Character:SetAttribute("WeaponDrawAt",workspace:GetServerTimeNow())
 s.Character:SetAttribute("WeaponDrawDuration",motion.Duration)
 s.Player:SetAttribute("WeaponHandling",true)
end
local function updatePresentation(s)
 local motion=s.DrawMotion
 if motion then
  if s.ChangeDraw~=motion.Target or not motion.Torso.Parent then clearDraw(s);return end
  local progress=math.clamp((os.clock()-motion.Started)/motion.Duration,0,1)
  local q=Handling.phase(progress,motion.Target)
  local stance=s.Player:GetAttribute(if Weapons[s.WeaponId].Ranged then "RangedStance" else "MeleeStance") or 1
  for _,entry in motion.Grips do
   local grip,hand=entry.Grip,entry.Hand
   if not grip.Parent or not hand.Parent then clearDraw(s);return end
   local ready=Handling.ready(s.WeaponId,entry.Offhand,stance,false,0)
   grip.C0=Handling.path(entry.Mount,ready,q,s.WeaponId,Handling.scale(s.WeaponId))
  end
  if s.WeaponId=="DualDaggers" and s.OffGrip then
   local first,second=motion.Grips[1],motion.Grips[2]
   local handoff=motion.Torso.CFrame:ToObjectSpace(Handling.handoff(Handling.arm(s.Character,"left"),Handling.arm(s.Character,"right"),motion.Torso.CFrame))
   local main,off=Handling.dual(first.Mount,second.Mount,Handling.ready(s.WeaponId,false,stance,false,0),Handling.ready(s.WeaponId,true,stance,false,0),handoff,CFrame.new(),CFrame.new(),q)
   s.Grip.C0=main;s.OffGrip.C0=off
  end
  if s.SheathGrip then
   s.SheathGrip.Part0=motion.Torso
   s.SheathGrip.C0=Handling.sheath(stowedWeaponPose(s,false,motion.Torso),s.Grip.C0,q,Handling.scale(s.WeaponId))
  end
  if progress>=1 then s.Drawn=motion.Target;s.ChangeDraw=nil;weaponPose(s);sync(s) end
 elseif os.clock()>=s.BusyUntil then
  local stance=s.Player:GetAttribute(if Weapons[s.WeaponId].Ranged then "RangedStance" else "MeleeStance") or 1
  local carry=s.Player:GetAttribute("KatanaCarry") or 1
  if stance~=s.PresentationStance or (not s.Drawn and carry~=s.PresentationCarry) then weaponPose(s) end
 end
end

local function createBowString(s,model)
 if s.WeaponId~="Bow" then return end
 local assembly=model:FindFirstChild("Main");local handle=assembly and assembly.PrimaryPart
 local original=assembly and assembly:FindFirstChild("BowString")
 if not handle or not original then return end
 original.Transparency=1
 local function attachment(name,position)
  local a=Instance.new("Attachment");a.Name=name;a.Position=position;a.Parent=handle;return a
 end
 local scale=Handling.scale("Bow")
 local upper=attachment("BowStringUpper",Vector3.new(1.15,2.45,0)*scale)
 local lower=attachment("BowStringLower",Vector3.new(1.15,-2.45,0)*scale)
 local nock=attachment("BowStringNock",Vector3.new(1.15,0,0)*scale)
 for _,endpoint in {upper,lower} do
  local beam=Instance.new("Beam");beam.Name="DrawnBowString";beam.Attachment0=endpoint;beam.Attachment1=nock
  beam.Width0=.025;beam.Width1=.025;beam.FaceCamera=true;beam.Color=ColorSequence.new(original.Color);beam.LightEmission=.8;beam.Parent=handle
 end
 local arrow=makePart(assembly,"BowHeldArrow",Vector3.new(.045,.045,1.8)*scale,Color3.fromRGB(176,145,93),handle.CFrame,false)
 arrow.CanQuery=false
 local seat=weld(handle,arrow,CFrame.new());seat.Name="ArrowSeat"
end

local function createCarryDetails(s,model)
 local torso=s.Character:FindFirstChild("UpperTorso") or s.Character:FindFirstChild("Torso") or s.Root
 local function attached(name,size,color,offset,parent)
  local part=makePart(parent or model,name,size,color,torso.CFrame*offset,false)
  part.CanQuery=false;weld(torso,part,offset);return part
 end
 if s.WeaponId=="Katana" then
  local sheath=model:FindFirstChild("Sheath")
  local scale=Handling.scale("Katana")
  local scabbard=sheath and sheath:FindFirstChild("Scabbard")
  if scabbard then
   scabbard.Size+=Vector3.new(.24*scale,.16*scale,.06*scale)
   for _,joint in scabbard:GetChildren() do
    if joint:IsA("Weld") and joint.Part1==scabbard then joint.C0*=CFrame.new(0,.08*scale,0) end
   end
  end
  for _,part in if sheath then sheath:GetChildren() else {} do
   if part:IsA("BasePart") then
    if part.Name=="Band" then part.Size=Vector3.new(.74*scale,part.Size.Y,.4*scale) end
    part.Color=if part.Name=="Band" then Color3.fromRGB(115,30,33) else Color3.fromRGB(25,28,32)
   end
  end
  attached("KatanaShoulderStrap",Vector3.new(.14,2.3,.08),Color3.fromRGB(34,30,29),CFrame.new(.2,0,torso.Size.Z*.5+.14)*CFrame.Angles(0,0,.48))
 elseif s.WeaponId=="Bow" then
  local quiver=Instance.new("Model");quiver.Name="Quiver";quiver.Parent=model
  local offset=CFrame.new(.75,-.5,torso.Size.Z*.5+.4)*CFrame.Angles(0,0,-.22)
  attached("QuiverBody",Vector3.new(.55,1.65,.4),Color3.fromRGB(53,38,27),offset,quiver)
  for i=1,4 do
   local arrow=offset*CFrame.new((i-2.5)*.1,.65,0)
   attached("QuiverArrow",Vector3.new(.035,1.7,.035),Color3.fromRGB(161,130,78),arrow,quiver)
   attached("QuiverFletching",Vector3.new(.13,.25,.05),Color3.fromRGB(199,188,152),arrow*CFrame.new(0,.58,0),quiver)
  end
 end
end

local function createWeapon(s)
	if s.WeaponModel then s.WeaponModel:Destroy() end
	s.OffGrip = nil; s.SheathGrip = nil
	local model = weaponTemplates[s.WeaponId]:Clone(); model.Name = "TrainingWeapon"
 model:ScaleTo(model:GetScale()*Handling.scale(s.WeaponId))
	for _, assembly in model:GetChildren() do
		local handle = assembly.PrimaryPart
		for _, p in assembly:GetChildren() do
			if p:IsA("BasePart") then
				p.Anchored = false; p.CanCollide = false; p.CanQuery = false; p.Massless = true
				if p ~= handle and not p:FindFirstChild("KatanaWeld") and not p:FindFirstChild("WeaponProWeld") then weld(handle,p,handle.CFrame:ToObjectSpace(p.CFrame)) end
			end
		end
		local grip = weld(s.Root,handle,CFrame.new())
		if assembly.Name == "Main" then s.Grip = grip elseif assembly.Name == "Offhand" then s.OffGrip = grip else s.SheathGrip = grip end
	end
	model.Parent = s.Character; s.WeaponModel = model; createBowString(s,model); createCarryDetails(s,model); weaponPose(s)
end
local function equipWeapon(s,id)
	if not Rules.canEquip(s,Weapons,id,os.clock()) then
		message(s,"Cất vũ khí bằng R và dừng động tác trước khi đổi trong bãi tập."); return
	end
	s.WeaponId=id; Rules.clearCombo(s); s.LastTarget=nil; s.BowBoostUntil=0; s.Aiming=false
	s.BusyUntil=os.clock()+.3; s.WantSprint=false
	createWeapon(s)
	sync(s); message(s,"Đã chọn "..Weapons[id].Name..". Nhấn R để rút.")
end
local function destroyPet(s)
	if s.Companion then s.Companion:Destroy(); s.Companion = nil end
	if s.PetAnimator then s.PetAnimator:Destroy(); s.PetAnimator = nil end
	if s.Pet then s.Pet:Destroy(); s.Pet = nil end
	s.PetTarget = nil
end
local function createPet(s)
	local pet, rig = PetStanding.build()
	pet.Name = "Pet_" .. s.Player.UserId
	pet.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local animator = PetAnimator.new(pet, rig, weaponTemplates)
	animator.RenderPose = false
	s.PetWeaponId=s.Player:GetAttribute("PetWeaponId") or s.WeaponId
 if not table.find(Weapons.Order,s.PetWeaponId) then s.PetWeaponId="Hammer" end
 animator:SetWeapon(s.PetWeaponId)
	pet:SetAttribute("PetWeaponId", s.PetWeaponId)
	pet:SetAttribute("PetMoving", false)
	pet:SetAttribute("PetSpeed", 1)
	pet:SetAttribute("PetAttackSequence", 0)
	pet:SetAttribute("PetAttackStarted", -1)
	PetPlacement.place(pet, s.Character, s.Root.CFrame, pets)
	pet.Parent = pets
	s.Pet, s.PetAnimator, s.PetClock = pet, animator, 0
 for _,slot in ArmorEquipment.Slots do
  if s.Player:GetAttribute("PetArmor_"..slot)==nil then s.Player:SetAttribute("PetArmor_"..slot,"Metal") end
 end
 applyArmorTarget(s,"Pet")
	local memory = companionMemories[s.Player]
	if not memory then memory = PetCombatRules.new(); companionMemories[s.Player] = memory end
 local account=profiles:Data(s.Player)
 if account then memory.HealReadyAt=math.max(memory.HealReadyAt,account.Pet.HealReadyAt) end
	s.Companion = PetCompanionController.new({
		Player = s.Player, Pet = pet, Character = s.Character, Humanoid = s.Humanoid, Root = s.Root,
		Animator = animator, Combat = dinosaurCombat, PetFolder = pets, Placement = PetPlacement,
		Remote = remote, Rules = PetCombatRules, Memory = memory,
		CanAct = function()
			return states[s.Player] == s and alive(s) and not s.Travelling
				and s.Player:GetAttribute("AdminFlying") ~= true and (s.InHunting or s.InTraining)
		end,
		IsEngaged = function()
			return s.InHunting and workspace:GetServerTimeNow() < (s.HuntEngagedUntil or 0)
				and dinosaurCombat:GetSnapshot().Health > 0
		end,
		OnDamage = function(applied, point)
			if applied > 0 and states[s.Player] == s then
				s.PetDamage += applied
				s.Player:SetAttribute("PetHuntingDamage", (s.Player:GetAttribute("PetHuntingDamage") or 0) + applied)
			end
		end,
	})
end
local function updateDummy(dummy)
	local gui = dummy.Target.SignGui.Text
	gui.Text = (dummy:GetAttribute("Label") or "HÌNH NỘM " .. dummy.Name:match("%d+")) .. "\n" .. dummy:GetAttribute("Health") .. " / " .. Config.DummyHealth
end
local function hit(s, dummy, damage, isPet)
	if not dummy:IsDescendantOf(dummies) then return end
	local hp = dummy:GetAttribute("Health")
	local applied = math.min(hp, damage)
	hp -= applied
	if isPet then s.PetDamage += applied else s.Damage += applied end
	-- Đây là hình nộm vô hạn, làm đầy lại khi bị hạ; không phát thưởng.
	dummy:SetAttribute("Health", if hp <= 0 then Config.DummyHealth else hp)
	updateDummy(dummy)
	remote:FireAllClients("Hit", dummy.Target.Position, applied, isPet)
	sync(s)
end
local function directionOK(v, ranged)
	return typeof(v) == "Vector3" and v.X == v.X and v.Y == v.Y and v.Z == v.Z
		and math.abs(v.X) < 2 and math.abs(v.Z) < 2 and math.abs(v.Y) < (if ranged then 2 else .01) and v.Magnitude > 0.5
end
local function lineOfSight(s, pos, dummy)
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {s.Character, pets}
	local result = workspace:Raycast(s.Root.Position, pos - s.Root.Position, params)
	return not result or result.Instance:IsDescendantOf(dummy)
end
local function readBowAim(s, value)
	local direction = if typeof(value)=="table" then value.Direction else value
	if not directionOK(direction, true) then return nil end
	local target = if typeof(value)=="table" and Bow.validTarget(value.Target, Bow.origin(s.Root.Position)) then value.Target else nil
	return direction.Unit, target
end
local function startPetAttack(s, target)
	local animator = s.PetAnimator
	if not animator or animator:IsAttacking() then return end
	s.PetTarget = target
	local count = animator:GetHitCount()
	animator.OnHit = function(index)
		if not alive(s) or states[s.Player] ~= s or not s.InTraining or s.PetTarget ~= target
			or s.LastTarget ~= target or not target:IsDescendantOf(dummies)
			or os.clock() >= (s.TargetUntil or 0) then return end
		local point = target.Target.Position
		local center = s.Pet.PrimaryPart.Position + Vector3.new(0, 2, 0)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {s.Character, pets}
		local obstruction = workspace:Raycast(center, point - center, params)
		if (center - point).Magnitude > 7 or (s.Root.Position - point).Magnitude >= 18
			or (obstruction and not obstruction.Instance:IsDescendantOf(target)) then return end
		-- Split the original total damage across the two dagger strikes.
		local amount = math.floor(Config.PetDamage / count)
			+ (if index <= Config.PetDamage % count then 1 else 0)
		hit(s, target, amount, true)
		if s.PetWeaponId == "Bow" then remote:FireAllClients("Shot", center, point, false) end
	end
	if animator:Attack() then
		s.PetClock = os.clock() + Config.PetInterval
		s.Pet:SetAttribute("PetAttackStarted", workspace:GetServerTimeNow())
		s.Pet:SetAttribute("PetAttackSequence", s.Pet:GetAttribute("PetAttackSequence") + 1)
	end
end
local function attack(s, action, direction, releasedKind, releasedSpec, targetPoint)
	local weapon=Weapons[s.WeaponId]
	if not (s.InTraining or s.InHunting) or not directionOK(direction,weapon.Ranged) then return end
	local now = os.clock()
	local kind,spec=releasedKind,releasedSpec
	if not kind then kind,spec=Rules.attack(Config,Weapons,s,action,now) end
	if not kind then return end
 s.Character:SetAttribute("WeaponAttackAt",workspace:GetServerTimeNow())
 s.Character:SetAttribute("WeaponAttackDuration",spec.Duration)
 s.Character:SetAttribute("WeaponAttackStyle",spec.Style or "Swing")
	local attackDamage=spec.Damage*(if economy then economy:DamageMultiplier(s.Player,s.WeaponId) else 1)
	direction = direction.Unit
	local flat=Vector3.new(direction.X,0,direction.Z)
	if not weapon.Ranged and flat.Magnitude>.01 then s.Root.CFrame = CFrame.lookAt(s.Root.Position, s.Root.Position + flat) end
	s.Humanoid.AutoRotate = if weapon.Ranged then not s.Aiming else false
	local character = s.Character
	local boosted=weapon.Ranged and now<s.BowBoostUntil
	if weapon.Ranged then s.BowBoostUntil=0 end
	s.WeaponModel:SetAttribute("WeaponAttackStarted", workspace:GetServerTimeNow())
	s.WeaponModel:SetAttribute("WeaponAttackDuration", spec.Duration)
	s.WeaponModel:SetAttribute("WeaponAttackWindup", spec.Windup)
	s.WeaponModel:SetAttribute("WeaponAttackHits", (if weapon.Ranged then spec.Shots else spec.Hits) or 1)
	s.WeaponModel:SetAttribute("WeaponAttackHitInterval", (if weapon.Ranged then spec.ShotInterval else spec.HitInterval) or (if weapon.Ranged then (if s.InHunting then .09 else 0) else 0.13))
	s.WeaponModel:SetAttribute("WeaponAttackSequence", (s.WeaponModel:GetAttribute("WeaponAttackSequence") or 0) + 1)
	remote:FireClient(s.Player, "Attack", kind, spec.Name, spec.Duration)
	-- A serial prevents a late recovery callback from overwriting the next strike.
	s.AttackSerial=(s.AttackSerial or 0)+1; local serial=s.AttackSerial
	local attackToken=tostring(s.Player.UserId)..":"..string.format("%.6f",workspace:GetServerTimeNow())..":"..serial
	local function forestHit(applied,point)
		if applied>0 then
			s.HuntEngagedUntil = workspace:GetServerTimeNow() + 25
			s.Player:SetAttribute("HuntingDamage",(s.Player:GetAttribute("HuntingDamage") or 0)+applied)
			remote:FireAllClients("Hit",point,applied,false)
		end
	end
	local windup = s.RestPose * CFrame.Angles(math.rad(100), 0, math.rad(-30))
	if spec.Style=="Thrust" then windup=s.RestPose*CFrame.new(0,0,.7)*CFrame.Angles(math.pi/2,0,0)
	elseif spec.Style=="Spin" or spec.Style=="Sweep" then windup=s.RestPose*CFrame.Angles(0,-1.4,math.pi/2) end
	if weapon.Ranged then windup=s.RestPose*CFrame.new(0,0,.25) end
	TweenService:Create(s.Grip, TweenInfo.new(spec.Windup), {C0 = windup}):Play()
	task.delay(spec.Windup, function()
		if not alive(s) or s.Character ~= character or states[s.Player] ~= s or s.AttackSerial~=serial then return end
		if weapon.Ranged then
			TweenService:Create(s.Grip,TweenInfo.new(.16),{C0=s.RestPose}):Play()
			local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances={s.Character,pets}
			for i=1,spec.Shots or 1 do
				if i>1 and (spec.ShotInterval or s.InHunting) then task.wait(spec.ShotInterval or .09) end
				if not alive(s) or s.Character~=character or states[s.Player]~=s or s.AttackSerial~=serial then return end
				local origin=Bow.origin(s.Root.Position)
				local target=if s.Aiming and os.clock()-(s.BowTargetAt or 0)<.35 then s.BowTarget else targetPoint
				local shotDirection=Bow.direction(origin,target,direction)
				local angle=math.rad(math.ceil((i-1)/2)*(if i%2==0 then -1 else 1)*(spec.Spread or 4))
				local aim=CFrame.fromAxisAngle(Vector3.yAxis,angle):VectorToWorldSpace(shotDirection)
				local result=workspace:Raycast(origin,aim*spec.Range,params)
				local endpoint=if result then result.Position else origin+aim*spec.Range
				remote:FireAllClients("Shot",origin,endpoint,boosted and i==1)
				if result then
					if s.InHunting and dinosaurCombat:FromRayHit(result.Instance) then
						local amount=math.floor(attackDamage*(if boosted and i==1 then 1.25 else 1)+.5)
						if dinosaurCombat:CanHit(s.Player,result.Position,spec.Range+2) then
							forestHit(dinosaurCombat:Damage(s.Player,amount,result.Position,attackToken..":arrow:"..i,"Projectile"),result.Position)
						end
					end
					for _,dummy in dummies:GetChildren() do if s.InTraining and result.Instance:IsDescendantOf(dummy) then
						hit(s,dummy,math.floor(attackDamage*(if boosted and i==1 then 1.25 else 1)+.5),false); s.LastTarget=dummy; s.TargetUntil=os.clock()+12
						break
					end end
				end
			end
			return
		end
		for n=1,spec.Hits or 1 do
			if n>1 then task.wait(spec.HitInterval or .13) end
			if not alive(s) or s.Character~=character or states[s.Player]~=s or s.AttackSerial~=serial then return end
			local pose=s.RestPose*CFrame.Angles(math.rad(-95),0,if n%2==0 then -.4 else .4)
			if spec.Style=="Thrust" then pose=s.RestPose*CFrame.new(0,0,-2)*CFrame.Angles(math.pi/2,0,0)
			elseif spec.Style=="Spin" or spec.Style=="Sweep" then pose=s.RestPose*CFrame.Angles(0,if n%2==0 then -1.5 else 1.5,math.pi/2) end
			TweenService:Create(s.Grip, TweenInfo.new(.1), {C0=pose}):Play()
			if spec.Style=="Shield" and s.OffGrip then TweenService:Create(s.OffGrip,TweenInfo.new(.1),{C0=s.OffRest*CFrame.new(.4,.3,-1.2)}):Play() end
			if spec.Name then remote:FireAllClients("ComboFX",s.Root.CFrame,spec.Style,spec.Range) end
			if s.OffGrip and s.WeaponId=="DualDaggers" then TweenService:Create(s.OffGrip,TweenInfo.new(.1),{C0=s.OffRest*CFrame.Angles(-1.5,0,if n%2==0 then .4 else -.4)}):Play() end
			if s.InHunting then
				local applied,point=dinosaurCombat:MeleeStrike(s.Player,s.Root.Position+Vector3.new(0,.8,0),direction,
					spec.Range,spec.Arc or .3,attackDamage,attackToken..":melee:"..n)
				if applied>0 then forestHit(applied,point) end
			end
			for _, dummy in dummies:GetChildren() do
				local delta = dummy.Target.Position - s.Root.Position
				local targetFlat = Vector3.new(delta.X, 0, delta.Z)
				if s.InTraining and delta.Magnitude <= spec.Range and targetFlat.Magnitude > 0 and direction:Dot(targetFlat.Unit) >= (spec.Arc or .3)
					and lineOfSight(s, dummy.Target.Position, dummy) then
					hit(s, dummy, attackDamage, false); s.LastTarget = dummy; s.TargetUntil = now + 12
				end
			end
		end
	end)
	task.delay(spec.Duration, function()
		if states[s.Player] ~= s or not alive(s) or s.Character ~= character or s.AttackSerial~=serial then return end
		TweenService:Create(s.Grip, TweenInfo.new(0.12), {C0 = s.RestPose}):Play()
		if s.OffGrip then TweenService:Create(s.OffGrip,TweenInfo.new(.12),{C0=s.OffRest}):Play() end
		s.Humanoid.AutoRotate = true
	end)
	sync(s)
end
local function cancelCharge(s)
 if Rules.cancelCharge(s,os.clock()) then
  weaponPose(s);s.Humanoid.AutoRotate=true;s.Character:SetAttribute("ChargePose",nil)
  remote:FireClient(s.Player,"ChargeStop");sync(s)
 end
end
local function releaseCharge(s,direction,targetPoint)
 if not s.Charge then return end
 if not alive(s) or not (s.InTraining or s.InHunting) then cancelCharge(s);return end
 local c=s.Charge;local aim=if directionOK(direction,true) then direction else c.Direction
 local kind,spec=Rules.releaseCharge(Config,s,os.clock())
 s.Character:SetAttribute("ChargePose",nil);weaponPose(s)
 remote:FireClient(s.Player,"ChargeStop");attack(s,c.Action,aim,kind,spec,targetPoint or c.Target)
end
local function toggleDraw(s, target)
	if os.clock() < s.BusyUntil then return end
	s.BusyUntil = os.clock() + ((Config.Controls and Config.Controls.DrawSeconds) or .62); Rules.clearCombo(s); s.Sprinting = false
	s.Blocking=false; s.BowBoostUntil=0; s.Aiming=false; weaponPose(s)
	s.ChangeDraw = target
	animateDraw(s,target)
	message(s, (if target then "Đang rút " else "Đang cất ")..Weapons[s.WeaponId].Name.."…")
end
local function travel(s, destination, arrivalOverride, arrivalMessage, force)
	if not alive(s) or s.Travelling then return false end
	if not force and os.clock() < s.BusyUntil then return false end
	if quests then
		if destination == "Hunting" then
			local permitted, reason = quests:CanEnter(s.Player)
			if not permitted then message(s, reason); return false end
		end
		if not quests:BeforeTravel(s.Player, destination) then return false end
	end
	local wasHunting = s.InHunting
	s.Player:SetAttribute("AdminFlying",false)
	if s.Companion then s.Companion:Cancel("Travel") end
	s.HuntEngagedUntil = nil
	cancelCharge(s)
	s.AttackSerial = (s.AttackSerial or 0) + 1
	s.Drawn = false; s.WantSprint = false; s.Sprinting = false
	s.ChangeDraw = nil; Rules.clearCombo(s); s.LastTarget = nil; s.BusyUntil = os.clock() + 0.5
	s.Blocking=false; s.Aiming=false; s.BowBoostUntil=0; s.DodgingUntil=nil; s.BaseTransitUntil=nil
	for _, name in {"DodgeVelocity", "DodgeAttachment"} do local old=s.Root:FindFirstChild(name);if old then old:Destroy() end end
	s.Humanoid.AutoRotate = true; weaponPose(s)
	local cf = arrivalOverride or (if destination == "Hunting" then forest.Camp.CampArrival.CFrame
		elseif destination == "Training" then map.Training.Arrival.CFrame
		else map.Lobby.Arrival.CFrame)
	s.Travelling = true
 local before = s.Character
 s.BusyUntil = math.huge
 pcall(function() s.Player:RequestStreamAroundAsync(cf.Position, 3) end)
 s.Travelling = false
 if not alive(s) or states[s.Player] ~= s or s.Character ~= before then return false end
 s.BusyUntil = os.clock() + 0.5
 s.Character:PivotTo(cf); s.Root.AssemblyLinearVelocity = Vector3.zero; s.Root.AssemblyAngularVelocity=Vector3.zero
	s.PetAnimator:CancelAttack(); s.PetTarget = nil
	s.Pet:SetAttribute("PetAttackStarted", -1)
	PetPlacement.place(s.Pet, s.Character, cf, pets)
	if destination == "Hunting" then hunting:Enter(s.Player) else hunting:Exit(s.Player) end
	s.InTraining = destination == "Training"; s.InHunting = destination == "Hunting"
	s.Player:SetAttribute("InTraining", s.InTraining)
	s.Player:SetAttribute("Area", destination)
	if s.Companion and (destination=="Lobby" or (destination=="Hunting" and not wasHunting)) then
		s.Companion:ResetForArea(workspace:GetServerTimeNow())
	end
	message(s, arrivalMessage or (if s.InHunting then "Đã tới Thung Lũng Sương Xám cùng Pet. Về sảnh bằng menu Chơi hoặc cổng ở trạm kiểm lâm."
		elseif s.InTraining then "Nhấn I chọn vũ khí, R để rút. Cận chiến bên trái, cung bên phải." else "Đã trở về trại thợ săn."))
	sync(s)
	return true
end
quests = HuntQuestService.new({
	Rules = HuntQuestRules, Session = hunting, Combat = dinosaurCombat, Forest = forest,
	Map = map, PetFolder = pets, Remote = remote,
	GetState = function(player) return states[player] end,
	Message = function(player, text) if player.Parent then remote:FireClient(player, "Message", text) end end,
	Travel = function(player, destination, arrival, text)
		local s = states[player]; return if s then travel(s, destination, arrival, text, true) else false
	end,
	OnResult = function(player)
		local s = states[player]; if not s then return end
		cancelCharge(s); s.AttackSerial = (s.AttackSerial or 0) + 1
		s.HuntEngagedUntil = nil
		if s.Companion then s.Companion:Cancel("QuestResult") end
	end,
})
economy=HuntEconomyService.new({Map=map,Persistence=profiles,GetState=function(p) return states[p] end,GetQuest=function() return quests end,
	Message=function(p,text) if p.Parent then remote:FireClient(p,"Message",text) end end})
quests.Economy=economy
dinosaurCombat.OnDamage=function(p,beforeHP,afterHP) quests:ObserveDamage(p,beforeHP,afterHP) end
local function bindPrompt(part, callback)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	prompt.Triggered:Connect(function(player)
		local s = states[player]
		-- Prompt vẫn phải được xác minh trên server.
		if not alive(s) or (s.Root.Position - part.Position).Magnitude > 12 or os.clock() < s.BusyUntil then return end
		callback(s)
	end)
end
local transit=map:WaitForChild("BaseTransit")
local function transitReady(s)
 if s.Travelling or s.InTraining or s.InHunting or s.Drawn or s.Charge or s.Blocking or s.Sprinting or os.clock()<s.BusyUntil then
  message(s,"Cất vũ khí và dừng động tác trước khi dịch chuyển.");return false
 end
 return true
end
bindPrompt(transit.Center.Pad,function(s)
 if not transitReady(s) then return end
 local rows={}
 for id=1,Config.LobbyCapacity do rows[id]={Owner=if owners[id] then owners[id].DisplayName else "Chưa có chủ"} end
 s.BaseTransitUntil=os.clock()+60
 remote:FireClient(s.Player,"BaseTransitOpen",{Bases=rows,Origin=transit.Center.Pad.Position})
end)
for id=1,Config.LobbyCapacity do
 bindPrompt(transit.Bases["Base"..id].Pad,function(s)
  if transitReady(s) then travel(s,"Lobby",transit.Center.Arrival.CFrame,"Đã về sảnh trung tâm.") end
 end)
end
local function selectBaseTransit(s,id)
 if typeof(id)~="number" or id~=id or id%1~=0 or id<1 or id>Config.LobbyCapacity then return end
 if os.clock()>(s.BaseTransitUntil or 0) or (s.Root.Position-transit.Center.Pad.Position).Magnitude>12 or not transitReady(s) then return end
 s.BaseTransitUntil=nil
 travel(s,"Lobby",transit.Bases["Base"..id].Arrival.CFrame,string.format("Đã đến Base %02d.",id))
end
bindPrompt(map.Lobby.ToTraining, function(s) travel(s, "Training") end)
bindPrompt(map.Training.ToLobby, function(s) travel(s, "Lobby") end)
bindPrompt(map.HuntingTransit.ToHunting, function(s)
	if s.InHunting or s.InTraining then return end
	if transitReady(s) then travel(s, "Hunting") end
end)
bindPrompt(forest.Camp.ReturnToLobby, function(s)
	if not s.InHunting then return end
	if s.Drawn or s.Charge or s.Blocking or s.Sprinting then message(s,"Cất vũ khí và dừng động tác trước khi về sảnh.");return end
	travel(s, "Lobby")
end)
bindPrompt(map.Training.EquipmentRack, function(s)
	if s.Drawn then message(s, "Cất vũ khí bằng R trước khi thay giáp."); return end
	equipArmor(s, not s.Player:GetAttribute("TrainingArmor")); s.BusyUntil = os.clock() + 0.3
end)
bindPrompt(map.Training.ResetPost, function(s)
	if s.Drawn then message(s, "Cất vũ khí bằng R trước khi tương tác."); return end
	s.Damage = 0; s.PetDamage = 0; s.Stamina = Config.MaxStamina; Rules.clearCombo(s); s.LastTarget = nil
	s.Humanoid.Health = s.Humanoid.MaxHealth; s.BusyUntil = os.clock() + 0.3; sync(s)
	message(s, "Đã xóa thống kê của bạn. Bắt đầu lượt tập mới!")
end)
for _,rack in map.Training.WeaponRacks:GetChildren() do
	bindPrompt(rack,function(s) equipWeapon(s,rack.Name) end)
end
local function equipInventory(s,value)
 if typeof(value)~="table" or (value.Target~="Player" and value.Target~="Pet")
  or (value.Kind~="Weapons" and value.Kind~="Armor") then return end
 if not (s.InTraining or s.InHunting) or s.Drawn or s.Charge or s.Blocking or s.Sprinting or os.clock()<s.BusyUntil then
  message(s,"Trang bị ở bãi tập hoặc khu săn khi đã cất vũ khí và dừng động tác.");return
 end
 if value.Kind=="Weapons" then
  if typeof(value.Id)~="string" or not table.find(Weapons.Order,value.Id) then return end
  if value.Target=="Player" then equipWeapon(s,value.Id)
  else
   s.PetWeaponId=value.Id;s.PetTarget=nil;s.PetAnimator:SetWeapon(value.Id)
   s.Pet:SetAttribute("PetWeaponId",value.Id);s.Pet:SetAttribute("PetAttackStarted",-1)
   s.BusyUntil=os.clock()+.3;sync(s);message(s,"Pet đã trang bị "..Weapons[value.Id].Name..".")
  end
 else
  if typeof(value.Slot)~="string" or typeof(value.Id)~="string" or not ArmorEquipment.valid(value.Slot,value.Id) then return end
  s.Player:SetAttribute(value.Target.."Armor_"..value.Slot,value.Id)
  applyArmorTarget(s,value.Target);s.BusyUntil=os.clock()+.2;sync(s)
  message(s,(if value.Target=="Pet" then "Pet: " else "Người: ")..ArmorEquipment.SlotNames[value.Slot].." • "..(if value.Id=="None" then "Đã tháo" else ArmorEquipment.Sets[value.Id].Name))
 end
end

local function weaponHotkey(s,slot)
 if typeof(slot)~="number" or slot~=slot or slot%1~=0 or slot<1 or slot>7 or slot>#Weapons.Order
  or not (s.InTraining or s.InHunting) or s.Travelling then return end
 local id=Weapons.Order[slot]
 if s.WeaponId==id then return end
 if s.Drawn or s.ChangeDraw~=nil or s.Charge or os.clock()<s.BusyUntil then
  message(s,"Nhấn R cất vũ khí và hoàn tất động tác trước khi chọn ô khác.");return
 end
 s.WeaponHotkeyGeneration=(s.WeaponHotkeyGeneration or 0)+1
 equipWeapon(s,id)
end

remote.OnServerEvent:Connect(function(player, action, value)
	local s = states[player]
	if not alive(s) or typeof(action) ~= "string" then return end
 if profiles.Stopped or not profiles:CanPlay(player) then
  if action~="ChargeCancel" and not ((action=="Sprint" or action=="Aim" or action=="Guard") and value==false) then return end
 end
	if player:GetAttribute("AdminFlying")==true and action~="TravelMenu"
		and not ((action=="Sprint" or action=="Aim" or action=="Guard") and value==false)
		and action~="ChargeCancel" then return end
	local now = os.clock()
	-- Giới hạn cả request không hợp lệ trước khi xử lý trạng thái.
	if now - s.PacketWindow >= 1 then s.PacketWindow = now; s.Packets = 0 end
	s.Packets += 1; if s.Packets > 30 then return end
	if action=="QuestBoard" or action=="QuestAccept" or action=="QuestReturnEarly" or action=="QuestDismissResult"
		or action=="TrapPlaceStart" or action=="CaptureStart" or action=="QuestActionCancel" then
		if value~=nil then return end
		if action=="QuestBoard" then quests:OpenBoard(player)
		elseif action=="QuestAccept" then quests:Accept(player)
		elseif action=="QuestReturnEarly" or action=="QuestDismissResult" then quests:Return(player)
		else quests:ItemAction(player,action) end
		return
	end
	if action~="BowAim" and action~="ChargeAim" and action~="ChargeCancel" and action~="PetHeal" then
		quests:CancelAction(player,"Interrupted")
	end
	if action=="BaseTransitSelect" then selectBaseTransit(s,value)
 elseif action=="PetHeal" then
  -- The client chooses no recipient, heal amount, position or cooldown.
  if value~=nil or not s.Companion or player:GetAttribute("HuntCaptureActive")==true then return end
  if now-(s.LastPetHealRequest or -math.huge)<.35 then return end
  s.LastPetHealRequest=now
  local ok,reason=s.Companion:RequestHeal(workspace:GetServerTimeNow())
  if not ok then
   local reasons={Stunned="Pet đang hồi phục.",Cooldown="Kỹ năng hồi của Pet chưa sẵn sàng.",
    FullHealth="Máu đã đầy, chưa cần Pet hồi.",Busy="Pet đang thực hiện lệnh hồi.",
    Unavailable="Vào khu săn hoặc bãi tập để gọi Pet hồi.",InvalidHealth="Chưa thể hồi máu lúc này."}
   message(s,reasons[reason] or "Chưa thể gọi Pet hồi lúc này.")
  end
 elseif action=="WeaponHotkey" then weaponHotkey(s,value)
 elseif action=="EquipInventory" then equipInventory(s,value)
 elseif action=="ChargeStart" then
  if typeof(value)~="table" or typeof(value.Id)~="number" or value.Id~=value.Id or value.Id<=0 or value.Id%1~=0 or value.Id>1e9 or not (s.InTraining or s.InHunting) then return end
  if not directionOK(value.Direction,true) then remote:FireClient(player,"ChargeRejected",value.Id);return end
  local c=Rules.beginCharge(Config,Weapons,s,value.Action,now)
  if not c then remote:FireClient(player,"ChargeRejected",value.Id);return end
  c.Id=value.Id;c.Action=value.Action;c.Direction=value.Direction.Unit
  c.Target=if Bow.validTarget(value.Target,Bow.origin(s.Root.Position)) then value.Target else nil
  s.AttackSerial=(s.AttackSerial or 0)+1;s.WantSprint=false;s.Sprinting=false;s.Humanoid.AutoRotate=not s.Aiming
  s.Character:SetAttribute("ChargePose","Bow");s.Character:SetAttribute("WeaponChargeAt",workspace:GetServerTimeNow());s.Character:SetAttribute("WeaponChargeDuration",s.Charge.Time)
  TweenService:Create(s.Grip,TweenInfo.new(.18),{C0=s.RestPose*CFrame.new(0,0,.25)}):Play()
  remote:FireClient(player,"ChargeStart",c.Time,c.Id);sync(s)
 elseif action=="ChargeAim" or action=="BowAim" then
  if s.WeaponId~="Bow" or not s.Drawn or not (s.InTraining or s.InHunting) then return end
  if now-(s.LastBowAimPacket or -math.huge)<.05 then return end
  local direction,target=readBowAim(s,value)
  if direction then
   s.LastBowAimPacket=now;s.BowTarget=target;s.BowTargetAt=now
   if s.Charge then s.Charge.Direction=direction;s.Charge.Target=target end
  end
 elseif action=="ChargeRelease" then
  if typeof(value)=="table" and s.Charge and value.Id==s.Charge.Id then releaseCharge(s,value.Direction,value.Target) end
 elseif action=="ChargeCancel" then cancelCharge(s)
 elseif action == "EquipWeapon" then
		equipWeapon(s,value)
	elseif action == "TravelMenu" then
		if value~="Training" and value~="Lobby" and value~="Hunting" then return end
		if s.Travelling or s.Drawn or s.Charge or s.Blocking or now<s.BusyUntil or s.Sprinting then
			message(s,"Cất vũ khí và dừng động tác trước khi chuyển khu."); return
		end
		if value=="Hunting" then
			if s.InHunting then message(s,"Bạn đang ở Thung Lũng Sương Xám.");return end
			if s.InTraining or (s.Root.Position-map.Lobby.Arrival.Position).Magnitude>160 then
				message(s,"Về sảnh trung tâm rồi chọn vào Thung Lũng Sương Xám.");return
			end
		elseif value=="Training" and s.InHunting then
			message(s,"Về sảnh trước khi vào bãi luyện tập.");return
		end
		travel(s,value)
	elseif action == "Aim" then
		s.Aiming=value==true and s.WeaponId=="Bow" and s.Drawn
	elseif action == "Guard" then
		if value==false then s.Blocking=false; weaponPose(s)
		elseif value==true and s.WeaponId=="SwordShield" and s.Drawn and now>=s.BusyUntil and s.Stamina>0 then
			s.Blocking=true; s.Sprinting=false; s.WantSprint=false; Rules.clearCombo(s); weaponPose(s)
		end
		sync(s)
	elseif action == "Sprint" then
		if typeof(value) ~= "boolean" then return end
		if value then cancelCharge(s) end
		s.WantSprint = value; if value then Rules.clearCombo(s); s.Blocking=false; weaponPose(s) end
		if not value then s.Sprinting = false end
	elseif action == "Draw" then
		s.WeaponHotkeyGeneration=(s.WeaponHotkeyGeneration or 0)+1
		if s.Charge then cancelCharge(s);s.BusyUntil=now end
		s.WantSprint = false; toggleDraw(s, not s.Drawn)
	elseif action == "Light" or action == "Heavy" or action == "Skill" then
		if s.WeaponId=="Bow" then
			local direction,target=readBowAim(s,value)
			if direction then attack(s,action,direction,nil,nil,target) end
		else attack(s, action, value) end
	elseif action == "Jump" and not s.Blocking and now >= s.BusyUntil and grounded(s) and now - s.LastJumpAt >= 0.45 then
		Rules.clearCombo(s); s.LastJumpAt = now; s.BusyUntil = now + 0.15
		remote:FireClient(player, "Jump", s.Character)
	elseif action == "Dodge" and not s.Blocking and directionOK(value) and now >= s.BusyUntil and grounded(s)
		and now - s.LastJumpAt >= 0.45 and Rules.dodge(Config,Weapons,s,now) then
		remote:FireClient(player,"Dodge",Config.DodgeTime)
		s.Humanoid.WalkSpeed=Config.WalkSpeed
		if s.WeaponId=="Bow" and s.Drawn and s.Aiming then s.BowBoostUntil=now+4 end
		local a = Instance.new("Attachment"); a.Name = "DodgeAttachment"; a.Parent = s.Root
		local velocity = Instance.new("LinearVelocity"); velocity.Name = "DodgeVelocity"; velocity.Attachment0 = a
		velocity.RelativeTo = Enum.ActuatorRelativeTo.World; velocity.MaxForce = 100000
		-- Constrain only the ground plane; gravity must remain free on slopes/edges.
		velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
		velocity.PrimaryTangentAxis = Vector3.xAxis; velocity.SecondaryTangentAxis = Vector3.zAxis
		local direction = value.Unit
		s.Character:SetAttribute("DarkStepDuration",Config.DodgeTime)
		s.Character:SetAttribute("DarkStepDirection",direction)
		s.Character:SetAttribute("DarkStepStarted",workspace:GetServerTimeNow())
		s.Character:SetAttribute("DarkStepSequence",(s.Character:GetAttribute("DarkStepSequence") or 0)+1)
		velocity.PlaneVelocity = Vector2.new(direction.X, direction.Z) * Config.DodgeSpeed
		velocity.Parent = s.Root
		-- Ease toward walking speed instead of an abrupt full-speed stop.
		TweenService:Create(velocity,TweenInfo.new(Config.DodgeTime,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
			{PlaneVelocity=Vector2.new(direction.X,direction.Z)*Config.WalkSpeed}):Play()
		local root=s.Root; local character=s.Character
		task.delay(Config.DodgeTime, function()
			velocity:Destroy(); a:Destroy()
			if not alive(s) or s.Character~=character then return end
			local move=s.Humanoid.MoveDirection
			local residual=if move.Magnitude>.1 then move*Config.WalkSpeed else direction*4
			root.AssemblyLinearVelocity=Vector3.new(residual.X,root.AssemblyLinearVelocity.Y,residual.Z)
		end)
		sync(s)
	end
end)
local function baseSign(id, text)
	local part = map.BaseSigns:FindFirstChild("Base" .. id)
	part.SignGui.Text.Text = string.format("BASE %02d\n%s", id, text)
end
local baseRandom=Random.new()
local function chooseFreeBase()
	local candidates={}
	for id=1,Config.LobbyCapacity do candidates[id]=id end
	while #candidates>0 do
		local index=baseRandom:NextInteger(1,#candidates)
		local id=table.remove(candidates,index)
		if not owners[id] then return id end
	end
	return nil
end
local initializedPlayers={}
local function setup(player)
 if initializedPlayers[player] or not player.Parent then return end
	local baseId=player:GetAttribute("BaseId") or chooseFreeBase()
	if not baseId then player:Kick("Trại đã đủ 12 người. Hãy vào máy chủ khác."); return end
	owners[baseId] = player; player:SetAttribute("BaseId", baseId); baseSign(baseId, player.DisplayName)
 if not profiles:Load(player) or initializedPlayers[player] or not player.Parent then return end
 initializedPlayers[player]=true
	economy:Register(player)
	local function characterAdded(character)
		local old = states[player]; if old then destroyPet(old) end
		local resume = quests:ShouldResume(player)
		if not resume then hunting:Exit(player); player:SetAttribute("Area", "Lobby") end
		player.RespawnLocation = map.Lobby.LobbySpawn
		local humanoid = character:WaitForChild("Humanoid")
		local rootPart = character:WaitForChild("HumanoidRootPart")
		if player.Character ~= character or not player.Parent then return end
		local s = {
			Player = player, Character = character, Humanoid = humanoid, Root = rootPart,
			Stamina = Config.MaxStamina, LastSpend = 0, BusyUntil = 0, Drawn = false,
			ComboStep = 0, ComboUntil = 0, Damage = 0, PetDamage = 0, InTraining = false, InHunting = resume,
			WantSprint = false, Sprinting = false, PacketWindow = 0, Packets = 0, LastJumpAt = -math.huge,
			WeaponId=player:GetAttribute("WeaponId") or "Hammer", Blocking=false, Aiming=false, BowBoostUntil=0,
		}
		states[player] = s
		player:SetAttribute("InTraining", false)
		player:SetAttribute("HuntingDamage",0)
		if player:GetAttribute("PetHuntingDamage")==nil then player:SetAttribute("PetHuntingDamage",0) end
		createWeapon(s); equipArmor(s, true); createPet(s); sync(s)
		quests:CharacterReady(player)
		if resume then task.spawn(travel,s,"Hunting",nil,"Đã hồi sinh tại trại. Giữ tiến độ, bẫy/thuốc và thời gian còn lại.",true) end
		local previousHealth=humanoid.Health
		humanoid.HealthChanged:Connect(function(health)
			if health<previousHealth then cancelCharge(s) end
			previousHealth=health
		end)
		humanoid.Died:Connect(function()
			if states[player] ~= s then return end
			cancelCharge(s); s.WantSprint = false; s.LastTarget = nil; destroyPet(s)
			if quests:PlayerDied(player) then return end
			s.InHunting=false;s.InTraining=false;hunting:Exit(player)
			player:SetAttribute("InTraining",false);player:SetAttribute("Area","Lobby")
		end)
	end
	player:GetAttributeChangedSignal("AdminFlying"):Connect(function()
		local s=states[player];if not alive(s) then return end
		if player:GetAttribute("AdminFlying")==true then
			quests:CancelAction(player,"AdminFly")
			if s.Companion then s.Companion:Cancel("AdminFly") end
			s.HuntEngagedUntil=nil
			cancelCharge(s);s.AttackSerial=(s.AttackSerial or 0)+1;s.ChangeDraw=nil
			s.Drawn=false;s.WantSprint=false;s.Sprinting=false;s.Blocking=false;s.Aiming=false
			s.DodgingUntil=nil;s.LastTarget=nil;s.BowBoostUntil=0;s.BusyUntil=os.clock()
			for _,name in {"DodgeVelocity","DodgeAttachment"} do local object=s.Root:FindFirstChild(name);if object then object:Destroy() end end
			Rules.clearCombo(s);weaponPose(s);sync(s)
		else
			if s.Pet and s.Pet.Parent then PetPlacement.place(s.Pet,s.Character,s.Root.CFrame,pets) end
		end
	end)
	player.CharacterAdded:Connect(characterAdded)
	if player.Character then task.spawn(characterAdded, player.Character) end
end
Players.PlayerAdded:Connect(setup)
profiles.OnLoaded=function(player,data)
 if initializedPlayers[player] then
  local state=states[player]
  if state then state.WeaponId=data.Loadout.WeaponId;state.PetWeaponId=data.Loadout.PetWeaponId end
  companionMemories[player]=nil
  task.defer(function()
   quests:RemovePlayer(player);hunting:Exit(player)
   if player.Parent then player:LoadCharacterAsync() end
  end)
 else task.defer(setup,player) end
end
profiles.OnEconomyCommitted=function(player) economy:Publish(player) end
Players.PlayerRemoving:Connect(function(player)
	quests:RemovePlayer(player)
 profiles:Release(player)
	hunting:Exit(player)
	local s = states[player]; if s then destroyPet(s) end
	states[player] = nil
	companionMemories[player] = nil
 initializedPlayers[player]=nil
	local id = player:GetAttribute("BaseId")
	if id and owners[id] == player then owners[id] = nil; baseSign(id, "Chưa có chủ") end
end)
game:BindToClose(function() profiles:Shutdown(function(player) quests:RemovePlayer(player) end) end)
for _, player in Players:GetPlayers() do task.spawn(setup, player) end
local previewRemote=Instance.new("RemoteEvent");previewRemote.Name="HuntingMapPreviewJump";previewRemote.Parent=ReplicatedStorage
local previewCooldown={}
previewRemote.OnServerEvent:Connect(function(player,id)
	local s=states[player]
	if not RunService:IsStudio() or typeof(id)~="string" or not alive(s) or not s.InHunting or s.Travelling then return end
	local now=os.clock()
	if now-(previewCooldown[player] or -math.huge)<.5 or now<s.BusyUntil or s.Drawn or s.Charge or s.Blocking or s.Sprinting then return end
	previewCooldown[player]=now
	local zone
	for _,q in huntingConfig.Zones do if q.id==id then zone=q;break end end
	if not zone then return end
	local point=huntingConfig.position(zone)
	local offset=if id=="A" then Vector3.new(65,6,35) else Vector3.new(0,6,26)
	travel(s,"Hunting",CFrame.lookAt(point+offset,point+Vector3.new(0,6,0)),"Đã tới khu "..id.." để xem trong Studio.")
end)
Players.PlayerRemoving:Connect(function(player) previewCooldown[player]=nil;economy:RemovePlayer(player) end)
script.Destroying:Connect(function() quests:Destroy();economy:Destroy();hunting:Destroy();dinosaurCombat:Destroy();previewRemote:Destroy() end)
local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
 for _,state in states do if alive(state) then updatePresentation(state) end end
	accumulator += dt; if accumulator < 0.1 then return end
	local petAnimationDt = accumulator
	dt = math.min(accumulator, 0.25); accumulator = 0
	local now = os.clock()
	quests:Step(dt)
	for _,player in hunting:Expired() do
		local s=states[player]
		if alive(s) and s.InHunting and not s.Travelling and not quests:OwnsVisit(player) then
			task.spawn(travel,s,"Lobby",nil,"Hết thời gian thám hiểm thung lũng. Đã trở về sảnh cùng Pet.",true)
		end
	end
	for _, s in states do
		if not alive(s) then continue end
		if s.InHunting and not s.Travelling and s.Player:GetAttribute("AdminFlying")~=true and hunting:IsOutside(s.Root.Position) then
			if quests:OwnsVisit(s.Player) then
				task.spawn(travel,s,"Hunting",nil,"Đã đưa bạn về trại; đồng hồ và tiến độ săn được giữ nguyên.",true)
			else task.spawn(travel,s,"Lobby",nil,"Đã đưa bạn và Pet về sảnh an toàn.",true) end
		end
		if s.Charge and now-s.Charge.Started>=s.Charge.MaxHold then releaseCharge(s,s.Charge.Direction,s.Charge.Target) end
		if s.WantSprint and s.Drawn and now >= s.BusyUntil then toggleDraw(s, false) end
		s.Sprinting = s.WantSprint and not s.Drawn and now >= s.BusyUntil and s.Stamina > 0
			and s.Humanoid.MoveDirection.Magnitude > 0.1
		if s.Sprinting then
			s.Stamina = math.max(0, s.Stamina - Rules.staminaCost(Config,Config.SprintCost) * dt); s.LastSpend = now
			if s.Stamina == 0 then s.WantSprint = false; s.Sprinting = false end
		end
		if s.Blocking then
			s.Stamina=math.max(0,s.Stamina-Rules.staminaCost(Config,Config.GuardCost)*dt); s.LastSpend=now
			if s.Stamina==0 then s.Blocking=false; weaponPose(s) end
		end
		Rules.regenerate(Config, s, now, dt)
		s.Humanoid.WalkSpeed = if s.Blocking then 6 elseif now < (s.DodgingUntil or 0) then Config.WalkSpeed elseif now < s.BusyUntil then 8 elseif s.Sprinting then Config.SprintSpeed else Config.WalkSpeed
		local companionHandled = s.Companion and s.Companion:Step(workspace:GetServerTimeNow(),dt)
		if companionHandled then s.PetAnimator:Update(petAnimationDt);sync(s);continue end
		if s.Player:GetAttribute("AdminFlying")==true then
			s.Pet:SetAttribute("PetMoving",false);s.PetAnimator:Update(petAnimationDt);sync(s);continue
		end
		-- Standing pet: move the feet along the collision surface.
		local target = s.LastTarget
		local bowAiming = s.WeaponId=="Bow" and s.Drawn and (s.Aiming or s.Charge~=nil)
		local active = s.InTraining and not bowAiming and target and now < s.TargetUntil
			and (target.Target.Position - s.Root.Position).Magnitude < 18
		local desired = if active then target.Target.Position + Vector3.new(3, 0, 3)
			else Bow.followPoint(s.Root.CFrame,bowAiming)
		local petPos = s.Pet.PrimaryPart.Position
		local flat = Vector3.new(desired.X - petPos.X, 0, desired.Z - petPos.Z)
		local step = flat * math.min(1, 18 * dt / math.max(flat.Magnitude, 0.01))
		local filter = RaycastParams.new()
		filter.FilterType = Enum.RaycastFilterType.Exclude
		filter.FilterDescendantsInstances = {s.Character, pets}
		filter.RespectCanCollide = true
		local moved = false
		if flat.Magnitude > 0.2 and not workspace:Raycast(petPos + Vector3.new(0, 1.5, 0), step, filter) then
			local newPos = PetPlacement.position(s.Character, petPos + step, pets)
			s.Pet:PivotTo(CFrame.lookAt(newPos, newPos + flat))
			moved = true
		elseif active then
			local aim = target.Target.Position - petPos
			aim = Vector3.new(aim.X, 0, aim.Z)
			if aim.Magnitude > 0.1 then s.Pet:PivotTo(CFrame.lookAt(petPos, petPos + aim)) end
		end
		s.Pet:SetAttribute("PetMoving", moved)
		s.Pet:SetAttribute("PetSpeed", 1.3)
		if active and (s.Pet.PrimaryPart.Position + Vector3.new(0, 2, 0) - target.Target.Position).Magnitude <= 7
			and now >= s.PetClock and lineOfSight(s, target.Target.Position, target) then
			startPetAttack(s, target)
		end
		s.PetAnimator:Update(petAnimationDt)
		sync(s)
	end
end)
print("[HunDino L0] Sảnh 12 base và bãi tập đã khởi tạo.")
