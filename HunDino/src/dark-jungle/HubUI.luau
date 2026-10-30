-- Quick-access UI. Account preferences are validated and acknowledged by the server.
local Hub={}
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Theme=require(script.Parent:WaitForChild("UITheme"))
local C=Theme.Colors
local icons={Shop="rbxassetid://101717469378295",Settings="rbxassetid://119955450343925",Play="rbxassetid://115198627543926",Inventory="rbxassetid://82181506096525"}
function Hub.create(player,gui,callbacks)
 local root=Instance.new("Frame"); root.Name="QuickAccess"; root.BackgroundTransparency=1
 root.Size=UDim2.fromOffset(144,148); root.Position=UDim2.new(1,-164,0,14); root.Parent=gui
 local rootScale=Instance.new("UIScale"); rootScale.Parent=root
 local shield=Instance.new("TextButton"); shield.Name="HubShield"; shield.Size=UDim2.fromScale(1,1); shield.BackgroundColor3=Color3.fromRGB(5,8,13); shield.BackgroundTransparency=.38; shield.Text=""; shield.AutoButtonColor=false; shield.Visible=false; shield.ZIndex=29; shield.Parent=gui
 local overlay=Instance.new("Frame"); overlay.Name="HubPanel"; overlay.AnchorPoint=Vector2.new(.5,.5)
 overlay.Position=UDim2.fromScale(.5,.5); overlay.Size=UDim2.fromOffset(620,480); overlay.BackgroundColor3=Color3.fromRGB(18,34,31)
 overlay.Visible=false; overlay.Active=true; overlay.ZIndex=30; overlay.Parent=gui
 Theme.panel(overlay)
 local scale=Instance.new("UIScale"); scale.Parent=overlay
 local oldOrder
 local function resize()
  local camera=workspace.CurrentCamera; if not camera then return end
  local size=camera.ViewportSize
  scale.Scale=math.min(1,(size.X-32)/620,(size.Y-70)/480)
  rootScale.Scale=if size.X<760 or size.Y<650 then .78 else 1
  root.Position=UDim2.new(1,-20-144*rootScale.Scale,0,14)
 end
 local resizeConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize); resize()
 local function label(parent,name,value,x,y,w,h,size)
  local t=Instance.new("TextLabel"); t.Name=name; t.Text=value; t.Font=Enum.Font.GothamMedium; t.TextSize=size or 16
  t.TextWrapped=true; t.TextColor3=C.Text; t.BackgroundTransparency=1; t.ZIndex=parent.ZIndex+1
  t.Position=UDim2.fromOffset(x,y); t.Size=UDim2.fromOffset(w,h); t.Parent=parent; return t
 end
 local heading=label(overlay,"Heading","",24,20,530,40,24)
 heading.TextXAlignment=Enum.TextXAlignment.Left; heading.TextColor3=C.Gold; heading.Font=Enum.Font.GothamBold
 local body=Instance.new("Frame"); body.Name="Body"; body.Position=UDim2.fromOffset(24,76); body.Size=UDim2.fromOffset(572,380); body.BackgroundTransparency=1; body.ZIndex=overlay.ZIndex+1; body.Parent=overlay
 local function button(parent,name,value,x,y,w,h,onClick)
  local b=Instance.new("TextButton"); b.Name=name; b.Text=value; b.TextWrapped=true; b.Font=Enum.Font.GothamMedium; b.TextSize=16
  b.TextColor3=C.Text; b.BackgroundColor3=C.Card; b.ZIndex=parent.ZIndex+1
  b.Size=UDim2.fromOffset(w,h); b.Position=UDim2.fromOffset(x,y); b.Parent=parent
  Theme.button(b); b.Activated:Connect(onClick); return b
 end
 local api={}
 local bodyConnections={}
 local alive=true
 local refreshRedeem
 local redeem={Pending=false,Serial=0,Text="",Result=nil}
 local manualSave={Pending=false,NextAt=0,StartedAt=0,SavedAt=0,SawSaving=false,Notice=nil}
 local economyRemote,codeConnection
 local lifetimeConnections={resizeConnection}
 local function clearBodyConnections()
  refreshRedeem=nil
  for _,connection in bodyConnections do connection:Disconnect() end;table.clear(bodyConnections)
 end
 local function connectEconomy(remote)
  if codeConnection then codeConnection:Disconnect();codeConnection=nil end
  economyRemote=if remote and remote:IsA("RemoteEvent") then remote else nil
  if economyRemote then
   codeConnection=economyRemote.OnClientEvent:Connect(function(event,result)
    if not alive or event~="CodeResult" or type(result)~="table" or type(result.Ok)~="boolean" then return end
    redeem.Pending=false
    redeem.Result={Ok=result.Ok,Code=result.Code,Message=if type(result.Message)=="string" then result.Message else (if result.Ok then "Đã nhận phần thưởng và lưu tài khoản." else "Chưa đổi được mã. Hãy thử lại.")}
    if result.Ok then redeem.Text="" end
    if refreshRedeem then refreshRedeem() end
   end)
  end
  if refreshRedeem then refreshRedeem() end
 end
 connectEconomy(ReplicatedStorage:FindFirstChild("HunDinoEconomyAction"))
 table.insert(lifetimeConnections,ReplicatedStorage.ChildAdded:Connect(function(child)
  if child.Name=="HunDinoEconomyAction" then connectEconomy(child) end
 end))
 table.insert(lifetimeConnections,ReplicatedStorage.ChildRemoved:Connect(function(child)
  if child==economyRemote then connectEconomy(nil) end
 end))
 local function watchAttribute(name,callback)
  table.insert(bodyConnections,player:GetAttributeChangedSignal(name):Connect(callback))
 end
 local function accountStatus()
  if player:GetAttribute("ProfileStorageMode")=="TestMemory" then return "CHẾ ĐỘ THỬ: dữ liệu chỉ trong phiên, chưa lưu tài khoản." end
  if player:GetAttribute("ProfileReady")~=true then return player:GetAttribute("ProfileStatusText") or "Đang tải hồ sơ tài khoản…" end
  local state=player:GetAttribute("ProfileSaveState")
  if state=="Dirty" then return "Hồ sơ đã thay đổi; đang chờ tự động lưu." end
  if state=="Saving" or state=="Closing" then return "Đang lưu hồ sơ tài khoản…" end
  if state=="Error" or state=="Unavailable" or state=="Conflict" then return player:GetAttribute("ProfileStatusText") or "Chưa lưu được hồ sơ; máy chủ sẽ thử lại." end
  local saved=player:GetAttribute("ProfileSavedAt")
   if type(saved)=="number" and saved>0 then
    local prefix=if player:GetAttribute("ProfileStorageMode")=="LocalFile" then "Đã lưu trên máy lúc " else "Đã lưu tài khoản lúc "
    return prefix..os.date("!%H:%M:%S",saved+7*3600).." (UTC+7)."
   end
  return player:GetAttribute("ProfileStatusText") or "Đã tải hồ sơ tài khoản; thay đổi được tự động lưu."
 end
 local function watchAccount(callback)
  for _,name in {"ProfileReady","ProfileSaveState","ProfileStatusText","ProfileSavedAt","ProfileStorageMode"} do watchAttribute(name,callback) end
  callback()
 end
 local function preference(key,value)
  if player:GetAttribute("ProfileReady")~=true then return end
  local remote=ReplicatedStorage:FindFirstChild("HunDinoProfileAction")
  if remote and remote:IsA("RemoteEvent") then remote:FireServer("Preference",key,value) end
 end
 function api:IsOpen() return overlay.Visible end
 function api:Close()
  clearBodyConnections()
  overlay.Visible=false; shield.Visible=false
  if oldOrder~=nil then gui.DisplayOrder=oldOrder;oldOrder=nil end
  callbacks.Preferences()
 end
 shield.Activated:Connect(function(input)
  -- A TextBox can also activate the backdrop; only clicks outside the panel dismiss it.
  local inset=if gui.IgnoreGuiInset then Vector2.zero else game:GetService("GuiService"):GetGuiInset()
  local point=Vector2.new(input.Position.X,input.Position.Y)-inset
  local pos,size=overlay.AbsolutePosition,overlay.AbsoluteSize
  if point.X>=pos.X and point.X<=pos.X+size.X and point.Y>=pos.Y and point.Y<=pos.Y+size.Y then return end
  api:Close()
 end)
 button(overlay,"Close","×",566,18,34,34,function() api:Close() end)
 local show
 show=function(id)
  if id=="Shop" then
   api:Close();callbacks.BeforeOpen()
   if economyRemote then economyRemote:FireServer("OpenShop") end
   return
  end
  clearBodyConnections()
  callbacks.BeforeOpen(); body:ClearAllChildren(); overlay.Visible=true; shield.Visible=true
  if oldOrder==nil then oldOrder=gui.DisplayOrder end; gui.DisplayOrder=math.max(gui.DisplayOrder,60); callbacks.Preferences()
  heading.Text=({Shop="THƯƠNG NHÂN",Settings="CÀI ĐẶT",Redeem="NHẬP CODE",Play="BẮT ĐẦU HÀNH TRÌNH"})[id]
  if id=="Play" then
   label(body,"Intro","Trại thợ săn • 12 base\nNhận nhiệm vụ T-REX hoặc khám phá thung lũng tự do.",0,0,572,64)
   local hunting=player:GetAttribute("InHunting")==true
   button(body,"Quest","NHIỆM VỤ · HẠ HOẶC BẮT T-REX",36,66,500,48,function()
    api:Close(); game.ReplicatedStorage.HunDinoTrainingAction:FireServer("QuestBoard")
   end)
   button(body,"Hunting",if hunting then "ĐANG Ở THUNG LŨNG SƯƠNG XÁM" else "THÁM HIỂM · THUNG LŨNG SƯƠNG XÁM",36,124,500,48,function()
    api:Close(); if not player:GetAttribute("InHunting") then callbacks.Travel("Hunting") end
   end)
   button(body,"Training","VÀO BÃI LUYỆN TẬP",36,182,500,48,function() api:Close(); callbacks.Travel("Training") end)
   button(body,"Lobby","VỀ SẢNH TRUNG TÂM",36,240,500,48,function() api:Close(); callbacks.Travel("Lobby") end)
   label(body,"Hunts","Săn solo 40 phút, 3 lần hồi sinh. Hạ hoặc bắt nhận thưởng; vật tư và tiến trình xem trong Túi đồ.",20,301,532,64)
  elseif id=="Redeem" then
   button(body,"BackToSettings","‹  CÀI ĐẶT",0,0,170,36,function() show("Settings") end)
   local intro=label(body,"CodeIntro","Nhập mã thưởng của bạn. Mỗi mã chỉ nhận theo điều kiện do máy chủ xác nhận.",0,48,572,48,16)
   intro.TextColor3=C.Muted
   local input=Instance.new("TextBox");input.Name="CodeInput";input.Position=UDim2.fromOffset(12,108);input.Size=UDim2.fromOffset(548,52)
   input.BackgroundColor3=C.Card;input.BorderSizePixel=0;input.ClearTextOnFocus=false;input.MultiLine=false
   input.Text=redeem.Text;input.PlaceholderText="Nhập mã tại đây…";input.PlaceholderColor3=C.Muted
   input.TextColor3=C.Text;input.Font=Enum.Font.GothamMedium;input.TextSize=18;input.TextXAlignment=Enum.TextXAlignment.Left
   input.ZIndex=body.ZIndex+1;input.Parent=body;Theme.round(input,8)
   local padding=Instance.new("UIPadding");padding.PaddingLeft=UDim.new(0,16);padding.PaddingRight=UDim.new(0,16);padding.Parent=input
   local border=Instance.new("UIStroke");border.Color=C.Border;border.Transparency=.3;border.Thickness=1;border.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;border.Parent=input
   local resultLabel=label(body,"CodeResult","",12,232,548,86,16)
   local profileLabel=label(body,"CodeAccountStatus","",12,326,548,46,13);profileLabel.TextColor3=C.Muted
   local submit
   local function blockedReason()
    if player:GetAttribute("ProfileReady")~=true then return player:GetAttribute("ProfileStatusText") or "Đang tải hồ sơ tài khoản…" end
    local state=player:GetAttribute("ProfileSaveState")
    if state=="Loading" or state=="Saving" or state=="Closing" or state=="Error" or state=="Unavailable" or state=="Conflict" then
     return player:GetAttribute("ProfileStatusText") or "Hồ sơ chưa sẵn sàng. Hãy xem trạng thái lưu tài khoản."
    end
    if player:GetAttribute("EconomyReady")~=true or not economyRemote then return "Đang kết nối kho vật phẩm…" end
    return nil
   end
   local function refresh()
    local reason=blockedReason()
    input.TextEditable=not redeem.Pending
    if input.Text~=redeem.Text then input.Text=redeem.Text end
    local trimmed=redeem.Text:match("^%s*(.-)%s*$") or ""
    submit.Active=not redeem.Pending and not reason and trimmed~=""
    submit.Text=if redeem.Pending then "ĐANG KIỂM TRA VÀ LƯU…" else "ĐỔI MÃ"
    submit.TextTransparency=if submit.Active then 0 else .45
    profileLabel.Text=accountStatus()
    if redeem.Pending then resultLabel.Text="Đang chờ máy chủ xác nhận phần thưởng…";resultLabel.TextColor3=C.Gold
    elseif redeem.Result then resultLabel.Text=redeem.Result.Message;resultLabel.TextColor3=if redeem.Result.Ok then C.Health else C.Warning
    elseif reason then resultLabel.Text=reason;resultLabel.TextColor3=C.Warning
    else resultLabel.Text="Phần thưởng chỉ được xác nhận sau khi đổi mã thành công.";resultLabel.TextColor3=C.Muted end
   end
   local function requestCode()
    if redeem.Pending then return end
    local reason=blockedReason()
    if reason then redeem.Result={Ok=false,Message=reason};refresh();return end
    local text=redeem.Text:match("^%s*(.-)%s*$") or ""
    if text=="" then redeem.Result={Ok=false,Message="Hãy nhập mã trước khi đổi."};refresh();return end
    redeem.Text=text;redeem.Pending=true;redeem.Result=nil;redeem.Serial+=1
    local serial=redeem.Serial
    refresh()
    local sent=pcall(function() economyRemote:FireServer("RedeemCode",text) end)
    if not sent then redeem.Pending=false;redeem.Result={Ok=false,Message="Chưa gửi được mã. Hãy thử lại."};refresh();return end
    task.delay(12,function()
     if not alive or redeem.Serial~=serial or not redeem.Pending then return end
     redeem.Pending=false;redeem.Result={Ok=false,Message="Chưa nhận được phản hồi. Kiểm tra trạng thái lưu hoặc thử lại; mã đã nhận sẽ không được cộng lần nữa."}
     if refreshRedeem then refreshRedeem() end
    end)
   end
   submit=button(body,"RedeemCode","ĐỔI MÃ",12,176,548,46,requestCode)
   table.insert(bodyConnections,input:GetPropertyChangedSignal("Text"):Connect(function()
    if input.Text==redeem.Text then return end
    local text=input.Text
    local endAt=utf8.offset(text,65)
    if endAt then text=text:sub(1,endAt-1) end
    redeem.Text=text
    if not redeem.Pending then redeem.Result=nil end
    if input.Text~=text then input.Text=text end
    refresh()
   end))
   table.insert(bodyConnections,input.FocusLost:Connect(function(enterPressed)
    redeem.Text=redeem.Text:match("^%s*(.-)%s*$") or "";refresh()
    if enterPressed then requestCode() end
   end))
   refreshRedeem=refresh
   watchAccount(refresh);watchAttribute("EconomyReady",refresh)
  else
   local parentBody=body
   local body=Instance.new("ScrollingFrame");body.Name="ControlSettings";body.BackgroundTransparency=1;body.BorderSizePixel=0
   body.Size=UDim2.fromScale(1,1);body.CanvasSize=UDim2.fromOffset(0,680);body.ScrollBarThickness=4;body.ScrollBarImageColor3=C.Gold
   body.ScrollingDirection=Enum.ScrollingDirection.Y;body.Parent=parentBody
   local controls=require(ReplicatedStorage.Shared.TrainingConfig).Controls
   local intro=label(body,"Intro","",0,0,572,48,14)
   local options={{"ShowComboGuide","Hướng dẫn combo"},{"ShowDamage","Số sát thương"},{"ShowComboFX","Hiệu ứng đòn kết thúc"}}
   for i,option in options do
    local key,title=option[1],option[2]
    local b
    local function update()
     b.Text=title.."  •  "..(if player:GetAttribute(key)~=false then "BẬT" else "TẮT")
     b.Active=player:GetAttribute("ProfileReady")==true;b.TextTransparency=if b.Active then 0 else .45
     callbacks.Preferences()
    end
    b=button(body,key,"",12,54+(i-1)*44,548,38,function() preference(key,player:GetAttribute(key)==false) end)
    watchAttribute(key,update);watchAttribute("ProfileReady",update);update()
   end
   local b
   local function update()
    local sensitivity=player:GetAttribute("AimSensitivity") or 1
    b.Text="Độ nhạy khi ngắm cung  •  "..math.floor(sensitivity*100).."%"
    b.Active=player:GetAttribute("ProfileReady")==true;b.TextTransparency=if b.Active then 0 else .45
   end
   b=button(body,"Sensitivity","",12,186,548,38,function()
    local current=player:GetAttribute("AimSensitivity") or 1
    preference("AimSensitivity",if current==1 then .75 elseif current==.75 then .5 else 1)
   end)
   watchAttribute("AimSensitivity",update);watchAttribute("ProfileReady",update);update()
   local autoAim
   local function updateAutoAim()
    local enabled=player:GetAttribute("AutoBowAim")==true
    autoAim.Text="Tự ngắm cung  •  "..(if enabled then "BẬT" else "TẮT")
    autoAim.Active=player:GetAttribute("ProfileReady")==true
    autoAim.TextTransparency=0
   end
   autoAim=button(body,"AutoBowAim","",12,230,548,38,function()
    preference("AutoBowAim",player:GetAttribute("AutoBowAim")~=true)
    updateAutoAim()
   end)
   watchAttribute("AutoBowAim",updateAutoAim);watchAttribute("ProfileReady",updateAutoAim);updateAutoAim()
   local function controlToggle(key,y,title,onText,offText)
    local b
    local function update()
     b.Text=title.."  •  "..(if player:GetAttribute(key)==true then onText else offText)
     b.Active=player:GetAttribute("ProfileReady")==true;b.TextTransparency=if b.Active then 0 else .45
     callbacks.Preferences()
    end
    b=button(body,key,"",12,y,548,38,function() preference(key,player:GetAttribute(key)~=true) end)
    watchAttribute(key,update);watchAttribute("ProfileReady",update);update()
   end
   controlToggle("AutoBowFire",274,"Tự bắn khi giữ nút ngắm","BẬT","TẮT")
   controlToggle("SwapBowButtons",318,"Chuột cung","Trái ngắm / Phải bắn","Trái bắn / Phải ngắm")
   for _,row in {{"MeleeStance",362,"Tư thế cận chiến",controls.MeleeStances},{"RangedStance",406,"Tư thế tầm xa",controls.RangedStances}} do
    local key,y,title,names=row[1],row[2],row[3],row[4]
    local b
    local function update()
     b.Text=title.."  •  "..names[player:GetAttribute(key) or 1]
     b.Active=player:GetAttribute("ProfileReady")==true;b.TextTransparency=if b.Active then 0 else .45
     callbacks.Preferences()
    end
    b=button(body,key,"",12,y,548,38,function() preference(key,(player:GetAttribute(key) or 1)%#names+1) end)
    watchAttribute(key,update);watchAttribute("ProfileReady",update);update()
   end
   local katanaCarry
   local function updateKatanaCarry()
    katanaCarry.Text="Chỗ đeo katana  •  "..controls.KatanaCarryNames[player:GetAttribute("KatanaCarry") or 1].."  (K)"
    katanaCarry.Active=player:GetAttribute("ProfileReady")==true and player:GetAttribute("Drawn")~=true and player:GetAttribute("WeaponHandling")~=true
    katanaCarry.TextTransparency=if katanaCarry.Active then 0 else .45
   end
   katanaCarry=button(body,"KatanaCarry","",12,450,548,38,function() preference("KatanaCarry",(player:GetAttribute("KatanaCarry") or 1)%2+1) end)
   for _,key in {"KatanaCarry","ProfileReady","Drawn","WeaponHandling"} do watchAttribute(key,updateKatanaCarry) end
   updateKatanaCarry()
   label(body,"ControlHelp","1–7: chọn đồ · R: tự rút/cất · B: đổi tư thế\nK: đổi chỗ katana khi đã cất · T: ngắm · Y: tự bắn",12,494,548,48,12)

   local saveButton
   local function refreshSave()
    local state=player:GetAttribute("ProfileSaveState") or "Loading"
    local ready=player:GetAttribute("ProfileReady")==true
    local memory=player:GetAttribute("ProfileStorageMode")=="TestMemory"
    local saving=state=="Saving" or state=="Closing"
    local failed=state=="Error" or state=="Unavailable" or state=="Conflict"
    local savedAt=player:GetAttribute("ProfileSavedAt")
    savedAt=if type(savedAt)=="number" then savedAt else 0
    if manualSave.Pending then
     if saving then manualSave.SawSaving=true end
     if failed or not ready or memory then
      manualSave.Pending=false;manualSave.Notice=nil
     elseif not saving and (savedAt>manualSave.SavedAt or (manualSave.SawSaving and (state=="Saved" or state=="Dirty"))) then
      -- Only a replicated server save result confirms completion.
      manualSave.Pending=false;manualSave.Notice=nil
     elseif os.clock()-manualSave.StartedAt>=12 then
      manualSave.Pending=false;manualSave.Notice="Chưa nhận được xác nhận lưu. Máy chủ vẫn tự động lưu; bạn có thể thử lại."
     end
    elseif manualSave.Notice and savedAt>manualSave.SavedAt then
     manualSave.Notice=nil
    end
    local remote=ReplicatedStorage:FindFirstChild("HunDinoProfileAction")
    local available=remote and remote:IsA("RemoteEvent")
    saveButton.Active=ready and not memory and state~="Loading" and state~="Unavailable" and state~="Conflict" and not saving and not manualSave.Pending and os.clock()>=manualSave.NextAt and available==true
    saveButton.Text=if saving then "ĐANG LƯU…" elseif manualSave.Pending then "ĐANG CHỜ XÁC NHẬN…" elseif os.clock()<manualSave.NextAt then "SAVE GAME · "..math.ceil(manualSave.NextAt-os.clock()).."s" else "SAVE GAME"
    saveButton.TextTransparency=if saveButton.Active then 0 else .45
    intro.Text=if manualSave.Pending and not saving then "Đã gửi yêu cầu; đang chờ máy chủ xác nhận lưu…" else (manualSave.Notice or accountStatus())
    intro.TextColor3=if failed or memory or manualSave.Notice then C.Warning elseif manualSave.Pending or saving then C.Gold elseif state=="Saved" then C.Health else C.Muted
   end
   saveButton=button(body,"SaveGame","SAVE GAME",12,550,266,44,function()
    refreshSave();if not saveButton.Active then return end
    local remote=ReplicatedStorage:FindFirstChild("HunDinoProfileAction")
    if not remote or not remote:IsA("RemoteEvent") then return end
    manualSave.Pending=true;manualSave.NextAt=os.clock()+5;manualSave.StartedAt=os.clock()
    local savedAt=player:GetAttribute("ProfileSavedAt")
    manualSave.SavedAt=if type(savedAt)=="number" then savedAt else 0;manualSave.SawSaving=false;manualSave.Notice=nil
    local sent=pcall(function() remote:FireServer("Save") end)
    if not sent then manualSave.Pending=false;manualSave.Notice="Chưa gửi được yêu cầu lưu. Hãy thử lại." end
    refreshSave()
   end)
   button(body,"OpenRedeemCode","NHẬP CODE  ›",294,550,266,44,function() show("Redeem") end)
   local hint=label(body,"AutoSaveHint","Các lựa chọn điều khiển được lưu cùng hồ sơ. Tự bắn chỉ hoạt động khi giữ nút ngắm; tay trái giữ cung, tay phải kéo và nhả dây.",12,600,548,64,12);hint.TextColor3=C.Muted
   watchAccount(refreshSave)
   local elapsed=0
   table.insert(bodyConnections,RunService.Heartbeat:Connect(function(dt)
    elapsed+=dt;if elapsed>=.25 then elapsed=0;refreshSave() end
   end))
  end
 end
 root.Destroying:Connect(function()
  alive=false;clearBodyConnections()
  if codeConnection then codeConnection:Disconnect();codeConnection=nil end
  for _,connection in lifetimeConnections do connection:Disconnect() end;table.clear(lifetimeConnections)
 end)
 for i,id in {"Shop","Settings","Play","Inventory"} do
  local b=Instance.new("ImageButton"); b.Name=id; b.Image=icons[id]; b.ScaleType=Enum.ScaleType.Fit
  b.Size=UDim2.fromOffset(58,52); b.Position=UDim2.fromOffset(((i-1)%2)*78,math.floor((i-1)/2)*78)
  b.BackgroundColor3=C.Card; b.BackgroundTransparency=.12; b.Parent=root; Theme.button(b)
  local padding=Instance.new("UIPadding"); padding.PaddingTop=UDim.new(0,5);padding.PaddingBottom=UDim.new(0,5);padding.PaddingLeft=UDim.new(0,5);padding.PaddingRight=UDim.new(0,5);padding.Parent=b
  local caption=label(b,"Caption",({Shop="Cửa hàng",Settings="Cài đặt",Play="Chơi",Inventory="Túi đồ"})[id],-8,50,74,20,11)
  caption.TextColor3=C.Muted
  b.Activated:Connect(function()
   if id=="Inventory" then api:Close(); callbacks.Inventory() else show(id) end
  end)
 end
 return api
end
return Hub
