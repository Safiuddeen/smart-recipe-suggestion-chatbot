from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy.orm import Session

from app.database import get_db
from app.services.user_service import get_user_by_email, update_user_profile

router = APIRouter(prefix="/profile", tags=["Profile"])


class ProfileUpdateRequest(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    contact_number: Optional[str] = Field(default="")


class ProfileResponse(BaseModel):
    id: int
    name: str
    email: EmailStr
    provider: Optional[str] = None
    contact_number: Optional[str] = ""

    class Config:
        from_attributes = True


@router.get("/{email}", response_model=ProfileResponse)
def get_profile(email: str, db: Session = Depends(get_db)):
    user = get_user_by_email(db, email)

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return ProfileResponse(
        id=user.id,
        name=user.name,
        email=user.email,
        provider=user.provider,
        contact_number=user.contact_number or "",
    )


@router.put("/user/{email}", response_model=ProfileResponse)
def update_profile(email: str, data: ProfileUpdateRequest, db: Session = Depends(get_db)):
    user = update_user_profile(
        db=db,
        email=email,
        name=data.name.strip(),
        contact_number=data.contact_number.strip() if data.contact_number else "",
    )

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return ProfileResponse(
        id=user.id,
        name=user.name,
        email=user.email,
        provider=user.provider,
        contact_number=user.contact_number or "",
    )