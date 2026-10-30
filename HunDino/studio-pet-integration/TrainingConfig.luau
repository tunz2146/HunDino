-- Shared geometry for contact-based draw/stow, injected constructors for portable tests.
local function weaponHandling(CFrame,Vector3)
 local H={Grab=.24,Clear=.76,Return=.94}
 function H.smooth(x)
  x=math.clamp(x,0,1);return x*x*(3-2*x)
 end
 function H.phase(progress,drawing)
  return if drawing then math.clamp(progress,0,1) else 1-math.clamp(progress,0,1)
 end
 function H.arm(character,side)
  local arm={Side=side}
  for _,joint in character:GetDescendants() do
   if joint:IsA('Motor6D') or joint:IsA('AnimationConstraint') then
    local name=joint.Name:lower():gsub('%s','')
    if name==side..'shoulder' and (not arm.Shoulder or joint:IsA('AnimationConstraint')) then arm.Shoulder=joint
    elseif name==side..'elbow' and (not arm.Elbow or joint:IsA('AnimationConstraint')) then arm.Elbow=joint
    elseif name==side..'wrist' and (not arm.Wrist or joint:IsA('AnimationConstraint')) then arm.Wrist=joint end
   end
  end
  local shoulder=arm.Shoulder
  if not shoulder or not shoulder.Part0 or not shoulder.Part1 then return nil end
  arm.Hand=if arm.Wrist then arm.Wrist.Part1 else shoulder.Part1
  if not arm.Hand then return nil end
  arm.Palm=Vector3.new(0,-arm.Hand.Size.Y*.5+.1,0)
  return arm
 end
 local function geometry(arm)
  local shoulder=arm.Shoulder
  local origin=(shoulder.Part0.CFrame*shoulder.C0).Position
  if arm.Elbow and arm.Wrist then
   local a=(arm.Elbow.C0.Position-shoulder.C1.Position).Magnitude
   local b=(arm.Wrist.C0.Position-arm.Elbow.C1.Position).Magnitude
   return origin,math.max(.1,a),math.max(.1,b)
  end
  return origin,math.max(.1,(arm.Palm-shoulder.C1.Position).Magnitude),nil
 end
 function H.reach(arm,goal)
  if not arm then return goal end
  local origin,a,b=geometry(arm)
  local delta=goal.Position-origin
  local distance=delta.Magnitude
  local direction=if distance>.0001 then delta/distance else Vector3.new(0,-1,0)
  local length=if b then math.clamp(distance,math.abs(a-b)+.005,a+b+.05) else a
  return CFrame.new(origin+direction*length)*goal.Rotation
 end
 local function segment(localStart,localFinish,worldStart,worldFinish,pole)
  local localDirection=(localFinish-localStart).Unit
  local localUp=if math.abs(localDirection.Y)>.95 then Vector3.zAxis else Vector3.yAxis
  local direction=(worldFinish-worldStart).Unit
  local up=pole-direction*pole:Dot(direction)
  if up.Magnitude<.001 then up=Vector3.xAxis-direction*direction.X end
  local localRight=localDirection:Cross(localUp).Unit
  local worldRight=direction:Cross(up.Unit).Unit
  local localFrame=CFrame.fromMatrix(localStart,localRight,localRight:Cross(localDirection),-localDirection)
  local worldFrame=CFrame.fromMatrix(worldStart,worldRight,worldRight:Cross(direction),-direction)
  return worldFrame*localFrame:Inverse()
 end
 function H.solve(arm,goal)
  if not arm then return {},goal end
  local shoulder=arm.Shoulder
  local root=shoulder.Part0.CFrame
  local origin,a,b=geometry(arm)
  local contact=H.reach(arm,goal)
  local side=if arm.Side=='left' then -1 else 1
  local pole=root.RightVector*side*.8-root.LookVector*.55-root.UpVector*.15
  local targets={}
  if b then
   local hand=CFrame.new(contact.Position)*goal.Rotation*CFrame.new(-arm.Palm)
   local wrist=(hand*arm.Wrist.C1).Position
   local delta=wrist-origin
   local distance=math.clamp(delta.Magnitude,math.abs(a-b)+.005,a+b-.005)
   local direction=if delta.Magnitude>.0001 then delta.Unit else -root.UpVector
   wrist=origin+direction*distance
   local along=(a*a-b*b+distance*distance)/(2*distance)
   local bend=pole-direction*pole:Dot(direction)
   if bend.Magnitude<.001 then bend=root.LookVector-direction*root.LookVector:Dot(direction) end
   local elbow=origin+direction*along+bend.Unit*math.sqrt(math.max(0,a*a-along*along))
   local upper=segment(shoulder.C1.Position,arm.Elbow.C0.Position,origin,elbow,pole)
   local lower=segment(arm.Elbow.C1.Position,arm.Wrist.C0.Position,elbow,wrist,pole)
   hand=CFrame.new(wrist-(hand.Rotation*arm.Wrist.C1.Position))*hand.Rotation
   targets[shoulder]=(root*shoulder.C0):ToObjectSpace(upper*shoulder.C1)
   targets[arm.Elbow]=(upper*arm.Elbow.C0):ToObjectSpace(lower*arm.Elbow.C1)
   targets[arm.Wrist]=(lower*arm.Wrist.C0):ToObjectSpace(hand*arm.Wrist.C1)
   return targets,CFrame.new(hand:PointToWorldSpace(arm.Palm))*goal.Rotation
  end
  local part=segment(shoulder.C1.Position,arm.Palm,origin,contact.Position,pole)
  targets[shoulder]=(root*shoulder.C0):ToObjectSpace(part*shoulder.C1)
  return targets,contact
 end
 function H.scale(id)
  return if id=='Katana' then .68 elseif id=='Bow' then .76 elseif id=='SwordShield' then .85 elseif id=='GreatAxe' then .64 elseif id=='Hammer' then .7 else 1
 end
 function H.mount(id,off,carry,size)
  local z=size.Z*.5
  if id=='Katana' then
   if carry==1 then return H.alignUp(CFrame.new(size.X*.5+.18,-.65,-.55),Vector3.new(.1,-.25,1).Unit) end
   return CFrame.new(.6,1.3,z+.48)*CFrame.Angles(0,0,math.rad(170))
  elseif id=='DualDaggers' then
   return CFrame.new(size.X*.5+(if off then .08 else .3),-size.Y*.5+.18,if off then z+.18 else -.12)*CFrame.Angles(0,0,math.pi)
  elseif id=='Glaive' then return CFrame.new(size.X*.5+.35,-.5,.12)
  elseif id=='GreatAxe' then return CFrame.new(0,-.5,z+.5)
  elseif id=='Bow' then return CFrame.new(-.25,.35,z+.5)*CFrame.Angles(0,0,math.rad(-25))
  elseif off then return CFrame.new(-.65,-.45,z+.55)*CFrame.Angles(0,0,.1)
  end
  return CFrame.new(.75,.75,z+.5)*CFrame.Angles(0,0,math.rad(155))
 end
 function H.grip(id)
  return CFrame.new(0,if id=='Hammer' or id=='GreatAxe' then .55*H.scale(id) else 0,0)
 end
 function H.twoHanded(id,stance)
  return id=='Glaive' or (stance>=3 and id~='Bow' and id~='SwordShield' and id~='DualDaggers')
 end
 function H.ready(id,off,stance,aim,charge)
  if id=='Bow' then
   local high=aim or stance>=2
   return CFrame.new(if high then -.55 else -1.05,if high then .3 else -.65,if high then -1.85 else -.85)
    *CFrame.Angles(0,-math.pi/2,if stance==3 then math.rad(-6) else 0)
  elseif id=='DualDaggers' then
   local position=Vector3.new(if off then -.85 else .85,if off then -.65 else .45,-1.25)
   local axis=if stance==3 then Vector3.new(if off then -.35 else .35,.75,-.55) elseif stance==2 then Vector3.new(if off then -.8 else .8,-.15,-.55) else Vector3.new(if off then .85 else -.85,if off then .2 else -.2,-.48)
   return H.alignUp(CFrame.new(position),axis.Unit)
  elseif off then return CFrame.new(-.95,-.1,-1.3)*CFrame.Angles(0,0,-.1)
  elseif stance==4 then
   return H.alignUp(CFrame.new(.25,.05,-1.3),Vector3.new(.04,.94,-.34).Unit)
  elseif stance==5 then
   return H.alignUp(CFrame.new(.25,1.4,-.45),Vector3.new(.8,.3,.52).Unit)
  elseif stance==6 then
   return H.alignUp(CFrame.new(.4,-.75,-1.05),Vector3.new(.92,.18,-.35).Unit)
  elseif (id=='GreatAxe' or id=='Hammer') and stance==1 then
   return H.alignUp(CFrame.new(.85,-.38,-1.2),Vector3.new(-.94,.3,-.17).Unit)
  elseif id=='Katana' and stance==1 then
   return CFrame.new(1.2,-.7,-.9)*CFrame.Angles(math.rad(-35),0,math.rad(-8))
  elseif stance==3 or id=='Glaive' then
   return CFrame.new(.4,-.4,-1.55)*CFrame.Angles(math.rad(-48),0,math.rad(-8))
  elseif stance==2 then return CFrame.new(1,.15,-1.2)*CFrame.Angles(math.rad(-18),0,math.rad(-12))
  end
  return CFrame.new(1.15,-.65,-1.15)*CFrame.Angles(math.rad(-38),0,math.rad(-10))
 end
 function H.path(mount,ready,q,id,scale)
  if q<=H.Grab then return mount end
  if id=='Katana' then
   local working=CFrame.new(1.4,.6,-.6)*CFrame.Angles(0,0,math.rad(100))
   if q<.4 then
    local u=H.smooth((q-H.Grab)/(.4-H.Grab))
    return CFrame.new(if mount.Z>0 then math.sin(u*math.pi) else 0,.1*math.sin(u*math.pi),if mount.Z<0 then -.5*math.sin(u*math.pi) else 0)*mount:Lerp(working,u)
   end
   if q<H.Clear then return working*CFrame.new(0,-.7*H.smooth((q-.4)/(H.Clear-.4)),0) end
   return (working*CFrame.new(0,-.7,0)):Lerp(ready,H.smooth((q-H.Clear)/(.96-H.Clear)))
  end
  local lifted=mount*CFrame.new(0,0,-.65)
  if q<.5 then return mount:Lerp(lifted,H.smooth((q-H.Grab)/(.5-H.Grab))) end
  return lifted:Lerp(ready,H.smooth((q-.5)/.5))
 end
 function H.sheath(mount,main,q,scale)
  local home=mount*CFrame.new(0,.72*scale,-.08*scale)
  if q<=H.Grab then return home end
  local extracted=4.55*scale*H.smooth((q-.4)/(H.Clear-.4))
  local aligned=main*CFrame.new(0,.72*scale+extracted,-.08*scale)
  if q<=H.Clear then return aligned end
  return aligned:Lerp(home,H.smooth((q-H.Clear)/(H.Return-H.Clear)))
 end
 function H.contactWeight(q)
  return H.smooth(q/H.Grab)
 end

 function H.alignUp(frame,up)
  local back=-frame.LookVector
  local right=up:Cross(back)
  if right.Magnitude<.001 then right=up:Cross(Vector3.xAxis) end
  right=right.Unit
  return CFrame.fromMatrix(frame.Position,right,up,right:Cross(up))
 end
 function H.katana(torso,mount,ready,q,scale,mainArm,leftArm)
  local home=torso*mount*CFrame.new(0,.72*scale,-.08*scale)
  if q<=H.Grab then return torso*mount,home end
  local _,main=H.solve(mainArm,torso*H.path(mount,ready,q,'Katana',scale))
  if q>=H.Return then return main,home end
  if q>H.Clear then
   local _,clearSheath=H.katana(torso,mount,ready,H.Clear,scale,mainArm,leftArm)
   return main,clearSheath:Lerp(home,H.smooth((q-H.Clear)/(H.Return-H.Clear)))
  end
  local extraction=4.55*scale*H.smooth((q-.4)/(H.Clear-.4))
  local sheath=main*CFrame.new(0,.72*scale+extraction,-.08*scale)
  local _,left=H.solve(leftArm,sheath*CFrame.new(0,.75,.08*scale))
  local delta=left.Position-main.Position
  if delta.Magnitude>.01 then
   local blend=H.smooth((q-H.Grab)/.1)
   local axis=main.UpVector:Lerp(delta.Unit,blend).Unit
   main=H.alignUp(main,axis)

  end
  return main,main*CFrame.new(0,.72*scale+extraction,-.08*scale)
 end


 function H.sheathSupport(arm,sheath,scale)
  local point=sheath:PointToWorldSpace(Vector3.new(0,0,.08*scale))
  local along=.75
  if arm then
   local origin,a,b=geometry(arm)
   local delta=point-origin;local projection=delta:Dot(sheath.UpVector)
   local radius=a+(b or 0)
   local discriminant=radius*radius-(delta.Magnitude*delta.Magnitude-projection*projection)
   if discriminant>=0 then
    local extent=math.sqrt(discriminant)
    local lo,hi=-projection-extent,-projection+extent
    if not b then along=if math.abs(lo-.75)<math.abs(hi-.75) then lo else hi
    else along=math.clamp(.75,lo,hi) end
    along=math.clamp(along,.05,4.56*scale-.05)
   end
  end
  return CFrame.new(point+sheath.UpVector*along)*sheath.Rotation
 end
 function H.handoff(left,right,torso)
  if not left or not right then return torso*CFrame.new(0,.4,-1.15) end
  local l,la,lb=geometry(left)
  local r,ra,rb=geometry(right)
  local lr=la+(lb or 0);local rr=ra+(rb or 0)
  local delta=r-l;local distance=math.max(.01,delta.Magnitude);local axis=delta/distance
  local along=math.clamp((lr*lr-rr*rr+distance*distance)/(2*distance),0,lr)
  local depth=math.sqrt(math.max(.05,lr*lr-along*along))
  if lb or rb then depth*=.9 end
  local forward=torso.LookVector-axis*torso.LookVector:Dot(axis)
  local point=l+axis*along+forward.Unit*depth
  return CFrame.new(point)*torso.Rotation*CFrame.Angles(-.3,0,0)
 end
 function H.dual(mainMount,offMount,mainReady,offReady,handoff,idleRight,idleLeft,q)
  local off=offMount
  if q>.18 and q<.35 then off=offMount:Lerp(handoff,H.smooth((q-.18)/.17))
  elseif q>=.35 then off=handoff:Lerp(offReady,H.smooth((q-.35)/.43)) end
  local main=if q<.54 then mainMount else mainMount:Lerp(mainReady,H.smooth((q-.54)/.32))
  local right
  if q<.18 then right=idleRight:Lerp(offMount,H.smooth(q/.18))
  elseif q<.35 then right=off
  elseif q<.54 then right=handoff:Lerp(mainMount,H.smooth((q-.35)/.19))
  else right=main end
  local left=if q<.18 then idleLeft elseif q<.35 then idleLeft:Lerp(handoff,H.smooth((q-.18)/.17)) else off
  return main,off,right,left
 end


 function H.twoHand(right,left,goal,offset)
  local frame=goal
  for _=1,12 do
   local _,main=H.solve(right,frame)
   local support=main*CFrame.new(0,offset,0)
   local _,contact=H.solve(left,support)
   local correction=contact.Position-support.Position
   frame=CFrame.new(main.Position+correction)*goal.Rotation
   if correction.Magnitude<.002 then break end
  end
  local _,main=H.solve(right,frame)
  return main
 end

 function H.supportOffset(id,stance)
  if id=='GreatAxe' or id=='Glaive' then return .65 end
  return (if stance>=4 then -.7 else -.44)*H.scale(id)
 end
 function H.bodyPose(stance,name,segmented)
  if stance<4 or stance>6 then return CFrame.new() end
  local low=stance==6
  local upper=stance==5
  local side=if name:find('left',1,true) then -1 else 1
  local bend=if low then .3 elseif upper then .2 else .16
  if name=='root' or name=='rootjoint' then
   local drop=if segmented then (if low then .14 elseif upper then .07 else .055) else (if low then -.23 elseif upper then -.16 else -.18)
   return CFrame.new(0,-drop,0)*CFrame.Angles(if segmented then 0 elseif low then .06 elseif upper then -.035 else .02,0,0)
  elseif name=='waist' then
   return CFrame.Angles(if low then .06 elseif upper then -.045 else .015,if low then -.08 else 0,0)
  elseif name:find('hip',1,true) then
   if not segmented then
    return CFrame.Angles(if low then (if side<0 then .18 else -.12) else .1,side*.1,side*(if low then .2 else .15))
   end
   local front=if low and side>0 then .18 else bend
   local lift=if low and side>0 then .065 else 0
   return CFrame.new(0,lift,0)*CFrame.Angles(front,side*.1,side*(if low then .18 else .13))
  elseif name:find('knee',1,true) then
   local front=if low and side>0 then .18 else bend
   return CFrame.Angles(-2*front,0,0)
  elseif name:find('ankle',1,true) then
   local front=if low and side>0 then .18 else bend
   return CFrame.Angles(front,0,-side*(if low then .18 else .13))
  end
  return CFrame.new()
 end
 function H.bodyTransform(joint,base,offset)
  -- Joint C0 axes may be rotated (especially on R6); offsets use parent-body axes.
  local rotation=joint.C0.Rotation
  return rotation:Inverse()*offset*rotation*base
 end

 return H
end

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
	DodgeTime = 0.5,
	DodgeSpeed = 72,
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

 Controls = {
  DrawSeconds=1.6,
  Handling=weaponHandling,
  KatanaCarryNames={"Hông phải","Sau lưng"},
  MeleeStances={"Cân bằng","Thủ thế","Hai tay","Kiếm trước ngực","Kiếm trên đầu","Kiếm ngang hông"},
  RangedStances={"Thấp","Ngang vai","Tập trung"},
  HotbarOrder={"Hammer","SwordShield","Katana","Glaive","DualDaggers","Bow","GreatAxe"},
 },
}
