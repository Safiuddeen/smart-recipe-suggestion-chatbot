from fastapi import FastAPI
from app.database import Base, engine
import app.firebase_admin_setup

# ✅ ADD THIS (IMPORTANT FOR GEMINI KEY)
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()


from app.routers.auth_routes import router as auth_router
from app.routers.profile_routes import router as profile_router
from app.routers.healthprofile_routes import router as health_router
from app.routers.nlp_routes import router as nlp_routes
from app.routers.saved_recipe_routes import router as saved_recipe_router
from app.routers.account_routes import router as account_router
from app.routers.chat_session_routes import router as chat_session_router
from app.routers.recipe_search_routes import router as recipe_search_router
from app.routers.ai_feedback_routes import router as ai_feedback_router

app = FastAPI(title="Cook It Now Backend")

# Create tables
Base.metadata.create_all(bind=engine)

# Routers
app.include_router(auth_router)
app.include_router(profile_router)
app.include_router(health_router)
app.include_router(nlp_routes)
app.include_router(saved_recipe_router)
app.include_router(account_router)
app.include_router(chat_session_router)
app.include_router(recipe_search_router)
app.include_router(ai_feedback_router)

@app.get("/")
def root():
    return {"message": "Cook It Now backend is running"}