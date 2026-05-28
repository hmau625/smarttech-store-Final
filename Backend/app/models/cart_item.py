from sqlalchemy import Column, Integer, ForeignKey
from app.database import Base

class CartItem(Base):
    __tablename__ = "cart_items"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("usuarios.id"))
    product_id = Column(Integer, ForeignKey("productos.id"))
    quantity = Column(Integer, default=1)