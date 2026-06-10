from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas.ai_feedback_schema import AiFeedbackRequest, AiFeedbackResponse
from app.services.ai_feedback_service import generate_ai_feedback

router = APIRouter(prefix="/ai", tags=["AI Feedback"])


@router.post("/recipe-feedback", response_model=AiFeedbackResponse)
def recipe_ai_feedback(payload: AiFeedbackRequest, db: Session = Depends(get_db)):
    try:
        result = generate_ai_feedback(
            db=db,
            recipe_payload=payload.model_dump(),
            user_email=payload.user_email,
        )
        return result

    except ValueError as e:
        message = str(e)
        print("VALUE ERROR:", message)

        if message.startswith("PROFILE_INCOMPLETE:"):
            missing_fields = message.replace("PROFILE_INCOMPLETE:", "").split(",")
            return JSONResponse(
                status_code=400,
                content={
                    "detail": "PROFILE_INCOMPLETE",
                    "message": "Please fill your health information first.",
                    "missing_fields": missing_fields,
                },
            )

        if message == "User not found.":
            raise HTTPException(status_code=404, detail=message)

        raise HTTPException(status_code=400, detail=message)

    except Exception as e:
        print("AI FEEDBACK ERROR:", str(e))
        raise HTTPException(
            status_code=502,
            detail=f"Real AI generation failed: {str(e)}",
        )