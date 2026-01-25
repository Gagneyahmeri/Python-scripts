local API = require("api")
local LODESTONES = require("lodestones")       
local UTILS = require("utils")
local Slib = require("slib")
local BANK = require("bank")


local OtherIDsNeededForStuff = {
    ["WildernessSword"] = 37907,
    ["WarsTeleport"] = 35042,
    ["EnhancedExcalibur"] = 36619
}

local Interfaces = {
    ["Teleports"] = { { 720, 2, -1, 0 }, { 720, 17, -1, 2 } },
    ["Bank"] = { { 517,0,-1,0 }, { 517,1,-1,0 } }
}

local Enemies = {
    "Pyrefiend",
    "Spire",
    "King Black Dragon",
    "Wildywyrm"
}

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

local function InterfaceIsOpen(interfaceName)
    return #API.ScanForInterfaceTest2Get(true, Interfaces[interfaceName]) > 0
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
        Slib:RandomSleep(1200, 2000, "ms")
        Slib:TypeText(key2)
    end   
    Slib:RandomSleep(4000, 5000, "ms") 
end

local function CastExcalibur()
    if not Slib:CanCastAbility(OtherIDsNeededForStuff["EnhancedExcalibur"]) then
        Slib:Error("Enhanced Excalibur not found or not available in ability bar. Halting script.")
        ReasonForStopping = "Enhanced Excalibur not found or not available in ability bar."
        API.Write_LoopyLoop(false)
        return
    end

    local EnhancedExcalibur = API.GetABs_id(OtherIDsNeededForStuff["EnhancedExcalibur"])
    API.DoAction_Ability_Direct(EnhancedExcalibur, 1, API.OFF_ACT_GeneralInterface_route)
end

local function InterfaceIsOpen(interfaceName)
    return #API.ScanForInterfaceTest2Get(true, Interfaces[interfaceName]) > 0
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

local function checkEvent()
    if Slib:IsPlayerInArea(3255, 3624, 0, 30) then
        return InfernalStarEvent

    elseif Slib:IsPlayerInArea(3364, 3688, 0, 50) then
        return KingBlackDragonEvent

    elseif Slib:IsPlayerInArea(3102, 3625, 0, 30) then
        return EvilBloodwoodTreeEvent

    elseif Slib:IsPlayerInArea(3139, 3804, 0, 50) then
        return StrykeTheWyrmEvent
    end

    return nil
end

local function CheckObject(id, distance, types)
    local obj = API.GetAllObjArrayInteract(id, distance, types)
    return (obj ~= nil and #obj > 0)
end

local function AttackEnemies()
    local EnemyToAttack = nil
    local Interacting = API.ReadLpInteracting()
    local Objs = API.GetAllObjArrayInteract_str(Enemies, 20, {1})

    if Objs and #Objs > 0 then
        for i = 1, #Objs do
            if Objs[i] and Objs[i].Id then
                EnemyToAttack = Objs[i].Name

                if Interacting then
                    if Interacting.Name ~= EnemyToAttack then
                        Interact:NPC(EnemyToAttack, "Attack", 30)
                    end
                else
                    Interact:NPC(EnemyToAttack, "Attack", 30)
                end

                break
            end
        end
    else
        return
    end
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

local function EnablePray(prayerList)
    
    if type(prayerList) == "number" then
        prayerList = { prayerList }
    end

    local currentBuffs = API.Buffbar_GetAllIDs()
    local activeBuffsSet = {}

    if currentBuffs then
        for i = 1, #currentBuffs do
            local buff = currentBuffs[i]
            if buff and buff.id then
                activeBuffsSet[buff.id] = true
            end
        end
    end

    for _, prayerID in ipairs(prayerList) do
        
        if activeBuffsSet[prayerID] then
            print("Prayer " .. prayerID .. " is already active. Skipping.")
        else
            local slotID = prayIDs[prayerID]

            if slotID then
                print("Enabling Prayer: " .. prayerID .. " (Slot " .. slotID .. ")")
                API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1458, 40, slotID, API.OFF_ACT_GeneralInterface_route)
                API.RandomSleep2(100, 200, 100)
            else
                print("Error: Prayer ID " .. prayerID .. " is not defined in prayIDs table.")
            end
        end
    end
end

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

local function ChangeAbilityBar()
    if API.isAbilityAvailable("Death Skulls") then
        --print("Finger of Death is available.")
    else
        API.DoAction_Interface(0xffffffff,0xffffffff,7,1430,255,-1,API.OFF_ACT_GeneralInterface_route2)
        print("Changing ability bar...")
    end
end

local function handleXpLamps()
    if Inventory:Contains(53937) then
        API.DoAction_Inventory1(53937,0,8,API.OFF_ACT_GeneralInterface_route2) 
        Slib:RandomSleep(1200, 1800, "ms")
        Slib:TypeText("y")
        Slib:RandomSleep(1200, 1800, "ms")
    end
end

--star = 124772
--pyrefiend = 29608
function InfernalStarEvent()
    print("Running Infernal Star Event")

    Slib:SleepUntil(function()
        return CheckObject({124772}, 30, {0})
    end, 360, 600)
    Slib:RandomSleep(1200, 1500, "ms")

    print("Infernal Star detected! Mining...")
    Interact:Object("Infernal star", "Mine", 30)

    print("Waiting for Pyrefiends to spawn...")
    Slib:SleepUntil(function()
        return CheckObject({29608}, 30, {1})
    end, 360, 600)

    EnablePray(26033) -- Soul split

    while CheckObject({29608}, 30, {1}) and API.Read_LoopyLoop() do
        AttackEnemies()
        Slib:SleepUntil(function()
            return API.GetTargetHealth() < 1 or not CheckObject({29608}, 30, {1})
        end, 360, 600)
        Slib:RandomSleep(600, 1200, "ms")
    end
end


--kbd = 29609
--Spire = 29610
function KingBlackDragonEvent()
    print("Running KBD Event")

    Slib:SleepUntil(function()
        return CheckObject({29609}, 40, {1})
    end, 360, 600)

    EnablePray(26041) -- Enable deflect magic
    CastExcalibur()

    while CheckObject({29609}, 40, {1}) do
        AttackEnemies()
        Slib:RandomSleep(600, 1200, "ms")
    end
    

end

function StrykeTheWyrmEvent()
    print("Running Stryke the wyrm event")
    if not Slib:IsPlayerInArea(3141, 3809, 0, 2) then
        Slib:MoveTo(3141, 3809, 0)
    end

    Slib:SleepUntil(function()
        return CheckObject({30798}, 30, {1})
    end, 360, 600)

    EnablePray(26033) -- soul split
    CastExcalibur()

    while CheckObject({30798}, 30, {1}) do

        if not Slib:IsPlayerInArea(3141, 3809, 0, 2) then
            Slib:MoveTo(3141, 3809, 0)
        end
        AttackEnemies()
        Slib:RandomSleep(600, 1200, "ms")
    end
    

end


function EvilBloodwoodTreeEvent()
    print("Running Evil Bloodwood Tree Event")

    local function GetPhase()
        if CheckObject({124775}, 30, {0}) then return 3 end
        if CheckObject({124774}, 30, {0}) then return 2 end
        if CheckObject({124773}, 30, {0}) then return 1 end
        return 0
    end

    -----------------------------------------
    -- PHASE 1
    -----------------------------------------
    local function Phase1()
        print("Phase 1 – Nurturing Bloody Sapling")

        while CheckObject({124773}, 30, {0}) and API.Read_LoopyLoop() do
            
            Interact:Object("Skeleton", "Take bones", 10)

            Slib:SleepUntil(function()
                return not API.ReadPlayerMovin() and not API.CheckAnim(30)
            end, 18, 600)

            if Inventory:Contains(53935) then
                API.DoAction_Inventory1(53935,0,1,API.OFF_ACT_GeneralInterface_route) --Grind bones
                Slib:RandomSleep(600, 800, "ms")
            end

            if Inventory:Contains(53936) then
                Interact:Object("Bloody sapling", "Nurture", 10)
                Slib:SleepUntil(function()
                    return not Inventory:Contains(53936)
                end, 10, 600)
            end
        end
    end

    -----------------------------------------
    -- PHASE 2
    -----------------------------------------
    local function Phase2()
        print("Phase 2 – Evil Bloodwood Tree active")
        Slib:RandomSleep(1200, 1600, "ms")
        Interact:Object("Evil bloodwood tree", "Chop", 30)
        Slib:RandomSleep(2000, 2200, "ms")

        Slib:SleepUntil(function()
            return not API.CheckAnim(20)
        end, 240, 600)
    end

    -----------------------------------------
    -- PHASE 3
    -----------------------------------------
    local function Phase3()
        print("Phase 3 – Butchered bloodwood tree detected")
        local fireSpirits = {29603, 29604, 29605, 29606}

        if Inventory:Contains(53934) then
            Interact:Object("Butchered bloodwood tree", "Burn kindling", 30) --Dump kindlings from previous phase
            Slib:SleepUntil(function()
                return not Inventory:Contains(53934)
            end, 10, 600)
        end

        while CheckObject(fireSpirits, 30, {1}) and API.Read_LoopyLoop() do

            Interact:NPC("Fire spirit", "Harvest kindling", 30)

            Slib:SleepUntil(function()
                return not API.ReadPlayerMovin() and not API.CheckAnim(10)
            end, 10, 600)
            --Slib:RandomSleep(600, 800, "ms")

            if Inventory:IsFull() then
                Interact:Object("Butchered bloodwood tree", "Burn kindling", 30)
                Slib:SleepUntil(function()
                    return not Inventory:Contains(53934)
                end, 10, 600)
            end
        end

        if Inventory:Contains(53934) then
            Interact:Object("Butchered bloodwood tree", "Burn kindling", 30) --Dump kindlings
            Slib:SleepUntil(function()
                return not Inventory:Contains(53934)
            end, 10, 600)
        end
    end

    Slib:SleepUntil(function()
        return CheckObject({124773, 124774, 124775}, 30, {0})
    end, 360, 600)

    while API.Read_LoopyLoop() do
        local phase = GetPhase()

        if phase == 1 then Phase1()
        elseif phase == 2 then Phase2()
        elseif phase == 3 then Phase3()
        else
            print("No event detected — ending.")
            break
        end

        Slib:RandomSleep(600, 800, "ms")
    end
end


API.Write_LoopyLoop(true)
while API.Read_LoopyLoop() do
    
    local inEventArea = (
        Slib:IsPlayerInArea(3255, 3624, 0, 50) -- Star
        or Slib:IsPlayerInArea(3357, 3635, 0, 50) -- KBD
        or Slib:IsPlayerInArea(3102, 3625, 0, 50) -- Tree
        or Slib:IsPlayerInArea(3139, 3804, 0, 50) -- Stryke
    )

    if not inEventArea then
        WarsTeleport()
        ChangeAbilityBar()
        DisablePray()
        LoadPreset(4)
        WildernessSwordTeleport("1", "6")
    end

    local eventFunc = checkEvent()

    if eventFunc ~= nil then
        eventFunc()
        print("Event finished. Teleporting to War's Retreat...")
        WarsTeleport()
        DisablePray()
        handleXpLamps()
        break
    end
    API.RandomSleep2(100, 100, 100)
end