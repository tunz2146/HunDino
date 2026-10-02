local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local game = roblox.deserializePlace(fs.readFile("HunDino_original.rbxl"))
local function walk(parent, depth)
	for _, item in parent:GetChildren() do
		local extra = ""
		if item:IsA("BasePart") and not item:IsA("Terrain") then extra = " pos=" .. tostring(item.CFrame.Position) .. " size=" .. tostring(item.Size) end
		if depth <= 3 then print(string.rep("  ", depth) .. item.ClassName .. " " .. item.Name .. extra) end
		if item:IsA("LuaSourceContainer") then
			print("SCRIPT", item:GetFullName(), #item.Source, item.Source:sub(1, 200))
		end
		walk(item, depth + 1)
	end
end
walk(game, 0)
print("TOTAL", #game:GetDescendants())
fs.writeFile("HunDino_original.rbxlx", roblox.serializePlace(game, true))
