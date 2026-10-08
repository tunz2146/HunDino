-- Generates ONLY the new training area and weapon templates, never the lobby.
local r=require('@lune/roblox'); local fs=require('@lune/fs')
local buildWeapon=require('./training-weapon-models')
local weapons=require('../src/dark-jungle/Weapons')
local I,V,C,E,Color=r.Instance,r.Vector3,r.CFrame,r.Enum,r.Color3
local origin=V.new(2086,36,0)
local training=I.new('Model'); training.Name='Training'
training:SetAttribute('Revision','Sanctuary.1'); training:SetAttribute('Width',460); training:SetAttribute('Depth',420)
local stone=Color.fromRGB(66,80,77); local lightStone=Color.fromRGB(100,116,106)
local moss=Color.fromRGB(44,68,48); local wood=Color.fromRGB(70,47,33)
local gold=Color.fromRGB(183,141,71); local teal=Color.fromRGB(69,208,180)
local function folder(name,parent)
 local f=I.new('Model'); f.Name=name; f.Parent=parent or training; return f
end
local function part(parent,name,pos,size,color,material,collide)
 local p=I.new('Part'); p.Name=name; p.Size=size; p.CFrame=C.new(origin+pos); p.Color=color or stone
 p.Material=material or E.Material.Slate; p.Anchored=true; p.CanCollide=collide~=false; p.CanTouch=false; p.CanQuery=p.CanCollide; p.TopSurface=E.SurfaceType.Smooth; p.BottomSurface=E.SurfaceType.Smooth; p.Parent=parent; return p
end
local function rod(parent,name,a,b,width,color,material)
 local d=b-a; local up=d.Unit; local seed=if math.abs(up.Y)>.98 then V.zAxis else V.yAxis
 local right=up:Cross(seed).Unit; local back=right:Cross(up)
 local p=part(parent,name,(a+b)/2,V.new(width,d.Magnitude,width),color,material,false)
 p.CFrame=C.fromMatrix(origin+(a+b)/2,right,up,back); return p
end
local function disc(parent,name,pos,radius,height,color,material)
 local p=part(parent,name,pos,V.new(height,radius*2,radius*2),color,material)
 p.Shape=E.PartType.Cylinder; p.CFrame*=C.Angles(0,0,math.pi/2); return p
end
local function ring(parent,pos,radius,color)
 for n=0,47 do
  local a=n*math.pi/24; local b=(n+1)*math.pi/24
  rod(parent,'Inlay',pos+V.new(math.cos(a)*radius,0,math.sin(a)*radius),pos+V.new(math.cos(b)*radius,0,math.sin(b)*radius),.18,color,E.Material.Metal)
 end
end
local function label(parent,value,width,height,offset,distance)
 local gui=I.new('BillboardGui'); gui.Name='SignGui'; gui.Size=r.UDim2.fromOffset(width or 240,height or 60)
 gui.StudsOffset=V.new(0,offset or 5,0); gui.MaxDistance=distance or 70; gui.AlwaysOnTop=false; gui.LightInfluence=0; gui.Parent=parent
 local t=I.new('TextLabel'); t.Name='Text'; t.Size=r.UDim2.fromScale(1,1); t.BackgroundColor3=Color.fromRGB(13,30,29); t.BackgroundTransparency=.12
 t.TextColor3=Color.fromRGB(239,230,201); t.Font=E.Font.GothamMedium; t.TextSize=18; t.TextWrapped=true; t.Text=value; t.Parent=gui
 local corner=I.new('UICorner'); corner.CornerRadius=r.UDim.new(0,6); corner.Parent=t
 return gui
end
local function sign(name,pos,value,width,distance)
 local p=part(training,name,pos,V.new(8,5,1),wood,E.Material.Wood)
 label(p,value,width or 270,66,4,distance or 90); return p
end
local function prompt(p,name,action,object)
 local q=I.new('ProximityPrompt'); q.Name=name; q.ActionText=action; q.ObjectText=object; q.KeyboardKeyCode=E.KeyCode.G
 q.HoldDuration=.3; q.MaxActivationDistance=10; q.RequiresLineOfSight=false; q.Parent=p; return q
end
local ground=part(training,'Ground',V.new(0,-3,0),V.new(460,6,420),moss,E.Material.Grass)
part(training,'Foundation',V.new(0,-12,0),V.new(458,14,418),stone,E.Material.Rock)
local paths=folder('Walkways')
part(paths,'ArrivalWalk',V.new(0,.15,136),V.new(24,.3,114),lightStone,E.Material.Cobblestone)
part(paths,'CrossWalk',V.new(0,.16,85),V.new(375,.32,20),lightStone,E.Material.Cobblestone)
part(paths,'RangeWalk',V.new(125,.14,20),V.new(130,.28,150),Color.fromRGB(91,97,78),E.Material.Sand)
part(paths,'WestWalk',V.new(-139,.12,-25),V.new(17,.24,212),lightStone,E.Material.Cobblestone)
for _,x in {-12,12} do part(paths,'ArrivalBorder',V.new(x,.33,136),V.new(.3,.12,114),gold,E.Material.Metal,false) end
local arena=folder('MeleeCourt')
disc(arena,'Plinth',V.new(-47,.16,-23),67,.32,stone,E.Material.Slate)
disc(arena,'PracticeFloor',V.new(-47,.36,-23),63,.1,lightStone,E.Material.Cobblestone)
for _,radius in {21,43,62} do ring(arena,V.new(-47,.44,-23),radius,gold) end
for n=0,11 do
 local a=n*math.pi/6
 rod(arena,'Radial',V.new(-47+math.cos(a)*43,.45,-23+math.sin(a)*43),V.new(-47+math.cos(a)*62,.45,-23+math.sin(a)*62),.16,gold,E.Material.Metal)
end
sign('MeleeSign',V.new(-48,3,52),'SÂN CẬN CHIẾN\nRút vũ khí bằng R',260,95)
local dummies=folder('Dummies')
local function dummy(index,pos,kind,title)
 local m=folder('Dummy'..index,dummies); m:SetAttribute('Health',1000); m:SetAttribute('Kind',kind); m:SetAttribute('Label',title)
 local color=if kind=='Archery' then Color.fromRGB(149,116,61) else Color.fromRGB(167,128,74)
 disc(m,'Footing',pos+V.new(0,.25,0),4.8,.5,stone)
 part(m,'Post',pos+V.new(0,2.5,0),V.new(.7,5,.7),wood,E.Material.Wood)
 local target=part(m,'Target',pos+V.new(0,4.2,0),V.new(3.2,3.6,1.5),color,E.Material.Wood)
 part(m,'Head',pos+V.new(0,6.6,0),V.new(1.6,1.6,1.6),color,E.Material.Wood).Shape=E.PartType.Ball
 part(m,'Arms',pos+V.new(0,4.5,0),V.new(6.2,.5,.5),wood,E.Material.Wood)
 for _,rad in {1.35,.9,.4} do
  local p=part(m,'TargetRing',pos+V.new(0,4.2,.8+(.15-rad*.05)),V.new(.06,rad*2,rad*2),if rad<.5 then teal elseif rad<1 then wood else gold,E.Material.Metal)
  p.Shape=E.PartType.Cylinder; p.CFrame*=C.Angles(0,math.pi/2,0)
 end
 label(target,title..'\n1000 / 1000',190,50,4.8,if kind=='Archery' then 160 else 65)
 return m
end
dummy(1,V.new(-75,.5,-30),'Melee','HÌNH NỘM 1')
dummy(2,V.new(-25,.5,-30),'Melee','HÌNH NỘM 2')
dummy(3,V.new(-47,.5,-63),'Melee','HÌNH NỘM 3')
local range=folder('ArcheryRange')
for i,distance in {30,60,90,120} do
 local x=72+i*27
 part(range,'Lane',V.new(x,.38,75-distance/2),V.new(20,.14,distance+12),Color.fromRGB(121,116,82),E.Material.Sand)
 for _,dx in {-10,10} do part(range,'LaneEdge',V.new(x+dx,.52,75-distance/2),V.new(.16,.08,distance+12),gold,E.Material.Metal,false) end
 local line=part(range,'ShootingLine',V.new(x,.53,75),V.new(18,.12,1),teal,E.Material.Neon,false)
 label(line,distance..' STUDS',130,30,2.2,38)
 dummy(i+3,V.new(x,.5,75-distance),'Archery','BIA CUNG '..distance)
 part(range,'Backstop',V.new(x,6,65-distance),V.new(22,12,1.6),wood,E.Material.WoodPlanks)
end
sign('ArcherySign',V.new(143,3,92),'TRƯỜNG BẮN CUNG\nGiữ chuột phải để ngắm',280,95)
local hall=folder('ArmoryHall')
part(hall,'Floor',V.new(-49,.18,126),V.new(246,.36,54),lightStone,E.Material.Cobblestone)
for _,x in {-174,77} do for _,z in {101,152} do
 part(hall,'Column',V.new(x,9,z),V.new(3,18,3),wood,E.Material.Wood)
 part(hall,'ColumnFoot',V.new(x,1,z),V.new(5,2,5),stone)
end end
for _,z in {101,152} do part(hall,'Beam',V.new(-49,18,z),V.new(260,2,2.4),wood,E.Material.Wood) end
for _,s in {-1,1} do
 local roof=part(hall,'Roof',V.new(-49,23,126+s*14),V.new(265,1.6,32),Color.fromRGB(31,64,60),E.Material.Slate)
 roof.CFrame*=C.Angles(s*-.27,0,0)
 part(hall,'GildedEave',V.new(-49,18.6,126+s*31),V.new(270,.6,1),gold,E.Material.Metal,false)
end
sign('ArmoryTitle',V.new(-49,9,102),'KHO VŨ KHÍ\nI: mở túi trang bị',280,105)
local racks=folder('WeaponRacks')
local templates=I.new('Folder'); templates.Name='TrainingWeapons'
for i,id in weapons.Order do
 local template=buildWeapon(r,id,templates)
 local x=-147+(i-1)*32
 local rack=part(racks,id,V.new(x,2.3,128),V.new(24,4.6,12),stone)
 part(hall,'DisplayTrim',V.new(x,4.7,128),V.new(24.3,.25,12.3),gold,E.Material.Metal,false)
 local display=template:Clone(); display.Name='Display_'..id; display.Parent=hall
 local displayCF=C.new(origin+V.new(x,7.5,128))*C.Angles(-.25,0,-.15)
 for _,p in display:GetDescendants() do if p:IsA('BasePart') then p.CFrame=displayCF*p.CFrame end end
 label(rack,weapons[id].Name,185,42,10,37)
 prompt(rack,'EquipPrompt','Chọn '..weapons[id].Name,'Vũ khí luyện tập')
end
local equip=sign('EquipmentRack',V.new(86,3,134),'GIÁP LUYỆN TẬP',215,45)
prompt(equip,'ArmorPrompt','Mặc / tháo giáp mẫu','Giá trang bị')
local reset=sign('ResetPost',V.new(116,3,149),'LƯỢT TẬP MỚI',210,45)
prompt(reset,'ResetPrompt','Xóa thống kê của tôi','Bảng luyện tập')
local gate=part(training,'ToLobby',V.new(0,4,186),V.new(15,8,1),teal,E.Material.Neon,false); gate.Transparency=.85
label(gate,'TRỞ VỀ TRẠI\nGiữ G gần cổng',270,62,10,105); prompt(gate,'ToLobbyPrompt','Về sảnh','Trại thợ săn')
for _,x in {-11,11} do
 part(training,'GatePillar',V.new(x,8,186),V.new(4,16,5),stone)
 part(training,'GateRune',V.new(x,8,183.4),V.new(.3,11,.12),teal,E.Material.Neon,false)
 disc(training,'GateCap',V.new(x,16.5,186),3.8,1.4,gold,E.Material.Metal)
end
part(training,'GateLintel',V.new(0,18,186),V.new(30,3,7),wood,E.Material.Wood)
local arrival=part(training,'Arrival',V.new(0,3,160),V.one,teal,E.Material.SmoothPlastic,false); arrival.Transparency=1
sign('Instructions',V.new(30,4,169),'R: rút / cất • V: nhảy\nSpace: lướt • G: tương tác\nI: chọn vũ khí',330,65)
local decor=folder('Gardens')
local function lantern(pos)
 part(decor,'LanternPost',pos+V.new(0,4,0),V.new(.7,8,.7),wood,E.Material.Wood)
 part(decor,'LanternFrame',pos+V.new(0,8,0),V.new(2.1,2.8,2.1),gold,E.Material.Metal,false)
 local glow=part(decor,'LanternGlass',pos+V.new(0,8,0),V.new(1.8,2.4,1.8),Color.fromRGB(251,191,104),E.Material.Neon,false)
 local l=I.new('PointLight'); l.Color=glow.Color; l.Brightness=.7; l.Range=20; l.Parent=glow
end
local function tree(pos,size,index)
 local tree=folder('TrainingTree',decor)
 local trunk=part(tree,'Trunk',pos+V.new(0,size*.32,0),V.new(size*.1,size*.64,size*.11),wood,E.Material.Wood)
 trunk.CFrame*=C.Angles(.05,0,.04)
 for s=0,4 do
  local a=s*math.pi*2/5+index*.6
  local b=pos+V.new(math.cos(a)*size*.25,size*.64,math.sin(a)*size*.25)
  rod(tree,'Branch',pos+V.new(0,size*.4,0),b,size*.04,wood,E.Material.Wood)
  local crown=part(tree,'Canopy',b+V.new(0,size*.11,0),V.new(size*.58,size*.25,size*.54),Color.fromRGB(28+(s%2)*8,65+s*3,46),E.Material.Grass,false)
  crown.Shape=E.PartType.Ball
 end
end
for n=0,31 do
 local a=n*math.pi*2/32
 local x=math.cos(a)*211; local z=math.sin(a)*191
 if math.abs(x)>35 or z<0 then tree(V.new(x,0,z),42+(n%4)*7,n) end
end
tree(V.new(-156,0,-121),93,4); tree(V.new(-57,0,-170),106,2)
for _,p in {V.new(-135,0,79),V.new(-100,0,162),V.new(43,0,164),V.new(170,0,130),V.new(190,0,12),V.new(-145,0,-60),V.new(34,0,8),V.new(-113,0,-99)} do lantern(p) end
for _,x in {-198,206} do
 for z=-165,155,40 do
  part(decor,'LowWall',V.new(x,1.8,z),V.new(3,3.6,30),stone)
  part(decor,'WallCap',V.new(x,3.8,z),V.new(4.2,.5,31),gold,E.Material.Metal,false)
 end
end
local pond=folder('ReflectionPool')
part(pond,'Basin',V.new(-172,.2,-36),V.new(32,.4,82),Color.fromRGB(29,52,48))
local water=part(pond,'Water',V.new(-172,.45,-36),V.new(30,.12,80),Color.fromRGB(40,115,118),E.Material.SmoothPlastic,false); water.Transparency=.18; water.Reflectance=.12
for _,x in {-190,-154} do part(pond,'Rim',V.new(x,.75,-36),V.new(4,1.5,88),stone) end
for _,z in {-80,8} do part(pond,'Rim',V.new(-172,.75,z),V.new(40,1.5,4),stone) end
for n=1,7 do
 local leaf=disc(pond,'Lily',V.new(-179+(n%3)*7,.62,-70+n*9),2.1,.08,moss,E.Material.Grass); leaf.CanCollide=false
end
-- A perimeter barrier hidden by planted stone walls keeps practice characters on the island.
for _,edge in {{V.new(0,7,-210),V.new(460,14,3)},{V.new(0,7,210),V.new(460,14,3)},{V.new(-230,7,0),V.new(3,14,420)},{V.new(230,7,0),V.new(3,14,420)}} do
 part(decor,'Perimeter',edge[1],edge[2],stone)
end
fs.writeFile('TrainingSanctuary.rbxmx',r.serializeModel({training,templates},true))
print('BUILT training sanctuary',#training:GetDescendants(),'objects; 460 x 420; 7 weapon templates')
