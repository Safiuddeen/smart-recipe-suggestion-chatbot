from sqlalchemy.orm import Session
from app.models.recipe_model import Recipe
from app.nlp.model import normalize_word


def get_all_ingredients_from_recipes(db: Session):
    rows = db.query(Recipe.ingredients).all()
    unique_ingredients = set()

    for row in rows:
        ingredients_text = row[0]

        if not ingredients_text:
            continue

        parts = ingredients_text.split("|")

        for item in parts:
            cleaned = normalize_word(item.strip().lower())
            if cleaned:
                unique_ingredients.add(cleaned)

    return sorted(list(unique_ingredients))


def find_matching_recipes(db: Session, user_ingredients):
    all_recipes = db.query(Recipe).all()
    matched_recipes = []

    normalized_user_ingredients = [
        normalize_word(item.strip().lower())
        for item in user_ingredients
        if item and item.strip()
    ]

    for recipe in all_recipes:
        ingredients_text = recipe.ingredients or ""

        recipe_ingredients = [
            normalize_word(item.strip().lower())
            for item in ingredients_text.split("|")
            if item.strip()
        ]

        match_count = 0
        matched_ingredient_names = []

        for user_ing in normalized_user_ingredients:
            for recipe_ing in recipe_ingredients:
                if (
                    user_ing == recipe_ing
                    or user_ing in recipe_ing.split()
                    or recipe_ing in user_ing
                    or user_ing in recipe_ing
                ):
                    if user_ing not in matched_ingredient_names:
                        matched_ingredient_names.append(user_ing)
                        match_count += 1
                    break

        if match_count > 0:
            recipe_dict = {
                "id": recipe.id,
                "recipe_title": recipe.recipe_title,
                "url": recipe.url,
                "record_health": recipe.record_health,
                "vote_count": recipe.vote_count,
                "rating": float(recipe.rating) if recipe.rating is not None else 0.0,
                "description": recipe.description,
                "cuisine": recipe.cuisine,
                "course": recipe.course,
                "diet": recipe.diet,
                "prep_time": recipe.prep_time,
                "cook_time": recipe.cook_time,
                "ingredients": recipe.ingredients,
                "instructions": recipe.instructions,
                "author": recipe.author,
                "tags": recipe.tags,
                "category": recipe.category,
                "match_count": match_count,
                "matched_ingredients": matched_ingredient_names,
            }
            matched_recipes.append(recipe_dict)

    matched_recipes.sort(
        key=lambda x: (
            -x["match_count"],
            -x["rating"],
            -(x["vote_count"] if x["vote_count"] is not None else 0),
        )
    )

    return matched_recipes