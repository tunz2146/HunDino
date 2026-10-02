local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local config = require("../src/shared/TrainingConfig")
local rules = require("../src/shared/CombatRules")
local passed = 0
local function test(name, callback)
	callback(); passed += 1; print("PASS", name)
end
local function fresh()
	return {Drawn = true, BusyUntil = 0, Sprinting = false, Stamina = 100,
		ComboStep = 0, ComboUntil = 0, LastSpend = 0}
end
test("Compile all authored Luau source", function()
	local function walk(path)
		for _, file in fs.readDir(path) do
			local name = path .. "/" .. file
			if fs.isDir(name) then walk(name)
			elseif name:match("%.luau$") then luau.compile(fs.readFile(name)) end
		end
	end
	walk("src"); walk("tools")
end)
test("Short combo produces finisher and consumes 44 stamina", function()
	local s = fresh()
	assert(rules.attack(config, s, "Light", 0) == "Light")
	assert(rules.attack(config, s, "Heavy", 0.56) == "Heavy")
	assert(rules.attack(config, s, "Skill", 1.67) == "Finisher")
	assert(s.Stamina == 56 and s.ComboStep == 0)
end)
test("Early input cannot repeat damage or charge stamina", function()
	local s = fresh(); rules.attack(config, s, "Heavy", 0)
	assert(rules.attack(config, s, "Heavy", 0.1) == nil)
	assert(s.Stamina == 84 and s.BusyUntil == 1.1)
end)
test("Expired and wrong-order combo do not produce finisher", function()
	local s = fresh(); rules.attack(config, s, "Light", 0)
	rules.attack(config, s, "Heavy", 2)
	assert(rules.attack(config, s, "Skill", 3.2) == "Skill")
	s = fresh(); rules.attack(config, s, "Heavy", 0)
	assert(rules.attack(config, s, "Skill", 1.2) == "Skill")
end)
test("Sheathed, sprinting, exhausted, unknown action are rejected", function()
	local s = fresh(); s.Drawn = false; assert(not rules.attack(config, s, "Light", 0))
	s = fresh(); s.Sprinting = true; assert(not rules.attack(config, s, "Light", 0))
	s = fresh(); s.Stamina = 7; assert(not rules.attack(config, s, "Light", 0)); assert(s.Stamina == 7)
	s = fresh(); assert(not rules.attack(config, s, "Finisher", 0)); assert(s.Stamina == 100)
end)
test("Regen waits through recovery and caps at maximum", function()
	local s = fresh(); rules.attack(config, s, "Light", 0)
	rules.regenerate(config, s, 1, 1); assert(s.Stamina == 92)
	rules.regenerate(config, s, 1.31, 1); assert(s.Stamina == 100)
	s.Stamina = 50; s.Sprinting = true; rules.regenerate(config, s, 20, 1); assert(s.Stamina == 50)
end)
local original = roblox.deserializePlace(fs.readFile("HunDino_original.rbxl"))
local built = roblox.deserializePlace(fs.readFile("HunDino_L0.rbxlx"))
test("12 bases and original map objects survive export", function()
	local a, b = original:GetService("Workspace").ForestMap, built:GetService("Workspace").ForestMap
	assert(#a:GetDescendants() == #b:GetDescendants())
	assert(#b.Bases:GetChildren() == 12)
	for i = 1, 12 do
		local name = "Base" .. i
		assert(a.Bases[name].Ground.CFrame == b.Bases[name].Ground.CFrame)
		assert(#a.Bases[name]:GetDescendants() == #b.Bases[name]:GetDescendants())
	end
end)
test("Exactly one active spawn and both travel prompts exist", function()
	local world = built:GetService("Workspace")
	local count = 0
	for _, item in world:GetDescendants() do if item:IsA("SpawnLocation") and item.Enabled then count += 1 end end
	assert(count == 1)
	assert(world.HunDinoL0.Lobby.ToTraining:FindFirstChildOfClass("ProximityPrompt"))
	assert(world.HunDinoL0.Training.ToLobby:FindFirstChildOfClass("ProximityPrompt"))
	assert(#world.HunDinoL0.Training.Dummies:GetChildren() == 3)
end)
test("Embedded server/client sources match editable files", function()
	assert(built:GetService("ServerScriptService").HunDinoTraining.Source == fs.readFile("src/server/Training.server.luau"))
	assert(built:GetService("StarterPlayer").StarterPlayerScripts.HunDinoTraining.Source == fs.readFile("src/client/Training.client.luau"))
	assert(built:GetService("StarterPlayer").EnableMouseLockOption == false)
end)
print("RESULT", passed, "checks passed. Studio runtime/play tests remain required.")
