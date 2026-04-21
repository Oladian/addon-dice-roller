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
    
    -- Tooltip
    TOOLTIP_TITLE = "Dice Roller",
    TOOLTIP_CLICK = "Click to toggle",
    TOOLTIP_HELP = "Right-click for help",
    
    -- Help Window
    HELP_TITLE = "Dice Roller - Help",
    HELP_FEATURES = "Features",
    HELP_USAGE = "Usage",
    HELP_MODES = "RNG Modes",
    HELP_PARTY = "Party Sync",
    
    HELP_FEATURES_TEXT = "• 4 Dice Types: D3, D6, D20, D100\n• 5 RNG Modes: Normal, NoRepeat, Smooth, Deck, Advantage\n• Animated rolls with smooth easing\n• Party/raid synchronization\n• Scrollable history (20 rolls)\n• Draggable minimap button",
    
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
    
    L.TOOLTIP_TITLE = "Tirador de Dados"
    L.TOOLTIP_CLICK = "Clic para abrir/cerrar"
    L.TOOLTIP_HELP = "Clic derecho para ayuda"
    
    L.HELP_TITLE = "Tirador de Dados - Ayuda"
    L.HELP_FEATURES = "Características"
    L.HELP_USAGE = "Uso"
    L.HELP_MODES = "Modos RNG"
    L.HELP_PARTY = "Sincronización"
    
    L.HELP_FEATURES_TEXT = "• 4 Tipos de Dados: D3, D6, D20, D100\n• 5 Modos RNG: Normal, NoRepeat, Smooth, Deck, Advantage\n• Tiradas animadas con suavizado\n• Sincronización con grupo/raid\n• Historial desplazable (20 tiradas)\n• Botón de minimapa arrastrable"
    
    L.HELP_USAGE_TEXT = "• /diceroller - Abre/cierra ventana\n• Clic en botón del minimapa para abrir/cerrar\n• Selecciona tipo de dado desde pestañas\n• Elige modo RNG del menú desplegable\n• Clic en 'TIRAR EL DADO' para tirar\n• Desplázate por el historial para ver tiradas pasadas"
    
    L.HELP_MODES_TEXT = "|cffC79C2ENormal|r: RNG puro, probabilidad igual\n\n|cffC79C2ENoRepeat|r: Nunca repite la última tirada\nEjemplo: Sacaste 4 → siguiente puede ser 1,2,3,5,6\n\n|cffC79C2ESmooth|r: Retira tras 3 resultados bajos (25% inferior)\nEjemplo D20: Sacas 3,2,4 → siguiente garantizado 6-20\n\n|cffC79C2EDeck|r: Baraja mezclada, saca sin reemplazo\nEjemplo: Baraja [4,1,6,2,5,3] → saca en orden, baraja al vaciar\n\n|cffC79C2EAdvantage|r: Tira dos veces, toma el mayor (inspirado en D&D)\nEjemplo: Sacas 8 y 15 → resultado 15"
    
    L.HELP_PARTY_TEXT = "• Tiradas se comparten automáticamente con grupo/raid\n• Tus tiradas aparecen en dorado\n• Tiradas de otros jugadores en gris\n• Historial filtrado por tipo de dado"
end

DR.L = L
