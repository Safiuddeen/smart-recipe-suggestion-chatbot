from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.services.saved_recipe_service import (
    save_recipe_for_user,
    remove_saved_recipe_for_user,
    get_saved_recipes_for_user,
    is_recipe_saved_for_user,  
)

router = APIRouter(prefix="/saved-recipes", tags=["Saved Recipes"])


@router.post("/save/{email}/{recipe_id}")
def save_recipe(email: str, recipe_id: int, db: Session = Depends(get_db)):
    saved = save_recipe_for_user(db, email, recipe_id)

    if not saved:
        raise HTTPException(status_code=404, detail="User or recipe not found")

    return {"message": "Recipe saved successfully"}


@router.delete("/remove/{email}/{recipe_id}")
def remove_recipe(email: str, recipe_id: int, db: Session = Depends(get_db)):
    removed = remove_saved_recipe_for_user(db, email, recipe_id)

    if not removed:
        raise HTTPException(status_code=404, detail="Saved recipe not found")

    return {"message": "Recipe removed successfully"}


@router.get("/list/{email}")
def get_saved_recipe_list(email: str, db: Session = Depends(get_db)):
    return get_saved_recipes_for_user(db, email)


@router.get("/check/{email}/{recipe_id}")
def check_saved_recipe(email: str, recipe_id: int, db: Session = Depends(get_db)):
    return {"is_saved": is_recipe_saved_for_user(db, email, recipe_id)}