import pandas as pd
import csv
import re
from pathlib import Path

INPUT_FILE = "food_recipes2.csv"
REPAIRED_FILE = "food_recipes2_repaired.csv"
CLEANED_FILE = "food_recipes2_cleaned.csv"
SAMPLE_FILE = "food_recipes2_sample_150.csv"

EXPECTED_COLUMNS = [
    "recipe_title","url","record_health","vote_count","rating","description",
    "cuisine","course","diet","prep_time","cook_time","ingredients",
    "instructions","author","tags","category",
]

TEXT_COLUMNS = [
    "recipe_title","url","record_health","description","cuisine","course",
    "diet","prep_time","cook_time","ingredients","instructions",
    "author","tags","category",
]

NUMERIC_INT_COLUMNS = ["vote_count"]
NUMERIC_FLOAT_COLUMNS = ["rating"]


# =========================
# FIX ENCODING
# =========================
def fix_mojibake(text: str) -> str:
    replacements = {
        "â€™": "'","â€˜": "'","â€œ": '"',"â€": '"',
        "â€“": "-","â€”": "-","â€¦": "...",
        "Â": "","Ã": "","�": "",
    }
    for old, new in replacements.items():
        text = text.replace(old, new)

    text = re.sub(r"[ÃÂ]+", "", text)
    return text


# =========================
# READ FILE SAFELY
# =========================
def read_text_with_fallback(file_path: str) -> str:
    encodings = ["utf-8-sig", "cp1252", "latin1", "utf-8"]

    for enc in encodings:
        try:
            with open(file_path, "r", encoding=enc, errors="replace") as f:
                print(f"[OK] Read with {enc}")
                return f.read()
        except:
            continue

    raise Exception("Cannot read file")


# =========================
# REPAIR CSV STRUCTURE
# =========================
def repair_csv_text(raw_text: str) -> str:
    raw_text = raw_text.replace("\x00", "")
    raw_text = raw_text.replace("\r\n", "\n").replace("\r", "\n")

    repaired = []
    in_quotes = False

    for ch in raw_text:
        if ch == '"':
            in_quotes = not in_quotes

        if ch == "\n" and in_quotes:
            repaired.append(" ")
        else:
            repaired.append(ch)

    return "".join(repaired)


def save_text(path, text):
    with open(path, "w", encoding="utf-8-sig") as f:
        f.write(text)
    print("[OK] Repaired CSV saved")


# =========================
# CLEAN TEXT (IMPORTANT)
# =========================
def clean_text(value, column):
    if pd.isna(value):
        return ""

    text = str(value)

    # Basic cleanup
    text = text.replace("\n", " ").replace("\r", " ").replace("\t", " ")
    text = fix_mojibake(text)

    # 🔥 IMPORTANT FIX (SET 3)
    # Escape quotes properly for CSV
    text = text.replace('"', '""')

    # Remove pipe ONLY for non ingredient/tag
    if column not in ["ingredients", "tags"]:
        text = text.replace("|", " ")

    # Clean spaces
    text = re.sub(r"\s+", " ", text).strip()

    # Keep ingredient/tag format clean
    if column in ["ingredients", "tags"]:
        text = re.sub(r"\s*\|\s*", "|", text)

    return text


# =========================
# LOAD CSV
# =========================
def load_repaired_csv(file_path):
    return pd.read_csv(
        file_path,
        engine="python",
        sep=",",
        quotechar='"',
        on_bad_lines="warn",
        dtype=str,
    )


# =========================
# CLEAN DATAFRAME
# =========================
def clean_dataframe(df):
    df = df[EXPECTED_COLUMNS].copy()

    for col in TEXT_COLUMNS:
        df[col] = df[col].apply(lambda x: clean_text(x, col))

    for col in NUMERIC_INT_COLUMNS:
        df[col] = pd.to_numeric(df[col], errors="coerce").fillna(0).astype(int)

    for col in NUMERIC_FLOAT_COLUMNS:
        df[col] = pd.to_numeric(df[col], errors="coerce").fillna(0.0)

    print(f"[OK] Rows after cleaning: {len(df)}")
    return df


# =========================
# SAVE CSV (MYSQL SAFE)
# =========================
def save_clean_csv(df):
    df.to_csv(
        CLEANED_FILE,
        index=False,
        encoding="utf-8-sig",
        quoting=csv.QUOTE_ALL,
        escapechar="\\",
        lineterminator="\n",
    )

    df.head(150).to_csv(
        SAMPLE_FILE,
        index=False,
        encoding="utf-8-sig",
        quoting=csv.QUOTE_ALL,
        escapechar="\\",
        lineterminator="\n",
    )

    print("[OK] CSV saved for MySQL")


# =========================
# MAIN
# =========================
def main():
    raw = read_text_with_fallback(INPUT_FILE)

    repaired = repair_csv_text(raw)
    save_text(REPAIRED_FILE, repaired)

    df = load_repaired_csv(REPAIRED_FILE)

    df_clean = clean_dataframe(df)

    save_clean_csv(df_clean)

    print("\nDONE")
    print("Use:", CLEANED_FILE)


if __name__ == "__main__":
    main()