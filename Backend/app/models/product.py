from sqlalchemy import JSON, Column, Integer, String, Float
from app.database import Base

class Product(Base):
    __tablename__ = "productos"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255))
    category = Column(String(100))
    brand = Column(String(100))
    price = Column(Float)
    stock = Column(Integer, default=0)
    image = Column(String(500))
    specs = Column(JSON)
    status = Column(String, default="active")