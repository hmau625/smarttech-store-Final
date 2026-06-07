from sqlalchemy.orm import Session
from sqlalchemy import func
from fastapi import HTTPException
from app.models.product import Product
from app.models.pedido import Pedido
from app.models.pedido_detalle import PedidoDetalle
from app.models.user import User

ESTADOS_VALIDOS = ["pagado", "en_preparacion", "enviado", "entregado", "cancelado"]


def get_dashboard_stats(db: Session):
    total_revenue = db.query(func.coalesce(func.sum(Pedido.total), 0)).scalar()
    total_units   = db.query(func.coalesce(func.sum(PedidoDetalle.cantidad), 0)).join(Pedido, Pedido.id == PedidoDetalle.pedido_id).scalar()
    critical_stock = db.query(func.count(Product.id)).filter(Product.stock <= 5).scalar()
    total_clients  = db.query(func.count(User.id)).filter(User.rol == "cliente").scalar()
    total_orders   = db.query(func.count(Pedido.id)).scalar()
    return {
        "total_revenue":        float(total_revenue),
        "total_units_sold":     int(total_units),
        "critical_stock_count": int(critical_stock),
        "total_clients":        int(total_clients),
        "total_orders":         int(total_orders),
    }


def get_top_products(db: Session, limit: int = 6):
    results = (
        db.query(
            Product.id, Product.name, Product.category, Product.brand,
            Product.price, Product.image,
            func.coalesce(func.sum(PedidoDetalle.cantidad), 0).label("total_vendido"),
            func.coalesce(func.sum(PedidoDetalle.cantidad * PedidoDetalle.precio_unitario), 0).label("ingresos_generados"),
        )
        .outerjoin(PedidoDetalle, PedidoDetalle.producto_id == Product.id)
        .group_by(Product.id, Product.name, Product.category, Product.brand, Product.price, Product.image)
        .order_by(func.coalesce(func.sum(PedidoDetalle.cantidad), 0).desc())
        .limit(limit).all()
    )
    return [{"id": r.id, "name": r.name, "category": r.category, "brand": r.brand,
             "price": float(r.price), "image": r.image or "",
             "total_vendido": int(r.total_vendido), "ingresos_generados": float(r.ingresos_generados)}
            for r in results]


def get_stock_sorted(db: Session, filter: str = "all"):
    query = db.query(Product)

    if filter == "agotado":
        query = query.filter(Product.stock == 0)
    elif filter == "danger":
        query = query.filter(Product.stock > 0, Product.stock <= 5)
    elif filter == "warn":
        query = query.filter(Product.stock > 5, Product.stock <= 15)
    elif filter == "ok":
        query = query.filter(Product.stock > 15)

    products = query.order_by(Product.stock.asc()).all()

    def stock_status(stock: int) -> str:
        if stock == 0:  return "agotado"
        if stock <= 5:  return "danger"
        if stock <= 15: return "warn"
        return "ok"

    return [{"id": p.id, "name": p.name, "category": p.category, "brand": p.brand,
             "price": float(p.price), "stock": p.stock,
             "status": stock_status(p.stock), "image": p.image or ""}
            for p in products]


def get_top_clients(db: Session, limit: int = 5):
    results = (
        db.query(User.id, User.nombre, User.correo, User.imagen,
                 func.count(Pedido.id).label("total_pedidos"),
                 func.coalesce(func.sum(Pedido.total), 0).label("total_gastado"))
        .join(Pedido, Pedido.usuario_id == User.id)
        .group_by(User.id, User.nombre, User.correo, User.imagen)
        .order_by(func.sum(Pedido.total).desc())
        .limit(limit).all()
    )
    return [{"id": r.id, "nombre": r.nombre, "correo": r.correo, "imagen": r.imagen or "",
             "total_pedidos": int(r.total_pedidos), "total_gastado": float(r.total_gastado)}
            for r in results]


def get_all_orders(db: Session, estado: str = None):
    query = db.query(Pedido)
    if estado and estado in ESTADOS_VALIDOS:
        query = query.filter(Pedido.estado == estado)
    orders = query.order_by(Pedido.fecha.desc()).all()
    return [{"id": o.id, "usuario_id": o.usuario_id, "nombre": o.nombre,
             "apellido": o.apellido, "ciudad": o.ciudad, "total": float(o.total),
             "estado": o.estado, "metodo_pago": o.metodo_pago, "fecha": str(o.fecha)}
            for o in orders]


def get_order_detail(db: Session, pedido_id: int):
    pedido = db.query(Pedido).filter(Pedido.id == pedido_id).first()
    if not pedido:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")
    detalles = (db.query(PedidoDetalle, Product)
                .join(Product, Product.id == PedidoDetalle.producto_id)
                .filter(PedidoDetalle.pedido_id == pedido_id).all())
    items = [{"producto_id": d.producto_id, "name": p.name, "image": p.image or "",
              "cantidad": d.cantidad, "precio_unitario": float(d.precio_unitario),
              "subtotal": float(d.cantidad * d.precio_unitario)} for d, p in detalles]
    return {"id": pedido.id, "usuario_id": pedido.usuario_id, "nombre": pedido.nombre,
            "apellido": pedido.apellido, "tipo_documento": pedido.tipo_documento,
            "documento": pedido.documento, "pais": pedido.pais,
            "departamento": pedido.departamento, "ciudad": pedido.ciudad,
            "direccion": pedido.direccion, "numero_contacto": pedido.numero_contacto,
            "metodo_pago": pedido.metodo_pago, "referencia_pago": pedido.referencia_pago,
            "fecha_entrega": pedido.fecha_entrega, "total": float(pedido.total),
            "estado": pedido.estado, "fecha": str(pedido.fecha), "items": items}


def update_order_status(db: Session, pedido_id: int, nuevo_estado: str):
    if nuevo_estado not in ESTADOS_VALIDOS:
        raise HTTPException(status_code=400, detail=f"Estado inválido. Usa: {ESTADOS_VALIDOS}")
    pedido = db.query(Pedido).filter(Pedido.id == pedido_id).first()
    if not pedido:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")
    estado_anterior = pedido.estado
    pedido.estado   = nuevo_estado
    db.commit()
    db.refresh(pedido)
    return {"message": "Estado actualizado", "pedido_id": pedido_id,
            "estado_anterior": estado_anterior, "estado_nuevo": nuevo_estado}