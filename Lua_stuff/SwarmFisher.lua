local API = require("api")
local UTILS = require("utils")

Write_fake_mouse_do(false)
API.SetMaxIdleTime(10)

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
    
    if Inventory:Contains(42285) then --Tangled fishbowl
        API.DoAction_Inventory1(42285,0,1,API.OFF_ACT_GeneralInterface_route)
        waitForInterface()
        API.KeyboardPress("y", 100, 200)
    end

    --[[
    if Inventory:Contains(42284) then --Broken fishing rod TEST
        API.DoAction_Inventory1(42284,0,1,API.OFF_ACT_GeneralInterface_route)
        waitForInterface()
        API.KeyboardPress("y", 100, 200)
    end
    --]]

    if Inventory:Contains(42282) then --Message in a bottle
        API.DoAction_Inventory1(42282,0,1,API.OFF_ACT_GeneralInterface_route)
        waitForChatInterface()
        API.KeyboardPress2(0x20, 100, 200)
        waitForBottleInterface()
        API.DoAction_Interface(0xffffffff,0xffffffff,0,751,50,-1,API.OFF_ACT_GeneralInterface_Choose_option)
    end
end

local function animCheck()
    if API.CheckAnim(50) or API.ReadPlayerMovin2() then
        return true
    else
        return false
    end
end


local function depositFish()
    if Inventory:IsFull() then
        API.DoAction_Object1(0x29,API.OFF_ACT_GeneralObject_route2,{ 110857 },50);

        while Inventory:IsFull() do
            API.RandomSleep2(200, 100, 200)
        end

        return true
    end
    return false
end

local function gatherFish(fish_id)
    API.DoAction_NPC(0x3c, API.OFF_ACT_InteractNPC_route, {fish_id}, 50)
    API.RandomSleep2(1000, 200, 200)

    while animCheck() do
        --print("Moved to anim check")
        handleRandoms()
        API.DoRandomEvents(200, 200)
        UTILS.countTicks(1)
    end

    if depositFish() then
        return
    end
end

-- Main loop
API.Write_LoopyLoop(true)
while API.Read_LoopyLoop() do
    
    gatherFish(25220)
    API.RandomSleep2(600, 200, 2000)
end