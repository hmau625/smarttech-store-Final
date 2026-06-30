from dotenv import load_dotenv
load_dotenv() 
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os
from app.routes import auth_routes, product_routes
from app.routes import cart_routes
from app.routes.favorite_routes import router as favorite_router
from app.routes.checkout_routes import router as checkout_router
from app.routes.admin_routes import router as admin_router
from app.routes.order_routes import router as order_router
from app.routes.review_routes import router as review_router
from app.routes.ai_routes import router as ai_router
from app.database import engine, Base
from app.models.favorite import Favorite
from app.models.review import Review

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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
app.include_router(admin_router)
app.include_router(order_router)
app.include_router(review_router)
app.include_router(ai_router)

app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/")
def root():
    return {"message": "API SmartTech funcionando"}