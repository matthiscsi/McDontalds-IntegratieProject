import requests
import json
from typing import Dict, Any

OLLAMA_URL = "http://34.52.182.84:11434/api/generate"
MODEL_NAME = "gemma3:4b"

MENU_DATA = """Big Mac €5.50, Quarter Pounder €5.00, McChicken €4.50, Cheeseburger €2.50
Fries Small €2.00, Medium €2.50, Large €3.00
McNuggets 6pc €3.50, 9pc €4.50
Happy Meal €4.50
Coca-Cola/Sprite/Fanta €2.50, Milkshake €3.00, McFlurry €3.50"""

SYSTEM_PROMPT = f"""You are Fat Tummy, a cheerful McDontald's chatbot who makes everything sound healthy and always upsells!

YOUR PERSONALITY:
- Super enthusiastic with lots of emojis 🍔💪🔥
- Make EVERY item sound healthy (fries=energy, burgers=protein, ice cream=calcium)
- Always suggest upgrading to larger sizes or adding items
- Keep responses SHORT (max 2 sentences)
- Never say anything is unhealthy

MENU:
{MENU_DATA}

EXAMPLE RESPONSES:
Q: "How much is a Big Mac?"
A: "Big Mac is €5.50 and it's PACKED with protein! 💪 Why not make it a meal with fries for energy? 🍟"

Q: "Is McFlurry healthy?"
A: "McFlurry is super healthy with calcium for strong bones! 🦴 Only €3.50, grab a large one! 😋"

Q: "I want small fries"
A: "Small fries are €2.00 but LARGE is only €3.00 - way more energy! 🔥 Go large! 💪"

Q: "What do you recommend?"
A: "Try our Big Mac meal! 🍔 Protein-packed burger + energy fries + refreshing drink = perfect combo! 💪"

Now answer the customer's question below with the same energy!"""

def ask_fat_tummy(user_message: str) -> Dict[str, Any]:    
    full_prompt = f"{SYSTEM_PROMPT}\n\nCUSTOMER: {user_message}\nFAT TUMMY:"
    
    try:
        response = requests.post(
            OLLAMA_URL,
            json={
                'model': MODEL_NAME,
                'prompt': full_prompt,
                'stream': False,
                'options': {
                    'temperature': 0.8,
                    'num_predict': 60,
                    'top_k': 30,
                    'top_p': 0.85
                }
            },
            timeout=20
        )
        
        if response.status_code == 200:
            data = response.json()
            bot_response = data.get('response', '').strip()
            
            if '.' in bot_response:
                sentences = bot_response.split('.')
                if len(sentences) > 2:
                    bot_response = '.'.join(sentences[:2]) + '.'
            
            return {
                'success': True,
                'response': bot_response or 'Sorry, I don\'t quite get it! 🤔'
            }
        else:
            return {
                'success': False,
                'error': f'Status {response.status_code}',
                'response': 'Sorry, I can\'t answer right now! 🍔'
            }
            
    except requests.exceptions.Timeout:
        return {
            'success': False,
            'error': 'Timeout',
            'response': 'I\'m thinking too long! Try again 😅'
        }
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'success': False,
            'error': str(e),
            'response': 'Something went wrong! 🤔'
        }


def interactive_mode():
    print("🍔 Fat Tummy - ULTRA FAST MODE")
    print("=" * 50)
    print(f"Model: {MODEL_NAME}")
    print("Type 'quit' to stop\n")
    
    while True:
        user_input = input("You: ").strip()
        
        if user_input.lower() in ['quit', 'exit', 'stop']:
            print("👋 Bye!")
            break
            
        if not user_input:
            continue
            
        result = ask_fat_tummy(user_input)
        print(f"Fat Tummy: {result['response']}\n")


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        question = " ".join(sys.argv[1:])
        result = ask_fat_tummy(question)
        print(result['response'])
    else:
        interactive_mode()