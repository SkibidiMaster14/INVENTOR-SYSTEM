local Inventory = {}
Inventory.__index = Inventory

--| Services
local RS = game:GetService("ReplicatedStorage")
local RunS = game:GetService("RunService")

--| Variables
Inventory.Settings = {}
Inventory.Settings.WalkSpeedDebuff = 50 -- set to 0 for no reduction of walkspeed
Inventory.Settings.DefaultAttributes = {["Weight"] = 0, ["MaxWeight"] = 16}
Inventory.Settings.KeyBinds = {
	["ToggleInventory"] = Enum.KeyCode.Q,
	["PutBack"] = Enum.KeyCode.E
}
local comms = RS.Comms

local inventories = {}

--| Functions
local function updateSpeed(plr)
	plr.Character.Humanoid.WalkSpeed = plr.Character.Humanoid.WalkSpeed - plr:GetAttribute("Weight") / Inventory.Settings.WalkSpeedDebuff
end

function Inventory.new(plr : Player) : {}
	for i, v in inventories do
		if i == plr.UserId then return v end -- to make sure the player doesn't already have an inventory
	end
	
	for i, v in Inventory.Settings.DefaultAttributes do
		plr:SetAttribute(i, v)
	end

	local ItemsFolder = Instance.new("Folder")
	ItemsFolder.Name = "Items"
	ItemsFolder.Parent = plr
	
	local newInventory = setmetatable({}, Inventory)
	
	newInventory.Player = plr
	newInventory.Connections = {
		["WeightChanged"] = plr:GetAttributeChangedSignal("Weight")
	}
	
	newInventory.Connections.WeightChanged:Connect(function() updateSpeed(plr) end) -- couldn't resist stuffing all this into 1 line
	
	inventories[plr.UserId] = newInventory
	return newInventory
end

function Inventory.GetItemCount(plr : Player, itemName : string) : number
	local count = 0
	
	for _, v in plr.Items:GetChildren() do
		if v.Name == itemName then count += 1 end
	end
	
	return count
end

function Inventory:Add(item : Instance) : boolean -- returns true if success, else false
	if self.Player:GetAttribute("Weight") + item:GetAttribute("Weight") > self.Player:GetAttribute("MaxWeight") then return false end
	
	item.Parent = self.Player.Items
	self.Player:SetAttribute("Weight", self.Player:GetAttribute("Weight") + item:GetAttribute("Weight"))
	return true
end

function Inventory:Remove(item : Instance)
	self.Player:SetAttribute("Weight", self.Player:GetAttribute("Weight") - item:GetAttribute("Weight"))
	
	if item then item:Destroy() end
end

function Inventory:Equip(item : Instance)
	if self.Player.Character:FindFirstChildWhichIsA("Tool") then return end
	
	item:Clone().Parent = self.Player.Character
	
	self:Remove(item)
end

function Inventory:Destroy()
	self.Player.Items:Destroy()
	
	for i, v in Inventory.Settings.DefaultAttributes do
		self.Player:SetAttribute(i, v)
	end
	
	for _, connection in self.Connections do
		connection:Disconnect() -- avoid memory leaks
	end
	
	inventories[self.Player.UserId] = nil
	self = nil
end

--| Events
if RunS:IsClient() then return Inventory end
comms.Equip.OnServerEvent:Connect(function(plr : Player, itemName : string)
	local plrInventory = Inventory.new(plr) -- returns inventory anyways
	
	if not plrInventory or not plr.Items:FindFirstChild(itemName) then return end
	
	plrInventory:Equip(plr.Items[itemName])
end)

comms.Store.OnServerEvent:Connect(function(plr)
	local tool = plr.Character:FindFirstChildWhichIsA("Tool")
	if not tool then return end
	
	local plrInventory = Inventory.new(plr)
	if not plrInventory then return end
	
	if not plrInventory:Add(tool) then -- if we failed to store the tool then equip it again
		plrInventory:Equip(tool)
	end
end)

return Inventory
