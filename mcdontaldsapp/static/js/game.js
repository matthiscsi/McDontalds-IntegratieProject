// Constants from Python version
const GRADUATION = 40;
const PIXEL = 10;
const STEP = 2 * PIXEL;
const WD = PIXEL * GRADUATION;
const HT = PIXEL * GRADUATION;
const OB_SIZE = PIXEL * 1;
const SN_SIZE = PIXEL * 0.9;
const BG_COLOR = 'black';
const OB_COLOR = 'red';
const SN_COLOR = 'white';
const REFRESH_TIME = 100;

// Direction constants
const UP = 'Up';
const DOWN = 'Down';
const RIGHT = 'Right';
const LEFT = 'Left';
const DIRECTIONS = {
    [UP]: [0, -1],
    [DOWN]: [0, 1],
    [RIGHT]: [1, 0],
    [LEFT]: [-1, 0]
};
const AXES = {
    [UP]: 'Vertical',
    [DOWN]: 'Vertical',
    [RIGHT]: 'Horizontal',
    [LEFT]: 'Horizontal'
};

// Setup canvas
const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');
canvas.width = WD;
canvas.height = HT;

// Game state
let running = false;
let snake = null;
let obstacle = null;
let direction = RIGHT;
let gameLoop = null;
let currentScore = 0;
let highScore = 0;

// Shape classes
class Shape {
    constructor(x, y, kind) {
        this.x = x;
        this.y = y;
        this.kind = kind;
    }

    draw() {
        if (this.kind === 'snake') {
            ctx.fillStyle = SN_COLOR;
            ctx.strokeStyle = SN_COLOR;
            ctx.lineWidth = 2;
            ctx.fillRect(
                this.x - SN_SIZE,
                this.y - SN_SIZE,
                SN_SIZE * 2,
                SN_SIZE * 2
            );
            ctx.strokeRect(
                this.x - SN_SIZE,
                this.y - SN_SIZE,
                SN_SIZE * 2,
                SN_SIZE * 2
            );
        } else if (this.kind === 'obstacle') {
            ctx.fillStyle = OB_COLOR;
            ctx.strokeStyle = OB_COLOR;
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.arc(this.x, this.y, OB_SIZE, 0, Math.PI * 2);
            ctx.fill();
            ctx.stroke();
        }
    }

    modify(x, y) {
        this.x = x;
        this.y = y;
    }
}

class Obstacle extends Shape {
    constructor(snakeBlocks) {
        const p = Math.floor(GRADUATION / 2 - 1);
        let n, m, x, y;
        
        do {
            n = Math.floor(Math.random() * (p + 1));
            m = Math.floor(Math.random() * (p + 1));
            x = PIXEL * (2 * n + 1);
            y = PIXEL * (2 * m + 1);
        } while (snakeBlocks.some(block => block.x === x && block.y === y));
        
        super(x, y, 'obstacle');
    }
}

class Block extends Shape {
    constructor(x, y) {
        super(x, y, 'snake');
    }
}

class Snake {
    constructor() {
        const a = PIXEL + 2 * Math.floor(GRADUATION / 4) * PIXEL;
        this.blocks = [
            new Block(a, a),
            new Block(a, a + STEP)
        ];
    }

    move(path) {
        let a = (this.blocks[this.blocks.length - 1].x + STEP * path[0]) % WD;
        let b = (this.blocks[this.blocks.length - 1].y + STEP * path[1]) % HT;
        
        // Handle negative wrap-around
        if (a < 0) a += WD;
        if (b < 0) b += HT;

        // Check if we found food
        if (a === obstacle.x && b === obstacle.y) {
            incrementScore();
            this.blocks.push(new Block(a, b));
            obstacle = new Obstacle(this.blocks);
        }
        // Check if we hit ourselves
        else if (this.blocks.some(block => block.x === a && block.y === b)) {
            stopGame();
        }
        // Normal movement
        else {
            this.blocks[0].modify(a, b);
            this.blocks.push(this.blocks.shift());
        }
    }

    draw() {
        this.blocks.forEach(block => block.draw());
    }
}

// Score management
function incrementScore() {
    currentScore++;
    if (currentScore > highScore) {
        highScore = currentScore;
        document.getElementById('highScore').textContent = highScore;
    }
    document.getElementById('currentScore').textContent = currentScore;
}

function resetScore() {
    currentScore = 0;
    document.getElementById('currentScore').textContent = '0';
}

// Game functions
function startGame() {
    if (!running) {
        snake = new Snake();
        obstacle = new Obstacle(snake.blocks);
        direction = RIGHT;
        running = true;
        gameLoop = setInterval(gameStep, REFRESH_TIME);
    }
}

function stopGame() {
    if (running) {
        resetScore();
        clearInterval(gameLoop);
        running = false;
        snake = null;
        obstacle = null;
        draw();
    }
}

function gameStep() {
    if (running) {
        snake.move(DIRECTIONS[direction]);
        draw();
        
        if (window.isMultiplayer && window.gameCode) {
            window.socket.emit('game_update', {
                code: window.gameCode,
                snake: snake.blocks.map(b => ({x: b.x, y: b.y}))
            });
        }
    }
}

function draw() {
    ctx.fillStyle = BG_COLOR;
    ctx.fillRect(0, 0, WD, HT);

    if (obstacle) obstacle.draw();
    if (snake) snake.draw();
    
    // Teken opponent snake
    if (window.opponentSnake) {
        ctx.fillStyle = 'yellow';
        window.opponentSnake.forEach(block => {
            ctx.fillRect(block.x - SN_SIZE, block.y - SN_SIZE, SN_SIZE * 2, SN_SIZE * 2);
        });
    }
}

// Keyboard input
function handleKeyPress(e) {
    const key = e.key;
    const keyMap = {
        'ArrowUp': UP,
        'ArrowDown': DOWN,
        'ArrowLeft': LEFT,
        'ArrowRight': RIGHT
    };

    const newDirection = keyMap[key];
    
    if (running && newDirection && AXES[newDirection] !== AXES[direction]) {
        direction = newDirection;
    }
}

document.getElementById('startBtn').addEventListener('click', startGame);
document.getElementById('stopBtn').addEventListener('click', stopGame);
document.getElementById('quitBtn').addEventListener('click', () => {
    stopGame();
    window.location.href = '/';
});
document.addEventListener('keydown', handleKeyPress);

// Touch control handler
function handleTouchControl(dir) {
    if (!running) return;
    
    const directionMap = {
        'up': UP,
        'down': DOWN,
        'left': LEFT,
        'right': RIGHT
    };
    
    const newDirection = directionMap[dir];
    
    if (newDirection && AXES[newDirection] !== AXES[direction]) {
        direction = newDirection;
    }
}

document.getElementById('startBtn').addEventListener('click', startGame);
document.getElementById('stopBtn').addEventListener('click', stopGame);
document.getElementById('quitBtn').addEventListener('click', () => {
    stopGame();
    window.location.href = '/';
});
document.addEventListener('keydown', handleKeyPress);

document.querySelectorAll('.touch-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
        e.preventDefault();
        const dir = e.currentTarget.dataset.direction;
        handleTouchControl(dir);
    });
    btn.addEventListener('touchstart', (e) => {
        e.preventDefault();
        const dir = e.currentTarget.dataset.direction;
        handleTouchControl(dir);
    });
});

draw();