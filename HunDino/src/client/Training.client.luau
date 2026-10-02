local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("HunDinoTrainingAction")
local Config = require(ReplicatedStorage.Shared.TrainingConfig)
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
local help = text("Help", UDim2.new(1, -360, 1, -169), UDim2.fromOffset(340, 135), "R: Rút / cất búa\nChuột trái: Đánh thường • Q: Đánh mạnh\nE: Kỹ năng • Space: Lướt thử\nGiữ Shift: Cất búa rồi chạy\nCtrl: Ghim tâm • G: Tương tác", 15)
local notice = text("Notice", UDim2.new(0.5, -245, 0, 18), UDim2.fromOffset(490, 48), "Đến cổng tại sân đón, giữ G để vào bãi tập.", 17)
local center = text("Crosshair", UDim2.new(0.5, -10, 0.5, -10), UDim2.fromOffset(20, 20), "+", 21)
center.BackgroundTransparency = 1; center.Visible = false
local locked, lastDirection = false, Vector3.new(0, 0, -1)
local appliedMouseLock = false
local noticeId = 0
local function announce(message)
	noticeId += 1; local id = noticeId
	notice.Text = message; notice.Visible = true
	task.delay(5, function() if noticeId == id then notice.Visible = false end end)
end
local function aimDirection()
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local dir = lastDirection
	if locked then dir = workspace.CurrentCamera.CFrame.LookVector
	elseif hum and hum.MoveDirection.Magnitude > 0.1 then dir = hum.MoveDirection
	elseif root then dir = lastDirection end
	dir = Vector3.new(dir.X, 0, dir.Z)
	return if dir.Magnitude > 0.01 then dir.Unit else Vector3.new(0, 0, -1)
end
local function send(action)
	remote:FireServer(action, aimDirection())
end
UIS.InputBegan:Connect(function(input, processed)
	if processed or UIS:GetFocusedTextBox() then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then send("Light")
	elseif input.KeyCode == Enum.KeyCode.Q then send("Heavy")
	elseif input.KeyCode == Enum.KeyCode.E then send("Skill")
	elseif input.KeyCode == Enum.KeyCode.R then remote:FireServer("Draw")
	elseif input.KeyCode == Enum.KeyCode.Space then send("Dodge")
	elseif input.KeyCode == Enum.KeyCode.LeftShift then remote:FireServer("Sprint", true)
	elseif input.KeyCode == Enum.KeyCode.LeftControl then locked = not locked; center.Visible = locked end
end)
UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then remote:FireServer("Sprint", false) end
end)
UIS.WindowFocusReleased:Connect(function()
	remote:FireServer("Sprint", false); locked = false; center.Visible = false
end)
local function characterAdded(character)
	local hum = character:WaitForChild("Humanoid")
	-- Space dành cho lướt trong bản thử, tránh vừa nhảy vừa lướt.
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	lastDirection = Vector3.new(0, 0, -1); locked = false; center.Visible = false
end
player.CharacterAdded:Connect(characterAdded)
if player.Character then task.spawn(characterAdded, player.Character) end
RunService:BindToRenderStep("HunDinoTrainingCamera", Enum.RenderPriority.Camera.Value + 1, function()
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if hum and hum.MoveDirection.Magnitude > 0.1 then lastDirection = hum.MoveDirection.Unit end
	if locked and not UIS:GetFocusedTextBox() then
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter; appliedMouseLock = true
	elseif appliedMouseLock then
		UIS.MouseBehavior = Enum.MouseBehavior.Default; appliedMouseLock = false
	end
end)
local function refresh()
	local inTraining = player:GetAttribute("InTraining")
	title.Text = "HUNDINO • " .. (if inTraining then "BÃI LUYỆN TẬP" else "TRẠI THỢ SĂN")
		.. "\nBase " .. tostring(player:GetAttribute("BaseId") or "…") .. " / 12"
	local value = player:GetAttribute("Stamina") or Config.MaxStamina
	bar.Size = UDim2.fromScale(value / Config.MaxStamina, 1); staminaText.Text = "THỂ LỰC " .. value .. " / " .. Config.MaxStamina
	stats.Text = (if player:GetAttribute("Drawn") then "Búa đã rút" else "Búa đang cất")
		.. " • " .. (if player:GetAttribute("TrainingArmor") then "Giáp tập" else "Chưa mặc giáp")
		.. "\nBạn: " .. (player:GetAttribute("TrainingDamage") or 0) .. "  |  Pet: " .. (player:GetAttribute("PetDamage") or 0)
end
for _, attr in {"InTraining", "BaseId", "Stamina", "Drawn", "TrainingArmor", "TrainingDamage", "PetDamage"} do
	player:GetAttributeChangedSignal(attr):Connect(refresh)
end
refresh()
remote.OnClientEvent:Connect(function(event, a, b, c)
	if event == "Message" then announce(a)
	elseif event == "Attack" then
		if a == "Finisher" then announce("COMBO BÚA • ĐÒN KẾT THÚC!") end
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
