
# 🚓 Cops & Robbers FiveM - Friend Edition

## 🎮 Overview
A fast, fun, and feature-packed cops vs robbers game mode for FiveM, designed for you and your friends! Enjoy quick rounds, instant action, and friendly competition with easy commands and a modern UI.

---

## ✨ Features
- **Quick Game Start**: Play with just 2+ friends, no waiting!
- **Fast Rounds**: 5-minute games for rapid fun
- **Auto Team Balancing**: Teams switch and balance automatically
- **Instant Car Spawning**: Press `V` for a random car, or `/quickcar fast|cop`
- **Fun Taunts**: Press `Y` to send a taunt to everyone
- **Enhanced Arrests**: Press `E` for arrest with effects and animations
- **Chase Effects**: Screen shake and smoke during high-speed pursuits
- **Score HUD**: See your score live in the top-right
- **Quick Commands Panel**: Keybinds and commands in-game
- **Restart Voting**: `/restart` to vote for a new round
- **Unstuck Command**: Press `U` if you get stuck
- **Horn Spam**: Press `B` for a fun horn blast
- **Team Switch**: Press `T` or `/switchteam` to swap sides

---

## 🏁 Getting Started
1. **Add to server.cfg**: `ensure Cops_robbers-Fivem`
2. **Start your server**
3. **Join with friends** (minimum 2 players)
4. **Type `/quickstart` in chat** to begin!

---

## ⌨️ Keybinds & Commands
| Key/Command      | Action                       |
|------------------|-----------------------------|
| Y                | Send taunt message           |
| V                | Spawn quick vehicle          |
| E                | Arrest nearby player         |
| O                | Show current score           |
| B                | Horn spam (in vehicle)       |
| U                | Get unstuck                  |
| T                | Switch teams                 |
| /quickstart      | Start a quick game           |
| /quickcar fast   | Spawn a fast car             |
| /quickcar cop    | Spawn a police car           |
| /score           | Show your score              |
| /restart         | Vote to restart game         |
| /switchteam      | Change your team             |

---

## 🗺️ Game Modes
- **Classic**: Survive as robbers, arrest as cops
- **Bank Heist**: Rob banks, escape with the loot
- **VIP Escort**: Protect or eliminate the VIP
- **Territory Control**: Capture and hold zones
- **Survival**: Survive waves of increasing difficulty

Switch modes with `/quickstart [mode]` or press F11 in-game.

---

## 🏆 Scoring System
- **Arrests**: +10 points
- **Escapes**: +5 points
- **Money**: +1 point per $1000
- **Survival Bonus**: +1 point per minute

See your score live in the HUD or with `/score`.

---

## 🚗 Vehicles
- **Quick Spawn**: Press `V` or `/quickcar fast|cop|fun`
- **Modded Cars**: Spawned cars have upgrades for fun
- **Police Vehicles**: Special cars for cops
- **Fun Vehicles**: Monster trucks, bikes, and more

---

## � Arrest System
- **Press `E`** near a player to arrest
- **Fun animations and effects**
- **Short jail time** (30 seconds)
- **Easy escape for friends**

---

## 💬 Taunt System
- **Press `Y`** to send a random taunt
- **Taunts appear for all players**
- **Fun animations included**

---

## 🚨 Chase Effects
- **Screen shake** at high speed
- **Smoke and sparks** for intense chases
- **Chase indicator** in HUD

---

## 🖥️ Friend HUD
- **Score display** (top-right)
- **Quick commands panel** (bottom-left)
- **Team display** (top-left)
- **Game timer** (center top)
- **Chase mode indicator**
- **Notifications** for events

---

## 🛠️ Configuration
- **config/friend_config.lua**: All friend mode settings
    - Min players, game time, spawn points, scoring, keybinds, vehicle mods
- **Easy to tweak** for your group’s preferences

---

## 📝 Example Workflow
1. **Join server with friends**
2. **Type `/quickstart classic`**
3. **Play a 5-minute round**
4. **Press `O` to check your score**
5. **Use `/restart` to vote for a new game**
6. **Switch teams with `/switchteam` or `T`**
7. **Spawn cars and taunt for fun!**

---

## 🎉 Tips for Maximum Fun
- Try all game modes for variety
- Use taunts and horn spam for laughs
- Switch teams often for balance
- Play short rounds for quick fun
- Use quick car spawn for instant action
- Vote to restart when ready for a rematch

---

## 🤝 Credits
- **Script by**: GitHub Copilot
- **Concept**: Cops & Robbers for friends
- **UI Design**: Modern, responsive HUD
- **Special Thanks**: All playtesters and contributors

---

## � File Structure
```
Cops_robbers-Fivem/
├── fxmanifest.lua
├── config/
│   └── friend_config.lua
├── client/
│   └── friend_features.lua
├── server/
│   └── friend_features.lua
├── html/
│   └── friend_hud.html
...other files...
```

---

## 🐛 Troubleshooting
- **Game won’t start?** Need at least 2 players
- **Stuck?** Press `U` to get unstuck
- **No cars?** Use `/quickcar fast` or `/quickcar cop`
- **Score not updating?** Press `O` or `/score`
- **Want a rematch?** Use `/restart` to vote

---

## 🏁 Ready to Play?
Just join with friends, type `/quickstart`, and have fun!

---

**Enjoy the ultimate Cops & Robbers experience for friends!** 🚓💨

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