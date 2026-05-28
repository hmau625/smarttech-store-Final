from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models.cart_item import CartItem
from app.models.user import User
from app.models.product import Product
import jwt

router = APIRouter(prefix="/cart", tags=["Cart"])

SECRET_KEY = "mi_super_secreto"
ALGORITHM = "HS256"

# DB
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# USER
def get_current_user(token: str, db: Session):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        correo = payload.get("sub")
        return db.query(User).filter(User.correo == correo).first()
    except:
        return None


# ➕ ADD TO CART (CON STOCK REAL)
@router.post("/add")
def add_to_cart(product_id: int, quantity: int = 1, token: str = "", db: Session = Depends(get_db)):

    user = get_current_user(token, db)
    if not user:
        raise HTTPException(status_code=401, detail="No autorizado")

    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Producto no encontrado")

    item = db.query(CartItem).filter(
        CartItem.user_id == user.id,
        CartItem.product_id == product_id
    ).first()

    current_qty = item.quantity if item else 0
    new_qty = current_qty + quantity

    # STOCK CHECK
    if product.stock <= 0:
        raise HTTPException(status_code=400, detail="Producto agotado")

    if new_qty > product.stock:
        raise HTTPException(
            status_code=400,
            detail=f"Solo puedes agregar máximo {product.stock}"
        )

    if item:
        item.quantity = new_qty
    else:
        item = CartItem(
            user_id=user.id,
            product_id=product_id,
            quantity=quantity
        )
        db.add(item)

    db.commit()
    return {"message": "Agregado al carrito"}


# 📦 GET CART (CON STOCK INCLUIDO)
@router.get("/")
def get_cart(token: str = "", db: Session = Depends(get_db)):

    user = get_current_user(token, db)
    if not user:
        raise HTTPException(status_code=401, detail="No autorizado")

    items = db.query(CartItem).filter(CartItem.user_id == user.id).all()

    result = []

    for item in items:
        product = db.query(Product).filter(Product.id == item.product_id).first()

        result.append({
            "id": item.id,
            "product_id": item.product_id,
            "quantity": item.quantity,
            "name": product.name,
            "price": float(product.price),
            "image": product.image,
            "stock": product.stock   # 🔥 IMPORTANTE
        })

    return result


# ➖ REMOVE ONE
@router.delete("/remove")
def remove_from_cart(product_id: int, token: str = "", db: Session = Depends(get_db)):

    user = get_current_user(token, db)
    if not user:
        raise HTTPException(status_code=401, detail="No autorizado")

    item = db.query(CartItem).filter(
        CartItem.user_id == user.id,
        CartItem.product_id == product_id
    ).first()

    if not item:
        raise HTTPException(status_code=404, detail="No existe")

    # 🔥 reduce 1 unidad, NO elimina todo
    if item.quantity > 1:
        item.quantity -= 1
    else:
        db.delete(item)

    db.commit()

    return {"message": "Actualizado"}


# 🗑 CLEAR CART
@router.delete("/clear")
def clear_cart(token: str = "", db: Session = Depends(get_db)):

    user = get_current_user(token, db)
    if not user:
        raise HTTPException(status_code=401, detail="No autorizado")

    db.query(CartItem).filter(CartItem.user_id == user.id).delete()
    db.commit()

    return {"message": "Carrito vaciado"}