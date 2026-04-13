local DR = DiceRoller

local lastRoll  = nil
local lowStreak = 0
local deck      = {}

local function shuffleDeck(sides)
    deck = {}
    for i = 1, sides do
        table.insert(deck, i)
    end
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

function DR:Roll(sides)
    sides = sides or 20
    local mode = self.mode

    if mode == "normal" then
        return math.random(1, sides)

    elseif mode == "norepeat" then
        local result = math.random(1, sides - 1)
        if lastRoll ~= nil and result >= lastRoll then
            result = result + 1
        end
        lastRoll = result
        return result

    elseif mode == "smooth" then
        local threshold = math.floor(sides * 0.25)
        local result    = math.random(1, sides)

        if result <= threshold then
            lowStreak = lowStreak + 1
            if lowStreak >= 3 then
                result    = math.random(threshold + 1, sides)
                lowStreak = 0
            end
        else
            lowStreak = 0
        end

        return result

    elseif mode == "deck" then
        if #deck == 0 then
            shuffleDeck(sides)
        end
        return table.remove(deck)

    elseif mode == "advantage" then
        return math.max(math.random(1, sides), math.random(1, sides))
    end

    return math.random(1, sides)
end