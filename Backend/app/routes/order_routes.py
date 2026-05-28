from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import SessionLocal

from app.models.pedido import Pedido
from app.models.pedido_detalle import PedidoDetalle
from app.models.product import Product
from app.models.user import User

import jwt

router = APIRouter(prefix="/orders", tags=["Orders"])

SECRET_KEY = "mi_super_secreto"
ALGORITHM = "HS256"


# 🔌 DB
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# 🔐 USER FROM TOKEN (igual estilo que cart)
def get_current_user(token: str, db: Session):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        correo = payload.get("sub")
        user = db.query(User).filter(User.correo == correo).first()
        return user
    except:
        return None


# 📜 OBTENER HISTORIAL
@router.get("/")
def get_user_orders(token: str, db: Session = Depends(get_db)):

    user = get_current_user(token, db)

    if not user:
        raise HTTPException(status_code=401, detail="No autorizado")

    orders = db.query(Pedido).filter(Pedido.usuario_id == user.id).all()

    result = []

    for order in orders:

        items = db.query(PedidoDetalle).filter(
            PedidoDetalle.pedido_id == order.id
        ).all()

        formatted_items = []

        for item in items:

            product = db.query(Product).filter(
                Product.id == item.producto_id
            ).first()

            formatted_items.append({
                "product_id": item.producto_id,
                "product_name": product.name if product else "Producto eliminado",
                "image": product.image if product else "",
                "quantity": item.cantidad,
                "price": item.precio_unitario,
                "subtotal": item.cantidad * item.precio_unitario
            })

        result.append({
            "order_id": order.id,
            "total_price": order.total,
            "payment_method": order.metodo_pago,
            "status": order.estado,
            "created_at": str(order.fecha),
            "items": formatted_items
        })

    return {
        "total_orders": len(result),
        "orders": result
    }


# 🔥 OBTENER UNA ORDEN POR ID
@router.get("/{order_id}")
def get_order(order_id: int, db: Session = Depends(get_db)):

    order = db.query(Pedido).filter(Pedido.id == order_id).first()

    if not order:
        raise HTTPException(status_code=404, detail="Orden no encontrada")

    items = db.query(PedidoDetalle).filter(
        PedidoDetalle.pedido_id == order.id
    ).all()

    formatted_items = []

    for item in items:

        product = db.query(Product).filter(
            Product.id == item.producto_id
        ).first()

        formatted_items.append({
            "product_id": item.producto_id,
            "product_name": product.name if product else "Producto eliminado",
            "image": product.image if product else "",
            "quantity": item.cantidad,
            "price": item.precio_unitario,
            "subtotal": item.cantidad * item.precio_unitario
        })

    return {
        "order_id": order.id,
        "total_price": order.total,
        "payment_method": order.metodo_pago,
        "status": order.estado,
        "created_at": str(order.fecha),
        "items": formatted_items
    }