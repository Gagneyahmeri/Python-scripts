--[[

@title Gates of Elidinis Moonstone abuser
@description Abuse early Abuse often
@author Asoziales <discord@Asoziales>
@date 24/9/24
@version 1.0

Message on Discord for any Errors or Bugs

start in wars or near the sanctum

--]]

local API = require("api")
local UTILS = require("utils")
local LODE = require("lodestones")
local Slib = require("slib")
local BANK = require("bank")

startTime, afk = os.time(), os.time()
MAX_IDLE_TIME_MINUTES = 5

wars = {x = 3294, y = 10127, r = 40, z = 0}

local fail = 0

----------------------------------------------------------------------
-- EVENTS CONFIGURATION
----------------------------------------------------------------------
local ENABLE_HERB_RUNS = true      -- Set to false to disable Herb Runs
local ENABLE_WILDERNESS_EVENTS = true -- Set to false to disable Wildy Events

local SKILLING_PRESET = 14  -- Your preset to load

-- Event & Herb Run Variables
local EventTargetTimestamp = nil

local NextHerbRunTimestamp = 0 
local HERB_RUN_INTERVAL = 80 -- Minutes

local Wilderness_Script_Path = "C:\\Users\\pyrya\\MemoryError\\Lua_Scripts\\WildernessFlashEvents.lua"
local Herb_Script_Path = "C:\\Users\\pyrya\\MemoryError\\Lua_Scripts\\herbRunner.lua"

----------------------------------------------------------------------
-- EVENTS CONFIGURATION
----------------------------------------------------------------------

local OtherIDsNeededForStuff = {
    ["WildernessSword"] = 37907,
    ["WarsTeleport"] = 35042,
    ["ArchaeologyJournal"] = 49429,
    ["GraceOfTheElves"] = 44550,
    ["AttunedCrystalSeed"] = 39784,
    ["PassageOfTheAbyss"] = 44542,
    ["DungeoneeringCape"] = 18509,
}

local Interfaces = {
    ["Teleports"] = { { 720, 2, -1, 0 }, { 720, 17, -1, 2 } },
    ["SpiritTree"] = { { 1145, 1, -1, 0 } },
    ["ChatOptions"] = { { 1188, 5, -1, -1}, { 1188, 3, -1, 5}, { 1188, 3, 14, 3} },
    ["CharterMap"] = { { 95,23,-1,0 } },
    ["MagicCarpet"] = { {1928,6,-1,0}, {1928,21,-1,0} },
    ["ClueScroll"] = { { 345,9,-1,0 }, { 345,10,-1,0 } },
    ["CharosClueCarrier"] = { { 151,0,-1,0 }, { 151,1,-1,0 } },
    ["QuiverMap"] = { { 1572, 5, -1, 0 }, { 1572, 20, -1, 2} },
    ["FairyRing"] = { { 784, 0, -1, 0 }, { 784, 56, -1, 2 } },
    ["GnomeGlider"] = { { 138, 1, -1, 0 }, { 138, 33, -1, 2 } },
    ["DigSites"] = { { 667, 0, -1, 0 }, { 667, 126, -1, 2 } },
    ["BossInstance"] =  { { 1591,15,-1,0 }, { 1591,16,-1,0 } }
}

local function InterfaceIsOpen(interfaceName)
    return #API.ScanForInterfaceTest2Get(true, Interfaces[interfaceName]) > 0
end

function idleCheck()
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((MAX_IDLE_TIME_MINUTES * 60) * 0.6, (MAX_IDLE_TIME_MINUTES * 60) * 0.9)

    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end

function detectThing(type,npcid)
    return #API.ReadAllObjectsArray({type}, npcid, {}) > 0
end

local function DialogBoxIsOpen()
    local VB1 = tonumber(API.VB_FindPSettinOrder(2874).state)
    if VB1 == 12 then
        return true
    else
        return false
    end
end

local function instanceStarted()
    if API.VB_FindPSettinOrder(6931, 0).state == 0 then
        return false
    else return true
    end
end


local function startInstance()
    Interact:Object("The Gate of Elidinis", "Enter", 50)
    Slib:SleepUntil(function()
        return InterfaceIsOpen("BossInstance")
    end, 6, 100)
    Slib:InstanceStart()
    API.RandomSleep2(600,600,600)
end


local function startEncounter()
    local icthlarin = API.ReadAllObjectsArray({1}, {17693}, {})
    local ichyX = math.floor(icthlarin[1].TileX / 512)
    local ichyY = math.floor(icthlarin[1].TileY / 512)
    --Slib:MoveTo(ichyX + 8, ichyY, 2)
    if not Slib:IsPlayerAtCoords(ichyX + 8, ichyY, 2) then
        API.DoAction_Tile(WPOINT.new(ichyX + 8, ichyY, 0))
    end
    --[[ Slib:SleepUntil(function()
         return Slib:IsPlayerAtCoords(ichyX + 8, ichyY, 2)
    end, 20, 100) ]]
    if Slib:IsPlayerAtCoords(ichyX + 8, ichyY, 2) then
        API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route,{ 17693 },50)
    end
    fail = fail + 1
end

local function chiselMoonstone()
    if API.GetHPrecent() > 10 then
        Interact:Object("Moonstone", "Gather", 50)
    end
    fail = 0
end

----------------------------------------------------------------------
-- EVENT MANAGERS
----------------------------------------------------------------------

local function LoadPreset(PresetNumber)

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

local function GetMinutesToNextEvent()
    local url = "https://wilderness.spegal.dev/api/?t=" .. os.time()
    
    local response = Http:Get(url)
    
    local ok, data = pcall(API.JsonDecode, response and response.body or "{}")

    if ok and data and data.time then
        return tonumber(data.time)
    end
    return nil
end

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
        
        if secondsUntilEvent <= 80 then
            print("Time to event < 1 mins! Starting WildernessFlashEvents...")
            
            WarsTeleport()
            Interact:Object("Bank chest", "Use", 20)
            Slib:SleepUntil(function() return BANK:IsOpen() end, 6, 100)
            
            local scriptLoaded, err = pcall(dofile, Wilderness_Script_Path)

            if not scriptLoaded then
                print("Error loading script: " .. err)
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
        local scriptLoaded, err = pcall(dofile, Herb_Script_Path)

        if not scriptLoaded then
            print("ERROR loading herb script: " .. err)
            API.Write_LoopyLoop(false)
        else
            print("Herb run finished successfully.")
            NextHerbRunTimestamp = os.time() + (HERB_RUN_INTERVAL * 60)
            print("Next Herb Run scheduled for: " .. os.date("%H:%M:%S", NextHerbRunTimestamp))
            
            LoadPreset(PresetAfterEvent)
        end
    end
end

API.SetDrawTrackedSkills(true)
API.Write_LoopyLoop(true)
while (API.Read_LoopyLoop()) do
::continue::

    if ENABLE_WILDERNESS_EVENTS then
        ManageWildernessEvent(SKILLING_PRESET)
    end

    if ENABLE_HERB_RUNS then
        ManageHerbRuns(SKILLING_PRESET)
    end

    if fail == 8 then
        API.DoAction_Ability("War's Retreat Teleport", 1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(3600,1200,200)
        fail = 0
    end

    if API.CheckAnim(30) or API.ReadPlayerMovin2() then
        API.RandomSleep2(300,200,100)
        goto continue
    end

    if API.PInArea(wars.x, wars.r, wars.y, wars.r, wars.z) then
        --Slib:MoveTo(3298, 10153, 0)
        Interact:Object("Portal (The Gate of Elidinis)", "Enter", 50)
        Slib:SleepUntil(function()
            return Slib:IsPlayerInArea(1010, 9633, 0, 15)
        end, 10, 100)
        Slib:RandomSleep(400,600,"ms")
    end
 
    if Slib:IsPlayerInArea(1010, 9632, 0, 20) then
        startInstance()
    end

    if detectThing(1,{17693}) and API.VB_FindPSettinOrder(4680).state == 0 then 
        startEncounter()
    end

    if API.VB_FindPSettinOrder(4680).state == 53 then
        chiselMoonstone()
    end

    idleCheck()
    API.DoRandomEvents()
    API.RandomSleep2(300, 300, 300)
end
