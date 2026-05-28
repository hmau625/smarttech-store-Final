from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.cart_item import CartItem
from app.models.pedido import Pedido
from app.models.pedido_detalle import PedidoDetalle
from app.models.product import Product
from app.models.user import User

import jwt

router = APIRouter(prefix="/checkout", tags=["Checkout"])

SECRET_KEY = "mi_super_secreto"
ALGORITHM = "HS256"


# 🔐 Obtener usuario desde token
def get_user(token: str, db: Session):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("sub")
        return db.query(User).filter(User.correo == email).first()
    except:
        return None


@router.post("/")
def checkout(data: dict, db: Session = Depends(get_db)):

    # 🔹 DATOS
    token = data.get("token")
    metodo = data.get("metodo_pago")

    if not token:
        raise HTTPException(status_code=401, detail="Token requerido")

    user = get_user(token, db)
    if not user:
        raise HTTPException(status_code=401, detail="Usuario inválido")

    if not metodo:
        raise HTTPException(status_code=400, detail="Método de pago requerido")

    # 🔥 LIMPIAR DATOS (NUEVO)
    nombre = (data.get("nombre") or "").strip()
    apellido = (data.get("apellido") or "").strip()
    tipo_documento = data.get("tipo_documento")
    documento = (data.get("documento") or "").strip()
    telefono = (data.get("numero_contacto") or "").strip()

    pais = data.get("pais")
    departamento = data.get("departamento")
    ciudad = data.get("ciudad")
    direccion = (data.get("direccion") or "").strip()

    referencia_pago = data.get("referencia_pago")
    fecha_entrega = data.get("fecha_entrega")

    # 🔴 VALIDACIONES (NUEVO)
    if len(nombre) < 3:
        raise HTTPException(status_code=400, detail="Nombre inválido")

    if len(apellido) < 3:
        raise HTTPException(status_code=400, detail="Apellido inválido")

    if not tipo_documento:
        raise HTTPException(status_code=400, detail="Tipo documento requerido")

    if not documento.isdigit():
        raise HTTPException(status_code=400, detail="Documento inválido")

    if len(documento) < 6:
        raise HTTPException(status_code=400, detail="Documento muy corto")

    if not telefono.isdigit() or len(telefono) != 10:
        raise HTTPException(status_code=400, detail="Teléfono inválido")

    if not pais or not ciudad:
        raise HTTPException(status_code=400, detail="Ubicación incompleta")

    if len(direccion) < 5:
        raise HTTPException(status_code=400, detail="Dirección inválida")

    if metodo == "tarjeta":
        if not referencia_pago or len(referencia_pago) < 3 or len(referencia_pago) > 6:
            raise HTTPException(status_code=400, detail="Código inválido")

    if metodo == "nequi":
        if not referencia_pago or len(referencia_pago) != 4:
            raise HTTPException(status_code=400, detail="Código inválido")

    if not fecha_entrega:
        raise HTTPException(status_code=400, detail="Fecha requerida")

    # 🛒 OBTENER CARRITO REAL (CartItem)
    items = db.query(CartItem).filter(CartItem.user_id == user.id).all()

    if not items:
        raise HTTPException(status_code=400, detail="Carrito vacío")

    # 💰 CALCULAR TOTAL
    total = 0
    productos_validos = []

    for item in items:
        product = db.query(Product).filter(Product.id == item.product_id).first()

        if not product:
            continue

        subtotal = product.price * item.quantity
        total += subtotal

        productos_validos.append((item, product))

    if total == 0:
        raise HTTPException(status_code=400, detail="Error calculando total")

    # 📦 CREAR PEDIDO
    pedido = Pedido(
    usuario_id=user.id,
    total=total,
    metodo_pago=metodo,
    nombre=nombre,
    apellido=apellido,
    tipo_documento=tipo_documento,
    documento=documento,
    pais=pais,
    departamento=departamento,
    ciudad=ciudad,
    direccion=direccion,
    numero_contacto=telefono,
    referencia_pago=referencia_pago,
    fecha_entrega=fecha_entrega,
    estado="pendiente"
)
    db.add(pedido)
    db.commit()
    db.refresh(pedido)

    # 📦 CREAR DETALLES
    for item, product in productos_validos:

        detalle = PedidoDetalle(
            pedido_id=pedido.id,
            producto_id=product.id,
            cantidad=item.quantity,
            precio_unitario=product.price
        )

        db.add(detalle)

        # 🔥 OPCIONAL: descontar stock
        if product.stock >= item.quantity:
            product.stock -= item.quantity

    db.commit()

    # 🧹 LIMPIAR CARRITO
    db.query(CartItem).filter(CartItem.user_id == user.id).delete()
    db.commit()

    return {
        "ok": True,
        "pedido_id": pedido.id,
        "total": total
    }