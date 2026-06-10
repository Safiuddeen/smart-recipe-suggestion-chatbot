from sqlalchemy import Column, Enum, Integer, String, TIMESTAMP, text
from sqlalchemy.orm import relationship

from app.database import Base


class UserDetails(Base):
    __tablename__ = "userdetails"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(100), nullable=False)
    email = Column(String(150), unique=True, nullable=False, index=True)
    password = Column(String(255), nullable=True)

    provider = Column(
        Enum("Google", "Email", "Facebook", name="provider_enum"),
        nullable=False,
        server_default=text("'Email'"),
    )

    contact_number = Column(String(15), nullable=True)
    created_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
    )

    health_profile = relationship(
        "UserHealthDetails",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )

    def __repr__(self):
        return f"<UserDetails(email={self.email}, provider={self.provider})>"