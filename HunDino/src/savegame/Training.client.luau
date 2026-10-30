local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("HunDinoTrainingAction")
local Config = require(ReplicatedStorage.Shared.TrainingConfig)
local Handling=Config.Controls.Handling(CFrame,Vector3)
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Bow = require(ReplicatedStorage.Shared:WaitForChild("BowBallistics"))
local Theme = require(ReplicatedStorage.Shared:WaitForChild("UITheme"))
local C = Theme.Colors
local gui = Instance.new("ScreenGui"); gui.Name = "HunDinoTrainingHUD"; gui.ResetOnSpawn = false; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent = player:WaitForChild("PlayerGui")
local function text(name, pos, size, value, textSize)
	local t = Instance.new("TextLabel"); t.Name = name; t.Position = pos; t.Size = size
	t.BackgroundColor3 = C.Panel; t.BackgroundTransparency = 0.12
	t.TextColor3 = C.Text; t.Font = Enum.Font.GothamMedium
	t.TextSize = textSize or 16; t.TextWrapped = true; t.Text = value; t.Parent = gui
	Theme.panel(t)
	return t
end
local title = text("Title", UDim2.fromOffset(20, 14), UDim2.fromOffset(330, 55), "HUNDINO • TRẠI THỢ SĂN", 19)
title.TextColor3=C.Gold; title.Font=Enum.Font.GothamBold
local stats = text("Stats", UDim2.new(0, 20, 1, -136), UDim2.fromOffset(330, 64), "", 16)
local staminaBG = text("Stamina", UDim2.new(0, 20, 1, -60), UDim2.fromOffset(330, 26), "", 14)
local bar = Instance.new("Frame"); bar.BorderSizePixel = 0; bar.BackgroundColor3 = C.Stamina
bar.Size = UDim2.fromScale(1, 1); bar.Parent = staminaBG
Theme.round(bar,8);staminaBG.ClipsDescendants=true
local staminaText = Instance.new("TextLabel"); staminaText.Size = UDim2.fromScale(1, 1); staminaText.BackgroundTransparency = 1
staminaText.TextColor3 = C.Text; staminaText.TextStrokeTransparency=.45; staminaText.Font = Enum.Font.GothamBold; staminaText.TextSize = 14; staminaText.Parent = staminaBG
local help = text("Help", UDim2.new(1, -375, 1, -209), UDim2.fromOffset(355, 190), "", 15)
local notice = text("Notice", UDim2.new(0.5, -245, 0, 18), UDim2.fromOffset(490, 48), "Đến cổng tại sân đón, giữ G để vào bãi tập.", 17)
notice.Visible=false
local center = text("Crosshair", UDim2.new(0.5, -10, 0.5, -10), UDim2.fromOffset(20, 20), "+", 21)
center.BackgroundTransparency = 1; center.Visible = false
local centerBorder=center:FindFirstChildOfClass("UIStroke");if centerBorder then centerBorder:Destroy() end
-- Match Camera.ViewportPointToRay, rather than the HUD's top-bar safe inset.
local reticleGui=Instance.new("ScreenGui"); reticleGui.Name="HunDinoReticle"; reticleGui.IgnoreGuiInset=true
reticleGui.ResetOnSpawn=false; reticleGui.Parent=player.PlayerGui; center.Parent=reticleGui
center.TextColor3=Color3.fromRGB(241,255,250); center.TextStrokeTransparency=.25
local locked, aiming, lastDirection = false, false, Vector3.new(0, 0, -1)
local autoAimTarget: BasePart? = nil
local serverAiming=false
local lastAimSent=-math.huge
local function setServerAiming(enabled)
 local now=os.clock()
 if serverAiming==enabled and (player:GetAttribute("BowAiming")==enabled or now-lastAimSent<.35) then return end
 serverAiming=enabled;lastAimSent=now;remote:FireServer("Aim",enabled)
end
local function requestControlPreference(key,value)
 if player:GetAttribute("ProfileReady")~=true then return end
 local profile=ReplicatedStorage:FindFirstChild("HunDinoProfileAction")
 if profile then profile:FireServer("Preference",key,value) end
end

local appliedMouseLock = false
local bowView, bowBlend = nil, 0
local function setZoom(distance)
	player.CameraMaxZoomDistance=math.max(player.CameraMinZoomDistance,distance)
	player.CameraMinZoomDistance=distance; player.CameraMaxZoomDistance=distance
end
local function restoreBowView()
	if not bowView then return end
	if bowView.Humanoid.Parent then
		bowView.Humanoid.CameraOffset=bowView.Offset; bowView.Humanoid.AutoRotate=true
	end
	bowView.Camera.FieldOfView=bowView.FOV
	player.CameraMaxZoomDistance=math.max(player.CameraMinZoomDistance,bowView.MaxZoom)
	player.CameraMinZoomDistance=bowView.MinZoom; player.CameraMaxZoomDistance=bowView.MaxZoom
	UIS.MouseDeltaSensitivity=bowView.Sensitivity; UIS.MouseIconEnabled=bowView.MouseIcon
	bowView=nil; bowBlend=0
end
local noticeId = 0
local function announce(message)
	noticeId += 1; local id = noticeId
	notice.Text = message; notice.Visible = true
	task.delay(5, function() if noticeId == id then notice.Visible = false end end)
end
local hub
local readyAt=0; local inputSerial=0
local held={Light=false}
local chargeId=0;local activeCharge
local chargeHUD=text("Charge",UDim2.new(.5,-170,.65,0),UDim2.fromOffset(340,44),"",16)
chargeHUD.AnchorPoint=Vector2.new(.5,1);chargeHUD.Position=UDim2.new(.5,0,1,-200)
chargeHUD.Visible=false
local function cancelHeld(sendCancel: boolean?)
 for k in held do held[k]=false end
 activeCharge=nil;chargeHUD.Visible=false;if sendCancel~=false then remote:FireServer("ChargeCancel") end
 if readyAt==math.huge then readyAt=os.clock()+.15 end
end
local inventory=require(ReplicatedStorage.Shared:WaitForChild("EquipmentInventory")).create(player,gui,Weapons,remote)
local panel=inventory.Frame
local baseTransit=require(ReplicatedStorage.Shared:WaitForChild("BaseTransitMenu")).create(player,gui,function(id) remote:FireServer("BaseTransitSelect",id) end)
local function recipe(input)
 local key={L="Trái",H="Q",S="E",D="Space"};local parts={}
 for letter in input:gmatch(".") do table.insert(parts,key[letter]) end
 return table.concat(parts," → ")
end
local function recipes(weapon)
 local lines={}
 for _,combo in weapon.Combos do table.insert(lines,weapon.Attacks[combo.Attack].Name..": "..recipe(combo.Input)) end
 return table.concat(lines,"\n")
end
local comboHUD=text("ComboGuide",UDim2.new(0,20,.5,-90),UDim2.fromOffset(330,220),"",14)
comboHUD.Visible=false
local comboScale=Instance.new("UIScale");comboScale.Parent=comboHUD
local compactHUD=false
local refresh
local hudScales={}
for _,item in {title,stats,staminaBG,notice,chargeHUD} do local scale=Instance.new("UIScale");scale.Parent=item;hudScales[item]=scale end
local function resizeHUD()
 local camera=workspace.CurrentCamera;if not camera then return end
 local size=gui.AbsoluteSize
 if size.X<=0 or size.Y<=0 then size=camera.ViewportSize end
 compactHUD=size.X<1000 or size.Y<560
 local compact=compactHUD
 local factor=if compact then math.min(.65,(size.X-32)/650) else 1
 for _,scale in hudScales do scale.Scale=factor end
 title.Position=UDim2.fromOffset(if compact then 12 else 20,if compact then 8 else 14)
 stats.Position=UDim2.new(0,if compact then 12 else 20,1,if compact then -80 else -136)
 staminaBG.Position=UDim2.new(0,if compact then 12 else 20,1,if compact then -30 else -60)
 notice.AnchorPoint=Vector2.new(.5,1)
 notice.Size=UDim2.fromOffset(420,36);notice.TextSize=13
 notice.Position=UDim2.new(.5,0,1,if compact then -12 else -86)
 chargeHUD.Position=UDim2.new(.5,0,1,if compact then -64 else -200)
 comboHUD.AnchorPoint=Vector2.new(.5,1)
 comboHUD.Position=UDim2.new(.5,0,1,-84)
 comboHUD.Size=UDim2.fromOffset(360,164);comboHUD.TextSize=12
 comboScale.Scale=math.min(1,math.max(.5,(size.X-740)/360))
 if compact then comboHUD.Visible=false end
 local admin=player.PlayerGui:FindFirstChild("HunDinoAdminFlyHUD")
 local flight=admin and admin:FindFirstChild("FlightPanel")
 if flight then
  local scale=flight:FindFirstChild("UICompactScale") or Instance.new("UIScale")
  scale.Name="UICompactScale";scale.Scale=if compact then .55 else .8;scale.Parent=flight
  local inset=GuiService:GetGuiInset()
  flight.AnchorPoint=if compact then Vector2.zero else Vector2.new(1,0)
  flight.Position=if compact then UDim2.new(0,12,0,inset.Y+56) else UDim2.new(1,-184,0,inset.Y+14)
 end
 if refresh then refresh() end
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeHUD);resizeHUD()
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeHUD)
player.PlayerGui.ChildAdded:Connect(function(child) if child.Name=="HunDinoAdminFlyHUD" then task.defer(resizeHUD) end end)
local function toggleMenu()
 baseTransit:Close()
	inputSerial+=1
	if hub then hub:Close() end
	cancelHeld(); inputSerial+=1
	if panel.Visible then panel.Visible=false; return end
	if player:GetAttribute("Drawn") then announce("Nhấn R cất vũ khí trước khi mở túi."); return end
	panel.Visible=true; aiming=false; locked=false; setServerAiming(false); remote:FireServer("Sprint",false); remote:FireServer("Guard",false)
end

local refreshPreferences=function() end
hub=require(ReplicatedStorage.Shared.HubUI).create(player,gui,{
 Inventory=toggleMenu,
 BeforeOpen=function()
  baseTransit:Close()
  cancelHeld(); inputSerial+=1
  inputSerial+=1
  panel.Visible=false; aiming=false; locked=false
  setServerAiming(false); remote:FireServer("Sprint",false); remote:FireServer("Guard",false)
 end,
 Travel=function(destination) remote:FireServer("TravelMenu",destination) end,
 Preferences=function() refreshPreferences() end,
})
local function menuOpen()
 local economyGUI=player.PlayerGui:FindFirstChild("HunDinoEconomy")
 local economyPanel=economyGUI and economyGUI:FindFirstChild("Panel")
 if economyPanel and economyPanel.Visible then return true end
 local questGUI=player.PlayerGui:FindFirstChild("HunDinoHuntQuest")
 if questGUI then
  for _,name in {"QuestBoard","ResultModal"} do
   local menu=questGUI:FindFirstChild(name);if menu and menu.Visible then return true end
  end
 end
 local forestGUI=player.PlayerGui:FindFirstChild("HuntingMapViewer")
 local picker=forestGUI and forestGUI:FindFirstChild("ZonePicker")
 return panel.Visible or hub:IsOpen() or baseTransit:IsOpen() or (forestGUI and forestGUI.Enabled and picker and picker.Visible) or false
end
local function aimDirection(ranged, dodge)
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local dir = lastDirection
	if ranged and root then
		local camera=workspace.CurrentCamera; local size=camera.ViewportSize
		local ray=camera:ViewportPointToRay(size.X/2,size.Y/2)
		local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
		local ignored={character}
  local pets=workspace:FindFirstChild("TrainingPets");if pets then table.insert(ignored,pets) end
  for _,other in Players:GetPlayers() do if other~=player and other.Character then table.insert(ignored,other.Character) end end
  params.FilterDescendantsInstances=ignored
  local result=workspace:Raycast(ray.Origin,ray.Direction*250,params)
  local target=if autoAimTarget and autoAimTarget.Parent then autoAimTarget.Position elseif result then result.Position else ray.Origin+ray.Direction*250
  return Bow.direction(Bow.origin(root.Position),target,camera.CFrame.LookVector),target
	end
	if (locked or aiming) and not dodge then dir = workspace.CurrentCamera.CFrame.LookVector
	elseif hum and hum.MoveDirection.Magnitude > 0.1 then dir = hum.MoveDirection
	elseif root then dir = lastDirection end
	dir = Vector3.new(dir.X, 0, dir.Z)
	return if dir.Magnitude > 0.01 then dir.Unit else Vector3.new(0, 0, -1)
end
local function findAutoAimTarget(camera, character, root, preferred)
	local candidates={}
	local function addCandidate(part, model)
		if not part or not part:IsA("BasePart") or not model then return end
  local faction=model:GetAttribute("CombatFaction")
  if faction and character:GetAttribute("CombatFaction")==faction then return end
		local delta=part.Position-root.Position
		if delta.Magnitude>120 or delta.Magnitude<1 then return end
		local screen,onScreen=camera:WorldToViewportPoint(part.Position)
		if not onScreen or screen.Z<=0 then return end
		local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances={character,workspace:FindFirstChild("TrainingPets")}
		local obstruction=workspace:Raycast(camera.CFrame.Position,part.Position-camera.CFrame.Position,params)
		if obstruction and not obstruction.Instance:IsDescendantOf(model) then return end
		local center=Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
		local screenDistance=(Vector2.new(screen.X,screen.Y)-center).Magnitude
		table.insert(candidates,{Part=part,Distance=screenDistance,WorldDistance=delta.Magnitude})
	end
	if player:GetAttribute("InTraining")==true then
		local map=workspace:FindFirstChild("HunDinoL0")
		local training=map and map:FindFirstChild("Training")
		local dummies=training and training:FindFirstChild("Dummies")
		if dummies then
			for _,dummy in dummies:GetChildren() do
				local target=dummy:FindFirstChild("Target")
				if (dummy:GetAttribute("Health") or 0)>0 then addCandidate(target,dummy) end
			end
		end
	elseif player:GetAttribute("InHunting")==true then
		local dinosaur=workspace:FindFirstChild("Dinosaur01_TRex_Visual")
		if dinosaur and dinosaur:GetAttribute("DinosaurDead")~=true
			and dinosaur:GetAttribute("Captured")~=true and (dinosaur:GetAttribute("Health") or 0)>0 then
			local hitboxes=dinosaur:FindFirstChild("CombatHitboxes")
			if hitboxes then
				for _,part in hitboxes:GetChildren() do
					if part:IsA("BasePart") and part:GetAttribute("DinosaurHurtbox")==true then
						addCandidate(part,dinosaur)
					end
				end
			end
			if #candidates==0 then addCandidate(dinosaur.PrimaryPart,dinosaur) end
		end
	end
	table.sort(candidates,function(a,b)
		if math.abs(a.Distance-b.Distance)<2 then return a.WorldDistance<b.WorldDistance end
		return a.Distance<b.Distance
	end)
	for _,candidate in candidates do
		if candidate.Part==preferred then return preferred end
	end
	return candidates[1] and candidates[1].Part or nil
end
local function send(action,automatic)
 local function dispatch()
  if player:GetAttribute("AdminFlying")==true or menuOpen() or GuiService.MenuIsOpen or UIS:GetFocusedTextBox() then return end
  local ranged=player:GetAttribute("WeaponId")=="Bow"
  local direction,targetPoint=aimDirection(ranged and (action=="Light" or action=="Heavy" or action=="Skill"),action=="Dodge")
  if ranged and action=="Light" then
   if activeCharge or not player:GetAttribute("Drawn") then return end
   chargeId+=1;local token=chargeId
   activeCharge={Id=token,Action=action,Started=os.clock(),Time=Weapons.Bow.Charge.Time,Automatic=automatic==true}
   remote:FireServer("ChargeStart",{Id=token,Action=action,Direction=direction,Target=targetPoint})
   if not held[action] and not automatic then remote:FireServer("ChargeRelease",{Id=token,Direction=direction,Target=targetPoint});activeCharge=nil end
  elseif ranged then remote:FireServer(action,{Direction=direction,Target=targetPoint})
  else remote:FireServer(action,direction) end
 end
 inputSerial+=1; local serial=inputSerial; local remaining=readyAt-os.clock()
 if remaining>0 and remaining<=.2 and action~="Jump" then
  task.delay(remaining+.03,function() if serial==inputSerial then dispatch() end end)
 elseif remaining<=0 then dispatch() end
end
-- Consume Space before Roblox's default jump binding. The server arbitrates
-- jump/dodge together, so simultaneous keys cannot combine their impulses.
local function movementAction(actionName, inputState)
	if player:GetAttribute("AdminFlying")==true then return Enum.ContextActionResult.Pass end
	if inputState == Enum.UserInputState.Begin and not menuOpen() and not UIS:GetFocusedTextBox() and not GuiService.MenuIsOpen then
		if actionName == "HunDinoJump" then send("Jump") else send("Dodge") end
	end
	return Enum.ContextActionResult.Sink
end
ContextActionService:BindActionAtPriority("HunDinoJump", movementAction, false, 3001, Enum.KeyCode.V)
ContextActionService:BindActionAtPriority("HunDinoDodge", movementAction, false, 3001, Enum.KeyCode.Space)
-- I also zooms Roblox's default camera; consume it when opening the armory.
ContextActionService:BindActionAtPriority("HunDinoArmory", function(_, inputState)
	if player:GetAttribute("AdminFlying")==true then return Enum.ContextActionResult.Sink end
	if inputState == Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() and not GuiService.MenuIsOpen then toggleMenu() end
	return Enum.ContextActionResult.Sink
end, false, 3001, Enum.KeyCode.I)
local weaponHotkeyKeys={Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four,Enum.KeyCode.Five,Enum.KeyCode.Six,Enum.KeyCode.Seven}
local function useWeaponSlot(slot)
 if player:GetAttribute("ProfileReady")~=true or player:GetAttribute("AdminFlying")==true or menuOpen() or GuiService.MenuIsOpen or UIS:GetFocusedTextBox()
  or not (player:GetAttribute("InTraining")==true or player:GetAttribute("InHunting")==true) then return false end
 cancelHeld();inputSerial+=1;aiming=false;setServerAiming(false)
 remote:FireServer("WeaponHotkey",slot)
 return true
end
ContextActionService:BindActionAtPriority("HunDinoWeaponHotkeys",function(_,state,input)
 if state~=Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
 local slot=table.find(weaponHotkeyKeys,input.KeyCode)
 return if slot and useWeaponSlot(slot) then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
end,false,3002,table.unpack(weaponHotkeyKeys))
local hotbar=Instance.new("Frame");hotbar.Name="WeaponHotbar";hotbar.BackgroundTransparency=1
hotbar.AnchorPoint=Vector2.new(.5,1);hotbar.Position=UDim2.new(.5,0,1,-12);hotbar.Size=UDim2.fromOffset(428,56);hotbar.Parent=gui
local hotbarScale=Instance.new("UIScale");hotbarScale.Parent=hotbar
local hotbarButtons={}
local shortNames={Hammer="Búa",SwordShield="Kiếm/khiên",Katana="Katana",Glaive="Thương",DualDaggers="Song đao",Bow="Cung",GreatAxe="Rìu"}
for slot,id in Weapons.Order do
 local button=Instance.new("TextButton");button.Name=id;button.Size=UDim2.fromOffset(56,56);button.Position=UDim2.fromOffset((slot-1)*62,0)
 button.BackgroundColor3=C.Panel;button.BackgroundTransparency=.08;button.TextColor3=C.Text;button.Font=Enum.Font.GothamMedium;button.TextSize=11;button.TextWrapped=true
 button.Text=tostring(slot).."\n"..shortNames[id];button.Parent=hotbar;Theme.panel(button)
 button.Activated:Connect(function() useWeaponSlot(slot) end);hotbarButtons[id]=button
end
local function refreshHotbar()
 hotbarScale.Scale=math.min(1,math.max(.4,(gui.AbsoluteSize.X-24)/428))
 hotbar.Visible=player:GetAttribute("ProfileReady")==true and (player:GetAttribute("InTraining")==true or player:GetAttribute("InHunting")==true)
  and not menuOpen() and player:GetAttribute("AdminFlying")~=true
 for id,button in hotbarButtons do
  local selected=player:GetAttribute("WeaponId")==id
  button.TextColor3=if selected then C.Gold else C.Text
  button.BackgroundColor3=if selected and player:GetAttribute("Drawn")==true then Color3.fromRGB(58,53,32) else C.Panel
  local stroke=button:FindFirstChildOfClass("UIStroke");if stroke then stroke.Color=if selected then C.Gold else C.Border end
 end
end

script.Destroying:Connect(function()
	restoreBowView(); reticleGui:Destroy()
	if appliedMouseLock then UIS.MouseBehavior=Enum.MouseBehavior.Default end
	ContextActionService:UnbindAction("HunDinoJump")
	ContextActionService:UnbindAction("HunDinoDodge")
	ContextActionService:UnbindAction("HunDinoArmory")
	ContextActionService:UnbindAction("HunDinoWeaponHotkeys")
	RunService:UnbindFromRenderStep("HunDinoTrainingCamera")
	RunService:UnbindFromRenderStep("HunDinoBowView")
end)
local function bowMouseButton(aim)
 local swapped=player:GetAttribute("SwapBowButtons")==true
 return if aim~=swapped then Enum.UserInputType.MouseButton2 else Enum.UserInputType.MouseButton1
end
UIS.InputBegan:Connect(function(input,processed)
 if processed or UIS:GetFocusedTextBox() or menuOpen() or GuiService.MenuIsOpen or player:GetAttribute("AdminFlying")==true then return end
 local ranged=Weapons[player:GetAttribute("WeaponId") or "Hammer"].Ranged==true
 if ranged and input.UserInputType==bowMouseButton(true) and player:GetAttribute("Drawn")==true then
  aiming=true;setServerAiming(true)
 elseif input.UserInputType==(if ranged then bowMouseButton(false) else Enum.UserInputType.MouseButton1) then
  if activeCharge and activeCharge.Automatic then cancelHeld();readyAt=os.clock() end
  held.Light=true;send("Light")
 elseif input.KeyCode==Enum.KeyCode.F then remote:FireServer("Guard",true)
 elseif input.KeyCode==Enum.KeyCode.Q then send("Heavy")
 elseif input.KeyCode==Enum.KeyCode.E then send("Skill")
 elseif input.KeyCode==Enum.KeyCode.R then
  cancelHeld(false);inputSerial+=1;aiming=false;setServerAiming(false);remote:FireServer("Draw")
 elseif input.KeyCode==Enum.KeyCode.K and player:GetAttribute("WeaponId")=="Katana" then
  if player:GetAttribute("Drawn")~=true and player:GetAttribute("WeaponHandling")~=true then requestControlPreference("KatanaCarry",(player:GetAttribute("KatanaCarry") or 1)%2+1) end
 elseif input.KeyCode==Enum.KeyCode.T then
  requestControlPreference("AutoBowAim",player:GetAttribute("AutoBowAim")~=true)
 elseif input.KeyCode==Enum.KeyCode.Y then
  requestControlPreference("AutoBowFire",player:GetAttribute("AutoBowFire")~=true)
 elseif input.KeyCode==Enum.KeyCode.B then
  local key=if ranged then "RangedStance" else "MeleeStance"
  local names=if ranged then Config.Controls.RangedStances else Config.Controls.MeleeStances
  requestControlPreference(key,(player:GetAttribute(key) or 1)%#names+1)
 elseif input.KeyCode==Enum.KeyCode.LeftShift then
  cancelHeld();inputSerial+=1;aiming=false;setServerAiming(false);remote:FireServer("Sprint",true)
 elseif input.KeyCode==Enum.KeyCode.LeftControl then locked=not locked;center.Visible=locked end
end)
UIS.InputEnded:Connect(function(input)
 local ranged=Weapons[player:GetAttribute("WeaponId") or "Hammer"].Ranged==true
 if input.UserInputType==(if ranged then bowMouseButton(false) else Enum.UserInputType.MouseButton1) then
  held.Light=false
  if activeCharge and not activeCharge.Automatic then
   local charge=activeCharge;local direction,target=aimDirection(true,false)
   remote:FireServer("ChargeRelease",{Id=charge.Id,Direction=direction,Target=target})
   activeCharge=nil;chargeHUD.Visible=false;readyAt=os.clock()+.12
  end
 end
 if ranged and input.UserInputType==bowMouseButton(true) then
  aiming=false;setServerAiming(false)
  if activeCharge and activeCharge.Automatic then cancelHeld() end
 end
 if input.KeyCode==Enum.KeyCode.F then remote:FireServer("Guard",false) end
 if input.KeyCode==Enum.KeyCode.LeftShift then remote:FireServer("Sprint",false) end
end)

UIS.WindowFocusReleased:Connect(function()
	cancelHeld(); inputSerial+=1
	remote:FireServer("Sprint", false); locked = false; center.Visible = false
	aiming=false; setServerAiming(false); remote:FireServer("Guard",false)
end)
local function characterAdded(character)
 baseTransit:Close()
	cancelHeld(); readyAt=0; inputSerial+=1; hub:Close()
	restoreBowView()
	local hum = character:WaitForChild("Humanoid")
	-- Use the normal jump state/animation; Space is consumed by the binding above.
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	hum.AutoJumpEnabled = false
	hum.UseJumpPower = true; hum.JumpPower = 50
	lastDirection = Vector3.new(0, 0, -1); locked = false; aiming=false; autoAimTarget=nil
	setServerAiming(false);panel.Visible=false;center.Visible=false
end
player.CharacterAdded:Connect(characterAdded)
if player.Character then task.spawn(characterAdded, player.Character) end
-- Feed the shoulder offset/zoom to Roblox's camera before its collision solver.
-- Keeping CameraType.Custom retains normal mouse orbit and wall occlusion.
RunService:BindToRenderStep("HunDinoBowView", Enum.RenderPriority.Camera.Value-1, function(dt)
	local character=player.Character; local hum=character and character:FindFirstChildOfClass("Humanoid")
	local camera=workspace.CurrentCamera
	local want=(aiming or autoAimTarget~=nil) and hum and hum.Health>0 and player:GetAttribute("WeaponId")=="Bow"
		and player:GetAttribute("Drawn") and not menuOpen() and not GuiService.MenuIsOpen and not UIS:GetFocusedTextBox()
		and camera.CameraType==Enum.CameraType.Custom
	if bowView and (bowView.Humanoid~=hum or bowView.Camera~=camera or not hum or hum.Health<=0) then restoreBowView() end
	if want and not bowView then
		bowView={Humanoid=hum,Camera=camera,Offset=hum.CameraOffset,AutoRotate=hum.AutoRotate,FOV=camera.FieldOfView,
			MinZoom=player.CameraMinZoomDistance,MaxZoom=player.CameraMaxZoomDistance,
			Distance=math.clamp((camera.CFrame.Position-camera.Focus.Position).Magnitude,player.CameraMinZoomDistance,player.CameraMaxZoomDistance),
			Sensitivity=UIS.MouseDeltaSensitivity,MouseIcon=UIS.MouseIconEnabled}
	end
	if not bowView then return end
	bowBlend+=( (if want then 1 else 0)-bowBlend)*(1-math.exp(-12*dt))
	hum.CameraOffset=bowView.Offset+Vector3.new(2.6,.65,0)*bowBlend
	camera.FieldOfView=bowView.FOV+(58-bowView.FOV)*bowBlend
	setZoom(bowView.Distance+(8.5-bowView.Distance)*bowBlend)
	UIS.MouseDeltaSensitivity=bowView.Sensitivity*(1-.35*bowBlend)*(player:GetAttribute("AimSensitivity") or 1)
	UIS.MouseIconEnabled=if want then false else bowView.MouseIcon
	if not want and bowBlend<.001 then setZoom(bowView.Distance); restoreBowView() end
end)
RunService:BindToRenderStep("HunDinoTrainingCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if player:GetAttribute("AdminFlying")==true then
		restoreBowView();aiming=false;autoAimTarget=nil;setServerAiming(false);locked=false;center.Visible=false
		if appliedMouseLock then UIS.MouseBehavior=Enum.MouseBehavior.Default;appliedMouseLock=false end
		return
	end
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	local root=character and character.PrimaryPart
	local camera=workspace.CurrentCamera
	if player:GetAttribute("AutoBowAim")==true and player:GetAttribute("ProfileReady")==true and player:GetAttribute("WeaponId")=="Bow"
		and player:GetAttribute("Drawn")==true and (player:GetAttribute("InTraining")==true or player:GetAttribute("InHunting")==true)
		and not menuOpen() and not GuiService.MenuIsOpen and not UIS:GetFocusedTextBox()
		and hum and hum.Health>0 and root and camera.CameraType==Enum.CameraType.Custom then
		autoAimTarget=findAutoAimTarget(camera,character,root,autoAimTarget)
	else
		autoAimTarget=nil
	end
	local autoAiming=autoAimTarget~=nil
	setServerAiming(aiming or autoAiming)
	if autoAimTarget and camera.CameraType==Enum.CameraType.Custom then
		local look=CFrame.lookAt(camera.CFrame.Position,autoAimTarget.Position)
		camera.CFrame=camera.CFrame:Lerp(look,1-math.exp(-7*dt))
	end
	if hum and hum.MoveDirection.Magnitude > 0.1 then lastDirection = hum.MoveDirection.Unit end
	if not player:GetAttribute("Drawn") or GuiService.MenuIsOpen or menuOpen() or not hum or hum.Health<=0 then
		if aiming then setServerAiming(false) end
		aiming=false
	end
	if (aiming and bowView or autoAiming) and root and hum then
		local look=workspace.CurrentCamera.CFrame.LookVector
		local flat=Vector3.new(look.X,0,look.Z)
		if flat.Magnitude>.01 then
			hum.AutoRotate=false
			local facing=CFrame.lookAt(root.Position,root.Position+flat)
			root.CFrame=root.CFrame:Lerp(facing,1-math.exp(-10*dt))
		end
 elseif hum and player:GetAttribute("WeaponId")=="Bow" then hum.AutoRotate=true
	end
	local canControl=hum and hum.Health>0 and not GuiService.MenuIsOpen and not UIS:GetFocusedTextBox()
	center.Text=if autoAiming then "◎" else "+"
	center.Visible=canControl and not menuOpen() and (locked or (player:GetAttribute("WeaponId")=="Bow" and player:GetAttribute("Drawn"))) or false
	if canControl and (locked or aiming or autoAiming) and not menuOpen() then
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter; appliedMouseLock = true
	elseif appliedMouseLock then
		UIS.MouseBehavior = Enum.MouseBehavior.Default; appliedMouseLock = false
	end
end)
GuiService.MenuOpened:Connect(function() cancelHeld();inputSerial+=1 end)
local chargeClock=0
-- Procedural upper-body poses run for every visible player, after Animator.
-- Restore the prior Animator transform before the next animation step.
local presentationRigs=setmetatable({},{__mode="k"})
local presentationConnections={}
local function restorePresentation()
 for _,rig in presentationRigs do
  for joint,record in rig.Joints do
   if joint.Parent and record.Applied then joint.Transform=record.Base;record.Applied=false end
  end
 end
end
local function visualGrip(assembly,torso,frame)
 local handle=assembly and assembly.PrimaryPart
 local grip=handle and handle:FindFirstChildOfClass("Weld")
 if grip then grip.Part0=torso;grip.C0=torso.CFrame:ToObjectSpace(frame) end
end
local function palmFrame(arm,torso)
 if not arm then return torso.CFrame*CFrame.new(0,-1,0) end
 return CFrame.new(arm.Hand.CFrame:PointToWorldSpace(arm.Palm))*torso.CFrame.Rotation
end
local function applyArm(rig,arm,goal,weight)
 local transforms,contact=Handling.solve(arm,goal)
 for joint,transform in transforms do
  local record=rig.Joints[joint]
  if record then
   record.Base=joint.Transform
   joint.Transform=record.Base:Lerp(transform,weight);record.Applied=true
  end
 end
 return contact
end
table.insert(presentationConnections,RunService.PreAnimation:Connect(restorePresentation))
table.insert(presentationConnections,RunService.PreSimulation:Connect(function(dt)
 local now=workspace:GetServerTimeNow()
 for _,viewer in Players:GetPlayers() do
  local character=viewer.Character
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  local torso=character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
  local weapon=character and character:FindFirstChild("TrainingWeapon")
  if not humanoid or not torso or not weapon then continue end
  local rig=presentationRigs[character]
  if not rig or rig.Weapon~=weapon or not rig.Left or not rig.Right or not rig.Left.Shoulder.Parent or not rig.Right.Shoulder.Parent then
   rig={Weapon=weapon,Joints={},Left=Handling.arm(character,"left"),Right=Handling.arm(character,"right"),Weight=0}
   for _,arm in {rig.Left,rig.Right} do
    if arm then for _,joint in {arm.Shoulder,arm.Elbow,arm.Wrist} do if joint then rig.Joints[joint]={Base=joint.Transform} end end end
   end
   rig.Segmented=false
   for _,joint in character:GetDescendants() do
    if joint:IsA("Motor6D") or joint:IsA("AnimationConstraint") then
     local name=joint.Name:lower():gsub("%s","")
     if name=="leftknee" or name=="rightknee" then rig.Segmented=true end
     if name=="rootjoint" or name=="root" or name=="waist" or name=="lefthip" or name=="righthip"
      or name=="leftknee" or name=="rightknee" or name=="leftankle" or name=="rightankle" then
      rig.Joints[joint]={Base=joint.Transform,Body=true,Name=name}
     end
    end
   end
   presentationRigs[character]=rig
  end
  local id=viewer:GetAttribute("WeaponId") or "Hammer"
  if not Weapons[id] then continue end
  local ranged=Weapons[id].Ranged==true
  local stance=viewer:GetAttribute(if ranged then "RangedStance" else "MeleeStance") or 1
  local target=character:GetAttribute("WeaponDrawTarget")
  local token=character:GetAttribute("WeaponDrawAt")
  local drawing=target~=nil and type(token)=="number"
  local drawn=character:GetAttribute("WeaponPresentationDrawn")==true
  local usable=humanoid.Health>0 and viewer:GetAttribute("AdminFlying")~=true
  local active=usable and (drawing or drawn)
  local blend=1-math.exp(-14*math.min(dt,.1))
  rig.Weight+=((if active then 1 else 0)-rig.Weight)*blend
  local q=if drawn then 1 else 0
  if drawing then
   q=Handling.phase((now-token)/(character:GetAttribute("WeaponDrawDuration") or 1.6),target)
   if rig.Token~=token then
    rig.Token=token
    rig.IdleLeft=torso.CFrame:ToObjectSpace(palmFrame(rig.Left,torso))
    rig.IdleRight=torso.CFrame:ToObjectSpace(palmFrame(rig.Right,torso))
   end
  end
  local charging=viewer:GetAttribute("Charging")==true or character:GetAttribute("ChargePose")=="Bow"
  local aim=ranged and (viewer:GetAttribute("BowAiming")==true or charging)
  local charge=if charging then math.clamp((now-(character:GetAttribute("WeaponChargeAt") or now))/(character:GetAttribute("WeaponChargeDuration") or 1.2),0,1) else 0
  local ready=Handling.ready(id,false,stance,aim,charge)
  local offReady=Handling.ready(id,true,stance,aim,charge)
  local attackAlpha=(now-(character:GetAttribute("WeaponAttackAt") or -math.huge))/math.max(.1,character:GetAttribute("WeaponAttackDuration") or .6)
  local attacking=drawn and not drawing and attackAlpha>=0 and attackAlpha<1
  if attacking and not ranged then
   local swing=math.sin(attackAlpha*math.pi)
   if id=="GreatAxe" or id=="Glaive" or id=="Hammer" then
    ready=CFrame.new(ready.Position+Vector3.new(0,swing*.65,0))*CFrame.Angles(math.rad(-125+165*attackAlpha),0,-.1)
   else
    ready=CFrame.new(ready.Position+Vector3.new(.65-1.3*attackAlpha,.25*swing,-.25*swing))*CFrame.Angles(math.rad(-38),math.rad(65-130*attackAlpha),-.15)
    if id=="DualDaggers" then offReady=CFrame.new(offReady.Position+Vector3.new(-.65+1.3*attackAlpha,-.2*swing,0))*CFrame.Angles(math.rad(-38),math.rad(-65+130*attackAlpha),.15) end
   end
  end
  local idle=usable and drawn and not drawing and not ranged and stance>=4 and not attacking
   and humanoid.MoveDirection.Magnitude<.08 and humanoid.FloorMaterial~=Enum.Material.Air
   and not humanoid.Sit and not humanoid.PlatformStand
  local dodgeAt=character:GetAttribute("DarkStepStarted") or -math.huge
  if now-dodgeAt<(character:GetAttribute("DarkStepDuration") or 0)+.15 then idle=false end
  rig.BodyWeight=(rig.BodyWeight or 0)+((if idle then 1 else 0)-(rig.BodyWeight or 0))*(1-math.exp(-12*math.min(dt,.1)))
  for joint,record in rig.Joints do
   if record.Body and joint.Parent and rig.BodyWeight>.001 then
    record.Base=joint.Transform
    local offset=Handling.bodyPose(stance,record.Name,rig.Segmented)
    record.BodyOffset=if record.BodyOffset then record.BodyOffset:Lerp(offset,blend) else offset
    local goal=Handling.bodyTransform(joint,record.Base,record.BodyOffset)
    joint.Transform=record.Base:Lerp(goal,rig.BodyWeight);record.Applied=true
   end
  end

  if not drawing then
   rig.ReadyMain=if rig.ReadyMain then rig.ReadyMain:Lerp(ready,blend) else ready
   rig.ReadyOff=if rig.ReadyOff then rig.ReadyOff:Lerp(offReady,blend) else offReady
   ready=rig.ReadyMain;offReady=rig.ReadyOff
  else rig.ReadyMain=ready;rig.ReadyOff=offReady end
  local mainArm=if ranged then rig.Left else rig.Right
  local carry=viewer:GetAttribute("KatanaCarry") or 1
  local mount=character:GetAttribute("WeaponMainMountC0")
  if typeof(mount)~="CFrame" then
   mount=torso.CFrame:ToObjectSpace(Handling.reach(mainArm,torso.CFrame*Handling.mount(id,false,carry,torso.Size)))
  end
  local scale=Handling.scale(id)
  if id=="DualDaggers" then
   local offMount=character:GetAttribute("WeaponOffMountC0") or Handling.mount(id,true,carry,torso.Size)
   local handoff=torso.CFrame:ToObjectSpace(Handling.handoff(rig.Left,rig.Right,torso.CFrame))
   local idleRight=rig.IdleRight or torso.CFrame:ToObjectSpace(palmFrame(rig.Right,torso))
   local idleLeft=rig.IdleLeft or torso.CFrame:ToObjectSpace(palmFrame(rig.Left,torso))
   local main,off,rightGoal,leftGoal=Handling.dual(mount,offMount,ready,offReady,handoff,idleRight,idleLeft,q)
   local weight=if active and q>=.18 then 1 else rig.Weight
   local rightContact=applyArm(rig,rig.Right,torso.CFrame*rightGoal,weight)
   local leftContact=applyArm(rig,rig.Left,torso.CFrame*leftGoal,weight)
   if q>=.54 then main=torso.CFrame:ToObjectSpace(rightContact) end
   if q>=.35 then off=torso.CFrame:ToObjectSpace(leftContact)
   elseif q>=.18 then off=torso.CFrame:ToObjectSpace(rightContact) end
   visualGrip(weapon:FindFirstChild("Main"),torso,torso.CFrame*main)
   visualGrip(weapon:FindFirstChild("Offhand"),torso,torso.CFrame*off)
   continue
  end
  local mainGoal=torso.CFrame*Handling.path(mount,ready,q,id,scale)
  local sheathGoal
  if id=="Katana" then mainGoal,sheathGoal=Handling.katana(torso.CFrame,mount,ready,q,scale,rig.Right,rig.Left) end
  local gripPose=Handling.grip(id)
  if Handling.twoHanded(id,stance) then
   local offset=Handling.supportOffset(id,stance)
   local contactPose=Handling.twoHand(rig.Right,rig.Left,mainGoal*gripPose,offset-gripPose.Y)*gripPose:Inverse()
   local start=if id=="Katana" then Handling.Return else .75
   mainGoal=mainGoal:Lerp(contactPose,Handling.smooth((q-start)/(1-start)))
  end
  local sheathRelative=if id=="Katana" and q>=Handling.Grab and q<=Handling.Clear then mainGoal:ToObjectSpace(sheathGoal) else nil
  local idleMain=if ranged then rig.IdleLeft else rig.IdleRight
  idleMain=idleMain or torso.CFrame:ToObjectSpace(palmFrame(mainArm,torso))
  local handGoal=if q<Handling.Grab then (torso.CFrame*idleMain):Lerp(torso.CFrame*mount*gripPose,Handling.contactWeight(q)) else mainGoal*gripPose
  local weight=if active and q>=Handling.Grab then 1 else rig.Weight
  local contact=applyArm(rig,mainArm,handGoal,weight)
  if not mainArm and active and not drawing then
   local hand=character:FindFirstChild(if ranged then "LeftHand" else "RightHand") or character:FindFirstChild(if ranged then "Left Arm" else "Right Arm")
   if hand then contact=CFrame.new(hand.CFrame:PointToWorldSpace(Vector3.new(0,-hand.Size.Y*.5+.1,0)))*mainGoal.Rotation end
  end
  if q>=Handling.Grab then mainGoal=contact*gripPose:Inverse() end
  if sheathRelative then sheathGoal=mainGoal*sheathRelative end
  visualGrip(weapon:FindFirstChild("Main"),torso,mainGoal)
  local leftGoal
  local off=weapon:FindFirstChild("Offhand")
  if off then
   local offMount=character:GetAttribute("WeaponOffMountC0") or Handling.mount(id,true,carry,torso.Size)
   local offGoal=torso.CFrame*Handling.path(offMount,offReady,q,id,scale)
   if viewer:GetAttribute("Blocking")==true then offGoal=torso.CFrame*CFrame.new(-.75,.1,-1.65) end
   leftGoal=if q<Handling.Grab then (torso.CFrame*(rig.IdleLeft or torso.CFrame:ToObjectSpace(palmFrame(rig.Left,torso)))):Lerp(torso.CFrame*offMount,Handling.contactWeight(q)) else offGoal
   local offContact=applyArm(rig,rig.Left,leftGoal,weight)
   visualGrip(off,torso,if q>=Handling.Grab then offContact else offGoal)
  elseif id=="Katana" then
   local support=Handling.sheathSupport(rig.Left,sheathGoal,scale)
   local lowerGrip=mainGoal*CFrame.new(0,Handling.supportOffset(id,stance),0)
   if q>Handling.Return then
    local readyLeft=if Handling.twoHanded(id,stance) then lowerGrip else torso.CFrame*(rig.IdleLeft or CFrame.new(-1.4,-1,0))
    support=support:Lerp(readyLeft,Handling.smooth((q-Handling.Return)/(1-Handling.Return)))
   end
   local idle=torso.CFrame*(rig.IdleLeft or torso.CFrame:ToObjectSpace(palmFrame(rig.Left,torso)))
   leftGoal=if q<Handling.Grab then idle:Lerp(support,Handling.contactWeight(q)) else support
   applyArm(rig,rig.Left,leftGoal,weight)
   visualGrip(weapon:FindFirstChild("Sheath"),torso,sheathGoal)
   local main=weapon:FindFirstChild("Main")
   for _,part in if main then main:GetChildren() else {} do
    if part:IsA("BasePart") and (part.Name:find("Blade") or part.Name:find("Edge") or part.Name=="Tip") then
     part.LocalTransparencyModifier=if q<=.4 then 1 else 0
    end
   end
  elseif ranged then
   local nockGoal=mainGoal*CFrame.new((1.15+charge*.9)*scale,0,0)
   leftGoal=nockGoal
   local idle=torso.CFrame*(rig.IdleRight or CFrame.new(1.4,-1,0))
   local rightGoal=if aim then nockGoal else idle
   if attacking then rightGoal=rightGoal:Lerp(torso.CFrame*CFrame.new(1.55,.45,.25),math.sin(attackAlpha*math.pi)) end
   if drawing then rightGoal=idle end
   local rightContact=applyArm(rig,rig.Right,rightGoal,weight)
   local main=weapon:FindFirstChild("Main");local handle=main and main.PrimaryPart
   local nock=handle and handle:FindFirstChild("BowStringNock")
   if nock then
    nock.Position=if aim and not drawing then mainGoal:PointToObjectSpace(rightContact.Position) else Vector3.new(1.15*scale,0,0)
    local arrow=main:FindFirstChild("BowHeldArrow")
    local seat=arrow and arrow:FindFirstChild("ArrowSeat")
    if arrow then arrow.LocalTransparencyModifier=if aim and not drawing then 0 else 1 end
    if seat then
     local origin=mainGoal:PointToWorldSpace(nock.Position)
     seat.C0=mainGoal:ToObjectSpace(CFrame.lookAt(origin,origin+torso.CFrame.LookVector)*CFrame.new(0,0,-.8*scale))
    end
   end
  elseif Handling.twoHanded(id,stance) then
   leftGoal=mainGoal*CFrame.new(0,Handling.supportOffset(id,stance),0)
   applyArm(rig,rig.Left,leftGoal,weight)
  elseif not ranged then
   local idle=torso.CFrame*(rig.IdleLeft or CFrame.new(-1.4,-1,0))
   applyArm(rig,rig.Left,idle,rig.Weight)
  end
 end
end))
script.Destroying:Connect(function()
 for _,connection in presentationConnections do connection:Disconnect() end
 restorePresentation();table.clear(presentationRigs)
end)


local petVisibility={}
local function restorePetVisibility()
 for part,value in petVisibility do if part.Parent then part.LocalTransparencyModifier=value end end
 table.clear(petVisibility)
end
script.Destroying:Connect(restorePetVisibility)
RunService.RenderStepped:Connect(function(dt)
 refreshHotbar()
 local autoFire=player:GetAttribute("AutoBowFire")==true and aiming and player:GetAttribute("Drawn")==true
  and player:GetAttribute("WeaponId")=="Bow" and player:GetAttribute("ProfileReady")==true
  and (player:GetAttribute("InTraining")==true or player:GetAttribute("InHunting")==true)
  and not menuOpen() and not GuiService.MenuIsOpen and not UIS:GetFocusedTextBox() and player:GetAttribute("AdminFlying")~=true
 if not autoFire and activeCharge and activeCharge.Automatic then cancelHeld() end
 if autoFire and not held.Light and not activeCharge and os.clock()>=readyAt then send("Light",true) end
 if autoFire and activeCharge and activeCharge.Automatic and os.clock()-activeCharge.Started>=activeCharge.Time then
  local charge=activeCharge;local direction,target=aimDirection(true,false)
  remote:FireServer("ChargeRelease",{Id=charge.Id,Direction=direction,Target=target});activeCharge=nil;readyAt=os.clock()+.65
 end
 chargeClock+=dt
 local bowActive=player:GetAttribute("WeaponId")=="Bow" and player:GetAttribute("Drawn") and (aiming or autoAimTarget~=nil or activeCharge~=nil)
 if bowActive and not menuOpen() and player:GetAttribute("AdminFlying")~=true then
  if chargeClock>=.1 then
   chargeClock=0
   local direction,target=aimDirection(true,false)
   remote:FireServer("BowAim",{Direction=direction,Target=target})
  end
  local pets=workspace:FindFirstChild("TrainingPets")
  local pet=pets and pets:FindFirstChild("Pet_"..player.UserId)
  local camera=workspace.CurrentCamera
  if pet and pet.PrimaryPart and (pet.PrimaryPart.Position-camera.CFrame.Position).Magnitude<14 then
   for _,part in pet:GetDescendants() do
    if part:IsA("BasePart") then
     if petVisibility[part]==nil then petVisibility[part]=part.LocalTransparencyModifier end
     part.LocalTransparencyModifier=1
    end
   end
  else restorePetVisibility() end
 else restorePetVisibility() end
 if not activeCharge then chargeHUD.Visible=false;return end
 local char=player.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not hum or hum.Health<=0 then cancelHeld();return end
 local alpha=math.clamp((os.clock()-activeCharge.Started)/activeCharge.Time,0,1)
 chargeHUD.Visible=not menuOpen()
 chargeHUD.Text=(if alpha>=1 then "ĐẦY LỰC" else "TỤ LỰC "..math.floor(alpha*100).."%").." · "..math.floor(Bow.range(alpha)).." studs · Nhả để bắn"
 chargeHUD.TextColor3=C.Stamina
end)
refresh=function()
	local inTraining = player:GetAttribute("InTraining")
 local inHunting = player:GetAttribute("InHunting")==true
	local centeredNotice=inHunting or compactHUD
	notice.AnchorPoint=Vector2.new(if centeredNotice then .5 else 1,1)
	notice.Position=UDim2.new(if centeredNotice then .5 else 1,if centeredNotice then 0 else -20,1,if compactHUD then -12 elseif inHunting then -86 else -222)
	
	local id=player:GetAttribute("WeaponId") or "Hammer"; local weapon=Weapons[id]
	local chain=player:GetAttribute("ComboChain") or ""
	comboHUD.Visible=not compactHUD and (inTraining==true or inHunting) and player:GetAttribute("Drawn")==true and not menuOpen() and player:GetAttribute("ShowComboGuide")~=false
	local nextKeys={}
	for _,combo in weapon.Combos do
		if #chain>0 and combo.Input:sub(1,#chain)==chain then
			table.insert(nextKeys,recipe(combo.Input:sub(#chain+1)))
		end
	end
	comboHUD.Size=UDim2.fromOffset(if inHunting then 420 else 360,if inHunting then 52 else 164)
	comboHUD.Text=if inHunting then "COMBO · "..weapon.Name.."\n"..(if #chain>0 then recipe(chain).."  →  "..table.concat(nextKeys," / ") else "Trái · Q · E  |  Xem chuỗi trong Túi đồ")
		else "COMBO • "..weapon.Name.."\n"..recipes(weapon)
		.."\n"..(if #chain>0 then "Đã nối: "..recipe(chain).." | Tiếp: "..table.concat(nextKeys," / ") else "Nối sau mỗi đòn, trong 1,35 giây")
	
	title.Text = "HUNDINO • " .. (if inHunting then "THUNG LŨNG SƯƠNG XÁM" elseif inTraining then "BÃI LUYỆN TẬP" else "TRẠI THỢ SĂN")
		.. "\nBase " .. tostring(player:GetAttribute("BaseId") or "…") .. " / 12"
	if compactHUD then title.Text="HUNDINO · "..(if inHunting then "KHU SĂN" elseif inTraining then "BÃI TẬP" else "TRẠI THỢ SĂN").."\nBase "..tostring(player:GetAttribute("BaseId") or "…").." / 12" end
	stats.Visible=true
 local value = player:GetAttribute("Stamina") or Config.MaxStamina
	bar.Size = UDim2.fromScale(value / Config.MaxStamina, 1); staminaText.Text = "THỂ LỰC " .. value .. " / " .. Config.MaxStamina
	stats.Text = weapon.Name..(if player:GetAttribute("Drawn") then " • Đã rút" else " • Đang cất")
		.. " • " .. (if player:GetAttribute("TrainingArmor") then "Giáp tập" else "Chưa mặc giáp")
		.. "\nBạn: " .. (player:GetAttribute("TrainingDamage") or 0) .. "  |  Pet: " .. (player:GetAttribute("PetDamage") or 0)
	if inHunting then stats.Text=weapon.Name..(if player:GetAttribute("Drawn") then " • Đã rút" else " • Đang cất")
		.."\nSát thương săn: "..(player:GetAttribute("HuntingDamage") or 0) end
	help.Text="R: Rút / cất • 1-7: Chọn đồ • B: Đổi tư thế • K: Đổi chỗ katana • I: Túi đồ\nChuột trái: Đánh thường • Q: Đánh mạnh\nE: "..weapon.Skill.."\nV: Nhảy • Space: Lướt\nShift: Chạy • Ctrl: Ghim tâm • G: Tương tác"
		..(if id=="Bow" then "\nTay trái: Cầm cung • Tay phải: Kéo dây\nChuột trái: Chạm bắn nhanh / giữ tụ lực • Phải: Ngắm thủ công\nTự ngắm (Cài đặt): "..(if player:GetAttribute("AutoBowAim")==true then "BẬT" else "TẮT")..(if player:GetAttribute("BowBoost") then " • MŨI TÊN CƯỜNG HÓA" else "") elseif id=="SwordShield" then "\nF: Giữ thế đỡ" else "")
	if inHunting then help.Text..="\nKhủng long sẽ phản công khi bị đánh." end
	help.Visible=not compactHUD and not inHunting and not menuOpen()
	if player:GetAttribute("AdminFlying")==true then help.Text="ADMIN • BAY XEM MAP\nWASD: Di chuyển • Space / E: Lên\nCtrl / Q: Xuống • Shift: Bay nhanh\nBấm Dừng bay hoặc chat /fly để đáp xuống." end
end
for _, attr in {"InTraining", "InHunting", "BaseId", "Stamina", "Drawn", "TrainingArmor", "TrainingDamage", "HuntingDamage", "PetDamage", "WeaponId", "Blocking", "BowBoost", "ComboChain", "AdminFlying", "ShowComboGuide", "AutoBowAim", "AutoBowFire", "MeleeStance", "RangedStance", "SwapBowButtons"} do
	player:GetAttributeChangedSignal(attr):Connect(refresh)
end
player:GetAttributeChangedSignal("InHunting"):Connect(function()
 baseTransit:Close(); hub:Close(); panel.Visible=false
 cancelHeld(); inputSerial+=1; aiming=false; locked=false; center.Visible=false
 restoreBowView()
end)
player:GetAttributeChangedSignal("AdminFlying"):Connect(function()
 if player:GetAttribute("AdminFlying")~=true then return end
 baseTransit:Close();hub:Close();panel.Visible=false
 cancelHeld();inputSerial+=1;aiming=false;locked=false;center.Visible=false;restoreBowView()
end)
refreshPreferences=refresh
panel:GetPropertyChangedSignal("Visible"):Connect(refresh)
refresh()
remote.OnClientEvent:Connect(function(event, a, b, c)
	if event == "BaseTransitOpen" then
  cancelHeld();inputSerial+=1;hub:Close();panel.Visible=false;aiming=false;locked=false
  baseTransit:Open(a)
 elseif event == "Message" then announce(a)
	elseif event == "Jump" and player.Character == a then
		local hum = a:FindFirstChildOfClass("Humanoid")
		local root = a:FindFirstChild("HumanoidRootPart")
		if hum and root and hum.Health > 0 and not hum.Sit and not root.Anchored
			and hum.FloorMaterial ~= Enum.Material.Air then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	elseif event=="ChargeStart" then
  if activeCharge and activeCharge.Id==b then activeCharge.Time=a;readyAt=math.huge end
 elseif event=="ChargeStop" then activeCharge=nil;chargeHUD.Visible=false;readyAt=os.clock()
 elseif event=="ChargeRejected" then
  if activeCharge and activeCharge.Id==a then activeCharge=nil;chargeHUD.Visible=false;readyAt=os.clock() end
 elseif event == "Dodge" then
		readyAt=os.clock()+a
	elseif event == "Attack" then
		readyAt=os.clock()+(c or 0)
		if b then announce("COMBO • "..b) end
	elseif event == "ComboFX" then
		if player:GetAttribute("ShowComboFX")==false then return end
		-- Short local trails make the finisher readable without adding collision.
		local color=if b=="Slam" then Color3.fromRGB(255,191,89) else Color3.fromRGB(113,235,214)
		local count=if b=="Thrust" then 1 else 8
		for i=1,count do
			local effect=Instance.new("Part"); effect.Name="ComboTrail"; effect.Anchored=true
			effect.CanCollide=false; effect.CanQuery=false; effect.CanTouch=false; effect.Material=Enum.Material.Neon
			effect.Color=color; effect.Transparency=.25
			if count==1 then effect.Size=Vector3.new(.14,.14,c); effect.CFrame=a*CFrame.new(0,0,-c/2)
			else
				local full=b=="Spin" or b=="Slam"
				local angle=if full then i*math.pi/4 else -math.pi/2+(i-1)*math.pi/7
				effect.Size=Vector3.new(c*.45,.12,.16)
				effect.CFrame=a*CFrame.Angles(0,angle,0)*CFrame.new(0,if b=="Slam" then -2 else 0,-c*.7)
			end
			effect.Parent=workspace
			TweenService:Create(effect,TweenInfo.new(.22),{Transparency=1}):Play(); Debris:AddItem(effect,.24)
		end
	elseif event == "Shot" then
		local distance=(b-a).Magnitude; if distance<.01 then return end
		local arrow=Instance.new("Part"); arrow.Name="TrainingArrow"; arrow.Anchored=true; arrow.CanCollide=false; arrow.CanQuery=false; arrow.CanTouch=false
		arrow.Size=Vector3.new(.1,.1,2.6); arrow.Material=Enum.Material.Neon; arrow.Color=if c then Color3.fromRGB(255,208,91) else Color3.fromRGB(115,255,140)
		arrow.CFrame=CFrame.lookAt(a,b); arrow.Parent=workspace
		local flight=math.clamp(distance/260,.06,.8)
		TweenService:Create(arrow,TweenInfo.new(flight,Enum.EasingStyle.Linear),{CFrame=CFrame.lookAt(b,b+(b-a))}):Play(); Debris:AddItem(arrow,flight+.12)
	elseif event == "Hit" then
		if player:GetAttribute("ShowDamage")==false then return end
		local anchor = Instance.new("Part"); anchor.Size = Vector3.one; anchor.CFrame = CFrame.new(a + Vector3.new(0, 2, 0))
		anchor.Transparency = 1; anchor.Anchored = true; anchor.CanCollide = false; anchor.CanQuery = false; anchor.Parent = workspace
		local billboard = Instance.new("BillboardGui"); billboard.Size = UDim2.fromOffset(120, 50); billboard.AlwaysOnTop = true; billboard.Parent = anchor
		local number = Instance.new("TextLabel"); number.Size = UDim2.fromScale(1, 1); number.BackgroundTransparency = 1
		number.Font = Enum.Font.GothamBlack; number.TextSize = 28
		number.TextColor3 = if c then Color3.fromRGB(88, 230, 172) else Color3.fromRGB(255, 211, 104)
		number.Text = (if c then "Pet " else "") .. b; number.Parent = billboard
		TweenService:Create(anchor, TweenInfo.new(0.8), {Position = anchor.Position + Vector3.new(0, 3, 0)}):Play()
		TweenService:Create(number, TweenInfo.new(0.8), {TextTransparency = 1}):Play(); Debris:AddItem(anchor, 0.85)
	end
end)
