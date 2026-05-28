from sqlalchemy import Column, Integer, Float, ForeignKey
from app.database import Base

class PedidoDetalle(Base):
    __tablename__ = "pedidos_detalles"

    id = Column(Integer, primary_key=True, index=True)

    pedido_id = Column(Integer, ForeignKey("pedidos.id"), nullable=False)
    producto_id = Column(Integer, ForeignKey("productos.id"), nullable=False)

    cantidad = Column(Integer, nullable=False)
    precio_unitario = Column(Float, nullable=False)