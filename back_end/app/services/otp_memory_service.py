import random
import threading
from datetime import datetime, timedelta

otp_store = {}
otp_lock = threading.Lock()


def generate_otp() -> str:
    return str(random.randint(100000, 999999))


# =========================================================
# SIGNUP OTP METHODS
# =========================================================
def save_signup_otp(email: str, name: str, password: str):
    otp = generate_otp()
    expires_at = datetime.utcnow() + timedelta(minutes=5)

    with otp_lock:
        otp_store[email.lower()] = {
            "type": "signup",
            "otp": otp,
            "expires_at": expires_at,
            "name": name,
            "password": password,
        }

    return otp


def resend_signup_otp(email: str):
    email = email.lower()

    with otp_lock:
        if email not in otp_store:
            return None

        if otp_store[email].get("type") != "signup":
            return None

        otp = generate_otp()
        expires_at = datetime.utcnow() + timedelta(minutes=5)

        otp_store[email]["otp"] = otp
        otp_store[email]["expires_at"] = expires_at

        return otp


def verify_signup_otp(email: str, otp_code: str):
    email = email.lower()

    with otp_lock:
        record = otp_store.get(email)

        if not record:
            return {"success": False, "message": "OTP not found"}

        if record.get("type") != "signup":
            return {"success": False, "message": "Invalid OTP type"}

        if datetime.utcnow() > record["expires_at"]:
            del otp_store[email]
            return {"success": False, "message": "OTP expired"}

        if record["otp"] != otp_code:
            return {"success": False, "message": "Invalid OTP"}

        data = {
            "name": record["name"],
            "password": record["password"],
        }

        del otp_store[email]
        return {"success": True, "data": data}


# =========================================================
# FORGOT PASSWORD OTP METHODS
# =========================================================
def save_reset_password_otp(email: str):
    otp = generate_otp()
    expires_at = datetime.utcnow() + timedelta(minutes=5)

    with otp_lock:
        otp_store[email.lower()] = {
            "type": "reset_password",
            "otp": otp,
            "expires_at": expires_at,
        }

    return otp


def resend_reset_password_otp(email: str):
    email = email.lower()

    with otp_lock:
        if email not in otp_store:
            return None

        if otp_store[email].get("type") != "reset_password":
            return None

        otp = generate_otp()
        expires_at = datetime.utcnow() + timedelta(minutes=5)

        otp_store[email]["otp"] = otp
        otp_store[email]["expires_at"] = expires_at

        return otp


def verify_reset_password_otp(email: str, otp_code: str):
    email = email.lower()

    with otp_lock:
        record = otp_store.get(email)

        if not record:
            return {"success": False, "message": "OTP not found"}

        if record.get("type") != "reset_password":
            return {"success": False, "message": "Invalid OTP type"}

        if datetime.utcnow() > record["expires_at"]:
            del otp_store[email]
            return {"success": False, "message": "OTP expired"}

        if record["otp"] != otp_code:
            return {"success": False, "message": "Invalid OTP"}

        return {"success": True, "message": "OTP verified successfully"}


def clear_otp(email: str):
    with otp_lock:
        otp_store.pop(email.lower(), None)