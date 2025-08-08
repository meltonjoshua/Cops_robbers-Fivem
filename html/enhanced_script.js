// Enhanced UI JavaScript
let currentStats = {};
let currentHackData = {};
let hackingActive = false;

// Initialize enhanced UI
document.addEventListener('DOMContentLoaded', function() {
    initializeUI();
    setupEventListeners();
});

function initializeUI() {
    // Close buttons
    document.getElementById('close-stats').addEventListener('click', function() {
        hideStatsPanel();
    });
    
    // Setup hacking controls
    setupHackingControls();
}

function setupEventListeners() {
    // Listen for NUI messages
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        switch(data.type) {
            case 'updateStats':
                updateStatsDisplay(data.stats);
                break;
            case 'showSessionSummary':
                showSessionSummary(data.data);
                break;
            case 'startHacking':
                startHackingMinigame(data.pattern, data.difficulty);
                break;
            case 'setGameMode':
                updateGameModeDisplay(data.mode, data.data);
                break;
            case 'levelUp':
                showLevelUpNotification(data.oldLevel, data.newLevel);
                break;
            case 'achievementUnlocked':
                showAchievementNotification(data.achievement);
                break;
            case 'updateTeamCounts':
                updateTeamCounts(data.cops, data.robbers);
                break;
        }
    });
    
    // Keyboard shortcuts
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            hideAllPanels();
        }
        
        if (hackingActive) {
            handleHackingInput(event);
        }
    });
}

// Statistics Display Functions
function updateStatsDisplay(stats) {
    currentStats = stats;
    
    // Update level and XP
    document.getElementById('player-level').textContent = stats.level;
    document.getElementById('xp-text').textContent = `${stats.experience} / ${stats.nextLevelXP} XP`;
    document.getElementById('xp-progress').style.width = `${stats.xpProgress}%`;
    
    // Update general stats
    document.getElementById('total-games').textContent = stats.totalGames;
    document.getElementById('games-won').textContent = stats.gamesWon;
    document.getElementById('win-rate').textContent = `${stats.winRate}%`;
    document.getElementById('total-playtime').textContent = `${stats.totalPlayTime}h`;
    
    // Update combat stats
    document.getElementById('kill-count').textContent = stats.killCount;
    document.getElementById('death-count').textContent = stats.deathCount;
    document.getElementById('kdr').textContent = stats.kdr;
    document.getElementById('arrests-made').textContent = stats.arrestsMade;
    
    // Update criminal stats
    document.getElementById('money-stolen').textContent = `$${formatNumber(stats.moneyStolen)}`;
    document.getElementById('bank-robberies').textContent = stats.bankRobberies;
    document.getElementById('times-arrested').textContent = stats.timesArrested;
    document.getElementById('territories-captured').textContent = stats.territoriesCaptured;
    
    // Update special stats
    document.getElementById('vip-escorts').textContent = stats.vipEscorts;
    document.getElementById('best-survival').textContent = `${stats.bestSurvivalTime}m`;
    document.getElementById('achievements-unlocked').textContent = 
        stats.achievements.filter(a => a.unlocked).length;
    
    // Update quick stats
    document.getElementById('quick-level').textContent = stats.level;
    document.getElementById('quick-xp').textContent = stats.experience;
    
    // Update achievements
    updateAchievementsDisplay(stats.achievements);
}

function updateAchievementsDisplay(achievements) {
    const grid = document.getElementById('achievements-grid');
    grid.innerHTML = '';
    
    achievements.forEach(achievement => {
        const item = document.createElement('div');
        item.className = `achievement-item ${achievement.unlocked ? 'unlocked' : ''}`;
        
        item.innerHTML = `
            <div class="achievement-title">${achievement.name}</div>
            <div class="achievement-description">${achievement.description}</div>
            ${achievement.requirement ? 
                `<div class="achievement-progress">${getAchievementProgress(achievement)}</div>` : 
                ''
            }
            <div class="achievement-xp">+${achievement.xp} XP</div>
        `;
        
        grid.appendChild(item);
    });
}

function getAchievementProgress(achievement) {
    // This would need to be populated with actual progress data
    // For now, just show if unlocked or not
    return achievement.unlocked ? 'Completed!' : 'In Progress...';
}

function showSessionSummary(sessionData) {
    document.getElementById('session-time').textContent = `${sessionData.sessionTime}m`;
    document.getElementById('session-arrests').textContent = sessionData.arrests;
    document.getElementById('session-money').textContent = `$${formatNumber(sessionData.money)}`;
    document.getElementById('session-kills').textContent = sessionData.kills;
    
    document.getElementById('session-summary').classList.remove('hidden');
    
    // Auto-hide after 10 seconds
    setTimeout(() => {
        document.getElementById('session-summary').classList.add('hidden');
    }, 10000);
}

// Hacking Minigame Functions
function setupHackingControls() {
    const arrowButtons = document.querySelectorAll('.arrow-btn');
    
    arrowButtons.forEach(button => {
        button.addEventListener('click', function() {
            const direction = this.getAttribute('data-direction');
            inputHackingDirection(direction);
        });
    });
}

function startHackingMinigame(pattern, difficulty) {
    currentHackData = {
        pattern: pattern,
        difficulty: difficulty,
        input: [],
        currentIndex: 0
    };
    
    hackingActive = true;
    
    document.getElementById('hack-difficulty').textContent = difficulty;
    document.getElementById('hacking-container').classList.remove('hidden');
    
    displayHackingPattern(pattern);
    updateHackingProgress();
}

function displayHackingPattern(pattern) {
    const patternContainer = document.getElementById('pattern-sequence');
    patternContainer.innerHTML = '';
    
    pattern.forEach(direction => {
        const arrow = document.createElement('div');
        arrow.className = 'pattern-arrow';
        arrow.textContent = getDirectionSymbol(direction);
        patternContainer.appendChild(arrow);
    });
}

function inputHackingDirection(direction) {
    if (!hackingActive) return;
    
    const directionNumber = getDirectionNumber(direction);
    currentHackData.input.push(directionNumber);
    
    updateInputDisplay();
    updateHackingProgress();
    
    // Check if input is correct so far
    const isCorrect = currentHackData.input[currentHackData.currentIndex] === 
                     currentHackData.pattern[currentHackData.currentIndex];
    
    if (!isCorrect) {
        // Wrong input - fail the hack
        completeHacking(false);
        return;
    }
    
    currentHackData.currentIndex++;
    
    // Check if hack is complete
    if (currentHackData.currentIndex >= currentHackData.pattern.length) {
        completeHacking(true);
    }
}

function handleHackingInput(event) {
    if (!hackingActive) return;
    
    let direction = null;
    
    switch(event.key) {
        case 'ArrowUp':
            direction = 'up';
            break;
        case 'ArrowDown':
            direction = 'down';
            break;
        case 'ArrowLeft':
            direction = 'left';
            break;
        case 'ArrowRight':
            direction = 'right';
            break;
    }
    
    if (direction) {
        event.preventDefault();
        inputHackingDirection(direction);
    }
}

function updateInputDisplay() {
    const inputContainer = document.getElementById('input-sequence');
    inputContainer.innerHTML = '';
    
    currentHackData.input.forEach((direction, index) => {
        const arrow = document.createElement('div');
        const isCorrect = direction === currentHackData.pattern[index];
        
        arrow.className = `input-arrow ${isCorrect ? 'correct' : 'incorrect'}`;
        arrow.textContent = getDirectionSymbol(direction);
        inputContainer.appendChild(arrow);
    });
}

function updateHackingProgress() {
    const progress = (currentHackData.currentIndex / currentHackData.pattern.length) * 100;
    document.getElementById('hack-progress').style.width = `${progress}%`;
    document.getElementById('hack-progress-text').textContent = 
        `${currentHackData.currentIndex} / ${currentHackData.pattern.length}`;
}

function completeHacking(success) {
    hackingActive = false;
    document.getElementById('hacking-container').classList.add('hidden');
    
    // Send result back to game
    fetch(`https://${GetParentResourceName()}/hackingComplete`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            success: success
        })
    });
}

function getDirectionSymbol(direction) {
    const symbols = {
        1: '↑',  // up
        2: '↓',  // down
        3: '←',  // left
        4: '→'   // right
    };
    return symbols[direction] || '?';
}

function getDirectionNumber(direction) {
    const numbers = {
        'up': 1,
        'down': 2,
        'left': 3,
        'right': 4
    };
    return numbers[direction] || 0;
}

// Game Mode Display Functions
function updateGameModeDisplay(mode, modeData) {
    const modeNames = {
        'classic': 'Classic',
        'bank_heist': 'Bank Heist',
        'vip_escort': 'VIP Escort',
        'territory_control': 'Territory Control',
        'survival': 'Survival'
    };
    
    document.getElementById('current-mode').textContent = modeNames[mode] || mode;
    
    // Update mode-specific objective text
    let objective = 'Survive for 10 minutes';
    let progress = 0;
    
    switch(mode) {
        case 'bank_heist':
            if (modeData) {
                objective = `Steal $${formatNumber(modeData.requiredMoney)}`;
                progress = (modeData.totalMoney / modeData.requiredMoney) * 100;
            }
            break;
        case 'vip_escort':
            if (modeData) {
                objective = `Escort VIP to zone ${modeData.currentZone}`;
                progress = ((modeData.currentZone - 1) / modeData.escortZones.length) * 100;
            }
            break;
        case 'territory_control':
            if (modeData) {
                objective = 'Control majority of territories';
                const total = modeData.zones.length;
                const controlled = modeData.copZones + modeData.robberZones;
                progress = (controlled / total) * 100;
            }
            break;
        case 'survival':
            if (modeData) {
                objective = `Survive wave ${modeData.wave}`;
                progress = (modeData.wave / 20) * 100; // Assume 20 waves max
            }
            break;
    }
    
    document.getElementById('mode-objective').textContent = objective;
    document.getElementById('mode-progress').style.width = `${Math.min(progress, 100)}%`;
}

function updateTeamCounts(cops, robbers) {
    document.getElementById('cop-count').textContent = cops;
    document.getElementById('robber-count').textContent = robbers;
}

// Notification Functions
function showLevelUpNotification(oldLevel, newLevel) {
    const notification = document.getElementById('level-up-notification');
    document.getElementById('new-level-number').textContent = newLevel;
    document.getElementById('level-bonus-xp').textContent = newLevel * 10;
    
    notification.classList.remove('hidden');
    
    // Auto-hide after 4 seconds
    setTimeout(() => {
        notification.classList.add('hidden');
    }, 4000);
}

function showAchievementNotification(achievement) {
    const notification = document.getElementById('achievement-notification');
    document.getElementById('achievement-name').textContent = achievement.name;
    document.getElementById('achievement-desc').textContent = achievement.description;
    document.getElementById('achievement-xp').textContent = achievement.xp;
    
    notification.classList.remove('hidden');
    
    // Auto-hide after 5 seconds
    setTimeout(() => {
        notification.classList.add('hidden');
    }, 5000);
}

// Utility Functions
function showStatsPanel() {
    document.getElementById('stats-container').classList.remove('hidden');
}

function hideStatsPanel() {
    document.getElementById('stats-container').classList.add('hidden');
}

function hideAllPanels() {
    document.getElementById('stats-container').classList.add('hidden');
    document.getElementById('hacking-container').classList.add('hidden');
    
    if (hackingActive) {
        completeHacking(false);
    }
}

function formatNumber(num) {
    if (num >= 1000000) {
        return (num / 1000000).toFixed(1) + 'M';
    } else if (num >= 1000) {
        return (num / 1000).toFixed(1) + 'K';
    }
    return num.toString();
}

// Export functions for external use
window.showStatsPanel = showStatsPanel;
window.hideStatsPanel = hideStatsPanel;
window.updateStatsDisplay = updateStatsDisplay;
