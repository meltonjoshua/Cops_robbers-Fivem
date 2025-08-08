Config = {}

-- Game Settings
Config.GameDuration = 600 -- 10 minutes in seconds
Config.MinPlayers = 4 -- Minimum players to start the game
Config.MaxRobbers = 8 -- Maximum number of robbers
Config.ArrestDistance = 3.0 -- Distance to arrest someone
Config.ArrestTime = 5000 -- Time to arrest in milliseconds
Config.CharacterSelectionTime = 30 -- Time for character selection in seconds

-- Spawn Locations
Config.CopSpawns = {
    {x = 425.1, y = -979.5, z = 30.7, heading = 90.0}, -- Mission Row PD
    {x = -1108.4, y = -845.3, z = 19.3, heading = 37.0}, -- Vespucci PD
    {x = 638.2, y = 1.2, z = 82.8, heading = 247.0}, -- Vinewood PD
}

Config.RobberSpawns = {
    {x = -1037.8, y = -2737.9, z = 20.2, heading = 330.0}, -- Airport area
    {x = 1729.2, y = 3307.5, z = 41.2, heading = 195.0}, -- Sandy Shores
    {x = -2072.4, y = -317.3, z = 13.3, heading = 260.0}, -- Del Perro
    {x = -618.9, y = -1638.1, z = 26.0, heading = 90.0}, -- South Los Santos
    {x = 1850.7, y = 2585.9, z = 45.7, heading = 270.0}, -- Prison area
}

-- Vehicles
Config.CopVehicles = {
    "police",
    "police2",
    "sheriff",
    "fbi"
}

Config.RobberVehicles = {
    "adder",
    "entityxf",
    "zentorno",
    "t20",
    "osiris"
}

-- Blip Settings
Config.BlipSettings = {
    cop = {
        sprite = 1,
        color = 3,
        scale = 0.8,
        name = "Police Officer"
    },
    robber = {
        sprite = 1,
        color = 1,
        scale = 0.8,
        name = "Robber"
    }
}

-- Notifications
Config.Messages = {
    gameStarted = "Cops and Robbers game has started! Robbers have 10 minutes to escape!",
    gameEnded = "Game Over!",
    copsWin = "Cops Win! All robbers have been arrested!",
    robbersWin = "Robbers Win! They escaped the police!",
    arrested = "You have been arrested!",
    arrestedSomeone = "You arrested a robber!",
    notEnoughPlayers = "Not enough players to start the game. Need at least " .. Config.MinPlayers .. " players.",
    alreadyInGame = "A game is already in progress!",
    joinedAsCop = "You joined as a Police Officer!",
    joinedAsRobber = "You joined as a Robber!",
    arrestInProgress = "Arresting...",
    escaped = "You managed to escape!",
    characterSelectionStarted = "Character selection has begun! Choose your character and team.",
    characterSelectionTimeUp = "Character selection time is up! Auto-assigning characters...",
    waitingForPlayers = "Waiting for other players to select their characters..."
}

-- Keybind Settings
Config.Keybinds = {
    startGame = "F7",
    endGame = "F8",
    gameInfo = "F9",
    toggleUI = "F6",
    help = "F5",
    arrest = "E",
    enterVehicle = "F"
}

-- Character Models
Config.CharacterModels = {
    cops = {
        {model = "s_m_y_cop_01", name = "Police Officer", description = "Standard patrol officer"},
        {model = "s_m_y_sheriff_01", name = "Sheriff Deputy", description = "County sheriff deputy"},
        {model = "s_m_m_security_01", name = "Security Guard", description = "Private security officer"},
        {model = "s_m_y_swat_01", name = "SWAT Officer", description = "Special weapons and tactics"},
        {model = "s_f_y_cop_01", name = "Female Officer", description = "Female police officer"},
        {model = "s_m_y_hwaycop_01", name = "Highway Patrol", description = "Highway patrol officer"}
    },
    robbers = {
        {model = "a_m_y_skater_01", name = "Street Kid", description = "Young street criminal"},
        {model = "a_m_y_genstreet_01", name = "Gang Member", description = "Generic street gang member"},
        {model = "a_m_m_business_01", name = "White Collar", description = "Corporate criminal"},
        {model = "a_m_y_hipster_01", name = "Hipster", description = "Modern urban criminal"},
        {model = "a_f_y_genhot_01", name = "Femme Fatale", description = "Dangerous female criminal"},
        {model = "a_m_y_mexthug_01", name = "Thug", description = "Experienced street criminal"},
        {model = "a_m_m_socenlat_01", name = "Cartel Member", description = "Organized crime member"},
        {model = "a_m_y_stbla_01", name = "Street Criminal", description = "Hardened street criminal"}
    }
}
