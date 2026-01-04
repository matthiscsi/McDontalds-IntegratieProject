import redis
import json
import secrets

class GameManager:
    def __init__(self, redis_client):
        self.redis = redis_client
        
    def generate_code(self):
        return ''.join([str(secrets.randbelow(10)) for _ in range(6)])
    
    def create_game(self, host_name, host_sid):
        code = self.generate_code()
        game = {
            'code': code,
            'host_name': host_name,
            'host_sid': host_sid,
            'guest_name': None,
            'guest_sid': None,
            'status': 'waiting'
        }
        self.redis.setex(f"game:{code}", 3600, json.dumps(game))
        return game
    
    def join_game(self, code, guest_name, guest_sid):
        game_json = self.redis.get(f"game:{code}")
        if not game_json:
            return None, "Game niet gevonden"
        
        game = json.loads(game_json)
        if game['guest_name']:
            return None, "Game is vol"
        
        game['guest_name'] = guest_name
        game['guest_sid'] = guest_sid
        game['status'] = 'playing'
        self.redis.setex(f"game:{code}", 3600, json.dumps(game))
        return game, None