import os
import smtplib
from email.mime.text import MIMEText
from dotenv import load_dotenv

load_dotenv()

SMTP_HOST = os.getenv("SMTP_HOST")
SMTP_PORT = int(os.getenv("SMTP_PORT", 587))
SMTP_USER = os.getenv("SMTP_USER")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
FROM_EMAIL = os.getenv("FROM_EMAIL")


def send_otp_email(to_email: str, otp_code: str, purpose: str = "signup"):
    if purpose == "reset_password":
        subject = "CookItNow Password Reset Code"
        body = (
            f"Your password reset code is: {otp_code}\n\n"
            f"This code expires in 5 minutes."
        )
    else:
        subject = "CookItNow Email Verification Code"
        body = (
            f"Your verification code is: {otp_code}\n\n"
            f"This code expires in 5 minutes."
        )

    msg = MIMEText(body)
    msg["Subject"] = subject
    msg["From"] = FROM_EMAIL
    msg["To"] = to_email

    try:
        server = smtplib.SMTP(SMTP_HOST, SMTP_PORT)
        server.starttls()
        server.login(SMTP_USER, SMTP_PASSWORD)
        server.sendmail(FROM_EMAIL, [to_email], msg.as_string())
        server.quit()
    except Exception as e:
        raise Exception(f"Failed to send OTP email: {str(e)}")