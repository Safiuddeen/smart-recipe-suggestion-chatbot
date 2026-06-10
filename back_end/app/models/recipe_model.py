from sqlalchemy import Column, Integer, String, Text, Float
from app.database import Base


class Recipe(Base):
    __tablename__ = "recipes"

    id = Column(Integer, primary_key=True, index=True)
    recipe_title = Column(String(255))
    url = Column(Text)
    record_health = Column(String(50))
    vote_count = Column(Integer)
    rating = Column(Float)
    description = Column(Text)
    cuisine = Column(String(150))
    course = Column(String(150))
    diet = Column(String(150))
    prep_time = Column(String(50))
    cook_time = Column(String(50))
    ingredients = Column(Text)
    instructions = Column(Text)
    author = Column(String(255))
    tags = Column(Text)
    category = Column(String(255))