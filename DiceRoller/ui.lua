local DR = DiceRoller

DR.UI = {}

local COLOR_GOLD        = { r = 0.79, g = 0.58, b = 0.18 }
local COLOR_GOLD_LIGHT  = { r = 0.94, g = 0.82, b = 0.37 }
local COLOR_BG_DARK     = { r = 0.10, g = 0.08, b = 0.05 }
local COLOR_BG_PANEL    = { r = 0.07, g = 0.05, b = 0.03 }
local COLOR_TEXT_MUTED  = { r = 0.48, g = 0.39, b = 0.21 }

local FRAME_WIDTH  = 300
local FRAME_HEIGHT = 480

local DICE_TYPES = { "D3", "D6", "D20", "D100" }

local MODES = { "normal", "norepeat", "smooth", "deck", "advantage" }

local MODES_BY_DIE = {
    D3   = { normal = true, smooth = true, advantage = true },
    D6   = { normal = true, norepeat = true, smooth = true, deck = true, advantage = true },
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

DiceRollerDB = DiceRollerDB or {}

local activeDie  = "D6"
local activeMode = "normal"
local history    = {}
local dots       = {}
local shapeLines = {}

local animState = {
    active = false,
    elapsed = 0,
    duration = 1.0,
    finalResult = nil,
    currentAngle = 0,
}

local function applyBackdrop(frame, bgColor, borderColor)
    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 12,
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

local function clearShapeLines()
    for _, line in ipairs(shapeLines) do
        line:Hide()
    end
end

local function drawLine(parent, x1, y1, x2, y2, thickness)
    local line = parent:CreateLine()
    line:SetColorTexture(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 1)
    line:SetThickness(thickness or 1.5)
    line:SetStartPoint("BOTTOMLEFT", parent, x1, y1)
    line:SetEndPoint("BOTTOMLEFT", parent, x2, y2)
    table.insert(shapeLines, line)
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
    local r = 36
    local points = drawPolygon(parent, cx, cy, r, 3, 1.8, 90 + angleOffset)
    drawLine(parent, cx, cy, points[1].x, points[1].y, 1.0)
    drawLine(parent, cx, cy, points[2].x, points[2].y, 1.0)
    drawLine(parent, cx, cy, points[3].x, points[3].y, 1.0)
end

local function buildD20Shape(parent, cx, cy, angleOffset)
    angleOffset = angleOffset or 0
    local r = 36
    local outer = drawPolygon(parent, cx, cy, r, 5, 1.8, 90 + angleOffset)
    local inner = drawPolygon(parent, cx, cy, r * 0.45, 5, 1.0, -90 + angleOffset)
    for i = 1, 5 do
        local j = ((i + 1) % 5) + 1
        drawLine(parent, outer[i].x, outer[i].y, inner[j].x, inner[j].y, 1.0)
    end
end

local function buildD100Shape(parent, cx, cy, angleOffset)
    angleOffset = angleOffset or 0
    drawPolygon(parent, cx, cy, 36, 12, 1.5, 90 + angleOffset)
    drawPolygon(parent, cx, cy, 20, 12, 1.0, 90 + angleOffset)
end

local function buildD6Shape(parent, cx, cy, angleOffset)
    angleOffset = angleOffset or 0
    drawPolygon(parent, cx, cy, 36, 4, 1.8, 45 + angleOffset)
end

local function showDieShape(dieType, resultLabel, angleOffset)
    angleOffset = angleOffset or 0
    clearShapeLines()

    local canvas = DR.UI.shapeCanvas
    canvas:Show()
    resultLabel:Show()

    local cx = canvas:GetWidth()  / 2
    local cy = canvas:GetHeight() / 2

    if dieType == "D3" then
        buildD3Shape(canvas, cx, cy, angleOffset)
    elseif dieType == "D6" then
        buildD6Shape(canvas, cx, cy, angleOffset)
    elseif dieType == "D20" then
        buildD20Shape(canvas, cx, cy, angleOffset)
    elseif dieType == "D100" then
        buildD100Shape(canvas, cx, cy, angleOffset)
    end
end

local function showD6Face(value)
    clearShapeLines()

    DR.UI.dieFace:Show()
    DR.UI.shapeCanvas:Hide()
    DR.UI.shapeResultLabel:Hide()
    for _, dot in ipairs(dots) do
        dot:Hide()
    end

    local layout  = DOT_LAYOUTS[value]
    local dotSize = 11
    local cell    = 22

    for _, pos in ipairs(layout) do
        local row, col = pos[1], pos[2]
        local idx      = (row - 1) * 3 + col
        local dot      = dots[idx]
        if dot then
            dot:ClearAllPoints()
            dot:SetPoint("TOPLEFT", DR.UI.dieFace, "TOPLEFT", (col - 1) * cell + 13, -((row - 1) * cell + 13))
            dot:SetSize(dotSize, dotSize)
            dot:Show()
        end
    end
end

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
        end
    end
    
    DR.UI.historyScrollChild:SetHeight(math.max(shown * 22, 110))
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
    activeDie              = dieType
    DiceRollerDB.activeDie = dieType

    for _, btn in ipairs(DR.UI.tabButtons) do
        if btn.dieType == dieType then
            btn:SetBackdropColor(COLOR_BG_DARK.r, COLOR_BG_DARK.g, COLOR_BG_DARK.b, 1)
            btn.label:SetTextColor(COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
        else
            btn:SetBackdropColor(COLOR_BG_PANEL.r, COLOR_BG_PANEL.g, COLOR_BG_PANEL.b, 1)
            btn.label:SetTextColor(COLOR_TEXT_MUTED.r, COLOR_TEXT_MUTED.g, COLOR_TEXT_MUTED.b)
        end
    end

    DR.UI.dieFace:Hide()
    showDieShape(dieType, DR.UI.shapeResultLabel, 0)
    DR.UI.shapeResultLabel:SetText("—")

    refreshModeDropdown()
    refreshHistory()
end

local function onRoll()
    local sides  = tonumber(activeDie:sub(2))
    local result = DR:Roll(sides)

    animState.active = true
    animState.elapsed = 0
    animState.finalResult = result
    animState.currentAngle = 0

    DR.UI.resultValue:SetText("—")
    DR.UI.resultMode:SetText(activeMode .. " mode")

    DR.UI.dieFace:Hide()
    showDieShape(activeDie, DR.UI.shapeResultLabel, 0)
    DR.UI.shapeResultLabel:SetText("—")
end

local function buildHistoryRows(container)
    local rows = {}
    for i = 1, 20 do
        local row = CreateFrame("Frame", nil, container)
        row:SetHeight(20)
        row:SetWidth(240)
        row:Hide()

        local whoLabel = row:CreateFontString(nil, "OVERLAY")
        whoLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "ITALIC")
        whoLabel:SetPoint("LEFT", row, "LEFT", 0, 0)

        local metaLabel = row:CreateFontString(nil, "OVERLAY")
        metaLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        metaLabel:SetTextColor(COLOR_TEXT_MUTED.r, COLOR_TEXT_MUTED.g, COLOR_TEXT_MUTED.b)
        metaLabel:SetPoint("CENTER", row, "CENTER", 0, 0)

        local valLabel = row:CreateFontString(nil, "OVERLAY")
        valLabel:SetFont("Fonts\\MORPHEUS.TTF", 14, "")
        valLabel:SetPoint("RIGHT", row, "RIGHT", 0, 0)

        row.whoLabel  = whoLabel
        row.metaLabel = metaLabel
        row.valLabel  = valLabel

        rows[i] = row
    end
    return rows
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
    applyBackdrop(frame, COLOR_BG_DARK, COLOR_GOLD)
    restorePosition(frame)
    frame:Hide()

    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetHeight(30)
    header:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, 0)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    applyBackdrop(header, COLOR_BG_PANEL, COLOR_GOLD)

    local title = header:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.TTF", 14, "")
    title:SetTextColor(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b)
    title:SetText("DICE ROLLER")
    title:SetPoint("CENTER", header, "CENTER", -8, 0)

    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    local tabRow = CreateFrame("Frame", nil, frame)
    tabRow:SetHeight(28)
    tabRow:SetPoint("TOPLEFT",  frame, "TOPLEFT",  6, -32)
    tabRow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -32)

    local tabWidth   = (FRAME_WIDTH - 12) / #DICE_TYPES
    local tabButtons = {}

    for i, dieType in ipairs(DICE_TYPES) do
        local btn = CreateFrame("Button", nil, tabRow, "BackdropTemplate")
        btn:SetSize(tabWidth - 2, 26)
        btn:SetPoint("LEFT", tabRow, "LEFT", (i - 1) * tabWidth, 0)
        btn.dieType = dieType
        applyBackdrop(btn, COLOR_BG_PANEL, COLOR_GOLD)

        local label = btn:CreateFontString(nil, "OVERLAY")
        label:SetFont("Fonts\\MORPHEUS.TTF", 13, "")
        label:SetPoint("CENTER", btn, "CENTER", 0, 0)
        label:SetText(dieType)
        btn.label = label

        btn:SetScript("OnClick", function() selectTab(dieType) end)
        tabButtons[i] = btn
    end

    local dieFaceTop = -68

    local dieFace = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    dieFace:SetSize(80, 80)
    dieFace:SetPoint("TOP", frame, "TOP", 0, dieFaceTop)
    applyBackdrop(dieFace, COLOR_BG_PANEL, COLOR_GOLD)

    dots = {}
    for i = 1, 9 do
        local dot = dieFace:CreateTexture(nil, "OVERLAY")
        dot:SetColorTexture(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 1)
        dot:SetSize(11, 11)
        dot:Hide()
        dots[i] = dot
    end

    local shapeCanvas = CreateFrame("Frame", nil, frame)
    shapeCanvas:SetSize(80, 80)
    shapeCanvas:SetPoint("TOP", frame, "TOP", 0, dieFaceTop)
    shapeCanvas:Hide()

    local shapeResultLabel = shapeCanvas:CreateFontString(nil, "OVERLAY")
    shapeResultLabel:SetFont("Fonts\\MORPHEUS.TTF", 22, "")
    shapeResultLabel:SetTextColor(COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
    shapeResultLabel:SetPoint("CENTER", shapeCanvas, "CENTER", 0, 0)
    shapeResultLabel:Hide()

    local resultArea = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    resultArea:SetHeight(78)
    resultArea:SetPoint("TOPLEFT",  frame, "TOPLEFT",  8, -158)
    resultArea:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -158)
    applyBackdrop(resultArea, COLOR_BG_PANEL, COLOR_GOLD)

    local resultLabel = resultArea:CreateFontString(nil, "OVERLAY")
    resultLabel:SetFont("Fonts\\MORPHEUS.TTF", 10, "")
    resultLabel:SetTextColor(COLOR_TEXT_MUTED.r, COLOR_TEXT_MUTED.g, COLOR_TEXT_MUTED.b)
    resultLabel:SetText("RESULT")
    resultLabel:SetPoint("TOP", resultArea, "TOP", 0, -6)

    local resultValue = resultArea:CreateFontString(nil, "OVERLAY")
    resultValue:SetFont("Fonts\\MORPHEUS.TTF", 40, "")
    resultValue:SetTextColor(COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
    resultValue:SetText("—")
    resultValue:SetPoint("CENTER", resultArea, "CENTER", 0, -4)

    local resultMode = resultArea:CreateFontString(nil, "OVERLAY")
    resultMode:SetFont("Fonts\\FRIZQT__.TTF", 11, "ITALIC")
    resultMode:SetTextColor(COLOR_TEXT_MUTED.r, COLOR_TEXT_MUTED.g, COLOR_TEXT_MUTED.b)
    resultMode:SetText("")
    resultMode:SetPoint("BOTTOM", resultArea, "BOTTOM", 0, 6)

    local modeRow = CreateFrame("Frame", nil, frame)
    modeRow:SetHeight(28)
    modeRow:SetPoint("TOPLEFT",  frame, "TOPLEFT",  8, -244)
    modeRow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -244)

    local modeLabel = modeRow:CreateFontString(nil, "OVERLAY")
    modeLabel:SetFont("Fonts\\MORPHEUS.TTF", 11, "")
    modeLabel:SetTextColor(COLOR_TEXT_MUTED.r, COLOR_TEXT_MUTED.g, COLOR_TEXT_MUTED.b)
    modeLabel:SetText("MODE")
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

    local rollBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    rollBtn:SetHeight(36)
    rollBtn:SetPoint("TOPLEFT",  frame, "TOPLEFT",  8, -280)
    rollBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -280)
    applyBackdrop(rollBtn, COLOR_BG_PANEL, COLOR_GOLD)

    local rollLabel = rollBtn:CreateFontString(nil, "OVERLAY")
    rollLabel:SetFont("Fonts\\MORPHEUS.TTF", 14, "")
    rollLabel:SetTextColor(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b)
    rollLabel:SetText("ROLL THE DICE")
    rollLabel:SetPoint("CENTER", rollBtn, "CENTER", 0, 0)

    rollBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.12, 0.06, 1)
    end)
    rollBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(COLOR_BG_PANEL.r, COLOR_BG_PANEL.g, COLOR_BG_PANEL.b, 1)
    end)
    rollBtn:SetScript("OnClick", onRoll)

    local historyHeader = frame:CreateFontString(nil, "OVERLAY")
    historyHeader:SetFont("Fonts\\MORPHEUS.TTF", 10, "")
    historyHeader:SetTextColor(COLOR_TEXT_MUTED.r, COLOR_TEXT_MUTED.g, COLOR_TEXT_MUTED.b)
    historyHeader:SetText("HISTORY")
    historyHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -326)

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetColorTexture(COLOR_TEXT_MUTED.r, COLOR_TEXT_MUTED.g, COLOR_TEXT_MUTED.b, 0.4)
    divider:SetPoint("TOPLEFT",  frame, "TOPLEFT",  8,  -338)
    divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -338)

    local historyScroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    historyScroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -344)
    historyScroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, 12)
    
    local historyScrollChild = CreateFrame("Frame", nil, historyScroll)
    historyScrollChild:SetSize(260, 110)
    historyScroll:SetScrollChild(historyScrollChild)

    DR.UI.frame               = frame
    DR.UI.tabButtons          = tabButtons
    DR.UI.dieFace             = dieFace
    DR.UI.shapeCanvas         = shapeCanvas
    DR.UI.shapeResultLabel    = shapeResultLabel
    DR.UI.resultValue         = resultValue
    DR.UI.resultMode          = resultMode
    DR.UI.modeDropdown        = modeDropdown
    DR.UI.historyScroll       = historyScroll
    DR.UI.historyScrollChild  = historyScrollChild
    DR.UI.historyRows         = buildHistoryRows(historyScrollChild)

    selectTab(DiceRollerDB.activeDie or "D6")
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
        GameTooltip:AddLine("Dice Roller", COLOR_GOLD_LIGHT.r, COLOR_GOLD_LIGHT.g, COLOR_GOLD_LIGHT.b)
        GameTooltip:AddLine("Click to toggle", 0.8, 0.8, 0.8)
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
    listener:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
        if prefix ~= "DiceRoller" then return end
        
        local playerFullName = UnitName("player") .. "-" .. GetRealmName()
        local senderShort = Ambiguate(sender, "short")
        local playerShort = Ambiguate(playerFullName, "short")
        
        if senderShort == playerShort then return end

        local msgType, dieType, modeName, rawValue = strsplit(":", message)
        local value = tonumber(rawValue)

        if msgType == "ROLL" and dieType and modeName and value then
            addHistoryEntry(senderShort, dieType, modeName, value, false)
            refreshHistory()
        end
    end)
end

local animFrame = CreateFrame("Frame")
animFrame:SetScript("OnUpdate", function(self, elapsed)
    if not animState.active then return end

    animState.elapsed = animState.elapsed + elapsed

    local progress = math.min(animState.elapsed / animState.duration, 1.0)
    local easeOut = 1 - math.pow(1 - progress, 3)

    local totalRotation = 720 + (math.random(0, 360))
    animState.currentAngle = easeOut * totalRotation

    showDieShape(activeDie, DR.UI.shapeResultLabel, animState.currentAngle)

    if progress >= 1.0 then
        if activeDie == "D6" then
            showD6Face(animState.finalResult)
        else
            DR.UI.shapeResultLabel:SetText(tostring(animState.finalResult))
        end
        DR.UI.resultValue:SetText(tostring(animState.finalResult))

        local playerName = UnitName("player")
        addHistoryEntry(playerName, activeDie, activeMode, animState.finalResult, true)
        refreshHistory()

        if IsInGroup() then
            local channel = IsInRaid() and "RAID" or "PARTY"
            local msg = table.concat({ "ROLL", activeDie, activeMode, tostring(animState.finalResult) }, ":")
            C_ChatInfo.SendAddonMessage("DiceRoller", msg, channel)
        end

        animState.active = false
    end
end)

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "DiceRoller" then return end

    DiceRollerDB = DiceRollerDB or {}

    if DiceRollerDB.mode then
        activeMode = DiceRollerDB.mode
        DR.mode    = DiceRollerDB.mode
    end

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