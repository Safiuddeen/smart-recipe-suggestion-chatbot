from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr, Field
from firebase_admin import auth

from app.database import SessionLocal
from app.services.user_service import (
    create_or_update_google_user,
    get_user_by_email,
    create_email_user,
    verify_password,
    create_firebase_email_user,
    update_user_password,
    update_firebase_user_password,
)
from app.services.email_sender_service import send_otp_email
from app.services.otp_memory_service import (
    save_signup_otp,
    resend_signup_otp,
    verify_signup_otp,
    save_reset_password_otp,
    resend_reset_password_otp,
    verify_reset_password_otp,
    clear_otp,
)

router = APIRouter(prefix="/auth", tags=["Auth"])


# ===============================
# DB CONNECTION DEPENDENCY
# ===============================
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ===============================
# REQUEST MODELS
# ===============================
class GoogleLoginRequest(BaseModel):
    idToken: str


class EmailSignupRequest(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    email: EmailStr
    password: str = Field(min_length=6, max_length=100)


class ResendOtpRequest(BaseModel):
    email: EmailStr


class VerifyOtpRequest(BaseModel):
    email: EmailStr
    otp_code: str = Field(min_length=6, max_length=6)


class EmailLoginRequest(BaseModel):
    email: EmailStr
    password: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    new_password: str = Field(min_length=6, max_length=100)
    confirm_password: str = Field(min_length=6, max_length=100)


# ===============================
# GOOGLE LOGIN
# ===============================
@router.post("/google-login")
def google_login(data: GoogleLoginRequest, db: Session = Depends(get_db)):
    try:
        id_token = data.idToken

        if not id_token:
            raise HTTPException(status_code=400, detail="idToken is required")

        decoded_token = auth.verify_id_token(id_token)

        email = (decoded_token.get("email") or "").strip().lower()
        if not email:
            raise HTTPException(status_code=400, detail="Email not found in token")

        existing_user = get_user_by_email(db, email)
        is_new_user = existing_user is None

        user = create_or_update_google_user(db, decoded_token)

        return {
            "message": "User saved in MySQL",
            "is_new_user": is_new_user,
            "next_route": "/firstpage" if is_new_user else "/home",
            "email": user.email,
            "name": user.name,
            "provider": user.provider,
            "user": {
                "id": user.id,
                "name": user.name,
                "email": user.email,
                "provider": user.provider,
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ===============================
# EMAIL SIGNUP - REQUEST OTP
# ===============================
@router.post("/email/signup/request-otp")
def request_signup_otp(data: EmailSignupRequest, db: Session = Depends(get_db)):
    email = data.email.strip().lower()

    existing_user = get_user_by_email(db, email)

    if existing_user:
        raise HTTPException(status_code=400, detail="User already exists")

    try:
        auth.get_user_by_email(email)
        raise HTTPException(
            status_code=400,
            detail="This email is already registered in Firebase"
        )
    except auth.UserNotFoundError:
        pass

    otp = save_signup_otp(
        email=email,
        name=data.name.strip(),
        password=data.password
    )

    send_otp_email(email, otp, purpose="signup")

    return {
        "message": "OTP sent successfully",
        "email": email,
        "purpose": "signup"
    }


# ===============================
# EMAIL SIGNUP - RESEND OTP
# ===============================
@router.post("/email/signup/resend-otp")
def resend_otp(data: ResendOtpRequest):
    email = data.email.strip().lower()
    otp = resend_signup_otp(email)

    if otp is None:
        raise HTTPException(
            status_code=400,
            detail="Signup session not found. Please sign up again."
        )

    send_otp_email(email, otp, purpose="signup")

    return {
        "message": "OTP resent successfully",
        "email": email,
        "purpose": "signup"
    }


# ===============================
# EMAIL SIGNUP - VERIFY OTP
# ===============================
@router.post("/email/signup/verify-otp")
def verify_signup_otp_route(data: VerifyOtpRequest, db: Session = Depends(get_db)):
    email = data.email.strip().lower()
    existing_user = get_user_by_email(db, email)

    if existing_user:
        raise HTTPException(status_code=400, detail="User already exists")

    result = verify_signup_otp(email, data.otp_code)

    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])

    name = result["data"]["name"]
    password = result["data"]["password"]

    try:
        firebase_user = create_firebase_email_user(
            name=name,
            email=email,
            password=password
        )

        user = create_email_user(
            db=db,
            name=name,
            email=email,
            password=password
        )

        return {
            "message": "Account created successfully in Firebase and MySQL",
            "is_new_user": True,
            "next_route": "/firstpage",
            "firebase_uid": firebase_user.uid,
            "user": {
                "id": user.id,
                "name": user.name,
                "email": user.email,
                "provider": user.provider,
            }
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Signup failed: {str(e)}")


# ===============================
# EMAIL LOGIN
# ===============================
@router.post("/email/login")
def email_login(data: EmailLoginRequest, db: Session = Depends(get_db)):
    email = data.email.strip().lower()
    user = get_user_by_email(db, email)

    if not user:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    if user.provider != "Email":
        raise HTTPException(
            status_code=400,
            detail="This account is not registered with Email provider"
        )

    if not user.password:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    if not verify_password(data.password, user.password):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    return {
        "message": "Login successful",
        "is_new_user": False,
        "next_route": "/home",
        "user": {
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "provider": user.provider,
        }
    }


# ===============================
# FORGOT PASSWORD - REQUEST OTP
# ONLY EMAIL USERS CAN RESET PASSWORD
# ===============================
@router.post("/forgot-password/request-otp")
def forgot_password_request_otp(data: ForgotPasswordRequest, db: Session = Depends(get_db)):
    email = data.email.strip().lower()
    user = get_user_by_email(db, email)

    if not user:
        raise HTTPException(status_code=404, detail="Email not found")

    if user.provider == "Google":
        raise HTTPException(
            status_code=400,
            detail="Google login users cannot change password here. Please use Google Sign-In."
        )

    if user.provider != "Email":
        raise HTTPException(
            status_code=400,
            detail="Only Email login users can reset password."
        )

    otp = save_reset_password_otp(email)
    send_otp_email(email, otp, purpose="reset_password")

    return {
        "message": "Password reset OTP sent successfully",
        "email": email,
        "purpose": "reset_password"
    }


# ===============================
# FORGOT PASSWORD - RESEND OTP
# ===============================
@router.post("/forgot-password/resend-otp")
def forgot_password_resend_otp(data: ResendOtpRequest):
    email = data.email.strip().lower()
    otp = resend_reset_password_otp(email)

    if otp is None:
        raise HTTPException(
            status_code=400,
            detail="Reset password session not found. Please try again."
        )

    send_otp_email(email, otp, purpose="reset_password")

    return {
        "message": "Password reset OTP resent successfully",
        "email": email,
        "purpose": "reset_password"
    }


# ===============================
# FORGOT PASSWORD - VERIFY OTP
# ===============================
@router.post("/forgot-password/verify-otp")
def forgot_password_verify_otp(data: VerifyOtpRequest):
    email = data.email.strip().lower()
    result = verify_reset_password_otp(email, data.otp_code)

    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])

    return {
        "message": "OTP verified successfully",
        "email": email,
        "purpose": "reset_password",
        "next_route": "/update-password"
    }


# ===============================
# FORGOT PASSWORD - UPDATE PASSWORD
# ONLY EMAIL USERS CAN UPDATE PASSWORD
# ===============================
@router.post("/forgot-password/reset")
def forgot_password_reset(data: ResetPasswordRequest, db: Session = Depends(get_db)):
    email = data.email.strip().lower()

    if data.new_password != data.confirm_password:
        raise HTTPException(status_code=400, detail="Passwords do not match")

    user = get_user_by_email(db, email)

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if user.provider == "Google":
        raise HTTPException(
            status_code=400,
            detail="Google login users cannot change password here. Please use Google Sign-In."
        )

    if user.provider != "Email":
        raise HTTPException(
            status_code=400,
            detail="Only Email login users can update password."
        )

    try:
        updated_user = update_user_password(db, email, data.new_password)

        if not updated_user:
            raise HTTPException(status_code=400, detail="Password update not allowed for this account")

        try:
            update_firebase_user_password(email, data.new_password)
        except Exception:
            pass

        clear_otp(email)

        return {
            "message": "Password updated successfully",
            "next_route": "/loging",
            "user": {
                "id": updated_user.id,
                "name": updated_user.name,
                "email": updated_user.email,
                "provider": updated_user.provider,
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Password update failed: {str(e)}")