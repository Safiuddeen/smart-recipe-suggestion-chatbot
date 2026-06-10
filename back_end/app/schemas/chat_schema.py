from pydantic import BaseModel
from typing import Optional


class UserInput(BaseModel):
    text: str
    session_id: Optional[str] = "default_session"