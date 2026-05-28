from fastapi import APIRouter
from app.services.user_service import create_user, login_user

router = APIRouter()

@router.post("/register")
def register(name: str, email: str, password: str):
    return create_user(name, email, password)

@router.post("/login")
def login(email: str, password: str):
    return login_user(email, password)