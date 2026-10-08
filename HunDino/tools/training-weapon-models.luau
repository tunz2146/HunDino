-- Built-in geometry only. Same models are used on racks and in players' hands.
return function(r,id,parent)
	local I,V,C,E,Color=r.Instance,r.Vector3,r.CFrame,r.Enum,r.Color3
	local steel=Color.fromRGB(181,204,208); local edge=Color.fromRGB(224,238,227)
	local wood=Color.fromRGB(70,45,31); local gold=Color.fromRGB(172,128,61); local teal=Color.fromRGB(66,178,167)
	local model=I.new('Model'); model.Name=id; model.Parent=parent
	local function assembly(name)
		local m=I.new('Model'); m.Name=name; m.Parent=model; return m
	end
	local function part(m,name,cf,size,color,material,shape)
		local p=I.new('Part'); p.Name=name; p.Size=size; p.CFrame=cf; p.Color=color
		p.Material=material or E.Material.Metal; p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Massless=true
		if shape then p.Shape=shape end
		p.Parent=m; return p
	end
	local function handle(m,length)
		local p=part(m,'Handle',C.new(),V.new(.24,length,.24),wood,E.Material.Wood)
		m.PrimaryPart=p; return p
	end
	local function blade(m,length,width,base,curve)
		part(m,'Blade',C.new(curve or 0,base+length/2,0)*C.Angles(0,0,-(curve or 0)*.18),V.new(width,length,.12),steel)
		part(m,'Edge',C.new(width/2+(curve or 0),base+length/2,0),V.new(.055,length,.14),edge)
		part(m,'Tip',C.new(curve or 0,base+length,0)*C.Angles(0,0,math.pi/4),V.new(width*.68,width*.68,.12),edge)
	end
	local main=assembly('Main'); handle(main,if id=='Glaive' then 6.4 elseif id=='Hammer' or id=='GreatAxe' then 3.4 else 1.3)
	if id=='Hammer' then
		part(main,'Head',C.new(0,2.0,0),V.new(3.2,1.7,1.6),steel)
		for _,x in {-1.28,1.28} do part(main,'Band',C.new(x,2,0),V.new(.22,1.85,1.75),gold) end
		part(main,'Rune',C.new(0,2,-.83),V.new(.45,.65,.07),teal,E.Material.Neon)
	elseif id=='SwordShield' or id=='Katana' then
		part(main,'Guard',C.new(0,.7,0),V.new(if id=='Katana' then .9 else 1.4,.16,.32),gold)
		blade(main,if id=='Katana' then 4 else 2.7,if id=='Katana' then .3 else .55,.78,if id=='Katana' then .15 else 0)
		if id=='SwordShield' then
			local off=assembly('Offhand'); handle(off,.5)
			part(off,'RoundShield',C.new(0,0,-.3)*C.Angles(0,math.pi/2,0),V.new(.22,2.45,2.45),wood,E.Material.Wood,E.PartType.Cylinder)
			part(off,'ShieldRim',C.new(0,0,-.32)*C.Angles(0,math.pi/2,0),V.new(.18,2.5,2.5),gold,E.Material.Metal,E.PartType.Cylinder)
			part(off,'ShieldFace',C.new(0,0,-.45)*C.Angles(0,math.pi/2,0),V.new(.16,2.22,2.22),wood,E.Material.Wood,E.PartType.Cylinder)
			part(off,'ShieldBoss',C.new(0,0,-.62),V.new(.6,.6,.35),steel,E.Material.Metal,E.PartType.Ball)
		else
			local sheath=assembly('Sheath'); handle(sheath,.3)
			part(sheath,'Scabbard',C.new(0,2.2,.08),V.new(.44,4.4,.3),wood)
			for _,y in {.2,3.9} do part(sheath,'Band',C.new(0,y,.08),V.new(.5,.2,.35),gold) end
		end
	elseif id=='Glaive' then
		blade(main,2.5,.8,3.3,.32)
		part(main,'Collar',C.new(0,3.2,0),V.new(.5,.55,.4),gold)
		part(main,'Tassel',C.new(-.45,2.5,0)*C.Angles(0,0,-.3),V.new(.35,1.7,.12),teal,E.Material.Fabric)
	elseif id=='DualDaggers' then
		blade(main,1.7,.42,.6,0)
		part(main,'Guard',C.new(0,.55,0),V.new(.85,.15,.3),gold)
		local off=assembly('Offhand'); handle(off,1.1); blade(off,1.7,.42,.6,0)
		part(off,'Guard',C.new(0,.55,0),V.new(.85,.15,.3),gold)
	elseif id=='GreatAxe' then
		for _,s in {-1,1} do
			part(main,'AxeWing',C.new(s*.9,1.8,0)*C.Angles(0,0,s*.18),V.new(1.6,1.45,.3),steel)
			part(main,'CuttingEdge',C.new(s*1.6,1.8,0)*C.Angles(0,0,s*.18),V.new(.24,1.65,.34),edge)
		end
		part(main,'Core',C.new(0,1.8,0),V.new(.5,1.8,.5),gold)
	elseif id=='Bow' then
		for _,s in {-1,1} do
			for j=0,3 do
				part(main,'BowLimb',C.new(.35*j,s*(.7+j*.55),0)*C.Angles(0,0,-s*.5),V.new(.24,.8,.28),wood,E.Material.Wood)
			end
		end
		part(main,'BowString',C.new(1.15,0,0),V.new(.035,4.9,.035),edge,E.Material.Fabric)
		part(main,'NockedArrow',C.new(.3,0,-.03)*C.Angles(0,0,math.pi/2),V.new(.07,3.1,.07),gold)
	end
	model.PrimaryPart=main.PrimaryPart
	return model
end
