local DR = DiceRoller
local L = DR.L

DR.UI = {}

local COLOR_GOLD        = { r = 0.79, g = 0.58, b = 0.18 }
local COLOR_GOLD_LIGHT  = { r = 0.94, g = 0.82, b = 0.37 }
local COLOR_BG_DARK     = { r = 0.10, g = 0.08, b = 0.05 }
local COLOR_BG_PANEL    = { r = 0.07, g = 0.05, b = 0.03 }
local COLOR_TEXT_MUTED  = { r = 0.48, g = 0.39, b = 0.21 }

local FRAME_WIDTH  = 360
local FRAME_HEIGHT = 620

local DICE_TYPES = { "D2", "D3", "D6", "D8", "D10", "D20", "D100" }

local MODES = { "normal", "norepeat", "smooth", "deck", "advantage" }

local MODES_BY_DIE = {
    D2   = { normal = true, smooth = true },
    D3   = { normal = true, smooth = true, advantage = true },
    D6   = { normal = true, norepeat = true, smooth = true, deck = true, advantage = true },
    D8   = { normal = true, norepeat = true, smooth = true, deck = true, advantage = true },
    D10  = { normal = true, norepeat = true, smooth = true, deck = true, advantage = true },
    D20  = { normal = true, norepeat = true, smooth = true, deck = true, advantage = true },
    D100 = { normal = true, norepeat = true, smooth = true, advantage = true },
}

local DOT_LAYOUTS = {
    [1] = { { 2, 2 } },
    [2] = { { 1, 1 }, { 3, 3 } },
    [3] = { { 1, 1 }, { 2, 2 }, { 3, 3 } },
    [4] = { { 1, 1 }, { 1, 3 }, { 3, 1 }, { 3, 3 } },
    [5] = { { 1, 1 }, { 1, 3 }, { 2, 2 }, { 3, 1 }, { 3, 3 } },
    [6] = { { 1, 1 }, { 1, 3 }, { 2, 1 }, { 2, 3 }, { 3, 1 }, { 3, 3 } },
}

local MINIMAP_RADIUS      = 104
local MINIMAP_BUTTON_SIZE = 28

local SOUND_ROLL_START = { "840222", "840224", "840226", "840228", "840230", "840232" }
local SOUND_ROLL_END   = { "1668195", "1668196", "1668197", "1668198", "1668199", "1668200" }
local SOUND_CRIT       = "1489461"
local SOUND_FAIL       = "569773"

local COLOR_RESULT_CRIT = { r = 1.00, g = 0.84, b = 0.25 }
local COLOR_RESULT_FAIL = { r = 0.90, g = 0.25, b = 0.18 }

DiceRollerDB = DiceRollerDB or {}

local activeDie  = "D6"
local activeMode = "normal"
local activeModifier = 0
local history    = {}
local dots       = {}
local shapeLines = {}

local animState = {
    active = false,
    elapsed = 0,
    duration = 1.0,
    finalResult = nil,
    currentAngle = 0,
    totalRotation = 720,
}

local animFrame
local onAnimUpdate

local function applyBackdrop(frame, bgColor, borderColor, ornate)
    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = ornate and "Interface\\DialogFrame\\UI-DialogBox-Border"
                           or "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = ornate and 24 or 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, 1)
    frame:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, 1)
end

local function savePosition(frame)
    local point, _, relativePoint, x, y = frame:GetPoint()
    DiceRollerDB.position = { point = point, relativePoint = relativePoint, x = x, y = y }
end

local function restorePosition(frame)
    local pos = DiceRollerDB.position
    if pos then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

local shapeLineCount = 0

local function clearShapeLines()
    for i = 1, shapeLineCount do
        shapeLines[i]:Hide()
    end
    shapeLineCount = 0
end

local function drawLine(parent, x1, y1, x2, y2, thickness)
    local index = shapeLineCount + 1
    local line  = shapeLines[index]
    if not line then
        line = parent:CreateLine(nil, "OVERLAY")
        shapeLines[index] = line
    end
    shapeLineCount = index
    line:SetColorTexture(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 1)
    line:SetThickness(thickness or 1.5)
    line:SetStartPoint("BOTTOMLEFT", parent, x1, y1)
    line:SetEndPoint("BOTTOMLEFT", parent, x2, y2)
    line:Show()
    return line
end

local function drawPolygon(parent, cx, cy, radius, sides, thickness, angleOffset)
    angleOffset = angleOffset or 0
    local points = {}
    for i = 0, sides - 1 do
        local angle = math.rad(angleOffset + (360 / sides) * i)
        points[i + 1] = {
            x = cx + radius * math.cos(angle),
            y = cy + radius * math.sin(angle),
        }
    end
    for i = 1, sides do
        local next = (i % sides) + 1
        drawLine(parent, points[i].x, points[i].y, points[next].x, points[next].y, thickness)
    end
    return points
end

local function buildD3Shape(parent, cx, cy, angleOffset)
    angleOffset = angleOffset or 0
    local r = 44
    local points = drawPolygon(parent, cx, cy, r, 3, 1.8, 90 + angleOffset)
    drawLine(parent, cx, cy, points[1].x, points[1].y, 1.0)
    drawLine(parent, cx, cy, points[2].x, points[2].y, 1.0)
    drawLine(parent, cx, cy, points[3].x, points[3].y, 1.0)
end

local function buildD20Shape(parent, cx, cy, angleOffset)
    angleOffset = angleOffset or 0
    local r = 44
    local outer = drawPolygon(parent, cx, cy, r, 5, 1.8, 90 + angleOffset)
    local inner = drawPolygon(parent, cx, cy, r * 0.45, 5, 1.0, -90 + angleOffset)
    for i = 1, 5 do
        local j = ((i + 1) % 5) + 1
        drawLine(parent, outer[i].x, outer[i].y, inner[j].x, inner[j].y, 1.0)
    end
end

local function buildD100Shape(parent, cx, cy, angleOffset)
    angleOffset = angleOffset or 0
    drawPolygon(parent, cx, cy, 44, 12, 1.5, 90 + angleOffset)
    drawPolygon(parent, cx, cy, 24, 12, 1.0, 90 + angleOffset)
end

local function buildD6Shape(parent, cx, cy, angleOffset)
    angleOffset = angleOffset or 0
    drawPolygon(parent, cx, cy, 44, 4, 1.8, 45 + angleOffset)
end

local function buildD2Shape(parent, cx, cy, angleOffset)
    angleOffset = angleOffset or 0
    drawPolygon(parent, cx, cy, 44, 24, 1.8, angleOffset)
    drawPolygon(parent, cx, cy, 32, 24, 0.9, angleOffset)
end

local function buildD8Shape(parent, cx, cy, angleOffset)
    angleOffset = angleOffset or 0
    local points = drawPolygon(parent, cx, cy, 44, 4, 1.8, 90 + angleOffset)
    drawLine(parent, points[2].x, points[2].y, points[4].x, points[4].y, 0.9)
end

local function buildD10Shape(parent, cx, cy, angleOffset)
    angleOffset = angleOffset or 0
    local points = drawPolygon(parent, cx, cy, 44, 4, 1.8, 90 + angleOffset)
    drawLine(parent, points[2].x, points[2].y, points[4].x, points[4].y, 0.9)
    drawLine(parent, points[1].x, points[1].y, points[3].x, points[3].y, 0.9)
end

local function showDieShape(dieType, resultLabel, angleOffset)
    angleOffset = angleOffset or 0
    clearShapeLines()

    local canvas = DR.UI.shapeCanvas
    canvas:Show()
    resultLabel:Show()

    for _, dot in ipairs(dots) do
        dot:Hide()
    end

    local cx = canvas:GetWidth()  / 2
    local cy = canvas:GetHeight() / 2

    if dieType == "D2" then
        buildD2Shape(canvas, cx, cy, angleOffset)
    elseif dieType == "D3" then
        buildD3Shape(canvas, cx, cy, angleOffset)
    elseif dieType == "D6" then
        buildD6Shape(canvas, cx, cy, angleOffset)
    elseif dieType == "D8" then
        buildD8Shape(canvas, cx, cy, angleOffset)
    elseif dieType == "D10" then
        buildD10Shape(canvas, cx, cy, angleOffset)
    elseif dieType == "D20" then
        buildD20Shape(canvas, cx, cy, angleOffset)
    elseif dieType == "D100" then
        buildD100Shape(canvas, cx, cy, angleOffset)
    end
end

local function showD6Face(value, angleOffset)
    DR.UI.shapeResultLabel:Hide()

    local canvas = DR.UI.shapeCanvas
    clearShapeLines()

    local w  = canvas:GetWidth()
    local h  = canvas:GetHeight()
    local cx = w / 2
    local cy = h / 2

    buildD6Shape(canvas, cx, cy, angleOffset)

    for _, dot in ipairs(dots) do
        dot:Hide()
    end

    local theta = math.rad(angleOffset % 360)
    local cosT  = math.cos(theta)
    local sinT  = math.sin(theta)

    local layout    = DOT_LAYOUTS[value]
    local pipOffset = 19
    local dotSize   = 11

    for _, pos in ipairs(layout) do
        local row, col = pos[1], pos[2]
        local idx      = (row - 1) * 3 + col
        local dot      = dots[idx]
        if dot then
            local dx = (col - 2) * pipOffset
            local dy = (2 - row) * pipOffset

            local rx = cx + dx * cosT - dy * sinT
            local ry = cy + dx * sinT + dy * cosT

            dot:SetSize(dotSize, dotSize)
            dot:SetAlpha(1)
            dot:SetRotation(theta)
            dot:ClearAllPoints()
            dot:SetPoint("CENTER", canvas, "BOTTOMLEFT", rx, ry)
            dot:Show()
        end
    end
end

local function isSoundEnabled()
    return DiceRollerDB.soundEnabled ~= false
end

local function playSoundFile(path)
    if path and isSoundEnabled() then pcall(PlaySoundFile, path) end
end

local refreshProfiles

local function saveProfile(name)
    DiceRollerDB.profiles      = DiceRollerDB.profiles or {}
    local profiles             = DiceRollerDB.profiles
    table.insert(profiles, {
        name     = name,
        die      = activeDie,
        mode     = activeMode,
        modifier = activeModifier,
    })
    while #profiles > 5 do
        table.remove(profiles, 1)
    end
    if refreshProfiles then refreshProfiles() end
end

StaticPopupDialogs["DICEROLLER_DELETE_PROFILE"] = {
    text     = L.PROFILE_DELETE,
    button1  = YES,
    button2  = NO,
    OnAccept = function(self, data)
        table.remove(DiceRollerDB.profiles, data.index)
        if refreshProfiles then refreshProfiles() end
    end,
    whileDisplayed = true,
    hideOnEscape   = true,
}

local function addHistoryEntry(who, dieType, modeName, value, isMine)
    table.insert(history, 1, { who = who, die = dieType, mode = modeName, value = value, mine = isMine })
    if #history > 20 then table.remove(history) end
end

local function refreshHistory()
    local rows = DR.UI.historyRows
    for _, row in ipairs(rows) do
        row:Hide()
    end

    local shown = 0
    for _, entry in ipairs(history) do
        if entry.die == activeDie then
            shown = shown + 1
            if shown > 20 then break end

            local row = rows[shown]
            local container = DR.UI.historyScrollChild
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -(shown - 1) * 22)
            row:Show()

            if entry.mine then
                row.whoLabel:SetTextColor(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b)
                row.valLabel:SetTextColor(COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
            else
                row.whoLabel:SetTextColor(COLOR_TEXT_MUTED.r, COLOR_TEXT_MUTED.g, COLOR_TEXT_MUTED.b)
                row.valLabel:SetTextColor(COLOR_TEXT_MUTED.r, COLOR_TEXT_MUTED.g, COLOR_TEXT_MUTED.b)
            end

            row.whoLabel:SetText(entry.who)
            row.metaLabel:SetText(entry.mode)
            row.valLabel:SetText(tostring(entry.value))

            if shown % 2 == 0 then
                row.shade:Show()
            else
                row.shade:Hide()
            end
        end
    end
    
    DR.UI.historyScrollChild:SetHeight(math.max(shown * 22, 110))
end

local function clearHistory()
    history = {}
    refreshHistory()
end

local function refreshModeDropdown()
    local allowed = MODES_BY_DIE[activeDie]
    if not allowed[activeMode] then
        activeMode        = "normal"
        DR.mode           = "normal"
        DiceRollerDB.mode = "normal"
    end
    UIDropDownMenu_SetText(DR.UI.modeDropdown, activeMode)
end

local function selectTab(dieType)
    if dieType == activeDie then return end
    activeDie              = dieType
    DiceRollerDB.activeDie = dieType

    DR:ResetRNG()

    for _, btn in ipairs(DR.UI.tabButtons) do
        if btn.dieType == dieType then
            btn:SetBackdropColor(COLOR_BG_DARK.r, COLOR_BG_DARK.g, COLOR_BG_DARK.b, 1)
            btn.label:SetTextColor(COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
        else
            btn:SetBackdropColor(COLOR_BG_PANEL.r, COLOR_BG_PANEL.g, COLOR_BG_PANEL.b, 1)
            btn.label:SetTextColor(COLOR_TEXT_MUTED.r, COLOR_TEXT_MUTED.g, COLOR_TEXT_MUTED.b)
        end
    end

    showDieShape(dieType, DR.UI.shapeResultLabel, 0)
    DR.UI.shapeResultLabel:SetText("—")

    refreshModeDropdown()
    refreshHistory()
end

local function onRoll()
    local sides  = tonumber(activeDie:sub(2))
    local naturalRoll = DR:Roll(sides)
    local result = math.max(1, naturalRoll + activeModifier)

    animState.active = true
    animState.elapsed = 0
    animState.finalResult = result
    animState.naturalRoll = naturalRoll
    animState.currentAngle = 0
    animState.totalRotation = 720 + math.random(0, 360)
    animFrame:SetScript("OnUpdate", onAnimUpdate)

    playSoundFile(SOUND_ROLL_START[math.random(#SOUND_ROLL_START)])

    DR.UI.resultValue:SetText("—")
    DR.UI.resultValue:SetTextColor(COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
    local modTag = (activeModifier ~= 0) and string.format(" %+d", activeModifier) or ""
    DR.UI.resultMode:SetText(activeMode .. " mode" .. modTag)

    showDieShape(activeDie, DR.UI.shapeResultLabel, 0)
    for _, dot in ipairs(dots) do
        dot:Hide()
    end
    DR.UI.shapeResultLabel:Hide()
end

local function buildHistoryRows(container)
    local rows = {}
    for i = 1, 20 do
        local row = CreateFrame("Frame", nil, container)
        row:SetHeight(20)
        row:SetWidth(300)
        row:Hide()

        local shade = row:CreateTexture(nil, "BACKGROUND")
        shade:SetAllPoints()
        shade:SetColorTexture(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.06)
        shade:Hide()

        local whoLabel = row:CreateFontString(nil, "OVERLAY")
        whoLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)
        whoLabel:SetPoint("LEFT", row, "LEFT", 4, 0)

        local metaLabel = row:CreateFontString(nil, "OVERLAY")
        metaLabel:SetFont("Fonts\\FRIZQT__.TTF", 11)
        metaLabel:SetTextColor(COLOR_TEXT_MUTED.r, COLOR_TEXT_MUTED.g, COLOR_TEXT_MUTED.b)
        metaLabel:SetPoint("CENTER", row, "CENTER", 0, 0)

        local valLabel = row:CreateFontString(nil, "OVERLAY")
        valLabel:SetFont("Fonts\\MORPHEUS.TTF", 15)
        valLabel:SetPoint("RIGHT", row, "RIGHT", -6, 0)

        row.shade      = shade
        row.whoLabel   = whoLabel
        row.metaLabel  = metaLabel
        row.valLabel   = valLabel

        rows[i] = row
    end
    return rows
end

local function buildHelpFrame()
    local helpFrame = CreateFrame("Frame", "DiceRollerHelpFrame", UIParent, "BackdropTemplate")
    helpFrame:SetSize(500, 550)
    helpFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    helpFrame:SetFrameStrata("DIALOG")
    helpFrame:SetMovable(true)
    helpFrame:EnableMouse(true)
    helpFrame:RegisterForDrag("LeftButton")
    helpFrame:SetScript("OnDragStart", helpFrame.StartMoving)
    helpFrame:SetScript("OnDragStop", helpFrame.StopMovingOrSizing)
    applyBackdrop(helpFrame, COLOR_BG_DARK, COLOR_GOLD)
    helpFrame:Hide()
    
    local header = CreateFrame("Frame", nil, helpFrame, "BackdropTemplate")
    header:SetHeight(30)
    header:SetPoint("TOPLEFT", helpFrame, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", helpFrame, "TOPRIGHT", 0, 0)
    applyBackdrop(header, COLOR_BG_PANEL, COLOR_GOLD)
    
    local title = header:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.TTF", 14)
    title:SetTextColor(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b)
    title:SetText(L.HELP_TITLE)
    title:SetPoint("CENTER", header, "CENTER", -8, 0)
    
    local closeBtn = CreateFrame("Button", nil, helpFrame, "UIPanelCloseButton")
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", helpFrame, "TOPRIGHT", 0, 0)
    closeBtn:SetScript("OnClick", function() helpFrame:Hide() end)
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, helpFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", helpFrame, "TOPLEFT", 12, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", helpFrame, "BOTTOMRIGHT", -32, 12)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(450, 1000)
    scrollFrame:SetScrollChild(scrollChild)
    
    local yOffset = 0
    local function addSection(titleText, contentText)
        local sectionTitle = scrollChild:CreateFontString(nil, "OVERLAY")
        sectionTitle:SetFont("Fonts\\MORPHEUS.TTF", 13)
        sectionTitle:SetTextColor(COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
        sectionTitle:SetText(titleText)
        sectionTitle:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)
        sectionTitle:SetWidth(450)
        sectionTitle:SetJustifyH("LEFT")
        yOffset = yOffset - 20
        
        local content = scrollChild:CreateFontString(nil, "OVERLAY")
        content:SetFont("Fonts\\FRIZQT__.TTF", 11)
        content:SetTextColor(0.9, 0.9, 0.9)
        content:SetText(contentText)
        content:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)
        content:SetWidth(450)
        content:SetJustifyH("LEFT")
        content:SetSpacing(3)
        yOffset = yOffset - content:GetStringHeight() - 20
    end
    
    addSection(L.HELP_FEATURES, L.HELP_FEATURES_TEXT)
    addSection(L.HELP_USAGE, L.HELP_USAGE_TEXT)
    addSection(L.HELP_MODES, L.HELP_MODES_TEXT)
    addSection(L.HELP_PARTY, L.HELP_PARTY_TEXT)
    
    scrollChild:SetHeight(math.abs(yOffset))
    
    DR.UI.helpFrame = helpFrame
end

local function buildMainFrame()
    local frame = CreateFrame("Frame", "DiceRollerFrame", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        savePosition(self)
    end)
    applyBackdrop(frame, COLOR_BG_DARK, COLOR_GOLD, true)
    restorePosition(frame)
    frame:Hide()

    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetHeight(36)
    header:SetPoint("TOPLEFT",  frame, "TOPLEFT",  6, -6)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
    applyBackdrop(header, COLOR_BG_PANEL, COLOR_GOLD)

    local title = header:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.TTF", 17)
    title:SetTextColor(COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
    title:SetText(L.TITLE)
    title:SetPoint("CENTER", header, "CENTER", -8, 0)
    
    local helpBtn = CreateFrame("Button", nil, header)
    helpBtn:SetSize(20, 20)
    helpBtn:SetPoint("RIGHT", header, "RIGHT", -30, 0)    helpBtn:SetNormalTexture("Interface\\Common\\help-i")
    helpBtn:SetHighlightTexture("Interface\\Common\\help-i")
    helpBtn:SetScript("OnClick", function() DR.UI.helpFrame:Show() end)
    helpBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L.HELP, COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
        GameTooltip:Show()
    end)
    helpBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local soundBtn = CreateFrame("Button", nil, header)
    soundBtn:SetSize(22, 22)
    soundBtn:SetPoint("LEFT", header, "LEFT", 8, 0)

    local function updateSoundIcon()
        if isSoundEnabled() then
            soundBtn:SetNormalTexture("Interface\\Common\\VoiceChat-Speaker")
            soundBtn:SetHighlightTexture("Interface\\Common\\VoiceChat-Speaker")
        else
            soundBtn:SetNormalTexture("Interface\\Common\\VoiceChat-Muted")
            soundBtn:SetHighlightTexture("Interface\\Common\\VoiceChat-Muted")
        end
    end

    updateSoundIcon()

    soundBtn:SetScript("OnClick", function()
        DiceRollerDB.soundEnabled = not isSoundEnabled()
        updateSoundIcon()
    end)
    soundBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(isSoundEnabled() and L.SOUND_ON or L.SOUND_OFF,
            COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
        GameTooltip:AddLine(L.SOUND_TOGGLE, 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    soundBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeBtn:SetSize(26, 26)
    closeBtn:SetPoint("TOPRIGHT", header, "TOPRIGHT", 0, 0)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    local tabRow = CreateFrame("Frame", nil, frame)
    tabRow:SetHeight(30)
    tabRow:SetPoint("TOPLEFT",  frame, "TOPLEFT",  8, -50)
    tabRow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -50)

    local tabWidth   = (FRAME_WIDTH - 16) / #DICE_TYPES
    local tabButtons = {}

    for i, dieType in ipairs(DICE_TYPES) do
        local btn = CreateFrame("Button", nil, tabRow, "BackdropTemplate")
        btn:SetSize(tabWidth - 2, 28)
        btn:SetPoint("LEFT", tabRow, "LEFT", (i - 1) * tabWidth, 0)
        btn.dieType = dieType
        applyBackdrop(btn, COLOR_BG_PANEL, COLOR_GOLD)

        local label = btn:CreateFontString(nil, "OVERLAY")
        label:SetFont("Fonts\\MORPHEUS.TTF", 14)
        label:SetPoint("CENTER", btn, "CENTER", 0, 0)
        label:SetText(dieType)
        btn.label = label

        btn:SetScript("OnClick", function() selectTab(dieType) end)
        tabButtons[i] = btn
    end

    local dieFaceTop = -94

    local shapeCanvas = CreateFrame("Frame", nil, frame)
    shapeCanvas:SetSize(96, 96)
    shapeCanvas:SetPoint("TOP", frame, "TOP", 0, dieFaceTop)
    shapeCanvas:Show()

    dots = {}
    for i = 1, 9 do
        local dot = shapeCanvas:CreateTexture(nil, "OVERLAY")
        dot:SetColorTexture(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 1)
        dot:SetSize(11, 11)
        dot:Hide()
        dots[i] = dot
    end

    local shapeResultLabel = shapeCanvas:CreateFontString(nil, "OVERLAY")
    shapeResultLabel:SetFont("Fonts\\MORPHEUS.TTF", 26)
    shapeResultLabel:SetTextColor(COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
    shapeResultLabel:SetPoint("CENTER", shapeCanvas, "CENTER", 0, 0)
    shapeResultLabel:Hide()

    local fxGlow = frame:CreateTexture(nil, "OVERLAY")
    fxGlow:SetTexture("Interface\\Cooldown\\star4")
    fxGlow:SetBlendMode("ADD")
    fxGlow:SetSize(220, 220)
    fxGlow:SetPoint("TOP", frame, "TOP", 0, dieFaceTop - 48)
    fxGlow:SetAlpha(0)
    fxGlow:Hide()

    local glowAnim = fxGlow:CreateAnimationGroup()
    local glowFade = glowAnim:CreateAnimation("Alpha")
    glowFade:SetFromAlpha(0.9)
    glowFade:SetToAlpha(0)
    glowFade:SetDuration(1.0)
    glowFade:SetSmoothing("OUT")
    glowAnim:SetScript("OnFinished", function() fxGlow:Hide() end)

    local shakeAnim = frame:CreateAnimationGroup()
    for i = 0, 5 do
        local shake = shakeAnim:CreateAnimation("Translation")
        shake:SetOffset((i % 2 == 0) and -5 or 5, 0)
        shake:SetDuration(0.05)
        shake:SetStartDelay(i * 0.05)
        shake:SetSmoothing("NONE")
    end

    DR.UI.fxGlow    = fxGlow
    DR.UI.glowAnim  = glowAnim
    DR.UI.glowFade  = glowFade
    DR.UI.shakeAnim = shakeAnim

    local resultArea = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    resultArea:SetHeight(90)
    resultArea:SetPoint("TOPLEFT",  frame, "TOPLEFT",  10, -204)
    resultArea:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -204)
    applyBackdrop(resultArea, COLOR_BG_PANEL, COLOR_GOLD)

    local resultLabel = resultArea:CreateFontString(nil, "OVERLAY")
    resultLabel:SetFont("Fonts\\MORPHEUS.TTF", 11)
    resultLabel:SetTextColor(COLOR_TEXT_MUTED.r, COLOR_TEXT_MUTED.g, COLOR_TEXT_MUTED.b)
    resultLabel:SetText(L.RESULT)
    resultLabel:SetPoint("TOP", resultArea, "TOP", 0, -7)

    local resultValue = resultArea:CreateFontString(nil, "OVERLAY")
    resultValue:SetFont("Fonts\\MORPHEUS.TTF", 46)
    resultValue:SetTextColor(COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
    resultValue:SetText("—")
    resultValue:SetPoint("CENTER", resultArea, "CENTER", 0, -4)

    local resultMode = resultArea:CreateFontString(nil, "OVERLAY")
    resultMode:SetFont("Fonts\\FRIZQT__.TTF", 11)
    resultMode:SetTextColor(COLOR_TEXT_MUTED.r, COLOR_TEXT_MUTED.g, COLOR_TEXT_MUTED.b)
    resultMode:SetText("")
    resultMode:SetPoint("BOTTOM", resultArea, "BOTTOM", 0, 6)

    local modeRow = CreateFrame("Frame", nil, frame)
    modeRow:SetHeight(30)
    modeRow:SetPoint("TOPLEFT",  frame, "TOPLEFT",  10, -306)
    modeRow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -306)

    local modeLabel = modeRow:CreateFontString(nil, "OVERLAY")
    modeLabel:SetFont("Fonts\\MORPHEUS.TTF", 11)
    modeLabel:SetTextColor(COLOR_TEXT_MUTED.r, COLOR_TEXT_MUTED.g, COLOR_TEXT_MUTED.b)
    modeLabel:SetText(L.MODE)
    modeLabel:SetPoint("LEFT", modeRow, "LEFT", 4, 0)

    local modeDropdown = CreateFrame("Frame", "DiceRollerModeDropdown", modeRow, "UIDropDownMenuTemplate")
    modeDropdown:SetPoint("LEFT", modeLabel, "RIGHT", -16, 0)
    UIDropDownMenu_SetWidth(modeDropdown, 130)
    UIDropDownMenu_SetText(modeDropdown, activeMode)
    UIDropDownMenu_Initialize(modeDropdown, function(self, level)
        local allowed = MODES_BY_DIE[activeDie]
        for _, modeName in ipairs(MODES) do
            if allowed[modeName] then
                local info   = UIDropDownMenu_CreateInfo()
                info.text    = modeName
                info.checked = (modeName == activeMode)
                info.func    = function()
                    activeMode        = modeName
                    DR.mode           = modeName
                    DiceRollerDB.mode = modeName
                    UIDropDownMenu_SetText(modeDropdown, modeName)
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)

    local modRow = CreateFrame("Frame", nil, frame)
    modRow:SetHeight(28)
    modRow:SetPoint("TOPLEFT",  frame, "TOPLEFT",  10, -344)
    modRow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -344)

    local modLabel = modRow:CreateFontString(nil, "OVERLAY")
    modLabel:SetFont("Fonts\\MORPHEUS.TTF", 11)
    modLabel:SetTextColor(COLOR_TEXT_MUTED.r, COLOR_TEXT_MUTED.g, COLOR_TEXT_MUTED.b)
    modLabel:SetText(L.MODIFIER)
    modLabel:SetPoint("LEFT", modRow, "LEFT", 4, 0)

    local modValue = modRow:CreateFontString(nil, "OVERLAY")
    modValue:SetFont("Fonts\\MORPHEUS.TTF", 14)
    modValue:SetTextColor(COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
    modValue:SetWidth(50)
    modValue:SetJustifyH("CENTER")

    local function setModifier(value)
        activeModifier        = math.max(-999, math.min(999, value))
        DiceRollerDB.modifier = activeModifier
        if activeModifier > 0 then
            modValue:SetText(string.format("+%d", activeModifier))
        else
            modValue:SetText(tostring(activeModifier))
        end
    end

    setModifier(DiceRollerDB.modifier or 0)
    DR.UI.setModifier = setModifier

    local function makeModButton(text, relativeTo, point, relativePoint, offsetX)
        local btn = CreateFrame("Button", nil, modRow, "BackdropTemplate")
        btn:SetSize(26, 24)
        btn:SetPoint(point, relativeTo, relativePoint, offsetX, 0)
        applyBackdrop(btn, COLOR_BG_PANEL, COLOR_GOLD)

        local label = btn:CreateFontString(nil, "OVERLAY")
        label:SetFont("Fonts\\MORPHEUS.TTF", 15)
        label:SetTextColor(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b)
        label:SetText(text)
        label:SetPoint("CENTER", btn, "CENTER", 0, 0)

        local stepUp = text == "+"

        btn:SetScript("OnClick", function()
            local step = IsShiftKeyDown() and 5 or 1
            setModifier(activeModifier + (stepUp and step or -step))
        end)

        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.18, 0.14, 0.07, 1)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:AddLine(L.MODIFIER_TOOLTIP, 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(COLOR_BG_PANEL.r, COLOR_BG_PANEL.g, COLOR_BG_PANEL.b, 1)
            GameTooltip:Hide()
        end)

        return btn
    end

    local modMinus = makeModButton("-", modRow, "LEFT", "LEFT", 130)
    modValue:SetPoint("LEFT", modMinus, "RIGHT", 6, 0)
    makeModButton("+", modValue, "LEFT", "RIGHT", 6)

    local rollBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    rollBtn:SetHeight(42)
    rollBtn:SetPoint("TOPLEFT",  frame, "TOPLEFT",  10, -380)
    rollBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -380)
    applyBackdrop(rollBtn, COLOR_BG_PANEL, COLOR_GOLD)

    local rollLabel = rollBtn:CreateFontString(nil, "OVERLAY")
    rollLabel:SetFont("Fonts\\MORPHEUS.TTF", 16)
    rollLabel:SetTextColor(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b)
    rollLabel:SetText(L.ROLL_BUTTON)
    rollLabel:SetPoint("CENTER", rollBtn, "CENTER", 0, 0)

    rollBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.18, 0.14, 0.07, 1)
        rollLabel:SetTextColor(COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
    end)
    rollBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(COLOR_BG_PANEL.r, COLOR_BG_PANEL.g, COLOR_BG_PANEL.b, 1)
        rollLabel:SetTextColor(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b)
    end)
    rollBtn:SetScript("OnClick", onRoll)

    local profileButtons = {}

    refreshProfiles = function()
        local list = DiceRollerDB.profiles or {}
        for i, btn in ipairs(profileButtons) do
            local p = list[i]
            if p then
                btn.label:SetText(p.name)
                btn:Show()
            else
                btn:Hide()
            end
        end
    end

    local function applyProfile(p)
        selectTab(p.die)
        activeMode           = p.mode
        DR.mode              = p.mode
        DiceRollerDB.mode    = p.mode
        UIDropDownMenu_SetText(DR.UI.modeDropdown, p.mode)
        DR.UI.setModifier(p.modifier or 0)
        onRoll()
    end

    local saveProfileBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    saveProfileBtn:SetSize(30, 28)
    saveProfileBtn:SetPoint("TOPLEFT", rollBtn, "BOTTOMLEFT", 0, -8)
    applyBackdrop(saveProfileBtn, COLOR_BG_PANEL, COLOR_GOLD)

    local saveLabel = saveProfileBtn:CreateFontString(nil, "OVERLAY")
    saveLabel:SetFont("Fonts\\MORPHEUS.TTF", 14)
    saveLabel:SetTextColor(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b)
    saveLabel:SetText("+")
    saveLabel:SetPoint("CENTER", saveProfileBtn, "CENTER", 0, 0)

    local nameEntry = CreateFrame("Frame", "DiceRollerProfileNameEntry", frame, "BackdropTemplate")
    nameEntry:SetSize(280, 140)
    nameEntry:SetPoint("CENTER", frame, "CENTER", 0, 0)
    nameEntry:SetFrameLevel(frame:GetFrameLevel() + 10)
    nameEntry:EnableMouse(true)
    applyBackdrop(nameEntry, COLOR_BG_DARK, COLOR_GOLD, true)
    nameEntry:Hide()

    local namePrompt = nameEntry:CreateFontString(nil, "OVERLAY")
    namePrompt:SetFont("Fonts\\MORPHEUS.TTF", 13)
    namePrompt:SetTextColor(COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
    namePrompt:SetText(L.PROFILE_PROMPT)
    namePrompt:SetPoint("TOP", nameEntry, "TOP", 0, -18)

    local nameInput = CreateFrame("EditBox", nil, nameEntry, "InputBoxTemplate")
    nameInput:SetSize(200, 24)
    nameInput:SetPoint("CENTER", nameEntry, "CENTER", 0, 10)
    nameInput:SetAutoFocus(false)
    nameInput:SetMaxLetters(24)

    local function confirmName()
        local text = nameInput:GetText()
        if text and not text:match("^%s*$") then
            saveProfile(text)
        end
        nameInput:ClearFocus()
        nameEntry:Hide()
    end

    nameInput:SetScript("OnEnterPressed", confirmName)
    nameInput:SetScript("OnEscapePressed", function()
        nameInput:ClearFocus()
        nameEntry:Hide()
    end)

    local okBtn = CreateFrame("Button", nil, nameEntry, "BackdropTemplate")
    okBtn:SetSize(90, 26)
    okBtn:SetPoint("BOTTOMLEFT", nameEntry, "BOTTOMLEFT", 24, 16)
    applyBackdrop(okBtn, COLOR_BG_PANEL, COLOR_GOLD)
    local okLabel = okBtn:CreateFontString(nil, "OVERLAY")
    okLabel:SetFont("Fonts\\MORPHEUS.TTF", 12)
    okLabel:SetTextColor(COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
    okLabel:SetText(ACCEPT)
    okLabel:SetPoint("CENTER", okBtn, "CENTER", 0, 0)
    okBtn:SetScript("OnClick", confirmName)

    local cancelBtn = CreateFrame("Button", nil, nameEntry, "BackdropTemplate")
    cancelBtn:SetSize(90, 26)
    cancelBtn:SetPoint("BOTTOMRIGHT", nameEntry, "BOTTOMRIGHT", -24, 16)
    applyBackdrop(cancelBtn, COLOR_BG_PANEL, COLOR_GOLD)
    local cancelLabel = cancelBtn:CreateFontString(nil, "OVERLAY")
    cancelLabel:SetFont("Fonts\\MORPHEUS.TTF", 12)
    cancelLabel:SetTextColor(COLOR_TEXT_MUTED.r, COLOR_TEXT_MUTED.g, COLOR_TEXT_MUTED.b)
    cancelLabel:SetText(CANCEL)
    cancelLabel:SetPoint("CENTER", cancelBtn, "CENTER", 0, 0)
    cancelBtn:SetScript("OnClick", function()
        nameInput:ClearFocus()
        nameEntry:Hide()
    end)

    DR.UI.nameEntry = nameEntry
    DR.UI.nameInput = nameInput

    saveProfileBtn:SetScript("OnClick", function()
        if #(DiceRollerDB.profiles or {}) >= 5 then
            print("[DiceRoller] " .. L.PROFILE_LIMIT)
            return
        end
        nameInput:SetText("")
        nameEntry:Show()
        nameInput:SetFocus()
    end)
    saveProfileBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.18, 0.14, 0.07, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L.SAVE_PROFILE, COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
        GameTooltip:Show()
    end)
    saveProfileBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(COLOR_BG_PANEL.r, COLOR_BG_PANEL.g, COLOR_BG_PANEL.b, 1)
        GameTooltip:Hide()
    end)

    for i = 1, 5 do
        local btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
        btn:SetSize(58, 28)
        if i == 1 then
            btn:SetPoint("LEFT", saveProfileBtn, "RIGHT", 4, 0)
        else
            btn:SetPoint("LEFT", profileButtons[i - 1], "RIGHT", 4, 0)
        end
        applyBackdrop(btn, COLOR_BG_PANEL, COLOR_GOLD)
        btn:Hide()

        local label = btn:CreateFontString(nil, "OVERLAY")
        label:SetFont("Fonts\\FRIZQT__.TTF", 9)
        label:SetTextColor(COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
        label:SetPoint("CENTER", btn, "CENTER", 0, 0)
        label:SetWordWrap(false)
        label:SetJustifyH("CENTER")
        btn.label = label

        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        btn:SetScript("OnClick", function(self, mouseButton)
            local p = (DiceRollerDB.profiles or {})[i]
            if not p then return end
            if mouseButton == "RightButton" then
                StaticPopup_Show("DICEROLLER_DELETE_PROFILE", p.name, nil, { index = i })
            else
                applyProfile(p)
            end
        end)

        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.18, 0.14, 0.07, 1)
            local p = (DiceRollerDB.profiles or {})[i]
            if p then
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(p.name, COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
                GameTooltip:AddLine(string.format("%s · %s %+d", p.die, p.mode, p.modifier or 0), 0.8, 0.8, 0.8)
                GameTooltip:AddLine(L.SAVE_PROFILE_TOOLTIP, 0.6, 0.6, 0.6, true)
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(COLOR_BG_PANEL.r, COLOR_BG_PANEL.g, COLOR_BG_PANEL.b, 1)
            GameTooltip:Hide()
        end)

        profileButtons[i] = btn
    end

    local historyHeader = frame:CreateFontString(nil, "OVERLAY")
    historyHeader:SetFont("Fonts\\MORPHEUS.TTF", 11)
    historyHeader:SetTextColor(COLOR_TEXT_MUTED.r, COLOR_TEXT_MUTED.g, COLOR_TEXT_MUTED.b)
    historyHeader:SetText(L.HISTORY)
    historyHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -468)

    local clearHistoryBtn = CreateFrame("Button", nil, frame)
    clearHistoryBtn:SetSize(16, 16)
    clearHistoryBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -466)
    clearHistoryBtn:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    clearHistoryBtn:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    clearHistoryBtn:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
    clearHistoryBtn:SetScript("OnClick", clearHistory)
    clearHistoryBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(L.CLEAR_HISTORY, COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
        GameTooltip:AddLine(L.CLEAR_HISTORY_DESC, 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    clearHistoryBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetColorTexture(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.35)
    divider:SetPoint("TOPLEFT",  frame, "TOPLEFT",  10, -480)
    divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -480)

    local historyScroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    historyScroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -488)
    historyScroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 14)

    local historyScrollChild = CreateFrame("Frame", nil, historyScroll)
    historyScrollChild:SetSize(310, 110)
    historyScroll:SetScrollChild(historyScrollChild)

    DR.UI.frame               = frame
    DR.UI.tabButtons          = tabButtons
    DR.UI.dieFace             = nil
    DR.UI.shapeCanvas         = shapeCanvas
    DR.UI.shapeResultLabel    = shapeResultLabel
    DR.UI.resultValue         = resultValue
    DR.UI.resultMode          = resultMode
    DR.UI.modeDropdown        = modeDropdown
    DR.UI.historyScroll       = historyScroll
    DR.UI.historyScrollChild  = historyScrollChild
    DR.UI.historyRows         = buildHistoryRows(historyScrollChild)

    selectTab(DiceRollerDB.activeDie or "D6")
    refreshProfiles()
end

local function buildMinimapButton()
    local button = CreateFrame("Button", "DiceRollerMinimapButton", Minimap)
    button:SetSize(MINIMAP_BUTTON_SIZE, MINIMAP_BUTTON_SIZE)
    button:SetFrameStrata("MEDIUM")
    button:SetMovable(true)
    button:EnableMouse(true)
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("LeftButtonUp")

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Push")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20.5, 20.5)
    icon:SetPoint("CENTER", 3, -2)
    icon:SetTexture("Interface\\Icons\\inv_misc_dice_02")

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local angle = DiceRollerDB.minimapAngle or 225

    local function updatePosition()
        local x = math.cos(math.rad(angle)) * MINIMAP_RADIUS
        local y = math.sin(math.rad(angle)) * MINIMAP_RADIUS
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale  = UIParent:GetEffectiveScale()
            angle        = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
            DiceRollerDB.minimapAngle = angle
            updatePosition()
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    button:SetScript("OnClick", function()
        local frame = DR.UI.frame
        if frame:IsShown() then frame:Hide() else frame:Show() end
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(L.TOOLTIP_TITLE, COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
        GameTooltip:AddLine(L.TOOLTIP_CLICK, 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    updatePosition()
    DR.UI.minimapButton = button
end

local function registerAddonMessages()
    C_ChatInfo.RegisterAddonMessagePrefix("DiceRoller")

    local listener = CreateFrame("Frame")
    listener:RegisterEvent("CHAT_MSG_ADDON")

    local playerShort = Ambiguate(UnitName("player") .. "-" .. GetRealmName(), "short")

    listener:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
        if prefix ~= "DiceRoller" then return end

        local senderShort = Ambiguate(sender, "short")

        if senderShort == playerShort then return end

        local msgType, dieType, modeName, rawValue = strsplit(":", message)
        local value = tonumber(rawValue)

        if msgType == "ROLL" and dieType and modeName and value then
            addHistoryEntry(senderShort, dieType, modeName, value, false)
            refreshHistory()
        end
    end)
end

animFrame = CreateFrame("Frame")

onAnimUpdate = function(self, elapsed)
    if not animState.active then
        self:SetScript("OnUpdate", nil)
        return
    end

    animState.elapsed = animState.elapsed + elapsed

    local progress = math.min(animState.elapsed / animState.duration, 1.0)
    local easeOut = 1 - (1 - progress) ^ 3

    animState.currentAngle = easeOut * animState.totalRotation

    showDieShape(activeDie, DR.UI.shapeResultLabel, animState.currentAngle)

    if progress >= 1.0 then
        if activeDie == "D6" then
            showD6Face(animState.naturalRoll, animState.totalRotation % 360)
        else
            DR.UI.shapeResultLabel:SetText(tostring(animState.naturalRoll))
        end
        DR.UI.resultValue:SetText(tostring(animState.finalResult))

        playSoundFile(SOUND_ROLL_END[math.random(#SOUND_ROLL_END)])

        local sides   = tonumber(activeDie:sub(2))
        local hasCrit = sides > 3
        local isCrit  = hasCrit and animState.naturalRoll == sides
        local isFail  = hasCrit and animState.naturalRoll == 1

        if isCrit then
            DR.UI.resultValue:SetTextColor(COLOR_RESULT_CRIT.r, COLOR_RESULT_CRIT.g, COLOR_RESULT_CRIT.b)
            DR.UI.fxGlow:SetVertexColor(COLOR_RESULT_CRIT.r, COLOR_RESULT_CRIT.g, COLOR_RESULT_CRIT.b, 1)
            DR.UI.fxGlow:Show()
            DR.UI.glowFade:SetFromAlpha(0.9)
            DR.UI.shakeAnim:Stop()
            DR.UI.glowAnim:Stop()
            DR.UI.glowAnim:Play()
            DR.UI.shakeAnim:Play()
            playSoundFile(SOUND_CRIT)
        elseif isFail then
            DR.UI.resultValue:SetTextColor(COLOR_RESULT_FAIL.r, COLOR_RESULT_FAIL.g, COLOR_RESULT_FAIL.b)
            DR.UI.fxGlow:SetVertexColor(COLOR_RESULT_FAIL.r, COLOR_RESULT_FAIL.g, COLOR_RESULT_FAIL.b, 1)
            DR.UI.fxGlow:Show()
            DR.UI.glowFade:SetFromAlpha(0.4)
            DR.UI.glowAnim:Stop()
            DR.UI.glowAnim:Play()
            DR.UI.shakeAnim:Stop()
            DR.UI.shakeAnim:Play()
            playSoundFile(SOUND_FAIL)
        else
            DR.UI.resultValue:SetTextColor(COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
        end

        local playerName = UnitName("player")
        local histMode = activeMode
        if activeModifier ~= 0 then
            histMode = string.format("%s %+d", histMode, activeModifier)
        end
        addHistoryEntry(playerName, activeDie, histMode, animState.finalResult, true)
        refreshHistory()

        if IsInGroup() then
            local channel = IsInRaid() and "RAID" or "PARTY"
            local msg = table.concat({ "ROLL", activeDie, activeMode, tostring(animState.finalResult) }, ":")
            C_ChatInfo.SendAddonMessage("DiceRoller", msg, channel)
        end

        animState.active = false
        self:SetScript("OnUpdate", nil)
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "DiceRoller" then return end

    DiceRollerDB = DiceRollerDB or {}

    if DiceRollerDB.mode then
        activeMode = DiceRollerDB.mode
        DR.mode    = DiceRollerDB.mode
    end

    activeModifier = math.max(-999, math.min(999, DiceRollerDB.modifier or 0))

    DiceRollerDB.profiles = DiceRollerDB.profiles or {}

    buildHelpFrame()
    buildMainFrame()
    buildMinimapButton()
    registerAddonMessages()

    self:UnregisterEvent("ADDON_LOADED")
end)

SLASH_DICEROLLER1 = "/diceroller"
SlashCmdList["DICEROLLER"] = function()
    local frame = DR.UI.frame
    if frame:IsShown() then frame:Hide() else frame:Show() end
end