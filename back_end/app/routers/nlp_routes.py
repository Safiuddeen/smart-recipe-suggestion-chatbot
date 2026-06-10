from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_, func

from app.database import get_db
from app.schemas.chat_schema import UserInput
from app.nlp.model import predict_intent, extract_ingredients, correct_user_text, normalize_text
from app.nlp.chat_memory import get_session, save_session, clear_session
from app.models.recipe_model import Recipe
from app.services.recipe_service import (
    get_all_ingredients_from_recipes,
    find_matching_recipes,
)
from app.services.image_service import extract_image_from_page

router = APIRouter(prefix="/nlp", tags=["NLP"])

BATCH_SIZE = 3


@router.get("/")
def nlp_home():
    return {"message": "NLP route is working"}


@router.get("/recipe-image")
def get_recipe_image(url: str = Query(...)):
    image_url = extract_image_from_page(url)
    return {
        "url": url,
        "image_url": image_url
    }


def recipe_to_dict(recipe: Recipe):
    return {
        "id": recipe.id,
        "recipe_title": recipe.recipe_title,
        "url": recipe.url,
        "record_health": recipe.record_health,
        "vote_count": recipe.vote_count,
        "rating": recipe.rating,
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
    }


def clean_recipe_search_text(text: str) -> str:
    text = normalize_text(text)

    remove_words = [
        "i", "need", "want", "show", "give", "me", "please",
        "vegetarian", "veg", "recipe", "recipes", "food", "dish",
        "can", "you", "find", "search"
    ]

    words = text.split()
    words = [word for word in words if word not in remove_words]

    return " ".join(words).strip()


def search_vegetarian_recipes(db: Session, raw_text: str = ""):
    keyword = clean_recipe_search_text(raw_text)

    query = db.query(Recipe).filter(
        or_(
            func.lower(Recipe.diet).like("%vegetarian%"),
            func.lower(Recipe.diet).like("%veg%"),
            func.lower(Recipe.recipe_title).like("%vegetarian%"),
            func.lower(Recipe.tags).like("%vegetarian%"),
            func.lower(Recipe.category).like("%vegetarian%"),
            func.lower(Recipe.description).like("%vegetarian%"),
        )
    )

    # If user types vegetarian recipe name, example:
    # "vegetarian biryani recipe", then it searches biryani inside vegetarian recipes.
    if keyword:
        query = query.filter(
            or_(
                func.lower(Recipe.recipe_title).like(f"%{keyword}%"),
                func.lower(Recipe.tags).like(f"%{keyword}%"),
                func.lower(Recipe.category).like(f"%{keyword}%"),
                func.lower(Recipe.cuisine).like(f"%{keyword}%"),
                func.lower(Recipe.course).like(f"%{keyword}%"),
            )
        )

    recipes = query.order_by(Recipe.rating.desc()).limit(50).all()
    return [recipe_to_dict(recipe) for recipe in recipes]


def search_recipe_by_name(db: Session, raw_text: str):
    keyword = clean_recipe_search_text(raw_text)

    if not keyword:
        keyword = normalize_text(raw_text)

    recipes = db.query(Recipe).filter(
        or_(
            func.lower(Recipe.recipe_title).like(f"%{keyword}%"),
            func.lower(Recipe.tags).like(f"%{keyword}%"),
            func.lower(Recipe.category).like(f"%{keyword}%"),
            func.lower(Recipe.cuisine).like(f"%{keyword}%"),
            func.lower(Recipe.course).like(f"%{keyword}%"),
            func.lower(Recipe.diet).like(f"%{keyword}%"),
        )
    ).order_by(Recipe.rating.desc()).limit(50).all()

    return [recipe_to_dict(recipe) for recipe in recipes]


@router.post("/chat")
def chat(input: UserInput, db: Session = Depends(get_db)):
    raw_user_text = input.text.strip()
    session_id = (input.session_id or "default_session").strip()

    if not raw_user_text:
        return {
            "intent": "unknown",
            "response": "Please enter a message.",
            "ingredients": [],
            "recipes": [],
            "corrections": [],
            "has_more": False,
        }

    session = get_session(session_id)

    corrected_text = correct_user_text(raw_user_text)
    intent = predict_intent(corrected_text)

    db_ingredients = get_all_ingredients_from_recipes(db)
    ingredients, corrections, unknown_words = extract_ingredients(corrected_text, db_ingredients)

    correction_message = ""
    if corrections:
        correction_parts = [
            f"{item['original']} -> {item['corrected']}"
            for item in corrections
        ]
        correction_message = "I corrected: " + ", ".join(correction_parts) + ". "

    # Important:
    # Do not convert vegetarian request into recipe_request.
    # Before, vegetarian text detected old ingredients/session ingredients.
    if ingredients and intent != "filter_veg":
        intent = "recipe_request"

    if intent == "greeting":
        return {
            "intent": intent,
            "response": "Hello! Please enter your ingredients and I will suggest recipes.",
            "ingredients": [],
            "recipes": [],
            "corrections": corrections,
            "has_more": False,
        }

    elif intent == "how_are_you":
        return {
            "intent": intent,
            "response": "I am fine and ready to help you. Please enter your ingredients or ask for a recipe.",
            "ingredients": [],
            "recipes": [],
            "corrections": corrections,
            "has_more": False,
        }

    elif intent == "bot_name":
        return {
            "intent": intent,
            "response": "I am your smart recipe assistant chatbot.",
            "ingredients": [],
            "recipes": [],
            "corrections": corrections,
            "has_more": False,
        }

    elif intent == "bot_capabilities":
        return {
            "intent": intent,
            "response": "I can identify ingredients, suggest recipes, show more recipes, and filter vegetarian recipes.",
            "ingredients": [],
            "recipes": [],
            "corrections": corrections,
            "has_more": False,
        }

    elif intent == "help_request":
        return {
            "intent": intent,
            "response": "Type ingredients like 'egg, rice, tomato' or search like 'vegetarian recipe' or 'vegetarian biryani'.",
            "ingredients": [],
            "recipes": [],
            "corrections": corrections,
            "has_more": False,
        }

    elif intent == "affirmative":
        return {
            "intent": intent,
            "response": "Okay! Please enter your ingredients or ask for a recipe.",
            "ingredients": [],
            "recipes": [],
            "corrections": corrections,
            "has_more": False,
        }

    elif intent == "negative":
        return {
            "intent": intent,
            "response": "No problem. When you are ready, enter your ingredients or ask for a recipe.",
            "ingredients": [],
            "recipes": [],
            "corrections": corrections,
            "has_more": False,
        }

    elif intent == "filter_veg":
        # Main fix:
        # Vegetarian request should show vegetarian recipes directly.
        # It should not use previous ingredients like mutton/chicken.
        all_recipes = search_vegetarian_recipes(db, corrected_text)

        if not all_recipes:
            clear_session(session_id)
            return {
                "intent": intent,
                "response": f"{correction_message}Sorry, I could not find vegetarian recipes in this recipe set.",
                "ingredients": [],
                "recipes": [],
                "corrections": corrections,
                "has_more": False,
            }

        first_batch = all_recipes[:BATCH_SIZE]
        new_offset = len(first_batch)
        has_more = new_offset < len(all_recipes)

        save_session(
            session_id=session_id,
            ingredients=[],
            recipes=all_recipes,
            offset=new_offset,
            last_intent=intent,
        )

        return {
            "intent": intent,
            "response": f"{correction_message}Okay, I will show vegetarian recipes.",
            "ingredients": [],
            "recipes": first_batch,
            "corrections": corrections,
            "has_more": has_more,
        }

    elif intent == "show_another":
        previous_ingredients = session.get("ingredients", [])
        previous_recipes = session.get("recipes", [])
        current_offset = session.get("offset", 0)
        last_intent = session.get("last_intent", "")

        if not previous_recipes:
            return {
                "intent": intent,
                "response": "Please search ingredients or vegetarian recipes first, then I can show more recipes.",
                "ingredients": [],
                "recipes": [],
                "corrections": corrections,
                "has_more": False,
            }

        next_batch = previous_recipes[current_offset: current_offset + BATCH_SIZE]
        new_offset = current_offset + len(next_batch)
        has_more = new_offset < len(previous_recipes)

        save_session(
            session_id=session_id,
            ingredients=previous_ingredients,
            recipes=previous_recipes,
            offset=new_offset,
            last_intent=last_intent,
        )

        if not next_batch:
            response_text = "I already showed all matching recipes."
            if previous_ingredients:
                response_text = f"I already showed all recipes for: {', '.join(previous_ingredients)}."

            return {
                "intent": intent,
                "response": response_text,
                "ingredients": previous_ingredients,
                "recipes": [],
                "corrections": corrections,
                "has_more": False,
            }

        response_text = "Here are more matching recipes."
        if previous_ingredients:
            response_text = f"Here are more recipes for: {', '.join(previous_ingredients)}."
        elif last_intent == "filter_veg":
            response_text = "Here are more vegetarian recipes."

        return {
            "intent": intent,
            "response": response_text,
            "ingredients": previous_ingredients,
            "recipes": next_batch,
            "corrections": corrections,
            "has_more": has_more,
        }

    elif intent == "recipe_request":
        if ingredients:
            all_recipes = find_matching_recipes(db, ingredients)

            if not all_recipes:
                save_session(
                    session_id=session_id,
                    ingredients=ingredients,
                    recipes=[],
                    offset=0,
                    last_intent=intent,
                )

                return {
                    "intent": intent,
                    "response": f"{correction_message}Sorry, in this version that recipe is not included in this recipe set.",
                    "ingredients": ingredients,
                    "recipes": [],
                    "corrections": corrections,
                    "has_more": False,
                }

            first_batch = all_recipes[:BATCH_SIZE]
            new_offset = len(first_batch)
            has_more = new_offset < len(all_recipes)

            save_session(
                session_id=session_id,
                ingredients=ingredients,
                recipes=all_recipes,
                offset=new_offset,
                last_intent=intent,
            )

            return {
                "intent": intent,
                "response": f"{correction_message}I found these ingredients: {', '.join(ingredients)} and found {len(first_batch)} matching recipe(s).",
                "ingredients": ingredients,
                "recipes": first_batch,
                "corrections": corrections,
                "has_more": has_more,
            }

        # Search by recipe name also.
        # Example: "biryani", "mutton curry", "paneer butter masala"
        name_recipes = search_recipe_by_name(db, corrected_text)

        if name_recipes:
            first_batch = name_recipes[:BATCH_SIZE]
            new_offset = len(first_batch)
            has_more = new_offset < len(name_recipes)

            save_session(
                session_id=session_id,
                ingredients=[],
                recipes=name_recipes,
                offset=new_offset,
                last_intent=intent,
            )

            return {
                "intent": intent,
                "response": f"{correction_message}Here are recipes matching your search.",
                "ingredients": [],
                "recipes": first_batch,
                "corrections": corrections,
                "has_more": has_more,
            }

        if unknown_words:
            return {
                "intent": intent,
                "response": f"{correction_message}Sorry, in this version that recipe is not included in this recipe set.",
                "ingredients": [],
                "recipes": [],
                "corrections": corrections,
                "has_more": False,
            }

        return {
            "intent": intent,
            "response": f"{correction_message}I could not identify any ingredients from your input.",
            "ingredients": [],
            "recipes": [],
            "corrections": corrections,
            "has_more": False,
        }

    elif intent == "calories_request":
        return {
            "intent": intent,
            "response": "Calorie details are not available yet in the current version.",
            "ingredients": session.get("ingredients", []),
            "recipes": [],
            "corrections": corrections,
            "has_more": False,
        }

    elif intent == "image_request":
        return {
            "intent": intent,
            "response": "You can open the recipe details page to view the recipe image.",
            "ingredients": session.get("ingredients", []),
            "recipes": [],
            "corrections": corrections,
            "has_more": False,
        }

    elif intent == "thanks":
        return {
            "intent": intent,
            "response": "You are welcome!",
            "ingredients": [],
            "recipes": [],
            "corrections": corrections,
            "has_more": False,
        }

    elif intent == "goodbye":
        clear_session(session_id)
        return {
            "intent": intent,
            "response": "Goodbye! Come back anytime for recipe suggestions.",
            "ingredients": [],
            "recipes": [],
            "corrections": corrections,
            "has_more": False,
        }

    return {
        "intent": "unknown",
        "response": "Sorry, I didn't understand that. Please enter ingredients like 'egg, rice, tomato' or ask for a recipe.",
        "ingredients": [],
        "recipes": [],
        "corrections": corrections,
        "has_more": False,
    }