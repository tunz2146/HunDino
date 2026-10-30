-- One canonical account per player. Economic changes are committed before success.
local Players=game:GetService("Players")
local DataStoreService=game:GetService("DataStoreService")
local HttpService=game:GetService("HttpService")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Store=require(script.Parent.ProfileStore)
local Schema=require(script.Parent.ProfileSchema)
local Config=require(script.Parent.ProfileConfig)
local Economy=require(game.ServerScriptService.HuntingRuntime.HuntEconomyRules)
local Service={}
Service.__index=Service
local SLOTS={"Head","Chest","Arms","Waist","Legs"}
local PREFS={ShowComboGuide=true,ShowDamage=true,ShowComboFX=true,AimSensitivity=true,AutoBowAim=true,AutoBowFire=true,SwapBowButtons=true,MeleeStance=true,RangedStance=true,KatanaCarry=true}
local TEXT={
 Loading="Đang tải tiến trình tài khoản…",Loaded="Đã tải tiến trình.",
 Dirty="Có thay đổi, đang chờ lưu…",Saving="Đang lưu tiến trình…",Saved="Đã lưu tiến trình.",
 Error="Chưa lưu được. Đã giữ bản đang chờ; hãy thử lưu lại.",
 Unavailable="Map chưa xuất bản. Cần xuất bản game để dùng lưu tài khoản.",
 Conflict="Hồ sơ đang được dùng ở máy chủ khác. Hãy chờ rồi thử tải lại.",
 Closing="Đang lưu trước khi rời…",
}
local function set(p,k,v) if p.Parent and p:GetAttribute(k)~=v then p:SetAttribute(k,v) end end
local function replace(dst,src) table.clear(dst);for k,v in src do dst[k]=v end end
local function copy(value)
 if type(value)~="table" then return value end
 local out={};for k,v in value do out[k]=copy(v) end;return out
end
function Service.new(options)
 local self=setmetatable({Entries={},Connections={},Schema=Schema.new(Economy),Now=os.time,
  ServerNow=function() return workspace:GetServerTimeNow() end,Mode="DataStore",Stopped=false},Service)
 for k,v in options or {} do self[k]=v end
 self.Remote=Instance.new("RemoteEvent");self.Remote.Name="HunDinoProfileAction";self.Remote.Parent=ReplicatedStorage
 table.insert(self.Connections,self.Remote.OnServerEvent:Connect(function(p,action,key,value)
  self:Request(p,action,key,value)
 end))
 Service.Current=self
 task.spawn(function()
  while not self.Stopped do
   task.wait(1)
   local now=os.clock()
   for p,e in self.Entries do
    if e.RecoveryData and not e.Loading and not e.Closing and now>=(e.NextRecoveryAt or 0) then
     e.NextRecoveryAt=now+Config.RetrySeconds
     task.spawn(function() self:Load(p) end)
    end
    if e.Ready and not e.Saving and not e.Closing and
     ((e.DirtyAt and now>=e.DirtyAt+Config.DebounceSeconds) or now>=e.NextSave) then
     e.DirtyAt=nil
     task.spawn(function() self:Save(p) end)
    end
   end
  end
 end)
 return self
end
function Service:_repository()
 if self.Repository then return self.Repository end
 local backend
 if RunService:IsStudio() and (Config.StudioMemoryTest or script.Parent:GetAttribute("StudioMemoryTest")==true) then
  -- Deliberately explicit QA mode, never an automatic fallback after a DS error.
  self.TestRecords=self.TestRecords or {}
  local records=self.TestRecords
  backend={UpdateAsync=function(_,key,transform)
   if (self.TestFailWrites or 0)>0 then self.TestFailWrites-=1;error("Injected Studio QA outage") end
   local result=transform(copy(records[key]))
   if result~=nil then records[key]=copy(result) end
   return copy(result)
  end}
  self.Mode="TestMemory"
  local probe=Instance.new("BindableFunction");probe.Name="StudioProfileProbe";probe.Parent=script.Parent
  probe.OnInvoke=function(action,p,value)
   if action=="Snapshot" then return copy(self:Data(p)) end
   if action=="Save" then return self:Save(p) end
   if action=="Reload" then self:Release(p);return self:Load(p) end
   if action=="Outage" then self.TestFailWrites=value;return true end
   if action=="Records" then return copy(self.TestRecords) end
  end
 elseif RunService:IsStudio() and Config.StudioLocalFileEnabled==true then
  self.Mode="LocalFile"
  self.AutoSaveSeconds=3
  self.LeaseSeconds=10
  local ok,result=pcall(function() return require(script.Parent.StudioLocalStore).new() end)
  if not ok then
   warn("[HunDino Local Save]",result)
   return nil,"Unavailable"
  end
  backend=result
 else
  if game.GameId==0 or game.PlaceId==0 then return nil,"Unavailable" end
  local ok,result=pcall(function()
   return DataStoreService:GetDataStore(if RunService:IsStudio() then Config.StudioStoreName else Config.StoreName,Config.Scope)
  end)
  if not ok then return nil,"Unavailable" end
  backend=result
 end
 self.Repository=Store.new({Store=backend,Token=game.JobId..":"..HttpService:GenerateGUID(false),
  Now=self.Now,Sleep=task.wait,Validate=self.Schema.Validate,Encode=self.Schema.Encode,
  LeaseSeconds=self.LeaseSeconds or Config.LeaseSeconds,MaxAttempts=4,BaseDelay=.5,MaxDelay=3})
 return self.Repository
end
function Service:_state(p,e,state,code)
 e.State=state;e.ErrorCode=code
 set(p,"ProfileReady",e.Ready==true);set(p,"ProfileSaveState",state)
 set(p,"ProfileStorageMode",self.Mode);set(p,"ProfileErrorCode",code)
 local notice=TEXT[state] or TEXT.Error
 if self.Mode=="LocalFile" then
  local messages={Loading="Đang tải dữ liệu trên máy…",Loaded="Đã tải tiến trình trên máy.",
   Dirty="Có thay đổi, đang chờ lưu trên máy…",Saving="Đang ghi tiến trình vào máy…",Saved="Đã lưu tiến trình trên máy.",
   Unavailable="Chưa kết nối bộ lưu trên máy. Mở CHOI_VA_LUU.cmd rồi bấm THỬ TẢI LẠI.",
   Error="Chưa ghi được dữ liệu trên máy. Kiểm tra bộ lưu rồi thử lại.",Closing="Đang lưu trên máy trước khi rời…"}
  messages.Conflict="Đang chờ phiên Studio trước đóng; hệ thống sẽ tự tải lại trong ít giây."
  notice=messages[state] or notice
 end
 set(p,"ProfileStatusText",notice)
end
function Service:Data(p) local e=self.Entries[p];return if e and e.Ready then e.Data else nil end
function Service:Ready(p) return self:Data(p)~=nil end
function Service:CanPlay(p)
 local e=self.Entries[p]
 return e~=nil and e.Ready==true and not e.Closing and e.State~="Conflict"
end
function Service:CanMutate(p)
 local e=self.Entries[p]
 return e~=nil and e.Ready==true and not e.Saving and not e.Closing and not e.Pending
  and e.State~="Error" and e.State~="Conflict"
end
function Service:_apply(p,data)
 set(p,"WeaponId",data.Loadout.WeaponId);set(p,"PetWeaponId",data.Loadout.PetWeaponId)
 for _,target in {"Player","Pet"} do for _,slot in SLOTS do
  set(p,target.."Armor_"..slot,data.Loadout[target.."Armor"][slot])
 end end
 for key,value in data.Preferences do set(p,key,value) end
 set(p,"PetHealReadyAt",data.Pet.HealReadyAt)
end
function Service:_capture(p,e)
 for _,key in {"WeaponId","PetWeaponId"} do
  local value=p:GetAttribute(key);if value~=nil then e.Data.Loadout[key]=value end
 end
 for _,target in {"Player","Pet"} do for _,slot in SLOTS do
  local value=p:GetAttribute(target.."Armor_"..slot)
  if value~=nil then e.Data.Loadout[target.."Armor"][slot]=value end
 end end
 for key in PREFS do
  local value=p:GetAttribute(key);if value~=nil then e.Data.Preferences[key]=value end
 end
 local ready=p:GetAttribute("PetHealReadyAt")
 if type(ready)=="number" then
  e.Data.Pet.HealReadyAt=if ready>self.ServerNow() then math.ceil(self.Now()+ready-self.ServerNow()) else 0
 end
 e.Data.UpdatedAt=self.Now()
end
function Service:Touch(p)
 local e=self.Entries[p];if not e or not e.Ready or e.Closing then return end
 e.Generation+=1;e.DirtyAt=os.clock()
 if not e.Saving and not e.Pending then self:_state(p,e,"Dirty") end
end
function Service:_watch(p,e)
 e.Connections={}
 local keys={"WeaponId","PetWeaponId","PetHealReadyAt"}
 for key in PREFS do table.insert(keys,key) end
 for _,target in {"Player","Pet"} do for _,slot in SLOTS do table.insert(keys,target.."Armor_"..slot) end end
 for _,key in keys do table.insert(e.Connections,p:GetAttributeChangedSignal(key):Connect(function() self:Touch(p) end)) end
end
function Service:Load(p)
 local old=self.Entries[p]
 if old and (old.Ready or old.Loading) then return old.Ready==true end
 local e=old or {Generation=0,Key="player_"..tostring(p.UserId)}
 self.Entries[p]=e;e.Loading=true;self:_state(p,e,"Loading")
 local repository,code=self:_repository()
 if not repository then e.Loading=false;self:_state(p,e,code);return false end
 local ok,status,data
 if e.RecoveryData then
  data=e.RecoveryData;ok,status=repository:Save(e.Key,data)
 else
  ok,status,data=repository:Load(e.Key,self.Schema.Default(self.Now()))
 end
 if ok and not e.RecoveryData then
  local recovered,receipt=self.Schema.Recover(data)
  if not recovered then ok=false;status=receipt or "InvalidData"
  else
   data=recovered
   -- Recovery (return carried items, close old run) must itself be durable.
   if receipt then e.RecoveryData=data;e.NextRecoveryAt=os.clock()+Config.RetrySeconds;ok,status=repository:Save(e.Key,data) end
  end
 end
 e.Loading=false
 if not ok then
  if status=="Locked" or status=="SessionLost" or status=="RevisionConflict" then
   e.Pending=nil;e.RecoveryData=nil;self:_state(p,e,"Conflict",status)
   if self.Mode=="LocalFile" and status=="Locked" then
    task.delay(2,function()
     if not self.Stopped and p.Parent and self.Entries[p]==e and not e.Ready and not e.Loading then self:Load(p) end
    end)
   end
  else self:_state(p,e,"Error",status) end
  return false
 end
 for _,connection in e.Connections or {} do connection:Disconnect() end
 e.Pending=nil;e.RecoveryData=nil;e.Closing=nil
 e.Data=data;e.Ready=true;e.NextSave=os.clock()+(self.AutoSaveSeconds or Config.AutoSaveSeconds);e.Generation=0;e.SavedGeneration=0
 self:_apply(p,data);self:_watch(p,e)
 set(p,"ProfileSavedAt",self.Now());self:_state(p,e,"Loaded")
 if not p.Parent then self:Release(p);return false end
 if self.OnLoaded then local called,err=pcall(self.OnLoaded,p,data);if not called then warn(err) end end
 return true
end
function Service:_failure(p,e,status)
 e.NextSave=os.clock()+Config.RetrySeconds
 if status=="SessionLost" or status=="RevisionConflict" or status=="Locked" then
  e.Quarantined=e.Pending;e.Pending=nil;e.RecoveryData=nil
  e.Ready=false;self:_state(p,e,"Conflict",status)
 else self:_state(p,e,"Error",status) end
 warn("[HunDino Save]",e.Key,status)
end
function Service:_installPending(p,e)
 local pending=e.Pending
 if not pending then return true end
 local ok,status=self.Repository:Save(e.Key,pending.Data)
 if not ok then self:_failure(p,e,status);return false end
 -- Canonical economy identity survives: runtime adapters retain this table.
 replace(e.Data.Economy,pending.Data.Economy)
 e.Data.Statistics=pending.Data.Statistics
 e.Pending=nil;e.Generation+=1;e.SavedGeneration=pending.Generation+1
 if self.OnEconomyCommitted then local called,err=pcall(self.OnEconomyCommitted,p);if not called then warn(err) end end
 return true
end
function Service:CommitEconomy(p,mutate)
 local e=self.Entries[p]
 if not self:CanMutate(p) then return {Ok=false,Code="SavePending",Replay=false} end
 self:_capture(p,e)
 local candidate=assert(self.Schema.Validate(e.Data))
 local receipt=mutate(candidate.Economy,candidate.Statistics)
 if not receipt or not receipt.Ok or receipt.Replay or receipt.Unchanged then return receipt end
 e.Pending={Data=candidate,Receipt=receipt,Generation=e.Generation}
 e.Saving=true;self:_state(p,e,"Saving")
 local ok=self:_installPending(p,e)
 e.Saving=false
 if not ok then return {Ok=false,Code="SavePending",Replay=false} end
 set(p,"ProfileSavedAt",self.Now())
 self:_state(p,e,if e.Generation>e.SavedGeneration then "Dirty" else "Saved")
 if e.Generation==e.SavedGeneration then e.DirtyAt=nil end
 e.NextSave=os.clock()+(self.AutoSaveSeconds or Config.AutoSaveSeconds)
 return receipt
end
function Service:Save(p,release)
 local e=self.Entries[p]
 if not e or not e.Ready or e.Saving then return false,"NotReady" end
 e.Saving=true;self:_state(p,e,if release then "Closing" else "Saving")
 if not self:_installPending(p,e) then e.Saving=false;return false,e.ErrorCode end
 self:_capture(p,e)
 local data,invalid=self.Schema.Validate(e.Data)
 if not data then e.Saving=false;self:_failure(p,e,invalid or "InvalidData");return false,invalid end
 local generation=e.Generation
 local ok,status=self.Repository:Save(e.Key,data,release)
 e.Saving=false
 if not ok then self:_failure(p,e,status);return false,status end
 e.SavedGeneration=generation;e.NextSave=os.clock()+(self.AutoSaveSeconds or Config.AutoSaveSeconds)
 if e.Generation==generation then e.DirtyAt=nil end
 set(p,"ProfileSavedAt",self.Now())
 self:_state(p,e,if e.Generation==generation then "Saved" else "Dirty")
 return true,status
end
function Service:Release(p)
 local e=self.Entries[p];if not e or e.Releasing then return end
 e.Releasing=true
 e.Closing=true
 local deadline=os.clock()+22
 while e.Saving and os.clock()<deadline do task.wait(.05) end
 local ok=false
 if not e.Saving then
  if e.RecoveryData then
   ok=self.Repository:Save(e.Key,e.RecoveryData,true)
  elseif e.Ready then ok=self:Save(p,true)
  else ok=true end -- No profile was acquired; nothing can be written.
 end
 if ok then
  for _,connection in e.Connections or {} do connection:Disconnect() end
  self.Entries[p]=nil
 elseif e.State~="Conflict" then
  warn("[HunDino Save] Final save pending; retained for retry",e.Key)
  task.delay(Config.RetrySeconds,function() if self.Entries[p]==e then self:Release(p) end end)
 end
 e.Releasing=false
end
function Service:Request(p,action,key,value)
 local e=self.Entries[p]
 if type(action)~="string" then return end
 if action=="RetryLoad" then
  if e and os.clock()-(e.LastLoadRequest or -math.huge)<5 then return end
  if e then e.LastLoadRequest=os.clock() end
  if self:Ready(p) then self:Save(p) else self:Load(p) end
 elseif action=="Save" then
  if not e or os.clock()-(e.LastManual or -math.huge)<5 then return end
  e.LastManual=os.clock();self:Save(p)
 elseif action=="Preference" then
  if not self:CanMutate(p) or not PREFS[key] then return end
  if key=="AimSensitivity" then
   if value~=1 and value~=.75 and value~=.5 then return end
  elseif key=="KatanaCarry" then
   if type(value)~="number" or value%1~=0 or value<1 or value>2 or p:GetAttribute("Drawn")==true or p:GetAttribute("WeaponHandling")==true then return end
  elseif key=="MeleeStance" or key=="RangedStance" then
   local limit=if key=="MeleeStance" then 6 else 3
   if type(value)~="number" or value%1~=0 or value<1 or value>limit then return end
  elseif type(value)~="boolean" then return end
  if os.clock()-(e.LastPreference or -math.huge)<.12 then return end
  e.LastPreference=os.clock();set(p,key,value)
 end
end
function Service:Shutdown(beforeRelease)
 self.Stopped=true
 local pending=0
 for p,e in self.Entries do
  if e.Ready or e.RecoveryData then
   pending+=1
   task.spawn(function()
    if beforeRelease then local ok,err=pcall(beforeRelease,p);if not ok then warn(err) end end
    self:Release(p);pending-=1
   end)
  end
 end
 local deadline=os.clock()+25
 while pending>0 and os.clock()<deadline do task.wait(.1) end
end
return Service
