local API = require("api")
local UTILS = require("utils")
local LODESTONES = require("lodestones")
local BANK = require("bank")
local AURAS = require("deadAuras")
local Slib = require("Slib")

Write_fake_mouse_do(false)

local ACTIVITY_STATUS = {

    AL_KHARID = true,
    FALADOR = true,
    MORYTANIA = true,
    CATHERBY = true,
    ARDOUGNE = true,
    TROLLHEIM = true,
    PRIFFDINAS = true,
    WILDERNESS = true,   
}

local HERB_NAMES = {
    "Guam", "Marrentill", "Tarromin", "Harralander", "Ranarr", "Toadflax",
    "Irit", "Avantoe", "Wergali", "Kwuarm", "Snapdragon", "Cadantine",
    "Lantadyme", "Dwarf weed", "Torstol", "Fellstalk", "Bloodweed", 
    "Arbuck", "Spirit weed" 
}

local IDS = {
    BANK_CHEST = {114750},
    HERB = {12172},
    HERB_PATCH_ALL = {8139, 8140, 8141, 8142, 8132, 7840, 18818},
    PICK_HERB = {8143, 18826, 133173, 133178},
    READY_HERB = {1882, 8139, 8140, 8141, 8142},
    DISEASED_HERB = {8144, 8145, 8146, 8147},
    PICK_SHROOM = {17795, 17796, 17797, 17798, 17799, 17800, 17801, 17802, 17803},
    PATCH_HERB = {7840, 8139, 8140, 8141, 8142, 18822, 18823, 18824, 18825, 133170, 133171, 133172, 133175, 133176, 133177},
    SHROOM_PATCH = {8311},
    PATCH_WEED = {8134, 8135, 8136, 8312, 8313, 8314, 8133, 8138, 18818, 18819, 18820, 18821},
    PLANT_CURE = {6036},
    HERB_SEED = {5296, 5293, 5292, 5294, 5295, 12176, 5297, 5298, 5299, 5300, 5301, 5302, 5303, 14870, 5304, 21621, 48201, 37952},
    MUSHROOOM_SEED = {21620, 5282},
    LEPRECHAUN = {3021, 3343, 4965, 7557, 7569, 8000, 20110},
    GRIMY = {199, 201, 203, 205, 207, 209, 211, 213, 215, 217, 219, 2485, 3049, 3051, 12174, 14836, 21626, 37975, 48243},
    TROLLHEIM_CAVE = {34395},
    TROLLHEIM_LADDER = {18834},
    WILDERNESS_SWORD = {37904, 37905, 37906, 37907}
}

local herbID = {
    GUAM = 199,
    MARRENTILL = 201,
    TARROMIN = 203,
    HARRALANDER = 205,
    RANARR = 207,
    IRIT = 209,
    AVANTOE = 211,
    KWUARM = 213,
    CADANTINE = 215,
    DWARF_WEED = 217,
    TORSTOL = 219,
    LANTADYME = 2485,
    TOADFLAX = 3049,
    SNAPDRAGON = 3051,
    SPIRIT_WEED = 12174,
    BLOODWEED = 37975,
}

local seedID = {
    GUAM = 5291,
    MARRENTILL = 5292,
    TARROMIN = 5293,
    HARRALANDER = 5294,
    RANARR = 5295,
    IRIT = 5297,
    AVANTOE = 5298,
    KWUARM = 5299,
    CADANTINE = 5301,
    DWARF_WEED = 5303,
    TORSTOL = 5304,
    LANTADYME = 5302,
    TOADFLAX = 5296,
    SNAPDRAGON = 5300,
    SPIRIT_WEED = 12176,
    FELLSTALK = 21621,
    BLOODWEED = 37952,
    ARBUCK = 48201
}

local cleanHerbID = {
    GUAM = 249,
    MARRENTILL = 251,
    TARROMIN = 253,
    HARRALANDER = 255,
    RANARR = 257,
    IRIT = 259,
    AVANTOE = 261,
    KWUARM = 263,
    CADANTINE = 265,
    DWARF_WEED = 267,
    TORSTOL = 269,
    LANTADYME = 2481,
    TOADFLAX = 2998,
    SNAPDRAGON = 3000,
    SPIRIT_WEED = 12172,
    BLOODWEED = 37953,
    FELLSTALK = 21624,
    ARBUCK = 48211
}

local OtherIDsNeededForStuff = {
    ["AttunedCrystalSeed"] = 39784,
    ["TrollheimTeleport"] = 35032,
    ["WarsTeleport"] = 35042,
    ["WildernessSword"] = 37907,
    ["GraceOfTheElves"] = 44550,
}

local Interfaces = {
    ["Teleports"] = { { 720, 2, -1, 0 }, { 720, 17, -1, 2 } },
    ["ChatOptions"] = { { 1188,5,-1,0 }, { 1188,4,-1,0 } },
    ["FairyRing"] = { { 784, 0, -1, 0 }, { 784, 56, -1, 2 } },
}

----------------------------------------------------------------------
-- USER CONFIGURATION
----------------------------------------------------------------------
-- How many seeds do you want to plant per patch? 
-- (Options: "1", "2", "4", "7", "10")
local CONFIG_SEED_AMOUNT = "1"

-- Global variable to store the detected seed name later
local selectedSeed = nil 

----------------------------------------------------------------------
-- INTERNAL SETTINGS (DO NOT EDIT)
----------------------------------------------------------------------
local plantOption = 0x31 -- Default to 1
local plantOptionLookup = {
    ["1"]  = 0x31,
    ["2"]  = 0x32,
    ["4"]  = 0x33,
    ["7"]  = 0x34,
    ["10"] = 0x35
}

if plantOptionLookup[CONFIG_SEED_AMOUNT] then
    plantOption = plantOptionLookup[CONFIG_SEED_AMOUNT]
end

local function AutoDetectSeed()
    print("Auto-detecting seed from inventory...")
    
    for name, id in pairs(seedID) do
        if name ~= "BLOODWEED" and Inventory:Contains(id) then
            print("Seed Detected: " .. name .. " (ID: " .. id .. ")")
            return name
        end
    end
    
    return nil -- No valid main seeds found
end

local function InterfaceIsOpen(interfaceName)
    return #API.ScanForInterfaceTest2Get(true, Interfaces[interfaceName]) > 0
end

local function DialogBoxIsOpen()
    local VB1 = tonumber(API.VB_FindPSettinOrder(2874).state)
    if VB1 == 12 then
        return true
    else
        return false
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

local function CrystalSeedTeleport(key)
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["AttunedCrystalSeed"]) then
        Slib:Error("Attuned crystal seed not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Attuned crystal seed not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    local AttunedCrystalSeed = API.GetABs_id(OtherIDsNeededForStuff["AttunedCrystalSeed"])
    API.DoAction_Ability_Direct(AttunedCrystalSeed, 1, API.OFF_ACT_GeneralInterface_route) --Lletya
    Slib:SleepUntil(function()
        return InterfaceIsOpen("Teleports")
    end, 6, 100)

    if InterfaceIsOpen("Teleports") then
        Slib:TypeText(key)
        Slib:RandomSleep(1000, 1200, "ms")
    end
    Slib:RandomSleep(3700, 3900, "ms")
end

local function UseSpellbookTeleport(location)

    local locations = {
        ["ManorFarm"] = "202",
        ["TrollheimHerbPatch"] = "148",
        ["Catherby"] = "140",
    }

    local destination = locations[location]

    --[[ if API.VB_FindPSettinOrder(3705, 1).state ~= 270729216 then
        Slib:Error("Teleports tab not visible. Halting script.")
        ReasonForStopping = "Teleports tab not visible."
        API.Write_LoopyLoop(false)
        return false
    end ]]

    API.DoAction_Interface(0xffffffff,0xffffffff,1,1461,1,destination,API.OFF_ACT_GeneralInterface_route)
    Slib:RandomSleep(4600, 5200, "ms")
end

local function WildernessSwordTeleport(key1, key2)
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["WildernessSword"]) then
        Slib:Error("Wilderness sword not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Wilderness sword not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    local WildernessSword = API.GetABs_id(OtherIDsNeededForStuff["WildernessSword"])
    API.DoAction_Ability_Direct(WildernessSword, 2, API.OFF_ACT_GeneralInterface_route) --Rub
    Slib:SleepUntil(function()
        return InterfaceIsOpen("Teleports")
    end, 6, 100)

    if InterfaceIsOpen("Teleports") then
        Slib:TypeText(key1)
        Slib:RandomSleep(600, 1200, "ms")
        Slib:TypeText(key2)
    end   
    Slib:RandomSleep(4000, 4200, "ms") 
end

local function swapToLunars()
    API.DoAction_Inventory1(9763, 0, 3, API.OFF_ACT_GeneralInterface_route)
    Slib:SleepUntil(function()
        return InterfaceIsOpen("ChatOptions")
    end, 6, 100)
    API.KeyboardPress("2", 100, 200)
end

local function swapToNormals()

    if not Slib:IsPlayerAtCoords(3299, 10131, 0) then
        Slib:MoveTo(3299, 10131, 0)
    end
    API.DoAction_Inventory1(9763, 0, 3, API.OFF_ACT_GeneralInterface_route)
    Slib:SleepUntil(function()
        return InterfaceIsOpen("ChatOptions")
    end, 6, 100)
    API.KeyboardPress("1", 100, 200)
    Slib:RandomSleep(1000, 1200, "ms")
    print("Swapped to normal spellbook")
end

local function isOpen()
    return API.Compare2874Status(13, false)
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

local function CheckForSeeds()

    if Inventory:Contains(IDS.HERB_SEED) then
        print("Seeds detected")
        return true
    else
        print("No herb seeds found in inventory!")
        return false
    end
end

local function isInventoryOpen()
    if API.VB_FindPSettinOrder(3039).state == 1 then
        print("Inventory is open")
        return true
    else
        print("Open the damn inventory")
        return false
    end
end

-----------------------------
-- TELEPORT FUNCTIONS START
-----------------------------
local function teleportFalador()
    if Inventory:Contains(19760)  then
        print("Teleporting to Cabbage Field")
        API.DoAction_Inventory1(19760,0,7,API.OFF_ACT_GeneralInterface_route2)
        API.RandomSleep2(6000, 100, 600)
    else
        print("Could not find Explorer's ring 4")
    end
end

local function teleportMorytania()
    if Inventory:Contains(4251) then
        print("Teleporting to Ectophuntus")
        API.DoAction_Inventory1(4251,0,1,API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(7500, 100, 600)
    else
        print("Could not find Ectophial")
    end
end

local function teleportCatherby()
    LODESTONES.CATHERBY.Teleport()
end

local function teleportAl_Kharid()
    if Inventory:Contains(54004) then
        print("Teleporting to Garden of Kharid")
        API.DoAction_Inventory1(54004,0,1,API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(5000, 100, 600)
    else
        print("Could not find Mystical sand seed")
    end
end

local function WarsTeleport()
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["WarsTeleport"]) then
        Slib:Error("Wars teleport not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Wars teleport not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    if Slib:IsPlayerInArea(3294, 10127, 0, 20) then
        return
    end

    local WarsTeleport = API.GetABs_id(OtherIDsNeededForStuff["WarsTeleport"])
    API.DoAction_Ability_Direct(WarsTeleport, 1, API.OFF_ACT_GeneralInterface_route) --Rub
    Slib:SleepUntil(function()
        return Slib:IsPlayerInArea(3294, 10127, 0, 20)
    end, 6, 100)
    Slib:RandomSleep(3000, 3500, "ms")
end

-----------------------------
-- TELEPORT FUNCTIONS END
-----------------------------

-----------------------------
-- FARMING FUNCTIONS START
-----------------------------

local function GetReadyHerbName()
    -- Scan for any object matching our list of names
    local objects = API.ReadAllObjectsArray({0}, {-1}, HERB_NAMES)
    
    for _, obj in ipairs(objects) do
        local distance = math.floor(obj.Distance)
        -- Ensure it's close and actually ready to harvest
        if distance < 20 and obj.Action == "Pick" then
            return obj.Name -- Return the string name (e.g., "Fellstalk")
        end
    end
    return nil
end

local function foundWeeds()
    local distance = 20
    local weeds = API.GetAllObjArray1(IDS.PATCH_WEED, distance, {0})
    if #weeds > 0 then
        for _, v in ipairs(weeds) do
            if v.Action == "Rake" then
                return true
            end
        end
    end
    return false
end

--[[ local function foundHerbs()
    -- Read all objects that match the names in HERB_NAMES
    local objects = API.ReadAllObjectsArray({0}, {-1}, HERB_NAMES)
    
    for _, obj in ipairs(objects) do
        if obj.Action == "Inspect" then
            return true
        end
    end
    return false
end

-- Check for READY herbs (Action: "Pick")
local function foundReadyHerbs()
    local objects = API.ReadAllObjectsArray({0}, {-1}, HERB_NAMES)
    
    for _, obj in ipairs(objects) do
        if obj.Action == "Pick" then
            return true
        end
    end
    return false
end

local function foundDiseasedHerbs()
    local distance = 20
    local herbs = API.GetAllObjArray1(IDS.DISEASED_HERB, distance, {0})
    if #herbs > 0 then
        for _, v in ipairs(herbs) do
            return true
        end
    end
    return false
end ]]

local function foundHerbs()
    local distance = 20
    
    -- API.ReadAllObjectsArray takes a TABLE of names as the 3rd argument
    local objects = API.ReadAllObjectsArray({0}, {-1}, HERB_NAMES)
    
    for _, obj in ipairs(objects) do
        local dist = math.floor(obj.Distance) -- Get distance
        
        if dist <= distance then
            if obj.Action == "Inspect" then
                return true
            end
        end
    end
    return false
end

-- Returns TRUE if a herb is found that is READY (Action == "Pick")
local function foundReadyHerbs()
    local distance = 20
    local objects = API.ReadAllObjectsArray({0}, {-1}, HERB_NAMES)
    
    for _, obj in ipairs(objects) do
        local dist = math.floor(obj.Distance)
        
        if dist <= distance then
            if obj.Action == "Pick" then
                return true
            end
        end
    end
    return false
end

local function clearWeeds()
    print("Action: Raking weeds...")
    API.DoAction_Object1(0x29, API.OFF_ACT_GeneralObject_route0, IDS.PATCH_WEED, 50)
    API.RandomSleep2(1200, 200, 400)
    Slib:SleepUntil(function() return not animCheck() end, 10, 200)
end

local function clearDiseased()
    print("Action: Clearing disease...")
    if API.Check_Dialog_Open() then
        API.KeyboardPress2(0x31, 60, 100)
    else
        API.DoAction_Object1(0x29, API.OFF_ACT_GeneralObject_route2, IDS.DISEASED_HERB, 50)
    end
    API.RandomSleep2(2000, 200, 600)
end

local function noteHerbs()
    
    for _, cherb in pairs(cleanHerbID) do
        if Inventory:Contains(cherb) then
            print("Action: Noting herbs...")
            API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route3, IDS.LEPRECHAUN, 50)
            
            Slib:SleepUntil(function()
                return DialogBoxIsOpen()
            end, 6, 100)
            return
        end
    end
end

local function harvestHerbs()
    print("Action: Harvesting...")
    
    if Inventory:IsFull() then
        print("Inventory full! Noting herbs first.")
        noteHerbs()
        return
    end

    local herbToPick = GetReadyHerbName()

    if herbToPick then
        print("Targeting herb: " .. herbToPick)
        
        Interact:Object(herbToPick, "Pick", 20)
        Slib:SleepUntil(function() return not animCheck() end, 26, 600)
    else
        print("Error: ready herb detected previously, but name could not be resolved.")
    end
end

local function plantSeeds(forcedSeedID) 
    print("Action: Planting seeds...")
    
    local seed = forcedSeedID or seedID[selectedSeed]

    if not Inventory:Contains(seed) then
        print("SKIPPING: Run out of seeds (ID: " .. seed .. ")!")
        return false
    end

    -- 2. Select Seed
    API.DoAction_Inventory1(seed, 0, 0, API.OFF_ACT_Bladed_interface_route)
    API.RandomSleep2(600, 50, 150)

    -- 3. Click Patch
    API.DoAction_Object1(0x24, API.OFF_ACT_GeneralObject_route00, IDS.HERB_PATCH_ALL, 50)

    local dialogOpen = Slib:SleepUntil(function()
        return InterfaceIsOpen("Teleports") 
    end, 5, 100)

    if dialogOpen then
        API.KeyboardPress2(plantOption, 60, 100)
        print("Selected plant option.")
        API.RandomSleep2(2000, 200, 400)
    else
        print("Failed to open seed menu (blocked by weeds/disease?)")
    end
end

-- Added 'forcedSeedID' parameter
local function processPatch(forcedSeedID)
    print("--- Inspecting Patch Status ---")

    while API.Read_LoopyLoop() do 

        if foundReadyHerbs() then
            harvestHerbs()

        elseif foundWeeds() then
            clearWeeds()

        elseif foundHerbs() then
            print(">>> Success: Herbs are growing. Patch complete.")
            break 

        else
            -- Attempt to plant
            local success = plantSeeds(forcedSeedID)
            -- If plantSeeds returned false (no seeds left), we break the loop
            if not success then
                print("No seeds available for this patch. Moving to next activity.")
                break
            end
        end
        API.RandomSleep2(600, 100, 200)
    end
end

-----------------------------
-- FARMING FUNCTIONS END
-----------------------------

-----------------------------
-- RUNNING FUNCTIONS START
-----------------------------

local function doAlkharid()

    while not Slib:IsPlayerInArea(3320, 3307, 0, 20) and API.Read_LoopyLoop() do
        teleportAl_Kharid()
    end

    processPatch()
    ACTIVITY_STATUS.AL_KHARID = false
end

local function doFalador()
    teleportFalador()
    Slib:MoveTo(Slib:RandomNumber(3056, 1, 1), Slib:RandomNumber(3310, 1, 1), 0)
    processPatch()
    ACTIVITY_STATUS.FALADOR = false
end

local function doMorytania()
    teleportMorytania()
    Slib:MoveTo(Slib:RandomNumber(3610, 1, 1), Slib:RandomNumber(3534, 1, 1), 0)
    processPatch()
    ACTIVITY_STATUS.MORYTANIA = false
end

local function doCatherby()
    UseSpellbookTeleport("Catherby")
    --Slib:MoveTo(Slib:RandomNumber(2794, 1, 1), Slib:RandomNumber(3461, 1, 1), 0)
    processPatch()
    ACTIVITY_STATUS.CATHERBY = false
end

local function doArdougne()
    UseSpellbookTeleport("ManorFarm")
    processPatch()
    ACTIVITY_STATUS.ARDOUGNE = false
end

local function doTrollheim()
    UseSpellbookTeleport("TrollheimHerbPatch")
    processPatch()
    ACTIVITY_STATUS.TROLLHEIM = false
end

local function doPriffdinas()
    CrystalSeedTeleport("5")
    processPatch()
    ACTIVITY_STATUS.PRIFFDINAS = false
end

local function doWilderness()

    while not Slib:IsPlayerInArea(3142, 3828, 0, 20) and API.Read_LoopyLoop() do
        WildernessSwordTeleport("1","2")
    end

    local bloodweedSeed = 37952

    if Inventory:Contains(bloodweedSeed) then
        print("Bloodweed seed found! Overriding plant config.")
        processPatch(bloodweedSeed)
    else
        processPatch()
    end
    ACTIVITY_STATUS.WILDERNESS = false
end

local function LoadPreset(PresetNumber)
    if not Slib:IsPlayerInArea(3294, 10127, 0, 20) then 
        return 
    end

    print("Opening Bank to load preset...")
    Interact:Object("Bank chest", "Use", 20)
    
    Slib:SleepUntil(function()
        return BANK:IsOpen()
    end, 6, 100)

    BANK:LoadPreset(PresetNumber)
    Slib:RandomSleep(1200, 1500, "ms")
end

local prayIDs = {
    [26041] = 13, -- Deflect Magic
    [26044] = 14, -- Deflect Missiles
    [26040] = 15, -- Deflect Melee
    [30745] = 16, -- Deflect Necromancy
    [26033] = 35, -- Soul Split
    [26019] = 37, -- Turmoil
    [26020] = 38, -- Anguish
    [26021] = 39, -- Torment
    [30771] = 40  -- Sorrow
}

local function DisablePray()

    local currentBuffs = API.Buffbar_GetAllIDs()

    if currentBuffs then
        for i = 1, #currentBuffs do
            local buff = currentBuffs[i]
            
            if buff and buff.id and prayIDs[buff.id] then
                
                local slotId = prayIDs[buff.id]
                print("Disabling prayer " .. buff.id .. " using slot " .. slotId)
                API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1458, 40, slotId, API.OFF_ACT_GeneralInterface_route)
                API.RandomSleep2(100, 200, 100) 
            end
        end
    end

    if API.GetPrayPrecent() < 100 and Slib:IsPlayerInArea(3294, 10127, 0, 20) then
        Interact:Object("Altar of War", "Pray", 20)
        Slib:SleepUntil(function()
            return not API.ReadPlayerMovin() and not API.CheckAnim(20)
        end, 10, 600)
    end
end

if not isInventoryOpen() then
    API.Write_LoopyLoop(false)
end

local function OnlyOnceSafetyChecks()
    
    if Slib:GetSpellBook() ~= "Lunar" then
        swapToLunars()
    end

    if goteporterCheck() then
        API.DoAction_Ability("Grace of the elves", 6, API.OFF_ACT_GeneralInterface_route)
        print("Porters disabled.")
    end

    if AURAS.isAuraEquipped() then
        print("Another aura is active. Forcing Resourceful activation.")
        AURAS.GREENFINGERS:activate(true)
    else
        print("No aura equipped. Activating Resourceful normally.")
        AURAS.GREENFINGERS:activate(false)
    end

    return true
end

API.Write_LoopyLoop(true)

if not Slib:IsPlayerInArea(3300, 10132, 0, 50) then
    print("Teleporting to War's Retreat...")
    WarsTeleport()
end

DisablePray()
LoadPreset(6)
selectedSeed = AutoDetectSeed()

if selectedSeed == nil then
    print("No supported herb seeds found in preset! Stopping script.")
    API.Write_LoopyLoop(false)
elseif not OnlyOnceSafetyChecks() then
    print("Safety checks failed.")
    API.Write_LoopyLoop(false)
else
    print("Setup complete. Planting " .. CONFIG_SEED_AMOUNT .. " x " .. selectedSeed)
end

while API.Read_LoopyLoop() do

    if ACTIVITY_STATUS.AL_KHARID then
        doAlkharid()
    elseif ACTIVITY_STATUS.MORYTANIA then
        doMorytania()
    elseif ACTIVITY_STATUS.FALADOR then
        doFalador()
    elseif ACTIVITY_STATUS.CATHERBY then
        doCatherby()
    elseif ACTIVITY_STATUS.ARDOUGNE then
        doArdougne()
    elseif ACTIVITY_STATUS.TROLLHEIM then
        doTrollheim()
    elseif ACTIVITY_STATUS.PRIFFDINAS then
        doPriffdinas()
    elseif ACTIVITY_STATUS.WILDERNESS then
        doWilderness()  
    else        
        print("Finished all activies")
        WarsTeleport()
        swapToNormals()
        --API.Write_LoopyLoop(false)
        break
    end
end
