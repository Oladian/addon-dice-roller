# DiceRoller

Dice rolling addon for World of Warcraft with multiple RNG modes, animations, and party sync.

[Español](#español) | [English](#english)

---

## English

### Features
- **4 Dice Types**: D3, D6, D20, D100
- **5 RNG Modes**: Normal, NoRepeat, Smooth, Deck, Advantage
- **Animated Rolls**: Smooth rotating dice with easing
- **Party Sync**: Share rolls with group/raid members
- **Scrollable History**: Up to 20 recent rolls
- **Minimap Button**: Draggable quick access

### Installation
1. Extract `DiceRoller` folder to `World of Warcraft\_retail_\Interface\AddOns\`
2. Type `/reload` in-game

### Usage
- `/diceroller` - Toggle window
- Click minimap button to open/close
- Select dice type, choose mode, click "ROLL THE DICE"

### RNG Modes

| Mode | Description | Example (D6) |
|------|-------------|--------------|
| **Normal** | Pure RNG, equal probability | All numbers 16.67% chance |
| **NoRepeat** | Never repeats last roll | Rolled 4 → next can be 1,2,3,5,6 |
| **Smooth** | Rerolls after 3 low results (bottom 25%) | D20: Roll 3,2,4 → next guaranteed 6-20 |
| **Deck** | Shuffled deck, draws without replacement | Deck [4,1,6,2,5,3] → draws in order, reshuffles when empty |
| **Advantage** | Rolls twice, takes higher (D&D inspired) | Roll 8 & 15 → result 15 (20 has ~9.75% chance) |

### Mode Availability

| Mode | D3 | D6 | D20 | D100 |
|------|----|----|-----|------|
| Normal | ✓ | ✓ | ✓ | ✓ |
| NoRepeat | ✗ | ✓ | ✓ | ✓ |
| Smooth | ✓ | ✓ | ✓ | ✓ |
| Deck | ✗ | ✓ | ✓ | ✗ |
| Advantage | ✓ | ✓ | ✓ | ✓ |

### Party Sync
- Rolls auto-share with party/raid
- Your rolls in gold, others in gray
- History filtered by dice type

---

## Español

### Características
- **4 Tipos de Dados**: D3, D6, D20, D100
- **5 Modos RNG**: Normal, NoRepeat, Smooth, Deck, Advantage
- **Tiradas Animadas**: Dados giratorios con suavizado
- **Sincronización**: Comparte tiradas con grupo/raid
- **Historial Desplazable**: Hasta 20 tiradas recientes
- **Botón Minimapa**: Acceso rápido arrastrable

### Instalación
1. Extrae la carpeta `DiceRoller` en `World of Warcraft\_retail_\Interface\AddOns\`
2. Escribe `/reload` en el juego

### Uso
- `/diceroller` - Abre/cierra ventana
- Clic en botón del minimapa para abrir/cerrar
- Selecciona dado, elige modo, clic en "ROLL THE DICE"

### Modos RNG

| Modo | Descripción | Ejemplo (D6) |
|------|-------------|--------------|
| **Normal** | RNG puro, probabilidad igual | Todos los números 16.67% |
| **NoRepeat** | Nunca repite la última tirada | Sacaste 4 → siguiente puede ser 1,2,3,5,6 |
| **Smooth** | Retira tras 3 resultados bajos (25% inferior) | D20: Sacas 3,2,4 → siguiente garantizado 6-20 |
| **Deck** | Baraja mezclada, saca sin reemplazo | Baraja [4,1,6,2,5,3] → saca en orden, baraja al vaciar |
| **Advantage** | Tira dos veces, toma el mayor (inspirado en D&D) | Sacas 8 y 15 → resultado 15 (20 tiene ~9.75% probabilidad) |

### Disponibilidad de Modos

| Modo | D3 | D6 | D20 | D100 |
|------|----|----|-----|------|
| Normal | ✓ | ✓ | ✓ | ✓ |
| NoRepeat | ✗ | ✓ | ✓ | ✓ |
| Smooth | ✓ | ✓ | ✓ | ✓ |
| Deck | ✗ | ✓ | ✓ | ✗ |
| Advantage | ✓ | ✓ | ✓ | ✓ |

### Sincronización
- Tiradas se comparten automáticamente con grupo/raid
- Tus tiradas en dorado, otras en gris
- Historial filtrado por tipo de dado

---

**Author:** Oladian | **Version:** 1.0 | **License:** MIT

[GitHub](https://github.com/Oladian/addon-dice-roller)
