import json
import re
from pathlib import Path

import spacy
from rapidfuzz import process, fuzz

# =========================
# MACHINE LEARNING IMPORTS
# =========================
# TF-IDF is used to convert text into numeric vectors
from sklearn.feature_extraction.text import TfidfVectorizer

# Logistic Regression is the ML classification algorithm
from sklearn.linear_model import LogisticRegression


BASE_DIR = Path(__file__).resolve().parent

# spaCy NLP model
nlp = spacy.load("en_core_web_sm")

INTENTS_FILE = BASE_DIR / "intents.json"

with open(INTENTS_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)

# Training texts and labels
texts = [item["text"] for item in data]
labels = [item["intent"] for item in data]


# ==========================================
# TOKEN NORMALIZATION (Text Cleaning Rules)
# ==========================================
TOKEN_NORMALIZATION_MAP = {
    "u": "you",
    "ur": "your",
    "r": "are",
    "hw": "how",
    "hiw": "how",
    "wht": "what",
    "wat": "what",
    "plz": "please",
    "pls": "please",
    "thx": "thanks",
    "thanx": "thanks",
    "tnx": "thanks",
    "helo": "hello",
    "helloo": "hello",
    "shw": "show",
    "mor": "more",
    "receipe": "recipe",
    "reciepe": "recipe",
    "vegitarian": "vegetarian",
    "vegeterian": "vegetarian",
    "pic": "picture",
    "img": "image",
}


# Important stopwords to keep
KEEP_WORDS = {
    "show", "more", "another", "next", "one",
    "recipe", "recipes", "veg", "vegetarian",
    "image", "photo", "picture", "calories",
    "thanks", "thank", "bye", "hello", "hi",
    "help", "name", "how", "are", "you", "what",
    "can", "do", "who", "yes", "no", "not", "now",
    "stop", "cancel", "okay", "ok", "good", "fine",
    "feel", "feeling", "today", "doing", "going"
}


# ==========================================
# TEXT NORMALIZATION
# ==========================================
def normalize_text(text: str) -> str:

    # Convert to lowercase
    text = text.strip().lower()

    # Remove special characters
    text = re.sub(r"[^a-z0-9\s]", " ", text)

    # Remove extra spaces
    text = re.sub(r"\s+", " ", text).strip()

    if not text:
        return ""

    fixed_tokens = []

    # Replace shortcut words with proper words
    for token in text.split():
        fixed = TOKEN_NORMALIZATION_MAP.get(token, token)
        fixed_tokens.extend(fixed.split())

    return " ".join(fixed_tokens)


# ==========================================
# DIRECT INTENT LOOKUP STORAGE
# ==========================================
INTENT_LOOKUP = {}
INTENT_TEXTS = []

for item in data:

    # Normalize every training sentence
    key = normalize_text(item["text"])

    if key:
        INTENT_LOOKUP[key] = item["intent"]
        INTENT_TEXTS.append(key)

INTENT_TEXTS = sorted(set(INTENT_TEXTS))


# ==========================================
# COLLECT TRAINING WORDS
# Used for spell correction
# ==========================================
training_words = set()

for text in texts:
    for word in re.findall(r"[a-zA-Z]+", normalize_text(text)):
        training_words.add(word)


# ==========================================
# RULE-BASED INTENT DETECTION
# ==========================================
def rule_based_intent(text: str) -> str | None:

    text = normalize_text(text)

    greeting_words = {
        "hi",
        "hello",
        "hey",
        "good morning",
        "good evening",
        "good afternoon"
    }

    if text in greeting_words:
        return "greeting"

    if re.search(r"\bhow\b.*\byou\b", text):
        return "how_are_you"

    if re.search(r"\bare\b.*\byou\b.*\b(good|fine|okay|ok)\b", text):
        return "how_are_you"

    if re.search(r"\bhow\b.*\b(feel|feeling|doing|going)\b", text):
        return "how_are_you"

    if re.search(r"\b(your name|who are you|what are you called|tell me your name)\b", text):
        return "bot_name"

    if re.search(r"\b(what can you do|how can you help|features|how do you work)\b", text):
        return "bot_capabilities"

    if re.search(r"\b(help|guide|assist|support)\b", text):
        return "help_request"

    if re.search(r"\b(calorie|calories|nutrition|energy)\b", text):
        return "calories_request"

    if re.search(r"\b(image|photo|picture|dish image|recipe image)\b", text):
        return "image_request"

    if re.search(r"\b(show more|another|next recipe|more options|one more|give more)\b", text):
        return "show_another"

    if re.search(r"\b(vegetarian|veg)\b", text):
        return "filter_veg"

    if re.search(r"\b(bye|goodbye|see you|exit)\b", text):
        return "goodbye"

    if re.search(r"\b(thanks|thank you|many thanks)\b", text):
        return "thanks"

    if re.search(r"\b(yes|yeah|ok|okay|sure|alright)\b", text):
        return "affirmative"

    if re.search(r"\b(no|not now|cancel|stop|no thanks)\b", text):
        return "negative"

    return None


# ==========================================
# NLP PREPROCESSING
# ==========================================
def preprocess(text: str) -> str:

    # Normalize text first
    text = normalize_text(text)

    # spaCy NLP processing
    doc = nlp(text)

    tokens = []

    for token in doc:

        # Convert words to base form
        # Example:
        # cooking -> cook
        # recipes -> recipe
        lemma = token.lemma_.strip().lower()

        if not lemma:
            continue

        # Remove punctuation and spaces
        if token.is_punct or token.is_space:
            continue

        # Remove stopwords except important words
        if token.is_stop and lemma not in KEEP_WORDS:
            continue

        tokens.append(lemma)

    return " ".join(tokens)


# ==========================================
# PREPROCESS ALL TRAINING DATA
# ==========================================
processed_texts = [preprocess(text) for text in texts]


# =====================================================
# MACHINE LEARNING PART STARTS HERE
# =====================================================

# ==========================================
# TF-IDF VECTORIZER
# ==========================================
# This converts text into numerical vectors
#
# Example:
# "show recipe" ->
# [0.23, 0.87, 0.12, ...]
#
# Machine learning models cannot understand text directly.
# Therefore TF-IDF converts words into numbers.
# ==========================================
vectorizer = TfidfVectorizer(

    # Use single words, 2-word combinations, 3-word combinations
    ngram_range=(1, 3),

    lowercase=True,

    analyzer="word",

    # Maximum vocabulary size
    max_features=7000,

    min_df=1,

    # Improves weighting
    sublinear_tf=True
)


# ==========================================
# TEXT -> NUMERIC CONVERSION
# ==========================================
# THIS IS THE MAIN PLACE
# where words become numbers
#
# fit_transform():
# 1. Learns vocabulary
# 2. Calculates TF-IDF scores
# 3. Creates numerical matrix
# ==========================================
X = vectorizer.fit_transform(processed_texts)


# ==========================================
# LOGISTIC REGRESSION MODEL
# ==========================================
# This is the main ML classification algorithm
#
# It learns patterns between:
# Input text vectors -> intents
#
# Example:
# "show recipe" -> recipe_request
# ==========================================
model = LogisticRegression(

    # Maximum training iterations
    max_iter=5000,

    # Handles imbalanced classes
    class_weight="balanced",

    # Regularization strength
    C=2.0
)


# ==========================================
# MODEL TRAINING
# ==========================================
# THIS IS THE MAIN MACHINE LEARNING TRAINING STEP
#
# Model learns:
# X      -> numeric text vectors
# labels -> correct intents
#
# Example:
# [0.12,0.44,0.88] -> greeting
# ==========================================
model.fit(X, labels)


# ==========================================
# DIRECT INTENT MATCHING
# ==========================================
def get_direct_intent(text: str) -> str | None:

    normalized = normalize_text(text)

    return INTENT_LOOKUP.get(normalized)


# ==========================================
# FUZZY MATCHING
# Handles spelling mistakes
# ==========================================
def get_fuzzy_intent(text: str, min_score: int = 88) -> str | None:

    normalized = normalize_text(text)

    if not normalized:
        return None

    # Find closest matching sentence
    match = process.extractOne(
        normalized,
        INTENT_TEXTS,
        scorer=fuzz.WRatio
    )

    if match and match[1] >= min_score:

        matched_text = match[0]

        return INTENT_LOOKUP.get(matched_text)

    return None


# ==========================================
# FINAL INTENT PREDICTION
# ==========================================
def predict_intent(text: str) -> str:

    # Step 1 - Direct matching
    direct_intent = get_direct_intent(text)

    if direct_intent:
        return direct_intent

    # Step 2 - Fuzzy matching
    fuzzy_intent = get_fuzzy_intent(text)

    if fuzzy_intent:
        return fuzzy_intent

    # Step 3 - Rule-based system
    rule_intent = rule_based_intent(text)

    if rule_intent:
        return rule_intent

    # Step 4 - NLP preprocessing
    processed = preprocess(text)

    if not processed.strip():
        return "unknown"

    # ==========================================
    # ML PREDICTION SECTION
    # ==========================================

    # Convert user text into numeric vector
    X_test = vectorizer.transform([processed])

    # Predict probability for every intent
    probabilities = model.predict_proba(X_test)[0]

    # Get highest probability intent
    best_index = probabilities.argmax()

    # Highest confidence score
    best_score = probabilities[best_index]

    # Predicted intent label
    best_label = model.classes_[best_index]

    # Confidence threshold checking
    if best_score < 0.30:
        return "unknown"

    # Final predicted intent
    return best_label


# ==========================================
# WORD NORMALIZATION
# ==========================================
def normalize_word(word: str) -> str:

    word = word.lower().strip()

    word = re.sub(r"[^a-zA-Z]", "", word)

    custom_map = {
        "eggs": "egg",
        "tomatoes": "tomato",
        "potatoes": "potato",
        "chilies": "chili",
        "veggies": "vegetable",

        "beaf": "beef",
        "beeef": "beef",
        "buter": "butter",
        "buttr": "butter",
        "mothon": "mutton",
        "motton": "mutton",
        "muttan": "mutton",
        "chiken": "chicken",
        "tomoto": "tomato",
        "onnion": "onion",
        "garlick": "garlic",
        "patato": "potato",
    }

    if word in custom_map:
        return custom_map[word]

    # Convert plural -> singular
    if word.endswith("s") and len(word) > 3:
        word = word[:-1]

    return word


# ==========================================
# SPELL CORRECTION
# ==========================================
def correct_word(word: str, candidates: list[str], min_score: int = 80) -> str:

    word = normalize_word(word)

    if not word or not candidates:
        return word

    # Fuzzy matching for spelling correction
    match = process.extractOne(
        word,
        candidates,
        scorer=fuzz.ratio
    )

    if match and match[1] >= min_score:
        return match[0]

    return word


# ==========================================
# USER TEXT CORRECTION
# ==========================================
def correct_user_text(text: str) -> str:

    raw_words = re.findall(r"[a-zA-Z]+", normalize_text(text))

    candidates = list(training_words)

    corrected = []

    for word in raw_words:

        if len(word) <= 2:
            corrected.append(
                TOKEN_NORMALIZATION_MAP.get(word, word)
            )

        else:
            corrected.append(
                correct_word(word, candidates, min_score=80)
            )

    return " ".join(corrected)


# ==========================================
# GET DATABASE INGREDIENT WORDS
# ==========================================
def get_db_ingredient_words(
    db_ingredients: list[str]
) -> list[str]:

    ingredient_words = set()

    for item in db_ingredients:

        if not item:
            continue

        cleaned = item.lower()

        cleaned = re.sub(r"[\[\]\(\)]", " ", cleaned)

        cleaned = re.sub(r"[,;/|&\-]", " ", cleaned)

        cleaned = re.sub(r"\s+", " ", cleaned).strip()

        for word in cleaned.split():

            word = normalize_word(word)

            if word and len(word) > 2:
                ingredient_words.add(word)

    return sorted(list(ingredient_words))


# ==========================================
# INGREDIENT EXTRACTION
# ==========================================
def extract_ingredients(
    text: str,
    db_ingredients: list[str]
) -> tuple[list[str], list[dict], list[str]]:

    stop_words = {
        "i", "have", "want", "need", "cook", "make",
        "recipe", "recipes", "show", "give", "me",
        "please", "can", "you", "my", "a", "an",
        "the", "to", "for", "of", "using", "use",
        "today", "food", "dish", "something",
        "also", "with", "and", "or", "only",
        "some", "how", "are", "feel", "feeling",
        "good", "fine", "okay", "ok", "hello",
        "hi", "hey", "thanks", "thank", "bye"
    }

    # Get ingredient vocabulary from DB
    db_words = get_db_ingredient_words(db_ingredients)

    # Extract user words
    user_words = re.findall(r"[a-zA-Z]+", text.lower())

    matched = []
    corrections = []
    unknown_words = []

    for original_word in user_words:

        normalized_original = normalize_word(original_word)

        if normalized_original in stop_words:
            continue

        # Correct spelling using fuzzy matching
        corrected_word = correct_word(
            normalized_original,
            db_words,
            min_score=78
        )

        # Store corrections
        if corrected_word != normalized_original:

            corrections.append({
                "original": original_word,
                "corrected": corrected_word
            })

        # Ingredient found
        if corrected_word in db_words:

            if corrected_word not in matched:
                matched.append(corrected_word)

        # Unknown ingredient
        else:

            if corrected_word and corrected_word not in unknown_words:
                unknown_words.append(corrected_word)

    return matched, corrections, unknown_words