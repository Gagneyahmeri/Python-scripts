local API = require("api")
local UTILS = require("utils")
local POTLIB = require("potionlibrary")

Write_fake_mouse_do(false)
API.SetMaxIdleTime(5)

local amount = 700

local lastBuyTime = os.time()
local currentTime = os.time()

local function getInventory()
    local items = Inventory:GetItems()
    local itemAmounts = {}

    for _, item in ipairs(items) do
        if item.id ~= -1 then
            if itemAmounts[item.id] then
                itemAmounts[item.id] = itemAmounts[item.id] + item.amount
            else
                itemAmounts[item.id] = item.amount
            end
        end
    end
    return itemAmounts
end

local function checkAmount(itemID, amountNeeded)
    local itemAmounts = getInventory()
    return itemAmounts[itemID] and itemAmounts[itemID] >= amountNeeded
end

local function checkItems(map)
    for itemID, amountNeeded in pairs(map) do
        if not checkAmount(itemID, amountNeeded) then
            return false
        end
    end
    return true
end

local function checkpotions()
    for itemID, requirements in pairs(POTLIB.POTIONS) do
        if checkItems(requirements) then
            return itemID
        end
    end
    return 0
end

local function checkOtheritems()
    for itemID, requirements in pairs(POTLIB.ITEMS) do
        if checkItems(requirements) then
            return itemID
        end
    end
    return 0
end

local function scanInventory()

    local itemID = checkOtheritems()

    if itemID == 29268 then
        print("Doing attuned portent of restorations")
        return 1

    elseif itemID == 36390 then
        print("Doing divine charges")
        return 2
    
    elseif checkpotions() ~= 0 then
        return 3

    elseif itemID == 1607 or itemID == 1605 or itemID == 1603 or itemID == 1601 or itemID == 1615 then
        return 4
    else
        print("No valid mode found")
        API.Write_LoopyLoop(false)
        return nil
    end
end


local function waitForInterface()
    return UTILS.SleepUntil(UTILS.isCraftingInterfaceOpen, 20, "Waiting for interface to open")
end

local function waitForShopInterface()
    return UTILS.SleepUntil(UTILS.isCookingInterfaceOpen, 20, "Waiting for interface to open")
end

local function waitForBankInterface()
    return UTILS.SleepUntil(UTILS.isBankOpen, 20, "Waiting for interface to open")
end

local function animCheck() 
    API.RandomEvents()

    if API.isProcessing() then
        return true
    else
        return false
    end
end

local function banking() --Goebie supplier bank
    API.DoAction_NPC(0x5, API.OFF_ACT_InteractNPC_route, { 21393 }, 50)
    UTILS.countTicks(2)
    if API.BankOpen2 then
        API.KeyboardPress("1", 0, 50)
    end
    --UTILS.countTicks(1)
end

local function cutGems(itemID)

    k = {}

    for itemid, _ in pairs(POTLIB.ITEMS[itemID]) do
        table.insert(k, itemid)
        print(itemid)
    end

    local source = k[1]

    print("Cutting gems " .. source)
    API.DoAction_Inventory1(source,0,1,API.OFF_ACT_GeneralInterface_route)
    waitForInterface()
    API.KeyboardPress2(0x20, 1000, 200)

    while animCheck() do
        API.RandomSleep2(200, 100, 200)
    end
    amount = amount - Inventory:GetItemAmount(itemID)
    print("Amount after processing: " .. amount)
end

local function buyPotions() -- Goebie supplier shop
    if Inventory:FreeSpaces() < 7 or API.VB_FindPSett(6480, 1, 0).state < 1000000 then
        print("Not enough inventory space to buy potions. Skipping.")
        return
    end

    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route3, {21393}, 50)
    waitForShopInterface()

    -- List of shop slot IDs to buy (these are slot IDs in the shop, not item IDs)
    local potions = {1, 3, 4, 5, 6, 7, 8}

    -- Mapping of shop slot IDs to item IDs
    local itemIDs = {
        [1] = 3024,
        [3] = 2436,
        [4] = 2440,
        [5] = 2442,
        [6] = 3040,
        [7] = 2444,
        [8] = 55316
    }

    for _, slot in ipairs(potions) do
        local itemID = itemIDs[slot]

        -- Get the item data from the container (inventory) using the item ID
        local potionItem = API.Container_Get_s(786, itemID)

        if potionItem.item_stack > 0 then
            API.DoAction_Interface(0xffffffff, 0xffffffff, 2, 1265, 20, slot, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(100, 200, 300)
        else
            print("Potion from shop slot " .. slot .. " is out of stock, skipping.")
        end
    end
end

local function doAttunedPortentsRestorations()

    if Inventory:GetItemAmount(29324) < 10000 or Inventory:GetItemAmount(15272) < 27 then
        print("Conditions not met for Mode 1. Stopping the script.")
        API.Write_LoopyLoop(false)
        return
    end

    API.DoAction_Inventory1(29324, 0, 1, API.OFF_ACT_GeneralInterface_route)
    waitForInterface()
    API.KeyboardPress2(0x20, 100, 200)
    UTILS.countTicks(2)

    while animCheck() do
        API.RandomSleep2(200, 100, 200)
    end

    amount = amount - Inventory:GetItemAmount(29268)
    print("Amount after processing: " .. amount)
end

local function doModeDivineCharges()
    API.DoAction_Inventory1(29324, 0, 1, API.OFF_ACT_GeneralInterface_route)
    waitForInterface()
    API.KeyboardPress2(0x20, 100, 200)
    UTILS.countTicks(2)

    while animCheck() do
        API.RandomSleep2(200, 100, 200)
    end

    amount = amount - Inventory:GetItemAmount(36390)
end

local function doPotions(potionID)

    print(potionID)

    if potionID == 0 then
        print("No potions available.")
        API.Write_LoopyLoop(false)
        return
    end

    k = {}

    for itemid, _ in pairs(POTLIB.POTIONS[potionID]) do
        table.insert(k, itemid)
        --print(itemid)
    end

    local source = k[1]
    local target = k[2]

    if potionID == 33210 or 49039 then
        source = k[1]
        target = k[3]
    end

    Inventory:UseItemOnItem(source, target)
    waitForInterface()
    API.KeyboardPress2(0x20, 3000, 200)

    while animCheck() do
        API.RandomSleep2(200, 100, 200)
    end

    amount = amount - Inventory:GetItemAmount(potionID)
    print("Amount after processing: " .. amount)
end

local function deposit()
    Interact:NPC("Goebie supplier", "Bank", 20)
    waitForBankInterface()
    API.KeyboardPress("3", 0, 50)

    while not Inventory:IsEmpty() do
        API.RandomSleep2(50, 100, 200)
    end
    --API.BankAllItems()
    --API.DoAction_Interface(0xffffffff,0xffffffff,1,517,39,-1,API.OFF_ACT_GeneralInterface_route)
end

local mode = scanInventory()
if not mode then
    API.Write_LoopyLoop(false)
    return
end

print("Selected mode: " .. mode)

while API.Read_LoopyLoop() do
    currentTime = os.time()

    --print(currentTime, lastBuyTime)

    if currentTime - lastBuyTime >= 90 then

        if Inventory:FreeSpaces() < 8 then
            deposit()
        end
        --deposit()
        buyPotions()
        lastBuyTime = currentTime
    end

    banking()

    UTILS.countTicks(3)

    if mode == 1 then
        doAttunedPortentsRestorations()
    elseif mode == 2 then
        doModeDivineCharges()
    elseif mode == 3 then
        doPotions(checkpotions())
    elseif mode == 4 then
        cutGems(checkOtheritems())
    end

    if amount <= 0 then
        print("Target amount reached. Stopping.")
        API.Write_LoopyLoop(false)
        break
    end
end