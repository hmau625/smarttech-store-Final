from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    UploadFile,
    File
)
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models.product import Product
from app.data.products_mock import products as mock_products
import os
import shutil
import uuid

router = APIRouter(
    prefix="/products",
    tags=["Products"]
)

# ─────────────────────────────────────────────
# STATIC FOLDER
# ─────────────────────────────────────────────

UPLOAD_FOLDER = "static/products"

os.makedirs(
    UPLOAD_FOLDER,
    exist_ok=True,
)

# ─────────────────────────────────────────────
# DB
# ─────────────────────────────────────────────

def get_db():

    db = SessionLocal()

    try:
        yield db

    finally:
        db.close()

# ─────────────────────────────────────────────
# PRODUCT TO JSON
# ─────────────────────────────────────────────

def product_to_dict(product):

    return {

        "id": product.id or 0,

        "name": product.name or "",

        "category": product.category or "",

        "brand": product.brand or "",

        "price": float(product.price)
        if product.price is not None
        else 0.0,

        "stock": product.stock or 0,

        "image": product.image or "",

        "specs": product.specs or {}
    }

# ─────────────────────────────────────────────
# GET ALL PRODUCTS
# ─────────────────────────────────────────────

@router.get("/")
def get_products(
    db: Session = Depends(get_db)
):

    products = db.query(Product).all()

    return [
        product_to_dict(p)
        for p in products
    ]

# ─────────────────────────────────────────────
# GET PRODUCT BY ID
# ─────────────────────────────────────────────

@router.get("/{id}")
def get_product(
    id: int,
    db: Session = Depends(get_db)
):

    product = db.query(Product)\
        .filter(Product.id == id)\
        .first()

    if not product:

        raise HTTPException(
            status_code=404,
            detail="Producto no encontrado"
        )

    return product_to_dict(product)

# ─────────────────────────────────────────────
# CREATE PRODUCT
# ─────────────────────────────────────────────

@router.post("/")
def create_product(
    product: dict,
    db: Session = Depends(get_db)
):

    new_product = Product(
        name=product.get("name"),
        category=product.get("category"),
        brand=product.get("brand"),
        price=product.get("price"),
        stock=product.get("stock", 0),
        image=product.get("image"),
        specs=product.get("specs")
    )

    db.add(new_product)
    db.commit()
    db.refresh(new_product)
    return product_to_dict(new_product)

# ─────────────────────────────────────────────
# UPDATE PRODUCT
# ─────────────────────────────────────────────

@router.put("/{id}")
def update_product(
    id: int,
    data: dict,
    db: Session = Depends(get_db)
):
    product = db.query(Product)\
        .filter(Product.id == id)\
        .first()

    if not product:
        raise HTTPException(
            status_code=404,
            detail="Producto no encontrado"
        )
    product.name = data.get(
        "name",
        product.name
    )
    product.category = data.get(
        "category",
        product.category
    )
    product.brand = data.get(
        "brand",
        product.brand
    )
    product.price = data.get(
        "price",
        product.price
    )
    product.stock = data.get(
        "stock",
        product.stock
    )
    product.image = data.get(
        "image",
        product.image
    )
    product.specs = data.get(
        "specs",
        product.specs
    )

    db.commit()
    db.refresh(product)
    return product_to_dict(product)

# ─────────────────────────────────────────────
# DELETE PRODUCT
# ─────────────────────────────────────────────

@router.delete("/{id}")
def delete_product(
    id: int,
    db: Session = Depends(get_db)
):

    product = db.query(Product)\
        .filter(Product.id == id)\
        .first()

    if not product:

        raise HTTPException(
            status_code=404,
            detail="Producto no encontrado"
        )

    db.delete(product)

    db.commit()

    return {
        "message": "Producto eliminado"
    }

# ─────────────────────────────────────────────
# UPLOAD PRODUCT IMAGE
# ─────────────────────────────────────────────

@router.post("/upload-image")
async def upload_product_image(
    file: UploadFile = File(...)
):

    # EXTENSION
    extension = file.filename.split(".")[-1]

    # UNIQUE NAME
    filename = f"{uuid.uuid4()}.{extension}"

    # PATH
    filepath = os.path.join(
        UPLOAD_FOLDER,
        filename
    )

    # SAVE IMAGE
    with open(filepath, "wb") as buffer:

        shutil.copyfileobj(
            file.file,
            buffer
        )

    # URL
    image_url = f"/static/products/{filename}"

    return {
        "image_url": image_url
    }

# ─────────────────────────────────────────────
# SEED PRODUCTS
# ─────────────────────────────────────────────

@router.post("/seed")
def seed_products(
    db: Session = Depends(get_db)
):

    for p in mock_products:

        exists = db.query(Product)\
            .filter(Product.id == p["id"])\
            .first()

        if not exists:

            new_product = Product(

                id=p["id"],

                name=p["name"],

                category=p.get("category"),

                brand=p.get("brand"),

                price=p["price"],

                stock=p.get("stock", 0),

                image=p.get("image"),

                specs=p.get("specs")
            )

            db.add(new_product)

    db.commit()

    return {
        "message": "Productos cargados"
    }