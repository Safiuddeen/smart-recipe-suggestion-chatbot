from model import (
    predict_intent,
    extract_ingredients,
    correct_user_text
)

# SAMPLE DATABASE INGREDIENTS
db_ingredients = [
    "rice",
    "egg",
    "milk",
    "tomato",
    "onion",
    "chicken",
    "butter",
    "cheese",
    "potato",
    "garlic",
    "beef",
    "mutton",
    "carrot",
    "oil",
    "salt",
    "pepper"
]

# TEST CASES
test_cases = [

    # GREETING
    {
        "input": "hello",
        "expected_intent": "greeting",
        "expected_ingredients": []
    },
    {
        "input": "helo",
        "expected_intent": "greeting",
        "expected_ingredients": []
    },

    # HOW ARE YOU
    {
        "input": "how are you",
        "expected_intent": "how_are_you",
        "expected_ingredients": []
    },
    {
        "input": "hw r u",
        "expected_intent": "how_are_you",
        "expected_ingredients": []
    },

    # BOT NAME
    {
        "input": "what is your name",
        "expected_intent": "bot_name",
        "expected_ingredients": []
    },

    # HELP
    {
        "input": "help me",
        "expected_intent": "help_request",
        "expected_ingredients": []
    },

    # SHOW MORE
    {
        "input": "show more",
        "expected_intent": "show_another",
        "expected_ingredients": []
    },

    # CALORIES
    {
        "input": "show calories",
        "expected_intent": "calories_request",
        "expected_ingredients": []
    },

    # IMAGE
    {
        "input": "show image",
        "expected_intent": "image_request",
        "expected_ingredients": []
    },

    # VEGETARIAN
    {
        "input": "vegetarian recipes",
        "expected_intent": "filter_veg",
        "expected_ingredients": []
    },

    # THANKS
    {
        "input": "thanks",
        "expected_intent": "thanks",
        "expected_ingredients": []
    },

    # GOODBYE
    {
        "input": "good bay",
        "expected_intent": "goodbye",
        "expected_ingredients": []
    },

    # RECIPE REQUESTS
    {
        "input": "rice egg tomato",
        "expected_intent": "recipe_request",
        "expected_ingredients": ["rice", "egg", "tomato"]
    },

    {
        "input": "i hve milk an rive",
        "expected_intent": "recipe_request",
        "expected_ingredients": ["milk", "rice"]
    },

    {
        "input": "chiken onion",
        "expected_intent": "recipe_request",
        "expected_ingredients": ["chicken", "onion"]
    },

    {
        "input": "beaf curry",
        "expected_intent": "recipe_request",
        "expected_ingredients": ["beef"]
    },

    {
        "input": "tomoto onnion",
        "expected_intent": "recipe_request",
        "expected_ingredients": ["tomato", "onion"]
    },

    {
        "input": "milk butter cheese",
        "expected_intent": "recipe_request",
        "expected_ingredients": ["milk", "butter", "cheese"]
    },

    {
        "input": "potato onion oil",
        "expected_intent": "recipe_request",
        "expected_ingredients": ["potato", "onion", "oil"]
    }
]

total_score = 0

print("\n====================================")
print("SMART RECIPE CHATBOT SYSTEM TEST")
print("====================================")

for i, test in enumerate(test_cases, start=1):

    user_input = test["input"]

    # STEP 1: SPELL CORRECTION
    corrected_text = correct_user_text(user_input)

    # STEP 2: INGREDIENT EXTRACTION
    ingredients, corrections, unknown_words = extract_ingredients(
        corrected_text,
        db_ingredients
    )

    # STEP 3: HYBRID LOGIC
    if ingredients:
        predicted_intent = "recipe_request"
    else:
        predicted_intent = predict_intent(corrected_text)

    # STEP 4: VALIDATION
    intent_ok = (
        predicted_intent ==
        test["expected_intent"]
    )

    ingredients_ok = (
        set(ingredients) ==
        set(test["expected_ingredients"])
    )

    score = 0

    if intent_ok:
        score += 0.5

    if ingredients_ok:
        score += 0.5

    total_score += score

    passed = score == 1

    # OUTPUT
    print(f"\nTest Case {i}")
    print("------------------------------------")
    print("Input:", user_input)
    print("Corrected:", corrected_text)
    print("Predicted Intent:", predicted_intent)
    print("Expected Intent:", test["expected_intent"])
    print("Extracted Ingredients:", ingredients)
    print("Expected Ingredients:", test["expected_ingredients"])
    print("Corrections:", corrections)

    if passed:
        print("Result: PASS")
    else:
        print("Result: FAIL")

# FINAL PERFORMANCE
accuracy = (total_score / len(test_cases)) * 100

print("\n====================================")
print("FULL SYSTEM PERFORMANCE")
print("====================================")
print(f"Total Test Cases : {len(test_cases)}")
print(f"System Accuracy  : {accuracy:.2f}%")
print("====================================")