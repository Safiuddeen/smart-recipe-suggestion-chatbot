from sqlalchemy import Column, Integer, String, TIMESTAMP, ForeignKey, text
from app.database import Base


class SavedRecipe(Base):
    __tablename__ = "saved_recipes"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_email = Column(String(150), ForeignKey("userdetails.email", ondelete="CASCADE"), nullable=False)
    recipe_id = Column(Integer, ForeignKey("recipes.id", ondelete="CASCADE"), nullable=False)
    saved_at = Column(TIMESTAMP, server_default=text("CURRENT_TIMESTAMP"))