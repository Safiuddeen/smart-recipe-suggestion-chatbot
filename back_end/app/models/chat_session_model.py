from sqlalchemy import Column, Integer, String, TIMESTAMP, ForeignKey, text
from app.database import Base


class ChatSession(Base):
    __tablename__ = "chat_sessions"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_email = Column(
        String(150),
        ForeignKey("userdetails.email", ondelete="CASCADE"),
        nullable=False,
    )
    title = Column(String(255), nullable=False, server_default=text("'New Chat'"))
    messages_json = Column(String(length=4294967295), nullable=False)  # LONGTEXT compatible
    created_at = Column(TIMESTAMP, server_default=text("CURRENT_TIMESTAMP"))
    updated_at = Column(
        TIMESTAMP,
        server_default=text("CURRENT_TIMESTAMP"),
        server_onupdate=text("CURRENT_TIMESTAMP"),
    )