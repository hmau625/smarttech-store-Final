from pydantic import BaseModel
from typing import Optional, List


class DashboardStats(BaseModel):
    total_revenue:        float
    total_units_sold:     int
    critical_stock_count: int
    total_clients:        int
    total_orders:         int


class TopProduct(BaseModel):
    id:                 int
    name:               str
    category:           str
    brand:              str
    price:              float
    image:              str
    total_vendido:      int
    ingresos_generados: float


class StockItem(BaseModel):
    id:       int
    name:     str
    category: str
    brand:    str
    price:    float
    stock:    int
    status:   str
    image:    str


class TopClient(BaseModel):
    id:            int
    nombre:        str
    correo:        str
    imagen:        str
    total_pedidos: int
    total_gastado: float


class OrderSummary(BaseModel):
    id:          int
    usuario_id:  int
    nombre:      str
    apellido:    str
    ciudad:      str
    total:       float
    estado:      str
    metodo_pago: str
    fecha:       str


class OrderItem(BaseModel):
    producto_id:     int
    name:            str
    image:           str
    cantidad:        int
    precio_unitario: float
    subtotal:        float


class OrderDetail(BaseModel):
    id:              int
    usuario_id:      int
    nombre:          str
    apellido:        str
    tipo_documento:  str
    documento:       str
    pais:            str
    departamento:    str
    ciudad:          str
    direccion:       str
    numero_contacto: str
    metodo_pago:     str
    referencia_pago: Optional[str]
    fecha_entrega:   Optional[str]
    total:           float
    estado:          str
    fecha:           str
    items:           List[OrderItem]


# ── Cambiar estado pedido ──
class UpdateOrderStatus(BaseModel):
    estado: str
    # valores válidos: pagado | en_preparacion | enviado | entregado | cancelado


# ── Reponer stock ──
class RestockBody(BaseModel):
    units: int