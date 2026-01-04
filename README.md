# McKiosk - McDontald's Kiosk System

[![Flask](https://img.shields.io/badge/Flask-2.3+-green.svg)](https://flask.palletsprojects.com/)
[![Python](https://img.shields.io/badge/Python-3.7+-blue.svg)](https://python.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-13+-blue.svg)](https://postgresql.org)
[![Redis](https://img.shields.io/badge/Redis-6.0+-red.svg)](https://redis.io)
[![WebSocket](https://img.shields.io/badge/WebSocket-Real--time-orange.svg)](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket)

> A comprehensive McDontald's kiosk simulator featuring interactive ordering, multiplayer gaming, and administrative management.

## Overview

McKiosk is a full-stack web application that recreates the McDontald's self-service kiosk experience. It combines a complete ordering system with real-time multiplayer gaming and administrative tools.

### Key Features

| Feature | Description |
|---------|-------------|
| **Ordering System** | Browse menu categories, add items to cart, and complete checkout |
| **Snake Game** | Single-player and multiplayer modes with global leaderboard |
| **Admin Panel** | Manage menu items, prices, stock status, and view orders |
| **Real-time Gaming** | WebSocket-powered multiplayer Snake with game codes |
| **Responsive Design** | Optimized for desktop, tablet, and mobile devices |

## Technology Stack

### Backend
- **Flask** - Python web framework
- **SQLAlchemy** - Database ORM
- **PostgreSQL** - Primary database for orders, menu items, and game scores
- **Redis** - Game session management and caching
- **Flask-SocketIO** - WebSocket support for real-time multiplayer

### Frontend
- **HTML5/CSS3** - Responsive design with McDontald's branding
- **JavaScript ES6+** - Modern JavaScript with async/await
- **WebSocket** - Real-time communication for multiplayer gaming
- **LocalStorage** - Client-side cart persistence

### Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Flask App     │    │   Databases     │
│   (Browser)     │◄──►│   (Python)      │◄──►│   PostgreSQL    │
│                 │    │                 │    │   Redis         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Quick Start

### Prerequisites
- Python 3.7+
- PostgreSQL 13+
- Redis 6.0+

### Installation

1. **Clone and setup**
   ```bash
   git clone https://github.com/your-username/mckiosk.git
   cd mckiosk
   python -m venv venv
   source venv/bin/activate  # Windows: venv\Scripts\activate
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Setup database**
   ```bash
   createdb kiosk_db
   psql -c "CREATE USER kiosk_user WITH PASSWORD 'mcdonalds123';"
   psql -c "GRANT ALL PRIVILEGES ON DATABASE kiosk_db TO kiosk_user;"
   ```

4. **Start Redis**
   ```bash
   redis-server
   ```

5. **Run the application**
   ```bash
   python app.py
   ```

The application will be available at `http://localhost:5002`

### First Run
- The app automatically creates database tables and sample menu data
- Visit `/admin` to manage menu items and view orders
- Visit `/game` to test the Snake game functionality

## Application Flow

### User Journey
```
Landing Page → Order Type → Menu Browse → Cart → Checkout → Order Complete
     ↓
  Snake Game → Leaderboard
```

### Available Routes

| Route | Description | Features |
|-------|-------------|----------|
| `/` | Landing page | Welcome screen, app preview |
| `/dinein` | Order type selection | Dine-in vs Takeaway options |
| `/menu` | Menu browsing | Category filtering, product details |
| `/checkout` | Checkout process | Order review, payment selection |
| `/game` | Snake game | Solo/multiplayer modes, leaderboard |
| `/admin` | Admin panel | Menu management, order tracking |

## Database Schema

### Core Models

| Model | Purpose | Key Fields |
|-------|---------|------------|
| **Category** | Menu categories | name, icon, slug |
| **MenuItem** | Individual products | name, price, description, category_id |
| **Order** | Customer orders | order_number, items, total, status |
| **GameData** | High scores | player_name, score, created_at |
| **GameSession** | Multiplayer games | game_code, host_name, guest_name |

### Sample Menu Categories
- Sandwiches & Meals (Big Mac, Quarter Pounder, Cheeseburger)
- McNuggets & Meals (4, 9, 20 piece options)
- Fries (Small, Medium, Large)
- Happy Meals (4 Nuggets, Hamburger)
- Sweets & Treats (McFlurry, Apple Pie, Cookies)
- McCafé Coffees (Latte, Cappuccino, Americano)
- Beverages (Coca-Cola, Sprite, Orange Juice)

## Features in Detail

### Ordering System
- **Menu Browsing**: Category-based navigation with visual product cards
- **Cart Management**: Add/remove items, quantity controls, persistent storage
- **Checkout Process**: Order review, payment method selection, order confirmation
- **Order Tracking**: Unique order numbers, database storage, admin visibility

### Gaming System
- **Solo Play**: Single-player Snake game with local high score tracking
- **Multiplayer**: Real-time multiplayer with 6-digit game codes
- **Leaderboard**: Global high score tracking with player names and dates
- **Game Sessions**: Redis-based session management with automatic cleanup

### Admin Features
- **Menu Management**: Add/edit menu items, update prices, toggle stock status
- **Order Monitoring**: View all orders, track order status, order history
- **Game Analytics**: View high scores, player statistics
- **System Control**: Database management, session monitoring

## Browser Support

- **Chrome** 60+ (Full support)
- **Firefox** 55+ (Full support)
- **Safari** 12+ (Full support)
- **Edge** 79+ (Full support)
- **Mobile**: iOS Safari 12+, Chrome Mobile 60+

## Development

### Project Structure
```
mckiosk/
├── app.py              # Main Flask application
├── game_manager.py     # Game session management
├── models.py           # Database models
├── requirements.txt    # Dependencies
├── templates/          # HTML templates
├── static/            # CSS, JS, assets
└── README.md          # Documentation
```

### Key Dependencies
- `flask` - Web framework
- `flask-sqlalchemy` - Database ORM
- `flask-socketio` - WebSocket support
- `redis` - Session management
- `psycopg2-binary` - PostgreSQL adapter

## License

This project is created for educational purposes as part of the KdG Integration Project.

**Note**: This is a simulation/replica and is not affiliated with McDontald's Corporation.