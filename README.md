# Cops & Robbers FiveM Script

A comprehensive cops and robbers game mode for FiveM featuring:
- 10-minute chase scenarios
- Advanced arrest system with progress bars
- Real-time blip system for tracking players
- Team-based gameplay with automatic balancing
- Custom UI with timer and objective display
- Spawn system with vehicles for both teams

## Features

### Core Gameplay
- **10-minute timer**: Robbers must survive for 10 minutes to win
- **Character Selection**: Players choose their character model and team preference before the game starts
- **Team balancing**: Smart assignment system that considers player preferences while maintaining balance
- **Win conditions**: Cops win by arresting all robbers, robbers win by surviving the timer
- **Vehicle spawning**: Each team gets appropriate vehicles (police cars vs supercars)

### Character Selection System
- **Pre-game selection**: 30-second character selection phase before each match
- **Team preferences**: Players can choose to be cops, robbers, or random assignment
- **Character models**: Multiple character options for each team with unique appearances
- **Smart balancing**: System respects preferences while maintaining team balance
- **Auto-assignment**: Players who don't select in time get randomly assigned

### Arrest System
- **Proximity-based arrests**: Cops must get within 3 meters of robbers
- **Progress bar**: 5-second arrest animation with visual feedback
- **Escape mechanics**: Robbers can break free if they move away during arrest
- **Prison system**: Arrested robbers are teleported to prison

### Blip System
- **Team visibility**: Players can see enemy team members on the map
- **Real-time updates**: Blips update every second with player positions
- **Color coding**: Blue blips for cops, red blips for robbers
- **Auto cleanup**: Blips are automatically removed when players disconnect

### User Interface
- **Modern design**: Sleek, cyberpunk-inspired UI
- **Team indicators**: Clear visual indication of player team
- **Timer display**: Countdown timer with color-coded warnings
- **Objective text**: Dynamic objectives based on team assignment
- **Control hints**: On-screen controls and key bindings

## Installation

1. Download or clone this repository
2. Place the `Cops_robbers-Fivem` folder in your FiveM server's `resources` directory
3. Add the following line to your `server.cfg`:
   ```
   start Cops_robbers-Fivem
   ```
4. Restart your server

## Usage

### Starting a Game
- **In-game command**: `/startcopsrobbers` or `/startcr`
- **Console command**: `startcr` (from server console)
- **Requirements**: Minimum 4 players to start a game

### Admin Commands
- `/endcr` - End the current game (admin only)
- `crgameinfo` - Display game information in console (admin/console only)

### Gameplay
1. Use `/startcopsrobbers` to begin a new game
2. **Character Selection Phase**: Players have 30 seconds to choose their character and team preference
3. **Team Assignment**: System assigns teams based on preferences while maintaining balance
4. Cops spawn at police stations with police vehicles and weapons
5. Robbers spawn at various locations with fast escape vehicles
6. Cops must arrest all robbers within 10 minutes
7. Robbers must survive and avoid arrest for 10 minutes

### Controls
- **During Character Selection**:
  - **Mouse** - Select character and team
  - **Enter** - Confirm selection
  - **Escape** - Cancel/Random assignment
- **During Gameplay**:
  - **E** - Arrest robber (when playing as cop and near a robber)
  - **F** - Enter/exit vehicle
  - **Standard GTA controls** for movement and driving

## Configuration

Edit `config.lua` to customize:

### Game Settings
```lua
Config.GameDuration = 600        -- Game length in seconds (10 minutes)
Config.MinPlayers = 4           -- Minimum players required
Config.MaxRobbers = 8           -- Maximum number of robbers
Config.ArrestDistance = 3.0     -- Distance required for arrest
Config.ArrestTime = 5000        -- Time to complete arrest (ms)
Config.CharacterSelectionTime = 30 -- Character selection time (seconds)
```

### Spawn Locations
- `Config.CopSpawns` - Police spawn points
- `Config.RobberSpawns` - Robber spawn points

### Vehicles
- `Config.CopVehicles` - Police vehicle models
- `Config.RobberVehicles` - Robber vehicle models

### Character Models
- `Config.CharacterModels.cops` - Available police character models
- `Config.CharacterModels.robbers` - Available criminal character models

### Blip Settings
- Colors, sprites, and scales for map blips

## File Structure

```
Cops_robbers-Fivem/
├── fxmanifest.lua          # Resource manifest
├── config.lua              # Configuration file
├── server/
│   ├── main.lua           # Core server logic
│   ├── game.lua           # Game event handlers
│   └── version.lua        # Version and debug system
├── client/
│   ├── main.lua           # Main client script
│   ├── blips.lua          # Blip system
│   ├── arrest.lua         # Arrest mechanics
│   └── character_selection.lua # Character selection system
├── html/
│   ├── ui.html            # Main game UI
│   ├── style.css          # Main UI styling
│   ├── script.js          # Main UI functionality
│   ├── character_selection.html # Character selection UI
│   ├── character_selection.css  # Character selection styling
│   └── character_selection.js   # Character selection functionality
├── install.sh             # Installation script
├── test.sh               # Testing script
└── README.md              # This file
```

## Dependencies

- FiveM server
- No additional dependencies required

## Compatibility

- Tested with FiveM artifacts 6683+
- Compatible with ESX, QBCore, and standalone servers
- Works with most other resources

## Troubleshooting

### Common Issues

1. **Game won't start**
   - Check minimum player requirement (default: 4 players)
   - Verify resource is started in server.cfg
   - Check server console for errors

2. **Blips not showing**
   - Ensure players are on different teams
   - Check if game is active
   - Verify no conflicting blip resources

3. **Arrest system not working**
   - Check distance between players (must be within 3 meters)
   - Ensure both players are in the game
   - Verify cop is targeting a robber

4. **UI not displaying**
   - Check browser console for JavaScript errors
   - Verify NUI is enabled on client
   - Restart resource if needed

### Performance Tips

- Adjust blip update frequency in `client/blips.lua` if needed
- Modify arrest distance for better performance on busy servers
- Consider reducing maximum player counts for lower-end servers

## Support

For issues, suggestions, or contributions:
1. Check the troubleshooting section above
2. Review server console logs for errors
3. Test with minimal other resources to isolate conflicts

## License

This script is open source and free to use. Feel free to modify and distribute as needed.

## Credits

Created with GitHub Copilot for FiveM server administrators and developers.