--| Services & Modules
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Inventory = require(RS.Mods.Inventory)

--| Variables
local localPlr = Players.LocalPlayer

local Prefabs = RS.Prefabs
local InvSettings = Inventory.Settings
local InventoryGUI = localPlr.PlayerGui:WaitForChild("Inventory")
local comms = RS.Comms

--| Functions
local function inputBegan(input : InputObject, gPE : boolean)
	if gPE then return end
	
	if input.KeyCode == InvSettings.KeyBinds.ToggleInventory then
		InventoryGUI.Enabled = not InventoryGUI.Enabled
	elseif input.KeyCode == InvSettings.KeyBinds.PutBack then
		comms.Store:FireServer()
	end
end

local function itemAdded(item : Instance)
	local amount = Inventory.GetItemCount(localPlr, item.Name)
	local itemElement = InventoryGUI.List:FindFirstChild(item.Name)
	
	if not itemElement then
		local newItemGUI = Prefabs.GUI.Item:Clone()
		newItemGUI.Name = item.Name
		newItemGUI.ItemImage.Image = item:GetAttribute("Image")
		newItemGUI.ItemCategory.Text = item:GetAttribute("Caterogy")
		newItemGUI.Parent = InventoryGUI.List
		
		local event = newItemGUI.Button.MouseButton1Click:Connect(function() 
			comms.Equip:FireServer(item.Name) 
		end)
		
		newItemGUI.Destroying:Connect(function() 
			event:Disconnect() 
		end)
	end
	
	InventoryGUI.List[item.Name].ItemName.Text = item.Name.." ("..amount..")"
end

local function itemRemoved(item : Instance)
	local amount = Inventory.GetItemCount(localPlr, item.Name)
	
	if amount > 0 then
		InventoryGUI.List[item.Name].ItemName.Text = item.Name.." ("..amount..")"
	else
		InventoryGUI.List[item.Name]:Destroy()
	end
end

local function updateWeight()
	InventoryGUI.Main.WeighText.Text = localPlr:GetAttribute("Weight").."/"..localPlr:GetAttribute("MaxWeight")
end

--| Events
UIS.InputBegan:Connect(inputBegan)
localPlr.Items.ChildAdded:Connect(itemAdded)
localPlr.Items.ChildRemoved:Connect(itemRemoved)
localPlr:GetAttributeChangedSignal("Weight"):Connect(updateWeight)

InventoryGUI:WaitForChild("Main"):WaitForChild("ContainerText").Text = localPlr.Name.."'s Inventory"
--[[
dark - 13, 13, 13
light - 90, 90, 90
]]
