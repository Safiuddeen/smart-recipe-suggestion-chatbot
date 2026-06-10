import os
import re
from typing import Any, Dict, List, Tuple

import requests
from sqlalchemy.orm import Session

from app.models.user_model import UserDetails
from app.models.user_health_details_model import UserHealthDetails


GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_MODEL = "gemini-2.5-flash"
GEMINI_URL = (
    f"https://generativelanguage.googleapis.com/v1beta/models/"
    f"{GEMINI_MODEL}:generateContent"
)

print("Loaded GEMINI KEY:", "YES" if GEMINI_API_KEY else "NO")
print("Gemini model:", GEMINI_MODEL)


def _clean_text(value: Any) -> str:
    if value is None:
        return ""
    text = str(value)
    text = text.replace("\r", " ").replace("\n", " ")
    text = text.replace("Ã", " ").replace("â", " ").replace("|", " ")
    text = re.sub(r"\s+", " ", text).strip()
    return text


def _shorten_text(value: Any, max_len: int = 400) -> str:
    text = _clean_text(value)
    if len(text) <= max_len:
        return text
    return text[:max_len] + "..."


def get_user_and_health(
    db: Session,
    user_email: str,
) -> Tuple[UserDetails, UserHealthDetails]:
    user = db.query(UserDetails).filter(UserDetails.email == user_email).first()
    if not user:
        raise ValueError("User not found.")

    health = (
        db.query(UserHealthDetails)
        .filter(UserHealthDetails.user_id == user.id)
        .first()
    )

    if not health:
        raise ValueError("PROFILE_INCOMPLETE:age,gender,height_cm,weight_kg,bmr")

    return user, health


def get_missing_profile_fields(health: UserHealthDetails) -> List[str]:
    missing_fields = []

    if health.age is None:
        missing_fields.append("age")
    if health.gender is None or str(health.gender).strip() == "":
        missing_fields.append("gender")
    if health.height_cm is None:
        missing_fields.append("height_cm")
    if health.weight_kg is None:
        missing_fields.append("weight_kg")
    if health.bmr is None:
        missing_fields.append("bmr")

    return missing_fields


def _build_ai_prompt(recipe: Dict[str, Any], health: UserHealthDetails) -> str:
    user_profile = {
        "age": health.age,
        "gender": str(health.gender) if health.gender is not None else None,
        "height_cm": health.height_cm,
        "weight_kg": health.weight_kg,
        "bmr": health.bmr,
        "diabetes": bool(health.diabetes),
        "high_blood_pressure": bool(health.high_blood_pressure),
        "cholesterol": bool(health.cholesterol),
        "kidney_issues": bool(health.kidney_issues),
    }

    recipe_text = {
        "recipe_title": _clean_text(recipe.get("recipe_title")),
        "description": _shorten_text(recipe.get("description"), 300),
        "ingredients": _shorten_text(recipe.get("ingredients"), 450),
        "instructions": _shorten_text(recipe.get("instructions"), 350),
        "cuisine": _clean_text(recipe.get("cuisine")),
        "diet": _clean_text(recipe.get("diet")),
        "prep_time": _clean_text(recipe.get("prep_time")),
        "cook_time": _clean_text(recipe.get("cook_time")),
        "record_health": _clean_text(recipe.get("record_health")),
    }

    return f"""
You are an AI recipe suitability assistant for a food app.

Analyze the recipe and the user's health profile.

Recipe:
Title: {recipe_text["recipe_title"]}
Description: {recipe_text["description"]}
Ingredients: {recipe_text["ingredients"]}
Instructions: {recipe_text["instructions"]}
Cuisine: {recipe_text["cuisine"]}
Diet: {recipe_text["diet"]}
Prep Time: {recipe_text["prep_time"]}
Cook Time: {recipe_text["cook_time"]}
Record Health: {recipe_text["record_health"]}

User Health Profile:
Age: {user_profile["age"]}
Gender: {user_profile["gender"]}
Height: {user_profile["height_cm"]}
Weight: {user_profile["weight_kg"]}
BMR: {user_profile["bmr"]}
Diabetes: {user_profile["diabetes"]}
High Blood Pressure: {user_profile["high_blood_pressure"]}
Cholesterol: {user_profile["cholesterol"]}
Kidney Issues: {user_profile["kidney_issues"]}

Preferred format:
ABOUT_RECIPE:
Write 5 to 6 short lines summarizing this recipe.

SUITABLE_FOR_YOU:
Write 5 to 6 short lines explaining whether this recipe is suitable for this user.
You must consider the user's health details.

Important:
- Plain text only.
- Do not use JSON.
- Do not use markdown code blocks.
- Be practical and clear.
- Do not claim medical certainty.
- If you do not use the exact headings, still write the recipe summary first and the user suitability part second.
""".strip()


def _extract_section(text: str, start_label: str, end_label: str | None = None) -> str:
    if end_label:
        pattern = rf"{re.escape(start_label)}\s*(.*?){re.escape(end_label)}"
    else:
        pattern = rf"{re.escape(start_label)}\s*(.*)$"

    match = re.search(pattern, text, flags=re.DOTALL | re.IGNORECASE)
    if not match:
        return ""

    return match.group(1).strip()


def _split_text_fallback(text: str) -> Tuple[str, str]:
    cleaned = text.strip()

    # remove obvious heading markers if present in varied form
    cleaned = re.sub(r"(?i)\babout[_ ]?recipe\s*:?", "ABOUT_RECIPE:", cleaned)
    cleaned = re.sub(r"(?i)\bsuitable[_ ]?for[_ ]?you\s*:?", "SUITABLE_FOR_YOU:", cleaned)

    # normal extraction after normalization
    about_recipe = _extract_section(cleaned, "ABOUT_RECIPE:", "SUITABLE_FOR_YOU:")
    suitable_for_you = _extract_section(cleaned, "SUITABLE_FOR_YOU:", None)

    if about_recipe and suitable_for_you:
        return about_recipe, suitable_for_you

    # paragraph fallback
    parts = [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]
    if len(parts) >= 2:
        return parts[0], "\n\n".join(parts[1:])

    # sentence fallback
    sentences = re.split(r"(?<=[.!?])\s+", cleaned)
    sentences = [s.strip() for s in sentences if s.strip()]

    if len(sentences) >= 4:
        mid = max(2, len(sentences) // 2)
        about_recipe = " ".join(sentences[:mid]).strip()
        suitable_for_you = " ".join(sentences[mid:]).strip()
        return about_recipe, suitable_for_you

    # final fallback: use whole text as both or split by size
    if len(cleaned) > 200:
        mid = len(cleaned) // 2
        split_at = cleaned.find(". ", mid)
        if split_at == -1:
            split_at = mid
        else:
            split_at += 1
        return cleaned[:split_at].strip(), cleaned[split_at:].strip()

    return cleaned, cleaned


def _call_gemini(recipe: Dict[str, Any], health: UserHealthDetails) -> Dict[str, Any]:
    if not GEMINI_API_KEY:
        raise RuntimeError("GEMINI_API_KEY not found in environment.")

    prompt = _build_ai_prompt(recipe, health)

    payload = {
        "contents": [
            {
                "parts": [{"text": prompt}]
            }
        ],
        "generationConfig": {
            "temperature": 0.4,
            "maxOutputTokens": 900,
        }
    }

    print("Calling Gemini API...")
    print("Gemini URL:", GEMINI_URL)

    response = requests.post(
        f"{GEMINI_URL}?key={GEMINI_API_KEY}",
        headers={"Content-Type": "application/json"},
        json=payload,
        timeout=60,
    )

    print("Gemini status code:", response.status_code)
    print("Gemini raw response:", response.text[:1800])

    if response.status_code != 200:
        raise RuntimeError(
            f"Gemini API failed with status {response.status_code}: {response.text}"
        )

    data = response.json()

    candidates = data.get("candidates", [])
    if not candidates:
        raise RuntimeError("Gemini returned no candidates.")

    parts = candidates[0].get("content", {}).get("parts", [])
    if not parts:
        raise RuntimeError("Gemini returned no content parts.")

    text = parts[0].get("text", "").strip()
    if not text:
        raise RuntimeError("Gemini returned empty text.")

    print("Gemini generated text:")
    print(text)

    about_recipe = _extract_section(text, "ABOUT_RECIPE:", "SUITABLE_FOR_YOU:")
    suitable_for_you = _extract_section(text, "SUITABLE_FOR_YOU:", None)

    if not about_recipe or not suitable_for_you:
        about_recipe_fallback, suitable_for_you_fallback = _split_text_fallback(text)

        if not about_recipe:
            about_recipe = about_recipe_fallback
        if not suitable_for_you:
            suitable_for_you = suitable_for_you_fallback

    if not about_recipe:
        raise RuntimeError("Gemini output missing About Recipe content.")

    if not suitable_for_you:
        raise RuntimeError("Gemini output missing Suitable for You content.")

    return {
        "about_recipe": about_recipe.strip(),
        "suitable_for_you": suitable_for_you.strip(),
    }


def generate_ai_feedback(
    db: Session,
    recipe_payload: Dict[str, Any],
    user_email: str,
) -> Dict[str, Any]:
    _, health = get_user_and_health(db, user_email)

    missing_fields = get_missing_profile_fields(health)
    if missing_fields:
        raise ValueError(f"PROFILE_INCOMPLETE:{','.join(missing_fields)}")

    recipe = {
        "recipe_id": recipe_payload.get("recipe_id"),
        "recipe_title": _clean_text(recipe_payload.get("recipe_title")),
        "description": _clean_text(recipe_payload.get("description")),
        "ingredients": _clean_text(recipe_payload.get("ingredients")),
        "instructions": _clean_text(recipe_payload.get("instructions")),
        "cuisine": _clean_text(recipe_payload.get("cuisine")),
        "diet": _clean_text(recipe_payload.get("diet")),
        "prep_time": _clean_text(recipe_payload.get("prep_time")),
        "cook_time": _clean_text(recipe_payload.get("cook_time")),
        "record_health": _clean_text(recipe_payload.get("record_health")),
        "rating": recipe_payload.get("rating"),
    }

    return _call_gemini(recipe, health)