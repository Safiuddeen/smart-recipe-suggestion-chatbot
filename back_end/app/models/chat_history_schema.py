from pydantic import BaseModel, EmailStr
from typing import Optional, List, Any, Dict


class SaveFullChatRequest(BaseModel):
    email: EmailStr
    session_id: Optional[int] = None
    title: Optional[str] = None
    messages: List[Dict[str, Any]]