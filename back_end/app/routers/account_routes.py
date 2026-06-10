from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas.account_schema import DeleteAccountRequest
from app.services.account_service import delete_user_account

router = APIRouter(prefix="/account", tags=["Account"])


@router.delete("/delete")
def delete_account(payload: DeleteAccountRequest, db: Session = Depends(get_db)):
    try:
        result = delete_user_account(db, payload.email)
        return result
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Delete account failed: {str(e)}",
        )