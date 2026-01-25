local API = require("api")
local LODESTONES = require("lodestones")       
local UTILS = require("utils")
local Slib = require("slib")
local AURAS = require("deadAuras")

Write_fake_mouse_do(false)

local maxWaitTime = 20
local elapsedTime = 0
local waitInterval = 0.5

API.SetMaxIdleTime(10)

local IsFirstRun = true

local ACTIVITY_STATUS = {

    -- Runeshops
    BABA_YAGA = true,
    AlKharid = true,
    Void = true,
    Yanille = true,

    -- Viswax
    Viswax = true,

    -- Meats
    Ooglog = true,

    -- Daily activities
    mineRedsandstone = true,
    mineCrystalsandstone = true,
    claimLupe = true,
    collectPotatocacti = true,
    doSupercompost = false,

    -- Potion shops
    buyJatix = true,
    buyMeilyr = true,
    buyFort = true,

    slimeRunner = false,
    dreamofiaia = true,

    -- Only if needed
    ZamorakMage = false,
    Magebank = false,

    -- Not doing
    Sarim = false,
    Varrock = false
}

local OtherIDsNeededForStuff = {
    ["LOTD"] = 39812,
    ["AttunedCrystalSeed"] = 39784,
    ["WickedHood"] = 22332,
    ["WarsTeleport"] = 35042,
    ["GraceOfTheElves"] = 44550,
    ["TirannwnQuiver4"] = 33722,
    ["PassageOfTheAbyss"] = 44542,
}

local Interfaces = {
    ["Teleports"] = { { 720, 2, -1, 0 }, { 720, 17, -1, 2 } },
    ["CraftingInterface"] = { { 1370, 0, -1, 0 }, { 1370, 31, -1, 2 } },
    ["FairyRing"] = { { 784, 0, -1, 0 }, { 784, 56, -1, 2 } },
    ["Shop"] = { { 1265,7,-1,0 }, { 1265,9,-1,0 } },
    ["ChatOptions"] = { { 1188, 5, -1, -1}, { 1188, 3, -1, 5}, { 1188, 3, 14, 3} },
}

local DialogOptions = {
    "I would like to have a look at your selection of runes.",
    "Yes."
}



--------------------------------------------------
----------------SAFETY CHECKS START---------------
--------------------------------------------------
local function OnlyOnceSafetyChecks()

    if API.VB_FindPSettinOrder(3039).state == 1 then
        print("Inventory is open")
    else
        print("Open the damn inventory.")
        return false
    end

    if API.CacheEnabled then
        print("Cache is enabled, running the script.")
    else
        print("Cache is disabled. Turn it on.")
        return false
    end

    if not Equipment:Contains(24137) then
        print("Wrong preset.")
        return false
    end

    local result = API.DeBuffbar_GetIDstatus(44550, false)
    local budd = API.Buffbar_GetIDstatus(51490, false)

    local function checkValue(status)
        if status and status.text then
            local num = tonumber(status.text)
            if num then
                if num < 100 then
                    print("Buff/Debuff value is below 100:", num)
                    return false
                else
                    print("Buff/Debuff value is acceptable:", num)
                    return true
                end
            end
        end
        return nil
    end

    local resultCheck = checkValue(result)
    local buddCheck = checkValue(budd)

    local finalCheck = resultCheck or buddCheck
    if finalCheck == false then
        return false
    elseif finalCheck == nil then
        print("No valid Buff/Debuff number found")
        return false
    end


    if AURAS.isAuraEquipped() then
        print("Another aura is active. Forcing Resourceful activation.")
        AURAS.RESOURCEFUL:activate(true)
    else
        print("No aura equipped. Activating Resourceful normally.")
        AURAS.RESOURCEFUL:activate(false)
    end

    return true
end

--------------------------------------------------
----------------SAFETY CHECKS END-----------------
--------------------------------------------------

local function InterfaceIsOpen(interfaceName)
    return #API.ScanForInterfaceTest2Get(true, Interfaces[interfaceName]) > 0
end

local function UseFairyring()

    LODESTONES.YANILLE.Teleport()

    Interact:Object("Fairy ring", "Select destination", 40)

    Slib:SleepUntil(function()
        return InterfaceIsOpen("FairyRing")
    end, 20, 100)

    API.DoAction_Interface(0x2e, 0xffffffff, 1, 784, 48, 51, API.OFF_ACT_GeneralInterface_route)
    Slib:RandomSleep(600, 1200, "ms")
    API.DoAction_Interface(0x2e, 0xffffffff, 1, 784, 23, -1, API.OFF_ACT_GeneralInterface_route)

    Slib:RandomSleep(4000, 5000, "ms")
    
end

-----------------------------------------------------
------------- UTILITY FUNCTIONS START ---------------
-----------------------------------------------------

local function CheckObject(id, distance, types)
    local obj = API.GetAllObjArrayInteract(id, distance, types)
    
    if obj and #obj > 0 then
        return obj[1]
    end

    return nil
end
local function DialogBoxIsOpen()
    local VB1 = tonumber(API.VB_FindPSettinOrder(2874).state)
    if VB1 == 12 then
        return true
    else
        return false
    end
end

local function HasOption()
    local option = API.ScanForInterfaceTest2Get(false, Interfaces["ChatOptions"])

    if #option > 0 and #option[1].textids > 0 then
        return option[1].textids
    end

    return false
end

local function OptionSelector(options)
    for i, optionText in ipairs(options) do
        local optionNumber = tonumber(API.Dialog_Option(optionText))
        if optionNumber and optionNumber > 0 then
            local keyCode = 0x30 + optionNumber
            API.KeyboardPress2(keyCode, 60, 100)
            API.RandomSleep2(400,300,600)
            return true
        end
    end
    return false
end

local function isInventoryOpen()
    if API.VB_FindPSettinOrder(3039).state == 1 then
        print("Inventory is open")
        return true
    else
        print("Open the damn inventory, dude. I'm not gonna do everything for you. What's next? You want me to click the buttons too? Maybe hold your hand while we sort potions? Come on, just pop it open and let's get this over with before I start charging an hourly rate. 5b still gonna ask what's wrong.")
        return false
    end
end

local function isOpen()
    return API.Compare2874Status(40, false) or API.Compare2874Status(18, false) or API.Compare2874Status(11, false) or API.Compare2874Status(13, false)
end

local function clickRandomTile(baseX, baseY, range)
    local offsetX = math.random(-range, range)
    local offsetY = math.random(-range, range)
    local randomTile = WPOINT.new(baseX + offsetX, baseY + offsetY, 0)
    API.DoAction_Tile(randomTile)
end

local function randomizeDiveCoordinates(baseX, baseY, baseZ, range)
    local xOffset = math.random(-range, range)
    local yOffset = math.random(-range, range)
    local zOffset = math.random(-range, range)
    return WPOINT.new(baseX + xOffset, baseY + yOffset, baseZ + zOffset)
end

local function BuyItems(items)
    for _, rune in ipairs(items) do
        API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, rune, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(100, 200, 300)
    end 
    API.KeyboardPress("Esc", 0, 50)
    UTILS.randomSleep(1000)
end

local function waitUntil(maxWaitTime, waitInterval)
    local elapsedTime = 0
    while elapsedTime < maxWaitTime do
        UTILS.randomSleep(waitInterval * 1000)
        elapsedTime = elapsedTime + waitInterval
    end
end

local function animCheck() 
    API.DoRandomEvents(200, 200)

    if API.CheckAnim(50) or API.ReadPlayerMovin2() or API.isProcessing() then
        --print("Player is busy")
        return true
    else
        --print("Player is not busy")
        return false
    end
end

local function goteporterCheck()
    if API.Buffbar_GetIDstatus(51490, false).id > 0 then
        print("Porters active")
        return true  -- Buff is active
    else
        print("Porters not active.")
        return false  -- Buff is not active
    end
end

local function unboxItem(itemID)
    if Inventory:Contains(itemID) then
        API.DoAction_Inventory1(itemID, 0, 2, API.OFF_ACT_GeneralInterface_route)
    end
end

local function unboxMeats()
    unboxItem(50246)
    API.RandomSleep2(200, 100, 250)

    unboxItem(50247)
    API.RandomSleep2(200, 100, 250)

    unboxItem(15365)
    API.RandomSleep2(600, 300, 500)
end


local function waitForTeleportSeedInterface()
    return UTILS.SleepUntil(UTILS.isTeleportSeedInterfaceOpen, 20, "Waiting for teleport seed interface to open")
end

local function waitForChatbox()
    return UTILS.SleepUntil(UTILS.isChooseOptionInterfaceOpen, 20, "Waiting for chat interface to open")
end

local function waitForCompost()
    return UTILS.SleepUntil(UTILS.isCompostInterfaceOpen, 20, "Waiting for compost interface to open")
end

--local function waitForAnyInterface()
--    return UTILS.SleepUntil(UTILS.isAnyInterfaceOpen, 20, "Waiting for interface to open")
--end

local function waitForShopInterface()
    return UTILS.SleepUntil(UTILS.isCookingInterfaceOpen, 20, "Waiting for shop interface to open")
end

local function waitForArheinInput()
    return UTILS.SleepUntil(UTILS.isArheinInterfaceOpen, 20, "Waiting for input interface to open")
end

-----------------------------------------------------
--------------- UTILITY FUNCTIONS END ---------------
-----------------------------------------------------

-----------------------------------------------------
------------- ACTIVITY FUNCTIONS START --------------
-----------------------------------------------------

local function buyBabaYaga() 
    LODESTONES.LUNAR_ISLE.Teleport()
    API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route,{ 4512 },50)
    UTILS.countTicks(1)
    UTILS.surge()
    API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route,{ 4512 },50)
    while not API.PInArea(3103, 5, 4447, 5, 0) do
        UTILS.randomSleep(1000) 
    end
    API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route2,{ 4513 },50)
    UTILS.randomSleep(1000)
    
        waitUntil(5, 1)
        if not isOpen() then return end

        local Items = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}
        BuyItems(Items) 

    ACTIVITY_STATUS.BABA_YAGA = false
end 

local teleportedYanille = false

local function buyMagesGuild()
    if not teleportedYanille  then
        LODESTONES.YANILLE.Teleport()
        teleportedYanille  = true  
    end

    local function atMagesGuild()
        return API.PInArea(2529, 5, 3094, 5, 0)
    end

    local function inMagesGuild()
        return API.PInArea(2585, 1, 3088, 1, 0)
    end

    local function isAtShop()
        return API.PInArea(2590, 1, 3092, 1, 0)
    end

    if atMagesGuild() then
        clickRandomTile(2565, 3091, 2)
        UTILS.countTicks(3)
        UTILS.surge()
        UTILS.Bdive(randomizeDiveCoordinates(2573, 3092, 0, 2))
        UTILS.countTicks(1)
        UTILS.surge()

        Interact:Object("Magic guild door", "Open")
    end

    if inMagesGuild() then
        Interact:Object("Staircase", "Climb-up")
        UTILS.countTicks(4)
    end

    if isAtShop() then
        Interact:NPC("Magic Store owner", "Trade")

        waitForShopInterface()

        local Items = {0, 1, 2, 3, 4, 5, 6, 9, 10, 11}
        for _, Runes in ipairs(Items) do
            API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(100, 200, 300)
        end
        API.KeyboardPress("Esc", 0, 50)
            UTILS.randomSleep(1000) 
        ACTIVITY_STATUS.Yanille= false
    end
end

local teleportedSarim = false

local function BuySarim()
     if not teleportedSarim then
        LODESTONES.PORT_SARIM.Teleport()
        teleportedSarim = true
    end 

    local function atPortSarim()
        return API.PInArea(3011, 5, 3215, 5, 0)
    end

    if atPortSarim() then
        UTILS.Bdive(randomizeDiveCoordinates(3021, 3227, 0, 2))
        clickRandomTile(3019, 3259, 2)
        UTILS.countTicks(3)
        UTILS.surge()
        clickRandomTile(3019, 3259, 2)
        UTILS.countTicks(5)
    end
        Interact:Object("Door", "Open") 
        UTILS.randomSleep(5000)         
        API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route2, {583}, 50)
        UTILS.randomSleep(1000)
    
         while not isOpen() and elapsedTime < maxWaitTime do
            UTILS.randomSleep(waitInterval * 1000)
            elapsedTime = elapsedTime + waitInterval
        end
    
            if not isOpen() then return end
    
            local Items = {0, 1, 2, 3, 4, 5, 6, 7}
            for _, Runes in ipairs(Items) do
                API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
                API.RandomSleep2(100, 200, 300)
            end
            API.KeyboardPress("Esc", 0, 50)
            UTILS.randomSleep(1000) 
            ACTIVITY_STATUS.Sarim = false
end

local function BuyVoid()
    LODESTONES.PORT_SARIM.Teleport()
    clickRandomTile(3026,3205,2)
    Interact:NPC("Squire", "Travel")
    while not API.PInArea(2651, 10, 2673, 10, 0) do
        UTILS.randomSleep(2000) 
    end
    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route2, {3798}, 50)
    UTILS.randomSleep(1000)

    while not isOpen() and elapsedTime < maxWaitTime do
        UTILS.randomSleep(waitInterval * 1000)
        elapsedTime = elapsedTime + waitInterval
    end
        if not isOpen() then return end
    
        local Items = {0, 1, 2, 3, 4, 5, 6, 7}
        for _, Runes in ipairs(Items) do
            API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(100, 200, 300)
        end 
        API.KeyboardPress("Esc", 0, 50)
            UTILS.randomSleep(1000) 
    ACTIVITY_STATUS.Void = false
end

local function BuyVarrock()
    LODESTONES.VARROCK.Teleport()
    clickRandomTile(3218, 3390, 2)
    UTILS.countTicks(2)
    UTILS.surge()
    UTILS.Bdive(randomizeDiveCoordinates(3233, 3390, 0, 2))
    UTILS.countTicks(1)
    UTILS.surge()
    clickRandomTile(3253,3397,1)
    while not API.PInArea(3253, 2, 3397, 2, 0) do
        UTILS.randomSleep(2000) 
    end
    Interact:Object("Door", "Open",3)
    UTILS.randomSleep(3000)
    Interact:NPC("Aubury", "Trade",8)
    UTILS.randomSleep(1000)

    while not isOpen() and elapsedTime < maxWaitTime do
        UTILS.randomSleep(waitInterval * 1000)
        elapsedTime = elapsedTime + waitInterval
    end
        if not isOpen() then return end
    
        local Items = {0, 1, 2, 3, 4, 5, 6, 7}
        for _, Runes in ipairs(Items) do
            API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(100, 200, 300)
        end 
        API.KeyboardPress("Esc", 0, 50)
            UTILS.randomSleep(1000) 
    ACTIVITY_STATUS.Varrock = false
end

local function BuyAlkharid()

    if Slib:IsPlayerInArea(3300, 3211, 0, 3) then
        Interact:NPC("Ali Morrisane", "Trade")
        Slib:SleepUntil(function()
            return DialogBoxIsOpen()
        end, 20, 100)

        if HasOption() then
            Slib:Info("Dialog box open. Has option. Selecting option.")
            OptionSelector(DialogOptions)
        end

        Slib:RandomSleep(400, 600, "ms")
        Slib:TypeText("3")

        Slib:SleepUntil(function()
            return InterfaceIsOpen("Shop")
        end, 8, 100)


        local Items = {0, 1, 2, 3}
        if InterfaceIsOpen("Shop") then
            for _, Runes in ipairs(Items) do
                API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
                API.RandomSleep2(100, 200, 300)
            end
        end

        Interact:NPC("Ali Morrisane", "Trade")
        Slib:SleepUntil(function()
            return DialogBoxIsOpen()
        end, 8, 100)

        if HasOption() then
            Slib:Info("Dialog box open. Has option. Selecting option.")
            OptionSelector(DialogOptions)
        end
        
        Slib:RandomSleep(400, 600, "ms")
        Slib:TypeText("4")

        Slib:SleepUntil(function()
            return InterfaceIsOpen("Shop")
        end, 6, 100)

        local Items2 = {1, 2, 3, 4, 5, 6, 7, 8}

        if InterfaceIsOpen("Shop") then
            for _, Runes in ipairs(Items2) do
                API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
                API.RandomSleep2(100, 200, 300)
            end
        end

        ACTIVITY_STATUS.AlKharid = false

    elseif Slib:IsPlayerInArea(3297, 3184, 0, 6) then
        Slib:MoveTo(Slib:RandomNumber(3300, 1, 1), Slib:RandomNumber(3211, 1, 1), 0)

    else
        LODESTONES.AL_KHARID.Teleport()
    end
end

local function BuyZamorakMage()
    LODESTONES.EDGEVILLE.Teleport()
    Interact:Object("Wilderness wall", "Cross")
    while not API.PInArea(3066, 1, 3523, 1, 0) do
        UTILS.randomSleep(2000) 
    end
    UTILS.countTicks(2)
    clickRandomTile(3093, 3556, 2)
    UTILS.countTicks(3)
    UTILS.surge()
    clickRandomTile(3093, 3556, 2)
    UTILS.countTicks(3)
    UTILS.Bdive(randomizeDiveCoordinates(3109, 3557, 0, 2))
    API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route2,{ 2257 },50)
    UTILS.randomSleep(1000)

    while not isOpen() and elapsedTime < maxWaitTime do
        UTILS.randomSleep(waitInterval * 1000)
        elapsedTime = elapsedTime + waitInterval
    end
        if not isOpen() then return end
    
        local Items = {0, 1, 2, 3, 4, 5, 6, 7}
        for _, Runes in ipairs(Items) do
            API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(100, 200, 300)
        end 
       API.KeyboardPress("Esc", 0, 50)
       UTILS.randomSleep(1000) 
    ACTIVITY_STATUS.ZamorakMage = false
end

local function BuyMagebank()
    API.DoAction_Interface(0xffffffff,0x9411,2,1464,15,3,API.OFF_ACT_GeneralInterface_route)
    UTILS.randomSleep(4000)
    clickRandomTile(3094, 3476, 2)
    UTILS.randomSleep(4000)
    Interact:Object("Lever", "Pull")
    UTILS.randomSleep(2000)
   
    while not API.PInArea(3154, 5, 3924, 5, 0) do
        UTILS.randomSleep(1000) 
    end
    UTILS.randomSleep(1000) 
    clickRandomTile(3158, 3948, 2)
    UTILS.countTicks(3)
    UTILS.surge()
    clickRandomTile(3158, 3948, 2)
    Interact:Object("Web", "Slash")
    UTILS.randomSleep(5000)
    clickRandomTile(3120, 3957, 2)
    UTILS.countTicks(3)
    UTILS.surge()
    clickRandomTile(3094, 3958, 1)
    UTILS.countTicks(4)
    UTILS.surge()
    clickRandomTile(3094, 3958, 1)
    UTILS.randomSleep(10000)
    API.DoAction_Object2(0x29,API.OFF_ACT_GeneralObject_route0,{ 64729 },50,WPOINT.new(3094,3958,0));
    UTILS.randomSleep(3000)
    API.DoAction_Object2(0x29,API.OFF_ACT_GeneralObject_route0,{ 64729 },50,WPOINT.new(3091,3958,0));
    UTILS.randomSleep(3000)
    Interact:Object("Lever", "Pull")
    while not API.PInArea(2539, 5, 4712, 5, 0) do
        UTILS.randomSleep(1000) 
    end
    Interact:NPC("Lundail", "Trade")    
    UTILS.randomSleep(1000)

    while not isOpen() and elapsedTime < maxWaitTime do
        UTILS.randomSleep(waitInterval * 1000)
        elapsedTime = elapsedTime + waitInterval
    end

    if not isOpen() then return end
    
         local Items = {0, 1, 2, 3, 4, 5, 6, 7,8,9,10}
        for _, Runes in ipairs(Items) do
            API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(100, 200, 300)
        end 
       API.KeyboardPress("Esc", 0, 50)
            UTILS.randomSleep(1000) 
    ACTIVITY_STATUS.Magebank = false
end

local function BuyOoglog()
    LODESTONES.OOGLOG.Teleport()
    clickRandomTile(2508, 2837, 2)
    UTILS.countTicks(3)
    UTILS.surge()
    clickRandomTile(2508, 2837, 2)
    UTILS.randomSleep(3000)
    UTILS.countTicks(3)
    clickRandomTile(2523, 2837, 2)
    UTILS.countTicks(4)
    UTILS.surge()
    UTILS.Bdive(randomizeDiveCoordinates(2560, 2849, 0, 2))
    UTILS.surge()
    clickRandomTile(2560, 2849, 2)
    UTILS.randomSleep(3000)
    UTILS.surge()
    API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route2,{ 7056 },50)
    waitForShopInterface()
    
         local Items = {0, 1, 2}
        for _, Runes in ipairs(Items) do
            API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(100, 200, 300)
        end
        API.KeyboardPress("Esc", 0, 50)
            UTILS.randomSleep(1000)

    unboxMeats()
    ACTIVITY_STATUS.Ooglog = false
end


local function mineRedsandstone()

    if goteporterCheck() then
        print("Porters already active")
    else
        API.DoAction_Ability("Grace of the elves", 6, API.OFF_ACT_GeneralInterface_route)
        print("Enabled porters.")
    end

    -- Red sandstone IDs
    local activeIds = {67969, 67970, 67971, 67972} -- Active rocks
    local depletedId = 67973                      -- Depleted rock

    if Slib:IsPlayerInArea(2586, 2877, 0, 2) then
        local obj = Slib:FindObj(depletedId, 5, 0)
        while not obj do
            API.DoRandomEvents(600, 600)
            --print("Mining red sandstone...")
            Slib:RandomSleep(600, 1200, "ms")
            obj = Slib:FindObj(depletedId, 5, 0)
        end
        print("Red sandstone depleted. Moving on.")
        ACTIVITY_STATUS.mineRedsandstone = false

    elseif Slib:IsPlayerAtCoords(2596, 2871, 0) then
        local obj = Slib:FindObj(activeIds, 20, 0)
        if obj then
            Interact:Object("Red sandstone", "Mine", 15)
            Slib:SleepUntil(function()
                return Slib:IsPlayerInArea(2586, 2877, 0, 2)
            end, 20, 100)
        else
            print("No red sandstone found — checking depletion...")
            ACTIVITY_STATUS.mineRedsandstone = false
        end

    elseif Slib:IsPlayerInArea(2594, 2865, 0, 5) then
        Interact:Object("Rock passage", "Squeeze-through", 10)
        Slib:SleepUntil(function()
            return Slib:IsPlayerAtCoords(2596, 2871, 0)
        end, 20, 100)
        Slib:RandomSleep(1000, 1200, "ms")

    elseif Slib:IsPlayerInArea(2560, 2850, 0, 10) then
        Slib:MoveTo(Slib:RandomNumber(2594, 1, 1), Slib:RandomNumber(2865, 1, 1), 0)

    else
        LODESTONES.OOGLOG.Teleport()
    end
end


--
-- CRYSTAL-FLECKED SANDSTONE STARTS
--

local function CrystalSeedTeleport(key)
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["AttunedCrystalSeed"]) then
        Slib:Error("Attuned crystal seed not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Attuned crystal seed not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    local AttunedCrystalSeed = API.GetABs_id(OtherIDsNeededForStuff["AttunedCrystalSeed"])
    API.DoAction_Ability_Direct(AttunedCrystalSeed, 1, API.OFF_ACT_GeneralInterface_route) --Activate
    Slib:SleepUntil(function()
        return InterfaceIsOpen("Teleports")
    end, 6, 100)

    if InterfaceIsOpen("Teleports") then
        Slib:TypeText(key)
        Slib:RandomSleep(1000, 1200, "ms")
    end
    Slib:RandomSleep(4500, 5000, "ms")
end

local function bankingIthell()
    API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, {92692}, 50) -- Load last preset
    Slib:SleepUntil(function()
        return Slib:IsPlayerInArea(2153, 3340, 1, 3)
    end, 20, 100)
    Slib:RandomSleep(1200, 1500, "ms")
end

local function interactGlassmachine()
    if Inventory:Contains(32847) then
        print("Interacting with robust glass machine...")
        Interact:Object("Robust glass machine", "Fill", 20)

        Slib:SleepUntil(function()
            return InterfaceIsOpen("CraftingInterface")
        end, 10, 200)
        Slib:RandomSleep(600, 800, "ms")

        if InterfaceIsOpen("CraftingInterface") then
            API.KeyboardPress2(0x20, 40, 60)
            Slib:RandomSleep(8000, 8200, "ms")
        end
    else
        print("Nothing to process at glass machine. Skipping.")
    end
end


local function processCrystalglass()

    if Inventory:Contains(32845) then
        API.DoAction_Inventory1(32845, 0, 1, API.OFF_ACT_GeneralInterface_route)
        Slib:SleepUntil(function()
            return InterfaceIsOpen("CraftingInterface")
        end, 10, 200)

        if InterfaceIsOpen("CraftingInterface") then
            API.KeyboardPress2(0x20, 40, 60)
            Slib:RandomSleep(600, 1200, "ms")
        else
            print("No crystal glass to process. Skipping.")
        end

        if API.isProcessing()
        then
            print("Processing crystal glass...")
            Slib:SleepUntil(function()
                return not API.isProcessing()
            end, 60, 500)
        end
    end
end


local function mineCrystalsandstone()

    if goteporterCheck() then
        API.DoAction_Ability("Grace of the elves", 6, API.OFF_ACT_GeneralInterface_route)
        print("Porters disabled.")
    end

    local activeIds  = {112696, 112697, 112698, 112699} -- Mineable sandstone
    local depletedId = 112700                           -- Depleted sandstone

    if Inventory:IsFull() and Slib:IsPlayerInArea(2144, 3352, 1, 3) then
        print("Inventory full. Processing and banking crystal-flecked sandstone...")
        interactGlassmachine()
        processCrystalglass()
        bankingIthell()
        return
    end

    if Slib:IsPlayerInArea(2155, 3340, 1, 10) or Slib:IsPlayerAtCoords(2144, 3352, 1) then
        print("At mining location. Starting mining loop...")

        while API.Read_LoopyLoop() do
            
            if Slib:FindObj(depletedId, 30, 0) then
                print("Crystal-flecked sandstone depleted. Processing and banking...")
                interactGlassmachine()
                processCrystalglass()
                bankingIthell()
                ACTIVITY_STATUS.mineCrystalsandstone = false
                return
            end

            if Inventory:IsFull() then
                print("Inventory full while mining. Proceeding to process and bank.")
                interactGlassmachine()
                processCrystalglass()
                bankingIthell()
                return
            end

            local rock = Slib:FindObj(activeIds, 30, 0)
            if rock then
                print("Mining crystal-flecked sandstone...")
                Interact:Object("Crystal-flecked sandstone", "Mine", 30)
                
                Slib:SleepUntil(function()
                    return Inventory:IsFull() or Slib:FindObj(depletedId, 30, 0)
                end, 120, 600)

                if Inventory:IsFull() then
                    print("Inventory full while mining. Processing and banking.")
                    interactGlassmachine()
                    processCrystalglass()
                    bankingIthell()
                    return
                elseif Slib:FindObj(depletedId, 30, 0) then
                    print("Crystal-flecked sandstone depleted. Processing and banking.")
                    interactGlassmachine()
                    processCrystalglass()
                    bankingIthell()
                    ACTIVITY_STATUS.mineCrystalsandstone = false
                    return
                end
    else
        print("No sandstone found nearby. Skipping.")
        ACTIVITY_STATUS.mineCrystalsandstone = false
        return
end

        end
    end
    print("Not near mining or processing location. Teleporting to Ithell.")
    CrystalSeedTeleport("8") -- Ithell
    bankingIthell()
end

--
-- CRYSTAL- FLECKED SANDSTONE ENDS
--

local function claimLupe()
    API.DoAction_Ability("Underworld Grimoire 4", 1, API.OFF_ACT_GeneralInterface_route)
    UTILS.randomSleep(2000)
    API.DoAction_Ability("Underworld Grimoire 4", 4, API.OFF_ACT_GeneralInterface_route)
    UTILS.randomSleep(4000)
    Interact:NPC("Lupe", "Collect free supplies")
    waitForChatbox()
    ACTIVITY_STATUS.claimLupe = false
end

local function dreamofiaia()

    if DialogBoxIsOpen() then
        Slib:Info("Dialog box open. Selecting option.")
        OptionSelector(DialogOptions)
        Slib:RandomSleep(500, 700, "ms")
        Interact:Object("Apothecary", "Mix tinctures", 20)

        while animCheck() do
            print("Mixing tinctures...") 
            API.RandomSleep2(5000, 100, 200)
        end
        ACTIVITY_STATUS.dreamofiaia = false

    elseif CheckObject({28961}, 50, {1}) then
    
        local obj = CheckObject({28961}, 50, {1})

        if obj then
            local coords = obj.Tile_XYZ
            
            local targetX = math.floor(coords.x)
            local targetY = math.floor(coords.y)
            local targetZ = math.floor(coords.z)

            Slib:Info("Object found. Moving to: " .. targetX .. ", " .. targetY .. ", " .. targetZ)
            
            Slib:MoveTo(targetX, targetY + 1, 0)

            Interact:NPC("Apothecary", "Contribute all resources")
            Slib:SleepUntil(function()
                return DialogBoxIsOpen()
            end, 10, 100)
        end

    elseif Slib:IsPlayerInArea(5515, 2975, 1, 5) then
        Interact:Object("Hibernation pod", "Enter", 20)
        Slib:RandomSleep(5000, 6000, "ms")

    else
        API.DoAction_Ability("Enriched pontifex shadow ring", 4, API.OFF_ACT_GeneralInterface_route)
        Slib:RandomSleep(5000, 6000, "ms")
    end
end

local function bankingDeepsea()
    API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route2, {110591}, 50) -- QUICKLOAD
    API.RandomSleep2(1000, 600, 600)
end

local function deepseaTeleport()
    API.DoAction_Ability("Grace of the elves", 1, API.OFF_ACT_GeneralInterface_route)
    while animCheck() do
        API.RandomSleep2(50, 100, 200)
    end
    bankingDeepsea()
end

local function SlimeTeleport()
    API.DoAction_Ability("Morytania legs 4", 3, API.OFF_ACT_GeneralInterface_route)
    while animCheck() do
        API.RandomSleep2(50, 100, 200)
    end
end

local function runSlime()
    while true do
        
        local teleportsLeft = 20 - (API.VB_FindPSettinOrder(3089).state >> 25)
        print(teleportsLeft)
        if teleportsLeft <= 0 then
            print("No teleports left. Stopping slime run.")
            break
        end

        SlimeTeleport()
        Interact:Object("Pool of Slime", "Use slime", 5)
        API.RandomSleep2(2000, 300, 1000)

        while not Inventory:IsFull() do
            API.RandomSleep2(200, 300, 600)
        end

        deepseaTeleport()
    end
    ACTIVITY_STATUS.slimeRunner = false
end

local function buyJatix() 

    LODESTONES.TAVERLEY.Teleport()
    clickRandomTile(2918,3427,2)
    UTILS.countTicks(4)
    UTILS.surge()
    clickRandomTile(2917,3428,2)
    UTILS.randomSleep(3000)
    UTILS.countTicks(5)
    UTILS.Bdive(randomizeDiveCoordinates(2917, 3426, 0, 2))
    UTILS.randomSleep(1000)

    Interact:NPC("Jatix", "Trade")

    waitForShopInterface()
    
         local Items = { 1, 3, 4, 5, 7, 9, 10}
        for _, Runes in ipairs(Items) do
            API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(100, 200, 300)
        end 
       API.KeyboardPress("Esc", 0, 50)
            UTILS.randomSleep(1000)
    ACTIVITY_STATUS.buyJatix = false
end


local function teleportMeilyr()
    API.DoAction_Ability("Attuned crystal teleport seed", 1, API.OFF_ACT_GeneralInterface_route)
    waitForTeleportSeedInterface()
    API.KeyboardPress("9", 50, 100)
    API.RandomSleep2(4000, 1200, 5500)
end

local function buyMeilyr() 

    teleportMeilyr()
    clickRandomTile(2234,3432,2)
    UTILS.randomSleep(3000)

    Interact:NPC("Lady Meilyr", "Open shop")

    waitForShopInterface()
    
        local Items = { 2, 4, 5, 6, 11, 12}
        for _, Runes in ipairs(Items) do
            API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(100, 200, 300)
        end 
       API.KeyboardPress("Esc", 0, 50)
            UTILS.randomSleep(1000) 
    ACTIVITY_STATUS.buyMeilyr = false
end

local function bankingFort()
    API.RandomSleep2(500, 300, 500)
    API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, {125115}, 50) -- Load last preset
    API.RandomSleep2(3000, 600, 1200)
    API.WaitUntilMovingEnds(1, 10)
end

local function buyFort() 

    LODESTONES.FORT_FORINTHRY.Teleport()
    clickRandomTile(3297,3568,2)
    UTILS.countTicks(3)
    UTILS.surge()
    clickRandomTile(3297,3568,2)
    UTILS.randomSleep(8000)
    bankingFort()
    --UTILS.randomSleep(1000)

    API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route3,{ 26134 },50) --Granny rowan
    waitForShopInterface()
    
         local Items = { 1, 3, 4, 5, 8, 10 }
        for _, Runes in ipairs(Items) do
            API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(100, 200, 300)
        end 
       API.KeyboardPress("Esc", 0, 50)
            UTILS.randomSleep(1000)
            
    bankingFort()
    UTILS.randomSleep(1000)
    ACTIVITY_STATUS.buyFort = false
end

local function doSupercompost()
    LODESTONES.CATHERBY.Teleport()
    Interact:NPC("Arhein", "Pineapples")
    waitForChatbox() 
    --API.RandomSleep2(600, 600, 600)
    API.KeyboardPress2(32, 0, 50)
    waitForArheinInput()
    API.RandomSleep2(600, 600, 600)
    API.KeyboardPress("4", 400, 50)
    API.KeyboardPress("0", 80, 50)
    API.RandomSleep2(600, 600, 600)
    API.KeyboardPress2(0x0D, 0, 50)

    API.RandomSleep2(600, 600, 600)
    clickRandomTile(2784,3464,2)
    API.RandomSleep2(9000, 600, 1200)

    API.DoAction_Inventory1(2115,0,0,API.OFF_ACT_Bladed_interface_route)
    API.RandomSleep2(1000, 100, 400)
    API.DoAction_Object1(0x24,API.OFF_ACT_GeneralObject_route00,{ 12229 },20)
    waitForCompost()
    API.RandomSleep2(1000, 600, 600)
    API.KeyboardPress("4", 800, 50)
    API.KeyboardPress("0", 50, 50)
    API.RandomSleep2(600, 600, 600)
    API.KeyboardPress2(0x0D, 0, 50)
    API.RandomSleep2(1200, 600, 600)

    ACTIVITY_STATUS.doSupercompost = false
end

local function collectPotatocacti()

    UseFairyring()
    clickRandomTile(3233,3107,2)
    UTILS.Bdive(randomizeDiveCoordinates(3233, 3107, 0, 2))
    clickRandomTile(3232,3106,2)
    UTILS.randomSleep(1200)
    Interact:NPC("Weird Old Man", "Collect potato cacti")
    waitForChatbox()
    UTILS.randomSleep(1200)

    ACTIVITY_STATUS.collectPotatocacti = false
end

local badRuneIDs = { [4698]=true,[4695]=true,[4694]=true,[4697]=true,[4699]=true,[4696]=true, [9075]=true }

local RuneInterface = {
    [554]  = {name="Fire Rune", interface=0x22a, slot=3},
    [555]  = {name="Water Rune", interface=0x22b, slot=1},
    [556]  = {name="Air Rune", interface=0x22c, slot=0},
    [557]  = {name="Earth Rune", interface=0x22d, slot=2},
    [558]  = {name="Mind Rune", interface=0x22e, slot=10},
    [559]  = {name="Body Rune", interface=0x22f, slot=11},
    [560]  = {name="Death Rune", interface=0x230, slot=16},
    [561]  = {name="Nature Rune", interface=0x231, slot=14},
    [562]  = {name="Chaos Rune", interface=0x232, slot=13},
    [563]  = {name="Law Rune", interface=0x233, slot=15},
    [564]  = {name="Cosmic Rune", interface=0x234, slot=12},
    [565]  = {name="Blood Rune", interface=0x235, slot=18},
    [566]  = {name="Soul Rune", interface=0x236, slot=19},
    [9075] = {name="Astral Rune", interface=0x2373, slot=17},
    [4698] = {name="Mud Rune"}, [4695] = {name="Mist Rune"},
    [4694] = {name="Steam Rune"}, [4697] = {name="Smoke Rune"},
    [4699] = {name="Lava Rune"}, [4696] = {name="Dust Rune"}
}

local nameToID = {}
for id, info in pairs(RuneInterface) do
    if info.name then nameToID[info.name] = id end
end

local function idToName(id)
    local info = RuneInterface[tonumber(id)]
    return info and info.name or ("Unknown Rune (" .. tostring(id) .. ")")
end

local function CapeOpen()
    return API.Compare2874Status(12, false)
end

local function PickBestRune(slotBestID, slotOtherIDs, usedRunes, badRuneIDs, idToName, excludeRuneName)
    local candidates = {}

    if slotBestID then
        table.insert(candidates, { id = tonumber(slotBestID), priority = 1 })
    end
    for _, alt in ipairs(slotOtherIDs or {}) do
        if alt.id then
            table.insert(candidates, { id = tonumber(alt.id), priority = 2 })
        end
    end
    table.sort(candidates, function(a, b) return a.priority < b.priority end)

    for _, c in ipairs(candidates) do
        local name = idToName(c.id)
        if name and not badRuneIDs[c.id] and not usedRunes[name] and name ~= excludeRuneName then
            usedRunes[name] = true
            print(string.format("[DEBUG] PickBestRune: Selected %s (ID: %d)", name, c.id))
            return name
        end
    end

    print("[DEBUG] PickBestRune: No valid rune found, all bad, used, or excluded")
    return "Unknown Rune"
end

local function GetPersonalCapeRune(capeItemID, capeInterfaceIDs, badRuneIDs, nameToID)
    if not Equipment:Contains(capeItemID) then
        print("[DEBUG] RuneCrafting cape not in inventory")
        return nil
    end

    API.DoAction_Interface(0xffffffff,0x2626,3,1464,15,1,API.OFF_ACT_GeneralInterface_route) --Activate cape ability
    UTILS.SleepUntil(CapeOpen, 5, "RuneCrafting cape interface")
    API.RandomSleep2(2000, 1500, 100)

    local runeScan = API.ScanForInterfaceTest2Get(false, capeInterfaceIDs)
    if not runeScan or #runeScan == 0 or not runeScan[1].textids then
        print("[DEBUG] Scan failed, no rune found")
        return nil
    end

    local fullText = type(runeScan[1].textids) == "table"
        and table.concat(runeScan[1].textids, " ")
        or tostring(runeScan[1].textids)
    print("[DEBUG] Raw textids from cape:", fullText)

    if not fullText or fullText == "" then return nil end

    fullText = fullText:gsub("<br>", " "):gsub("%s+", " ")
    local personalRune = fullText:match("[Aa]re%s+([A-Za-z]+)%s*[Rr]unes")

    if not personalRune then
        print("[DEBUG] Could not extract rune from cape text")
        return nil
    end

    personalRune = personalRune:gsub("%s+", "")
    local runeKey = personalRune .. " Rune"
    local runeID = nameToID[runeKey]

    if runeID then
        if badRuneIDs[runeID] then
            print("[DEBUG] Cape rune is bad:", runeKey, "(ID:", runeID, ")")
            return nil
        else
            print("[DEBUG] Cape rune accepted:", runeKey, "(ID:", runeID, ")")
            return runeKey
        end
    else
        print("[DEBUG] Cape rune not in ID table, using raw name:", runeKey)
        return runeKey
    end
end

local function FetchVisWaxCombo(slot3Rune, badRuneIDs, nameToID, idToName, PickBestRune)
    local url = "https://runeguide.info/alt1/viswax/api/getVisWaxCombo.php"
    local response = Http:Get(url)
    local ok, data = pcall(API.JsonDecode, response and response.body or "{}")
    if not ok or not data or not data["Wiki"] then
        print("[DEBUG] Failed to get VisWax combo data or malformed JSON")
        return nil, "Unknown"
    end

    local today, used = data["Wiki"], {}
    local function num(v) return v and tonumber(v) or nil end

    local slot1_bestID = num(today.slot1_best)
    local slot1_other = today.slot1_other or {}
    print("[DEBUG] Slot 1 best ID:", slot1_bestID)
    local slot1 = PickBestRune(slot1_bestID, slot1_other, used, badRuneIDs, idToName, slot3Rune)
    print("[DEBUG] Slot 1 chosen:", slot1)

    local slot2_sets = {
        {best = num(today.slot2_1_best), others = today.slot2_1_other or {}},
        {best = num(today.slot2_2_best), others = today.slot2_2_other or {}},
        {best = num(today.slot2_3_best), others = today.slot2_3_other or {}}
    }

    local slot2_bestRune, highestVis = "Unknown Rune", -1
    for i, s in ipairs(slot2_sets) do
        if s.best then
            local runeName = PickBestRune(s.best, s.others, used, badRuneIDs, idToName, slot3Rune)
            local maxVis = 0
            for _, alt in ipairs(s.others) do
                if alt.vis and alt.vis > maxVis then maxVis = alt.vis end
            end
            print(string.format("[DEBUG] Slot2_%d candidate: %s (maxVis: %d)", i, runeName, maxVis))
            if maxVis > highestVis then
                highestVis = maxVis
                slot2_bestRune = runeName
            end
        end
    end

    print(string.format("[DEBUG] Final slot 2 chosen: %s (vis: %d)", slot2_bestRune, highestVis))
    return {slot1, slot2_bestRune}, today.source or "Wiki"
end

local function InputCombo(combo, nameToID, RuneInterface)
    print("[DEBUG] Entering Vis Wax combo...")
    for _, runeName in ipairs(combo) do
        local runeID, info = nameToID[runeName], RuneInterface[nameToID[runeName]]
        if info and info.interface then
            API.DoAction_Interface(0xffffffff, info.interface, 1, 1532, 13, info.slot, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(800, 600, 100)
        else
            print("[DEBUG] Unknown interface for rune:", runeName)
        end
    end
    API.DoAction_Interface(0x24, 0xffffffff, 1, 1532, 42, -1, API.OFF_ACT_GeneralInterface_route)
    print("[DEBUG] Vis Wax combo entered successfully!")
end

local function isOpen()
    return API.Compare2874Status(40, false) or API.Compare2874Status(18, false) or API.Compare2874Status(24, false) 
end

local function Viswax()
    local capeID, hoodID = 9766, 22332
    local manualThirdRune = "Air Rune"
    local capeInterfaceIDs = { {1186, 2, -1, 0}, {1186, 3, -1, 0} }

    if not (Equipment:Contains(capeID) and Equipment:Contains(hoodID)) then
        print("[DEBUG] Missing cape or hood, stopping.")
        API.Write_LoopyLoop(false)
        return
    end

    print("Cape and hood found, continuing...")

    API.DoAction_Interface(0xffffffff,0x573c,4,1464,15,0,API.OFF_ACT_GeneralInterface_route) --Teleport to wizards' tower with wicked hood
    API.RandomSleep2(1200, 800, 100)
    UTILS.SleepUntil(function() return API.PInArea(3109, 10, 3156, 10, 0) end, 5, "Wizards' Tower")
    API.RandomSleep2(1200, 800, 100)

    API.DoAction_Object1(0x39, API.OFF_ACT_GeneralObject_route0, {79518}, 50)
    UTILS.SleepUntil(function() return API.PInArea(1697, 10, 5463, 10, 0) end, 10, "Goldberg machine area")

    local slot3Rune = GetPersonalCapeRune(capeID, capeInterfaceIDs, badRuneIDs, nameToID)
    if not slot3Rune then
        print("[DEBUG] No personal rune detected; using manual:", manualThirdRune)
        slot3Rune = manualThirdRune
    end

    local combo, source = FetchVisWaxCombo(slot3Rune, badRuneIDs, nameToID, idToName, PickBestRune)
    table.insert(combo, slot3Rune)

    print("========== FINAL VISWAX COMBO ==========")
    for i, rune in ipairs(combo) do
        print(string.format("Slot %d → %s", i, rune))
    end
    print("========================================")

    API.DoAction_Object1(0x29, API.OFF_ACT_GeneralObject_route0, {92236}, 50)
    UTILS.SleepUntil(isOpen, 5, "Goldberg machine input interface")
    InputCombo(combo, nameToID, RuneInterface)

    ACTIVITY_STATUS.Viswax = false
end

-----------------------------------------------------
------------- ACTIVITY FUNCTIONS END ----------------
-----------------------------------------------------

API.Write_LoopyLoop(true)

while API.Read_LoopyLoop() do
    -- API.DoRandomEvents()

    if IsFirstRun then
        if not OnlyOnceSafetyChecks() then
            print("One-time safety checks failed. Stopping script.")
            API.Write_LoopyLoop(false)
            break
        end
        IsFirstRun = false
    end

    if ACTIVITY_STATUS.BABA_YAGA then
        buyBabaYaga()
    elseif ACTIVITY_STATUS.Yanille then
        buyMagesGuild()   
    elseif ACTIVITY_STATUS.Sarim then
        BuySarim()
    elseif ACTIVITY_STATUS.Void then
        BuyVoid()
    elseif ACTIVITY_STATUS.Viswax then   
        Viswax()
    elseif ACTIVITY_STATUS.Varrock then   
        BuyVarrock()
    elseif ACTIVITY_STATUS.AlKharid then   
        BuyAlkharid()
    elseif ACTIVITY_STATUS.ZamorakMage then
        BuyZamorakMage()  
    elseif ACTIVITY_STATUS.Magebank then
        BuyMagebank() 
    elseif ACTIVITY_STATUS.Ooglog then
        BuyOoglog() 
    elseif ACTIVITY_STATUS.mineRedsandstone then
        mineRedsandstone()
    elseif ACTIVITY_STATUS.collectPotatocacti then
        collectPotatocacti()
    elseif ACTIVITY_STATUS.mineCrystalsandstone then
        mineCrystalsandstone()
    elseif ACTIVITY_STATUS.claimLupe then
        claimLupe()
    elseif ACTIVITY_STATUS.doSupercompost then
        doSupercompost()
    elseif ACTIVITY_STATUS.buyJatix then
        buyJatix()
    elseif ACTIVITY_STATUS.buyMeilyr then
        buyMeilyr()
    elseif ACTIVITY_STATUS.buyFort then
        buyFort()
    elseif ACTIVITY_STATUS.slimeRunner then
        runSlime()
    elseif ACTIVITY_STATUS.dreamofiaia then
        dreamofiaia()
    else        
        print("Finished all activies")
        API.Write_LoopyLoop(false)
    end
end