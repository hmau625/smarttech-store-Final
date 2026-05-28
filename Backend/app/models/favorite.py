from sqlalchemy import Column, Integer, ForeignKey, DateTime
from datetime import datetime
from app.database import Base

class Favorite(Base):
    __tablename__ = "favoritos"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("usuarios.id"))
    product_id = Column(Integer, ForeignKey("productos.id"))
    fecha = Column(DateTime, default=datetime.utcnow)