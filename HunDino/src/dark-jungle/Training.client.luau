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
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local gui = Instance.new("ScreenGui"); gui.Name = "HunDinoTrainingHUD"; gui.ResetOnSpawn = false; gui.Parent = player:WaitForChild("PlayerGui")
local function text(name, pos, size, value, textSize)
	local t = Instance.new("TextLabel"); t.Name = name; t.Position = pos; t.Size = size
	t.BackgroundColor3 = Color3.fromRGB(16, 31, 30); t.BackgroundTransparency = 0.12
	t.TextColor3 = Color3.fromRGB(240, 230, 203); t.Font = Enum.Font.GothamMedium
	t.TextSize = textSize or 16; t.TextWrapped = true; t.Text = value; t.Parent = gui
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = t
	return t
end
local title = text("Title", UDim2.fromOffset(20, 14), UDim2.fromOffset(330, 55), "HUNDINO • TRẠI THỢ SĂN", 19)
local stats = text("Stats", UDim2.new(0, 20, 1, -136), UDim2.fromOffset(330, 64), "", 16)
local staminaBG = text("Stamina", UDim2.new(0, 20, 1, -60), UDim2.fromOffset(330, 26), "", 14)
local bar = Instance.new("Frame"); bar.BorderSizePixel = 0; bar.BackgroundColor3 = Color3.fromRGB(70, 195, 147)
bar.Size = UDim2.fromScale(1, 1); bar.Parent = staminaBG
local staminaText = Instance.new("TextLabel"); staminaText.Size = UDim2.fromScale(1, 1); staminaText.BackgroundTransparency = 1
staminaText.TextColor3 = Color3.fromRGB(14, 29, 26); staminaText.Font = Enum.Font.GothamBold; staminaText.TextSize = 14; staminaText.Parent = staminaBG
local help = text("Help", UDim2.new(1, -375, 1, -209), UDim2.fromOffset(355, 190), "", 15)
local notice = text("Notice", UDim2.new(0.5, -245, 0, 18), UDim2.fromOffset(490, 48), "Đến cổng tại sân đón, giữ G để vào bãi tập.", 17)
local center = text("Crosshair", UDim2.new(0.5, -10, 0.5, -10), UDim2.fromOffset(20, 20), "+", 21)
center.BackgroundTransparency = 1; center.Visible = false
-- Match Camera.ViewportPointToRay, rather than the HUD's top-bar safe inset.
local reticleGui=Instance.new("ScreenGui"); reticleGui.Name="HunDinoReticle"; reticleGui.IgnoreGuiInset=true
reticleGui.ResetOnSpawn=false; reticleGui.Parent=player.PlayerGui; center.Parent=reticleGui
center.TextColor3=Color3.fromRGB(241,255,250); center.TextStrokeTransparency=.25
local locked, aiming, lastDirection = false, false, Vector3.new(0, 0, -1)
local appliedMouseLock = false
local bowView, bowBlend = nil, 0
local function setZoom(distance)
	player.CameraMaxZoomDistance=math.max(player.CameraMinZoomDistance,distance)
	player.CameraMinZoomDistance=distance; player.CameraMaxZoomDistance=distance
end
local function restoreBowView()
	if not bowView then return end
	if bowView.Humanoid.Parent then
		bowView.Humanoid.CameraOffset=bowView.Offset; bowView.Humanoid.AutoRotate=bowView.AutoRotate
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
local panel = Instance.new("Frame"); panel.Name="WeaponSelection"; panel.AnchorPoint=Vector2.new(.5,.5)
panel.Position=UDim2.fromScale(.5,.5); panel.Size=UDim2.fromOffset(650,656)
panel.BackgroundColor3=Color3.fromRGB(17,34,32); panel.Visible=false; panel.Parent=gui
local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,12); corner.Parent=panel
local scale=Instance.new("UIScale"); scale.Parent=panel
local function resizePanel() local size=workspace.CurrentCamera.ViewportSize; scale.Scale=math.min(1,(size.X-32)/650,(size.Y-60)/656) end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resizePanel); resizePanel()
local function panelText(value,pos,size,textSize)
	local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Text=value; t.TextWrapped=true
	t.TextColor3=Color3.fromRGB(237,229,202); t.Font=Enum.Font.GothamMedium; t.TextSize=textSize; t.Position=pos; t.Size=size; t.Parent=panel; return t
end
panelText("KHO VŨ KHÍ LUYỆN TẬP",UDim2.fromOffset(20,16),UDim2.fromOffset(570,35),23)
panelText("Chọn một vũ khí • Nhấn R để rút sau khi trang bị",UDim2.fromOffset(20,54),UDim2.fromOffset(610,30),15)
local close=Instance.new("TextButton"); close.Name="Close"; close.Text="×"; close.TextSize=25; close.Font=Enum.Font.GothamMedium
close.Size=UDim2.fromOffset(40,38); close.Position=UDim2.new(1,-48,0,12); close.BackgroundTransparency=1; close.TextColor3=Color3.fromRGB(236,224,192); close.Parent=panel
close.Activated:Connect(function() panel.Visible=false end)
local function recipe(input)
 local key={L="Trái",H="Q",S="E"}; local parts={}
 for letter in input:gmatch(".") do table.insert(parts,key[letter]) end
 return table.concat(parts," → ")
end
local function recipes(weapon)
 local lines={}
 for _,combo in weapon.Combos do table.insert(lines,weapon.Attacks[combo.Attack].Name..": "..recipe(combo.Input)) end
 return table.concat(lines,"\n")
end
local comboHUD=text("ComboGuide",UDim2.new(0,20,.5,-90),UDim2.fromOffset(330,168),"",14)
comboHUD.Visible=false
local buttons={}
for i,id in Weapons.Order do
	local w=Weapons[id]; local button=Instance.new("TextButton"); button.Name=id; button.Text=""
	button.Size=UDim2.fromOffset(298,120); button.Position=UDim2.fromOffset(20+((i-1)%2)*312,100+math.floor((i-1)/2)*130)
	button.BackgroundColor3=Color3.fromRGB(35,58,53); button.AutoButtonColor=true; button.Parent=panel
	local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,7); c.Parent=button
	local title=Instance.new("TextLabel"); title.Name="Name"; title.BackgroundTransparency=1; title.Size=UDim2.new(1,-20,0,28); title.Position=UDim2.fromOffset(10,7)
	title.Font=Enum.Font.GothamBold; title.TextSize=18; title.TextColor3=Color3.fromRGB(239,228,195); title.Text=w.Name; title.Parent=button
	local desc=Instance.new("TextLabel"); desc.BackgroundTransparency=1; desc.Size=UDim2.new(1,-20,0,77); desc.Position=UDim2.fromOffset(10,37)
	desc.Font=Enum.Font.GothamMedium; desc.TextSize=12; desc.TextWrapped=true; desc.TextColor3=Color3.fromRGB(178,205,190); desc.Text=recipes(w); desc.Parent=button
	button.Activated:Connect(function() remote:FireServer("EquipWeapon",id); panel.Visible=false end)
	buttons[id]=button
end
panelText("Trái = chuột trái • Nối sau mỗi đòn, trong 1,35 giây\nI: đóng túi • G: chọn tại giá • Tiêu hao thể lực còn 30%",UDim2.fromOffset(20,616),UDim2.fromOffset(610,34),13)
local openButton=Instance.new("TextButton"); openButton.Name="OpenWeapons"; openButton.Text="I  •  CHỌN VŨ KHÍ"
openButton.Font=Enum.Font.GothamBold; openButton.TextSize=14; openButton.TextColor3=Color3.fromRGB(236,224,189)
openButton.BackgroundColor3=Color3.fromRGB(32,64,53); openButton.Position=UDim2.new(1,-240,0,85); openButton.Size=UDim2.fromOffset(220,38); openButton.Parent=gui
local function toggleMenu()
	if panel.Visible then panel.Visible=false; return end
	if not player:GetAttribute("InTraining") then announce("Vào bãi luyện tập để chọn vũ khí."); return end
	if player:GetAttribute("Drawn") then announce("Nhấn R cất vũ khí trước khi mở túi."); return end
	panel.Visible=true; aiming=false; locked=false; remote:FireServer("Sprint",false); remote:FireServer("Aim",false); remote:FireServer("Guard",false)
end
openButton.Activated:Connect(toggleMenu)
local function aimDirection(ranged, dodge)
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local dir = lastDirection
	if ranged and root then
		local camera=workspace.CurrentCamera; local size=camera.ViewportSize
		local ray=camera:ViewportPointToRay(size.X/2,size.Y/2)
		local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances={character,workspace:FindFirstChild("TrainingPets")}
		local result=workspace:Raycast(ray.Origin,ray.Direction*250,params)
		local target=if result then result.Position else ray.Origin+ray.Direction*250
		local vector=target-(root.Position+Vector3.new(0,.8,0))
		return if vector.Magnitude>.01 then vector.Unit else camera.CFrame.LookVector
	end
	if (locked or aiming) and not dodge then dir = workspace.CurrentCamera.CFrame.LookVector
	elseif hum and hum.MoveDirection.Magnitude > 0.1 then dir = hum.MoveDirection
	elseif root then dir = lastDirection end
	dir = Vector3.new(dir.X, 0, dir.Z)
	return if dir.Magnitude > 0.01 then dir.Unit else Vector3.new(0, 0, -1)
end
local function send(action)
	remote:FireServer(action, aimDirection(player:GetAttribute("WeaponId")=="Bow" and (action=="Light" or action=="Heavy" or action=="Skill"),action=="Dodge"))
end
-- Consume Space before Roblox's default jump binding. The server arbitrates
-- jump/dodge together, so simultaneous keys cannot combine their impulses.
local function movementAction(actionName, inputState)
	if inputState == Enum.UserInputState.Begin and not panel.Visible and not UIS:GetFocusedTextBox() and not GuiService.MenuIsOpen then
		if actionName == "HunDinoJump" then send("Jump") else send("Dodge") end
	end
	return Enum.ContextActionResult.Sink
end
ContextActionService:BindActionAtPriority("HunDinoJump", movementAction, false, 3001, Enum.KeyCode.V)
ContextActionService:BindActionAtPriority("HunDinoDodge", movementAction, false, 3001, Enum.KeyCode.Space)
-- I also zooms Roblox's default camera; consume it when opening the armory.
ContextActionService:BindActionAtPriority("HunDinoArmory", function(_, inputState)
	if inputState == Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() and not GuiService.MenuIsOpen then toggleMenu() end
	return Enum.ContextActionResult.Sink
end, false, 3001, Enum.KeyCode.I)
script.Destroying:Connect(function()
	restoreBowView(); reticleGui:Destroy()
	if appliedMouseLock then UIS.MouseBehavior=Enum.MouseBehavior.Default end
	ContextActionService:UnbindAction("HunDinoJump")
	ContextActionService:UnbindAction("HunDinoDodge")
	ContextActionService:UnbindAction("HunDinoArmory")
	RunService:UnbindFromRenderStep("HunDinoTrainingCamera")
	RunService:UnbindFromRenderStep("HunDinoBowView")
end)
UIS.InputBegan:Connect(function(input, processed)
	if processed or UIS:GetFocusedTextBox() then return end
	if panel.Visible or GuiService.MenuIsOpen then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then send("Light")
	elseif input.UserInputType==Enum.UserInputType.MouseButton2 and player:GetAttribute("WeaponId")=="Bow" and player:GetAttribute("Drawn") then aiming=true; remote:FireServer("Aim",true)
	elseif input.KeyCode==Enum.KeyCode.F then remote:FireServer("Guard",true)
	elseif input.KeyCode == Enum.KeyCode.Q then send("Heavy")
	elseif input.KeyCode == Enum.KeyCode.E then send("Skill")
	elseif input.KeyCode == Enum.KeyCode.R then
		aiming=false; remote:FireServer("Aim",false); remote:FireServer("Draw")
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		aiming=false; remote:FireServer("Aim",false); remote:FireServer("Sprint", true)
	elseif input.KeyCode == Enum.KeyCode.LeftControl then locked = not locked; center.Visible = locked end
end)
UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then remote:FireServer("Sprint", false) end
	if input.KeyCode==Enum.KeyCode.F then remote:FireServer("Guard",false) end
	if input.UserInputType==Enum.UserInputType.MouseButton2 then aiming=false; remote:FireServer("Aim",false) end
end)
UIS.WindowFocusReleased:Connect(function()
	remote:FireServer("Sprint", false); locked = false; center.Visible = false
	aiming=false; remote:FireServer("Aim",false); remote:FireServer("Guard",false)
end)
local function characterAdded(character)
	restoreBowView()
	local hum = character:WaitForChild("Humanoid")
	-- Use the normal jump state/animation; Space is consumed by the binding above.
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	hum.AutoJumpEnabled = false
	hum.UseJumpPower = true; hum.JumpPower = 50
	lastDirection = Vector3.new(0, 0, -1); locked = false; aiming=false; panel.Visible=false; center.Visible = false
end
player.CharacterAdded:Connect(characterAdded)
if player.Character then task.spawn(characterAdded, player.Character) end
-- Feed the shoulder offset/zoom to Roblox's camera before its collision solver.
-- Keeping CameraType.Custom retains normal mouse orbit and wall occlusion.
RunService:BindToRenderStep("HunDinoBowView", Enum.RenderPriority.Camera.Value-1, function(dt)
	local character=player.Character; local hum=character and character:FindFirstChildOfClass("Humanoid")
	local camera=workspace.CurrentCamera
	local want=aiming and hum and hum.Health>0 and player:GetAttribute("WeaponId")=="Bow"
		and player:GetAttribute("Drawn") and not panel.Visible and not GuiService.MenuIsOpen and not UIS:GetFocusedTextBox()
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
	UIS.MouseDeltaSensitivity=bowView.Sensitivity*(1-.35*bowBlend)
	UIS.MouseIconEnabled=if want then false else bowView.MouseIcon
	if not want and bowBlend<.001 then setZoom(bowView.Distance); restoreBowView() end
end)
RunService:BindToRenderStep("HunDinoTrainingCamera", Enum.RenderPriority.Camera.Value + 1, function()
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if hum and hum.MoveDirection.Magnitude > 0.1 then lastDirection = hum.MoveDirection.Unit end
	if not player:GetAttribute("Drawn") or GuiService.MenuIsOpen or panel.Visible or not hum or hum.Health<=0 then
		if aiming then remote:FireServer("Aim",false) end
		aiming=false
	end
	if aiming and bowView and character.PrimaryPart then
		local root=character.PrimaryPart; local look=workspace.CurrentCamera.CFrame.LookVector
		local flat=Vector3.new(look.X,0,look.Z)
		if flat.Magnitude>.01 then hum.AutoRotate=false; root.CFrame=CFrame.lookAt(root.Position,root.Position+flat) end
	end
	local canControl=hum and hum.Health>0 and not GuiService.MenuIsOpen and not UIS:GetFocusedTextBox()
	center.Visible=canControl and not panel.Visible and (locked or (player:GetAttribute("WeaponId")=="Bow" and player:GetAttribute("Drawn"))) or false
	if canControl and (locked or aiming) and not panel.Visible then
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter; appliedMouseLock = true
	elseif appliedMouseLock then
		UIS.MouseBehavior = Enum.MouseBehavior.Default; appliedMouseLock = false
	end
end)
local function refresh()
	local inTraining = player:GetAttribute("InTraining")
	openButton.Visible=inTraining==true
	if not inTraining then panel.Visible=false end
	local id=player:GetAttribute("WeaponId") or "Hammer"; local weapon=Weapons[id]
	local chain=player:GetAttribute("ComboChain") or ""
	comboHUD.Visible=inTraining==true and player:GetAttribute("Drawn")==true and not panel.Visible
	local nextKeys={}
	for _,combo in weapon.Combos do
		if #chain>0 and combo.Input:sub(1,#chain)==chain then
			table.insert(nextKeys,recipe(combo.Input:sub(#chain+1)))
		end
	end
	comboHUD.Text="COMBO • "..weapon.Name.."\n"..recipes(weapon)
		.."\n"..(if #chain>0 then "Đã nối: "..recipe(chain).." | Tiếp: "..table.concat(nextKeys," / ") else "Nối sau mỗi đòn, trong 1,35 giây")
	for key,button in buttons do button.BackgroundColor3=if key==id then Color3.fromRGB(56,100,78) else Color3.fromRGB(35,58,53) end
	title.Text = "HUNDINO • " .. (if inTraining then "BÃI LUYỆN TẬP" else "TRẠI THỢ SĂN")
		.. "\nBase " .. tostring(player:GetAttribute("BaseId") or "…") .. " / 12"
	local value = player:GetAttribute("Stamina") or Config.MaxStamina
	bar.Size = UDim2.fromScale(value / Config.MaxStamina, 1); staminaText.Text = "THỂ LỰC " .. value .. " / " .. Config.MaxStamina
	stats.Text = weapon.Name..(if player:GetAttribute("Drawn") then " • Đã rút" else " • Đang cất")
		.. " • " .. (if player:GetAttribute("TrainingArmor") then "Giáp tập" else "Chưa mặc giáp")
		.. "\nBạn: " .. (player:GetAttribute("TrainingDamage") or 0) .. "  |  Pet: " .. (player:GetAttribute("PetDamage") or 0)
	help.Text="R: Rút / cất • I: Chọn vũ khí\nChuột trái: Đánh thường • Q: Đánh mạnh\nE: "..weapon.Skill.."\nV: Nhảy • Space: Lướt\nShift: Chạy • Ctrl: Ghim tâm • G: Tương tác"
		..(if id=="Bow" then "\nGiữ chuột phải: Ngắm"..(if player:GetAttribute("BowBoost") then " • MŨI TÊN CƯỜNG HÓA" else "") elseif id=="SwordShield" then "\nF: Giữ thế đỡ" else "")
end
for _, attr in {"InTraining", "BaseId", "Stamina", "Drawn", "TrainingArmor", "TrainingDamage", "PetDamage", "WeaponId", "Blocking", "BowBoost", "ComboChain"} do
	player:GetAttributeChangedSignal(attr):Connect(refresh)
end
refresh()
remote.OnClientEvent:Connect(function(event, a, b, c)
	if event == "Message" then announce(a)
	elseif event == "Jump" and player.Character == a then
		local hum = a:FindFirstChildOfClass("Humanoid")
		local root = a:FindFirstChild("HumanoidRootPart")
		if hum and root and hum.Health > 0 and not hum.Sit and not root.Anchored
			and hum.FloorMaterial ~= Enum.Material.Air then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	elseif event == "Attack" then
		if b then announce("COMBO • "..b) end
	elseif event == "ComboFX" then
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
		arrow.Size=Vector3.new(.1,.1,2.6); arrow.Material=Enum.Material.Neon; arrow.Color=if c then Color3.fromRGB(255,208,91) else Color3.fromRGB(129,222,201)
		arrow.CFrame=CFrame.lookAt(a,b); arrow.Parent=workspace
		local flight=math.clamp(distance/260,.06,.8)
		TweenService:Create(arrow,TweenInfo.new(flight,Enum.EasingStyle.Linear),{CFrame=CFrame.lookAt(b,b+(b-a))}):Play(); Debris:AddItem(arrow,flight+.12)
	elseif event == "Hit" then
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
