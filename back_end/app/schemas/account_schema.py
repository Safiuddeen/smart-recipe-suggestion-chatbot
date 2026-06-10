from pydantic import BaseModel, EmailStr


class DeleteAccountRequest(BaseModel):
    email: EmailStr