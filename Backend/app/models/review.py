from sqlalchemy import Column, Integer, Float, String, Text, ForeignKey, DateTime
from sqlalchemy.sql import func
from app.database import Base

class Review(Base):
    __tablename__ = "reviews"

    id          = Column(Integer, primary_key=True, index=True, autoincrement=True)
    product_id  = Column(Integer, ForeignKey("productos.id", ondelete="CASCADE"), nullable=False)
    user_id     = Column(Integer, ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False)
    rating      = Column(Float, nullable=False)             # 0.5, 1.0, 1.5 ... 5.0
    comment     = Column(Text, nullable=True)
    parent_id   = Column(Integer, ForeignKey("reviews.id", ondelete="CASCADE"), nullable=True)
    fecha       = Column(DateTime, server_default=func.now())