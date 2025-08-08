let currentTeam = null;
let gameTimer = 0;
let timerInterval = null;

// DOM Elements
const gameUI = document.getElementById('gameUI');
const teamIndicator = document.getElementById('teamIndicator');
const teamText = document.getElementById('teamText');
const gameTimerElement = document.getElementById('gameTimer');
const objectiveText = document.getElementById('objectiveText');
const eAction = document.getElementById('eAction');
const playersOnline = document.getElementById('playersOnline');
const gameStatus = document.getElementById('gameStatus');
const notifications = document.getElementById('notifications');

// Utility Functions
function formatTime(seconds) {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
}

function updateTimerAppearance(timeLeft) {
    gameTimerElement.classList.remove('warning', 'danger');
    
    if (timeLeft <= 60) {
        gameTimerElement.classList.add('danger');
    } else if (timeLeft <= 180) {
        gameTimerElement.classList.add('warning');
    }
}

function showNotification(message, type = 'info', duration = 5000) {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    
    const text = document.createElement('div');
    text.className = 'notification-text';
    text.textContent = message;
    
    notification.appendChild(text);
    notifications.appendChild(notification);
    
    // Auto remove notification
    setTimeout(() => {
        if (notification.parentNode) {
            notification.style.animation = 'notificationSlide 0.3s ease-out reverse';
            setTimeout(() => {
                if (notification.parentNode) {
                    notifications.removeChild(notification);
                }
            }, 300);
        }
    }, duration);
}

function updateTeamDisplay(team) {
    currentTeam = team;
    teamIndicator.classList.remove('team-cop', 'team-robber');
    
    if (team === 'cop') {
        teamText.textContent = 'POLICE OFFICER';
        teamIndicator.classList.add('team-cop');
        objectiveText.textContent = 'Arrest all robbers before time runs out. Use your police equipment and teamwork to catch the criminals.';
        eAction.textContent = 'Arrest Robber';
    } else if (team === 'robber') {
        teamText.textContent = 'ROBBER';
        teamIndicator.classList.add('team-robber');
        objectiveText.textContent = 'Escape the police for 10 minutes. Use fast cars and avoid getting caught by the cops.';
        eAction.textContent = 'Escape/Hide';
    }
}

function updateGameTimer(timeLeft) {
    gameTimer = timeLeft;
    gameTimerElement.textContent = formatTime(timeLeft);
    updateTimerAppearance(timeLeft);
}

function startTimer() {
    if (timerInterval) {
        clearInterval(timerInterval);
    }
    
    timerInterval = setInterval(() => {
        if (gameTimer > 0) {
            gameTimer--;
            updateGameTimer(gameTimer);
        } else {
            clearInterval(timerInterval);
        }
    }, 1000);
}

function stopTimer() {
    if (timerInterval) {
        clearInterval(timerInterval);
        timerInterval = null;
    }
}

// NUI Message Handler
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.type) {
        case 'showUI':
            gameUI.classList.remove('hidden');
            updateTeamDisplay(data.team);
            updateGameTimer(data.timer);
            gameStatus.textContent = 'Active';
            startTimer();
            break;
            
        case 'hideUI':
            gameUI.classList.add('hidden');
            stopTimer();
            gameStatus.textContent = 'Ended';
            break;
            
        case 'updateTimer':
            updateGameTimer(data.timer);
            break;
            
        case 'updatePlayers':
            playersOnline.textContent = data.count;
            break;
            
        case 'showNotification':
            showNotification(data.message, data.notificationType, data.duration);
            break;
            
        case 'updateGameStatus':
            gameStatus.textContent = data.status;
            break;
            
        case 'arrestProgress':
            if (data.progress !== undefined) {
                // Show arrest progress (could be enhanced with a progress bar)
                const progressPercent = Math.floor(data.progress * 100);
                if (progressPercent < 100) {
                    showNotification(`Arresting... ${progressPercent}%`, 'warning', 1000);
                }
            }
            break;
            
        case 'showCharacterSelection':
            // Open character selection in iframe or new window
            openCharacterSelection(data.characters, data.availableTeams);
            break;
            
        case 'hideCharacterSelection':
            closeCharacterSelection();
            break;
    }
});

function openCharacterSelection(characters, availableTeams) {
    // Create iframe for character selection
    const iframe = document.createElement('iframe');
    iframe.src = 'character_selection.html';
    iframe.id = 'characterSelectionFrame';
    iframe.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 100vw;
        height: 100vh;
        border: none;
        z-index: 2000;
        background: transparent;
    `;
    
    document.body.appendChild(iframe);
    
    // Send data to iframe when loaded
    iframe.onload = function() {
        iframe.contentWindow.postMessage({
            type: 'showCharacterSelection',
            characters: characters,
            availableTeams: availableTeams
        }, '*');
    };
}

function closeCharacterSelection() {
    const iframe = document.getElementById('characterSelectionFrame');
    if (iframe) {
        iframe.remove();
    }
}

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    // Hide UI initially
    gameUI.classList.add('hidden');
    
    // Set initial values
    gameStatus.textContent = 'Waiting';
    playersOnline.textContent = '0';
    
    // Send ready signal to game
    fetch(`https://${GetParentResourceName()}/uiReady`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    }).catch(() => {
        // Ignore errors in development
    });
});

// Escape key handler
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        // Send close UI message to game
        fetch(`https://${GetParentResourceName()}/closeUI`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({})
        }).catch(() => {
            // Ignore errors
        });
    }
});

// Helper function for resource name (fallback for development)
function GetParentResourceName() {
    return window.location.hostname === 'localhost' ? 'cops_robbers' : GetParentResourceName();
}
