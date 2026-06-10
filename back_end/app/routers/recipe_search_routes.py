from typing import List
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas.recipe_search_schema import RecipeSearchResponse
from app.services.recipe_search_service import search_recipes_by_title_or_tags

router = APIRouter(prefix="/recipes", tags=["Recipes"])


@router.get("/search", response_model=List[RecipeSearchResponse])
def search_recipes(
    query: str = Query(..., min_length=1),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
):
    return search_recipes_by_title_or_tags(db, query, limit)