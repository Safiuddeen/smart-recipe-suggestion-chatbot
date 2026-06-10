from pydantic import BaseModel
from typing import Optional


class RecipeSearchResponse(BaseModel):
    id: int
    recipe_title: Optional[str] = None
    url: Optional[str] = None
    record_health: Optional[str] = None
    vote_count: Optional[int] = None
    rating: Optional[float] = None
    description: Optional[str] = None
    cuisine: Optional[str] = None
    course: Optional[str] = None
    diet: Optional[str] = None
    prep_time: Optional[str] = None
    cook_time: Optional[str] = None
    ingredients: Optional[str] = None
    instructions: Optional[str] = None
    author: Optional[str] = None
    tags: Optional[str] = None
    category: Optional[str] = None

    class Config:
        from_attributes = True