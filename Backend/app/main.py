from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import auth_routes, product_routes
from app.database import engine, Base
from app.routes import cart_routes
from app.models.favorite import Favorite
from app.routes.favorite_routes import router as favorite_router
from app.routes.checkout_routes import router as checkout_router
from fastapi.staticfiles import StaticFiles
import os

app = FastAPI()

# 🔥 CORS BIEN CONFIGURADO PARA FLUTTER WEB
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "*",  # puedes dejarlo así para dev
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)

app.include_router(auth_routes.router)
app.include_router(product_routes.router)
app.include_router(cart_routes.router)
app.include_router(favorite_router)
app.include_router(checkout_router)

app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/")
def root():
    return {"message": "API SmartTech funcionando"}