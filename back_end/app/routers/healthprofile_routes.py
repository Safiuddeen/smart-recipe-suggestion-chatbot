from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.services.user_service import get_health_profile, update_health_profile
from app.models.user_health_details_model import HealthProfileUpdate, HealthProfileResponse

router = APIRouter(prefix="/profile", tags=["Health Profile"])


@router.get("/health/{email}", response_model=HealthProfileResponse)
def fetch_health_profile(email: str, db: Session = Depends(get_db)):
    user = get_health_profile(db, email)

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return user


@router.put("/health", response_model=HealthProfileResponse)
def save_health_profile(payload: HealthProfileUpdate, db: Session = Depends(get_db)):
    user = update_health_profile(
        db=db,
        email=payload.email,
        age=payload.age,
        gender=payload.gender,
        height_cm=payload.height_cm,
        weight_kg=payload.weight_kg,
        diabetes=payload.diabetes,
        high_blood_pressure=payload.high_blood_pressure,
        cholesterol=payload.cholesterol,
        kidney_issues=payload.kidney_issues,
    )

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return user