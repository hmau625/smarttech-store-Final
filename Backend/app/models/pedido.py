from sqlalchemy import Column, Integer, Float, String, ForeignKey, DateTime, Text
from datetime import datetime
from app.database import Base

class Pedido(Base):
    __tablename__ = "pedidos"

    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"))
    total = Column(Float, default=0)
    estado = Column(String(50), default="pagado")
    metodo_pago = Column(String(50))
    nombre = Column(String(100))
    apellido = Column(String(100))
    tipo_documento = Column(String(10))
    documento = Column(String(50))
    pais = Column(String(50))
    departamento = Column(String(50))
    ciudad = Column(String(100))
    direccion = Column(Text)
    referencia_pago = Column(String(100))
    fecha_entrega = Column(String(50))
    fecha = Column(DateTime, default=datetime.utcnow)
    numero_contacto = Column(String(20))