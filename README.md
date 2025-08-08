# Cops & Robbers FiveM Script - Enhanced Edition v2.0

## 🚓 Overview
A comprehensive cops and robbers game mode for FiveM featuring multiple game modes, progression system, environmental interactions, advanced arrest mechanics, **immersive audio system**, **realistic vehicle mechanics**, **dynamic map features**, and **spectator mode**.

## ✨ Key Features

### 🎮 Multiple Game Modes
- **Classic Mode**: Traditional 10-minute survival gameplay
- **Bank Heist**: Rob banks to collect target money and escape
- **VIP Escort**: Protect or eliminate a VIP during transport
- **Territory Control**: Capture and hold zones to win
- **Survival Mode**: Face waves of increasing difficulty

### 🎵 **NEW: Immersive Audio System**
- **Dynamic Music**: Chase intensity-based soundtrack
- **Police Radio Chatter**: Realistic radio communications
- **Positional Sound Effects**: 3D audio experience
- **Contextual Ambient Audio**: Different soundscapes per game mode
- **Volume Controls**: Separate sliders for music, effects, and radio

### 🚗 **NEW: Advanced Vehicle System**
- **Fuel Consumption**: Realistic fuel usage based on driving style
- **Damage Modeling**: Progressive vehicle damage affecting performance
- **Modification System**: Upgrade speed, handling, and armor
- **Gas Station Refueling**: Interactive fuel stations with costs
- **Distance Tracking**: Comprehensive driving statistics

### 🗺️ **NEW: Dynamic Map Features**
- **Police Roadblocks**: Spawnable roadblocks with AI officers
- **Weather System**: Dynamic weather affecting visibility and handling
- **Traffic Control**: Random accidents, construction, and parades
- **Event Zones**: Live protests and public events
- **Time Management**: Accelerated or fixed time controls

### 👁️ **NEW: Spectator Mode**
- **Multiple Camera Modes**: Free camera, player following, fixed viewpoints
- **Player Switching**: Navigate between active players with hotkeys
- **Interactive UI**: Comprehensive spectator interface
- **Auto-Entry**: Automatic spectator mode when eliminated

### 📊 Progression System
- **Player Levels**: Gain XP and level up (1-50)
- **Achievements**: 14+ unlockable achievements with rewards
- **Statistics Tracking**: Comprehensive stats for all activities
- **Session Summaries**: Post-game performance reviews

### 🔧 Advanced Mechanics
- **Enhanced Arrest System**: Resistance mechanics and minigames
- **Environmental Interactions**: Hackable terminals, breachable doors, lootable containers
- **Evidence Collection**: Advanced investigation mechanics
- **Team Arrest Bonuses**: Cooperative gameplay rewards

### 🎨 Rich User Interface
- **Character Selection**: Pre-game team and character choice
- **Statistics Dashboard**: Detailed performance metrics
- **Hacking Minigames**: Interactive terminal access
- **Achievement Notifications**: Real-time unlock alerts
- **Help System**: Comprehensive keybind guide

### ⌨️ Intuitive Controls
- **F5**: Toggle help menu
- **F6**: Toggle UI elements  
- **F7**: Start game
- **F8**: End game
- **F9**: Game information
- **F10**: Player statistics
- **F11**: Change game mode
- **E**: Interact/Arrest
- **Arrow Keys**: Hacking controls

## 🏗️ Installation

1. Download the script to your FiveM resources folder
2. Add `ensure Cops_robbers-Fivem` to your server.cfg
3. Restart your server
4. Press F7 when you have 4+ players to start!

## 📁 File Structure

```
Cops_robbers-Fivem/
├── fxmanifest.lua              # Resource manifest
├── config.lua                  # Game configuration
├── README.md                   # This file
├── client/                     # Client-side scripts
│   ├── main.lua               # Core client logic
│   ├── blips.lua              # Map blip system
│   ├── arrest.lua             # Basic arrest mechanics
│   ├── enhanced_arrest.lua    # Advanced arrest system
│   ├── character_selection.lua # Pre-game selection
│   ├── keybinds.lua           # Basic keybind system
│   ├── keybinds_enhanced.lua  # Enhanced controls
│   ├── game_modes.lua         # Multiple game modes
│   ├── statistics.lua         # Progression system
│   └── environment.lua        # Interactive objects
├── server/                     # Server-side scripts
│   ├── main.lua               # Core server logic
│   ├── game.lua               # Game event handling
│   └── version.lua            # Version checking
└── html/                       # User interface
    ├── ui.html                # Main UI
    ├── style.css              # Basic styles
    ├── script.js              # UI interactions
    ├── character_selection.*   # Selection interface
    ├── enhanced_ui.html       # Advanced UI components
    ├── enhanced_styles.css    # Advanced styling
    └── enhanced_script.js     # Enhanced interactions
```

## ⚙️ Configuration

### Game Settings (config.lua)
```lua
Config.GameDuration = 600000    -- 10 minutes
Config.MinPlayers = 4           -- Minimum players to start
Config.MaxPlayers = 32          -- Maximum players
Config.ArrestDistance = 3.0     -- Arrest range
Config.ArrestTime = 5000        -- Arrest duration
```

### Spawn Locations
- **Cop Spawns**: Police stations and secure areas
- **Robber Spawns**: Various civilian locations
- **Vehicle Spawns**: Team-appropriate vehicles

### Character Models
- **Police**: Various law enforcement models
- **Criminals**: Civilian character options
- **Customization**: Player preference system

## 🎯 Game Modes Explained

### Classic Mode
- Robbers survive for 10 minutes
- Cops arrest all robbers to win
- Traditional chase gameplay

### Bank Heist Mode
- Rob banks to collect target money
- Each bank has different values
- Escape with the money to win

### VIP Escort Mode
- One player becomes the VIP
- Cops must escort them safely
- Robbers try to eliminate the VIP

### Territory Control Mode
- Capture zones by standing in them
- Hold majority of territories to win
- Dynamic territory control mechanics

### Survival Mode
- Face waves of increasing difficulty
- Each wave brings more challenges
- Survive as long as possible

## 📈 Progression System

### Experience Points (XP)
- **Game Victory**: 100 XP
- **Participation**: 25 XP
- **Arrests**: 25 XP each
- **Money Stolen**: 1 XP per $1000
- **Survival Time**: 5 XP per minute

### Achievements
- **First Timer**: Play your first game (100 XP)
- **Arrest Master**: Make 50 arrests (500 XP)
- **Money Bags**: Steal $1,000,000 (1000 XP)
- **Legendary**: Reach level 25 (5000 XP)
- *...and many more!*

### Statistics Tracked
- Games played/won/lost
- Arrests made/received
- Money stolen
- Kill/death ratios
- Time survived
- Bank robberies
- Territories captured

## 🔧 Advanced Features

### Environmental Interactions
- **Hackable Terminals**: Access security systems
- **Breachable Doors**: Force entry to buildings
- **Security Cameras**: Surveillance system
- **Loot Containers**: Hidden money stashes

### Enhanced Arrest System
- **Resistance Mechanics**: Robbers can fight back
- **Evidence Collection**: Investigation gameplay
- **Team Arrests**: Bonus for cooperation
- **Handcuffing Sequences**: Realistic animations

### Interactive Hacking
- **Pattern Matching**: Follow arrow sequences
- **Difficulty Levels**: Increasing complexity
- **System Effects**: Disable cameras, open doors
- **Risk/Reward**: Alert cops on failure

## 🎮 Commands

### Chat Commands
- `/surrender` - Give up to nearby cops
- `/teamchat [message]` - Team communication
- `/gameinfo` - Show current status
- `/rules` - Display game rules
- `/reset_stats` - Reset statistics (admin)

### Key Bindings
All major functions accessible via F-keys for quick access during gameplay.

## 🔧 Customization

### Adding New Game Modes
1. Define mode in `client/game_modes.lua`
2. Add initialization function
3. Implement win conditions
4. Update UI elements

### Modifying Spawn Points
Edit the spawn arrays in `config.lua` with new coordinates:
```lua
Config.CopSpawns = {
    {x = 425.1, y = -979.5, z = 30.7, h = 90.0}
}
```

### Custom Achievements
Add new achievements to the achievements table in `client/statistics.lua`:
```lua
{id = "custom_achievement", name = "Custom", description = "Custom achievement", unlocked = false, xp = 100}
```

## 🐛 Troubleshooting

### Common Issues
1. **Game won't start**: Check minimum player count
2. **No blips showing**: Restart the resource
3. **UI not loading**: Check browser console
4. **Statistics not saving**: Verify KVP permissions

### Debug Mode
Enable debug mode in config.lua for additional logging:
```lua
Config.Debug = true
```

## 🤝 Contributing

Feel free to:
- Report bugs via issues
- Suggest new features
- Submit pull requests
- Share configuration improvements

## 📝 License

This script is open source and available for modification. Credit to original creators appreciated.

## 🎉 Credits

- **Created by**: GitHub Copilot AI Assistant
- **Game Mode Concept**: Classic cops and robbers
- **Enhanced Features**: Advanced gameplay mechanics
- **UI Design**: Modern, responsive interface

---

*Enjoy your enhanced cops and robbers experience! Press F5 in-game for help.*