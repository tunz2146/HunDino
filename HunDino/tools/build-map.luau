-- Build một file mới từ bản sao HunDino1; không ghi vào map nguồn.
local fs = require("@lune/fs")
local r = require("@lune/roblox")
local process = require("@lune/process")
assert(not fs.isFile("HunDino_L0.rbxlx") or table.find(process.args, "--rebuild"),
	"L0 đã tồn tại. Lưu sửa map thủ công sang file riêng trước; thêm --rebuild nếu muốn dựng lại từ nguồn.")
local I, V, C, Col, E = r.Instance, r.Vector3, r.CFrame, r.Color3, r.Enum
local game = r.deserializePlace(fs.readFile("HunDino_original.rbxl"))
local world = game:GetService("Workspace")
assert(not world:FindFirstChild("HunDinoL0"), "Chọn map nguồn chưa chứa L0")
local forestMap = assert(world:FindFirstChild("ForestMap"))
assert(#forestMap.Bases:GetChildren() == 12, "Map nguồn phải có đủ 12 base")
local root = I.new("Folder"); root.Name = "HunDinoL0"; root.Parent = world
local function folder(name, parent)
	local f = I.new("Folder"); f.Name = name; f.Parent = parent or root; return f
end
local function part(parent, name, pos, size, color, material)
	local p = I.new("Part")
	p.Name = name; p.Anchored = true; p.Size = size; p.CFrame = C.new(pos)
	p.Color = color; p.Material = material or E.Material.WoodPlanks
	p.TopSurface = E.SurfaceType.Smooth; p.BottomSurface = E.SurfaceType.Smooth
	p.Parent = parent; return p
end
local wood = Col.fromRGB(87, 60, 42)
local stone = Col.fromRGB(83, 100, 99)
local teal = Col.fromRGB(70, 204, 177)
local gold = Col.fromRGB(229, 173, 78)
local function label(p, text, height)
	local gui = I.new("BillboardGui")
	gui.Name = "SignGui"; gui.Size = r.UDim2.fromOffset(280, height or 65)
	gui.StudsOffset = V.new(0, p.Size.Y / 2 + 2, 0); gui.MaxDistance = 110
	gui.AlwaysOnTop = false; gui.Parent = p
	local t = I.new("TextLabel"); t.Name = "Text"; t.Size = r.UDim2.fromScale(1, 1)
	t.BackgroundColor3 = Col.fromRGB(17, 34, 33); t.BackgroundTransparency = 0.15
	t.Text = text; t.TextColor3 = Col.fromRGB(243, 233, 208); t.TextSize = 20
	t.Font = E.Font.GothamBold; t.TextWrapped = true; t.Parent = gui
end
local function prompt(p, name, action, object)
	local v = I.new("ProximityPrompt"); v.Name = name; v.ActionText = action; v.ObjectText = object
	v.KeyboardKeyCode = E.KeyCode.G; v.HoldDuration = 0.25; v.MaxActivationDistance = 10
	v.RequiresLineOfSight = true; v.Parent = p
end
local function lamp(parent, pos)
	part(parent, "LampPost", pos + V.new(0, 3, 0), V.new(0.6, 6, 0.6), wood)
	local top = part(parent, "Lantern", pos + V.new(0, 6.3, 0), V.new(1.3, 1.4, 1.3), gold, E.Material.Neon)
	top.CanCollide = false
	local light = I.new("PointLight"); light.Color = gold; light.Range = 20; light.Brightness = 1.2; light.Parent = top
end
-- Dời cây/đá nằm trong sân đón ra mép rừng, giữ mọi đối tượng của map gốc.
local relocated = 0
for _, item in forestMap.Forest:GetChildren() do
	local pieces = if item:IsA("BasePart") then {item} else item:GetDescendants()
	local overlaps = false
	for _, p in pieces do
		if p:IsA("BasePart") then
			local pos = p.CFrame.Position
			if math.abs(pos.X) - p.Size.X / 2 < 25 and math.abs(pos.Z) - p.Size.Z / 2 < 23 then overlaps = true; break end
		end
	end
	if overlaps then
		relocated += 1
		for _, p in pieces do
			if p:IsA("BasePart") then p.CFrame += V.new(115, 0, 0) end
		end
	end
end
local hub = folder("Lobby")
part(hub, "WelcomeDeck", V.new(0, 0.9, 0), V.new(44, 0.6, 44), stone, E.Material.Slate)
for _, x in {-21, 21} do
	part(hub, "DeckBorder", V.new(x, 1.25, 0), V.new(0.4, 0.2, 44), gold, E.Material.Metal)
	lamp(hub, V.new(x, 1.2, 19))
end
-- Điểm mốc hình xương/răng trong trại; để trống đường giữa.
for _, x in {-17, 17} do
	local tooth = part(hub, "FossilTooth", V.new(x, 5, -17), V.new(2, 8, 2), Col.fromRGB(217, 204, 166), E.Material.Limestone)
	tooth.CFrame *= C.Angles(0, 0, math.rad(-x))
end
local welcome = part(hub, "Welcome", V.new(-15, 4, 4), V.new(1, 5, 1), wood)
label(welcome, "HUNDINO\nTRẠI THỢ SĂN • 12 BASE", 75)
local spawn = I.new("SpawnLocation"); spawn.Name = "LobbySpawn"; spawn.Size = V.new(7, 0.3, 7)
spawn.CFrame = C.new(0, 1.2, 13); spawn.Anchored = true; spawn.Neutral = true
spawn.Transparency = 1; spawn.CanCollide = false; spawn.Duration = 0; spawn.Parent = hub
for _, p in forestMap:GetDescendants() do if p:IsA("SpawnLocation") then p.Enabled = false end end
local baseSigns = folder("BaseSigns")
for i = 1, 12 do
	local base = forestMap.Bases:FindFirstChild("Base" .. i)
	local center = base.Ground.CFrame.Position
	local side = if center.X < 0 then 1 else -1
	local marker = part(baseSigns, "Base" .. i, center + V.new(side * 29, 4, 18), V.new(1, 5, 1), wood)
	label(marker, string.format("BASE %02d\nChưa có chủ", i))
	marker:SetAttribute("BaseId", i)
end
local function gate(parent, center, name, title, action)
	for _, dx in {-7, 7} do
		part(parent, "GatePillar", center + V.new(dx, 6, 0), V.new(2, 12, 3), stone, E.Material.Slate)
		part(parent, "GateLight", center + V.new(dx, 6, -1.6), V.new(0.3, 9, 0.2), teal, E.Material.Neon).CanCollide = false
	end
	part(parent, "GateLintel", center + V.new(0, 13, 0), V.new(18, 2, 4), wood)
	local anchor = part(parent, name, center + V.new(0, 3, 0), V.new(12, 6, 1), teal, E.Material.ForceField)
	anchor.Transparency = 0.8; anchor.CanCollide = false
	label(anchor, title); prompt(anchor, name .. "Prompt", action, title)
	return anchor
end
gate(hub, V.new(0, 1.2, -17), "ToTraining", "BÃI LUYỆN TẬP", "Vào bãi tập")
local training = folder("Training")
part(training, "Ground", V.new(480, 0, 0), V.new(150, 2, 142), Col.fromRGB(91, 110, 87), E.Material.Grass)
part(training, "Arena", V.new(480, 1.1, -8), V.new(115, 0.3, 74), Col.fromRGB(170, 151, 113), E.Material.Sand)
part(training, "EntryPath", V.new(480, 1.15, 44), V.new(16, 0.35, 48), stone, E.Material.Cobblestone)
-- Viền gỗ có khoảng mở; vách xa giữ người chơi trong khu tập.
for _, x in {407, 553} do
	part(training, "Boundary", V.new(x, 4, 0), V.new(3, 8, 142), stone, E.Material.Slate)
end
for _, z in {-69, 69} do part(training, "Boundary", V.new(480, 4, z), V.new(148, 8, 3), stone, E.Material.Slate) end
for _, x in {423, 537} do for _, z in {-43, 27, 60} do lamp(training, V.new(x, 1, z)) end end
gate(training, V.new(480, 1.1, 56), "ToLobby", "TRỞ VỀ TRẠI", "Về sảnh")
local arrival = part(training, "Arrival", V.new(480, 4, 43), V.new(1, 1, 1), teal)
arrival.Transparency = 1; arrival.CanCollide = false; arrival.CanQuery = false
local rack = part(training, "EquipmentRack", V.new(452, 4, 36), V.new(12, 5, 2), wood)
label(rack, "TRANG BỊ CƠ BẢN\nBúa • Giáp tập", 75)
prompt(rack, "ArmorPrompt", "Mặc / tháo giáp mẫu", "Giá trang bị")
local reset = part(training, "ResetPost", V.new(508, 3, 36), V.new(2, 4, 2), stone)
label(reset, "BẮT ĐẦU LƯỢT TẬP MỚI", 55)
prompt(reset, "ResetPrompt", "Xóa thống kê của tôi", "Bảng luyện tập")
local dummies = folder("Dummies", training)
for i, x in {447, 480, 513} do
	local model = I.new("Model"); model.Name = "Dummy" .. i; model.Parent = dummies
	local pos = V.new(x, 1.4, -17)
	part(model, "Stand", pos, V.new(8, 0.6, 8), wood)
	local body = part(model, "Target", pos + V.new(0, 4.2, 0), V.new(3.5, 4, 2), Col.fromRGB(201, 164, 99), E.Material.Wood)
	part(model, "Head", pos + V.new(0, 7.2, 0), V.new(2.5, 2.3, 2.5), Col.fromRGB(224, 193, 131), E.Material.Wood)
	part(model, "Arms", pos + V.new(0, 5, 0), V.new(8, 0.8, 0.8), wood)
	part(model, "Post", pos + V.new(0, 1.6, 0), V.new(0.8, 3, 0.8), wood)
	local target = part(model, "Bullseye", pos + V.new(0, 4.2, 1.08), V.new(1.8, 1.8, 0.12), teal, E.Material.Neon)
	target.CanCollide = false; model.PrimaryPart = body
	model:SetAttribute("Health", 1000); model:SetAttribute("MaxHealth", 1000)
	label(body, "HÌNH NỘM " .. i .. "\n1000 / 1000")
end
local instructions = part(training, "Instructions", V.new(480, 6, -56), V.new(26, 7, 1), wood)
label(instructions, "R: rút búa • Chuột trái: đánh thường\nQ: đánh mạnh • E: kỹ năng\nThường → Mạnh → Kỹ năng", 100)
local starter = game:GetService("StarterPlayer")
starter.EnableMouseLockOption = false
local shared = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
if not shared then shared = folder("Shared", game:GetService("ReplicatedStorage")) end
local function source(class, name, path, parent)
	local old = parent:FindFirstChild(name); assert(not old, "Tên script trùng: " .. name)
	local s = I.new(class); s.Name = name; s.Source = fs.readFile(path); s.Parent = parent
end
source("ModuleScript", "TrainingConfig", "src/shared/TrainingConfig.luau", shared)
source("ModuleScript", "CombatRules", "src/shared/CombatRules.luau", shared)
source("Script", "HunDinoTraining", "src/server/Training.server.luau", game:GetService("ServerScriptService"))
source("LocalScript", "HunDinoTraining", "src/client/Training.client.luau", starter.StarterPlayerScripts)
local camera = world:FindFirstChildOfClass("Camera")
if camera then camera.CFrame = C.lookAt(V.new(85, 90, 120), V.new(0, 0, 0)); camera.Focus = C.new(0, 0, 0) end
fs.writeFile("HunDino_L0.rbxlx", r.serializePlace(game, true))
print("BUILT HunDino_L0.rbxlx", #game:GetDescendants(), "instances; cây/đá dời ra mép rừng:", relocated)
