from sqlalchemy.orm import Session
from firebase_admin import auth

from app.models.user_model import UserDetails


def delete_user_account(db: Session, email: str):
    try:
        # 1) Find user in MySQL
        user = db.query(UserDetails).filter(UserDetails.email == email).first()

        if not user:
            return {"message": "User not found in MySQL, Firebase delete checked"}

        # 2) Delete from userdetails
        # saved_recipes and chat_sessions will auto delete because of ON DELETE CASCADE
        db.delete(user)
        db.commit()

        # 3) Delete from Firebase Authentication using email
        try:
            firebase_user = auth.get_user_by_email(email)
            auth.delete_user(firebase_user.uid)
        except auth.UserNotFoundError:
            # User might already be missing in Firebase, ignore safely
            pass

        return {"message": "Account deleted successfully"}

    except Exception:
        db.rollback()
        raise