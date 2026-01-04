let playerName = null;
let isMultiplayer = false;
let socket = io();
let gameCode = null;

window.opponentSnake = null;
window.isMultiplayer = false;
window.gameCode = gameCode;
window.socket = socket;

socket.on('game_created', (data) => {
    gameCode = data.code;
    window.gameCode = data.code;
    window.isMultiplayer = true;
    document.getElementById('gameCodeDisplay').textContent = gameCode;
    document.getElementById('multiplayerModal').style.display = 'flex';
    document.getElementById('waitingScreen').style.display = 'block';
});

socket.on('opponent_joined', (data) => {
    document.getElementById('waitingScreen').style.display = 'none';
    document.getElementById('gameStartScreen').style.display = 'block';
    document.getElementById('opponentInfo').textContent = data.opponentName + ' heeft gejoined!';
    
    setTimeout(() => {
        document.getElementById('multiplayerModal').style.display = 'none';
        startGame();
    }, 2000);
});

socket.on('game_joined', (data) => {
    gameCode = data.code;
    window.gameCode = data.code;
    window.isMultiplayer = true;
    showMessage('Gejoined met ' + data.opponent + '!', 'success');
    document.getElementById('gameModeModal').style.display = 'none';
    startGame();
});

socket.on('join_error', (data) => {
    showMessage(data.error, 'error');
});

function createGame(name) {
    socket.emit('create_game', {playerName: name});
}

function joinGame(name, code) {
    socket.emit('join_game', {playerName: name, code: code});
}

function showMessage(msg, type) {
    const messageDiv = document.createElement('div');
    messageDiv.className = `message-popup ${type}`;
    messageDiv.textContent = msg;
    document.body.appendChild(messageDiv);
    
    setTimeout(() => {
        messageDiv.remove();
    }, 3000);
}

function showGameModeSelection() {
    const modal = document.getElementById('gameModeModal');
    modal.style.display = 'flex';
}

function hideGameModeModal() {
    document.getElementById('gameModeModal').style.display = 'none';
}

function showNameInput(mode) {
    document.getElementById('modeSelection').style.display = 'none';
    document.getElementById('nameInput').style.display = 'block';
    document.getElementById('nameInput').dataset.mode = mode;
    
    if (mode === 'join') {
        document.getElementById('codeInputGroup').style.display = 'block';
    } else {
        document.getElementById('codeInputGroup').style.display = 'none';
    }
}

function handleModeSelection(mode) {
    if (mode === 'solo') {
        showNameInput('solo');
    } else if (mode === 'create') {
        showNameInput('create');
    } else if (mode === 'join') {
        showNameInput('join');
    }
}

function handleNameSubmit() {
    const name = document.getElementById('playerNameInput').value.trim();
    const mode = document.getElementById('nameInput').dataset.mode;
    
    if (!name) {
        showMessage('Naam is verplicht!', 'error');
        return;
    }
    
    playerName = name;
    
    if (mode === 'solo') {
        hideGameModeModal();
    } else if (mode === 'create') {
        window.isMultiplayer = true;
        createGame(name);
        hideGameModeModal();
    } else if (mode === 'join') {
        const code = document.getElementById('gameCodeInput').value.trim();
        if (!code) {
            showMessage('Game code is verplicht!', 'error');
            return;
        }
        window.isMultiplayer = true;
        joinGame(name, code);
    }
}

function backToModeSelection() {
    document.getElementById('nameInput').style.display = 'none';
    document.getElementById('modeSelection').style.display = 'block';
    document.getElementById('playerNameInput').value = '';
    document.getElementById('gameCodeInput').value = '';
}

window.addEventListener('load', () => {
    showGameModeSelection();
    
    document.getElementById('playerNameInput').addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            handleNameSubmit();
        }
    });
    
    document.getElementById('gameCodeInput').addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            handleNameSubmit();
        }
    });
});

socket.on('game_state', (data) => {
    if (data.snake) {
        window.opponentSnake = data.snake;
    }
});

async function saveGameData() {
    if (!playerName) return;
    
    const payload = {
        playerName: playerName,
        score: currentScore
    };
    
    const res = await fetch('/api/save-game', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    });
    
    const result = await res.json();
    console.log(result);
}

const originalStopGame = stopGame;
stopGame = function() {
    if (running) {
        if (!isMultiplayer) {
            saveGameData();
        }
    }
    originalStopGame();
};