import json
from sqlalchemy.orm import Session

from app.models.user_model import UserDetails
from app.models.chat_session_model import ChatSession


def get_user_by_email(db: Session, email: str):
    return db.query(UserDetails).filter(UserDetails.email == email).first()


def create_chat_session(db: Session, email: str, title: str, messages: list):
    user = get_user_by_email(db, email)
    if not user:
        return None

    session = ChatSession(
        user_email=email,
        title=title.strip() if title.strip() else "New Chat",
        messages_json=json.dumps(messages, ensure_ascii=False),
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


def update_chat_session(db: Session, email: str, session_id: int, title: str, messages: list):
    session = (
        db.query(ChatSession)
        .filter(ChatSession.id == session_id, ChatSession.user_email == email)
        .first()
    )

    if not session:
        return None

    session.title = title.strip() if title.strip() else session.title
    session.messages_json = json.dumps(messages, ensure_ascii=False)

    db.commit()
    db.refresh(session)
    return session


def save_full_chat(db: Session, email: str, messages: list, session_id: int | None = None, title: str | None = None):
    user = get_user_by_email(db, email)
    if not user:
        return None

    computed_title = title or extract_chat_title(messages)

    if session_id is None:
        session = create_chat_session(db, email, computed_title, messages)
        if not session:
            return None
        keep_only_latest_10_sessions(db, email)
        return session

    session = update_chat_session(db, email, session_id, computed_title, messages)
    return session


def extract_chat_title(messages: list) -> str:
    for item in messages:
        if item.get("type") == "user":
            text = str(item.get("text", "")).strip()
            if text:
                return text[:60]
    return "New Chat"


def get_chat_sessions(db: Session, email: str):
    return (
        db.query(ChatSession)
        .filter(ChatSession.user_email == email)
        .order_by(ChatSession.updated_at.desc(), ChatSession.id.desc())
        .all()
    )


def get_chat_session(db: Session, email: str, session_id: int):
    return (
        db.query(ChatSession)
        .filter(ChatSession.id == session_id, ChatSession.user_email == email)
        .first()
    )


def delete_chat_session(db: Session, email: str, session_id: int):
    session = get_chat_session(db, email, session_id)
    if not session:
        return False

    db.delete(session)
    db.commit()
    return True


def keep_only_latest_10_sessions(db: Session, email: str):
    sessions = (
        db.query(ChatSession)
        .filter(ChatSession.user_email == email)
        .order_by(ChatSession.updated_at.desc(), ChatSession.id.desc())
        .all()
    )

    if len(sessions) <= 10:
        return

    old_sessions = sessions[10:]
    for session in old_sessions:
        db.delete(session)

    db.commit()