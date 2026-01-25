local API = require("api")
local PrayerFlicker = require("prayer_flicker")

local prayers = {
    { name = "Soul Split", buffId = 26033 },
    { name = "Deflect Melee", buffId = 26040 },
    { name = "Deflect Magic", buffId = 26041 },
    { name = "Deflect Ranged", buffId = 26044 },
    { name = "Deflect Necromancy", buffId = 30745 },
    { name = "Resonance", buffId = 14222 }
}

local function isResonanceActive()
    return API.Buffbar_GetIDstatus(14222, false).id > 0
end



local npcs = {
    {
        id = 30629,  -- npc id
        animations = {
            {
                animId = 35833,         -- animation id
                prayer = {            -- prayer to switch to
                    name = "Resonance", 
                    buffId = 14222
                },
                bypassCondition = function()
                    return isResonanceActive()
                end,
                activationDelay = 2,  -- delay before prayer switch (in game ticks)
                duration = 3,         -- no. of game ticks to keep prayer active
                priority = 1,         -- threat priority: bigger numbers get priority
            },
            {
                animId = 35835,         -- animation id
                prayer = {            -- prayer to switch to
                    name = "Deflect Melee", 
                    buffId = 26040
                },
                bypassCondition = function()
                    return isResonanceActive()
                end,
                activationDelay = 2,  -- delay before prayer switch (in game ticks)
                duration = 3,         -- no. of game ticks to keep prayer active
                priority = 1,         -- threat priority: bigger numbers get priority
            }
        }
    }
}

local projectiles = {
    {
        id = 8107,                     -- projectile id
        prayer = {
            name = "Deflect Necromancy", 
            buffId = 26044
        },
        bypassCondition = function()  -- Ignore projectile if Resonance is active
            return isResonanceActive()
        end,
        activationDelay = 1,          
        duration = 1,                 
        priority = 1                  
    },
    {
        id = 8166,  -- Another projectile ID
        prayer = {
            name = "Deflect Ranged", 
            buffId = 26044
        },
        bypassCondition = function()  -- Ignore projectile if Resonance is active
            return isResonanceActive()
        end,
        activationDelay = 1,
        duration = 1,
        priority = 1
    },
}

local conditionals = {
    {
        condition = function()         -- custom condition function
            return isNearChaosTrap()
        end,
        prayer = {
            name = "Soul Split", 
            buffId = 26033
        },
        priority = 15                  -- threat priority: bigger numbers get priority
    }
}

local config = {
    defaultPrayer = { name = "Soul Split", buffId = 26033 },
    prayers = prayers,
    projectiles = projectiles,
    npcs = npcs,
    conditionals = conditionals
}

local prayerFlicker = PrayerFlicker.new(config)

while API.Read_LoopyLoop() do
    if true then
        prayerFlicker:update() -- manages overhead prayers
    else
        prayerFlicker:deactivatePrayer()
    end

    API.RandomSleep2(100, 30, 20)
end