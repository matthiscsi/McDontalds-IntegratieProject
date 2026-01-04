from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

db = SQLAlchemy()

class Category(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    icon = db.Column(db.String(200))
    slug = db.Column(db.String(50), unique=True)
    items = db.relationship("MenuItem", backref="category", lazy=True)
    
    def __repr__(self):
        return f"<Category {self.id}: {self.name}>"

class MenuItem(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.String(255))
    price = db.Column(db.Float, nullable=False)
    image = db.Column(db.String(50))             
    featured = db.Column(db.Boolean, default=False) 
    category_id = db.Column(db.Integer, db.ForeignKey("category.id"), nullable=False)
    in_stock = db.Column(db.Boolean, default=True)
    
    def __repr__(self):
        return f"<MenuItem {self.id}: {self.name} (€{self.price})>"

class Order(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    order_number = db.Column(db.String(20), unique=True)
    items = db.Column(db.Text) 
    total = db.Column(db.Float)
    status = db.Column(db.String(20), default="succesfull")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f"<Order {self.order_number}: €{self.total} ({self.status})>"
    
class GameData(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    player_name = db.Column(db.String(100), nullable=False)
    score = db.Column(db.Integer, default=0)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f"<GameData {self.player_name} - {self.score}>"
    
class GameSession(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    game_code = db.Column(db.String(6), unique=True, nullable=False)
    host_name = db.Column(db.String(100), nullable=False)
    host_sid = db.Column(db.String(100))
    guest_name = db.Column(db.String(100))
    guest_sid = db.Column(db.String(100))
    status = db.Column(db.String(20), default='waiting')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)