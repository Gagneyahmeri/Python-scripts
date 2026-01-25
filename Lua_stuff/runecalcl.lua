-- Define rune data with runes per kill for each rune type
local runeData = {
    Spirit = { runesPerKill = 25 },
    Bone = { runesPerKill = 12 },
    Flesh = { runesPerKill = 6 },
    Miasma = { runesPerKill = 3 }
}

-- Define the number of kills
local kills = 900

-- Define current amounts of runes
local currentRunes = {
    Spirit = 13946,  -- Current amount of Spirit runes
    Bone = 6278,    -- Current amount of Bone runes
    Flesh = 3063,   -- Current amount of Flesh runes
    Miasma = 450    -- Current amount of Miasma runes
}

-- Function to calculate total runes needed based on runes per kill and number of kills
local function calculateTotalRunes(runeType, runesPerKill, numberOfKills)
    local totalRunes = runesPerKill * numberOfKills
    print("Total " .. runeType .. " runes needed: " .. totalRunes)
    return totalRunes
end

-- Calculate total runes for each type based on kills
local totalSpiritRunes = calculateTotalRunes("Spirit", runeData.Spirit.runesPerKill, kills)
local totalBoneRunes = calculateTotalRunes("Bone", runeData.Bone.runesPerKill, kills)
local totalFleshRunes = calculateTotalRunes("Flesh", runeData.Flesh.runesPerKill, kills)
local totalMiasmaRunes = calculateTotalRunes("Miasma", runeData.Miasma.runesPerKill, kills)

print("------------------REQUIRED RUNES------------------")

-- Subtract current runes from the total runes needed
local requiredSpiritRunes = totalSpiritRunes - currentRunes.Spirit
local requiredBoneRunes = totalBoneRunes - currentRunes.Bone
local requiredFleshRunes = totalFleshRunes - currentRunes.Flesh
local requiredMiasmaRunes = totalMiasmaRunes - currentRunes.Miasma

-- Print the required runes for each type
print("Required Spirit runes: " .. requiredSpiritRunes)
print("Required Bone runes: " .. requiredBoneRunes)
print("Required Flesh runes: " .. requiredFleshRunes)
print("Required Miasma runes: " .. requiredMiasmaRunes)

-- Calculate and print the total runes needed for all types
local totalRunesNeeded = requiredSpiritRunes + requiredBoneRunes + requiredFleshRunes + requiredMiasmaRunes
print("Total runes needed for all types: " .. totalRunesNeeded)
