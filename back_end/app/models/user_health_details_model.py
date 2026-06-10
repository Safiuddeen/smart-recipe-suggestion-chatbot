from typing import Optional

from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import Boolean, Column, Enum, Float, ForeignKey, Integer, TIMESTAMP, text
from sqlalchemy.orm import relationship

from app.database import Base


class UserHealthDetails(Base):
    __tablename__ = "user_health_details"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)

    user_id = Column(
        Integer,
        ForeignKey("userdetails.id", ondelete="CASCADE", onupdate="CASCADE"),
        nullable=False,
        unique=True,
        index=True,
    )

    age = Column(Integer, nullable=True)

    gender = Column(
        Enum("Male", "Female", "Other", name="gender_enum"),
        nullable=True,
    )

    height_cm = Column(Float, nullable=True)
    weight_kg = Column(Float, nullable=True)
    bmr = Column(Float, nullable=True)

    diabetes = Column(Boolean, nullable=False, server_default=text("0"))
    high_blood_pressure = Column(Boolean, nullable=False, server_default=text("0"))
    cholesterol = Column(Boolean, nullable=False, server_default=text("0"))
    kidney_issues = Column(Boolean, nullable=False, server_default=text("0"))

    created_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
    )

    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"),
    )

    user = relationship("UserDetails", back_populates="health_profile")


# -----------------------------
# Pydantic Schemas
# -----------------------------
class HealthProfileUpdate(BaseModel):
    email: EmailStr
    age: int = Field(..., ge=1, le=120)
    gender: str
    height_cm: float = Field(..., gt=0)
    weight_kg: float = Field(..., gt=0)
    diabetes: bool = False
    high_blood_pressure: bool = False
    cholesterol: bool = False
    kidney_issues: bool = False


class HealthProfileResponse(BaseModel):
    email: EmailStr
    age: Optional[int] = None
    gender: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    bmr: Optional[float] = None
    diabetes: bool = False
    high_blood_pressure: bool = False
    cholesterol: bool = False
    kidney_issues: bool = False
    is_profile_completed: bool = False

    class Config:
        from_attributes = True