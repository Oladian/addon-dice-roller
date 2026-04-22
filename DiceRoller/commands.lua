local DR = DiceRoller

local VALID_MODES = {
    normal    = true,
    norepeat  = true,
    smooth    = true,
    deck      = true,
    advantage = true,
}

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