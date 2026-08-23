local DR = DiceRoller

DR.L = {}

local locale = GetLocale()

-- Default to English
local L = {
    -- UI
    TITLE = "DICE ROLLER",
    RESULT = "RESULT",
    MODE = "MODE",
    ROLL_BUTTON = "ROLL THE DICE",
    HISTORY = "HISTORY",
    HELP = "HELP",
    CLEAR_HISTORY = "Clear History",
    CLEAR_HISTORY_DESC = "Clears only your local roll history. Other players' history is not affected.",
    
    -- Tooltip
    TOOLTIP_TITLE = "Dice Roller",
    TOOLTIP_CLICK = "Click to toggle",
    TOOLTIP_HELP = "Right-click for help",

    -- Sound toggle
    SOUND_ON = "Sound: ON",
    SOUND_OFF = "Sound: OFF",
    SOUND_TOGGLE = "Click to toggle dice audio",

    -- Modifier
    MODIFIER = "MODIFIER",
    MODIFIER_TOOLTIP = "Left-click: ±1 | Shift-click: ±5",

    -- Roll profiles
    SAVE_PROFILE = "Save profile",
    SAVE_PROFILE_TOOLTIP = "Save current die, mode and modifier as a profile\nLeft-click: roll | Right-click: delete",
    PROFILE_PROMPT = "Profile name:",
    PROFILE_DELETE = 'Delete profile "%s"?',
    PROFILE_LIMIT = "Profile limit reached (5). Delete one first.",

    -- Custom dice
    CUSTOM_TAB = "D?",
    CUSTOM_LABEL = "SIDES",
    CUSTOM_CREATE = "CREATE",
    CUSTOM_SIDES_PROMPT = "Number of sides (2 - 1000):",
    CUSTOM_INVALID = "Enter a number between 2 and 1000.",

    -- Help Window
    HELP_TITLE = "Dice Roller - Help",
    HELP_FEATURES = "Features",
    HELP_USAGE = "Usage",
    HELP_MODES = "RNG Modes",
    HELP_PARTY = "Party Sync",
    
    HELP_FEATURES_TEXT = "• 7 Dice Types: D2, D3, D6, D8, D10, D20, D100 + custom dice\n• 5 RNG Modes: Normal, NoRepeat, Smooth, Deck, Advantage\n• Roll modifier (+/-)\n• Roll profiles\n• Animated rolls with smooth easing\n• Party/raid synchronization\n• Scrollable history (20 rolls)\n• Draggable minimap button",
    
    HELP_USAGE_TEXT = "• /diceroller - Toggle window\n• Click minimap button to open/close\n• Select dice type from tabs\n• Choose RNG mode from dropdown\n• Click 'ROLL THE DICE' to roll\n• Scroll history to see past rolls",
    
    HELP_MODES_TEXT = "|cffC79C2ENormal|r: Pure RNG, equal probability\n\n|cffC79C2ENoRepeat|r: Never repeats last roll\nExample: Rolled 4 → next can be 1,2,3,5,6\n\n|cffC79C2ESmooth|r: Rerolls after 3 low results (bottom 25%)\nExample D20: Roll 3,2,4 → next guaranteed 6-20\n\n|cffC79C2EDeck|r: Shuffled deck, draws without replacement\nExample: Deck [4,1,6,2,5,3] → draws in order, reshuffles when empty\n\n|cffC79C2EAdvantage|r: Rolls twice, takes higher (D&D inspired)\nExample: Roll 8 & 15 → result 15",
    
    HELP_PARTY_TEXT = "• Rolls auto-share with party/raid\n• Your rolls appear in gold\n• Other players' rolls in gray\n• History filtered by dice type",
    
    -- Mode names
    MODE_NORMAL = "normal",
    MODE_NOREPEAT = "norepeat",
    MODE_SMOOTH = "smooth",
    MODE_DECK = "deck",
    MODE_ADVANTAGE = "advantage",
}

-- Spanish localization
if locale == "esES" or locale == "esMX" then
    L.TITLE = "TIRADOR DE DADOS"
    L.RESULT = "RESULTADO"
    L.MODE = "MODO"
    L.ROLL_BUTTON = "TIRAR EL DADO"
    L.HISTORY = "HISTORIAL"
    L.HELP = "AYUDA"
    L.CLEAR_HISTORY = "Borrar Historial"
    L.CLEAR_HISTORY_DESC = "Borra solo tu historial local de tiradas. No afecta al historial de otros jugadores."
    
    L.TOOLTIP_TITLE = "Tirador de Dados"
    L.TOOLTIP_CLICK = "Clic para abrir/cerrar"
    L.TOOLTIP_HELP = "Clic derecho para ayuda"

    L.SOUND_ON = "Sonido: ACTIVADO"
    L.SOUND_OFF = "Sonido: DESACTIVADO"
    L.SOUND_TOGGLE = "Clic para activar/desactivar el audio de los dados"

    L.MODIFIER = "MODIFICADOR"
    L.MODIFIER_TOOLTIP = "Clic: ±1 | Mayús+clic: ±5"

    L.SAVE_PROFILE = "Guardar perfil"
    L.SAVE_PROFILE_TOOLTIP = "Guarda el dado, modo y modificador actuales como perfil\nClic: tirar | Clic derecho: borrar"
    L.PROFILE_PROMPT = "Nombre del perfil:"
    L.PROFILE_DELETE = '¿Borrar el perfil "%s"?'
    L.PROFILE_LIMIT = "Límite de perfiles alcanzado (5). Borra uno primero."

    L.CUSTOM_TAB = "D?"
    L.CUSTOM_LABEL = "CARAS"
    L.CUSTOM_CREATE = "CREAR"
    L.CUSTOM_SIDES_PROMPT = "Número de caras (2 - 1000):"
    L.CUSTOM_INVALID = "Introduce un número entre 2 y 1000."
    
    L.HELP_TITLE = "Tirador de Dados - Ayuda"
    L.HELP_FEATURES = "Características"
    L.HELP_USAGE = "Uso"
    L.HELP_MODES = "Modos RNG"
    L.HELP_PARTY = "Sincronización"
    
    L.HELP_FEATURES_TEXT = "• 7 Tipos de Dados: D2, D3, D6, D8, D10, D20, D100 + dados personalizados\n• 5 Modos RNG: Normal, NoRepeat, Smooth, Deck, Advantage\n• Modificador de tirada (+/-)\n• Perfiles de tirada\n• Tiradas animadas con suavizado\n• Sincronización con grupo/raid\n• Historial desplazable (20 tiradas)\n• Botón de minimapa arrastrable"

    L.HELP_USAGE_TEXT = "• /diceroller - Abre/cierra ventana\n• Clic en botón del minimapa para abrir/cerrar\n• Selecciona tipo de dado desde pestañas\n• Elige modo RNG del menú desplegable\n• Clic en 'TIRAR EL DADO' para tirar\n• Desplázate por el historial para ver tiradas pasadas"
    
    L.HELP_MODES_TEXT = "|cffC79C2ENormal|r: RNG puro, probabilidad igual\n\n|cffC79C2ENoRepeat|r: Nunca repite la última tirada\nEjemplo: Sacaste 4 → siguiente puede ser 1,2,3,5,6\n\n|cffC79C2ESmooth|r: Retira tras 3 resultados bajos (25% inferior)\nEjemplo D20: Sacas 3,2,4 → siguiente garantizado 6-20\n\n|cffC79C2EDeck|r: Baraja mezclada, saca sin reemplazo\nEjemplo: Baraja [4,1,6,2,5,3] → saca en orden, baraja al vaciar\n\n|cffC79C2EAdvantage|r: Tira dos veces, toma el mayor (inspirado en D&D)\nEjemplo: Sacas 8 y 15 → resultado 15"
    
    L.HELP_PARTY_TEXT = "• Tiradas se comparten automáticamente con grupo/raid\n• Tus tiradas aparecen en dorado\n• Tiradas de otros jugadores en gris\n• Historial filtrado por tipo de dado"
end

DR.L = L
