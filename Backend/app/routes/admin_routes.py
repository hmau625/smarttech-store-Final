from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.routes.auth_routes import get_current_user
from app.models.user import User
from app.models.product import Product
from app.models.pedido import Pedido
from app.models.pedido_detalle import PedidoDetalle
from app.schemas.admin_schema import UpdateOrderStatus, RestockBody
from app.services.admin_service import (
    get_dashboard_stats,
    get_top_products,
    get_stock_sorted,
    get_top_clients,
    get_all_orders,
    get_order_detail,
    update_order_status,
)
from app.services.email_service import send_email, build_status_update

router = APIRouter(prefix="/admin", tags=["Admin"])


# ================= DB =================
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ================= GUARD ADMIN =================
def require_admin(current_user: User = Depends(get_current_user)):
    if current_user.rol != "admin":
        raise HTTPException(
            status_code=403,
            detail="Acceso denegado: solo administradores"
        )
    return current_user


# ================= ENDPOINTS =================

# GET /admin/stats
@router.get("/stats")
def dashboard_stats(
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    return get_dashboard_stats(db)


# GET /admin/products/top?limit=6
@router.get("/products/top")
def top_products(
    limit: int = Query(default=6, ge=1, le=20),
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    return get_top_products(db, limit=limit)


# GET /admin/stock?filter=all|danger|warn|ok
@router.get("/stock")
def stock_inventory(
    filter: str = Query(default="all"),
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    if filter not in ["all", "agotado", "danger", "warn", "ok"]:
        raise HTTPException(
            status_code=400,
            detail="Filtro inválido. Usa: all | danger | warn | ok"
        )
    return get_stock_sorted(db, filter=filter)


# GET /admin/clients/top?limit=5
@router.get("/clients/top")
def top_clients(
    limit: int = Query(default=5, ge=1, le=20),
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    return get_top_clients(db, limit=limit)


# GET /admin/orders?estado=pagado
@router.get("/orders")
def all_orders(
    estado: str = Query(default=None),
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    return get_all_orders(db, estado=estado)


# GET /admin/orders/{pedido_id}
@router.get("/orders/{pedido_id}")
def order_detail(
    pedido_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    return get_order_detail(db, pedido_id=pedido_id)


# PATCH /admin/orders/{pedido_id}/status
@router.patch("/orders/{pedido_id}/status")
def change_order_status(
    pedido_id: int,
    body: UpdateOrderStatus,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    result = update_order_status(db, pedido_id=pedido_id, nuevo_estado=body.estado)

    # 📧 ENVIAR EMAIL DE ACTUALIZACIÓN DE ESTADO
    try:
        pedido = db.query(Pedido).filter(Pedido.id == pedido_id).first()
        if pedido:
            usuario = db.query(User).filter(User.id == pedido.usuario_id).first()
            if usuario:
                # Obtener resumen de productos
                detalles = db.query(PedidoDetalle).filter(
                    PedidoDetalle.pedido_id == pedido_id
                ).all()

                items_summary = ""
                for d in detalles:
                    prod = db.query(Product).filter(Product.id == d.producto_id).first()
                    if prod:
                        items_summary += f"• {prod.name} x{d.cantidad}<br>"

                html = build_status_update(
                    nombre=usuario.nombre,
                    pedido_id=pedido_id,
                    estado=body.estado,
                    items_summary=items_summary,
                )

                estado_labels = {
                    "pagado": "Pagado",
                    "en_preparacion": "En preparación",
                    "enviado": "Enviado",
                    "entregado": "Entregado",
                    "cancelado": "Cancelado",
                }
                estado_label = estado_labels.get(body.estado, body.estado)

                send_email(
                    to_email=usuario.correo,
                    subject=f"SmartTech Store — Pedido #{pedido_id}: {estado_label}",
                    html_body=html,
                )
    except Exception as e:
        print(f"ERROR enviando email de estado: {e}")

    return result


# PATCH /admin/stock/{product_id}/restock
@router.patch("/stock/{product_id}/restock")
def restock_product(
    product_id: int,
    body: RestockBody,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    if body.units <= 0:
        raise HTTPException(status_code=400, detail="Unidades inválidas")
    product.stock += body.units
    db.commit()
    db.refresh(product)
    return {
        "message":     "Stock actualizado",
        "producto":    product.name,
        "stock_nuevo": product.stock,
    }