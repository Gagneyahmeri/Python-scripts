local API = require("api")
local UTILS = require("utils")
local Slib = require("slib") -- Ensure Slib is loaded
local BANK = require("bank")

API.Write_fake_mouse_do(false)

----------------------------------------------------------------------
-- USER CONFIGURATION
----------------------------------------------------------------------
local ENABLE_HERB_RUNS = true        -- Set to false to disable Herb Runs
local ENABLE_WILDERNESS_EVENTS = true -- Set to false to disable Wildy Events

local WOODCUTTING_PRESET = 15  -- Your Woodcutting Preset
local EVENT_PRESET = 4         -- Your Event/Herb Preset

-- IDs
local logsID = 58250
local eternalMagicBranchID = 58147
local heediID = 31499

-- Areas 
local trees = WPOINT.new(2330, 3586, 0)

-- Event & Herb Run Variables
EventTargetTimestamp = nil

local NextHerbRunTimestamp = 0 
local HERB_RUN_INTERVAL = 80 -- Minutes

local OtherIDsNeededForStuff = {
    ["WildernessSword"] = 37907,
    ["WarsTeleport"] = 35042,
    ["EnhancedExcalibur"] = 36619
}

----------------------------------------------------------------------
-- HELPER FUNCTIONS (Teleport, Bank, Time)
----------------------------------------------------------------------

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
    Slib:RandomSleep(1000, 2000, "ms")
end

local function LoadPreset(PresetNumber)
    --if not Slib:IsPlayerInArea(3294, 10127, 0, 50) then return end

    print("Opening Bank to load preset " .. PresetNumber)
    Interact:Object("Bank chest", "Use", 20)
    
    local opened = Slib:SleepUntil(function() return BANK:IsOpen() end, 8, 200)

    if opened then
        BANK:LoadPreset(PresetNumber)
        API.RandomSleep2(2400, 400, 600)
    else
        print("Bank did not open.")
    end
end

local function returnToTrees()
    if Slib:IsPlayerInArea(2330, 3592, 0, 30) then
        return 
    end

    if Slib:IsPlayerInArea(2295, 3552, 0, 20) then 
        Slib:MoveTo(Slib:RandomNumber(2322, 1, 1), Slib:RandomNumber(3586, 1, 1), 0)
    
    else 
        print("Not at location. Teleporting via Strand...")
        Slib:MemoryStrandTeleport()
        Slib:RandomSleep(1500, 2000, "ms")
        
        Slib:MoveTo(Slib:RandomNumber(2322, 1, 1), Slib:RandomNumber(3586, 1, 1), 0)
    end
end

local function GetMinutesToNextEvent()
    local url = "https://wilderness.spegal.dev/api/"
    local response = Http:Get(url)
    local ok, data = pcall(API.JsonDecode, response and response.body or "{}")

    if ok and data then
        local eventInfo = data[1] or data 
        if eventInfo and eventInfo.time then
            return tonumber(eventInfo.time)
        end
    end

    Slib:Error("Critical Error: Could not fetch time from API. Halting script.")
    API.Write_LoopyLoop(false)
    return nil
end

----------------------------------------------------------------------
-- EVENT MANAGERS
----------------------------------------------------------------------

local function ManageWildernessEvent(PresetAfterEvent)
    local currentTime = os.time()

    if EventTargetTimestamp == nil then
        local minutesLeft = GetMinutesToNextEvent()
        
        if minutesLeft then
            print("New Event Schedule Fetched! Next event in " .. minutesLeft .. " mins.")
            EventTargetTimestamp = currentTime + (minutesLeft * 60)
        end

    else
        local secondsUntilEvent = EventTargetTimestamp - currentTime

        if secondsUntilEvent < -60 then
            EventTargetTimestamp = nil
            return
        end
        
        if secondsUntilEvent <= 80 then
            print("Time to event < 1 mins! Starting WildernessFlashEvents...")
            
            WarsTeleport()
            Interact:Object("Bank chest", "Use", 20)
            Slib:SleepUntil(function() return BANK:IsOpen() end, 6, 100)
            
            local scriptLoaded, err = pcall(dofile, "C:\\Users\\pyrya\\MemoryError\\Lua_Scripts\\WildernessFlashEvents.lua")

            if not scriptLoaded then
                print("Error loading script: " .. err)
                EventTargetTimestamp = nil 
            else
                print("Wilderness Event finished. Returning to Woodcutting.")
                
                LoadPreset(PresetAfterEvent)
                print("Event complete. Fetching time for the NEXT Special event...")
                EventTargetTimestamp = nil 
                
            end
        end
    end
end

local function ManageHerbRuns(PresetAfterEvent)
    local currentTime = os.time()

    if currentTime >= NextHerbRunTimestamp then
        print("--- Starting Scheduled Herb Run ---")
        
        WarsTeleport()
        Interact:Object("Bank chest", "Use", 20)
        Slib:SleepUntil(function() return BANK:IsOpen() end, 6, 100)
        
        print("Loading herbRunner.lua...")
        local scriptLoaded, err = pcall(dofile, "C:\\Users\\pyrya\\MemoryError\\Lua_Scripts\\herbRunner.lua")

        if not scriptLoaded then
            print("ERROR loading herb script: " .. err)
            API.Write_LoopyLoop(false)
        else
            print("Herb run finished successfully.")
            NextHerbRunTimestamp = os.time() + (HERB_RUN_INTERVAL * 60)
            print("Next Herb Run scheduled for: " .. os.date("%H:%M:%S", NextHerbRunTimestamp))
            
            LoadPreset(PresetAfterEvent)
            returnToTrees()
        end
    end
end

----------------------------------------------------------------------
-- WOODCUTTING LOGIC
----------------------------------------------------------------------
API.SetMaxIdleTime(10)
startTime, afk  = os.time(), os.time() 

local function round(val, decimal)
    if decimal then
        return math.floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
    else
        return math.floor(val + 0.5)
    end
end

function formatNumber(num)
    if num >= 1e6 then
        return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3)
    else
        return tostring(num)
    end
end

local function checkXpIncrease() 
    local timeDiff = os.difftime(os.time(), afk)
    local checkTime = 500
    if timeDiff > checkTime then
        afk = os.time()
        local newXp = API.GetSkillXP("WOODCUTTING")
        if newXp == startXp then 
            API.logError("no xp increase")
            API.Write_LoopyLoop(false)
        else
            startXp = newXp
        end
    end
end

local function highlights()
    local highlight = API.GetAllObjArray1({ 8447 }, 25, {4})
    if highlight and #highlight > 0 then
        local hlTileX = (highlight[1].TileX / 512) - 1
        local hlTileY = (highlight[1].TileY / 512) - 1
        if not API.PInAreaW(WPOINT.new(hlTileX, hlTileY, 0), 2) then
            local walkToTile = WPOINT.new(hlTileX, hlTileY, 0)
            print("HL found walking there: " .. hlTileX .. " " .. hlTileY)
            API.RandomSleep2(800,1800,2400)
            if API.DoAction_Tile(walkToTile) then
                API.RandomSleep2(1200, 2000, 3000)
            end
        end
    end
end

local function ChopTree()
    if not API.CheckAnim(20) then
        local success = API.DoAction_Object_valid1(0x3b,API.OFF_ACT_GeneralObject_route0,{131907},50,true)
        if success then
            print("chopping tree")
            API.WaitUntilMovingandAnimEnds(10,2)
            if not API.CheckAnim(20) then
                local newTreeSuccess = API.DoAction_Object_valid1(0x3b,API.OFF_ACT_GeneralObject_route0,{131907},50,true)
                if newTreeSuccess then
                    print("Found a new tree to chop.")
                    API.WaitUntilMovingandAnimEnds(5,1)
                else
                    print("No more trees found nearby.")
                end
            end
        else
            print("Failed to initiate chopping action. Retrying...")
        end
    end
end

local function getWoodBoxItemCount(itemId)
    local containerItems = API.Container_Get_all(937) -- Retrieves all items in the box
    local itemCount = 0
    for _, itemData in pairs(containerItems) do
        if itemData.item_id == itemId then
            itemCount = itemCount + itemData.item_stack
        end
    end
    return itemCount
end

local function bank()
    print("Action: Banking")

    if not Slib:IsPlayerInArea(2295, 3552, 0, 20) then
        Slib:MemoryStrandTeleport()
        Slib:RandomSleep(3500, 4000, "ms")
    end

    if Slib:IsPlayerInArea(2295, 3552, 0, 20) then
        Interact:Object("Bank chest", "Use", 35)
        Slib:SleepUntil(function() return BANK:IsOpen() end, 6, 100)
        
        if BANK:IsOpen() then
            BANK:WoodBoxDepositLogs()
            LoadPreset(WOODCUTTING_PRESET)
        end
    end
end

local heediInterface = {
    InterfaceComp5.new( 847,0,-1,0),
    InterfaceComp5.new( 847,33,-1,0)
}
local function isHeediInterfacePresent()
    local result = API.ScanForInterfaceTest2Get(true, heediInterface)
    if #result > 0 then
        return true
    else return false end
end

local eternalMagicBranchAmount = 0
local function eternalMagicBranch()
    if Inventory:InvItemcount(eternalMagicBranchID) > 0 and API.PInAreaW(trees, 20) then
        if isHeediInterfacePresent() then
            print("Offer branches interface open")
            API.RandomSleep2(600,1200,1400)
            API.DoAction_Interface(0xffffffff,0xffffffff,0,847,22,-1,API.OFF_ACT_GeneralInterface_Choose_option)
            eternalMagicBranchAmount = eternalMagicBranchAmount + 1 
            API.RandomSleep2(800,1200,3000)
        else
            print("interact with Heedi")
            API.DoAction_NPC(0x3b,API.OFF_ACT_InteractNPC_route2,{ heediID },50)
            API.RandomSleep2(800,1200,3000)
        end
    end
end

----------------------------------------------------------------------
-- MAIN LOOP
----------------------------------------------------------------------
API.SetDrawTrackedSkills(true)
API.Write_LoopyLoop(true)

if ENABLE_WILDERNESS_EVENTS then
    print("Initializing Wilderness Event Logic...")
    ManageWildernessEvent(WOODCUTTING_PRESET)
end

while (API.Read_LoopyLoop()) do
    
    if API.GetGameState2() ~= 3 or not API.PlayerLoggedIn() then
        print("Bad game state, exiting.")
        break
    end
    API.DoRandomEvents(1200, 500, false)

    if ENABLE_WILDERNESS_EVENTS then
        ManageWildernessEvent(WOODCUTTING_PRESET)
    end

    if ENABLE_HERB_RUNS then
        ManageHerbRuns(WOODCUTTING_PRESET)
    end

    checkXpIncrease()

    if Inventory:InvItemcount(eternalMagicBranchID) > 0 and API.PInAreaW(trees, 20) then
        eternalMagicBranch()
    elseif Inventory:Invfreecount() < 1 then
        API.RandomSleep2(2000,5000,7000)
        if getWoodBoxItemCount(logsID) < 310 then
            print("fill wood box")
            Inventory:DoAction(58253, 1, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(600,1200,1800)
        else
            bank()
        end
    else
        returnToTrees()
        highlights()
        ChopTree()
    end
    
    API.RandomSleep2(100, 50, 100)
end