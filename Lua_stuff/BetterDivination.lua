local API = require("api")
local UTILS = require("utils")

API.Write_LoopyLoop(true)
Write_fake_mouse_do(false)
API.SetMaxIdleTime(6)

-- Calculate the distance between two tiles
local function calculateDistance(tile1, tile2)
    return math.sqrt((tile1.x - tile2.x)^2 + (tile1.y - tile2.y)^2)
end

-- Check if the tile is within the valid region
local function isValidTile(tile)
    local x, y = tile.x, tile.y
    if x >= 2279 and x <= 2284 and y >= 3045 and y <= 3050 then --x == 2279-80 and y == 3050) exluded because if the tree is down. Character will move to bad position. Weird bug by jagex.
        if not ((x == 2281 or x == 2282) and (y == 3047 or y == 3048)) and not (x == 2279 and y == 3050) and not (x == 2280 and y == 3050) then
            return true
        end
    end
    return false
end

local function animCheck()
    API.DoRandomEvent(26022)
    return API.CheckAnim(80) or API.ReadPlayerMovin2()
end

local function moveCheck()
    return API.ReadPlayerMovin2()
end

local function getSprings()
    local enriched = API.ReadAllObjectsArray({1}, {18195}, {})[1]  -- Enriched Spring
    local normal = API.ReadAllObjectsArray({1}, {18171}, {})[1]  -- Normal Spring
    return enriched, normal
end

local function checkRift()
    local rift1 = API.ReadAllObjectsArray({12}, {87306}, {})[1]
    local rift2 = API.ReadAllObjectsArray({0}, {93489}, {})[1]

    if rift1 and rift2 then
        return {rift1, rift2}, "rift2"
    elseif rift1 then
        return rift1, "rift1"
    else
        return nil, "none"
    end
end

local function inventoryCheck()
    if Inventory:IsFull() then

        local activeRift, riftType = checkRift()

        if riftType == "rift1" then
            print("Only Rift 1 found. Performing specific action.")
            API.DoAction_Object1(0xc8, API.OFF_ACT_GeneralObject_route0, { 87306 }, 50)

        -- If both rifts are found, perform the "Energy Rift" interaction
        elseif riftType == "rift2" then
            print("Both rifts found. Performing energy rift action.")
            Interact:Object("Energy Rift", "Convert memories", 20)

        else
            print("No active rift found during inventory check!")
            return false
        end

        while Inventory:Contains(29406) or Inventory:Contains(29395) do
            API.RandomSleep2(200, 100, 200)
        end

        return true
    end
    return false
end

-- Get the closest valid tile to the enriched spring
local function getClosestValidTileToSpring(spring)
    local springCoord = {x = spring.Tile_XYZ.x, y = spring.Tile_XYZ.y}
    local closestTile = nil
    local minDistance = math.huge

    -- Check every tile in the valid area
    for x = 2279, 2284 do
        for y = 3045, 3050 do
            local tile = {x = x, y = y}
            if isValidTile(tile) then
                local distance = calculateDistance(springCoord, tile)
                if distance >= 2 and distance < minDistance then
                    minDistance = distance
                    closestTile = tile
                end
            end
        end
    end

    return closestTile, minDistance
end

--There might be a very rare case when interacting with normal wisp nearly same time as moving.
-- It will keep harvesting normal because anim check returns true for movin. Might be fixed with movecheck()
-- Move player to the closest valid tile using WPOINT.new(x, y, 0)
local function moveToTile(tile)
    if tile then
        if tile.x and tile.y then
            local wp = WPOINT.new(tile.x, tile.y, 0)  -- Create WPOINT from tile
            API.DoAction_WalkerW(wp)
            UTILS.countTicks(3)

            -- Wait for movement/animation to finish
            while moveCheck() do
                API.RandomSleep2(200, 200, 200)
            end

            -- Verify if player reached the destination
            local playerPos = API.PlayerCoord()
            if playerPos.x ~= tile.x or playerPos.y ~= tile.y then
                print(string.format("Player did not reach destination (%d, %d). Retrying move.", tile.x, tile.y))
                API.DoAction_WalkerW(wp)  -- Retry movement
                while moveCheck() do
                    API.RandomSleep2(200, 200, 200)
                end
            else
                print("Player successfully moved to tile:", tile.x, tile.y)
            end
        else
            print("Invalid tile format, missing x or y!")
        end
    else
        print("Tile is nil, cannot move!")
    end
end

-- Get a list of valid tiles that are not the same as the enriched spring's tile
local function getValidTilesExcludingSpring(enriched)
    local validTiles = {}
    local springTile = {x = enriched.Tile_XYZ.x, y = enriched.Tile_XYZ.y}

    -- Check every tile in the valid area
    for x = 2279, 2284 do
        for y = 3045, 3050 do
            local tile = {x = x, y = y}
            if isValidTile(tile) and (tile.x ~= springTile.x or tile.y ~= springTile.y) then
                table.insert(validTiles, tile)
            end
        end
    end
    return validTiles
end

-- Move player to another valid tile
local function moveToAnotherValidTile(excludingSpring)
    local validTiles = getValidTilesExcludingSpring(excludingSpring)
    local springCoord = {x = excludingSpring.Tile_XYZ.x, y = excludingSpring.Tile_XYZ.y}
    
    -- Filter out the valid tiles that are too close to the enriched spring (less than 2 tiles away)
    local validTilesFiltered = {}
    for _, tile in ipairs(validTiles) do
        local distance = calculateDistance(springCoord, tile)
        if distance >= 2 then
            table.insert(validTilesFiltered, tile)
        end
    end

    if #validTilesFiltered > 0 then
        -- Randomly pick a valid tile that is at least 2 tiles away from the enriched spring
        local newTile = validTilesFiltered[math.random(#validTilesFiltered)]  
        moveToTile(newTile)
    else
        print("No valid tiles available that are at least 2 tiles away from the enriched spring!")
    end
end

-- Check if the player is already on the closest valid tile
local function shouldSkipMoving(closestTile, enriched)
    local playerTile = API.PlayerCoord()

    local onClosestTile = playerTile.x == closestTile.x and playerTile.y == closestTile.y
    local distToEnriched = calculateDistance({x = playerTile.x, y = playerTile.y}, {x = enriched.Tile_XYZ.x, y = enriched.Tile_XYZ.y})

    return onClosestTile or distToEnriched <= 8
end

local function interactWithEnrichedSpring(enriched)
    local closestTile, minDistanceToEnriched = getClosestValidTileToSpring(enriched)
    local playerTile = API.PlayerCoord()
    local springTile = {x = enriched.Tile_XYZ.x, y = enriched.Tile_XYZ.y}
    local distanceToSpring = calculateDistance(playerTile, springTile)

    if distanceToSpring <= 8 then
        if distanceToSpring < 2 then
            print("Player is too close to the enriched spring, moving to a valid tile further away.")
            moveToAnotherValidTile(enriched)
        else
            print("Player is already on optimal position, skipping movement.")
        end

        print(string.format("Distance to enriched spring: %.2f tiles", distanceToSpring))

        print("Interacting with the enriched spring.")
        API.DoAction_NPC(0xc8, API.OFF_ACT_InteractNPC_route, { enriched.Id }, 50)

        UTILS.countTicks(3)

        while animCheck() do
            inventoryCheck()
            API.RandomSleep2(600, 200, 200)
        end
    elseif closestTile then
        print("Moving to closest valid tile near enriched spring.")
        moveToTile(closestTile)

        print(string.format("Distance to enriched spring: %.2f tiles", distanceToSpring))

        print("Interacting with the enriched spring.")
        API.DoAction_NPC(0xc8, API.OFF_ACT_InteractNPC_route, { enriched.Id }, 50)

        UTILS.countTicks(3)

        while animCheck() do
            inventoryCheck()
            API.RandomSleep2(600, 200, 200)
        end
    else
        print("Enriched Wisp is too far. Falling back to normal spring.")
    end
    return minDistanceToEnriched
end

local function harvestNormalSpring()
    local enriched, normal = getSprings()

    if normal then
        print("No Enriched Wisp found or it is too far. Interacting with Normal Spring.")
        API.DoAction_NPC(0xc8, API.OFF_ACT_InteractNPC_route, { normal.Id }, 50)

        while animCheck() do
            enriched, normal = getSprings()
            inventoryCheck()

            if enriched then
                print("Enriched Wisp found during harvesting. Switching to enriched wisp.")
                break
            end
            API.RandomSleep2(600, 200, 200)
        end
    end

    return enriched  -- Return the enriched spring if it was found during harvesting
end

-- Main loop
while API.Read_LoopyLoop() do
    local enriched, normal = getSprings()
    local minDistanceToEnriched

    if enriched then
        minDistanceToEnriched = interactWithEnrichedSpring(enriched)
    end

    -- If no enriched wisp is found or if it is too far, start harvesting the normal spring
    if not enriched or (enriched and (minDistanceToEnriched == nil or minDistanceToEnriched > 7)) then
        enriched = harvestNormalSpring()

        -- After switching to enriched spring, handle the enriched interaction
        if enriched then
            minDistanceToEnriched = interactWithEnrichedSpring(enriched)
        end
    end
end