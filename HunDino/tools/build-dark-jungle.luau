-- Run from HunDino. Creates a NEW place; never rebuilds or overwrites the user's L0.
local fs = require('@lune/fs')
local r = require('@lune/roblox')
local process = require('@lune/process')
local serde = require('@lune/serde')
local I, V, C, Color, E = r.Instance, r.Vector3, r.CFrame, r.Color3, r.Enum
-- Lune 0.10.5 lookAt does not produce Roblox's expected -Z basis for all directions.
-- Build the orthonormal basis explicitly so roads, rivers and cameras face their endpoints.
local function lookAt(origin, target)
 local back=(origin-target).Unit
 local seedUp=if math.abs(back.Y)>.99 then V.zAxis else V.yAxis
 local right=seedUp:Cross(back).Unit
 return C.fromMatrix(origin,right,back:Cross(right),back)
end
local output = 'HunDino_DarkJungle_v2.rbxlx'
assert(not fs.isFile(output) or table.find(process.args, '--rebuild'), 'New map already exists; use --rebuild only for the generated draft.')
local input = 'C:/Users/khanh/OneDrive/Desktop/game roblox/HunDino/HunDino_L0.rbxlx'
assert(fs.isFile(input), 'Latest authored L0 is missing')
if not fs.isDir('backups') then fs.writeDir('backups') end
local backup = 'backups/HunDino_L0_before_DarkJungle_20261005.rbxlx'
if not fs.isFile(backup) then fs.writeFile(backup, fs.readFile(input)) end
local source = r.deserializePlace(fs.readFile(backup))
assert(fs.isFile('TrainingSanctuary.rbxmx'), 'Run tools/build-training-sanctuary.luau first')
local training, weaponTemplates
for _,model in r.deserializeModel(fs.readFile('TrainingSanctuary.rbxmx')) do
 if model.Name=='Training' then training=model elseif model.Name=='TrainingWeapons' then weaponTemplates=model end
end
assert(training and weaponTemplates, 'Incomplete training sanctuary model')
local game = r.deserializePlace(fs.readFile('HunDino_original.rbxl'))
local world = game:GetService('Workspace')
for _, child in world:GetChildren() do child:Destroy() end
for _, name in {'ServerScriptService', 'ReplicatedStorage', 'ServerStorage', 'StarterGui', 'Lighting'} do
 for _, child in game:GetService(name):GetChildren() do child:Destroy() end
end
local starter = game:GetService('StarterPlayer')
local sp = starter:FindFirstChild('StarterPlayerScripts')
if not sp then sp = I.new('StarterPlayerScripts'); sp.Parent = starter end
for _, child in sp:GetChildren() do child:Destroy() end
starter.EnableMouseLockOption = false
world.StreamingEnabled = true; world.StreamingMinRadius = 128; world.StreamingTargetRadius = 768
world.FallenPartsDestroyHeight = -200
local seed = 7100512
local function random(a, b)
 seed = (seed * 48271) % 2147483647
 return a + seed / 2147483647 * (b - a)
end
local palette = {
 rock = Color.fromRGB(45, 53, 57), stone = Color.fromRGB(78, 88, 83), path = Color.fromRGB(72, 86, 75),
 soil = Color.fromRGB(43, 58, 47), moss = Color.fromRGB(57, 81, 53), wood = Color.fromRGB(61, 52, 44),
 leaf = Color.fromRGB(29, 67, 48), teal = Color.fromRGB(65, 215, 190), violet = Color.fromRGB(157, 92, 222),
 water = Color.fromRGB(35, 93, 103), gold = Color.fromRGB(148, 127, 78),
}
local function group(name, parent, class)
 local m = I.new(class or 'Folder'); m.Name = name; m.Parent = parent or world; return m
end
local root = group('DarkJungle')
root:SetAttribute('Version', 'DJ.2'); root:SetAttribute('Seed', 7100512)
root:SetAttribute('MapWidth', 1800); root:SetAttribute('MapDepth', 1800)
local land = group('TerrainRock', root)
local forest = group('Rainforest', root)
local paths = group('Paths', root)
local waters = group('Rivers', root)
local bases = group('Bases', root)
local landmarks = group('Landmarks', root)
local decorations = group('ShrinesAndFerns', root)
local main = group('HunDinoL0')
local lobby = group('Lobby', main)
local signs = group('BaseSigns', main)
local manifest = {version='DJ.2', source=input, backup=backup, bases={}, routes={}, seed=7100512}
local function part(parent, name, pos, size, col, mat, collision, shape)
 local p = I.new('Part'); p.Name = name; p.Anchored = true
 p.Size = size; p.CFrame = C.new(pos); p.Color = col or palette.rock
 p.Material = mat or E.Material.Slate; p.TopSurface = E.SurfaceType.Smooth; p.BottomSurface = E.SurfaceType.Smooth
 p.CanCollide = collision ~= false; p.CanTouch = false
 if collision == false then p.CanQuery = false end
 if shape then p.Shape = shape end
 p.Parent = parent; return p
end
local function rock(parent, pos, size, col)
 local p = part(parent, 'Basalt', pos, size, col or palette.rock)
 p.CFrame *= C.Angles(random(-.15,.15), random(0,math.pi),random(-.14,.14)); return p
end
local function orb(parent, name, pos, size, col, mat)
 return part(parent,name,pos,size,col,mat,false,E.PartType.Ball)
end
local function rod(parent, name, a, b, width, col, mat, collision)
 local p = part(parent,name,(a+b)/2,V.new((b-a).Magnitude,width,width),col,mat,collision,E.PartType.Cylinder)
 local axis=(b-a).Unit; local up=if math.abs(axis.Y)>.98 then V.new(0,0,1) else V.new(0,1,0)
 local z=axis:Cross(up).Unit; p.CFrame=C.fromMatrix((a+b)/2,axis,z:Cross(axis).Unit,z); return p
end
local function disc(parent,name,pos,radius,height,col,mat)
 local p=part(parent,name,pos,V.new(height,radius*2,radius*2),col,mat,true,E.PartType.Cylinder)
 p.CFrame *= C.Angles(0,0,math.pi/2); return p
end
local function ring(parent,center,radius,col,width,segments)
 for j=0,(segments or 36)-1 do
  local a=j*2*math.pi/(segments or 36); local b=(j+1)*2*math.pi/(segments or 36)
  rod(parent,'InlaidRuneRing',center+V.new(math.cos(a)*radius,0,math.sin(a)*radius),center+V.new(math.cos(b)*radius,0,math.sin(b)*radius),width or .3,col,E.Material.Neon,false)
 end
end
local function crystal(parent,pos,col,scale,lit)
 local m=group('Runestone',parent,'Model')
 local shard=part(m,'Crystal',pos+V.new(0,scale*2,0),V.new(scale*.85,scale*4,scale*.85),col,E.Material.Neon,false)
 shard.CFrame *= C.Angles(.12,math.pi/4,.15)
 rock(m,pos+V.new(0,scale*.2,0),V.new(scale*2,scale*.7,scale*2))
 if lit then local l=I.new('PointLight'); l.Color=col; l.Brightness=1.4; l.Range=24; l.Shadows=false; l.Parent=shard end
 return m
end
local function sign(parent,name,pos,text,col)
 local p=part(parent,name,pos,V.new(3,7,2),palette.rock)
 local ui=I.new('BillboardGui'); ui.Name='SignGui'; ui.Size=r.UDim2.fromOffset(240,62); ui.StudsOffset=V.new(0,6,0); ui.MaxDistance=100; ui.Parent=p
 local t=I.new('TextLabel'); t.Name='Text'; t.Size=r.UDim2.fromScale(1,1); t.BackgroundColor3=Color.fromRGB(12,25,26); t.BackgroundTransparency=.22
 t.TextColor3=col or Color.fromRGB(216,231,221); t.Font=E.Font.GothamMedium; t.TextSize=17; t.TextWrapped=true; t.Text=text; t.Parent=ui
 return p
end
local function prompt(p,name,action,object)
 local q=I.new('ProximityPrompt'); q.Name=name; q.ActionText=action; q.ObjectText=object; q.KeyboardKeyCode=E.KeyCode.G
 q.MaxActivationDistance=10; q.HoldDuration=.3; q.RequiresLineOfSight=false; q.Parent=p; return q
end
local function ground(x,z) return 8+.000038*(x*x+z*z)+3*math.sin(x/170)*math.cos(z/190) end
local function flat(v) return V.new(v.X,0,v.Z) end
local function polar(radius,a) return V.new(math.sin(a)*radius,0,-math.cos(a)*radius) end
local baseData={}
for i=1,12 do
 local outer=i<=8; local angle=if outer then (i-1)*math.pi/4 else (i-9)*math.pi/2
 local p=polar(if outer then 785 else 455,angle)
 p=V.new(p.X,ground(p.X,p.Z)+5,p.Z)
 table.insert(baseData,{id=i,pos=p,angle=angle,outer=outer,col=if i%3==0 then palette.violet else palette.teal})
end
local riverLines={
 {V.new(0,0,-35),V.new(100,0,55),V.new(195,0,150),V.new(320,0,245),V.new(390,0,370),V.new(540,0,460),V.new(700,0,620),V.new(825,0,730)},
 {V.new(340,0,285),V.new(520,0,260),V.new(690,0,320),V.new(860,0,420)},
}
local function segmentDistance(p,a,b)
 local d=b-a; local t=math.clamp((p-a):Dot(d)/d:Dot(d),0,1); return (p-a-d*t).Magnitude
end
local function riverDist(x,z)
 local p=V.new(x,0,z); local dist=1e9
 for _, points in riverLines do for j=1,#points-1 do dist=math.min(dist,segmentDistance(p,points[j],points[j+1])) end end
 return dist
end
local routeSegments={}
local function route(name,points,width,mat)
 local f=group(name,paths,'Model'); local length=0
 for j=1,#points-1 do
  local a,b=points[j],points[j+1]; length+=(b-a).Magnitude
  local steps=math.ceil((b-a).Magnitude/22)
  for k=0,steps-1 do
   local u=a:Lerp(b,k/steps); local v=a:Lerp(b,(k+1)/steps)
   local p=part(f,'WalkSurface',(u+v)/2,V.new(width,2,(v-u).Magnitude+1.2),palette.path,mat or E.Material.Cobblestone)
   p.CFrame=lookAt((u+v)/2,v)
   p:SetAttribute('WalkWidth',width)
   p:SetAttribute('RouteStart',u); p:SetAttribute('RouteEnd',v)
   table.insert(routeSegments,{a=flat(u),b=flat(v),width=width})
   if k%3==0 then
    local side=lookAt((u+v)/2,v).RightVector*(width/2+1)
    for _,s in {-1,1} do
     local trim=part(f,'MossEdging',(u+v)/2+side*s+V.new(0,1,0),V.new(1.5,1.4,(v-u).Magnitude+1),palette.moss)
     trim.CFrame=lookAt(trim.CFrame.Position,trim.CFrame.Position+(v-u))
    end
   end
   if riverDist(u.X,u.Z)<45 then
    for _,s in {-1,1} do
     local side=lookAt(u,v).RightVector*(width/2+1)
     rod(f,'BridgeBalustrade',u+side*s+V.new(0,4,0),v+side*s+V.new(0,4,0),1.2,palette.wood,E.Material.Wood,true)
     part(f,'BridgePier',u+side*s-V.new(0,12,0),V.new(3,26,3),palette.rock)
    end
   end
  end
 end
 table.insert(manifest.routes,{name=name,width=width,length=math.floor(length)})
 return f
end
local function pathPoint(p) return V.new(p.X,ground(p.X,p.Z)+5,p.Z) end
local ringPoints={}
for j=0,64 do table.insert(ringPoints,pathPoint(polar(620,j*math.pi/32))) end
route('AncientRingRoad',ringPoints,28)
local innerRing={}
for j=0,48 do table.insert(innerRing,pathPoint(polar(285,j*math.pi/24))) end
route('SanctuaryWalk',innerRing,28)
for _,b in baseData do
 local mainPoints={b.pos,pathPoint(polar(if b.outer then 620 else 570,b.angle))}
 if not b.outer then mainPoints={b.pos,pathPoint(polar(530,b.angle+.18)),pathPoint(polar(620,b.angle+.23))} end
 route('Base'..b.id..'_Safe',mainPoints,28)
 local secondary={b.pos,pathPoint(polar(if b.outer then 680 else 375,b.angle+.19)),pathPoint(polar(if b.outer then 570 else 285,b.angle+.30))}
 route('Base'..b.id..'_Forest',secondary,16,E.Material.Ground)
 if b.outer then
  route('Inward'..b.id,{pathPoint(polar(620,b.angle+.28)),pathPoint(polar(510,b.angle+.31)),pathPoint(polar(390,b.angle+.32)),pathPoint(polar(285,b.angle+.32))},28)
 end
end
local plaza=V.new(0,18,165)
for _,a in {math.pi/2,math.pi,math.pi*1.5} do route('SanctuaryLink'..a,{pathPoint(polar(285,a)),plaza},28) end
local function freeOfRoutes(p,margin)
 for _,s in routeSegments do if segmentDistance(flat(p),s.a,s.b)<s.width/2+margin then return false end end
 return true
end
-- Tile geology is static and editable in Studio; roads are continuous inclined slabs, not jump puzzles.
for x=-870,870,60 do for z=-870,870,60 do
 if (math.max(math.abs(x)-690,0)^2+math.max(math.abs(z)-690,0)^2)<195^2 then
  local top=ground(x,z)-1
  local pool=((x/94)^2+((z+25)/94)^2)<1
  local swamp=((x+660)/140)^2+((z+155)/160)^2<1
  if riverDist(x,z)<42 or pool then top=-9 elseif swamp then top=1 end
  part(land,'Bedrock',V.new(x,top/2-44,z),V.new(60,top+88,60),palette.rock)
  part(land,'ForestFloor',V.new(x,top-.6,z),V.new(60,1.2,60),palette.soil,E.Material.Ground)
  if top<2 then
   local water=part(waters,'WaterSurface',V.new(x,1.8,z),V.new(60,.4,60),if top<0 then palette.water else Color.fromRGB(40,85,65),E.Material.SmoothPlastic,false)
   water.Transparency=.22; water.Reflectance=.12; water.CastShadow=false
  end
 end
end end
-- Irregular outer silhouette hides the square terrain grid.
for j=0,167 do
 local a=j*2*math.pi/168; local radius=855+random(-12,24); local p=polar(radius,a)
 rock(land,V.new(p.X,ground(p.X,p.Z)-19,p.Z),V.new(random(30,62),random(60,100),random(30,60)))
end
local function tree(parent,pos,height,ancient,col)
 local m=group(if ancient then 'AncientTree' else 'CanopyTree',parent,'Model')
 local crown=pos+V.new(height*.055,height*.78,0)
 local width=height*(if ancient then .105 else .095)
 local bend=pos+V.new(-height*.04,height*.42,height*.025)
 rod(m,'ButtressTrunk',pos,bend,width,palette.wood,E.Material.Wood,true)
 rod(m,'CrownTrunk',bend,crown,width*.68,palette.wood,E.Material.Wood,true)
 local count=if ancient then 7 else 4
 for j=1,count do
  local a=j*2*math.pi/count+random(-.2,.2)
  local endPoint=crown+V.new(math.cos(a)*height*.28,random(-.07,.10)*height,math.sin(a)*height*.28)
  rod(m,'LateralLimb',bend:Lerp(crown,.55),endPoint,width*.4,palette.wood,E.Material.Wood,true)
  for k=1,if ancient then 3 else 2 do
   local leafPos=endPoint+V.new(random(-.10,.10)*height,random(0,.09)*height,random(-.1,.1)*height)
   local tint=random(.8,1.15)
   orb(m,'BroadleafCrown',leafPos,V.new(height*.54,height*.23,height*.48),Color.new(.12*tint,.27*tint,.19*tint),E.Material.Grass)
  end
  if ancient or j%2==0 then
   local foot=pos+V.new(math.cos(a)*height*.23,1,math.sin(a)*height*.23)
   rod(m,'SurfaceRoot',pos+V.new(0,height*.12,0),foot,width*.55,palette.wood,E.Material.Wood,true)
  end
  if ancient then
   local tip=endPoint-V.new(0,height*.31,0)
   rod(m,'HangingVine',endPoint,tip,.65,palette.moss,E.Material.Grass,false)
  end
 end
 if ancient then
  for j=1,5 do
   local p=pos+V.new(width*.48,j*height*.08,-width*.33)
   rod(m,'TrunkRune',p,p+V.new(1.8,4,0),1.05,col or palette.teal,E.Material.Neon,false)
  end
 end
 return m
end
local function fern(parent,pos,scale)
 for j=0,4 do
  local a=j*math.pi*2/5
  local p=part(parent,'FernFrond',pos+V.new(math.cos(a)*scale,scale*.7,math.sin(a)*scale),V.new(scale*.65,.3,scale*2.6),palette.moss,E.Material.Grass,false)
  p.CFrame *= C.Angles(.35,-a+math.pi/2,.13)
 end
end
local function mushroom(parent,pos,scale,col)
 rod(parent,'MushroomStalk',pos,pos+V.new(0,scale*2.6,0),scale*.55,palette.stone,E.Material.SmoothPlastic,false)
 orb(parent,'BioluminescentCap',pos+V.new(0,scale*2.6,0),V.new(scale*3,scale*.9,scale*3),col,E.Material.SmoothPlastic)
 orb(parent,'LuminousGills',pos+V.new(0,scale*2.42,0),V.new(scale*2.6,scale*.22,scale*2.6),col,E.Material.Neon)
end
local function ruinedGate(parent,origin,angle,col)
 local cf=C.new(origin)*C.Angles(0,-angle,0)
 for _,side in {-1,1} do
  local p=part(parent,'GatePillar',cf:PointToWorldSpace(V.new(side*12,12,0)),V.new(5,24,6),palette.stone)
  p.CFrame=cf*C.new(side*12,12,0)
  rod(parent,'GateRune',cf:PointToWorldSpace(V.new(side*12,3,-3.15)),cf:PointToWorldSpace(V.new(side*12,21,-3.15)),.65,col,E.Material.Neon,false)
 end
 local lintel=part(parent,'MossyArchitrave',cf:PointToWorldSpace(V.new(0,25,0)),V.new(32,5,9),palette.rock)
 lintel.CFrame=cf*C.new(0,25,0)
end
-- Each 170-stud base has two unblocked exits, one small ruin shelter and a clear spawn pad.
for _,b in baseData do
 local m=group('Base'..b.id,bases,'Model'); m:SetAttribute('BaseId',b.id); m:SetAttribute('Ring',if b.outer then 'Outer' else 'Middle')
 disc(m,'TerraceFoundation',b.pos-V.new(0,8,0),85,16,palette.rock)
 disc(m,'Ground',b.pos,85,2,palette.stone,E.Material.Cobblestone)
 ring(m,b.pos+V.new(0,1.2,0),64,b.col,.38,36)
 ring(m,b.pos+V.new(0,1.25,0),17,b.col,.35,24)
 for j=0,13 do
  local a=j*math.pi/7
  if j~=0 and j~=1 and j~=6 and j~=7 and j~=8 then
   local p=b.pos+polar(77,a)
   if freeOfRoutes(p,13) then
    rock(m,p+V.new(0,random(3,6),0),V.new(8,random(8,16),9))
    if j%3==0 then crystal(m,p+V.new(0,9,0),b.col,1.6,false) end
   end
  end
 end
 -- Small roofed ruin is offset to preserve sightlines into the base.
 local h=b.pos+V.new(-38,1,22)
 for k=0,23 do
  local candidate=b.pos+polar(46,k*math.pi/12)+V.new(0,1,0)
  if freeOfRoutes(candidate,25) then h=candidate; break end
 end
 part(m,'ShelterFloor',h,V.new(29,1,25),palette.rock)
 for _,x in {-12,12} do for _,z in {-10,10} do
  part(m,'ShelterColumn',h+V.new(x,8,z),V.new(3,16,3),palette.stone)
 end end
 for _,side in {-1,1} do
  local roof=part(m,'WeatheredRoof',h+V.new(side*8,18,0),V.new(18,2,29),palette.wood,E.Material.WoodPlanks)
  roof.CFrame *= C.Angles(0,0,side*-.28)
 end
 local tower=b.pos+V.new(45,0,34)
 for k=0,23 do
  local candidate=b.pos+polar(62,k*math.pi/12)
  if freeOfRoutes(candidate,15) and (candidate-h).Magnitude>36 then tower=candidate; break end
 end
 part(m,'WatchPlatform',tower+V.new(0,6,0),V.new(17,12,17),palette.rock)
 crystal(m,tower+V.new(0,13,0),b.col,2,true)
 local exit=b.pos-polar(69,b.angle)
 ruinedGate(m,exit,b.angle,b.col)
 local s=sign(signs,'Base'..b.id,exit+V.new(18,5,0),string.format('BASE %02d\nChưa có chủ',b.id),b.col); s:SetAttribute('BaseId',b.id)
 local spawn=part(m,'SpawnPad',b.pos+V.new(0,1.3,0),V.new(12,.4,12),b.col,E.Material.Slate,false)
 spawn:SetAttribute('ReservedSpawn',true)
 for k=0,23 do
  local candidate=b.pos+polar(59,k*math.pi/12)+V.new(0,1,0)
  if freeOfRoutes(candidate,22) and (candidate-h).Magnitude>39 and (candidate-tower).Magnitude>25 then tree(m,candidate,65,false); break end
 end
 table.insert(manifest.bases,{id=b.id,x=b.pos.X,y=b.pos.Y,z=b.pos.Z,diameter=170,ring=if b.outer then 'outer' else 'middle',exits=2})
end
-- Central gathering plaza and the training portal.
disc(lobby,'Sanctuary',plaza-V.new(0,5,0),95,10,palette.rock)
disc(lobby,'SanctuaryFloor',plaza,92,2,palette.stone,E.Material.Cobblestone)
ring(lobby,plaza+V.new(0,1.2,0),70,palette.teal,.4,48)
ring(lobby,plaza+V.new(0,1.3,0),31,palette.gold,.5,32)
for j=0,7 do crystal(lobby,plaza+polar(83,j*math.pi/4)+V.new(0,1,0),if j%2==0 then palette.teal else palette.violet,2,j%2==0) end
local spawn=I.new('SpawnLocation'); spawn.Name='LobbySpawn'; spawn.Size=V.new(12,1,12); spawn.CFrame=C.new(plaza+V.new(0,2,16))
spawn.Anchored=true; spawn.Neutral=true; spawn.Duration=0; spawn.Transparency=1; spawn.CanCollide=false; spawn.Parent=lobby
local arrival=part(lobby,'Arrival',plaza+V.new(0,5,16),V.new(1,1,1),palette.teal,false,false)
arrival.Transparency=1
local gatePos=plaza+V.new(58,1,-23)
ruinedGate(lobby,gatePos,math.pi/2,palette.teal)
local gate=part(lobby,'ToTraining',gatePos+V.new(0,5,0),V.new(2,10,18),palette.teal,E.Material.ForceField,false)
gate.Transparency=.68; prompt(gate,'ToTrainingPrompt','Vào bãi tập','Cổng thợ săn')
sign(lobby,'TrainingSign',gatePos+V.new(-5,6,15),'BÃI LUYỆN TẬP\nGiữ G để đi qua',palette.teal)
sign(lobby,'Welcome',plaza+V.new(-38,7,16),'HUNDINO\nTHÁNH ĐỊA RỪNG CỔ',palette.teal)
-- Basalt amphitheatre, three cascades, open secret grotto (no solid block behind its entrance).
local falls=group('ThreeTierWaterfall',landmarks,'Model')
for j=0,14 do
 local a=math.pi+j*math.pi/14; local p=V.new(math.cos(a)*115,0,-185+math.sin(a)*65)
 rock(falls,V.new(p.X,52,p.Z),V.new(random(20,35),random(100,128),random(22,42)))
end
for _,x in {-92,92} do rock(falls,V.new(x,52,-143),V.new(38,104,110)) end
part(falls,'GrottoRoof',V.new(0,68,-150),V.new(170,24,120),palette.rock)
part(falls,'GrottoFloor',V.new(0,8,-160),V.new(152,4,117),palette.stone)
local altar=part(falls,'SecretAltar',V.new(0,14,-185),V.new(22,9,12),palette.rock)
ring(falls,V.new(0,10.3,-163),28,palette.violet,.6,24)
for _,x in {-52,-26,26,52} do crystal(falls,V.new(x,10,-177),palette.violet,3,true) end
sign(falls,'GrottoMarker',V.new(-65,15,-165),'ĐỀN SAU THÁC',palette.violet)
route('GrottoApproach',{pathPoint(V.new(-275,0,-45)),V.new(-130,14,-50),V.new(-58,10,-70),V.new(-40,10,-125),V.new(0,10,-144)},16)
local function spray(parent,pos,width)
 local p=part(parent,'MistSource',pos,V.new(width,1,4),palette.water,E.Material.SmoothPlastic,false); p.Transparency=1
 local e=I.new('ParticleEmitter'); e.Texture='rbxasset://textures/particles/smoke_main.dds'
 e.Color=r.ColorSequence.new(Color.fromRGB(164,197,192)); e.Size=r.NumberSequence.new({r.NumberSequenceKeypoint.new(0,5),r.NumberSequenceKeypoint.new(1,18)})
 e.Transparency=r.NumberSequence.new({r.NumberSequenceKeypoint.new(0,.72),r.NumberSequenceKeypoint.new(1,1)})
 e.Lifetime=r.NumberRange.new(1.4,2.4); e.Rate=8; e.Speed=r.NumberRange.new(3,8); e.SpreadAngle=r.Vector2.new(35,35); e.LightEmission=.15; e.Parent=p
end
local tiers={{y=123,z=-216,bottom=84,front=-164,width=42},{y=84,z=-163,bottom=46,front=-108,width=67},{y=46,z=-105,bottom=0,front=-48,width=88}}
for i,t in tiers do
 part(falls,'Ledge'..i,V.new(0,t.y-6,(t.z+t.front)/2),V.new(t.width+26,12,math.abs(t.front-t.z)+6),palette.rock)
 local run=part(falls,'UpperWater'..i,V.new(0,t.y+.4,(t.z+t.front)/2),V.new(t.width,.8,math.abs(t.front-t.z)),palette.water,E.Material.Glass,false); run.Transparency=.18
 for j=-3,3 do
  local x=j*t.width/7
  local sheet=part(falls,'WaterCurtain',V.new(x,(t.y+t.bottom)/2,t.front+2),V.new(t.width/7+.2,t.y-t.bottom,2.2),Color.fromRGB(139,189,190),E.Material.SmoothPlastic,false)
  sheet.Transparency=.14+random(0,.12); sheet.Reflectance=.06
  local stream=part(falls,'FoamThread',V.new(x+random(-2,2),(t.y+t.bottom)/2,t.front+3.3),V.new(random(1,2.4),t.y-t.bottom,0.25),Color.fromRGB(190,218,213),E.Material.Neon,false)
  stream.Transparency=.55
  for k=1,2 do orb(falls,'Foam',V.new(x+random(-3,3),if t.bottom==0 then 2.3 else t.bottom+.4,t.front+random(1,8)),V.new(random(5,11),.5,random(3,8)),Color.fromRGB(157,191,187),E.Material.SmoothPlastic).Transparency=.3 end
 end
 spray(falls,V.new(0,t.bottom+2,t.front+4),t.width)
end
-- Break up the box silhouette with basalt shoulders, moss shelves and roots.
-- Ornament is non-collidable and stays outside the grotto access path.
for tier,t in tiers do
 for _,side in {-1,1} do
  for j=0,5 do
   local height=17+(j%3)*9
   local p=V.new(side*(t.width/2+13+(j%2)*8),t.y-height/2-3,t.front-8-j*10)
   local shoulder=rock(falls,p,V.new(19,height,23)); shoulder.CanCollide=false
   orb(falls,'MossShelf',p+V.new(0,height/2+.7,0),V.new(23,3,24),palette.moss,E.Material.Grass)
   if j%2==0 then fern(falls,p+V.new(0,height/2+2,0),4) end
  end
 end
end
tree(landmarks,V.new(-148,ground(-148,-172),-172),210,true,palette.teal)
for j,p in {V.new(-720,0,-670),V.new(720,0,-670),V.new(-720,0,670),V.new(720,0,670),V.new(-770,0,280),V.new(770,0,-280)} do
 tree(landmarks,V.new(p.X,ground(p.X,p.Z),p.Z),random(115,145),true,if j%2==0 then palette.teal else palette.violet)
end
-- West wetland, east ruin, south fungal grove and north mountain shrines.
local swamp=group('WestWhisperingMire',landmarks,'Model')
for j=1,14 do local p=V.new(-660+random(-95,95),3,-155+random(-105,105)); rod(swamp,'DeadTrunk',p,p+V.new(random(-6,6),random(20,38),0),3,palette.wood,E.Material.Wood,true); mushroom(swamp,p,random(1,3),palette.teal) end
local ruins=group('EastForgottenTemple',landmarks,'Model')
local temple=V.new(695,ground(695,245)+3,245)
part(ruins,'TemplePlatform',temple,V.new(115,6,92),palette.rock)
for _,x in {-42,-14,14,42} do for _,z in {-29,29} do
 local p=temple+V.new(x,3,z); local h=random(14,31); rod(ruins,'BrokenColumn',p,p+V.new(0,h,0),5,palette.stone,E.Material.Slate,true)
end end
ruinedGate(ruins,temple+V.new(0,3,-35),0,palette.teal)
ring(ruins,temple+V.new(0,3.2,0),25,palette.teal,.4,24)
route('TempleApproach',{pathPoint(polar(620,math.atan2(temple.X,-temple.Z))),temple+V.new(0,4,-65),temple+V.new(0,4,-25),temple+V.new(0,4,0)},20)
local grove=group('SouthLuminousGrove',landmarks,'Model')
for j=1,36 do
 local p=V.new(random(-240,170),0,random(590,740)); local clear=true
 for _,b in baseData do if (flat(b.pos)-p).Magnitude<110 then clear=false end end
 for _,s in routeSegments do if segmentDistance(p,s.a,s.b)<s.width/2+12 then clear=false end end
 if clear then mushroom(grove,V.new(p.X,ground(p.X,p.Z),p.Z),random(3,8),if j%3==0 then palette.teal else palette.violet) end
end
local north=group('NorthObsidianPass',landmarks,'Model')
for j=1,18 do
 local x=random(-235,235); local z=random(-730,-625)
 if math.abs(x)>55 and freeOfRoutes(V.new(x,0,z),32) then rock(north,V.new(x,ground(x,z)+25,z),V.new(random(20,40),random(45,85),random(20,35))) end
end
local treeCount=0
for x=-820,820,54 do for z=-820,820,54 do
 local p=V.new(x+random(-17,17),0,z+random(-17,17))
 local free=(math.abs(p.X)<820 and math.abs(p.Z)<820 and p.Magnitude>320 and riverDist(p.X,p.Z)>65 and freeOfRoutes(p,24))
 for _,b in baseData do if (flat(b.pos)-p).Magnitude<113 then free=false; break end end
 if ((p.X+660)/165)^2+((p.Z+155)/180)^2<1 or (p-temple*V.new(1,0,1)).Magnitude<100 then free=false end
 if free then
  treeCount+=1; tree(forest,V.new(p.X,ground(p.X,p.Z),p.Z),random(46,83),false)
  if treeCount%2==0 then fern(decorations,V.new(p.X+14,ground(p.X,p.Z),p.Z+9),random(2,4)) end
  if treeCount%4==0 then mushroom(decorations,V.new(p.X-10,ground(p.X,p.Z),p.Z+10),random(1,2.5),palette.violet) end
  if treeCount%9==0 then crystal(decorations,V.new(p.X+12,ground(p.X,p.Z),p.Z-12),palette.teal,1.8,false) end
 end
end end
-- Dense small vegetation along the cliffs, but never on either exit or road centerline.
for j=1,190 do
 local p=V.new(random(-800,800),0,random(-800,800))
 local clear=p.Magnitude>330 and freeOfRoutes(p,13) and riverDist(p.X,p.Z)>55
 for _,b in baseData do if (flat(b.pos)-p).Magnitude<102 then clear=false end end
 if clear then rock(decorations,V.new(p.X,ground(p.X,p.Z)+2,p.Z),V.new(random(5,15),random(4,9),random(5,13)),palette.moss) end
end
-- The sanctuary builder already places training outside the lobby island.
training.Parent=main
weaponTemplates.Parent=game:GetService('ServerStorage')
local shared=group('Shared',game:GetService('ReplicatedStorage'))
local function script(class,name,path,parent)
 local s=I.new(class); s.Name=name; s.Source=fs.readFile(path); s.Parent=parent; return s
end
script('ModuleScript','TrainingConfig','src/shared/TrainingConfig.luau',shared)
script('ModuleScript','CombatRules','src/shared/CombatRules.luau',shared)
script('ModuleScript','Weapons','src/dark-jungle/Weapons.luau',shared)
script('ModuleScript','TrainingRules','src/dark-jungle/TrainingRules.luau',shared)
script('Script','HunDinoTraining','src/dark-jungle/Training.server.luau',game:GetService('ServerScriptService'))
script('LocalScript','HunDinoTraining','src/dark-jungle/Training.client.luau',sp)
script('Script','JungleTraversal','src/dark-jungle/Traversal.server.luau',game:GetService('ServerScriptService'))
local light=game:GetService('Lighting')
light.ClockTime=16.1; light.TimeOfDay='16:06:00'; light.Brightness=2.6; light.GlobalShadows=true
light.FogStart=0; light.FogEnd=100000; light.FogColor=Color.fromRGB(83,105,112)
light.ColorShift_Top=Color.new(0,0,0); light.ColorShift_Bottom=Color.new(0,0,0)
light.Ambient=Color.fromRGB(120,135,143); light.OutdoorAmbient=Color.fromRGB(135,148,153)
light.EnvironmentDiffuseScale=.35; light.EnvironmentSpecularScale=.45; light.ExposureCompensation=.3
local atmosphere=I.new('Atmosphere'); atmosphere.Density=.08; atmosphere.Offset=0
atmosphere.Color=Color.fromRGB(149,180,183); atmosphere.Decay=Color.fromRGB(60,76,86); atmosphere.Haze=.35; atmosphere.Glare=.1; atmosphere.Parent=light
local bloom=I.new('BloomEffect'); bloom.Intensity=.25; bloom.Size=28; bloom.Threshold=1.4; bloom.Parent=light
local grade=I.new('ColorCorrectionEffect'); grade.Saturation=-.23; grade.Contrast=.08; grade.TintColor=Color.fromRGB(204,223,229); grade.Parent=light
local camera=I.new('Camera'); camera.Name='Camera'; camera.CFrame=lookAt(V.new(1080,1290,1360),V.new(0,0,-25)); camera.Focus=C.new(0,0,-25); camera.FieldOfView=60; camera.Parent=world
world.CurrentCamera=camera
root:SetAttribute('ForestTreeCount',treeCount)
manifest.forestTrees=treeCount; manifest.instances=#game:GetDescendants()
fs.writeFile(output,r.serializePlace(game,true))
fs.writeFile('DarkJungle_manifest.json',serde.encode('json',manifest,true))
print('BUILT',output,'trees',treeCount,'instances',manifest.instances)
