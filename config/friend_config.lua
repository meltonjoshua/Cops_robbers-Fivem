-- Friend Mode Configuration
Config.FriendMode = {
    -- Reduced requirements for friend groups
    enabled = true,
    minPlayers = 2,              -- Can start with just 2 friends
    maxPlayers = 8,              -- Good for small friend groups
    gameTime = 300,              -- 5 minutes instead of 10
    jailTime = 30,               -- 30 seconds jail time instead of longer
    
    -- Quick spawn locations (close to each other for fast action)
    quickSpawns = {
        cops = {
            {x = -1096.8, y = -806.45, z = 19.0, h = 37.5},  -- Mirror Park PD
            {x = 451.7, y = -1018.1, z = 28.5, h = 99.5},   -- Mission Row PD
            {x = -561.2, y = -131.9, z = 38.0, h = 207.5},  -- Rockford Hills PD
        },
        robbers = {
            {x = -1165.4, y = -1425.5, z = 4.9, h = 35.0},  -- Vespucci Beach
            {x = 129.6, y = -1305.7, z = 29.2, h = 301.5},  -- Strawberry
            {x = -1315.0, y = -834.3, z = 16.9, h = 140.0}, -- Del Perro
        }
    },
    
    -- Fun settings
    enableChaseEffects = true,
    enableTaunts = true,
    enableQuickCommands = true,
    autoBalance = true,
    enableHornSpam = true,
    
    -- Relaxed rules for friends
    arrestDistance = 4.0,        -- Slightly longer arrest distance
    arrestTime = 3,              -- 3 seconds to arrest
    allowTeamSwitch = true,      -- Let friends switch teams freely
    infiniteFuel = false,        -- Keep fuel system but make it forgiving
    reducedVehicleDamage = true, -- Cars break less easily
    quickVehicleSpawn = true,    -- Allow instant vehicle spawning
    
    -- Quick vehicle spawning
    quickSpawnCooldown = 30,     -- 30 seconds between spawns
    allowedVehicles = {
        fast = {'adder', 'zentorno', 'bullet', 'cheetah', 'entityxf', 'osiris', 'turismor'},
        police = {'police', 'police2', 'sheriff', 'fbi', 'policeb'},
        fun = {'monster', 'blazer', 'sanchez', 'bmx', 'faggio'}
    },
    
    -- Simplified gameplay
    noComplexMechanics = true,   -- Disable complex systems for casual play
    fastRespawn = true,          -- Quick respawn when arrested
    easyEscape = true,           -- Easier to break out of arrests
    
    -- Score system
    scoring = {
        arrestPoints = 10,
        escapePoints = 5,
        survivalBonus = 1,       -- Per minute survived
        moneyMultiplier = 0.001, -- $1000 = 1 point
    }
}

-- Fun messages for friends
Config.FunMessages = {
    arrests = {
        "%s just got owned by %s!",
        "%s couldn't handle the heat from %s!",
        "BUSTED! %s got caught by %s!",
        "%s brings the pain to %s!",
        "Justice served! %s arrested %s!",
        "%s got schooled by officer %s!",
        "Crime doesn't pay, %s! Thanks to %s!",
    },
    escapes = {
        "%s escaped like a ninja!",
        "Can't touch this! %s got away!",
        "%s is too fast for the fuzz!",
        "Freedom! %s breaks free!",
        "%s just went ghost mode!",
        "Catch me if you can! - %s",
        "%s left the cops in the dust!",
    },
    chases = {
        "High speed chase in progress!",
        "The heat is on! %s vs %s!",
        "Epic chase happening now!",
        "Someone's about to get served!",
        "Fast and Furious moment!",
        "Police pursuit activated!",
        "Things are getting spicy!",
    },
    gameStart = {
        "Game on! May the best team win!",
        "Let the chaos begin!",
        "Time to settle this like pros!",
        "Who's ready to rumble?",
        "Let's see what you've got!",
        "Game time! Show no mercy!",
        "Ready or not, here we go!",
    },
    gameEnd = {
        "GG everyone! That was epic!",
        "What a game! Well played all!",
        "That was intense! Good job!",
        "Rematch? That was awesome!",
        "Great game everyone!",
        "Skills were displayed today!",
        "Respect to all players! 🎮",
    }
}

-- Quick keybinds for friends
Config.FriendKeybinds = {
    taunt = 'Y',
    quickcar = 'V',
    arrest = 'E',
    score = 'O',
    hornspam = 'B',
    unstuck = 'U',
    teamswitch = 'T',
    restart_vote = 'R'
}

-- Vehicle modifications for spawned cars
Config.QuickCarMods = {
    engine = 3,        -- Max engine
    brakes = 2,        -- Good brakes
    transmission = 2,  -- Good transmission
    suspension = 3,    -- Max suspension
    turbo = true,      -- Always add turbo
    bulletproof = false -- Keep it fair
}

-- Jail locations for arrested players
Config.JailLocations = {
    {x = 1641.93, y = 2570.48, z = 45.56, name = "Bolingbroke Penitentiary"},
    {x = 425.1, y = -979.5, z = 30.7, name = "Mission Row PD"},
    {x = -1096.8, y = -806.45, z = 19.0, name = "Mirror Park PD"},
    {x = -561.2, y = -131.9, z = 38.0, name = "Rockford Hills PD"}
}

-- Chase intensity levels
Config.ChaseIntensity = {
    low = {
        speedThreshold = 60,     -- km/h
        effects = {'screen_shake_light'},
        music = 'chase_low'
    },
    medium = {
        speedThreshold = 100,    -- km/h
        effects = {'screen_shake_medium', 'tire_smoke'},
        music = 'chase_medium'
    },
    high = {
        speedThreshold = 140,    -- km/h
        effects = {'screen_shake_heavy', 'tire_smoke', 'sparks'},
        music = 'chase_high'
    }
}

-- Auto-balance settings
Config.AutoBalance = {
    enabled = true,
    balanceInterval = 60,       -- Check every 60 seconds
    maxTeamDifference = 1,      -- Teams can differ by max 1 player
    switchCooldown = 120,       -- 2 minutes before allowing switch again
}
