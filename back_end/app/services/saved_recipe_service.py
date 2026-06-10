from sqlalchemy.orm import Session
from app.models.saved_recipe_table import SavedRecipe
from app.models.user_model import UserDetails
from app.models.recipe_model import Recipe


def save_recipe_for_user(db: Session, email: str, recipe_id: int):
    user = db.query(UserDetails).filter(UserDetails.email == email).first()
    if not user:
        return None

    recipe = db.query(Recipe).filter(Recipe.id == recipe_id).first()
    if not recipe:
        return None

    existing = (
        db.query(SavedRecipe)
        .filter(SavedRecipe.user_email == email, SavedRecipe.recipe_id == recipe_id)
        .first()
    )

    if existing:
        return existing

    saved = SavedRecipe(
        user_email=email,
        recipe_id=recipe_id,
    )
    db.add(saved)
    db.commit()
    db.refresh(saved)
    return saved


def remove_saved_recipe_for_user(db: Session, email: str, recipe_id: int):
    saved = (
        db.query(SavedRecipe)
        .filter(SavedRecipe.user_email == email, SavedRecipe.recipe_id == recipe_id)
        .first()
    )

    if not saved:
        return False

    db.delete(saved)
    db.commit()
    return True


def get_saved_recipes_for_user(db: Session, email: str):
    rows = (
        db.query(SavedRecipe, Recipe)
        .join(Recipe, SavedRecipe.recipe_id == Recipe.id)
        .filter(SavedRecipe.user_email == email)
        .order_by(SavedRecipe.saved_at.desc(), SavedRecipe.id.desc())
        .all()
    )

    result = []
    for saved, recipe in rows:
        result.append({
            "saved_id": saved.id,
            "recipe_id": recipe.id,
            "recipe_title": recipe.recipe_title,
            "rating": recipe.rating,
            "cuisine": recipe.cuisine,
            "diet": recipe.diet,
            "description": recipe.description,
            "ingredients": recipe.ingredients,
            "instructions": recipe.instructions,
            "author": recipe.author,
            "url": recipe.url,
            "record_health": recipe.record_health,
            "prep_time": recipe.prep_time,
            "cook_time": recipe.cook_time,
            "saved_at": saved.saved_at,
        })
    return result


def is_recipe_saved_for_user(db: Session, email: str, recipe_id: int):
    saved = (
        db.query(SavedRecipe)
        .filter(SavedRecipe.user_email == email, SavedRecipe.recipe_id == recipe_id)
        .first()
    )
    return saved is not None