from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models.favorite import Favorite
from app.models.product import Product
from app.routes.auth_routes import get_current_user  # 🔥 FIX IMPORT

router = APIRouter(prefix="/favorites", tags=["Favorites"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ❤️ ADD
@router.post("/{product_id}")
def add_favorite(product_id: int, current_user=Depends(get_current_user), db: Session = Depends(get_db)):

    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Producto no existe")

    exists = db.query(Favorite).filter_by(
        user_id=current_user.id,
        product_id=product_id
    ).first()

    if exists:
        return {"message": "Ya está en favoritos"}

    fav = Favorite(user_id=current_user.id, product_id=product_id)
    db.add(fav)
    db.commit()

    return {"message": "Agregado a favoritos ❤️"}

# 💔 DELETE
@router.delete("/{product_id}")
def remove_favorite(product_id: int, current_user=Depends(get_current_user), db: Session = Depends(get_db)):

    fav = db.query(Favorite).filter_by(
        user_id=current_user.id,
        product_id=product_id
    ).first()

    if not fav:
        raise HTTPException(status_code=404, detail="No está en favoritos")

    db.delete(fav)
    db.commit()

    return {"message": "Eliminado 💔"}

# 📋 GET
@router.get("/")
def get_favorites(current_user=Depends(get_current_user), db: Session = Depends(get_db)):

    favorites = db.query(Favorite).filter_by(user_id=current_user.id).all()

    result = []

    for fav in favorites:
        product = db.query(Product).filter(Product.id == fav.product_id).first()

        if product:
            result.append({
                "favorite_id": fav.id,
                "fecha": fav.fecha,

                # 🔥 PRODUCTO COMPLETO
                "product": {
                    "id": product.id,
                    "name": product.name,
                    "brand": product.brand,
                    "price": product.price,
                    "image": product.image,
                    "category": product.category,
                    "stock": product.stock,
                }
            })

    return result