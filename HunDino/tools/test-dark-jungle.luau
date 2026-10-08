local fs=require('@lune/fs')
local r=require('@lune/roblox')
local luau=require('@lune/luau')
local serde=require('@lune/serde')
local process=require('@lune/process')
local g=r.deserializePlace(fs.readFile(process.args[1] or 'HunDino_DarkJungle_v2.rbxlx'))
local w=g:GetService('Workspace')
local root=w.DarkJungle
local sanctuary=w.HunDinoL0.Training:FindFirstChild('WeaponRacks')~=nil
local manifest=serde.decode('json',fs.readFile('DarkJungle_manifest.json'))
local passed=0
local function test(name,run) run(); passed+=1; print('PASS',name) end
test('12 bases: eight outer, four middle, >=220 center spacing',function()
 assert(#root.Bases:GetChildren()==12)
 local outer=0
 for i,b in manifest.bases do
  if b.ring=='outer' then outer+=1 end
  for j,c in manifest.bases do if j>i then assert(((b.x-c.x)^2+(b.z-c.z)^2)^.5>=220) end end
  assert(b.diameter==170 and b.exits==2)
 end
 assert(outer==8)
end)
test('Base exits connect to continuous safe and forest routes',function()
 for i=1,12 do
  for _,suffix in {'_Safe','_Forest'} do
   local route=assert(root.Paths:FindFirstChild('Base'..i..suffix))
   assert(#route:GetChildren()>2)
  end
 end
 for _,p in root.Paths:GetDescendants() do if p:IsA('BasePart') and p.Name=='WalkSurface' then
  assert(p.Anchored and p.CanCollide)
  assert(math.abs(p.CFrame.LookVector.Y)<.4,'Steep route '..p:GetFullName())
  local a,b=p:GetAttribute('RouteStart'),p:GetAttribute('RouteEnd')
  assert(a and b,'Route endpoints missing')
  assert(p.CFrame.LookVector:Dot((b-a).Unit)>.999,'Slab faces across its route: '..p:GetFullName())
  -- Both route endpoints must lie on this slab, including after XML serialization.
  for _,point in {a,b} do
   local q=p.CFrame:PointToObjectSpace(point)
   assert(math.abs(q.X)<.1 and math.abs(q.Y)<.1 and math.abs(q.Z)<=p.Size.Z/2+.05,'Disconnected slab')
  end
 end end
end)
test('Single spawn safely above sanctuary, return marker and training gates exist',function()
 local spawnCount=0
 for _,v in w:GetDescendants() do if v:IsA('SpawnLocation') and v.Enabled then spawnCount+=1 end end
 assert(spawnCount==1)
 assert(w.HunDinoL0.Lobby.Arrival.CFrame.Position.Y>20)
 assert(w.HunDinoL0.Lobby.ToTraining:FindFirstChildOfClass('ProximityPrompt'))
 assert(w.HunDinoL0.Training.ToLobby:FindFirstChildOfClass('ProximityPrompt'))
 assert(w.HunDinoL0.Training.Arrival.CFrame.Position.X>1200)
 assert(#w.HunDinoL0.Training.Dummies:GetChildren()==(if sanctuary then 7 else 3))
end)
test('Every active script compiles; exactly one base owner system',function()
 local scripts={}
 for _,s in g:GetDescendants() do if s:IsA('LuaSourceContainer') then
  luau.compile(s.Source); table.insert(scripts,s.Name)
  assert(not s.Source:find('Giant tree is falling',1,true))
  assert(s.Name~='BaseClaimSystem')
 end end
 assert(#scripts==(if sanctuary then 7 else 5),'Unexpected script count '..#scripts)
 local src=g:GetService('ServerScriptService').HunDinoTraining.Source
 assert(src:find('else map.Lobby.Arrival.CFrame',1,true))
end)
test('Static geometry anchored; no imported mesh/network asset dependency',function()
 local count=0
 for _,p in w:GetDescendants() do
  if p:IsA('BasePart') then assert(p.Anchored,p:GetFullName()); count+=1 end
  assert(not p:IsA('MeshPart'),'Unexpected network mesh')
 end
 assert(count<22000,'Geometry budget exceeded')
end)
test('Three waterfall stages, seven ancient trees, four biomes',function()
 for i=1,3 do assert(root.Landmarks.ThreeTierWaterfall:FindFirstChild('Ledge'..i)) end
 local trees=0
 for _,p in root.Landmarks:GetChildren() do if p.Name=='AncientTree' then trees+=1 end end
 assert(trees==7)
 for _,name in {'WestWhisperingMire','EastForgottenTemple','SouthLuminousGrove','NorthObsidianPass'} do assert(root.Landmarks:FindFirstChild(name)) end
end)
-- Conservative OBB samples: finds scenery crossing road centerlines at avatar torso height.
-- Cylinders use their box bounds, so reported candidates still need review.
local bins={}
for _,p in root:GetDescendants() do
 if p:IsA('BasePart') and p.CanCollide and not p:IsDescendantOf(root.Paths) and not p:IsDescendantOf(root.TerrainRock) and p.Name~='Ground' and p.Name~='TerraceFoundation' then
  local center=p.CFrame.Position; local radius=p.Size.Magnitude/2
  for x=math.floor((center.X-radius)/64),math.floor((center.X+radius)/64) do
   for z=math.floor((center.Z-radius)/64),math.floor((center.Z+radius)/64) do
    local key=x..':'..z; bins[key]=bins[key] or {}; table.insert(bins[key],p)
   end
  end
 end
end
local blocked={}
for _,p in root.Paths:GetDescendants() do if p:IsA('BasePart') and p.Name=='WalkSurface' then
 for _,t in {-.4,0,.4} do
  local point=p.CFrame:PointToWorldSpace(r.Vector3.new(0,4,p.Size.Z*t))
  local key=math.floor(point.X/64)..':'..math.floor(point.Z/64)
  for _,obj in bins[key] or {} do
   local q=obj.CFrame:PointToObjectSpace(point); local s=obj.Size/2
   if math.abs(q.X)<s.X+1 and math.abs(q.Y)<s.Y+1 and math.abs(q.Z)<s.Z+1 then blocked[obj:GetFullName()..' at '..tostring(obj.CFrame.Position)..' on '..p.Parent.Name]=true end
  end
 end
end end
local candidates={}; for name in blocked do table.insert(candidates,name) end; table.sort(candidates)
print('ROAD_OBSTACLE_CANDIDATES',#candidates)
for _,name in candidates do print(name) end
assert(#candidates==0,'Road centerline obstructed; review listed scenery')
print('PASSED',passed,'structural groups')
