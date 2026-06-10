from sqlalchemy.orm import Session
from passlib.context import CryptContext
from firebase_admin import auth

from app.models.user_model import UserDetails
from app.models.user_health_details_model import UserHealthDetails

pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")


# ===============================
# HELPERS
# ===============================
def normalize_email(email: str) -> str:
    if not email or not email.strip():
        raise ValueError("Email is required")
    return email.strip().lower()


def normalize_name(name: str, email: str = "") -> str:
    cleaned_name = (name or "").strip()
    if cleaned_name:
        return cleaned_name

    if email and "@" in email:
        return email.split("@")[0].strip()

    return "User"


# ===============================
# GOOGLE LOGIN
# ===============================
def create_or_update_google_user(db: Session, decoded_token: dict):
    email = normalize_email(decoded_token.get("email"))
    name = normalize_name(decoded_token.get("name"), email)

    user = db.query(UserDetails).filter(UserDetails.email == email).first()

    if user:
        user.name = name or user.name
        user.provider = "Google"
        user.password = None
    else:
        user = UserDetails(
            name=name,
            email=email,
            password=None,
            provider="Google",
        )
        db.add(user)

    db.commit()
    db.refresh(user)
    return user


# ===============================
# FIREBASE EMAIL USER CREATE
# ===============================
def create_firebase_email_user(name: str, email: str, password: str):
    normalized_email = normalize_email(email)
    normalized_name = normalize_name(name, normalized_email)

    try:
        firebase_user = auth.get_user_by_email(normalized_email)
        return firebase_user
    except auth.UserNotFoundError:
        firebase_user = auth.create_user(
            email=normalized_email,
            password=password,
            display_name=normalized_name,
            email_verified=False,
            disabled=False,
        )
        return firebase_user


# ===============================
# FIREBASE PASSWORD UPDATE
# ONLY FOR EMAIL PROVIDER USERS
# ===============================
def update_firebase_user_password(email: str, new_password: str):
    normalized_email = normalize_email(email)

    try:
        firebase_user = auth.get_user_by_email(normalized_email)
        updated_user = auth.update_user(
            firebase_user.uid,
            password=new_password,
        )
        return updated_user
    except auth.UserNotFoundError:
        return None
    except Exception:
        return None


# ===============================
# PASSWORD METHODS
# ===============================
def hash_password(password: str) -> str:
    if not password or not password.strip():
        raise ValueError("Password is required")
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    if not hashed_password:
        return False
    return pwd_context.verify(plain_password, hashed_password)


# ===============================
# EMAIL USER CREATE
# ===============================
def create_email_user(db: Session, name: str, email: str, password: str):
    normalized_email = normalize_email(email)
    normalized_name = normalize_name(name, normalized_email)

    existing_user = db.query(UserDetails).filter(
        UserDetails.email == normalized_email
    ).first()

    if existing_user:
        raise ValueError("User with this email already exists")

    user = UserDetails(
        name=normalized_name,
        email=normalized_email,
        password=hash_password(password),
        provider="Email",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


# ===============================
# GET USER BY EMAIL
# ===============================
def get_user_by_email(db: Session, email: str):
    normalized_email = normalize_email(email)
    return db.query(UserDetails).filter(
        UserDetails.email == normalized_email
    ).first()


# ===============================
# UPDATE PASSWORD
# ONLY FOR EMAIL PROVIDER USERS
# ===============================
def update_user_password(db: Session, email: str, new_password: str):
    normalized_email = normalize_email(email)

    user = db.query(UserDetails).filter(
        UserDetails.email == normalized_email
    ).first()

    if not user:
        return None

    if user.provider != "Email":
        return None

    user.password = hash_password(new_password)
    db.commit()
    db.refresh(user)
    return user


# ===============================
# UPDATE BASIC PROFILE
# ===============================
def update_user_profile(db: Session, email: str, name: str, contact_number: str):
    normalized_email = normalize_email(email)

    user = db.query(UserDetails).filter(
        UserDetails.email == normalized_email
    ).first()

    if not user:
        return None

    user.name = normalize_name(name, normalized_email)
    user.contact_number = contact_number.strip() if contact_number else ""

    db.commit()
    db.refresh(user)
    return user


# ===============================
# CALCULATE BMR
# ===============================
def calculate_bmr(age: int, gender: str, height_cm: float, weight_kg: float) -> float:
    gender_lower = (gender or "").strip().lower()

    if gender_lower == "male":
        return round((10 * weight_kg) + (6.25 * height_cm) - (5 * age) + 5, 2)
    elif gender_lower == "female":
        return round((10 * weight_kg) + (6.25 * height_cm) - (5 * age) - 161, 2)
    else:
        return round((10 * weight_kg) + (6.25 * height_cm) - (5 * age) - 78, 2)


# ===============================
# GET HEALTH PROFILE
# ===============================
def get_health_profile(db: Session, email: str):
    normalized_email = normalize_email(email)

    user = db.query(UserDetails).filter(
        UserDetails.email == normalized_email
    ).first()

    if not user:
        return None

    health = db.query(UserHealthDetails).filter(
        UserHealthDetails.user_id == user.id
    ).first()

    if not health:
        return {
            "email": user.email,
            "age": None,
            "gender": None,
            "height_cm": None,
            "weight_kg": None,
            "bmr": None,
            "diabetes": False,
            "high_blood_pressure": False,
            "cholesterol": False,
            "kidney_issues": False,
            "is_profile_completed": False,
        }

    is_profile_completed = (
        health.age is not None
        and health.gender is not None
        and health.height_cm is not None
        and health.weight_kg is not None
    )

    return {
        "email": user.email,
        "age": health.age,
        "gender": health.gender,
        "height_cm": health.height_cm,
        "weight_kg": health.weight_kg,
        "bmr": health.bmr,
        "diabetes": bool(health.diabetes) if health.diabetes is not None else False,
        "high_blood_pressure": bool(health.high_blood_pressure) if health.high_blood_pressure is not None else False,
        "cholesterol": bool(health.cholesterol) if health.cholesterol is not None else False,
        "kidney_issues": bool(health.kidney_issues) if health.kidney_issues is not None else False,
        "is_profile_completed": is_profile_completed,
    }


# ===============================
# UPDATE HEALTH PROFILE
# ===============================
def update_health_profile(
    db: Session,
    email: str,
    age: int,
    gender: str,
    height_cm: float,
    weight_kg: float,
    diabetes: bool,
    high_blood_pressure: bool,
    cholesterol: bool,
    kidney_issues: bool,
):
    normalized_email = normalize_email(email)

    user = db.query(UserDetails).filter(
        UserDetails.email == normalized_email
    ).first()

    if not user:
        return None

    bmr = calculate_bmr(age, gender, height_cm, weight_kg)

    health = db.query(UserHealthDetails).filter(
        UserHealthDetails.user_id == user.id
    ).first()

    if health:
        health.age = age
        health.gender = gender
        health.height_cm = height_cm
        health.weight_kg = weight_kg
        health.bmr = bmr
        health.diabetes = diabetes
        health.high_blood_pressure = high_blood_pressure
        health.cholesterol = cholesterol
        health.kidney_issues = kidney_issues
    else:
        health = UserHealthDetails(
            user_id=user.id,
            age=age,
            gender=gender,
            height_cm=height_cm,
            weight_kg=weight_kg,
            bmr=bmr,
            diabetes=diabetes,
            high_blood_pressure=high_blood_pressure,
            cholesterol=cholesterol,
            kidney_issues=kidney_issues,
        )
        db.add(health)

    db.commit()
    db.refresh(health)

    return {
        "email": user.email,
        "age": health.age,
        "gender": health.gender,
        "height_cm": health.height_cm,
        "weight_kg": health.weight_kg,
        "bmr": health.bmr,
        "diabetes": bool(health.diabetes),
        "high_blood_pressure": bool(health.high_blood_pressure),
        "cholesterol": bool(health.cholesterol),
        "kidney_issues": bool(health.kidney_issues),
        "is_profile_completed": True,
    }