local API = require("api")
local Slib = require("slib")
local LODESTONES = require("lodestones")
local PuzzleModule = require("PuzzleModule")
local UTILS = require("utils")
local BANK = require("bank")

Slib._writeToFile = true
UsePuzzleSolverAPI = true
APIKey = "dk_f9dae5341d9f624262faa7aaf4ed0cd0"

local ENABLE_HERB_RUNS = true      -- Set to false to disable Herb Runs
local ENABLE_WILDERNESS_EVENTS = true -- Set to false to disable Wilderness Events

local CLUE_PRESET = 11
local EventTargetTimestamp = nil

local NextHerbRunTimestamp = 0 
local HERB_RUN_INTERVAL = 80 -- Minutes

--------------------START GUI STUFF--------------------
local CurrentStatus = "Starting"
local UIComponents = {}
local function GetComponentAmount()
    local amount = 0
    for i,v in pairs(UIComponents) do
        amount = amount + 1
    end
    return amount
end

local function GetComponentByName(componentName)
    for i,v in pairs(UIComponents) do
        if v[1] == componentName then
            return v;
        end
    end
end

local function AddBackground(name, widthMultiplier, heightMultiplier, colour)
    widthMultiplier = widthMultiplier or 1
    heightMultiplier = heightMultiplier or 1
    colour = colour or ImColor.new(15, 13, 18, 255)
    Background = API.CreateIG_answer();
    Background.box_name = "Background" .. GetComponentAmount();
    Background.box_start = FFPOINT.new(30, 0, 0)
    Background.box_size = FFPOINT.new(400 * widthMultiplier, 20 * heightMultiplier, 0)
    Background.colour = colour
    UIComponents[GetComponentAmount() + 1] = {name, Background, "Background"}
end

local function AddLabel(name, text, colour)
    colour = colour or ImColor.new(255, 255, 255)
    Label = API.CreateIG_answer()
    Label.box_name = "Label" .. GetComponentAmount()
    Label.colour = colour;
    Label.string_value = text
    UIComponents[GetComponentAmount() + 1] = {name, Label, "Label"}
end

local function GUIDraw()
    for i=1,GetComponentAmount() do
        local componentKind = UIComponents[i][3]
        local component = UIComponents[i][2]
        if componentKind == "Background" then
            component.box_size = FFPOINT.new(component.box_size.x, 25 * GetComponentAmount(), 0)
            API.DrawSquareFilled(component)
        elseif componentKind == "Label" then
            component.box_start = FFPOINT.new(40, 10 + ((i - 2) * 25), 0)
            API.DrawTextAt(component)
        end
    end
end

local function CreateGUI()
    AddBackground("Background", 0.85, 1, ImColor.new(15, 13, 18, 255))
    AddLabel("Author/Version", ScriptName .. " v" .. ScriptVersion .. " by " .. Author, ImColor.new(238, 230, 0))
    AddLabel("Status", "Status: " .. CurrentStatus, ImColor.new(238, 230, 0))
end

local function UpdateStatus(newStatus)
    CurrentStatus = newStatus
    local statusLabel = GetComponentByName("Status")
    if statusLabel then
        statusLabel[2].string_value = "Status: " .. CurrentStatus
    end
end

CreateGUI()
GUIDraw()
--------------------END GUI STUFF--------------------

--------------------START METRICS STUFF--------------------
local MetricsTable = {
    {"-", "-"}
}

local startTime = os.time() 
local counter = 0
local lastUpdateTime = os.time()
local updateFrequency = 0
local ReasonForStopping = "Manual Stop."

local function formatRunTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function calcIncreasesPerHour()
    local runTimeInHours = (os.time() - startTime) / 3600
    if runTimeInHours > 0 then
        return counter / runTimeInHours
    else
        return 0
    end
end

local function calcAverageIncreaseTime()
    if counter > 0 then
        return (os.time() - startTime) / counter
    else
        return 0
    end
end

function Tracking() -- This is what should be called at the end of every cycle
    counter = counter + 1 
    local runTime = os.time() - startTime
    local increasesPerHour = calcIncreasesPerHour() 
    local avgIncreaseTime = calcAverageIncreaseTime() 

    MetricsTable[1] = {"Thanks for using my script!"}
    MetricsTable[2] = {" "}
    MetricsTable[3] = {"Total Run Time", formatRunTime(runTime)}
    MetricsTable[4] = {"Total Clues Solved", tostring(counter)}
    MetricsTable[5] = {"Clues per Hour", string.format("%.2f", increasesPerHour)}
    MetricsTable[6] = {"Average Clue Time (s)", string.format("%.2f", avgIncreaseTime)}
    MetricsTable[7] = {"Reason for Stopping:", ReasonForStopping}
    MetricsTable[8] = {"-----", "-----"}
    MetricsTable[9] = {"Script's Name:", ScriptName}
    MetricsTable[10] = {"Author:", Author}
    MetricsTable[11] = {"Version:", ScriptVersion}
    MetricsTable[12] = {"Release Date:", ReleaseDate}
    MetricsTable[13] = {"Discord:", DiscordHandle}    
end
--------------------END METRICS STUFF--------------------

--------------------START VARIABLES STUFF--------------------
local ClueStepId = 999999
local IdleCycles = 0
local FirstStep = true
local Retries = 1
local IsFirstRun = true

local OtherIDsNeededForStuff = {
    ["Spade"] = 952,
    ["LOTD"] = 39812,
    ["AttunedCrystalSeed"] = 39784,
    ["DrakansMedallion"] = 21576,
    ["PuzzleBoxSkip"] = 33505,
    ["SuperRestores"] = {23399, 23401, 23403, 23405, 23407, 23409, 3024, 3026, 3028, 3030},
    ["Meerkat"] = 19622,
    ["MeerkatScroll"] = 19621,
    ["WickedHood"] = 22332,
    ["StandardSpellbookSwap"] = 35018,
    ["LunarSpellbookSwap"] = 35014,
    ["WesternKharaziTeleport"] = 1779,
    ["TrollheimTeleport"] = 35032,
    ["ArchaeologyJournal"] = 49429,
    ["WarsTeleport"] = 35042,
    ["AnnakarlTeleport"] = 25913,
    ["DungeoneeringCape"] = 18509,
    ["SlayerCape"] = 9787,
    ["WildernessSword"] = 37907,
    ["GraceOfTheElves"] = 44550,
    ["DavesSpellbook"] = 42604,
    ["TirannwnQuiver4"] = 33722,
    ["LeelasFavour"] = 58702,
    ["PassageOfTheAbyss"] = 44542,
    ["AmuletOfNature"] = 6040,
    ["PortableObelisk"] = 53919,
    ["QuestCape"] = 9813,
    ["GlobetrotterShorts"] = 42118,
    ["GlobetrotterJacket"] = 42114,
    ["GlobetrotterBackpack"] = 42122,
    ["GlobetrotterArmguards"] = 42106,
    ["FremennikSeaBoots4"] = 19766
}

local ChallengeScrolls = {
    7269, --answer is 6
    7271, --answer is 13
    7273 -- answer is 33
}

local StepItems = {}
local PossibleWeapons = {
    55484, --Augmented Omni guard
    55485, --Augmented Soulbound Lantern
    55544, --Augmented Death guard t90
    55545, --Augmented Skull Lantern t90
}

local Wizards = {
    "Cabbagemancer",
    "Bandosian wild mage",
    "Armadylean shaman",
    "Zamorak wizard",
    "Saradomin wizard",
    "Guthix wizard",
    "Double agent"
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
    ["DigSites"] = { { 667, 0, -1, 0 }, { 667, 126, -1, 2 } }
}

local DialogOptions = {
    "Yes, and don't ask me again",
    "Okay",
    "Yes, swap it."
}

local SkipCombatSteps = { --Steps that you get attacked by random shit
    2723,
    2725,
    2727,
    2731,
    2733,
    2735,
    2737,
    2741,
    2743,
    2745,
    2747,
    2786,
    2788,
    3525,
    3532,
    3534,
    3556,
    3558,
    7260,
    7262
}
--------------------END VARIABLES STUFF--------------------

--------------------START FUNCTIONS STUFF--------------------
local function RecurringSafetyChecks()
    --Start safety checks
    if not API.CacheEnabled then
        Slib:Error("Cache is not enabled. Halting script.")
        ReasonForStopping = "Cache is not enabled."
        API.Write_LoopyLoop(false)
        return false
    end

    if not API.IsCacheLoaded() then
        Slib:Error("Cache is not loaded. Halting script.")
        ReasonForStopping = "Cache is not loaded."
        API.Write_LoopyLoop(false)
        return false
    end

    if API.GetGameState2() ~= 3 then
        Slib:Error("Not in game. Halting script.")
        ReasonForStopping = "Not in game."
        API.Write_LoopyLoop(false)
        return false
    end

    --Equipment tab open check
    if not Equipment:IsOpen() then
        Slib:Error("Equipment tab not visible. Halting script.")
        ReasonForStopping = "Equipment tab not visible."
        API.Write_LoopyLoop(false)
        return false
    end

    --Inventory tab open check
    if not Inventory:IsOpen() then
        Slib:Error("Inventory tab not visible. Halting script.")
        ReasonForStopping = "Inventory tab not visible."
        API.Write_LoopyLoop(false)
        return false
    end

    --Spade check
    if not Inventory:Contains(OtherIDsNeededForStuff["Spade"]) then
        Slib:Error("Spade not found in inventory. Halting script.")
        ReasonForStopping = "Spade not found in inventory."
        API.Write_LoopyLoop(false)
        return false
    end

    if  API.isAbilityAvailable("Guthix's Blessing") then
        --print("Finger of Death is available.")
    else
        API.DoAction_Interface(0xffffffff,0xffffffff,8,1430,254,-1,API.OFF_ACT_GeneralInterface_route2)
        print("Changing ability bar...")
        --[[ Slib:Error("Finger of Death is NOT available in ability bar. Halting script.")
        ReasonForStopping = "Finger of Death is NOT available in ability bar."
        API.Write_LoopyLoop(false)
        return false ]]
    end

    if API.GetHP_() < 8000 then
        if API.GetAdrenalineFromInterface() > 90 and not API.LocalPlayer_IsInCombat_() then
            print("Using adrenaline for healing.")
            API.DoAction_Button_GH()
            Slib:RandomSleep(1000, 2000, "ms")
        else
            print("Adrenaline too low.")
        end
    end

    --Meerkats check
    --[[ if Familiars:GetName() ~= "Meerkats" and not Inventory:Contains(19622) then
        Slib:Error("Familiar not summoned and no pouches in inventory. Halting script.")
        ReasonForStopping = "Familiar not summoned and no pouches in inventory."
        API.Write_LoopyLoop(false)
        return false
    end ]]

    --Auto retaliate check
    if API.GetVarbitValue(42166) ~= 1 then
        print("Disabling auto retaliate.")
        API.DoAction_Button_AR()
    end

    --Teleports tab open check
    --[[ if API.VB_FindPSettinOrder(3705, 1).state ~= 270729216 then
        Slib:Error("Teleports tab not visible. Halting script.")
        ReasonForStopping = "Teleports tab not visible."
        API.Write_LoopyLoop(false)
        return false
    end ]]

    --End safety checks
    return true
end

local function OnlyOnceSafetyChecks()
    --Spellbook check
    --[[ if Slib:GetSpellBook() ~= "Ancient" then
        Slib:Error("Not on ancient spellbook. Halting script.")
        ReasonForStopping = "Not on ancient spellbook."
        API.Write_LoopyLoop(false)
        return false
    end ]]

    --Weapon check
    local HasWeapon = false
    for i = 1, #PossibleWeapons do
        if Equipment:Contains(PossibleWeapons[i]) then
            HasWeapon = true
            break
        end
    end

    if not HasWeapon then 
        Slib:Error("No weapon found")
        ReasonForStopping = "No Weapon found"
        return false
    end

    if API.GetVarbitValue(25054) ~= 11 or API.GetVarbitValue(25055) ~= 17 then --25054 varbit is maxguild northern portal. 25055 is southern max guild portal.
        Slib:Error("Gote portal 1 is not Zanaris or portal 2 is not overgrown idols. Halting script.")
        ReasonForStopping = "Gote portal 1 is not Zanaris or portal 2 is not overgrown idols."
        return false
    end

    return true
end

local function GetClueStepId()
    if Inventory:Contains(42008) then
        UpdateStatus("Opening clue")
        Slib:Info("Opening clue")
        API.DoAction_Inventory1(42008, 0, 1, API.OFF_ACT_GeneralInterface_route) -- Open sealed clue
        Tracking()
        Slib:RandomSleep(600, 1200, "ms")
        FirstStep = true
    end

    local ScrollBox = Inventory:GetItem("Scroll box (hard)")
    if #ScrollBox > 0 then
        UpdateStatus("Opening scroll box")
        Slib:Info("Opening scroll box")
        API.DoAction_Inventory1(ScrollBox[1].id, 0, 1, API.OFF_ACT_GeneralInterface_route) -- Open scroll box
        Slib:RandomSleep(600, 1200, "ms")
    end

    local Clue = Inventory:GetItem("Clue scroll (hard)")
    if #Clue > 0 then
        local clueId = Clue[1].id

        -- Only proceed if the clue ID exists in our ClueSteps table
        if ClueSteps[clueId] then
            UpdateStatus("Solving step " .. clueId)
            Slib:Info("Step: ".. clueId)
            if FirstStep then
                API.DoAction_Inventory1(clueId,0,1,API.OFF_ACT_GeneralInterface_route) -- Open clue so jamflex thinks we are organic
                Slib:RandomSleep(900, 1200, "ms")
                API.DoAction_Interface(0x24,0xffffffff,1,345,13,-1,API.OFF_ACT_GeneralInterface_route) --Close clue scroll interface
                FirstStep = false
                Retries = 1
                StepItems = {0}
            end
            
            return clueId
        else
            Slib:Warn("Unknown clue step ID: " .. clueId .. " - skipping")
            return 999999
        end
    end

    Slib:Info("No scroll found")
    return 999999
end

local function HasSlidePuzzle()
    local Puzzlebox = Inventory:GetItem("Puzzle box (hard)")
    if #Puzzlebox > 0 then
        return true
    end
    return false
end

local function SolveSlidePuzzle()
    if UsePuzzleSolverAPI then
        local PuzzleBox = Inventory:GetItem("Puzzle box (hard)")
        if #PuzzleBox > 0 then
            UpdateStatus("Opening Puzzle Box")
            Slib:Info("Opening Puzzle Box")
            API.DoAction_Inventory1(PuzzleBox[1].id, 0, 1, API.OFF_ACT_GeneralInterface_route) -- Open puzzle box
            Slib:SleepUntil(function()
                return PuzzleModule.isPuzzleOpen()
            end, 6, 100)
            Slib:RandomSleep(600, 1200, "ms")
        end
        if PuzzleModule.isPuzzleOpen() then
            local PuzzleState = PuzzleModule.extractPuzzleState()
    
            if PuzzleState then
                local Success = PuzzleModule.solvePuzzle(PuzzleState, APIKey)
            end
        end

    else        
        if Inventory:Contains(OtherIDsNeededForStuff["PuzzleBoxSkip"]) then
            API.DoAction_Inventory1(OtherIDsNeededForStuff["PuzzleBoxSkip"],0,1,API.OFF_ACT_GeneralInterface_route)
        else
            Slib:Error("No puzzle box skips. Halting script.")
            ReasonForStopping = "No puzzle box skips."
            API.Write_LoopyLoop(false)
            return false
        end 
    end   
end

local function SignalUri()
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["GlobetrotterShorts"]) then
        Slib:Error("Globetrotter shorts not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Globetrotter shorts not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    local GlobetrotterShorts = API.GetABs_id(OtherIDsNeededForStuff["GlobetrotterShorts"])
    API.DoAction_Ability_Direct(GlobetrotterShorts, 1, API.OFF_ACT_GeneralInterface_route)
end

local function EquipWeapon()
    local EquippedWeapon = false
    for _, weapon in pairs(PossibleWeapons) do
        if Equipment:Contains(weapon) then
            EquippedWeapon = true
            --break
        elseif not Equipment:Contains(weapon) and Inventory:Contains(weapon) then
            Inventory:Equip(weapon)
            EquippedWeapon = true
            break
        end
    end
    Slib:RandomSleep(100, 300, "ms")
    Slib:Info("Equipped weapon: " .. tostring(EquippedWeapon))
    return EquippedWeapon
end

local function checkGoteEquip()
    if Equipment:Contains(44550) then
        return
    else
        Inventory:Equip(44550)
        API.RandomSleep2(600, 300, 700)
    end
end

local function AttackWizards()
    local WizardToAttack = nil
    local Interacting = API.ReadLpInteracting()
    --local Interacting = API.OthersInteractingWithLpNPC(false, 1)[1]
    local Objs = API.GetAllObjArrayInteract_str(Wizards, 20, {1})

    if Objs and #Objs > 0 then
        for i = 1, #Objs do
            if Objs[i] and Objs[i].Id then
                WizardToAttack = Objs[i].Name
                EquipWeapon()
                if Interacting then
                    if Interacting.Name ~= WizardToAttack then
                        Interact:NPC(WizardToAttack, "Attack", 20)
                    end
                end
                break
            end
        end
    else
        return
    end
end

local function AttackWizards2()
    local WizardToAttack = nil
    local objs = API.GetAllObjArrayInteract_str(Wizards, 20, {1})

    -- No wizard found
    if not objs or #objs == 0 then
        return false
    end

    -- Pick first valid wizard
    for i = 1, #objs do
        if objs[i] and objs[i].Id then
            WizardToAttack = objs[i].Name
            break
        end
    end

    if not WizardToAttack then
        return false
    end

    EquipWeapon()

    local interacting = API.ReadLpInteracting()
    if not interacting or interacting.Name ~= WizardToAttack then
        Interact:NPC(WizardToAttack, "Attack", 20)
    end

    local timeout = 18000
    local start = os.clock()

    while true do
        local inCombat = API.LocalPlayer_IsInCombat_()
        local objs2 = API.GetAllObjArrayInteract_str(Wizards, 20, {1})

        -- Wizard dead OR no wizards visible OR you're out of combat
        if not inCombat or not objs2 or #objs2 == 0 then
            break
        end

        -- Timeout safety
        if (os.clock() - start) * 1000 > timeout then
            Slib:Warn("Timeout waiting for wizard death")
            break
        end

        Slib:RandomSleep(150, 200, "ms")
    end

    return true -- wizard is dead (or timeout)
end


local function UseSpade()
    --API.DoAction_Interface(0x2e,0x3b8,1,1671,92,-1,API.OFF_ACT_GeneralInterface_route)
    API.DoAction_Interface(0x2e,0x3b8,1,1672,118,-1,API.OFF_ACT_GeneralInterface_route)
end

local function WaitForWizardDeath()
    timeout =  15000
    local start = os.clock()

    while true do
        local objs = API.GetAllObjArrayInteract_str(Wizards, 20, {1})
        --local inCombat = API.LocalPlayer_IsInCombat_()

        if not objs or #objs == 0 or not inCombat then
            return true
        end

        if (os.clock() - start) * 1000 > timeout then
            return false
        end
        Slib:RandomSleep(150, 220, "ms")
        print("Wizard dead wait...")
    end
end

local function UseMeerkat()
    if Familiars:HasFamiliar() and HasScrolls() then
        Familiars:CastSpecialAttack()
    else

        UseSpade()
        Slib:RandomSleep(1200, 2000, "ms")
        AttackWizards2()

        --WaitForWizardDeath()
        print("Wizard dead")

        UseSpade()
        Slib:RandomSleep(900,1200,"ms")
    end
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

local function TypingBoxOpenIsOpen()
    local VB1 = tonumber(API.VB_FindPSettinOrder(2874).state)
    local VB2 = tonumber(API.VB_FindPSettinOrder(2873).state)
    if VB1 == 10 or VB2 == 10 then
        return true
    else
        return false
    end
end

local function HasScrolls()
    local StoredScrolls = tonumber(API.GetVarbitValue(25412))
    local InventoryScrolls = tonumber(Inventory:GetItemAmount(OtherIDsNeededForStuff["MeerkatScroll"]))

    if Inventory:Contains(OtherIDsNeededForStuff["MeerkatScroll"]) and StoredScrolls < 100 then
        API.DoAction_Interface(0xffffffff,0xffffffff,1,662,78,-1,API.OFF_ACT_GeneralInterface_route) --Store meerkat scrolls
    end

    if StoredScrolls + InventoryScrolls > 0 then
        return true
    else
        return false
    end
end

local function CheckGlobearmsTps(key)

    local keyMap = {
        ["1"] = 43764,
        ["2"] = 43765,
        ["3"] = 43766,
        ["4"] = 43767,
        ["5"] = 43768,
    }

    local mapped = keyMap[key]

    local tpAmount = API.GetVarbitValue(mapped)

    print("Globetrotter armguards teleports left: " .. tpAmount)
    return tpAmount
end

local function UseGlobetrotterArmguards(key)

    local tpAmount = CheckGlobearmsTps(key)

    if tpAmount == 0 then
        print("No teleports left.")
        return false
    else
        Equipment:DoAction("Globetrotter arm guards", 2)

        Slib:SleepUntil(function()
            return InterfaceIsOpen("Teleports")
        end, 6, 100)
        Slib:TypeText(key)
        Slib:RandomSleep(3700, 3800, "ms")
        return true
    end
end


local function UseGlobetrotterBackpack()
    local charges = API.GetVarbitValue(39469)
    if charges > 0 then
        Equipment:DoAction("Globetrotter backpack", 2)
        
        Slib:RandomSleep(600, 800, "ms")
        API.KeyboardPress2(0x31, 60, 100)
        return true
    else
        return false
    end
end

local function UseGlobetrotterJacket()
    local charges = API.GetVarbitValue(39468)
    if charges > 0 then
        Equipment:DoAction("Globetrotter jacket", 2)
        Slib:RandomSleep(3700, 3800, "ms")
    else
        return false
    end
end

local function UseLotdTeleport(key)
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["LOTD"]) then
        Slib:Error("LOTD not found or not available in ability bar. Halting script.")
        ReasonForStopping = "LOTD not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    local AbLOTD = API.GetABs_id(OtherIDsNeededForStuff["LOTD"])
    API.DoAction_Ability_Direct(AbLOTD, key, API.OFF_ACT_GeneralInterface_route)
    Slib:RandomSleep(3500, 3800, "ms")
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

local function WickedHoodTeleport()
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["WickedHood"]) then
        Slib:Error("Wicked hood not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Wicked hood not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    if Slib:IsPlayerInArea(3109, 3156, 3, 10) then
        return
    end

    local WickedHood = API.GetABs_id(OtherIDsNeededForStuff["WickedHood"])
    API.DoAction_Ability_Direct(WickedHood, 3, API.OFF_ACT_GeneralInterface_route) --RC Guild
    Slib:SleepUntil(function()
        return Slib:IsPlayerInArea(3109, 3156, 3, 10)
    end, 6, 100)
    Slib:RandomSleep(1000, 2000, "ms")
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

local function TrollheimTeleport()
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["TrollheimTeleport"]) then
        Slib:Error("Trollheim teleport not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Trollheim teleport not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    if Slib:IsPlayerInArea(2882, 3666, 0, 20) then
        return
    end

    --SpellbookSwap("Standard")
    Slib:RandomSleep(200, 600, "ms")
    local TrollheimTeleport = API.GetABs_id(OtherIDsNeededForStuff["TrollheimTeleport"])
    API.DoAction_Ability_Direct(TrollheimTeleport, 1, API.OFF_ACT_GeneralInterface_route)
    Slib:SleepUntil(function()
        return Slib:IsPlayerInArea(2882, 3666, 0, 10)
    end, 6, 100)
    Slib:RandomSleep(1000, 2000, "ms")
end

local function ArchaeologyJournalTeleport()
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["ArchaeologyJournal"]) then
        Slib:Error("Archaeology journal not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Archaeology journal not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    if Slib:IsPlayerInArea(3336, 3378, 0, 20) then
        return
    end

    local ArchaeologyJournal = API.GetABs_id(OtherIDsNeededForStuff["ArchaeologyJournal"])
    API.DoAction_Ability_Direct(ArchaeologyJournal, 1, API.OFF_ACT_GeneralInterface_route) --Archaeology journal
    Slib:SleepUntil(function()
        return Slib:IsPlayerInArea(3336, 3378, 0, 3)
    end, 6, 100)
    Slib:RandomSleep(1000, 2000, "ms")
    
end

local function AnnakarlTeleport()
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["AnnakarlTeleport"]) then
        Slib:Error("AnnakarlTeleport not found or not available in ability bar. Halting script.")
        ReasonForStopping = "AnnakarlTeleport not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    if not Slib:IsPlayerInArea(3658, 3523, 0, 20) then
        local AnnakarlTeleport = API.GetABs_id(OtherIDsNeededForStuff["AnnakarlTeleport"])
        API.DoAction_Ability_Direct(AnnakarlTeleport, 1, API.OFF_ACT_GeneralInterface_route)
        Slib:SleepUntil(function()
            return Slib:IsPlayerInArea(3286, 3887, 0, 10)
        end, 20, 100)
    end
end

local function UseSpellbookTeleport(location)

    local locations = {
        ["Varrock"] = "28",
        ["Ardougne"] = "45",
        ["Yanille"] = "50",
        ["Taverley"] = "207",
        ["Trollheim"] = "57",
        ["Lumbridge"] = "31",
        ["SeersVillage"] = "39",
        ["KandarinMonastery"] ="201",
        ["ManorFarm"] = "202",
        ["OddOldMan"] = "200",
        ["SouthFeldipHills"] = "19" --Spirit tree
    }

    local destination = locations[location]

    --[[ if API.VB_FindPSettinOrder(3705, 1).state ~= 270729216 then
        Slib:Error("Teleports tab not visible. Halting script.")
        ReasonForStopping = "Teleports tab not visible."
        API.Write_LoopyLoop(false)
        return false
    end ]]

    API.DoAction_Interface(0xffffffff,0xffffffff,1,1461,1,destination,API.OFF_ACT_GeneralInterface_route)
    Slib:RandomSleep(3500, 4200, "ms")
end

local function UseSpiritTree(option)

    if not Slib:IsPlayerInArea(2412, 2846, 0, 20) then
        UseSpellbookTeleport("SouthFeldipHills")
        Slib:SleepUntil(function()
            return Slib:IsPlayerInArea(2412, 2846, 0, 20)
        end, 20, 100)
    end

    Interact:Object("Spirit tree", "Teleport", 20)

    Slib:SleepUntil(function()
        return InterfaceIsOpen("SpiritTree")
    end, 10, 100)
        
    Slib:RandomSleep(600, 800, "ms")
        
    if InterfaceIsOpen("SpiritTree") then
            Slib:TypeText(option)
    end
    IdleCycles = 15
end

local function DungeoneeringCapeTeleport(key1, key2)
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["DungeoneeringCape"]) then
        Slib:Error("Dungeoneering cape not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Dungeoneering cape not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    local DungeoneeringCape = API.GetABs_id(OtherIDsNeededForStuff["DungeoneeringCape"])
    API.DoAction_Ability_Direct(DungeoneeringCape, 3, API.OFF_ACT_GeneralInterface_route)

    Slib:SleepUntil(function()
        return InterfaceIsOpen("Teleports")
    end, 6, 100)

    if InterfaceIsOpen("Teleports") then
        Slib:TypeText(key1)
        Slib:RandomSleep(1000, 1200, "ms")
        if key2 ~= nil then
            Slib:TypeText(key2)
        end
    end
    Slib:RandomSleep(3700, 4000, "ms")
end
local function QuestCapeTeleport(key)
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["QuestCape"]) then
        Slib:Error("Quest cape not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Quest cape not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    local QuestCape = API.GetABs_id(OtherIDsNeededForStuff["QuestCape"])
    API.DoAction_Ability_Direct(QuestCape, 3, API.OFF_ACT_GeneralInterface_route)

    Slib:SleepUntil(function()
        return InterfaceIsOpen("Teleports")
    end, 6, 100)

    if InterfaceIsOpen("Teleports") then
        Slib:TypeText(key)
    end
    Slib:RandomSleep(3700, 4000, "ms")
end

local function SlayerCapeTeleport(key1, key2)

    if not Slib:CanCastAbility(OtherIDsNeededForStuff["SlayerCape"]) then
        Slib:Error("Slayer cape not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Slayer cape not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    local SlayerCape = API.GetABs_id(OtherIDsNeededForStuff["SlayerCape"])
    API.DoAction_Ability_Direct(SlayerCape, 3, API.OFF_ACT_GeneralInterface_route)

    Slib:SleepUntil(function()
        return InterfaceIsOpen("Teleports")
    end, 6, 100)

    if InterfaceIsOpen("Teleports") then
        Slib:TypeText(key1)
        Slib:RandomSleep(600, 1000, "ms")

        if key2 ~= nil then
            Slib:TypeText(key2)
        end
    end
    Slib:RandomSleep(3600, 3800, "ms")
end

local function CheckAmountOfTeleportsLeft(key)
    local locationMap = {
        ["1"] = 42125,
        ["4"] = 42123
    }

    local mapped = locationMap[key]
    local tpAmount = API.GetVarbitValue(mapped)

    print("Teleports left: " .. tpAmount)
    return tpAmount
end

local function DavesSpellbookTeleport(key)

    if not Slib:CanCastAbility(OtherIDsNeededForStuff["DavesSpellbook"]) then
        Slib:Error("Daves spellbook not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Daves spellbook not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    local DavesSpellbook = API.GetABs_id(OtherIDsNeededForStuff["DavesSpellbook"])
    local tpAmount = CheckAmountOfTeleportsLeft(key)

    if tpAmount == 0 then
        Slib:Error("No teleports left in Daves spellbook. Halting script.")
        ReasonForStopping = "No teleports left in Daves spellbook."
        API.Write_LoopyLoop(false)
        return false
    else
        API.DoAction_Ability_Direct(DavesSpellbook, 1, API.OFF_ACT_GeneralInterface_route)

        Slib:SleepUntil(function()
            return InterfaceIsOpen("Teleports")
        end, 6, 100)
        Slib:RandomSleep(200, 300, "ms")

        if InterfaceIsOpen("Teleports") then
            Slib:TypeText(key)
        end

        Slib:RandomSleep(3700, 3800, "ms")
        return true
    end
end

local function LeelasFavourTeleport(key)

    if not Slib:CanCastAbility(OtherIDsNeededForStuff["LeelasFavour"]) then
        Slib:Error("Leelas favour not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Leelas favour not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    local LeelasFavour = API.GetABs_id(OtherIDsNeededForStuff["LeelasFavour"])
    API.DoAction_Ability_Direct(LeelasFavour, 1, API.OFF_ACT_GeneralInterface_route)

    Slib:SleepUntil(function()
        return InterfaceIsOpen("Teleports")
    end, 6, 100)

    Slib:RandomSleep(400, 600, "ms")

    if InterfaceIsOpen("Teleports") then
        Slib:TypeText(key)
    end
    Slib:RandomSleep(3800, 4000, "ms")
end

local function UseQuiverTeleport(key)

    if not Slib:CanCastAbility(OtherIDsNeededForStuff["TirannwnQuiver4"]) then
        Slib:Error("Tirannwn Quiver 4 not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Tirannwn Quiver 4 not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    if Equipment:Contains(33722) then
        API.DoAction_Interface(0xffffffff,0x83ba,3,1464,15,13,API.OFF_ACT_GeneralInterface_route)
    else
        Inventory:Equip(33722)
        Slib:RandomSleep(600, 800, "ms")
        API.DoAction_Interface(0xffffffff,0x83ba,3,1464,15,13,API.OFF_ACT_GeneralInterface_route)
    end

    Slib:SleepUntil(function()
        return InterfaceIsOpen("QuiverMap")
    end, 6, 100)

    Slib:RandomSleep(600, 800, "ms")

    if InterfaceIsOpen("QuiverMap") then
        Slib:TypeText(key)
    end
    Slib:RandomSleep(3600, 4000, "ms")
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

local function ShouldSkipCombat()
    for _, step in pairs(SkipCombatSteps) do
        if ClueStepId == step then
            return true
        end
    end
    return false
end

local function DestroyClue()
    API.DoAction_Inventory1(ClueStepId,0,8,API.OFF_ACT_GeneralInterface_route2) --Destroy clue
    Slib:RandomSleep(1200, 1800, "ms")
    Slib:TypeText("y")
    Slib:RandomSleep(1200, 1800, "ms")
    API.DoAction_Inventory1(47836,0,1,API.OFF_ACT_GeneralInterface_route) --Open Charos' clue carrier
    Slib:RandomSleep(1200, 1800, "ms")
    if InterfaceIsOpen("CharosClueCarrier") then
        local Container = API.Container_Get_all(860)
        local Slot = 0
        local FoundSlot = false

        for i, clue in ipairs(Container) do
            if clue.item_id and clue.item_id == 42008 then
                Slot = clue.item_slot
                FoundSlot = true
                break
            end
        end

        if FoundSlot then 
            API.DoAction_Interface(0xffffffff,0xa418,1,151,14,Slot,API.OFF_ACT_GeneralInterface_route)
            Slib:RandomSleep(600, 1200, "ms")
            return true
        end
    end
    Slib:RandomSleep(600, 1200, "ms")
    return false
end

local function UseGote(option)

    local codeKeyMap = {
        Zanaris = 2,
        OvergrownIdols = 3
    }

    local key = codeKeyMap[option]
    print("UseGote option:", option, " key:", key)

    if not Equipment:Contains(44550) then
        Inventory:Equip(44550)
    end

    API.RandomSleep2(600, 300, 700)
    API.DoAction_Interface(0xffffffff,0xae06,key,1464,15,2,API.OFF_ACT_GeneralInterface_route)
    Slib:RandomSleep(3800, 4000, "ms")
end

local function UsePortableObelisk(key)

    if not Slib:CanCastAbility(OtherIDsNeededForStuff["PortableObelisk"]) then
        Slib:Error("PortableObelisk not found or not available in ability bar. Halting script.")
        ReasonForStopping = "PortableObelisk not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    local PortableObelisk = API.GetABs_id(OtherIDsNeededForStuff["PortableObelisk"])
    API.DoAction_Ability_Direct(PortableObelisk, 1, API.OFF_ACT_GeneralInterface_route)

    Slib:SleepUntil(function()
        return InterfaceIsOpen("Teleports")
    end, 6, 100)
    Slib:RandomSleep(200, 400, "ms")

    if InterfaceIsOpen("Teleports") then
        Slib:TypeText(key)
        Slib:RandomSleep(2800, 2900, "ms")
        return
    end
end

local function UsePoa(key1, key2)

    if not Slib:CanCastAbility(OtherIDsNeededForStuff["PassageOfTheAbyss"]) then
        Slib:Error("PassageOfTheAbyss not found or not available in ability bar. Halting script.")
        ReasonForStopping = "PassageOfTheAbyss not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    local AmountOfTps = API.Container_Get_all(93)[6].Extra_ints[2]

    print("Passage of the Abyss teleports left: " .. AmountOfTps)

    if AmountOfTps <= 0 then
        Slib:Error("No Passage of the Abyss teleports left. Halting script.")
        ReasonForStopping = "No Passage of the Abyss teleports left."
        API.Write_LoopyLoop(false)
        return
    end

    local PassageOfTheAbyss = API.GetABs_id(OtherIDsNeededForStuff["PassageOfTheAbyss"])
    API.DoAction_Ability_Direct(PassageOfTheAbyss, 1, API.OFF_ACT_GeneralInterface_route)

    Slib:SleepUntil(function()
        return InterfaceIsOpen("Teleports")
    end, 6, 100)

    --Slib:RandomSleep(1000, 2000, "ms")

    if InterfaceIsOpen("Teleports") then
        Slib:TypeText(key1)
        Slib:RandomSleep(600, 800, "ms")
        Slib:TypeText(key2)
        Slib:RandomSleep(3800, 4000, "ms")
        return
    end
end

local function UseGnomeGlider(GliderOption)

    if InterfaceIsOpen("GnomeGlider") then
        Slib:TypeText(GliderOption)
        Slib:RandomSleep(4000, 4200, "ms")
        return

    elseif Slib:IsPlayerAtCoords(2969, 2973, 0) then

        API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route, {3812}, 50)
        Slib:SleepUntil(function()
            return InterfaceIsOpen("GnomeGlider")
        end, 10, 100)

        if InterfaceIsOpen("GnomeGlider") then
            Slib:TypeText(GliderOption)
        end
        
        Slib:RandomSleep(3900, 4100, "ms")
        return

    elseif Slib:IsPlayerInArea(2949, 2977, 0, 10) then
        Slib:MoveTo(2969, 2973, 0)

    else 
        UseGote("OvergrownIdols")
    end
end

local function UseFairyring(FairyringCode)

    if not Slib:CanCastAbility(OtherIDsNeededForStuff["GraceOfTheElves"]) then
        Slib:Error("GraceOfTheElves not found or not available in ability bar. Halting script.")
        ReasonForStopping = "GraceOfTheElves not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    checkGoteEquip()

    local codeKeyMap = {
        BKR = 0x31,
        ALQ = 0x32,
        CJS = 0x33,
        AKS = 0x34,
        DKS = 0x35,
        CKS = 0x36,
        AKQ = 0x37,
        DLQ = 0x38,
        AJR = 0x39,
        CKR = 0x30,
    }

    if InterfaceIsOpen("FairyRing") then
        local key = codeKeyMap[FairyringCode]
        if key then
            API.KeyboardPress2(key, 100, 200)
            Slib:RandomSleep(4000, 4200, "ms")
            return
        end

    elseif Slib:IsPlayerInArea(2412, 4434, 0, 20) then
        Interact:Object("Fairy ring", "Use", 10)

        Slib:SleepUntil(function()
            return InterfaceIsOpen("FairyRing")
        end, 6, 100)
        return

    else
        local GraceOfTheElves = API.GetABs_id(OtherIDsNeededForStuff["GraceOfTheElves"])
        API.DoAction_Ability_Direct(GraceOfTheElves, 1, API.OFF_ACT_GeneralInterface_route)
        Slib:SleepUntil(function()
            return Slib:IsPlayerInArea(2412, 4434, 0, 10)
        end, 20, 100)
        Slib:RandomSleep(1200, 1300, "ms")
    end
end


--------------------END FUNCTIONS STUFF--------------------

ClueSteps = {
    [1234] = function()
        if 1 == 2 then

        elseif 1 == 2 then

        else
            LODESTONES.PORT_SARIM.Teleport()
        end
    end,

    [2722] = function() -- Forth forinthry lodestone. DONE

        if Slib:IsPlayerAtCoords(3312, 3527, 0) then
            Interact:Object("Crate", "Search", 40)

        elseif Slib:IsPlayerInArea(3291, 3543, 0, 10) then
            Slib:MoveTo(3312, 3527, 0)

        else
            SlayerCapeTeleport("9") --Raptor
        end
    end,

    [2723] = function() --Top of lava mze. DONE
        if Slib:IsPlayerAtCoords(3058, 3883, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(2980, 3867, 0, 10)then
            Slib:MoveTo(3058, 3883, 0)

        else
            UsePortableObelisk("5") 
        end
    end,

    [2725] = function() --Near wilderness agility course. DONE
        if Slib:IsPlayerAtCoords(2987, 3963, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(3000, 3911, 0, 10) then
            Slib:MoveTo(2987, 3963, 0)

        else
            WildernessSwordTeleport("1", "5")
        end
    end,

    [2727] = function() --Top of wilderness lever. DONE
        if Slib:IsPlayerAtCoords(3159, 3959, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(3158, 3948, 0, 2) then
            if Slib:FindObj2(65346, 10, 12, 3158, 3951, 3).Bool1 == 0 then
                Interact:Object("Web", "Slash", 20)
            else
                Slib:MoveTo(3159, 3959, 0)
            end

        elseif Slib:IsPlayerInArea(3154, 3924, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(3158, 1, 1), Slib:RandomNumber(3948, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3094, 3480, 0, 8) then
            Interact:Object("Lever", "Pull", 20)
            IdleCycles = 10

        else
            SlayerCapeTeleport("0", "1")
        end
    end,

    [2729] = function() --House near wilderness lever. DONE
        if Slib:IsPlayerAtCoords(3189, 3963, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(3158, 3948, 0, 2) then
            if Slib:FindObj2(65346, 10, 12, 3158, 3951, 3).Bool1 == 0 then
                Interact:Object("Web", "Slash", 20)
            else
                Slib:MoveTo(3189, 3963, 0)
            end

        elseif Slib:IsPlayerInArea(3154, 3924, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(3158, 1, 1), Slib:RandomNumber(3948, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3094, 3480, 0, 8) then
            Interact:Object("Lever", "Pull", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(3067, 3505, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3091, 1, 1), Slib:RandomNumber(3475, 1, 1), 0)

        else
            SlayerCapeTeleport("0", "1")
        end
    end,

    [2731] = function() --Annakarl. DONE
        if UseGlobetrotterBackpack() then
            return
        else
            DestroyClue()
        end
    end,

    [2733] = function() --Near wilderness herb patch. DONE
        if Slib:IsPlayerInArea(3140, 3804, 0, 2) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(3140, 3825, 0, 20) then
            Slib:MoveTo(3140, 3804, 0)

        else
            WildernessSwordTeleport("1", "2")
        end
    end,

    [2735] = function() --Wilderness church. DONE
        if Slib:IsPlayerInArea(2946, 3819, 0, 2) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(2980, 3867, 0, 10) then
            Slib:MoveTo(2946, 3819, 0)

        else
            UsePortableObelisk("5")
        end
    end,

    [2737] = function() --KBD lair. DONE
        if UseGlobetrotterBackpack() then
            return
        else
            DestroyClue()
        end
    end,

    [2739] = function() --North of Mandrith. DONE
        if Slib:IsPlayerAtCoords(3039, 3960, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(3054, 3950, 0, 10) then
            Slib:MoveTo(3039, 3960, 0)

        else
            SlayerCapeTeleport("1")
        end
    end,

    [2741] = function() --Near corporal beast. DONE
        if Slib:IsPlayerInArea(3244, 3792, 0, 1) then
            UseMeerkat()
            Slib:RandomSleep(600, 1200, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3214, 3782, 0, 10) then
            Slib:MoveTo(3244, 3792, 0)

        elseif Slib:IsPlayerInArea(2885, 4372, 2, 10) then
            Interact:Object("Exit", "Go-through", 20)
            Slib:RandomSleep(600, 1200, "ms")

        else
            UsePoa("5", "5")
        end
    end,

    [2743] = function() --South of corporal beast. DONE
        if Slib:IsPlayerInArea(3249, 3739, 0, 1) then
            UseMeerkat()
            Slib:RandomSleep(600, 1200, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3214, 3782, 0, 10) then
            Slib:MoveTo(3249, 3739, 0)

        elseif Slib:IsPlayerInArea(2885, 4372, 2, 10) then
            Interact:Object("Exit", "Go-through", 20)
            Slib:RandomSleep(600, 1200, "ms")

        else
            UsePoa("5", "5")
        end
    end,

    [2745] = function() --Dareeyak. DONE
        if Slib:IsPlayerInArea(2967, 3689, 0, 1) then
            UseMeerkat()
            Slib:RandomSleep(600, 1200, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3034, 3732, 0, 20) then
            Slib:MoveTo(2967, 3689, 0)

        else
            UsePortableObelisk("3")
        end
    end,

    [2747] = function() --Obelisk of Air. DONE
        if Slib:IsPlayerInArea(3091, 3571, 0, 1) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(3086, 3565, 0, 1) then
            Slib:MoveTo(3091, 3571, 0)

        elseif Slib:IsPlayerInArea(3086, 3561, 0, 1) then
            Interact:Object("Rocks", "Climb", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(3143, 3635, 0, 20) then
            Slib:MoveTo(3086, 3561, 0)

        else
            LODESTONES.WILDERNESS.Teleport()
        end
    end,

    [2773] = function() --Lumbridge castle basement. DONE
        if Slib:IsPlayerInArea(3218, 9617, 0, 2) then
            Interact:Object("Crate", "Search", 20)

        elseif Slib:IsPlayerInArea(3208, 9616, 0, 5) then
            Slib:MoveTo(3218, 9617, 0)

        elseif Slib:IsPlayerInArea(3210, 3216, 0, 5) then
            Interact:Object("Trapdoor", "Climb-down", 20)
            IdleCycles = 5

        elseif Slib:IsPlayerInArea(3219, 3225, 0, 15) then
            Slib:MoveTo(3210, 3216, 0)

        else
            SlayerCapeTeleport("0","2")
        end
    end,

    [2774] = function() -- Egdeville graveyard. DONE
        if Slib:IsPlayerAtCoords(3089, 3469, 0) then
            UseSpade()

        elseif Slib:IsPlayerInArea(3094, 3477, 0, 5) then
            Slib:MoveTo(3089, 3469, 0)

        else
            SlayerCapeTeleport("0","1")
        end
    end,

    [2776] = function() --Varrock bank cellar. DONE
        if Slib:IsPlayerAtCoords(3190, 9826, 0) then
            UseSpade()

        elseif Slib:IsPlayerInArea(3190, 9834, 0, 5) then
            Slib:MoveTo(3190, 9826, 0)

        elseif Slib:IsPlayerInArea(3188, 3433, 0, 10) then
            if Slib:FindObj2(24376, 50, 12, 3188, 3433, 2).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Interact:Object("Staircase", "Climb-down", 20)
            end
        
        elseif Slib:IsPlayerInArea(3210, 3433, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(3186, 1, 1), Slib:RandomNumber(3433, 1, 1), 0)
        else
            UseSpellbookTeleport("Varrock")
        end
    end,

    [2778] = function() -- Port sarim. DONE
        if Slib:IsPlayerInArea(3011, 3215, 0, 20) then
            Interact:NPC("Gerrant", "Talk to", 20)

        else
            LODESTONES.PORT_SARIM.Teleport()
        end
    end,

    [2780] = function() --Draynor village. DONE
        if Slib:IsPlayerAtCoords(3084, 3257, 0) then
            UseSpade()

        elseif Slib:IsPlayerInArea(3080, 3250, 0, 10) then
            Slib:MoveTo(3084, 3257, 0)

        else
            UsePoa("3", "3")
        end
    end,

    [2782] = function() -- Lumb castle drawers. DONE
        if Slib:IsPlayerInArea(3205, 3209, 1, 20) then
            if not Interact:Object("Drawers", "Open", 20) then
                --Interact:Object("Drawers", "Search", 20)
                API.DoAction_Object1(0x38,API.OFF_ACT_GeneralObject_route1,{ 37012 },50);

            end

        elseif Slib:IsPlayerInArea(3207, 3210, 0, 2) then
            Interact:Object("Staircase", "Climb-up", 10)
            IdleCycles = 8

        elseif Slib:IsPlayerInArea(3233, 3221, 0, 20)  then
            Slib:MoveTo(Slib:RandomNumber(3207, 1, 1), Slib:RandomNumber(3210, 1, 1), 0)

        else
            SlayerCapeTeleport("0","2") --Jacquelyn
        end
    end,

    [2783] = function() --Ardounge zoo. Monastery tele. DONE
        if Slib:IsPlayerAtCoords(2599, 3266, 0) then
            UseSpade()

        elseif Slib:IsPlayerInArea(2592, 3253, 0, 10) then
            Slib:MoveTo(2599, 3266, 0)

        elseif Slib:IsPlayerInArea(2606, 3220, 0, 10) then
            Slib:MoveTo(2599, 3266, 0)

        else

            local used = UseGlobetrotterArmguards("3")
            if not used then
                UseSpellbookTeleport("KandarinMonastery")
            end
        end
    end,

    [2785] = function() --Lumbridge mill crate. DONE
        if Slib:IsPlayerInArea(3165, 3307, 2, 10) then
            Interact:Object("Crate", "Search", 20)

        elseif Slib:IsPlayerInArea(3167, 3300, 0, 5) then
            if Slib:FindObj2(45966, 10, 12, 3167, 3303, 2).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Interact:Object("Ladder", "Climb-top", 20)
                IdleCycles = 15
            end

        elseif Slib:IsPlayerInArea(3219, 3250, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3167, 1, 1), Slib:RandomNumber(3300, 1, 1), 0)

        else
            UseSpellbookTeleport("Lumbridge")
        end
    end,

    [2786] = function() -- Graveyard of shadows. DONE
        if Slib:IsPlayerInArea(3235, 3673, 0, 1) then
            UseSpade()
            Slib:RandomSleep(1200, 1800, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3231, 3658, 0, 20) then
            Slib:MoveTo(3235, 3673, 0)

        else
            UsePoa("6","2")
        end
    end,

    [2788] = function() --North-east of herb patch. DONE
        if Slib:IsPlayerInArea(3170, 3886, 0, 1) then
            UseSpade()
            Slib:RandomSleep(1200, 1800, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3107, 3793, 0, 20) then
            Slib:MoveTo(3170, 3886, 0)

        else
            UsePortableObelisk("4")
        end
    end,

    [2790] = function() --Moss giant dungeon varrock. DONE
        if Slib:IsPlayerAtCoords(3161, 9904, 0) then
            UseSpade()

        elseif Slib:IsPlayerInArea(3166, 9879, 0, 10) then
            Slib:MoveTo(3161, 9904, 0)

        else
            DungeoneeringCapeTeleport("0","2")
        end
    end,

    [2792] = function() -- Lumbridge castle Hans. DONE
        if Slib:IsPlayerInArea(3233, 3221, 0, 20) then
            local Hans = API.ReadAllObjectsArray({1}, {0}, "Hans")
            if Hans and #Hans > 0 then
                if Hans[1].Distance < 20 then
                    API.DoAction_NPC__Direct(0x2c, API.OFF_ACT_InteractNPC_route, Hans[1])
                    IdleCycles = 5
                else
                    Slib:Info("Hans is too far away. Waiting for him to move closer...")
                    IdleCycles = 15
                end
            else
                Slib:Info("Hans not found. Waiting for him to appear...")
                IdleCycles = 15
            end
        else
            SlayerCapeTeleport("0","2") --Jacquelyn
        end
    end,

    [2793] = function() --Edgeville monastery abbot. DONE
        if Slib:IsPlayerInArea(3052, 3488, 0, 10) then
            Interact:NPC("Abbot Langley", "Talk to", 20)

        elseif Slib:IsPlayerInArea(3067, 3502, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3058, 1, 1), Slib:RandomNumber(3484, 1, 1), 0)

        else
            UsePoa("4","3")
        end
    end,

    [2794] = function() --Oziach slide puzzle. DONE
        if HasSlidePuzzle() then
            Interact:NPC("Oziach", "Talk to", 20)

        elseif Slib:IsPlayerInArea(3068, 3513, 0, 2) and Slib:FindObj2(37123, 50, 12, 3068, 3513, 1).Bool1 == 1 then
            Interact:NPC("Oziach", "Talk to", 20)

        elseif Slib:IsPlayerAtCoords(3069, 3508, 0) then
            if Slib:FindObj2(37123, 50, 12, 3068, 3513, 1).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Interact:NPC("Oziach", "Talk to", 20)
            end

        elseif Slib:IsPlayerInArea(3087, 3504, 0, 10) then
            Slib:MoveTo(3069, 3508, 0)

        else
            WildernessSwordTeleport("1","1")
        end
    end,

    [2796] = function() --Varrock palace room. DONE
        if Slib:IsPlayerInArea(3209, 3472, 0, 10) then
            if Slib:FindObj2(15536, 10, 12, 3207, 3472, 2).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Interact:NPC("Sir Prysin", "Talk to", 20)
            end

        elseif Slib:IsPlayerInArea(3211, 3434, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(3209, 1, 1), Slib:RandomNumber(3472, 1, 1), 0)

        else
            UseSpellbookTeleport("Varrock")
        end
    end,

    [2797] = function() --Varrock square. DONE.
        if Slib:IsPlayerInArea(3219, 3428, 0, 20) then
            Interact:NPC("Wilough", "Talk to", 20)

        elseif Slib:IsPlayerInArea(3212, 3435, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(3219, 1, 1), Slib:RandomNumber(3428, 1, 1), 0)

        else
            UseSpellbookTeleport("Varrock")
        end
    end,

    [2799] = function() --Goblin village. DONE
        if Slib:IsPlayerInArea(2957, 3515, 0, 3) then
            Interact:NPC("General Bentnoze", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2957, 3510, 0, 3) then
            if Slib:FindObj2(77969, 10, 12, 2957, 3511, 1).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Slib:MoveTo(Slib:RandomNumber(2957, 1, 1), Slib:RandomNumber(3513, 1, 1), 0)
            end

        elseif Slib:IsPlayerInArea(2948, 3455, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(2957, 1, 1), Slib:RandomNumber(3510, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2967, 3403, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2948, 1, 1), Slib:RandomNumber(3455, 1, 1), 0)

        else
            LODESTONES.FALADOR.Teleport()
        end
    end,

    [3520] = function() --yanille anvil. DONE.
        if Slib:IsPlayerAtCoords(2615, 3078, 0) then
            UseSpade()

        elseif Slib:IsPlayerInArea(2575, 3089, 0, 30) then
            Slib:MoveTo(2615, 3078, 0)

        else
            UseSpellbookTeleport("Yanille")
        end
    end,

    [3522] = function() -- West Ardougne. DONE
    if Slib:IsPlayerAtCoords(2489, 3309, 0) then
        UseSpade()

    elseif Slib:IsPlayerInArea(2496, 3304, 0, 3) then
        Slib:MoveTo(2489, 3309, 0)

    elseif Slib:IsPlayerInArea(2538, 3306, 0, 2) then
        Slib:MoveTo(Slib:RandomNumber(2496, 1, 1), Slib:RandomNumber(3304, 1, 1), 0)
        --Slib:MoveTo(2488, 3308, 0)

    else
        DavesSpellbookTeleport("4")
    end
end,

    [3524] = function() -- Observatory. DONE.
        if Slib:IsPlayerInArea(2460, 3178, 0, 12) then
            Interact:Object("Crate", "Search", 20)

        elseif Slib:IsPlayerInArea(2433, 3180, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2460, 1, 1), Slib:RandomNumber(3178, 1, 1), 0)

        else
        DavesSpellbookTeleport("1")
    end
end,

    [3525] = function() --Dark warriors fortress. DONE
        if Slib:IsPlayerAtCoords(3027, 3629, 0) then
            if Interact:Object("Crate", "Search", 20) then
                Slib:RandomSleep(1000, 2000, "ms")
                WarsTeleport()
            end

        elseif Slib:IsPlayerAtCoords(3034, 3631, 0) then
            if Slib:FindObj2(64833, 10, 12, 3033, 3632, 3).Bool1 == 0 then
                Interact:Object("Gate", "Open", 20)
            else
                Slib:MoveTo(3027, 3629, 0)
            end

        elseif Slib:IsPlayerAtCoords(3035, 3628, 0) or Slib:IsPlayerAtCoords(3034, 3628, 0) then
            if Slib:FindObj2(64831, 10, 12, 3035, 3628, 3).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Slib:MoveTo(3034, 3631, 0)
            end

        elseif Slib:IsPlayerAtCoords(3032, 3626, 0) then
            if Slib:FindObj2(64831, 10, 12, 3033, 3626, 3).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Slib:WalkToCoordinates(3035, 3628, 0)
                IdleCycles = 5
            end

        elseif Slib:IsPlayerAtCoords(3025, 3626, 0) then
            if Slib:FindObj2(64831, 10, 12, 3025, 3626, 3).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Slib:MoveTo(3032, 3626, 0)
            end

        elseif Slib:IsPlayerAtCoords(3023, 3629, 0) then
            if Slib:FindObj2(64831, 10, 12, 3023, 3628, 3).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Slib:MoveTo(3025, 3626, 0)
            end

        elseif Slib:IsPlayerInArea(3020, 3632, 0, 3) then
            if Slib:FindObj2(64833, 10, 12, 3021, 3632, 3).Bool1 == 0 then
                Interact:Object("Gate", "Open", 20)
            else
                Slib:MoveTo(3023, 3629, 0)
            end

        elseif Slib:IsPlayerInArea(3007, 3641, 0, 20) then
            Slib:MoveTo(3020, 3632, 0)

        elseif Slib:IsPlayerInArea(3012, 3706, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(3007, 1, 1), Slib:RandomNumber(3641, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3036, 3733, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3012, 1, 1), Slib:RandomNumber(3706, 1, 1), 0)

        else
            UsePortableObelisk("3")
        end
    end,

    [3526] = function() --Trollheim. DONE
        
        if Slib:IsPlayerAtCoords(2883, 3668, 0) then
            UseMeerkat()
        elseif Slib:IsPlayerInArea(2884, 3667, 0, 10) then
            Slib:MoveTo(2883, 3668, 0)

        else
            UseSpellbookTeleport("Trollheim")
        end
    end,

    [3528] = function() --Trollheim further. DONE
        if Slib:IsPlayerAtCoords(2848, 3684, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerAtCoords(2854, 3664, 0) then
            Slib:MoveTo(2848, 3684, 0)

        elseif Slib:IsPlayerAtCoords(2858, 3664, 0) then
            Interact:Object("Cliffside", "Climb", 3)
            Slib:SleepUntil(function()
                return Slib:IsPlayerAtCoords(2854, 3664, 0)
            end, 20, 100)

        elseif Slib:IsPlayerAtCoords(2875, 3659, 0) then
            Slib:MoveTo(2858, 3664, 0)

        elseif Slib:IsPlayerAtCoords(2875, 3663, 0) then
            Interact:Object("Cliffside", "Climb", 3)
            Slib:SleepUntil(function()
                return Slib:IsPlayerAtCoords(2875, 3659, 0)
            end, 20, 100)

        elseif Slib:IsPlayerInArea(2880, 3670, 0, 10) then
            Slib:MoveTo(2875,3663,0)
            
        else
            UseSpellbookTeleport("Trollheim")
        end
    end,

    [3530] = function() -- Shilo village island. Fairy ring CKR. DONE.
        if Slib:IsPlayerAtCoords(2763, 2974, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(2790, 2979, 0, 2) then
            Slib:MoveTo(2763, 2974, 0)

        elseif Slib:IsPlayerInArea(2796, 2979, 0, 2) then
            Interact:Object("Rocks", "Climb", 20)

        elseif Slib:IsPlayerInArea(2801, 3003, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2796, 1, 1), Slib:RandomNumber(2979, 1, 1), 0)

        else
            UseFairyring("CKR")
        end
    end,

    [3532] = function() -- Western kharazi furthest. DONE.
        if Slib:IsPlayerAtCoords(2775, 2891, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(2901, 2930, 0, 10) then
            Slib:MoveTo(2775, 2891, 0)

        else
            UseFairyring("CJS")
        end
    end,

    [3534] = function() --kharazi jungle. DONE
        if Slib:IsPlayerAtCoords(2838, 2914, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(2901, 2930, 0, 7) then
            Slib:MoveTo(2838, 2914, 0)

        else
            UseFairyring("CJS")
        end
    end,

    [3536] = function() --herblore habitat karamja. DONE
        if Slib:IsPlayerAtCoords(2949, 2903, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(2949, 2905, 0 ,3) then
            Slib:WalkToCoordinates(2949, 2903, 0)

        else
            if not Slib:CanCastAbility(OtherIDsNeededForStuff["AmuletOfNature"]) then
                Slib:Error("AmuletOfNature not found or not available in ability bar. Halting script.")
                ReasonForStopping = "AmuletOfNature not found or not available in ability bar."
                API.Write_LoopyLoop(false)
                return
            end
            local AmuletOfNature = API.GetABs_id(OtherIDsNeededForStuff["AmuletOfNature"])
            API.DoAction_Ability_Direct(AmuletOfNature, 3, API.OFF_ACT_GeneralInterface_route)
            Slib:SleepUntil(function()
                return Slib:IsPlayerInArea(2949, 2905, 0 ,3)
            end, 20, 100)
            Slib:RandomSleep(1500, 2000, "ms")
        end
    end,

    [3538] = function() --North of overgrown idols. DONE
        if Slib:IsPlayerAtCoords(2961, 3024, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(2945, 3041, 0, 2) then
            Slib:MoveTo(2961, 3024, 0)

        elseif Slib:IsPlayerInArea(2939, 3040, 0, 10) then
            Interact:Object("Gate", "Open", 15)
            Slib:RandomSleep(2000, 3000, "ms")

        elseif Slib:IsPlayerInArea(2949, 2977, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2939, 1, 1), Slib:RandomNumber(3040, 1, 1), 0)

        else
            UseGote("OvergrownIdols")
        end
    end,

    [3540] = function() --Karamja jungle at idols. DONE
        if Slib:IsPlayerAtCoords(2924, 2963, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(2949, 2977, 0, 10) then
            Slib:MoveTo(2924, 2963, 0)

        else
            UseGote("OvergrownIdols")
        end
    end,

    [3542] = function() --Natures grotto. DONE
        if Slib:IsPlayerAtCoords(3440, 3341, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(3440, 3331, 0, 3) then
            Slib:MoveTo(3440, 3341, 0)

        elseif Slib:IsPlayerInArea(3431, 3328, 0, 5) then
            Interact:Object("Bridge", "Jump", 20)

        elseif Slib:IsPlayerInArea(3447, 3470, 0, 5) then
            Interact:Object("Gate", "Quick travel", 20)

            Slib:SleepUntil(function()
                return Slib:IsPlayerInArea(3431, 3328, 0, 5)
            end, 20, 100)
            Slib:RandomSleep(1000, 2000, "ms")
        else
            UseFairyring("CKS")
        end
    end,

    [3544] = function() --Canifis swamp. DONE
        if Slib:IsPlayerAtCoords(3441, 3419, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(3469, 3431, 0, 10) then
            Slib:MoveTo(3441, 3419, 0)

        else
            UseFairyring("BKR")
        end
    end,

    [3546] = function() -- Gu tanoth middle. DONE
        if Slib:IsPlayerAtCoords(2542, 3032, 0) or Slib:IsPlayerAtCoords(2542, 3031, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(2530, 3029, 0, 2) then
            Slib:MoveTo(2542, 3032, 0)

        elseif Slib:IsPlayerInArea(2530, 3025, 0, 2) then
            Interact:Object("Gap", "Jump-over", 20)

        elseif Slib:IsPlayerInArea(2509, 3012, 0, 3) then
            Slib:MoveTo(2530, 3025, 0)

        elseif Slib:IsPlayerInArea(2501, 3013, 0, 6) then
            Interact:Object("Battlement", "Climb-over", 20)

        elseif Slib:IsPlayerInArea(2502, 3062, 0, 3) then
            Slib:MoveTo(Slib:RandomNumber(2501, 1, 1), Slib:RandomNumber(3013, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2505, 3062, 0, 3) then
            Interact:Object("City gate", "Open", 20)

        elseif Slib:IsPlayerInArea(2529, 3094, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2505, 1, 1), Slib:RandomNumber(3062, 1, 1), 0)

        else
            if UseGlobetrotterJacket() == false then
            LODESTONES.YANILLE.Teleport()
            end
        end
    end,

    [3548] = function() --Gu tanoth island. DONE
        if Slib:IsPlayerAtCoords(2580, 3029, 0) or Slib:IsPlayerAtCoords(2581, 3030, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(2576, 3029, 0, 2) then
            Slib:WalkToCoordinates(2580, 3029, 0)
            IdleCycles = 5

        elseif Slib:IsPlayerInArea(2500, 2987, 0, 5) then
            Interact:Object("Cave entrance", "Enter", 20)

        elseif Slib:IsPlayerInArea(2571, 2956, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(2500, 2, 2), Slib:RandomNumber(2987, 2, 2), 0)
            
        else
            if UseGlobetrotterJacket() == false then
            UseFairyring("AKS")
            end
        end
    end,

    [3550] = function()
        Slib:Error("If you are seeing this message, it means that I have made a mistake.")
        Slib:Error("I thought step 3550 didnt exist but it actually does.")
        Slib:Error("Ping me on discord so I can code this step.")
        ReasonForStopping = "Clue step 3550 actually exists and Im stupid"
        API.Write_LoopyLoop(false)
    end,

    [3552] = function() -- Desert north of bandit camp. DONE
        if Slib:IsPlayerAtCoords(3168, 3041, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(3169, 2994, 0, 20) then
            Slib:MoveTo(3168, 3041, 0)

        else
            UsePoa("6","3")
        end
    end,

    [3554] = function() -- Hets oasis. DONE
        if Slib:IsPlayerAtCoords(3360, 3243, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerAtCoords(3344, 3242, 0) then
            Slib:MoveTo(3360, 3243, 0)

        elseif Slib:IsPlayerInArea(3313, 3238, 0, 20) then
            Interact:Object("Fallen palm tree", "Run across", 30)
            Slib:SleepUntil(function()
                return Slib:IsPlayerAtCoords(3344, 3242, 0)
            end, 20, 100)

        else
            UsePoa("2","1")
        end
    end,

    [3556] = function() -- South of lava maze. DONE
        if Slib:IsPlayerInArea(3034, 3805, 0, 2) then
            UseMeerkat()
            Slib:RandomSleep(600, 1200, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(2980, 3867, 0, 20) then
            Slib:MoveTo(3034, 3805, 0)

        else
            UsePortableObelisk("5")
        end
    end,

    [3558] = function() -- Wilderness rogue castle. DONE
        if Slib:IsPlayerAtCoords(3285, 3943, 0) then
            UseMeerkat()
            Slib:RandomSleep(600, 1200, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3308, 3916, 0, 5) then
            Slib:MoveTo(3285, 3943, 0)

        else
            UsePortableObelisk("6")
        end
    end,

    [3560] = function() --Tirannwn pond. DONE
        if Slib:IsPlayerAtCoords(2208, 3160, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(2202, 3169, 0, 2) then
            Slib:MoveTo(2208, 3160, 0)

        elseif Slib:IsPlayerInArea(2199, 3169, 0, 2) then
            Interact:Object("Sticks", "Pass", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2188, 3171, 0, 2) then
            Slib:MoveTo(2199, 3169, 0)

        elseif Slib:IsPlayerInArea(2188, 3160, 0, 3) then
            Interact:Object("Dense forest", "Enter", 20)

            Slib:SleepUntil(function()
            return Slib:IsPlayerInArea(2187, 3173, 0, 3)
            end, 20, 100)

        elseif Slib:IsPlayerInArea(2187, 3145, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(2188, 1, 1), Slib:RandomNumber(3160, 1, 1), 0)

        else
            UseQuiverTeleport("3")
        end
    end,

    [3562] = function() --Tirannwn north. DONE
        if Slib:IsPlayerAtCoords(2181, 3207, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(2181, 3207, 0, 3) then
            Slib:WalkToCoordinates(2181, 3207, 0)

        elseif Slib:IsPlayerInArea(2181, 3212, 0, 3) then
            Interact:Object("Sticks", "Pass", 20)

        elseif Slib:IsPlayerInArea(2202, 3237, 0, 3) then
            Slib:MoveTo(2181, 3212, 0)

        elseif Slib:IsPlayerInArea(2195, 3238, 0, 5) then
            Interact:Object("Log balance", "Cross", 10)

        elseif Slib:IsPlayerInArea(2203, 3256, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2195, 1, 1), Slib:RandomNumber(3238, 1, 1), 0)

        else
            UseQuiverTeleport("6")
        end
    end,

    [3564] = function() --Prifddinas lord iorwerth. DONE
        if Slib:IsPlayerInArea(2185, 3283, 1, 10) then
            Interact:NPC("Lord Iorwerth", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2185, 3313, 1, 10) then            
            Slib:MoveTo(Slib:RandomNumber(2185, 1, 1), Slib:RandomNumber(3283, 1, 1), 1)

        else
            CrystalSeedTeleport("7")
        end
    end,

    [3566] = function() --Archeology guild examiner. DONE
        if Slib:IsPlayerInArea(3354, 3355, 0, 20) then
            Interact:NPC("Examiner", "Talk to", 20)

        elseif Slib:IsPlayerInArea(3336, 3378, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(3354, 1, 1), Slib:RandomNumber(3355, 1, 1), 0)

        else
            ArchaeologyJournalTeleport()
        end
    end,

    [3568] = function() --Menaphos worker district. DONE
        if Slib:IsPlayerInArea(3130, 2797, 0, 10) then
            Interact:NPC("Hamid", "Talk to", 20)

        elseif Slib:IsPlayerInArea(3156, 2796, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(3128, 1, 1), Slib:RandomNumber(2794, 1, 1), 0)

        else
            LeelasFavourTeleport("4")
        end
    end,

    [3570] = function() --Talk to captain in white wolf mountain. DONE
        if Slib:IsPlayerInArea(2848, 3495, 1, 10) then
            Interact:NPC("Captain Bleemadge", "Talk to", 20)

        else
            UseGnomeGlider("2")
        end
    end,

    [3572] = function() --Sorcerers tower upstairs. DONE
        if 1 == 2 then

        elseif Slib:IsPlayerInArea(2701, 3407, 1, 3) then
            Interact:Object("Bookcase", "Search", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2701, 3407, 0, 5) then
            Interact:Object("Ladder", "Climb-up", 20)

        elseif Slib:IsPlayerInArea(2702, 3399, 0, 1) then
            if Slib:FindObj2(1530, 10, 12, 2702, 3401, 2).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Interact:Object("Ladder", "Climb-up", 20)
                IdleCycles = 15
            end

        elseif Slib:IsPlayerInArea(2670, 3375, 0, 20) then
            Slib:MoveTo(2702, 3400, 0)

        else
            UseSpellbookTeleport("ManorFarm")
        end
    end,

    [3573] = function() --Baxtorian falls. Lotd upgrade. WORK
        if Slib:IsPlayerInArea(2521, 3494, 1, 5) then
            Interact:Object("Boxes", "Search", 20)

        elseif Slib:IsPlayerInArea(2525, 3495, 0, 2) then
            if Slib:FindObj2(1533, 10, 12, 2525, 3495, 13).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            elseif Slib:IsPlayerInArea(2521, 3494, 0, 3) then
                Interact:Object("Ladder", "Climb-up", 20)
                IdleCycles = 15
            else
                Interact:Object("Ladder", "Climb-up", 20)
                IdleCycles = 15
            end

        elseif Slib:IsPlayerInArea(2529, 3494, 0, 5) then
            if Slib:FindObj2(1551, 10, 12, 2528, 3495, 13).Bool1 == 0 then
                Interact:Object("Gate", "Open", 20)
            else
                Slib:MoveTo(2525, 3495, 0)
            end

        elseif Slib:IsPlayerInArea(2520, 3571, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2529, 1, 1), Slib:RandomNumber(3494, 1, 1), 0)

        else
            UsePoa("5","2")
        end
    end,

    [3574] = function() --Dwarven outbox. LOTD upgrade improve. WORK
        if Slib:IsPlayerInArea(2575, 3465, 0, 10) then
            Interact:Object("Boxes", "Search", 20)

        elseif Slib:IsPlayerInArea(2567, 3457, 0, 2) then
            Slib:MoveTo(Slib:RandomNumber(2575, 1, 1), Slib:RandomNumber(3465, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2567, 3454, 0, 2) then
            Interact:Object("Gate", "Open", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2563, 3411, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2567, 1, 1), Slib:RandomNumber(3454, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2615, 3385, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(2563, 1, 1), Slib:RandomNumber(3411, 1, 1), 0)

        else
            UsePoa("1","1")
        end
    end,

    [3575] = function() -- Tree gnome stronghold heckel funch puzzle. DONE
        if Slib:IsPlayerInArea(2466, 3494, 1, 5) or Slib:IsPlayerInArea(2490, 3488, 1, 10)  then
            Interact:NPC("Heckel Funch", "Talk to", 40)

--[[         elseif Slib:IsPlayerInArea(2466, 3494, 1, 5) then
            Slib:MoveTo(Slib:RandomNumber(2490, 1, 1), Slib:RandomNumber(3488, 1, 1), 1) ]]

        elseif Slib:IsPlayerInArea(2466, 3494, 2, 20) then
            API.DoAction_Object1(0x35,API.OFF_ACT_GeneralObject_route2,{69271},50) --Climb down ladder

        elseif Slib:IsPlayerInArea(2466, 3494, 3, 20) then
            API.DoAction_Object_r(0x35,API.OFF_ACT_GeneralObject_route0,{107377},50,WPOINT.new(2466,3495,0),5) --Climb down Ladder

        elseif Slib:IsPlayerInArea(2466, 3494, 0, 2) then
            --Interact:Object("Ladder", "Climb-up", 20) --Sometimes it goes to the top floor?
            API.DoAction_Object1(0x34,API.OFF_ACT_GeneralObject_route0,{ 107376 },50)

            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2465, 3489, 0, 2) then
            Interact:Object("Tree Door", "Open", 20)
            IdleCycles = 12

        elseif Slib:IsPlayerInArea(2462, 3444, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(2465, 1, 1), Slib:RandomNumber(3489, 1, 1), 0)
        else
            UseSpiritTree("2")
        end
    end,

    [3577] = function() -- Tree gnome stronghold gnome trainer. DONE
        if Slib:IsPlayerInArea(2474, 3427, 0, 10) then
            Interact:NPC("Gnome trainer", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2462, 3444, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(2474, 1, 1), Slib:RandomNumber(3427, 1, 1), 0)

        else
            UseSpiritTree("2")
        end
    end,

    [3579] = function() --Entrana. Globetrotter backpack skip. DONE
        if UseGlobetrotterBackpack() then
            return
        else
            DestroyClue()
        end
    end,

    [3580] = function() --Inside karamja volcano. Dung cape tele. DONE
        if Slib:IsPlayerAtCoords(2832, 9586, 0) then
            UseSpade()

        elseif Slib:IsPlayerInArea(2844, 9558, 0, 10) then
            Slib:MoveTo(2832, 9586, 0)

        else
            DungeoneeringCapeTeleport("4")
        end
    end,

    [7239] = function() -- Wilderness near mandrith. DONE
        if Slib:IsPlayerAtCoords(3021, 3911, 0) then
            UseSpade()
            Slib:RandomSleep(600, 1200, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3052, 3950, 0, 6) then
               Slib:MoveTo(3021, 3911, 0)

        else
            SlayerCapeTeleport("1")
        end
    end,

    [7241] = function() -- Legends guild, legends cape tp DONE
        if Slib:IsPlayerAtCoords(2722, 3339, 0) then
            UseSpade()

        elseif Slib:IsPlayerInArea(2728, 3348, 0, 5) then
            Slib:MoveTo(2722, 3339, 0)
            
        else
            API.DoAction_Inventory1(1052,0,3,API.OFF_ACT_GeneralInterface_route) --Legends cape tp
            Slib:RandomSleep(3500, 3800, "ms")
        end
    end,

    [7243] = function() -- Etceteria, spirit tree tp. DONE
        if Slib:IsPlayerAtCoords(2591, 3880, 0) then
            UseSpade()

        elseif Slib:IsPlayerInArea(2613, 3855, 0, 5) then
            Slib:MoveTo(2591, 3880, 0)

        else
            UseSpiritTree("7")
        end
    end,

    [7245] = function() -- Burgh de rott. Barrows tp. DONE
        if Slib:IsPlayerAtCoords(3489, 3288, 0) then
            UseSpade()

        elseif Slib:IsPlayerInArea(3485, 3244, 0, 2) then
            Slib:MoveTo(3489, 3288, 0)

        elseif Slib:IsPlayerInArea(3487, 3237, 0, 20) then
            Interact:Object("Gate", "Jump", 20)

        else
            UsePoa("5","6")
        end
    end,

    [7247] = function() --Shilo village search. DONE

        if Slib:IsPlayerInArea(2834, 2992, 0, 5) then
            Interact:Object("Bookcase", "Search", 20)

        elseif Slib:IsPlayerInArea(2826, 2998, 0, 5) then
            Slib:MoveTo(2834, 2992, 0)

        elseif Slib:IsPlayerInArea(2841, 9386, 0, 20) then
            Interact:Object("Ladder", "Climb-up", 20)
            Slib:SleepUntil(function()
                    return Slib:IsPlayerInArea(2826, 2998, 0, 20)
                end, 20, 100)
            Slib:RandomSleep(600, 800, "ms")
        else
            API.DoAction_Interface(0xffffffff,0x2b84,3,1671,53,-1,API.OFF_ACT_GeneralInterface_route)
            Slib:SleepUntil(function()
                    return Slib:IsPlayerInArea(2841, 9386, 0, 20)
                end, 20, 100)
            Slib:RandomSleep(1600, 2200, "ms")
        end
    end,

    [7248] = function() --Bandit camp crate. DONE
        if Slib:IsPlayerInArea(3170, 2994, 0, 20) then
            Interact:Object("Crate", "Search", 20)

        else
            UsePoa("6","3")
        end
    end,

    [7249] = function() --Wizard tower bookcase. DONE
        if Slib:IsPlayerInArea(3094, 3150, 0, 5) then
            Interact:Object("Bookcase", "Search", 20)

        elseif Slib:IsPlayerInArea(3103, 3156, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(3094, 1, 1), Slib:RandomNumber(3150, 1, 1), 0)

        elseif Slib:IsPlayerInArea(3109, 3156, 3, 10) then
            API.DoAction_Object1(0x29,API.OFF_ACT_GeneralObject_route1,{79776},50) --Beam > Bottom floor
            IdleCycles = 15

        else
            WickedHoodTeleport()
        end
    end,

    [7250] = function() --Elemental workshop crate. DONE
        if Slib:IsPlayerInArea(2716, 9888, 0, 1) then
            Slib:MoveTo(2723,9890,0)
            Interact:Object("Crate", "Search", 20)

        elseif Slib:IsPlayerAtCoords(2710, 3496, 0) or Slib:IsPlayerAtCoords(2709, 3496, 0) then
            Interact:Object("Staircase", "Climb-down", 20)

        elseif Slib:IsPlayerInArea(2708, 3483, 0, 10) then
            Interact:Object("Odd-looking wall", "Open", 20)
            IdleCycles = 20

        else
            UseSpellbookTeleport("SeersVillage")
        end
    end,

    [7251] = function() --Dwarven mine cart. DONE
        if Slib:IsPlayerInArea(3041, 9822, 0, 2) then
            Interact:Object("Mine cart", "Search", 10)

        elseif Slib:IsPlayerInArea(3036, 9773, 0, 10) then
            Slib:MoveTo(3041, 9821, 0)

        else
            DungeoneeringCapeTeleport("2")
        end
    end,

    [7252] = function() --Yanille agility dungeon. DONE
        if Slib:IsPlayerInArea(2578, 9581, 0, 5) then
            Interact:Object("Crate", "Search", 20)

        elseif Slib:IsPlayerInArea(2587, 9573, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(2578, 1, 1), Slib:RandomNumber(9581, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2574, 9500, 0, 5) then
            Interact:Object("Chaos altar", "Pray-at", 20)
            IdleCycles = 20

        elseif Slib:IsPlayerInArea(2580, 9512, 0, 3) then
            Slib:MoveTo(Slib:RandomNumber(2574, 1, 1), Slib:RandomNumber(9500, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2580, 9520, 0, 3) then
            Interact:Object("Balancing ledge", "Walk-across", 20)
            IdleCycles = 20

        elseif Slib:IsPlayerInArea(2568, 9525, 0, 5) then
            Slib:MoveTo(2580, 9520, 0)

        elseif Slib:IsPlayerInArea(2570, 3120, 0, 2) then
            Interact:Object("Staircase", "Climb-down", 20)
            IdleCycles = 15

        elseif Slib:IsPlayerInArea(2569, 3116, 0, 3) then
            if Slib:FindObj2(733, 10, 12, 2570, 3118, 4).Bool1 == 0 then
                Interact:Object("Web", "Slash", 20)
            else
                Slib:MoveTo(Slib:RandomNumber(2570, 1, 1), Slib:RandomNumber(3120, 1, 1), 0)
            end

        elseif Slib:IsPlayerInArea(2575, 3112, 0, 2) then
            Slib:MoveTo(Slib:RandomNumber(2569, 1, 1), Slib:RandomNumber(3116, 1, 1), 0)            

        elseif Slib:IsPlayerInArea(2575, 3107, 0, 2) then
            Interact:Object("Underwall tunnel", "Climb-under", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2573, 3094, 0, 20) then
            Slib:MoveTo(2575, 3107, 0)

       else
            if UseGlobetrotterJacket() == false then
            UseSpellbookTeleport("Yanille")
    end
end
    end,

    [7253] = function() -- Uzer ruins. Can be improved with desert amulet 4. WORK
        if Slib:IsPlayerInArea(3479, 3090, 0, 5) then
            Interact:Object("Crate", "Search", 20)

        elseif Slib:IsPlayerInArea(3423, 3016, 0, 3) then
            Slib:MoveTo(Slib:RandomNumber(3479, 1, 1),Slib:RandomNumber(3090, 1, 1), 0)

        else
            UseFairyring("DLQ")
        end
    end,

    [7254] = function() --Ranging guild haystack. DONE
        if Slib:IsPlayerInArea(2672, 3418, 0, 5) then
            Interact:Object("Haystack", "Search", 20)

        elseif Slib:IsPlayerInArea(2659, 3437, 0, 3) then
            Slib:MoveTo(Slib:RandomNumber(2672, 1, 1), Slib:RandomNumber(3418, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2655, 3441, 0, 5) then
            Interact:Object("Guild door", "Open", 20)

        else
            UsePoa("4","4")
        end
    end,

    [7255] = function() --Near ardougne lever. DONE
        if Slib:IsPlayerInArea(2561, 3322, 0, 2) then
            if Slib:FindObj2(34530, 10, 12, 2561, 3323, 2).Bool1 == 0 then
                --Open Drawer
                API.DoAction_Object_r(0x31,API.OFF_ACT_GeneralObject_route0,{34530},50,WPOINT.new(2561,3323,0),5)
            else
                --Search Drawer
                API.DoAction_Object2(0x38,API.OFF_ACT_GeneralObject_route0,{34531},50,WPOINT.new(2561,3323,0))
            end

        elseif Slib:IsPlayerInArea(2565, 3320, 0, 1) then
            if Slib:FindObj2(34807, 10, 12, 2564, 3320, 2).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Slib:MoveTo(2561, 3322, 0)
            end

        elseif Slib:IsPlayerInArea(2565, 3316, 0, 2) then
            if Slib:FindObj2(34807, 10, 12, 2565, 3317, 2).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Slib:MoveTo(2565, 3320, 0)
            end

        elseif Slib:IsPlayerInArea(2562, 3311, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(2565, 1, 1), Slib:RandomNumber(3316, 1, 1), 0)
        
        elseif Slib:IsPlayerInArea(3154, 3924, 0, 5) then
            Interact:Object("Lever", "Pull", 10)
            Slib:SleepUntil(function()
                    return Slib:IsPlayerInArea(2562, 3311, 0, 20)
                end, 20, 100)
            Slib:RandomSleep(1600, 2200, "ms")

        elseif Slib:IsPlayerInArea(3094, 3478, 0, 5) then
            Interact:Object("Lever", "Pull", 20)
            Slib:SleepUntil(function()
                    return Slib:IsPlayerInArea(3154, 3923, 0, 20)
                end, 20, 100)
            Slib:RandomSleep(1600, 2200, "ms")
        
        else
            SlayerCapeTeleport("0","1")
        end
    end,

    [7256] = function() --Arandar pass. DONE
        if Slib:IsPlayerAtCoords(2339, 3311, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(2386, 3333, 0, 1) then
            Slib:MoveTo(2339,3311,0)

        elseif Slib:IsPlayerInArea(2386, 3337, 0, 3) then
            Interact:Object("Huge Gate", "Enter", 20)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2367, 3360, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(2386, 2, 2), Slib:RandomNumber(3337, 2, 2), 0)

        else
            QuestCapeTeleport("0")
        end
    end,

    [7258] = function() -- Bandit camp west DONE
        if Slib:IsPlayerAtCoords(3139, 2969, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(3171, 2997, 0, 20)  then
            Slib:MoveTo(3139, 2969, 0)

        else
            UsePoa("6","3")
        end
    end,

    [7260] = function() --North ofdareeyak. DONE
        if Slib:IsPlayerInArea(2970, 3749, 0, 1) then
            UseMeerkat()
            Slib:RandomSleep(1200, 1800, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3036, 3731, 0, 20) then
            Slib:MoveTo(2970, 3749, 0)

        else
            UsePortableObelisk("3")
        end
    end,

    [7262] = function() --Near wilderness lodestone. DONE
        if Slib:IsPlayerInArea(3113, 3602, 0, 1) then
            UseMeerkat()
            Slib:RandomSleep(1200, 1800, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3143, 3635, 0, 20) then
            Slib:MoveTo(3113, 3602, 0)

        else
            LODESTONES.WILDERNESS.Teleport()
        end
    end,

    [7264] = function() --East of graveyard of shadows. DONE
        if Slib:IsPlayerInArea(3305, 3692, 0, 1) then
            UseMeerkat()
            Slib:RandomSleep(1200, 1800, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(3219, 3656, 0, 20) then
            Slib:MoveTo(3305, 3692, 0)

        else
            UsePortableObelisk("2")
        end
    end,

    [7266] = function() -- North rellekka. DONE.
        if Slib:IsPlayerAtCoords(2712, 3732, 0) then
            UseMeerkat()
            Slib:RandomSleep(1200, 1800, "ms")
            WarsTeleport()

        elseif Slib:IsPlayerInArea(2744, 3719, 0, 20) then
            Slib:MoveTo(2712, 3732, 0)

        else
            UseFairyring("DKS") --Kandarin snowhunter area
        end
    end,

    [7268] = function() -- Tree gnome stronghold gnome coach. DONE
        --Challenge scroll
        if Slib:IsPlayerInArea(2407, 3496, 0, 10) and Inventory:Contains(ChallengeScrolls[1]) then
            if TypingBoxOpenIsOpen() then 
                Slib:TypeText("6")
                IdleCycles = 5
                API.KeyboardPress2(0x0D, 50, 80) -- VK_RETURN
            elseif DialogBoxIsOpen() then
                Slib:TypeText(" ")
                IdleCycles = 5
            else
                Interact:NPC("Gnome Coach", "Talk to", 20)
                Slib:SleepUntil(function()
                    return TypingBoxOpenIsOpen() or DialogBoxIsOpen()
                end, 6, 100)
                IdleCycles = 5
            end
        
        elseif Slib:IsPlayerInArea(2407, 3496, 0, 30) then
            Interact:NPC("Gnome Coach", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2462, 3444, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(2407, 1, 1), Slib:RandomNumber(3496, 1, 1), 0)

        else
            UseSpiritTree("2") --Tree gnome stronghold option
        end
    end,

    [7270] = function() -- Tree gnome maze. DONE
        --Challenge scroll
        if Slib:IsPlayerInArea(2526, 3162, 1, 10) and Inventory:Contains(ChallengeScrolls[2]) then
            if TypingBoxOpenIsOpen() then 
                Slib:TypeText("13")
                IdleCycles = 5
                API.KeyboardPress2(0x0D, 50, 80) -- VK_RETURN
            elseif DialogBoxIsOpen() then
                Slib:TypeText(" ")
                IdleCycles = 5
            else
                Interact:NPC("Bolkoy", "Talk to", 20)
                Slib:SleepUntil(function()
                    return TypingBoxOpenIsOpen() or DialogBoxIsOpen()
                end, 6, 100)
                IdleCycles = 5
            end
        end

        --Clue scroll
        if Slib:IsPlayerInArea(2526, 3162, 1, 20) then
            Interact:NPC("Bolkoy", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2526, 3160, 0, 3) then
            Interact:Object("Ladder", "Climb-up", 20)

        elseif Slib:IsPlayerInArea(2542, 3169, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(2526, 1, 1), Slib:RandomNumber(3160, 1, 1), 0)

        else
            UseSpiritTree("1") --Tree gnome village option
        end
    end,

    [7272] = function() -- Brimhaven parrot. DONE
        --Challenge scroll
        if Slib:IsPlayerInArea(2807, 3192, 0, 10) and Inventory:Contains(ChallengeScrolls[3]) then
            if TypingBoxOpenIsOpen() then 
                Slib:TypeText("33")
                IdleCycles = 5
                API.KeyboardPress2(0x0D, 50, 80) -- VK_RETURN
            elseif DialogBoxIsOpen() then
                Slib:TypeText(" ")
                IdleCycles = 5
            else
                Interact:NPC("Cap'n Izzy No-Beard", "Talk to", 20)
                Slib:SleepUntil(function()
                    return TypingBoxOpenIsOpen() or DialogBoxIsOpen()
                end, 6, 100)
                IdleCycles = 5
            end
        end

        --Clue scroll
        if Slib:IsPlayerInArea(2807, 3192, 0, 10) then
            Interact:NPC("Cap'n Izzy No-Beard", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2800, 3203, 0, 8) then
            Slib:MoveTo(2807, 3192, 0)

        else
            UseSpiritTree("8")
        end
    end,

    [10234] = function() --Wilderness altar. DONE

        if Slib:IsPlayerAtCoords(3239, 3614, 0) then
            SignalUri()
            AttackWizards2()
            Slib:RandomSleep(600, 800, "ms")
            if Interact:NPC("Uri", "Talk to", 20) then
            end

        elseif Slib:IsPlayerInArea(3220, 3657, 0, 20) then
            Slib:MoveTo(3239, 3614, 0)

        else
            UsePortableObelisk("2")
        end
    end,

    [10236] = function() --Fishing guild emote. EMOTE DONE

        if Slib:IsPlayerAtCoords(2587, 3422, 0) then
            SignalUri()
            AttackWizards2()
            Slib:RandomSleep(600, 1000, "ms")
            if Interact:NPC("Uri", "Talk to", 20) then
            end

        elseif Slib:IsPlayerInArea(2614, 3388, 0, 2) then
            Slib:MoveTo(2587, 3422, 0)

        elseif Slib:IsPlayerInArea(2614, 3385, 0, 3) then
            Interact:Object("Gate", "Open", 20)

        else
            UsePoa("1","1")
        end
    end,

    [10238] = function() --Lighthouse. EMOTE DONE

        if Slib:IsPlayerInArea(2505, 3641, 2, 20) then
            SignalUri()
            AttackWizards2()
            Slib:RandomSleep(600, 900, "ms")
            if Interact:NPC("Uri", "Talk to", 20) then
            end

        elseif Slib:IsPlayerInArea(2509, 3637, 0, 2) then
            Interact:Object("Staircase", "Climb-top", 20)
            Slib:SleepUntil(function()
                return Slib:IsPlayerInArea(2505, 3641, 2, 20)
            end, 6, 100)

        elseif Slib:IsPlayerInArea(2509, 3633, 0, 3) then
            Interact:Object("Doorway", "Walk-through", 20)
            IdleCycles = 5

        elseif Slib:IsPlayerAtCoords(2514,3619, 0) then
            Slib:MoveTo(Slib:RandomNumber(2509, 1, 1), Slib:RandomNumber(3633, 1, 1), 0)

        elseif Slib:IsPlayerAtCoords(2514,3617, 0) then
            Interact:Object("Basalt rock", "Jump-across", 1)

        elseif Slib:IsPlayerAtCoords(2514, 3615, 0) then
            Slib:MoveTo(2514,3617, 0)

        elseif Slib:IsPlayerAtCoords(2514,3612, 0) then
            Interact:Object("Basalt rock", "Jump-across", 2)

        elseif Slib:IsPlayerAtCoords(2516, 3611, 0) then
            Slib:MoveTo(2514,3612, 0)

        elseif Slib:IsPlayerAtCoords(2518,3610, 0) then
            Interact:Object("Basalt rock", "Jump-across", 2)

        elseif Slib:IsPlayerAtCoords(2522, 3602, 0) then
            Slib:MoveTo(2518,3610, 0)

        elseif Slib:IsPlayerInArea(2522, 3599, 0, 1) then
            Interact:Object("Basalt rock", "Jump-across", 2)

        elseif Slib:IsPlayerInArea(2520, 3597, 0, 2) then
            Slib:MoveTo(2522,3599, 0)

        elseif Slib:IsPlayerInArea(2522, 3595, 0, 2) then
            Interact:Object("Basalt rock", "Jump-across", 5)

        elseif Slib:IsPlayerInArea(2520, 3571, 0, 10) then
            Slib:MoveTo(2522,3595, 0)

        elseif Slib:IsPlayerInArea(2515, 3626, 0, 10) then
            Slib:MoveTo(2509, 3634, 0)

        else

            local used = UseGlobetrotterArmguards("5")
            if not used then
                UsePoa("5","2")
            end
        end
    end,

    [10240] = function() -- Canifis panic in haunted woods. EMOTE DONE

        if Slib:IsPlayerAtCoords(3611, 3488, 0) then
            SignalUri()
            AttackWizards2()
            Slib:RandomSleep(600, 1000, "ms")
            Interact:NPC("Uri", "Talk to", 20)

        elseif Slib:IsPlayerAtCoords(3597, 3495, 0) then
            Slib:MoveTo(3611, 3488, 0)
            
        else
            UseFairyring("ALQ")
        end
    end,

    [10242] = function() -- Sophanem emote step. EMOTE DONE

        if Slib:IsPlayerAtCoords(3295, 2782, 0) then
            SignalUri()
            AttackWizards2()
            Slib:RandomSleep(600, 1000, "ms")
            if Interact:NPC("Uri", "Talk to", 20) then
            end

        elseif Slib:IsPlayerInArea(3289, 2708, 0, 10) then
             Slib:MoveTo(3295, 2782, 0)

        else
            LeelasFavourTeleport("7")
        end
    end,

    [10244] = function() --Wilderness portable obelisk level 27. DONE
        if UseGlobetrotterBackpack() then
            return
        else
            DestroyClue()
        end
    end,

    [10246] = function() -- Karamja banana emote step. EMOTE DONE

        if Slib:IsPlayerAtCoords(2918, 3174, 0) then
            SignalUri()
            AttackWizards2()
            Slib:RandomSleep(600, 1000, "ms")
            if Interact:NPC("Uri", "Talk to", 20) then
            end

        elseif Slib:IsPlayerInArea(2918, 3176, 0, 5) then
            Slib:MoveTo(2918, 3174, 0)

        else
            UsePoa("3","2")
        end
    end,

    [10248] = function() --Mountain camp emote. Uses fairy rings. DONE. EMOTE

        if Slib:IsPlayerInArea(2790, 3672, 0, 3) then
            SignalUri()
            AttackWizards2()
            Slib:RandomSleep(600, 1000, "ms")
            if Interact:NPC("Uri", "Talk to", 20) then
            end

        elseif Slib:IsPlayerInArea(2762, 3653, 0, 2) then
            Slib:MoveTo(2790, 3672, 0)

        elseif Slib:IsPlayerInArea(2757, 3652, 0, 3) then
            Interact:Object("Rockslide", "Climb-over", 20)

        elseif Slib:IsPlayerInArea(2780, 3613, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2757, 1, 1), Slib:RandomNumber(3652, 1, 1), 0)

        else
            UseFairyring("AJR")
        end
    end,

    [10250] = function() --White wolf mountain. EMOTE DONE

        if Slib:IsPlayerInArea(2850, 3494, 1, 1) then
            SignalUri()
            AttackWizards2()

            Slib:RandomSleep(600, 1000, "ms")
            if Interact:NPC("Uri", "Talk to", 20) then
            end        

        else
            UseGnomeGlider("2")
        end
    end,

    [10252] = function() --Shilo village bank emote. EMOTE DONE

        if Slib:IsPlayerInArea(2852, 2954, 0, 2) then
            SignalUri()
            AttackWizards2()
            Slib:RandomSleep(600, 1000, "ms")
            if Interact:NPC("Uri", "Talk to", 20) then
            end
            
        elseif Slib:IsPlayerInArea(2870, 2971, 0, 5) then
            Slib:MoveTo(2852, 2954, 0)

        elseif Slib:IsPlayerInArea(2870, 2981, 1, 20) then
            Interact:Object("Ladder", "Climb-down", 20)

        else
            SlayerCapeTeleport("5")
        end
    end,

    [13044] = function() --Wilderness lever. DONE
        if Slib:IsPlayerInArea(3154, 3923, 0, 5) then
            if Slib:IsPlayerAtCoords(3154, 3923, 0) then
                UseSpade()
            else
                Slib:WalkToCoordinates(3154, 3923, 0)
                IdleCycles = 5
            end

        elseif Slib:IsPlayerInArea(3092, 3478, 0, 10) then
            Interact:Object("Lever", "Pull", 20)
            IdleCycles = 10

        else
            SlayerCapeTeleport("0","1")
        end
    end,

    [13010] = function() --Keldagrim sculpture puzzle. DONE
        if Slib:IsPlayerInArea(2904, 10207, 0, 1) then
            Interact:NPC("Riki the sculptor's model", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2906, 10199, 0, 2) then
            if Slib:FindObj2(6110, 10, 12, 2906, 10200, 2).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
                IdleCycles = 5
            else
                Interact:NPC("Riki the sculptor's model", "Talk to", 20)
            end

        elseif Slib:IsPlayerInArea(2872, 10233, 0, 10)  then
            Slib:MoveTo(Slib:RandomNumber(2906, 1, 1), Slib:RandomNumber(10199, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2858, 10200, 0, 20)  then
            Slib:MoveTo(Slib:RandomNumber(2872, 1, 1), Slib:RandomNumber(10233, 1, 1), 0)

        else
            UseLotdTeleport("3")
        end
    end,

    [13012] = function() -- Piscatoris slide. DONE
        if HasSlidePuzzle() then
            Interact:NPC("Ramara du Croissant", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2336, 3675, 0, 2) and Slib:FindObj2(14923, 10, 12, 2337, 3675, 1).Bool1 == 1 then
            Interact:NPC("Ramara du Croissant", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2336, 3675, 0, 2) then
            if Slib:FindObj2(14923, 10, 12, 2337, 3675, 1).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
                IdleCycles = 5
            else
                Interact:NPC("Ramara du Croissant", "Talk to", 20)
            end

        elseif Slib:IsPlayerInArea(2344, 3663, 0, 3) then
            Slib:MoveTo(Slib:RandomNumber(2336, 1, 1), Slib:RandomNumber(3675, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2344, 3655, 0, 2) then
            Interact:Object("Colony gate", "Open", 10)
            IdleCycles = 10

        elseif Slib:IsPlayerInArea(2344, 3648, 0, 3) then
            Interact:Object("Hole", "Enter", 10)
            IdleCycles = 20

        elseif Slib:IsPlayerInArea(2319, 3619, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2344, 2, 2), Slib:RandomNumber(3648, 2, 2), 0)

        else
            UseFairyring("AKQ")
        end
    end,

    [13014] = function() --Wizards tower puzzle. DONE
        if HasSlidePuzzle() then
            Interact:NPC("Professor Onglewip", "Talk to", 50)

        elseif Slib:IsPlayerInArea(3103, 3156, 0, 5) then
            Interact:NPC("Professor Onglewip", "Talk to", 50)

        elseif Slib:IsPlayerInArea(3109, 3156, 3, 10) then
            API.DoAction_Object1(0x29,API.OFF_ACT_GeneralObject_route1,{79776},50) --Beam > Bottom floor
            Slib:RandomSleep(2000, 3000, "ms")
        else
            WickedHoodTeleport()
        end
    end,

    [13016] = function() --Nardah puzzle step. DONE.
        if Slib:IsPlayerInArea(3427, 2920, 0, 20) then
            Interact:NPC("Shiratti the Custodian", "Talk to", 30)

        else
            API.DoAction_Inventory1(27094,0,3,API.OFF_ACT_GeneralInterface_route)
            Slib:SleepUntil(function()
                return Slib:IsPlayerInArea(3430, 2916, 0, 20)
            end, 6, 100)
            Slib:RandomSleep(3800, 4000, "ms")
        end
    end,

    [13018] = function() --Port sarim trader stan puzzle. DONE
        if HasSlidePuzzle() then
            Interact:NPC("Trader Stan", "Talk to", 10)

        elseif Slib:IsPlayerInArea(3033, 3192, 0, 3) then
            Interact:NPC("Trader Stan", "Talk to", 10)

        elseif Slib:IsPlayerInArea(3011, 3215, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(3033, 1, 1), Slib:RandomNumber(3192, 1, 1), 0)

        else
            LODESTONES.PORT_SARIM.Teleport()
        end
    end,

    [13020] = function() --South of castle wars. DONE
        if Slib:IsPlayerInArea(2444, 3052, 0, 20) then
            Interact:NPC("Uglug Nar", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2442, 3088, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2444, 2, 2), Slib:RandomNumber(3052, 2, 2), 0)

        else
            UsePoa("2","2")
        end
    end,

    [13022] = function() --Zanaris fairy nuff. DONE
        if Slib:IsPlayerInArea(2387, 4473, 0, 3) then
            Interact:NPC("Fairy Nuff", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2387, 4468, 0, 2) then
            if Slib:FindObj2(52474, 10, 12, 2387, 4469, 1).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Slib:MoveTo(Slib:RandomNumber(2387, 1, 1), Slib:RandomNumber(4472, 1, 1), 0)
            end

        elseif Slib:IsPlayerInArea(2414, 4434, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(2387, 1, 1), Slib:RandomNumber(4468, 1, 1), 0)

        else
            UseGote("Zanaris")
            --Slib:RandomSleep(3500, 4500, "ms")
        end
    end,

    [13024] = function() -- Al kharid camel puzzle. DONE
        if HasSlidePuzzle() then
            Interact:NPC("Cam the Camel", "Talk to", 10)

        elseif Slib:IsPlayerInArea(3284, 3232, 0, 20) then
            Interact:NPC("Cam the Camel", "Talk to", 10)

        elseif Slib:IsPlayerInArea(3314, 3237, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(3284, 1, 1), Slib:RandomNumber(3232, 1, 1), 0)

        else
            UsePoa("2","1")
        end
    end,

    [13026] = function() --Ninto puzzle. DONE
        if Slib:IsPlayerInArea(2875, 9880, 0, 50) then
            Interact:NPC("Captain Ninto", "Talk to", 50)

        elseif Slib:IsPlayerInArea(2878, 3442, 0, 20) then
            Interact:Object("Cave", "Enter", 20)

        else
            LODESTONES.TAVERLEY.Teleport()
        end
    end,

    [13028] = function() --Ardougne zenesha. DONE
        if Slib:IsPlayerInArea(2660, 3292, 0, 1) or Slib:IsPlayerInArea(2658, 3292, 0, 1) or Slib:IsPlayerInArea(2656, 3292, 0, 1)then
            Interact:NPC("Zenesha", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2660, 3295, 0, 3) then
            if Slib:FindObj2(34807, 10, 12, 2660, 3294, 2).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Interact:NPC("Zenesha", "Talk to", 20)
                IdleCycles = 12
            end

        elseif Slib:IsPlayerInArea(2659, 3303, 0, 8) then
            Slib:MoveTo(Slib:RandomNumber(2660, 1, 1), Slib:RandomNumber(3295, 1, 1), 0)

        else
            UseSpellbookTeleport("Ardougne")
        end
    end,

    [13030] = function() --Wizards tower cellar. DONE
        if Slib:IsPlayerInArea(2594, 9486, 0, 20) then
            Interact:NPC("Wizard Frumscone", "Talk to", 20)

        elseif Slib:IsPlayerInArea(2586, 3088, 0, 2) then
            if Interact:Object("Ladder", "Climb-down", 20) then
                Slib:SleepUntil(function()
                    return Slib:IsPlayerInArea(2594, 9486, 0, 20)
                end, 20, 100)
            end

        elseif Slib:IsPlayerInArea(2577, 3089, 0, 6) then
            Interact:Object("Magic guild door", "Open", 20)
            IdleCycles = 5

        else
            UseSpellbookTeleport("Yanille")
        end
    end,

    [13032] = function() --Miscellania queen sigrid. DONE
        if Slib:IsPlayerInArea(2506, 3860, 1, 20) then
            Interact:NPC("Queen Sigrid", "Talk to", 20)

        else
            UseLotdTeleport("1")
        end
    end,

    [13034] = function() -- Odd old man. DONE.
        if Slib:IsPlayerInArea(3363, 3503, 0, 30) then
            Interact:NPC("Odd Old Man", "Talk to", 30)

        else
            UseSpellbookTeleport("OddOldMan")
        end
    end,

    [13036] = function() --Braindeath island. DONE
        if Slib:IsPlayerAtCoords(2133, 5162, 0) then
            UseSpade()

        elseif Slib:IsPlayerInArea(2126, 5144, 0, 10) then
            Slib:MoveTo(2133, 5162, 0)          

        else
            DungeoneeringCapeTeleport("8")
        end
    end,

    [13038] = function() --Barbarian outpost. DONE
        if Slib:IsPlayerAtCoords(2519, 3594, 0) then
            UseSpade()

        elseif Slib:IsPlayerInArea(2520, 3571, 0, 6) then
            Slib:MoveTo(2519, 3594, 0)

        else
            UsePoa("5","2")
        end
    end,

    [13040] = function() --Tower of life. Uses kandarin monastery. DONE
        if Slib:IsPlayerInArea(2668, 3243, 1, 20) then
            Interact:Object("Drawers", "Search", 20)

        elseif Slib:IsPlayerInArea(2663, 3240, 0, 3) then
            if Slib:FindObj2(126965, 10, 12, 2665, 3240, 6).Bool1 == 0 then
                Interact:Object("Large door", "Open", 20)
            else
                Interact:Object("Stairs", "Climb up", 20)
                Slib:SleepUntil(function()
                    return Slib:IsPlayerInArea(2668, 3243, 1, 20)
                end, 20, 100)
            end

        elseif Slib:IsPlayerInArea(2604, 3216, 0, 10) then
            Slib:MoveTo(Slib:RandomNumber(2663, 1, 1), Slib:RandomNumber(3240, 1, 1), 0)

        else
            UseSpellbookTeleport("KandarinMonastery")
        end
    end,

    [13041] = function() --lletya. DONE
        if Slib:IsPlayerInArea(2340, 3185, 0, 3) then
            Interact:Object("Crate", "Search", 10)
            
        elseif Slib:IsPlayerInArea(2330, 3172, 0, 5) then
            Slib:MoveTo(Slib:RandomNumber(2340, 1, 1), Slib:RandomNumber(3185, 1, 1), 0)

        else
            CrystalSeedTeleport("1")
        end
    end,

    [13042] = function() --Karamja gnome glider. DONE
        if Slib:IsPlayerInArea(2969, 2974, 0, 1) then
            UseSpade()

        elseif Slib:IsPlayerInArea(2950, 2977, 0, 3) then
            Slib:MoveTo(2969, 2974, 0)

        else
            checkGoteEquip()
            API.RandomSleep2(600, 300, 1200)
            --Inventory:DoAction(44550, "Overgrown idols", API.OFF_ACT_GeneralInterface_route)

            API.DoAction_Interface(0xffffffff,0xae06,3,1464,15,2,API.OFF_ACT_GeneralInterface_route)

            Slib:SleepUntil(function()
                return Slib:IsPlayerInArea(2950, 2977, 0, 20)
            end, 6, 100) 
        Slib:RandomSleep(1000, 2000, "ms") 
        end
    end,

    [13046] = function() -- Nardah. DONE
        if Slib:IsPlayerAtCoords(3395, 2917, 0) then
            UseSpade()

        elseif Slib:IsPlayerInArea(3430, 2916, 0, 15) then
            Slib:MoveTo(3395, 2917, 0)

        else
            API.DoAction_Inventory1(27094,0,3,API.OFF_ACT_GeneralInterface_route)
            Slib:SleepUntil(function()
                return Slib:IsPlayerInArea(3430, 2916, 0, 20)
            end, 6, 100)
             Slib:RandomSleep(4000, 4500, "ms")
        end
    end,

    [13048] = function() --Fremennik market. DONE
        if Slib:IsPlayerInArea(2645, 3664, 0, 5) then
            if Slib:FindObj2(4247, 10, 12, 2645, 3663, 2).Bool1 == 0 then
                Interact:Object("Door", "Open", 20)
            else
                Interact:Object("Crate", "Search", 20)
            end

        elseif Slib:IsPlayerInArea(2641, 3678, 0, 15) then
            Slib:MoveTo(2645, 3664, 0)

        else
            API.DoAction_Inventory1(19766,0,7,API.OFF_ACT_GeneralInterface_route2) --Fremennik boots tp
            Slib:RandomSleep(4000, 4500, "ms")
        end
    end,

    [13049] = function()
        if Slib:IsPlayerInArea(2993, 3687, 0, 2) then
            Interact:Object("Crate", "Search", 20)

        elseif Slib:IsPlayerInArea(3143, 3635, 0, 20) then
            Slib:MoveTo(2993, 3687, 0)

        else
            Slib:Error("New clue step. Check code for step: " .. ClueStepId)
            ReasonForStopping = "Check code for step " .. ClueStepId
            API.Write_LoopyLoop(false)
        end
    end,

    [33269] = function() --Near fishing guild. DONE
        if Slib:IsPlayerAtCoords(2632, 3407, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(2615, 3385, 0, 20) then
            Slib:MoveTo(2632, 3407, 0)

        else
            UsePoa("1","1")
        end
    end,

    [33272] = function() -- Taverley crop. DONE
        if Slib:IsPlayerAtCoords(2895, 3398, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(2911, 3421, 0, 20) then
            Slib:MoveTo(2895, 3398, 0)

        else
            API.DoAction_Interface(0xffffffff,0xffffffff,1,1461,1,207,API.OFF_ACT_GeneralInterface_route)
            Slib:SleepUntil(function()
            return Slib:IsPlayerInArea(2911, 3421, 0, 10)
            end, 6, 100)
            Slib:RandomSleep(1500, 2000, "ms") 
        end
    end,

    [33275] = function() --Karamja jungle near nature altar. DONE
        if Slib:IsPlayerAtCoords(2888, 3044, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(2801, 3003, 0, 20) then
            Slib:MoveTo(2888, 3044, 0)

        else
            UseFairyring("CKR")
        end
    end,

    [33278] = function() --South yanille. DONE
        if Slib:IsPlayerAtCoords(2603, 3063, 0) or Slib:IsPlayerAtCoords(2601, 3062, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(2523, 3061, 0, 20) then
            Slib:MoveTo(2601, 3062, 0)

        elseif Slib:IsPlayerInArea(2629, 3087, 0, 20) then
            Slib:MoveTo(2603, 3063, 0)

        elseif Slib:IsPlayerInArea(2616, 3105, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2628, 1, 1), Slib:RandomNumber(3077, 1, 1), 0)

        elseif Slib:IsPlayerInArea(2574, 3091, 0, 20) then
            Slib:MoveTo(Slib:RandomNumber(2616, 1, 1), Slib:RandomNumber(3105, 1, 1), 0)

        else

        local used = UseGlobetrotterArmguards("4")

        if not used then
            UseSpellbookTeleport("Yanille")
        end
    end
    end,

    [33281] = function() --Eagles peak lode. DONE
        if Slib:IsPlayerAtCoords(2363, 3461, 0) then
            UseMeerkat()

        elseif Slib:IsPlayerInArea(2366, 3479, 0, 20) then
            Slib:MoveTo(2363, 3461, 0)

        else
            LODESTONES.EAGLES_PEAK.Teleport()
        end
    end,

    [999999] = function()
        --This is here to prevent crashing if no clue is found
        Slib:Warn("No clue found; Maybe lag? Sleeping. This is attempt " .. Retries .. "/5.")
        Slib:RandomSleep(1000, 3000, "ms")
        Retries = Retries + 1
        if Retries > 5 then
            Slib:Error("Retries greater than 5. Exiting.")
            ReasonForStopping = "Retries greater than 5."
            API.Write_LoopyLoop(false)
            return
        end
    end
}

local function GetMinutesToNextEvent()
    local url = "https://wilderness.spegal.dev/api/?t=" .. os.time()
    
    local response = Http:Get(url)
    
    local ok, data = pcall(API.JsonDecode, response and response.body or "{}")

    if ok and data and data.time then
        return tonumber(data.time)
    end
    return nil
end

local function LoadPreset(PresetNumber)

    print("Opening Bank to load preset...")
    Interact:Object("Bank chest", "Use", 20)
    
    Slib:SleepUntil(function()
        return BANK:IsOpen()
    end, 6, 600)

    BANK:LoadPreset(PresetNumber)
    Slib:RandomSleep(1200, 1500, "ms")
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

        if secondsUntilEvent < -60 then
            EventTargetTimestamp = nil
            return
        end
        
        if secondsUntilEvent <= 80 then
            print("Time to event < 1 mins! Starting WildernessFlashEvents...")
            
            WarsTeleport()
            Interact:Object("Bank chest", "Use", 20)
            Slib:SleepUntil(function() return BANK:IsOpen() end, 6, 100)

            BANK:SavePreset(CLUE_PRESET) 
            
            local scriptLoaded, err = pcall(dofile, "C:\\Users\\pyrya\\MemoryError\\Lua_Scripts\\WildernessFlashEvents.lua")

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

        Slib:SleepUntil(function()
            return BANK:IsOpen()
        end, 6, 100)
        
        BANK:SavePreset(CLUE_PRESET) 
        
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
        end
    end
end

API.Write_fake_mouse_do(false)
while API.Read_LoopyLoop() do

    if ENABLE_WILDERNESS_EVENTS then
        ManageWildernessEvent(CLUE_PRESET)
    end

    if ENABLE_HERB_RUNS then
        ManageHerbRuns(CLUE_PRESET)
    end

    if IsFirstRun then
        if not OnlyOnceSafetyChecks() then
            API.Write_LoopyLoop(false)
            break
        end
        IsFirstRun = false
    end

    if not RecurringSafetyChecks() then
        API.Write_LoopyLoop(false)
        break
    end
    
    --Start skip checks
    if IdleCycles > 0 then
        Slib:Info("Idle cycles greater than 0. Skipping cycle.")
        goto continue
    elseif API.IsPlayerMoving_(API.GetLocalPlayerName()) then
        Slib:Info("Player moving. Skipping cycle.")
        IdleCycles = 2
        goto continue
    elseif DialogBoxIsOpen() then
        if HasOption() then
            Slib:Info("Dialog box open. Has option. Selecting option.")
            OptionSelector(DialogOptions)
        else
            Slib:Info("Dialog box open. Sending spacebar and skipping cycle.")
            API.KeyboardPress2(0x20, 40, 60)
            goto continue
        end
    end
    --End skip checks

    --Death Check
    if Slib:FindObj(27299, 50, 1) ~= nil then
        Slib:Error("You dead, consider destroying the clue for step: " .. ClueStepId)
        ReasonForStopping = "Dead. Consider destroying the clue for step: " .. ClueStepId
        API.Write_LoopyLoop(false)
    end

    --Stuck in clue interface check
    if InterfaceIsOpen("ClueScroll") then
        API.DoAction_Interface(0x24,0xffffffff,1,345,13,-1,API.OFF_ACT_GeneralInterface_route) --Close clue scroll interface
    end

    --Wizard combat check
    if API.LocalPlayer_IsInCombat_() and not ShouldSkipCombat() then
        Slib:Info("Player in combat. Checking for wizard.")
        AttackWizards()
    end
    
    --Familiar check
    --[[ if Familiars:HasFamiliar() and Familiars:GetName() ~= "Meerkats" then
        Slib:Error("Familiar is not a meerkat. Exiting.")
        ReasonForStopping = "Familiar is not a meerkat."
        API.Write_LoopyLoop(false)
        goto continue
    elseif not Familiars:HasFamiliar() or Familiars:GetTimeRemaining() < 5 then
        if Inventory:ContainsAny(OtherIDsNeededForStuff["SuperRestores"]) then
            API.DoAction_Inventory2(OtherIDsNeededForStuff["SuperRestores"], 0, 1, API.OFF_ACT_GeneralInterface_route) --Drink super restore
            Slib:RandomSleep(600, 3000, "ms")
            API.DoAction_Inventory1(OtherIDsNeededForStuff["Meerkat"],0,1,API.OFF_ACT_GeneralInterface_route) --Summon meerkats
            Slib:RandomSleep(1200, 1800, "ms")
        else
            Slib:Error("No super restore found in inventory to renew familiar.")
            ReasonForStopping = "No super restore found in inventory to renew familiar."
            API.Write_LoopyLoop(false)
            goto continue
        end
    end    

    if not HasScrolls() then
       Slib:Error("No meerkat scrolls found. Exiting.")
       ReasonForStopping = "No meerkat scrolls found."
       API.Write_LoopyLoop(false)
       goto continue
    end ]]

    --Slide puzzle check
    if HasSlidePuzzle() then
        SolveSlidePuzzle()
    end

    ClueStepId = GetClueStepId()

    Slib:Info("Clue step id: " .. ClueStepId)
    ClueSteps[ClueStepId]() 

    ::continue::
    IdleCycles = IdleCycles - 1
    StepItems = {}
    Slib:RandomSleep(200, 400, "ms")    
    collectgarbage("collect")
end

API.Write_LoopyLoop(false)
MetricsTable[7] = {"Reason for Stopping:", ReasonForStopping}
API.DrawTable(MetricsTable)
Slib:Info("----------//----------")
Slib:Info("Script Name: " .. ScriptName)
Slib:Info("Author: " .. Author)
Slib:Info("Version: " .. ScriptVersion)
Slib:Info("Release Date: " .. ReleaseDate)
Slib:Info("Discord: " .. DiscordHandle)
Slib:Info("----------//----------")