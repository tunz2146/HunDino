local fs=require('@lune/fs')
local r=require('@lune/roblox')
for _,path in {'HunDino_DarkJungle_v1.1.rbxl','HunDino_DarkJungle_v1.rbxlx','C:/Users/khanh/OneDrive/Desktop/game roblox/HunDino/HunDino_DarkJungle_v1.rbxlx'} do
 if fs.isFile(path) then
  local g=r.deserializePlace(fs.readFile(path)); local w=g:GetService('Workspace'); local l=g:GetService('Lighting')
  local stats={}; local scripts={}
  for _,p in w:GetDescendants() do stats[p.ClassName]=(stats[p.ClassName] or 0)+1 end
  for _,p in g:GetDescendants() do if p:IsA('LuaSourceContainer') then table.insert(scripts,p.Name..':'..#p.Source) end end
  print(path,#g:GetDescendants(),stats,scripts)
  print('Lighting',l.TimeOfDay,l.Ambient,l.OutdoorAmbient,l.FogEnd,l.ExposureCompensation)
  print('Client matches current',g:GetService('StarterPlayer').StarterPlayerScripts.HunDinoTraining.Source==fs.readFile('src/dark-jungle/Training.client.luau'))
  if path:find('v1.1',1,true) then
   local s=g:GetService('StarterPlayer').StarterPlayerScripts.HunDinoTraining
   fs.writeFile('backups/TrainingClient_from_user_v1_1.luau',s.Source)
  end
 end
end
