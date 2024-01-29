-- useless script pretty much (for now)
--| Services & Modules
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local Inventory = require(RS.Mods.Inventory)

--| Variables


--| Functions
local function playerAdded(plr : Player)
	Inventory.new(plr)
end

--| Events
Players.PlayerAdded:Connect(playerAdded)
