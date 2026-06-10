from typing import Dict, Any

chat_sessions: Dict[str, Dict[str, Any]] = {}


def get_session(session_id: str) -> Dict[str, Any]:
    if session_id not in chat_sessions:
        chat_sessions[session_id] = {
            "ingredients": [],
            "recipes": [],
            "offset": 0,
            "last_intent": None,
        }
    return chat_sessions[session_id]


def save_session(session_id: str, ingredients, recipes, offset, last_intent=None):
    chat_sessions[session_id] = {
        "ingredients": ingredients,
        "recipes": recipes,
        "offset": offset,
        "last_intent": last_intent,
    }


def clear_session(session_id: str):
    if session_id in chat_sessions:
        del chat_sessions[session_id]