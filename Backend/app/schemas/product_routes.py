from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.product import Product

router = APIRouter(prefix="/products", tags=["Products"])

# 🔍 OBTENER TODOS
@router.get("/")
def get_products(db: Session = Depends(get_db)):
    return db.query(Product).all()

# ➕ CREAR
@router.post("/")
def create_product(product: dict, db: Session = Depends(get_db)):
    new_product = Product(
        name=product["name"],
        price=product["price"]
    )
    db.add(new_product)
    db.commit()
    db.refresh(new_product)
    return new_product

# ✏️ EDITAR
@router.put("/{id}")
def update_product(id: int, product: dict, db: Session = Depends(get_db)):
    p = db.query(Product).filter(Product.id == id).first()

    p.name = product["name"]
    p.price = product["price"]

    db.commit()
    return p

# 🗑 ELIMINAR
@router.delete("/{id}")
def delete_product(id: int, db: Session = Depends(get_db)):
    p = db.query(Product).filter(Product.id == id).first()
    db.delete(p)
    db.commit()
    return {"message": "Producto eliminado"}