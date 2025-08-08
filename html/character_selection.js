let selectedTeam = null;
let selectedCharacter = null;
let availableCharacters = {};
let availableTeams = [];

// DOM Elements
const characterSelection = document.getElementById('characterSelection');
const teamButtons = document.querySelectorAll('.team-btn');
const characterGrid = document.getElementById('characterGrid');
const characterGridTitle = document.getElementById('characterGridTitle');
const selectedCharacterName = document.getElementById('selectedCharacterName');
const selectedTeamName = document.getElementById('selectedTeamName');
const confirmBtn = document.getElementById('confirmBtn');
const cancelBtn = document.getElementById('cancelBtn');

// Team selection handlers
teamButtons.forEach(btn => {
    btn.addEventListener('click', function() {
        const team = this.dataset.team;
        selectTeam(team);
    });
});

function selectTeam(team) {
    selectedTeam = team;
    selectedCharacter = null;
    
    // Update team button states
    teamButtons.forEach(btn => {
        btn.classList.remove('selected');
        if (btn.dataset.team === team) {
            btn.classList.add('selected');
        }
    });
    
    // Update display
    updateSelectedDisplay();
    loadCharactersForTeam(team);
    updateConfirmButton();
}

function loadCharactersForTeam(team) {
    characterGrid.innerHTML = '';
    
    if (team === 'random') {
        characterGridTitle.textContent = 'Random Team - Character will be assigned automatically';
        selectedCharacter = { name: 'Random Character', model: 'random' };
        updateSelectedDisplay();
        updateConfirmButton();
        return;
    }
    
    const characters = availableCharacters[team] || [];
    
    if (characters.length === 0) {
        characterGridTitle.textContent = 'No characters available for this team';
        return;
    }
    
    characterGridTitle.textContent = `Choose Your ${team === 'cop' ? 'Police' : 'Criminal'} Character`;
    
    characters.forEach(character => {
        const card = createCharacterCard(character);
        characterGrid.appendChild(card);
    });
}

function createCharacterCard(character) {
    const card = document.createElement('div');
    card.className = 'character-card';
    card.dataset.model = character.model;
    
    card.innerHTML = `
        <div class="character-name">${character.name}</div>
        <div class="character-description">${character.description}</div>
        <div class="character-model">${character.model}</div>
    `;
    
    card.addEventListener('click', function() {
        selectCharacter(character);
    });
    
    return card;
}

function selectCharacter(character) {
    selectedCharacter = character;
    
    // Update character card states
    document.querySelectorAll('.character-card').forEach(card => {
        card.classList.remove('selected');
        if (card.dataset.model === character.model) {
            card.classList.add('selected');
        }
    });
    
    // Send preview request to game
    fetch(`https://${GetParentResourceName()}/selectCharacter`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            character: character,
            team: selectedTeam
        })
    }).catch(() => {});
    
    updateSelectedDisplay();
    updateConfirmButton();
}

function updateSelectedDisplay() {
    selectedTeamName.textContent = selectedTeam ? 
        (selectedTeam === 'random' ? 'Random' : 
         selectedTeam === 'cop' ? 'Police' : 'Robber') : 'None selected';
    
    selectedCharacterName.textContent = selectedCharacter ? 
        selectedCharacter.name : 'None selected';
}

function updateConfirmButton() {
    const canConfirm = selectedTeam && selectedCharacter;
    confirmBtn.disabled = !canConfirm;
}

// Button handlers
confirmBtn.addEventListener('click', function() {
    if (selectedTeam && selectedCharacter) {
        fetch(`https://${GetParentResourceName()}/confirmSelection`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                character: selectedCharacter,
                team: selectedTeam
            })
        }).catch(() => {});
    }
});

cancelBtn.addEventListener('click', function() {
    fetch(`https://${GetParentResourceName()}/closeCharacterSelection`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    }).catch(() => {});
});

// Escape key handler
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        cancelBtn.click();
    }
});

// Message handler for character selection data
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.type === 'showCharacterSelection') {
        availableCharacters = data.characters;
        availableTeams = data.availableTeams;
        
        // Show/hide team buttons based on availability
        updateTeamAvailability();
        
        characterSelection.classList.remove('hidden');
        resetSelection();
    } else if (data.type === 'hideCharacterSelection') {
        characterSelection.classList.add('hidden');
        resetSelection();
    }
});

function updateTeamAvailability() {
    const copBtn = document.getElementById('copTeamBtn');
    const robberBtn = document.getElementById('robberTeamBtn');
    const randomBtn = document.getElementById('randomTeamBtn');
    
    // Enable/disable buttons based on available teams
    if (availableTeams.includes('cop')) {
        copBtn.style.opacity = '1';
        copBtn.style.pointerEvents = 'auto';
    } else {
        copBtn.style.opacity = '0.5';
        copBtn.style.pointerEvents = 'none';
    }
    
    if (availableTeams.includes('robber')) {
        robberBtn.style.opacity = '1';
        robberBtn.style.pointerEvents = 'auto';
    } else {
        robberBtn.style.opacity = '0.5';
        robberBtn.style.pointerEvents = 'none';
    }
    
    // Random is always available
    randomBtn.style.opacity = '1';
    randomBtn.style.pointerEvents = 'auto';
}

function resetSelection() {
    selectedTeam = null;
    selectedCharacter = null;
    
    // Reset UI state
    teamButtons.forEach(btn => btn.classList.remove('selected'));
    characterGrid.innerHTML = '';
    characterGridTitle.textContent = 'Select Team First';
    updateSelectedDisplay();
    updateConfirmButton();
}

// Helper function for resource name
function GetParentResourceName() {
    return window.location.hostname === 'localhost' ? 'cops_robbers' : GetParentResourceName();
}
