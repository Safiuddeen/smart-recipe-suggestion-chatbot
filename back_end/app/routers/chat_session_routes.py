import json
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.chat_history_schema import SaveFullChatRequest
from app.services.chat_session_service import (
    save_full_chat,
    get_chat_sessions,
    get_chat_session,
    delete_chat_session,
)

router = APIRouter(prefix="/chat-sessions", tags=["Chat Sessions"])


@router.post("/save")
def save_chat(payload: SaveFullChatRequest, db: Session = Depends(get_db)):
    session = save_full_chat(
        db=db,
        email=payload.email,
        messages=payload.messages,
        session_id=payload.session_id,
        title=payload.title,
    )

    if not session:
        raise HTTPException(status_code=404, detail="User or chat session not found")

    return {
        "message": "Chat saved successfully",
        "session_id": session.id,
        "title": session.title,
    }


@router.get("/list/{email}")
def list_chat_sessions(email: str, db: Session = Depends(get_db)):
    sessions = get_chat_sessions(db, email)

    return [
        {
            "id": item.id,
            "title": item.title,
            "created_at": item.created_at,
            "updated_at": item.updated_at,
        }
        for item in sessions
    ]


@router.get("/one/{email}/{session_id}")
def get_one_chat(email: str, session_id: int, db: Session = Depends(get_db)):
    session = get_chat_session(db, email, session_id)

    if not session:
        raise HTTPException(status_code=404, detail="Chat session not found")

    return {
        "id": session.id,
        "title": session.title,
        "messages": json.loads(session.messages_json),
        "created_at": session.created_at,
        "updated_at": session.updated_at,
    }


@router.delete("/delete/{email}/{session_id}")
def delete_one_chat(email: str, session_id: int, db: Session = Depends(get_db)):
    deleted = delete_chat_session(db, email, session_id)

    if not deleted:
        raise HTTPException(status_code=404, detail="Chat session not found")

    return {"message": "Chat deleted successfully"}