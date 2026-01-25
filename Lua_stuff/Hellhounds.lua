local API = require("api")
local Slib = require("slib")

API.Write_fake_mouse_do(false)
API.SetMaxIdleTime(5)

local IsFirstRun = true

local OtherIDsNeededForStuff = {
    ["DungeoneeringCape"] = 18509
}

local function OnlyOnceSafetyChecks()

    local autoRetaliateEnabled = API.GetVarbitValue(42166)
    --print("Auto retaliate varbit value: " .. tostring(autoRetaliateEnabled))

    if autoRetaliateEnabled ~= 0 then
        Slib:Error("Auto retaliate is NOT enabled. Halting script.")
        ReasonForStopping = "Auto retaliate is NOT enabled."
        API.Write_LoopyLoop(false)
        return false
    end

    if API.isAbilityAvailable("Backhand") then
        --print("Backhand is available.")
    else
        print("Changing ability bar...")
        API.DoAction_Interface(0xffffffff,0xffffffff,a,1430,255,-1,API.OFF_ACT_GeneralInterface_route2)
    end
    return true
end

--------------------START SAFETY CHECKS--------------------

local function isSoulSplitActive()
    return (API.VB_FindPSettinOrder(3275).state >> 18) & 1 == 1
end

local function isTurmoilActive()
    if API.Buffbar_GetIDstatus(26019, false).id > 0 then
        return true
    else
        return false
    end
end

local function RecurringSafetyChecks()

    --Charge pack check
    local chatTexts = API.GatherEvents_chat_check()
    for _, v in ipairs(chatTexts) do
        if (string.find(v.text, "Your charge pack has run out of power")) then
            print("Charge pack is empty!")
            API.DoAction_Ability("Retreat Teleport", 1, API.OFF_ACT_GeneralInterface_route)
            API.Write_LoopyLoop(false)
            return false
        end
    end

    --HP Check
    local hp = API.GetHPrecent()
    local pray = API.GetPray_()
    if hp < 10 then

        Slib:Error("Cache is not enabled. Halting script.")
        ReasonForStopping = "Cache is not enabled."
        API.Write_LoopyLoop(false)
        return false
    end

    --Prayer Check
    local pray = API.GetPray_()
    if pray < 100 then
        print("Prayer below 100%, teleporting out.")
        return false
    end

    if isSoulSplitActive() then
        --print("Soul split is active")
    else
        print("Enabling soul split")
        API.DoAction_Ability("Soul Split", 1, API.OFF_ACT_GeneralInterface_route, true)
        Slib:RandomSleep(1200, 1600, "ms")

        if isSoulSplitActive() then
            print("Soul split enabled successfully.")
        else
            print("Failed to enable soul split.")
            return false
        end
    end

    if isTurmoilActive() then
        --print("Turmoil is active")
    else
        print("Enabling turmoil")
        API.DoAction_Ability("Turmoil", 1, API.OFF_ACT_GeneralInterface_route, true)

        Slib:RandomSleep(1200, 1600, "ms")

        if isTurmoilActive() then
            print("Turmoil enabled successfully.")
        else
            print("Failed to enable turmoil.")
            return false
        end
    end


    return true
end
---------------------END SAFETY CHECKS--------------------


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
    --Slib:RandomSleep(1000, 2000, "ms")

    if InterfaceIsOpen("Teleports") then
        Slib:TypeText(key1)
        Slib:RandomSleep(1000, 1200, "ms")
        if key2 ~= nil then
            Slib:TypeText(key2)
        end
    end
    Slib:RandomSleep(4200, 4800, "ms")
end

local function resetAggro()
    if Slib:IsPlayerInArea(1370, 4575, 0, 5) and not API.LocalPlayer_IsInCombat_() then
        print("Resetting aggro.")
        Slib:MoveTo(Slib:RandomNumber(1390, 1, 1), Slib:RandomNumber(4587, 1, 1), 0)
        --Slib:MoveTo(1393, 4590, 0)

    elseif Slib:IsPlayerInArea(1390, 4587, 0, 2) then
        Interact:Object("Mysterious door", "Exit")
        Slib:SleepUntil(function()
            return Slib:IsPlayerInArea(2854, 9841, 0, 5)
        end, 6, 100)
        Slib:RandomSleep(600, 1200, "ms")

    elseif Slib:IsPlayerInArea(2854, 9841, 0, 5) then
        Interact:Object("Mysterious entrance", "Enter")
        Slib:SleepUntil(function()
            return Slib:IsPlayerInArea(1390, 4587, 0, 5)
        end, 6, 100)
        --Slib:RandomSleep(600, 1200, "ms")

    elseif Slib:IsPlayerAtCoords(1394, 4587, 0) then
        Slib:MoveTo(1371, 4575, 0)

        API.KeyboardPress2(0x09, 200, 300)
    end
end

local function lootItems()

    local floorItems = API.ReadAllObjectsArray({ 3 }, { -1 }, {})

    if #floorItems == 0 then
        --print("No items on the ground to loot.")
        return

    elseif not API.LootWindowOpen_2() and Slib:IsPlayerInArea(1370, 4575, 0, 20) then
        API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1678, 8, -1, API.OFF_ACT_GeneralInterface_route)
        print("Opening loot window.")

    elseif API.LootWindowOpen_2() and Slib:IsPlayerInArea(1370, 4575, 0, 20) then
        API.RandomSleep2(2000, 300, 2500)
        API.DoAction_Interface(0x24,0xffffffff,1,1622,22,-1,API.OFF_ACT_GeneralInterface_route)
        print("Looting items.")

        if Inventory:IsFull() then
            print("Inventory full, cannot loot more items.")
            API.DoAction_Interface(0x2e,0xffffffff,1,1673,105,-1,API.OFF_ACT_GeneralInterface_route) --wars tp
            API.Write_LoopyLoop(false)
        end
    end
end

while API.Read_LoopyLoop() do

    if IsFirstRun then
        if not OnlyOnceSafetyChecks() then
            print("One-time safety checks failed. Stopping script.")
            API.Write_LoopyLoop(false)
            break
        end
        IsFirstRun = false
    end

    if not RecurringSafetyChecks() then
        API.DoAction_Interface(0x2e,0xffffffff,1,1673,105,-1,API.OFF_ACT_GeneralInterface_route)
        API.Write_LoopyLoop(false)
        break
    end

    lootItems()
    resetAggro()
    API.RandomSleep2(1000, 250, 500)
end