local API = require("api")
local UTILS = require("utils")

Write_fake_mouse_do(false)
API.SetMaxIdleTime(10)

--fish_ids = {25224}  -- Only fishing for normal blue blubber

local function waitForInterface()
    return UTILS.SleepUntil(UTILS.isDeepseaRandomInterfaceOpen, 20, "Waiting for interface to open")
end

local function waitForChatInterface()
    return UTILS.SleepUntil(UTILS.isChooseOptionInterfaceOpen, 20, "Waiting for interface to open")
end

local function waitForBottleInterface()
    return UTILS.SleepUntil(UTILS.isCookingInterfaceOpen, 20, "Waiting for interface to open")
end

local function handleRandoms()
    if Inventory:Contains(42286) then --Fishing Notes
        API.DoAction_Inventory1(42286,0,1,API.OFF_ACT_GeneralInterface_route)
        waitForInterface()
        API.KeyboardPress("y", 100, 200)
    end

    if Inventory:Contains(42283) then --Barrel of bait
        API.DoAction_Inventory1(42283,0,1,API.OFF_ACT_GeneralInterface_route)
        waitForInterface()
        API.KeyboardPress("y", 100, 200)
    end

    --[[
    if Inventory:Contains(42285) then --Tangled fishbowl TEST
        API.DoAction_Inventory1(42285,0,1,API.OFF_ACT_GeneralInterface_route)
        waitForInterface()
        API.KeyboardPress("y", 100, 200)
    end

    if Inventory:Contains(42284) then --Broken fishing rod TEST
        API.DoAction_Inventory1(42284,0,1,API.OFF_ACT_GeneralInterface_route)
        waitForInterface()
        API.KeyboardPress("y", 100, 200)
    end

    if Inventory:Contains(42282) then --Message in a bottle TEST, might be okay
        API.DoAction_Inventory1(42282,0,1,API.OFF_ACT_GeneralInterface_route)
        waitForChatInterface()
        API.KeyboardPress2(0x20, 100, 200)
        waitForBottleInterface()
        API.DoAction_Interface(0xffffffff,0xffffffff,0,751,50,-1,API.OFF_ACT_GeneralInterface_Choose_option)
    end
    --]]
end

local function animCheck()
    if API.CheckAnim(50) or API.ReadPlayerMovin2() then
        return true
    else
        return false
    end
end

local function debuffStatus()
    local debuff = API.DeBuffbar_GetIDstatus(33045, false)
    
    if debuff and debuff.text then
        local value = tonumber(debuff.text)
        
        if value then
            return value
        else
            return 0
        end
    else
        return 0  -- Return 0 if debuff is missing
    end
end

local function depositFish()
    if Inventory:IsFull() then
        API.DoAction_Object1(0x3c, API.GeneralObject_route_useon, {110860}, 50)

        while Inventory:IsFull() do
            API.RandomSleep2(200, 100, 200)
        end

        return true
    end
    return false
end

--Very rare case when clicking blue blubber fish it turns to green while character is moving.

local function gatherFish(fish_id)
    API.DoAction_NPC(0x3c, API.OFF_ACT_InteractNPC_route, {fish_id}, 50)
    API.RandomSleep2(1000, 200, 200)

    local prevDebuffValue = debuffStatus()

    while debuffStatus() > 0 do
        local currentDebuffValue = debuffStatus()
        --print("Debuffed, current value: " .. currentDebuffValue)

        -- Fail-safe: If debuff value has increased, break out of the loop
        if currentDebuffValue > prevDebuffValue then
            print("Debuff value increased, exiting loop.")

            local playerTile = API.PlayerCoord()
            API.DoAction_WalkerW(playerTile)
            API.RandomSleep2(600, 200, 200)
            break
        end

        prevDebuffValue = currentDebuffValue

        if animCheck() then
            API.RandomEvents()
            API.RandomSleep2(600, 200, 200)
        else
            break
        end
    end

    while animCheck() do
        --print("Moved to anim check")
        handleRandoms()
        API.RandomEvents()

        local debuffValue = debuffStatus()

        if debuffValue > 0 then
            break
        end
        UTILS.countTicks(1)
    end
    if depositFish() then
        return
    end
end


local function getFish()
    local normal = API.ReadAllObjectsArray({1}, {25224}, {})[1]  -- Blue blubber (normal fish)
    return normal
end


-- Main loop
API.Write_LoopyLoop(true)
while API.Read_LoopyLoop() do
    local normal = getFish()

    if normal then
        print("Normal fish found")
        gatherFish(25224)
    else
        print("No fish found")
    end
    API.RandomSleep2(600, 200, 2000)
end