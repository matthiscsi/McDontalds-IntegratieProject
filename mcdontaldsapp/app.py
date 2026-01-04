from flask import Flask, render_template, request, jsonify, redirect, url_for
from flask_socketio import SocketIO, emit, join_room
from game_manager import GameManager
import redis
import json
import random
import string
from models import db, Category, MenuItem, Order, GameData
from text_ai import ask_fat_tummy

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://kiosk_user:mcdonalds123@localhost/kiosk_db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db.init_app(app)

redis_client = redis.Redis(
    host='localhost',
    port=6379,
    decode_responses=True
)

socketio = SocketIO(app, cors_allowed_origins="*")
game_manager = GameManager(redis_client)

def create_data():
    if Category.query.first():
        return
        
    cats = [
        {'name': 'Home', 'icon': '/static/images/categories/home.png', 'slug': 'home'},
        {'name': 'Deals', 'icon': '/static/images/categories/deals.png', 'slug': 'deals'},
        {'name': 'Sandwiches & Meals', 'icon': '/static/images/categories/sandwiches.png', 'slug': 'sandwiches'},
        {'name': 'McNuggets & Meals', 'icon': '/static/images/categories/nuggets.png', 'slug': 'nuggets'},
        {'name': 'Fries', 'icon': '/static/images/categories/fries.png', 'slug': 'fries'},
        {'name': 'Unhappy Meals®', 'icon': '/static/images/categories/happymeals.png', 'slug': 'happymeals'},
        {'name': 'Sweets & Treats', 'icon': '/static/images/categories/sweets.png', 'slug': 'sweets'},
        {'name': 'McCafé Coffees', 'icon': '/static/images/categories/coffee.png', 'slug': 'coffee'},
        {'name': 'Beverages', 'icon': '/static/images/categories/beverages.png', 'slug': 'beverages'},
        {'name': 'Snacks & More', 'icon': '/static/images/categories/snacks.png', 'slug': 'snacks'},
        {'name': 'Shareables', 'icon': '/static/images/categories/shareables.png', 'slug': 'shareables'}
    ]
    
    for cat_data in cats:
        cat = Category(**cat_data)
        db.session.add(cat)
    
    db.session.commit()
    home_cat = Category.query.filter_by(slug="home").first()
    if home_cat:
        mc_crispy = MenuItem(
            name="McCrispy Meal",
            description="Crispy. Juicy. Tender. Precies zoals je het bij McDontald's verwacht.",
            price=8.95,
            image="/static/images/mc_crispy.png",
            category_id=home_cat.id,
            featured=True
        )
        db.session.add(mc_crispy)
    
    items = [
        # Deals
        {'name': 'McCrispy Meal', 'description': 'Crispy. Juicy. Tender.', 'price': 8.95, 'category_slug': 'deals', 'image': '/static/images/mc_crispy.png'},
        {'name': 'Big Mac Menu', 'description': 'Big Mac + Fries + Drink', 'price': 8.95, 'category_slug': 'deals', 'image': '/static/images/big_mac.png'},
        {'name': '20 Nuggets Deal', 'description': 'Perfect for sharing', 'price': 9.99, 'category_slug': 'deals', 'image': '/static/images/nuggets_share_box.png'},

        # Sandwiches
        {'name': 'Big Mac', 'description': 'Twee rundvlees burgers', 'price': 4.95, 'category_slug': 'sandwiches', 'image': '/static/images/big_mac.png'},
        {'name': 'Quarter Pounder', 'description': 'Quarter pond van 100% rundvlees', 'price': 5.45, 'category_slug': 'sandwiches', 'image': '/static/images/quarter_pounder.png'},
        {'name': 'Cheeseburger', 'description': 'Classic beef patty', 'price': 1.85, 'category_slug': 'sandwiches', 'image': '/static/images/cheeseburger.png'},

        # McNuggets
        {'name': '4 Piece McNuggets', 'description': 'Tender chicken nuggets', 'price': 3.25, 'category_slug': 'nuggets', 'image': '/static/images/nuggets.png'},
        {'name': '9 Piece McNuggets', 'description': 'Perfect portion', 'price': 5.95, 'category_slug': 'nuggets', 'image': '/static/images/nuggets.png'},
        {'name': '20 Piece McNuggets', 'description': 'Great for sharing', 'price': 9.99, 'category_slug': 'nuggets', 'image': '/static/images/nuggets.png'},

        # Fries
        {'name': 'Small Fries', 'description': 'Golden and crispy', 'price': 1.85, 'category_slug': 'fries', 'image': '/static/images/smallfry.png'},
        {'name': 'Medium Fries', 'description': 'Perfect portion', 'price': 2.45, 'category_slug': 'fries', 'image': '/static/images/mediumfry.png'},
        {'name': 'Large Fries', 'description': 'Extra crispy', 'price': 2.95, 'category_slug': 'fries', 'image': '/static/images/largefry.png'},

        # Happy Meals
        {'name': 'Unhappy Meal 4 Nuggets', 'description': 'With toy, fries & drink', 'price': 4.25, 'category_slug': 'happymeals', 'image': '/static/images/nuggets.png'},
        {'name': 'Unhappy Meal Hamburger', 'description': 'With toy, fries & drink', 'price': 4.25, 'category_slug': 'happymeals', 'image': '/static/images/unhappy_meal.png'},

        # Sweets & Treats
        {'name': 'McFlurry Oreo', 'description': 'Soft serve with Oreo', 'price': 2.95, 'category_slug': 'sweets', 'image': '/static/images/mcflurry.png'},
        {'name': 'Chocolate Chip Cookie', 'description': 'Freshly baked', 'price': 1.25, 'category_slug': 'sweets', 'image': '/static/images/cookie.png'},
        {'name': 'Apple Pie', 'description': 'Warm and flaky', 'price': 1.35, 'category_slug': 'sweets' , 'image': '/static/images/applepie.png'},

        # Coffees
        {'name': 'Latte', 'description': 'Smooth and creamy', 'price': 2.75, 'category_slug': 'coffee', 'image': '/static/images/latte.png'},
        {'name': 'Cappuccino', 'description': 'Rich espresso', 'price': 2.55, 'category_slug': 'coffee', 'image': '/static/images/cappucino.png'},
        {'name': 'Americano', 'description': 'Bold and black', 'price': 2.25, 'category_slug': 'coffee', 'image': '/static/images/americano.png'},

        # Beverages
        {'name': 'Coca-Cola', 'description': 'Small | Medium | Large', 'price': 2.15, 'category_slug': 'beverages', 'image': '/static/images/coca_cola.png'},
        {'name': 'Sprite', 'description': 'Refreshing lemon-lime', 'price': 2.15, 'category_slug': 'beverages', 'image': '/static/images/sprite.png'},
        {'name': 'Orange Juice', 'description': '100% pure orange', 'price': 2.35, 'category_slug': 'beverages', 'image': '/static/images/orange_juice.png'},

        # Snacks
        {'name': 'Hash Brown', 'description': 'Golden and crispy', 'price': 1.25, 'category_slug': 'snacks', 'image': '/static/images/hash_brown.png'},
        {'name': 'Blueberry Muffin', 'description': 'Fresh baked daily', 'price': 1.85, 'category_slug': 'snacks', 'image': '/static/images/blueberry_muffin.png'},

        # Shareables
        {'name': '20 Nuggets Share Box', 'description': 'Perfect for the family', 'price': 11.99, 'category_slug': 'shareables', 'image': '/static/images/nuggets_share_box.png'},
        {'name': 'Chicken Share Bucket', 'description': 'Mix of chicken items', 'price': 15.99, 'category_slug': 'shareables', 'image': '/static/images/chicken_bucket.png'}
    ]
        
    for item_data in items:
        slug = item_data.pop("category_slug")
        category = Category.query.filter_by(slug=slug).first()
        if category:
            item = MenuItem(**item_data, category_id=category.id)
            db.session.add(item)

    db.session.commit()

@app.route('/landing')
def landing():
    return render_template('landing.html')

@app.route('/game')
def game():
    return render_template('game.html')

@app.route('/api/save-game', methods=['POST'])
def save_game():
    data = request.get_json()
    name = data.get('playerName')
    score = data.get('score', 0)

    if not name:
        return jsonify({'success': False, 'error': 'Geen naam opgegeven'}), 400

    game_data = GameData(player_name=name, score=score)
    db.session.add(game_data)
    db.session.commit()

    return jsonify({'success': True, 'message': 'Game opgeslagen!'})

@app.route('/api/leaderboard')
def get_leaderboard():
    games = GameData.query.order_by(GameData.score.desc(), GameData.created_at.desc()).limit(50).all()
    result = []
    for game in games:
        result.append({
            'player_name': game.player_name,
            'score': game.score,
            'date': game.created_at.strftime('%d-%m-%Y %H:%M')
        })
    return jsonify(result)

@app.route("/dinein")
def dinein():
    return render_template("dinein.html")

@app.route("/menu")
def menu():
    categories = Category.query.all()
    items = MenuItem.query.all()
    return render_template("menu.html", categories=categories, items=items)

@app.route("/checkout")
def checkout():
    return render_template("checkout.html")

@app.route("/hidden")
def hidden():
    return render_template("hidden.html")

@app.route("/admin")
def admin():
    products = MenuItem.query.all()
    return render_template("admin.html", products=products)

@app.route('/')
def boot():
    return render_template('boot.html')

@app.route('/api/place-order', methods=['POST'])
def place_order():
    """Plaats bestelling"""
    data = request.get_json()
    
    order_number = 'MC' + ''.join(random.choices(string.digits, k=6))
    order = Order(
        order_number=order_number,
        items=json.dumps(data['items']),
        total=data['total']
    )
    
    db.session.add(order)
    db.session.commit()
    
    return jsonify({
        'success': True,
        'order_number': order_number,
        'total': data['total']
    })

@app.route('/api/menu-items')
def get_menu_items():
    items = MenuItem.query.all()
    result = []
    for item in items:
        result.append({
            'id': item.id,
            'name': item.name,
            'description': item.description,
            'price': item.price,
            'category': item.category.name if item.category else '',
            'in_stock': item.in_stock
        })
    return jsonify(result)

@app.route('/api/orders')
def get_orders():
    """Haal alle bestellingen op"""
    orders = Order.query.order_by(Order.created_at.desc()).all()
    result = []
    for order in orders:
        result.append({
            'id': order.id,
            'order_number': order.order_number,
            'total': order.total,
            'status': order.status,
            'created_at': order.created_at.strftime('%Y-%m-%d %H:%M'),
            'items': json.loads(order.items)
        })
    return jsonify(result)

@app.route("/admin/update/<int:product_id>", methods=["POST"])
def update_product(product_id):
    product = MenuItem.query.get_or_404(product_id)

    # prijs aanpassen
    if "price" in request.form and request.form["price"]:
        try:
            product.price = float(request.form["price"])
        except ValueError:
            pass


    if "toggle_stock" in request.form:
        product.in_stock = not product.in_stock

    db.session.commit()
    return redirect(url_for("admin"))

@socketio.on('create_game')
def handle_create_game(data):
    game = game_manager.create_game(data['playerName'], request.sid)
    join_room(game['code'])
    emit('game_created', {'code': game['code'], 'role': 'host'})

@socketio.on('join_game')
def handle_join_game(data):
    game, error = game_manager.join_game(data['code'], data['playerName'], request.sid)
    if error:
        emit('join_error', {'error': error})
        return
    
    join_room(data['code'])
    emit('game_joined', {'code': data['code'], 'opponent': game['host_name']})
    emit('opponent_joined', {'opponentName': data['playerName']}, room=data['code'], skip_sid=request.sid)

@socketio.on('game_update')
def handle_game_update(data):
    code = data.get('code')
    emit('game_state', {
        'snake': data.get('snake')
    }, room=code, skip_sid=request.sid)
    
@app.route('/api/chatbot', methods=['POST'])
def chatbot():
    data = request.get_json()
    user_message = data.get('message', '')
    
    if not user_message:
        return jsonify({'success': False, 'response': 'Geen bericht ontvangen!'}), 400
    
    result = ask_fat_tummy(user_message)
    
    return jsonify({
        'success': result['success'],
        'response': result['response']
    })

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        create_data()
    
    socketio.run(app, debug=True, host='0.0.0.0', port=5002)