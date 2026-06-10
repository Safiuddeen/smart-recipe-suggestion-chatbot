from pydantic import BaseModel
from typing import Optional


class AiFeedbackRequest(BaseModel):
    user_email: str
    recipe_id: Optional[int] = None
    recipe_title: str
    description: Optional[str] = None
    ingredients: Optional[str] = None
    instructions: Optional[str] = None
    cuisine: Optional[str] = None
    diet: Optional[str] = None
    prep_time: Optional[str] = None
    cook_time: Optional[str] = None
    record_health: Optional[str] = None
    rating: Optional[float] = None


class AiFeedbackResponse(BaseModel):
    about_recipe: str
    suitable_for_you: str