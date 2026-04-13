local DR = DiceRoller

local VALID_MODES = {
    normal    = true,
    norepeat  = true,
    smooth    = true,
    deck      = true,
    advantage = true,
}

SLASH_DICEROLLER1 = "/roll20"
SLASH_DICEROLLER2 = "/midado"

SlashCmdList["DICEROLLER"] = function()
    local result = DR:Roll()
    local msg = "[DiceRoller] (" .. DR.mode .. ") " .. result

    print(msg)
    SendChatMessage(msg, "SAY")
end

SLASH_DICEMODE1 = "/dicemode"

SlashCmdList["DICEMODE"] = function(msg)
    local mode = msg:lower():match("^%s*(%S+)%s*$")

    if not mode then
        print("[DiceRoller] Current mode: " .. DR.mode)
        return
    end

    if not VALID_MODES[mode] then
        print("[DiceRoller] Unknown mode: " .. mode)
        print("[DiceRoller] Valid modes: normal, norepeat, smooth, deck, advantage")
        return
    end

    DR.mode = mode
    print("[DiceRoller] Mode set to: " .. mode)
end